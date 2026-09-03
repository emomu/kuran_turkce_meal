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
    final directory = await getTemporaryDirectory();
    final file = File(
      p.join(directory.path, 'ayet-${ayah.surahNumber}-${ayah.ayahNumber}.png'),
    );
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        // Metin de eklenir: görseli açamayan ya da metin arayan
        // uygulamalarda ayet yine de okunabilir kalır.
        text: _format(ayah, surahName, languageCode),
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
