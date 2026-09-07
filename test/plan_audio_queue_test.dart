import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/data/models/ayah.dart';

/// Plan gününün ses kuyruğu.
///
/// Plan okuyucusundaki `_queueFor` ile aynı kural. Kuyruk kurulumu ekranın
/// durumuna bağlı olmadığı için saf mantık olarak sınanır.
///
/// İki kural var ve ikisi de kolayca gözden kaçar:
///  1. Birleşik meal bloklarında (Alak 9-10) her ayetin ayrı ses dosyası
///     vardır; blok listesi kullanılırsa bloğun kalanı sessiz geçer.
///  2. Gün birden çok sureye yayılır; kuyruk sure sınırında durmamalı.
List<({int surah, int ayah})> queueFor(
  List<Ayah> blocks, {
  int? fromSurah,
  int? fromAyah,
}) {
  final entries = <({int surah, int ayah})>[];
  var started = fromAyah == null;

  for (final block in blocks) {
    for (var n = block.ayahNumber; n <= block.endAyahNumber; n++) {
      if (!started) {
        if (block.surahNumber == fromSurah && n == fromAyah) {
          started = true;
        } else {
          continue;
        }
      }
      entries.add((surah: block.surahNumber, ayah: n));
    }
  }
  return entries;
}

Ayah _block(int surah, int from, [int? to]) => Ayah(
  id: surah * 1000 + from,
  surahNumber: surah,
  ayahNumber: from,
  endAyahNumber: to,
  translation: 'metin',
);

void main() {
  group('tek sure', () {
    test('bütün ayetler sırayla kuyruğa girer', () {
      final q = queueFor([_block(96, 1), _block(96, 2), _block(96, 3)]);
      expect(q, [
        (surah: 96, ayah: 1),
        (surah: 96, ayah: 2),
        (surah: 96, ayah: 3),
      ]);
    });
  });

  group('birleşik bloklar', () {
    test('aralıktaki her ayet ayrı ayrı çalınır', () {
      // Alak 9-10 tek blokta gösterilir ama iki ses dosyası vardır.
      final q = queueFor([_block(96, 8), _block(96, 9, 10), _block(96, 11)]);
      expect(q, [
        (surah: 96, ayah: 8),
        (surah: 96, ayah: 9),
        (surah: 96, ayah: 10),
        (surah: 96, ayah: 11),
      ]);
    });

    test('uzun aralık tamamen açılır', () {
      final q = queueFor([_block(37, 1, 18)]);
      expect(q.length, 18);
      expect(q.first, (surah: 37, ayah: 1));
      expect(q.last, (surah: 37, ayah: 18));
    });
  });

  group('sure sınırını aşma', () {
    test('gün birden çok sureye yayılırsa kuyruk kesintisiz akar', () {
      // Plan gününün asıl farkı bu: 30 günlük planın 2. günü on altı sureye
      // yayılıyor ve kullanıcı o günü bir bütün olarak dinlemek istiyor.
      final q = queueFor([
        _block(96, 18),
        _block(96, 19),
        _block(68, 1),
        _block(68, 2),
      ]);
      expect(q, [
        (surah: 96, ayah: 18),
        (surah: 96, ayah: 19),
        (surah: 68, ayah: 1),
        (surah: 68, ayah: 2),
      ]);
    });

    test('sure sırası korunur', () {
      final q = queueFor([_block(1, 1), _block(111, 1), _block(81, 1)]);
      expect(q.map((e) => e.surah).toList(), [1, 111, 81]);
    });
  });

  group('belirli ayetten başlama', () {
    test('seçilen ayetten önceki ayetler atlanır', () {
      final q = queueFor(
        [_block(96, 1), _block(96, 2), _block(96, 3)],
        fromSurah: 96,
        fromAyah: 2,
      );
      expect(q, [(surah: 96, ayah: 2), (surah: 96, ayah: 3)]);
    });

    test('birleşik bloğun ortasından başlanabilir', () {
      // Kullanıcı 9-10 bloğuna uzun basıp "buradan dinle" derse blok başından
      // başlar; ama kuyruk 10'u da içermeli.
      final q = queueFor(
        [_block(96, 8), _block(96, 9, 10), _block(96, 11)],
        fromSurah: 96,
        fromAyah: 10,
      );
      expect(q, [(surah: 96, ayah: 10), (surah: 96, ayah: 11)]);
    });

    test('sonraki surenin ayetinden başlanabilir', () {
      final q = queueFor(
        [_block(96, 19), _block(68, 1), _block(68, 2)],
        fromSurah: 68,
        fromAyah: 1,
      );
      expect(q, [(surah: 68, ayah: 1), (surah: 68, ayah: 2)]);
    });

    test('aynı ayet numarası başka surede kuyruğu başlatmaz', () {
      // 96:1 ile 68:1 aynı ayet numarasını taşır; sure kontrolü olmasaydı
      // kuyruk yanlış yerden başlardı.
      final q = queueFor(
        [_block(96, 1), _block(96, 2), _block(68, 1)],
        fromSurah: 68,
        fromAyah: 1,
      );
      expect(q, [(surah: 68, ayah: 1)]);
    });

    test('bulunmayan başlangıç boş kuyruk verir', () {
      final q = queueFor(
        [_block(96, 1), _block(96, 2)],
        fromSurah: 96,
        fromAyah: 99,
      );
      expect(q, isEmpty);
    });
  });

  group('boş gün', () {
    test('ayet yoksa kuyruk boş', () {
      expect(queueFor([]), isEmpty);
    });
  });
}
