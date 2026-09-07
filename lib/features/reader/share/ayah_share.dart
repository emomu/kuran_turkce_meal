import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/models/ayah.dart';
import 'ayah_card.dart';
import 'ayah_card_renderer.dart';

/// Ayet paylaşımı: düz metin ve görsel kart.
///
/// Metin paylaşımı her zaman çalışır. Kart ise çizilmeyi gerektiriyor ve
/// bu, kullandığı raster hattının bulunmadığı ortamlarda başarısız
/// olabiliyor; o durumda sessizce metin paylaşımına düşülür. Kullanıcıya
/// "kart oluşturulamadı" demek yerine istediği şeyin bir biçimini vermek
/// daha iyi — paylaşmak isteyen kullanıcı ayeti paylaşmış olur.
abstract final class AyahShare {

  /// Ayeti düz metin olarak paylaşır.
  static Future<void> text({
    required Ayah ayah,
    required String surahName,
    required String languageCode,
  }) {
    return SharePlus.instance.share(
      ShareParams(text: _format(ayah, surahName, languageCode)),
    );
  }

  /// Ayeti görsel kart olarak paylaşır.
  ///
  /// [origin] paylaşım yaprağının iPad'de nereden açılacağını belirler;
  /// verilmezse iPad'de yaprak ekranın ortasında beliriyor ve sistem uyarı
  /// veriyor.
  ///
  /// Kart çizilemezse metin paylaşımına düşülür ve `false` döner; çağıran
  /// taraf isterse kullanıcıyı bilgilendirebilir.
  static Future<bool> card({
    required BuildContext context,
    required Ayah ayah,
    required String surahName,
    required String languageCode,
    required bool isDark,
    bool includeArabic = false,
    Rect? origin,
  }) async {
    final bytes = await AyahCardRenderer.toPng(
      context: context,
      size: AyahCard.size,
      card: AyahCard(
        text: ayah.translationFor(languageCode),
        surahName: surahName,
        verseLabel: ayah.numberLabel,
        appName: 'app.title'.tr(),
        arabic: includeArabic ? ayah.arabic : null,
        isDark: isDark,
      ),
    );

    if (bytes == null) {
      await text(
        ayah: ayah,
        surahName: surahName,
        languageCode: languageCode,
      );
      return false;
    }

    // Görsel geçici dizine yazılır. Paylaşım yaprağı dosya yolu ister;
    // baytları doğrudan veremiyoruz. Geçici dizin seçildi çünkü dosya
    // paylaşımdan sonra tutulmaz — sistem kendi zamanında temizler.
    //
    // Dosya adına zaman damgası eklenir. Sabit adla yazıldığında iOS'un
    // paylaşım yaprağı aynı yolu daha önce gördüyse önbellekteki eski
    // görseli gösterebiliyor; kullanıcı temayı değiştirip yeniden
    // paylaştığında ya da Arapça metni açıp kapattığında eski kartı
    // görürdü.
    final directory = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(
      p.join(
        directory.path,
        'ayet-${ayah.surahNumber}-${ayah.ayahNumber}-$stamp.png',
      ),
    );
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        // Yalnızca görsel gönderilir; metin bilinçli olarak eklenmez.
        //
        // Görsel ve metin birlikte verildiğinde iOS'ta pek çok hedef
        // uygulama (WhatsApp, Signal, Mesajlar) ikisinden birini seçip
        // diğerini düşürüyor ve düşen genellikle görsel oluyor — kullanıcı
        // "kart paylaş" dediği hâlde karşı tarafa düz metin gidiyordu.
        // Bilinen bir eşleşme sorunu, share_plus tarafında değil hedef
        // uygulamaların paylaşım eklentilerinde:
        // https://github.com/fluttercommunity/plus_plugins/issues/261
        //
        // Metni isteyen kullanıcı için eylem yaprağında ayrı bir "Paylaş"
        // satırı zaten var; kart paylaşımının işi görseli teslim etmek.
        //
        // Konu satırı e-posta gibi hedeflerde başlık olur; görselin ne
        // olduğunu orada da söylüyor.
        subject: _format(ayah, surahName, languageCode),
        sharePositionOrigin: origin,
      ),
    );

    return true;
  }

  /// Paylaşım ve kopyalama için biçimlenmiş metin.
  static String _format(Ayah ayah, String surahName, String languageCode) {
    return 'actions.shareFormat'.tr(
      namedArgs: {
        'text': ayah.translationFor(languageCode),
        'surah': surahName,
        'verse': ayah.numberLabel,
      },
    );
  }
}
