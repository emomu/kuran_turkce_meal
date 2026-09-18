import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/data/models/reciter.dart';
import 'package:kuran_turkce_meal/data/repositories/segment_repository.dart';

/// Zamanlama paketi Python tarafında üretilir, Dart tarafında okunur. İki
/// uç arasındaki tek sözleşme `tool/build_segments.py` başındaki biçim
/// tarifi; bu testler o sözleşmenin tutup tutmadığını gerçek asset üzerinde
/// denetler. Paket bozulursa tilavet vurgusu sessizce yanlış yere düşerdi —
/// gözle fark edilmesi zor, testle kolay.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Gerçek asset dosyasını okur. Test ortamında `rootBundle` proje
  /// asset'lerini görmediği için dosya doğrudan diskten verilir.
  final bundle = _FileBundle('assets/data/segments.bin');

  late SegmentRepository repo;

  setUp(() async {
    repo = SegmentRepository(bundle: bundle);
    await repo.load();
  });

  test('paket okunur', () {
    expect(repo.isAvailable, isTrue);
  });

  test('uygulamanın tanıdığı her kari pakette var', () {
    // Kari listesi değişip pakete eklenmezse o kari sessizce vurgusuz
    // kalırdı; bu test ikisini birbirine bağlar.
    for (final reciter in Reciter.all) {
      final segments = repo.segmentsFor(
        reciterId: reciter.id,
        surahNumber: 1,
        ayahNumber: 1,
      );
      expect(
        segments,
        isNotNull,
        reason: '${reciter.id} için zamanlama yok',
      );
    }
  });

  test('Fatiha 1:1 dört kelimedir ve süreler artar', () {
    final segments = repo.segmentsFor(
      reciterId: 'alafasy',
      surahNumber: 1,
      ayahNumber: 1,
    )!;

    // "بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ" — dört kelime.
    expect(segments.wordCount, 4);

    var previous = -1;
    for (var i = 0; i < segments.wordCount; i++) {
      final at = segments.wordAt(_startOf(segments, i));
      expect(at, i, reason: '$i. kelimenin başı kendi indeksini vermeli');
      expect(_startOf(segments, i), greaterThan(previous));
      previous = _startOf(segments, i);
    }
  });

  test('ayet başlamadan önce vurgu yok', () {
    final segments = repo.segmentsFor(
      reciterId: 'alafasy',
      surahNumber: 1,
      ayahNumber: 1,
    )!;
    expect(segments.wordAt(0), isNull);
  });

  test('ayet bittikten sonra vurgu kalkar', () {
    final segments = repo.segmentsFor(
      reciterId: 'alafasy',
      surahNumber: 1,
      ayahNumber: 1,
    )!;
    // Son kelimenin bitişinden çok sonrası.
    expect(segments.wordAt(600000), isNull);
  });

  test('kelimeler arası sessizlikte son kelime yanık kalır', () {
    final segments = repo.segmentsFor(
      reciterId: 'alafasy',
      surahNumber: 1,
      ayahNumber: 1,
    )!;

    // İlk kelimenin bitişi ile ikincinin başı arasında boşluk varsa, o
    // aralıkta hâlâ ilk kelime vurgulu olmalı. Aksi halde vurgu her
    // kelimeden sonra sönüp yanardı.
    final gap = _startOf(segments, 1) - 1;
    expect(segments.wordAt(gap), 0);
  });

  test('bilinmeyen kari ve ayet null döner', () {
    expect(
      repo.segmentsFor(
        reciterId: 'yok_boyle_bir_kari',
        surahNumber: 1,
        ayahNumber: 1,
      ),
      isNull,
    );
    expect(
      repo.segmentsFor(
        reciterId: 'alafasy',
        surahNumber: 1,
        ayahNumber: 999,
      ),
      isNull,
    );
  });

  test('kari değişince önbellek karışmaz', () {
    // Aynı ayet iki kari için sorulur; ikisi farklı kayıtlar olduğu için
    // süreleri de farklı olmalı. Önbellek kari kimliğini gözetmeseydi
    // ikincisi birincinin değerini döndürürdü.
    final first = repo.segmentsFor(
      reciterId: 'alafasy',
      surahNumber: 2,
      ayahNumber: 255,
    )!;
    final second = repo.segmentsFor(
      reciterId: 'sudais',
      surahNumber: 2,
      ayahNumber: 255,
    )!;

    expect(first.wordCount, second.wordCount);
    expect(
      _startOf(first, first.wordCount - 1),
      isNot(_startOf(second, second.wordCount - 1)),
      reason: 'iki kari aynı ayeti aynı anda bitiremez',
    );
  });

  test('paket yoksa vurgu kapanır, istisna atılmaz', () async {
    final missing = SegmentRepository(bundle: _FileBundle('yok/olmayan.bin'));
    await missing.load();

    expect(missing.isAvailable, isFalse);
    expect(
      missing.segmentsFor(
        reciterId: 'alafasy',
        surahNumber: 1,
        ayahNumber: 1,
      ),
      isNull,
    );
  });

  test('geniş örneklemde zaman ekseni geri sarmaz', () {
    // Bozuk bir segment vurguyu geri sıçratır. Kaynak veride birkaç tane
    // vardı; üretim aracı bunları düzeltiyor. Bu test düzeltmenin
    // pakette gerçekten durduğunu doğrular.
    for (final reciter in Reciter.all) {
      for (var surah = 1; surah <= 114; surah += 7) {
        for (var ayah = 1; ayah <= 5; ayah++) {
          final segments = repo.segmentsFor(
            reciterId: reciter.id,
            surahNumber: surah,
            ayahNumber: ayah,
          );
          if (segments == null) continue;

          var previous = -1;
          for (var i = 0; i < segments.wordCount; i++) {
            final start = _startOf(segments, i);
            expect(
              start,
              greaterThanOrEqualTo(previous),
              reason: '${reciter.id} $surah:$ayah kelime $i geri sardı',
            );
            previous = start;
          }
        }
      }
    }
  });
}

/// Bir kelimenin başlangıç anını [AyahSegments.wordAt] üzerinden arar.
///
/// Başlangıçlar dışarıya açılmadı: dışarıdan yalnızca "şu anda hangi
/// kelime" sorusu sorulur. Test de aynı kapıdan geçsin diye başlangıç,
/// indeksin değiştiği ilk ana bakılarak bulunur.
int _startOf(AyahSegments segments, int index) {
  // İkili arama kullanılamaz: `wordAt` ayet bitiminden sonra da null döner,
  // yani null "henüz gelmedi" anlamına gelmez. Tarama, adımı veri
  // çözünürlüğüne (20 ms) eşit tutarak yapılır.
  for (var ms = 0; ms <= 600000; ms += 20) {
    if (segments.wordAt(ms) == index) return ms;
  }
  fail('$index. kelimenin başlangıcı bulunamadı');
}

/// Testte gerçek dosyayı okuyan basit bir bundle.
class _FileBundle extends CachingAssetBundle {
  _FileBundle(this.path);

  final String path;

  @override
  Future<ByteData> load(String key) async {
    final file = File(path);
    if (!file.existsSync()) {
      throw FlutterError('Asset bulunamadı: $path');
    }
    return ByteData.sublistView(await file.readAsBytes());
  }
}
