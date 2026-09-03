import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/data/models/ayah.dart';

import 'helpers/localized_app.dart';

/// Ayet numarasından liste indeksine dönüşüm.
///
/// Okuma ekranı, aramadan/yer iminden/plandan gelen ayet numarasını
/// [ScrollablePositionedList] indeksine çevirir. İki kayma vardır ve ikisi de
/// gözden kaçtığında kullanıcı yanlış ayete iner:
///
///  1. Listenin 0. öğesi sure başlığıdır; ayetler 1'den başlar.
///  2. Bazı meallerde çevirmen ardışık ayetleri tek blokta karşılar. O
///     surelerde blok sayısı ayet sayısından azdır; fark biriktikçe hedef
///     ayet ekranın dışında kalır.
///
/// Bu testler gerçek meal verisi üzerinde çalışır: veri değişip yeni birleşik
/// bloklar eklenirse burada görünür.
void main() async {
  await TestApp.ensureInitialized();

  late Map<int, List<Ayah>> bySurah;

  setUpAll(() async {
    final raw = await rootBundle.loadString('assets/data/ayahs.json');
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    bySurah = {};
    for (final m in list) {
      final a = Ayah.fromMap(m);
      bySurah.putIfAbsent(a.surahNumber, () => []).add(a);
    }
  });

  /// Okuma ekranındaki `_indexOfAyah` ile aynı kural.
  int? indexOfAyah(List<Ayah> ayahs, int ayahNumber) {
    for (var i = 0; i < ayahs.length; i++) {
      final a = ayahs[i];
      if (ayahNumber >= a.ayahNumber && ayahNumber <= a.endAyahNumber) {
        return i + 1; // 0 = sure başlığı
      }
    }
    return null;
  }

  test('bulunan indeksteki blok istenen ayeti gerçekten kapsar', () {
    var checked = 0;
    final failures = <String>[];

    for (final entry in bySurah.entries) {
      final ayahs = entry.value;
      final lastAyah = ayahs.last.endAyahNumber;

      for (var n = 1; n <= lastAyah; n++) {
        final index = indexOfAyah(ayahs, n);
        checked++;
        if (index == null) {
          failures.add('${entry.key}:$n indeks bulunamadı');
          continue;
        }
        final block = ayahs[index - 1];
        if (n < block.ayahNumber || n > block.endAyahNumber) {
          failures.add('${entry.key}:$n -> blok ${block.numberLabel}');
        }
      }
    }

    expect(checked, greaterThan(6000));
    expect(failures, isEmpty, reason: failures.take(5).join(' | '));
  });

  test('birleşik blok içeren surelerde ayet numarası indekse eşit değildir',
      () {
    // Kaymanın gerçekten var olduğunu doğrular; olmasaydı bu dönüşüme de
    // gerek kalmazdı ve test yanlış güven verirdi.
    final shifted = <int, int>{};
    for (final entry in bySurah.entries) {
      final ayahs = entry.value;
      final drift = ayahs.last.endAyahNumber - ayahs.length;
      if (drift > 0) shifted[entry.key] = drift;
    }

    expect(shifted, isNotEmpty);
    // Sâffât en çok birleşik blok içeren suredir.
    expect(shifted[37], greaterThan(10));
  });

  test('Sâffât 100. ayet doğru bloğa iner', () {
    final ayahs = bySurah[37]!;
    final index = indexOfAyah(ayahs, 100)!;
    final block = ayahs[index - 1];

    // Ham numara indeks olarak kullanılsaydı bambaşka bir ayet açılırdı.
    expect(index, isNot(100));
    expect(block.ayahNumber, lessThanOrEqualTo(100));
    expect(block.endAyahNumber, greaterThanOrEqualTo(100));
  });

  test('sure dışındaki numara indeks üretmez', () {
    final ayahs = bySurah[1]!; // Fâtiha, 7 ayet
    expect(indexOfAyah(ayahs, 0), isNull);
    expect(indexOfAyah(ayahs, 99), isNull);
  });

  test('birleşik bloğun her ayeti aynı indekse gider', () {
    // Kullanıcı 9. ya da 10. ayeti istesin, ikisi de aynı blokta gösterilir.
    for (final ayahs in bySurah.values) {
      for (var i = 0; i < ayahs.length; i++) {
        final a = ayahs[i];
        if (!a.isRange) continue;
        for (var n = a.ayahNumber; n <= a.endAyahNumber; n++) {
          expect(indexOfAyah(ayahs, n), i + 1);
        }
      }
    }
  });
}
