import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/data/models/reciter.dart';

void main() {
  group('Reciter dosya adı', () {
    test('sure ve ayet numarasını üçer haneye tamamlar', () {
      expect(Reciter.fileName(1, 1), '001001.mp3');
      expect(Reciter.fileName(2, 255), '002255.mp3');
      expect(Reciter.fileName(114, 6), '114006.mp3');
    });

    test('üç haneli sayıları bozmaz', () {
      // Bakara'nın 286 ayeti var; en uzun sure üç haneyi tam doldurur ve
      // dolgu fazladan hane eklememeli.
      expect(Reciter.fileName(2, 286), '002286.mp3');
    });

    test('adres kök adresle dosya adını birleştirir', () {
      const reciter = Reciter(
        id: 'test',
        name: 'Test',
        baseUrl: 'https://example.com/data/Test/',
        approximateBytesPerAyah: 1000,
      );

      expect(
        reciter.urlFor(96, 1),
        'https://example.com/data/Test/096001.mp3',
      );
    });
  });

  group('Reciter.byId', () {
    test('bilinen kimliği bulur', () {
      expect(Reciter.byId('husary').id, 'husary');
    });

    test('tanınmayan kimlikte varsayılana düşer', () {
      // Kullanıcının kayıtlı tercihi, uygulama güncellemesiyle listeden
      // kaldırılmış bir kariyi gösteriyor olabilir. Hata vermek yerine
      // varsayılanla devam edilmeli; kullanıcı sesin çalmasını bekler.
      expect(Reciter.byId('kaldirilmis-kari').id, Reciter.fallback.id);
    });

    test('null kimlikte varsayılana düşer', () {
      expect(Reciter.byId(null).id, Reciter.fallback.id);
    });
  });

  group('Reciter listesi', () {
    test('varsayılan kari listenin ilk öğesiyle aynı', () {
      // İkisi ayrı yazıldı (sabit bağlamda `first` çağrılamıyor); ayrışırlarsa
      // ayarlar ekranında hiçbir seçenek işaretli görünmezdi.
      expect(Reciter.fallback.id, Reciter.all.first.id);
      expect(Reciter.fallback.baseUrl, Reciter.all.first.baseUrl);
    });

    test('kimlikler benzersiz', () {
      // Kimlik dosya sisteminde klasör adı; çakışan iki kari aynı klasörü
      // paylaşır ve birinin sesi diğerininmiş gibi çalardı.
      final ids = Reciter.all.map((r) => r.id).toSet();
      expect(ids.length, Reciter.all.length);
    });

    test('kök adresler eğik çizgiyle biter', () {
      // Bitmezse dosya adı doğrudan eklenir ve adres bozulur.
      for (final reciter in Reciter.all) {
        expect(reciter.baseUrl.endsWith('/'), isTrue, reason: reciter.id);
      }
    });

    test('boyut tahmini ayet sayısıyla orantılı', () {
      final reciter = Reciter.fallback;
      final fatiha = reciter.estimatedBytesFor(7);
      final bakara = reciter.estimatedBytesFor(286);

      expect(bakara, greaterThan(fatiha));
      expect(bakara, reciter.approximateBytesPerAyah * 286);
    });
  });
}
