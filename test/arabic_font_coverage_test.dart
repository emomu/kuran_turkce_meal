import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// Mushaf fontunun ayet metnini eksiksiz kapsadığını denetler.
///
/// Font bir karakteri taşımıyorsa Flutter hata vermez; o karakteri boş
/// kutu (tofu) olarak çizer. Gözle ancak o karakterin geçtiği ayete
/// denk gelirsen fark edilir — 6000 ayet içinde kolayca gözden kaçar.
///
/// Bu kontrol gerçekten gerekliydi: ilk denenen KFGQPC Uthmanic Hafs,
/// metindeki yuvarlak tenvin işaretlerini (U+08F0–08F2) içermediği için
/// ayetlerin yarısından fazlasında kutu çiziyordu. Font 2010 yapımı;
/// o işaretler Unicode'a 2012'de eklendi.
void main() {
  test('mushaf fontu ayet metnindeki her karakteri kapsar', () {
    final covered = _fontCharacters(File('assets/fonts/UthmanicHafs.ttf'));
    expect(covered, isNotEmpty, reason: 'font cmap tablosu okunamadı');

    final used = <int>{};
    final ayahs = jsonDecode(File('assets/data/ayahs.json').readAsStringSync())
        as List<dynamic>;
    for (final row in ayahs) {
      final arabic = (row as Map<String, dynamic>)['arabic'] as String?;
      if (arabic != null) used.addAll(arabic.runes);
    }

    // Boşluk ve satır sonu her fontta yoktur ve çizilecek bir şekilleri
    // de yoktur; kapsama dışı tutulur.
    used.removeAll(const {0x20, 0x0A});

    final missing = used.difference(covered).toList()..sort();
    expect(
      missing,
      isEmpty,
      reason: 'fontta olmayan karakterler kutu çizer: '
          '${missing.map((c) => 'U+${c.toRadixString(16).toUpperCase().padLeft(4, '0')}').join(', ')}',
    );
  });

}

/// TrueType `cmap` tablosundan fontun kapsadığı kod noktalarını çıkarır.
///
/// Yalnızca format 4 (BMP) ve format 12 (tam Unicode) alt tabloları okunur;
/// Arapça metin için gereken ikisi budur.
Set<int> _fontCharacters(File file) {
  final data = ByteData.sublistView(file.readAsBytesSync());
  final tableCount = data.getUint16(4);

  var cmapOffset = -1;
  for (var i = 0; i < tableCount; i++) {
    final entry = 12 + i * 16;
    final tag = String.fromCharCodes(
      Uint8List.sublistView(data, entry, entry + 4),
    );
    if (tag == 'cmap') {
      cmapOffset = data.getUint32(entry + 8);
      break;
    }
  }
  if (cmapOffset < 0) return const {};

  final chars = <int>{};
  final subtableCount = data.getUint16(cmapOffset + 2);
  for (var i = 0; i < subtableCount; i++) {
    final record = cmapOffset + 4 + i * 8;
    final table = cmapOffset + data.getUint32(record + 4);
    switch (data.getUint16(table)) {
      case 4:
        final segCount = data.getUint16(table + 6) ~/ 2;
        final endBase = table + 14;
        final startBase = endBase + segCount * 2 + 2;
        for (var s = 0; s < segCount; s++) {
          final end = data.getUint16(endBase + s * 2);
          final start = data.getUint16(startBase + s * 2);
          // 0xFFFF kapanış işaretçisidir, gerçek bir karakter değil.
          if (end == 0xFFFF) continue;
          for (var c = start; c <= end; c++) {
            chars.add(c);
          }
        }
      case 12:
        final groupCount = data.getUint32(table + 12);
        for (var g = 0; g < groupCount; g++) {
          final group = table + 16 + g * 12;
          final start = data.getUint32(group);
          final end = data.getUint32(group + 4);
          for (var c = start; c <= end; c++) {
            chars.add(c);
          }
        }
    }
  }
  return chars;
}
