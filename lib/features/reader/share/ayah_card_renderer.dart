import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Ayet kartını ekranda göstermeden PNG'ye çevirir.
///
/// Kart, uygulamanın kendi widget ağacına geçici bir katman (`OverlayEntry`)
/// olarak eklenir, bir kare çizilir, görüntü alınır ve katman kaldırılır.
///
/// Neden ağacın içinde: `toImage` yalnızca gerçekten düzenlenmiş ve boyanmış
/// bir `RenderRepaintBoundary` üzerinde çalışır. Ağacın dışında elle bir
/// render ağacı kurmak da mümkün ama uygulamanın `View`'ı ile çakışıyor ve
/// çizim hiç tamamlanmıyordu.
///
/// Neden görünmüyor: katman ekranın dışına, sol üstün epeyce ötesine
/// kaydırılır. `Offstage` denendi ve olmadı — alt ağacı düzenler ama
/// BOYAMAZ, oysa `toImage` boyanmış bir katman ister ve boyanmamış
/// boundary'de doğrudan hata verir. Şeffaflık (`Opacity(0)`) da uygun
/// değil: şeffaf da olsa çizilen bir katman dokunma olaylarını yakalar.
/// Ekran dışına taşımak her iki sorunu da çözer — kart gerçekten boyanır,
/// kullanıcı hiçbir şey görmez.
abstract final class AyahCardRenderer {

  /// [card] widget'ını [size]×[size] boyutunda PNG'ye çevirir.
  ///
  /// Başarısızlıkta `null` döner: kart paylaşımı ikincil bir özellik,
  /// hata vermesi okuma akışını bozmamalı — çağıran taraf metin
  /// paylaşımına düşebilir.
  static Future<Uint8List?> toPng({
    required Widget card,
    required double size,
    required BuildContext context,
  }) async {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return null;

    final boundaryKey = GlobalKey();
    final direction = Directionality.maybeOf(context) ?? TextDirection.ltr;

    final entry = OverlayEntry(
      builder: (_) => Positioned(
        // Kartın kenar uzunluğu kadar sola ve yukarı taşınır; ekranda hiçbir
        // pikseli görünmez. `IgnorePointer` ile de dokunuşları yutmaz.
        left: -size * 2,
        top: -size * 2,
        child: IgnorePointer(
          child: Directionality(
            textDirection: direction,
            child: MediaQuery(
              // Sistem yazı boyutu ayarı karta sızmamalı: kart sabit ölçülü
              // bir görsel, kullanıcının erişilebilirlik ayarı metni karttan
              // taşırırdı.
              data: const MediaQueryData(textScaler: TextScaler.noScaling),
              child: RepaintBoundary(
                key: boundaryKey,
                child: SizedBox(
                  width: size,
                  height: size,
                  child: card,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    try {
      // Katman boyanana kadar beklenir.
      //
      // Kare bekleme geri çağrıları (`endOfFrame`, `addPostFrameCallback`)
      // burada güvenilir değil: çağrı bir test sarmalayıcısının içinden
      // ya da uygulama boştayken gelirse beklenen kare hiç düşmüyor ve
      // çizim asılı kalıyordu. Onun yerine katmanın gerçekten boyanmış
      // olması yoklanır — beklenen durum doğrudan sınanınca, o duruma
      // hangi yoldan gelindiği önemsizleşiyor.
      final boundary = await _paintedBoundary(boundaryKey);
      if (boundary == null) return null;

      // Kart zaten hedef piksel boyutunda tasarlandı; ölçeklemek yalnızca
      // dosyayı büyütürdü.
      //
      // Zaman aşımı bilinçli: `toImage` raster hattına iş verir ve o hattın
      // bulunmadığı ortamlarda (widget testleri, bazı öykünücüler) hiç
      // tamamlanmaz. Zaman aşımı olmadan paylaş düğmesi kullanıcıyı sonsuz
      // bir bekleyişte bırakırdı; süre dolduğunda `null` dönülür ve çağıran
      // taraf metin paylaşımına düşer.
      final bytes = await _capture(boundary).timeout(
        _renderTimeout,
        onTimeout: () => null,
      );

      return bytes;
    } catch (error, stack) {
      debugPrint('Ayet kartı çizilemedi: $error\n$stack');
      return null;
    } finally {
      entry.remove();
    }
  }

  /// Katmanı PNG baytlarına çevirir.
  static Future<Uint8List?> _capture(RenderRepaintBoundary boundary) async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      return bytes?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  /// Çizim için tanınan süre. Kart tek bir statik görsel; normalde birkaç
  /// yüz milisaniye sürer. Bu sınır bir performans hedefi değil, asılı
  /// kalmaya karşı emniyet supabı.
  static const _renderTimeout = Duration(seconds: 5);

  /// Katman boyanana kadar bekler ve boyanmış boundary'yi döndürür.
  ///
  /// Kısa aralıklarla yoklanır. Yoklama, kare geri çağrılarına göre daha
  /// kaba ama çok daha dayanıklı: katmanın ağaca eklenmesi ile boyanması
  /// arasında kaç kare geçtiği ortama göre değişiyor ve tek bir kare
  /// beklemek her zaman yetmiyordu.
  ///
  /// Süre dolarsa `null` döner; çağıran taraf metin paylaşımına düşer.
  static Future<RenderRepaintBoundary?> _paintedBoundary(GlobalKey key) async {
    final deadline = DateTime.now().add(_renderTimeout);

    while (DateTime.now().isBefore(deadline)) {
      // Uygulama boştaysa kendiliğinden kare çizilmez; açıkça istenir.
      WidgetsBinding.instance.scheduleFrame();
      await Future<void>.delayed(const Duration(milliseconds: 16));

      final object = key.currentContext?.findRenderObject();
      if (object is! RenderRepaintBoundary) continue;

      // `debugNeedsPaint` yalnızca hata ayıklama yapısında anlamlı; yayın
      // yapısında her zaman `false` döner. Bu yüzden tek başına ölçüt
      // yapılmaz: katmanın düzenlenmiş olması (`hasSize`) her iki yapıda da
      // geçerli ve boyamanın önkoşulu. Hata ayıklamada ikisi birden
      // sınanır, yayında düzen kontrolü kalır.
      if (!object.hasSize) continue;

      var painted = true;
      assert(() {
        painted = !object.debugNeedsPaint;
        return true;
      }());

      if (painted) return object;
    }

    return null;
  }
}
