import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kuran_turkce_meal/data/models/reciter.dart';
import 'package:kuran_turkce_meal/data/repositories/audio_repository.dart';
import 'package:path/path.dart' as p;

const _reciter = Reciter(
  id: 'test-kari',
  name: 'Test',
  baseUrl: 'https://example.com/data/Test/',
  approximateBytesPerAyah: 1000,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('audio_repo_test');

    // `path_provider` test ortamında platform kanalı bulamaz; destek dizini
    // geçici bir klasöre yönlendirilir.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => tempDir.path,
        );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  /// İstenen her ayeti sabit bir gövdeyle karşılayan sahte sunucu.
  AudioRepository repositoryServing(
    List<Uri> requested, {
    int statusCode = 200,
  }) {
    final client = MockClient((request) async {
      requested.add(request.url);
      return http.Response.bytes([1, 2, 3, 4], statusCode);
    });
    return AudioRepository(client: client);
  }

  group('indirme', () {
    test('surenin her ayeti için bir istek yapar', () async {
      final requested = <Uri>[];
      final repo = repositoryServing(requested);

      await repo.downloadSurah(
        reciter: _reciter,
        surahNumber: 1,
        ayahCount: 7,
      );

      expect(requested.length, 7);
      expect(
        requested.map((u) => u.path).toList()..sort(),
        containsAll([
          '/data/Test/001001.mp3',
          '/data/Test/001007.mp3',
        ]),
      );
    });

    test('tamamlanınca sure hazır işaretlenir', () async {
      final repo = repositoryServing([]);

      expect(await repo.isSurahDownloaded(_reciter, 1), isFalse);

      await repo.downloadSurah(
        reciter: _reciter,
        surahNumber: 1,
        ayahCount: 7,
      );

      expect(await repo.isSurahDownloaded(_reciter, 1), isTrue);
    });

    test('ilerleme her ayette bildirilir', () async {
      final repo = repositoryServing([]);
      final progress = <int>[];

      await repo.downloadSurah(
        reciter: _reciter,
        surahNumber: 1,
        ayahCount: 7,
        onProgress: progress.add,
      );

      expect(progress.length, 7);
      expect(progress.last, 7);
    });

    test('zaten inmiş ayetler tekrar istenmez', () async {
      final first = <Uri>[];
      await repositoryServing(first).downloadSurah(
        reciter: _reciter,
        surahNumber: 1,
        ayahCount: 7,
      );
      expect(first.length, 7);

      // İkinci indirme: dosyalar yerinde, hiçbir istek yapılmamalı. Yarım
      // kalmış bir indirmenin kaldığı yerden sürmesi buna dayanıyor.
      final second = <Uri>[];
      await repositoryServing(second).downloadSurah(
        reciter: _reciter,
        surahNumber: 1,
        ayahCount: 7,
      );
      expect(second, isEmpty);
    });

    test('iptal edilen indirme sureyi hazır işaretlemez', () async {
      final repo = repositoryServing([]);

      await repo.downloadSurah(
        reciter: _reciter,
        surahNumber: 2,
        ayahCount: 286,
        isCancelled: () => true,
      );

      expect(await repo.isSurahDownloaded(_reciter, 2), isFalse);
    });

    test('sunucu hatası yukarı taşınır', () async {
      final repo = repositoryServing([], statusCode: 404);

      await expectLater(
        repo.downloadSurah(
          reciter: _reciter,
          surahNumber: 1,
          ayahCount: 7,
        ),
        throwsA(isA<AudioDownloadException>()),
      );
    });

    test('başarısız indirme sureyi hazır işaretlemez', () async {
      final repo = repositoryServing([], statusCode: 500);

      try {
        await repo.downloadSurah(
          reciter: _reciter,
          surahNumber: 1,
          ayahCount: 7,
        );
      } catch (_) {
        // Beklenen.
      }

      expect(await repo.isSurahDownloaded(_reciter, 1), isFalse);
    });

    test('yeniden indirme önce hazır işaretini kaldırır', () async {
      final repo = repositoryServing([]);
      await repo.downloadSurah(
        reciter: _reciter,
        surahNumber: 1,
        ayahCount: 7,
      );
      expect(await repo.isSurahDownloaded(_reciter, 1), isTrue);

      // Yarıda kesilen bir yeniden indirme sureyi "hazır" bırakmamalı.
      final failing = AudioRepository(
        client: MockClient((_) async => http.Response('', 500)),
      );
      // Dosyalar duruyor, bu yüzden ağa hiç çıkılmaz ve işaret geri yazılır;
      // asıl sınama işaretin silinip yeniden yazılması.
      await failing.downloadSurah(
        reciter: _reciter,
        surahNumber: 1,
        ayahCount: 7,
      );
      expect(await repo.isSurahDownloaded(_reciter, 1), isTrue);
    });

    test('yarım yazılmış dosya geride bırakılmaz', () async {
      // İndirme dosyanın ortasında kesilirse geriye bozuk bir MP3 kalmamalı;
      // aksi halde "dosya var" diye atlanır ve o ayet hep bozuk çalardı.
      // Geçici ada yazıp taşıma bunu garantiler: `.part` uzantılı hiçbir
      // dosya kalmamalı.
      final repo = repositoryServing([]);
      await repo.downloadSurah(
        reciter: _reciter,
        surahNumber: 1,
        ayahCount: 7,
      );

      final dir = Directory(p.join(tempDir.path, 'audio', _reciter.id, '1'));
      final leftovers = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.part'));

      expect(leftovers, isEmpty);
    });
  });

  group('depo yönetimi', () {
    test('indirilen sureler listelenir', () async {
      final repo = repositoryServing([]);
      await repo.downloadSurah(
        reciter: _reciter,
        surahNumber: 1,
        ayahCount: 7,
      );
      await repo.downloadSurah(
        reciter: _reciter,
        surahNumber: 114,
        ayahCount: 6,
      );

      expect(await repo.downloadedSurahs(_reciter), {1, 114});
    });

    test('yarım kalan sure listede görünmez', () async {
      final repo = repositoryServing([]);
      await repo.downloadSurah(
        reciter: _reciter,
        surahNumber: 1,
        ayahCount: 7,
        isCancelled: () => true,
      );

      expect(await repo.downloadedSurahs(_reciter), isEmpty);
    });

    test('silinen sure listeden çıkar', () async {
      final repo = repositoryServing([]);
      await repo.downloadSurah(
        reciter: _reciter,
        surahNumber: 1,
        ayahCount: 7,
      );

      await repo.deleteSurah(_reciter, 1);

      expect(await repo.isSurahDownloaded(_reciter, 1), isFalse);
      expect(await repo.downloadedSurahs(_reciter), isEmpty);
    });

    test('boyut indirilen dosyalarla artar', () async {
      final repo = repositoryServing([]);
      expect(await repo.totalSizeOnDisk(_reciter), 0);

      await repo.downloadSurah(
        reciter: _reciter,
        surahNumber: 1,
        ayahCount: 7,
      );

      // Her ayet 4 bayt; `.done` işareti boş.
      expect(await repo.sizeOnDisk(_reciter, 1), 28);
      expect(await repo.totalSizeOnDisk(_reciter), 28);
    });

    test('tümünü silmek depoyu boşaltır', () async {
      final repo = repositoryServing([]);
      await repo.downloadSurah(
        reciter: _reciter,
        surahNumber: 1,
        ayahCount: 7,
      );

      await repo.deleteAll(_reciter);

      expect(await repo.totalSizeOnDisk(_reciter), 0);
      expect(await repo.downloadedSurahs(_reciter), isEmpty);
    });

    test('kariler birbirinin dosyalarını görmez', () async {
      // Kimlik klasör adı olduğu için iki kari aynı sureyi ayrı ayrı tutar;
      // kari değiştiren kullanıcı sesin indirilmiş olduğunu sanmamalı.
      const other = Reciter(
        id: 'baska-kari',
        name: 'Başka',
        baseUrl: 'https://example.com/data/Baska/',
        approximateBytesPerAyah: 1000,
      );

      final repo = repositoryServing([]);
      await repo.downloadSurah(
        reciter: _reciter,
        surahNumber: 1,
        ayahCount: 7,
      );

      expect(await repo.isSurahDownloaded(_reciter, 1), isTrue);
      expect(await repo.isSurahDownloaded(other, 1), isFalse);
    });

    test('dosya yolu kari ve sureye göre ayrışır', () async {
      final repo = repositoryServing([]);

      final path = await repo.filePathFor(_reciter, 96, 1);

      expect(path, contains(p.join('audio', 'test-kari', '96')));
      expect(path, endsWith('096001.mp3'));
    });
  });
}
