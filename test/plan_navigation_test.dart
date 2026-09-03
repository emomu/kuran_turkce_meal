import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/localized_app.dart';

/// Okuma planındaki gün → ayet eşlemesi.
///
/// Plan günleri global ayet kimliği aralığı taşır. Kimlikler sure künyesindeki
/// `ayahCount` üzerinden hesaplanamaz: birleşik meal bloklarında bir kayıt
/// birden çok ayeti kapsar, bu yüzden kayıt sayısı ayet sayısından azdır ve
/// fark sure sure birikir. Hesaplamaya güvenildiğinde kullanıcı iniş sırasında
/// Alak'a dokunup Âdiyât'a düşüyordu.
void main() async {
  await TestApp.ensureInitialized();

  late List<({int id, int surahNumber, int ayahNumber})> index;
  late Map<int, int> ayahCountByNumber;
  late Map<int, int> revelationByNumber;

  setUpAll(() async {
    final rawAyahs = await rootBundle.loadString('assets/data/ayahs.json');
    index = [
      for (final m in (jsonDecode(rawAyahs) as List).cast<Map<String, dynamic>>())
        (
          id: m['id'] as int,
          surahNumber: m['surah_number'] as int,
          ayahNumber: m['ayah_number'] as int,
        ),
    ];

    final rawSurahs = await rootBundle.loadString('assets/data/surahs.json');
    final surahMaps =
        (jsonDecode(rawSurahs) as List).cast<Map<String, dynamic>>();
    ayahCountByNumber = {
      for (final m in surahMaps) m['number'] as int: m['ayah_count'] as int,
    };
    revelationByNumber = {
      for (final m in surahMaps)
        m['number'] as int: m['revelation_order'] as int,
    };
  });

  test('kayıt sayısı ayet sayısından az olduğu için kimlik kayması gerçektir',
      () {
    // Hatanın kaynağı: künyeden hesaplanan kimlik ile gerçek kimlik ayrışır.
    var runningId = 1;
    final drift = <int, int>{};

    for (var n = 1; n <= 114; n++) {
      final calculated = runningId;
      final real = index.firstWhere((r) => r.surahNumber == n).id;
      if (calculated != real) drift[n] = calculated - real;
      runningId += ayahCountByNumber[n]!;
    }

    expect(drift, isNotEmpty, reason: 'kayma yoksa bu dönüşüme gerek kalmaz');
    // Alak'a gelindiğinde fark onlarca kaydı bulur.
    expect(drift[96]!, greaterThan(40));
  });

  test('gerçek kimlik doğru sureye çözülür', () {
    // Alak (96) kimliği Alak'ı açmalı; hesaplanan kimlik Âdiyât'a düşüyordu.
    final alakStart = index.firstWhere((r) => r.surahNumber == 96);
    expect(alakStart.surahNumber, 96);
    expect(alakStart.ayahNumber, 1);

    // Aynı konum künyeden hesaplansaydı başka bir sureye denk gelirdi.
    var runningId = 1;
    for (var n = 1; n < 96; n++) {
      runningId += ayahCountByNumber[n]!;
    }
    final wrong = index.firstWhere((r) => r.id == runningId);
    expect(wrong.surahNumber, isNot(96),
        reason: 'eski hesap doğru çıkarsa bu test hatayı yakalayamaz');
  });

  test('her sure kaydı kendi suresine çözülür', () {
    // Plan hangi sureden başlarsa başlasın, ilk kaydı o sureyi açmalı.
    for (var n = 1; n <= 114; n++) {
      final first = index.firstWhere((r) => r.surahNumber == n);
      expect(first.surahNumber, n);
      expect(first.ayahNumber, 1);
    }
  });

  test('kimlikler kesintisiz ve artan sırada', () {
    // Plan günleri aralık olarak verilir; boşluk olsaydı gün sınırları kayardı.
    for (var i = 0; i < index.length; i++) {
      expect(index[i].id, i + 1);
    }
  });

  test('iniş sırasında dizilen kayıtlar tüm Kuran kayıtlarını kapsar', () {
    final bySurah = <int, List<int>>{};
    for (final row in index) {
      bySurah.putIfAbsent(row.surahNumber, () => []).add(row.id);
    }

    // Plan sıralaması sureleri yeniden dizer; hiçbir kayıt düşmemeli.
    final total = bySurah.values.fold<int>(0, (sum, ids) => sum + ids.length);
    expect(total, index.length);
    expect(bySurah.keys.length, 114);
  });

  test('gün kimlikleri aralık olarak verilemez', () {
    // İniş sırasında bir gün mushafta bitişik olmayan sureleri kapsayabilir.
    // Aralık (min..max) kullanılsaydı arada kalan bütün sureler de o güne
    // dahil olurdu; ölçüldüğünde en kötü gün 17 ayet yerine binlercesini
    // getiriyordu. Bu yüzden PlanDay kimlik listesi taşır.
    final bySurah = <int, List<int>>{};
    for (final row in index) {
      bySurah.putIfAbsent(row.surahNumber, () => []).add(row.id);
    }

    // İniş sırasına göre diz.
    final revelationOrder = [
      for (final e in revelationByNumber.entries) (e.key, e.value),
    ]..sort((a, b) => a.$2.compareTo(b.$2));

    final sequence = <int>[];
    for (final (number, _) in revelationOrder) {
      sequence.addAll(bySurah[number] ?? const []);
    }

    const dayCount = 365;
    final perDay = (sequence.length / dayCount).ceil();
    var daysWhereRangeWouldOverreach = 0;

    for (var d = 0; d < dayCount; d++) {
      final from = d * perDay;
      if (from >= sequence.length) break;
      final to = ((d + 1) * perDay - 1).clamp(0, sequence.length - 1);

      final ids = sequence.sublist(from, to + 1);
      final lo = ids.reduce((a, b) => a < b ? a : b);
      final hi = ids.reduce((a, b) => a > b ? a : b);
      // Aralık, listedekinden fazlasını kapsıyorsa eski yöntem hatalıydı.
      if (hi - lo + 1 != ids.length) daysWhereRangeWouldOverreach++;
    }

    expect(daysWhereRangeWouldOverreach, greaterThan(50),
        reason: 'aralık yöntemi hatasızsa bu testin koruduğu şey yok');
  });
}
