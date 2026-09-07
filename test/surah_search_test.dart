import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kuran_turkce_meal/data/models/surah.dart';
import 'package:kuran_turkce_meal/features/home/providers/home_provider.dart';

const _surahs = <Surah>[
  Surah(
    number: 1,
    name: 'Fâtiha',
    nameEn: 'Al-Fatihah',
    meaning: 'Açılış',
    meaningEn: 'The Opening',
    revelationOrder: 5,
    revelationPlace: RevelationPlace.mekke,
    ayahCount: 7,
  ),
  Surah(
    number: 2,
    name: 'Bakara',
    nameEn: 'Al-Baqarah',
    meaning: 'İnek',
    meaningEn: 'The Cow',
    revelationOrder: 87,
    revelationPlace: RevelationPlace.medine,
    ayahCount: 286,
  ),
  Surah(
    number: 36,
    name: 'Yâsîn',
    nameEn: 'Ya-Sin',
    meaning: 'Yâsîn',
    meaningEn: 'Ya-Sin',
    revelationOrder: 41,
    revelationPlace: RevelationPlace.mekke,
    ayahCount: 83,
  ),
  Surah(
    number: 96,
    name: 'Alak',
    nameEn: 'Al-Alaq',
    meaning: 'Kan Pıhtısı',
    meaningEn: 'The Clot',
    revelationOrder: 1,
    revelationPlace: RevelationPlace.mekke,
    ayahCount: 19,
  ),
];

void main() {
  group('sure süzme', () {
    test('boş sorgu tüm listeyi verir', () async {
      final container = ProviderContainer(
        overrides: [
          surahListProvider.overrideWith((ref) async => _surahs),
        ],
      );
      addTearDown(container.dispose);

      await container.read(surahListProvider.future);
      final result = container.read(filteredSurahListProvider).valueOrNull;

      expect(result, hasLength(_surahs.length));
    });

    test('ada göre eşleşir', () async {
      final container = ProviderContainer(
        overrides: [surahListProvider.overrideWith((ref) async => _surahs)],
      );
      addTearDown(container.dispose);
      await container.read(surahListProvider.future);

      container.read(surahQueryProvider.notifier).state = 'bakara';
      final result = container.read(filteredSurahListProvider).valueOrNull!;

      expect(result, hasLength(1));
      expect(result.single.number, 2);
    });

    test('şapkalı harf olmadan da bulunur', () async {
      // Kullanıcı klavyesinde "â" yoktur; "yasin" yazıp Yâsîn'i bulmalı.
      final container = ProviderContainer(
        overrides: [surahListProvider.overrideWith((ref) async => _surahs)],
      );
      addTearDown(container.dispose);
      await container.read(surahListProvider.future);

      container.read(surahQueryProvider.notifier).state = 'yasin';
      final result = container.read(filteredSurahListProvider).valueOrNull!;

      expect(result.single.number, 36);
    });

    test('büyük harf ve Türkçe i ayrımı sorun çıkarmaz', () async {
      // "İNEK" -> "inek": Dart'ın varsayılan toLowerCase'i burada yanılır.
      final container = ProviderContainer(
        overrides: [surahListProvider.overrideWith((ref) async => _surahs)],
      );
      addTearDown(container.dispose);
      await container.read(surahListProvider.future);

      container.read(surahQueryProvider.notifier).state = 'İNEK';
      final result = container.read(filteredSurahListProvider).valueOrNull!;

      expect(result.single.number, 2);
    });

    test('anlamına göre eşleşir', () async {
      final container = ProviderContainer(
        overrides: [surahListProvider.overrideWith((ref) async => _surahs)],
      );
      addTearDown(container.dispose);
      await container.read(surahListProvider.future);

      container.read(surahQueryProvider.notifier).state = 'açılış';
      final result = container.read(filteredSurahListProvider).valueOrNull!;

      expect(result.single.number, 1);
    });

    test('mushaf numarasına göre eşleşir', () async {
      // "36" yazan kullanıcı Yâsîn'i arıyordur.
      final container = ProviderContainer(
        overrides: [surahListProvider.overrideWith((ref) async => _surahs)],
      );
      addTearDown(container.dispose);
      await container.read(surahListProvider.future);

      container.read(surahQueryProvider.notifier).state = '36';
      final result = container.read(filteredSurahListProvider).valueOrNull!;

      expect(result.single.number, 36);
    });

    test('İngilizce ada göre eşleşir', () async {
      final container = ProviderContainer(
        overrides: [surahListProvider.overrideWith((ref) async => _surahs)],
      );
      addTearDown(container.dispose);
      await container.read(surahListProvider.future);

      container.read(surahQueryProvider.notifier).state = 'baqarah';
      final result = container.read(filteredSurahListProvider).valueOrNull!;

      expect(result.single.number, 2);
    });

    test('eşleşme yoksa boş liste döner', () async {
      final container = ProviderContainer(
        overrides: [surahListProvider.overrideWith((ref) async => _surahs)],
      );
      addTearDown(container.dispose);
      await container.read(surahListProvider.future);

      container.read(surahQueryProvider.notifier).state = 'zzzz';
      final result = container.read(filteredSurahListProvider).valueOrNull!;

      expect(result, isEmpty);
    });

    test('yalnızca boşluk içeren sorgu süzmez', () async {
      final container = ProviderContainer(
        overrides: [surahListProvider.overrideWith((ref) async => _surahs)],
      );
      addTearDown(container.dispose);
      await container.read(surahListProvider.future);

      container.read(surahQueryProvider.notifier).state = '   ';
      final result = container.read(filteredSurahListProvider).valueOrNull!;

      expect(result, hasLength(_surahs.length));
    });

    test('kısmi eşleşme çalışır', () async {
      final container = ProviderContainer(
        overrides: [surahListProvider.overrideWith((ref) async => _surahs)],
      );
      addTearDown(container.dispose);
      await container.read(surahListProvider.future);

      container.read(surahQueryProvider.notifier).state = 'ala';
      final result = container.read(filteredSurahListProvider).valueOrNull!;

      expect(result.map((s) => s.number), contains(96));
    });
  });
}
