import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/data/models/audio_download.dart';
import 'package:kuran_turkce_meal/data/models/ayah.dart';
import 'package:kuran_turkce_meal/features/audio/providers/audio_provider.dart';

/// Tekil ayet bloğu.
const _single = Ayah(
  id: 1,
  surahNumber: 96,
  ayahNumber: 1,
  translation: 'Yaratan Rabbinin adıyla oku.',
);

/// Birleşik meal bloğu: 9 ve 10. ayetler tek metinde karşılanmış.
const _range = Ayah(
  id: 9,
  surahNumber: 96,
  ayahNumber: 9,
  endAyahNumber: 10,
  translation: 'Gördün mü şu men edeni, namaz kıldığında bir kulu?',
);

void main() {
  group('AudioState.isBlockActive', () {
    test('çalan ayet bloğun kendisiyse etkin', () {
      const state = AudioState(surahNumber: 96, currentAyahNumber: 1);
      expect(state.isBlockActive(_single, 96), isTrue);
    });

    test('başka ayet çalıyorsa etkin değil', () {
      const state = AudioState(surahNumber: 96, currentAyahNumber: 2);
      expect(state.isBlockActive(_single, 96), isFalse);
    });

    test('birleşik blok, aralığın ilk ayeti çalarken etkin', () {
      const state = AudioState(surahNumber: 96, currentAyahNumber: 9);
      expect(state.isBlockActive(_range, 96), isTrue);
    });

    test('birleşik blok, aralığın son ayeti çalarken de etkin', () {
      // Asıl sınama bu: ses 10. ayete geçtiğinde vurgu bloğun üstünde
      // kalmalı. Numara eşitliğiyle karşılaştırılsaydı vurgu bloğun
      // ortasında kaybolur, kullanıcı okuduğu satırı yitirirdi.
      const state = AudioState(surahNumber: 96, currentAyahNumber: 10);
      expect(state.isBlockActive(_range, 96), isTrue);
    });

    test('aralığın dışındaki ayet bloğu etkinleştirmez', () {
      const state = AudioState(surahNumber: 96, currentAyahNumber: 11);
      expect(state.isBlockActive(_range, 96), isFalse);
    });

    test('başka surede çalıyorsa etkin değil', () {
      // Plan okuyucusunda ekranda birden çok surenin ayetleri yan yana
      // durabilir; sure kontrolü olmasaydı 2:9 çalarken 96:9 da vurgulanırdı.
      const state = AudioState(surahNumber: 2, currentAyahNumber: 9);
      expect(state.isBlockActive(_range, 96), isFalse);
    });

    test('ses kapalıyken hiçbir blok etkin değil', () {
      const state = AudioState();
      expect(state.isBlockActive(_single, 96), isFalse);
      expect(state.isBlockActive(_range, 96), isFalse);
    });
  });

  group('AudioState.isActive', () {
    test('sure atanmışsa etkin', () {
      expect(const AudioState(surahNumber: 1).isActive, isTrue);
    });

    test('boş durumda etkin değil', () {
      expect(const AudioState().isActive, isFalse);
    });
  });

  group('AudioDownload', () {
    test('ilerleme oranı tamamlanan / toplam', () {
      const download = AudioDownload(
        surahNumber: 2,
        status: AudioDownloadStatus.downloading,
        completedAyahs: 143,
        totalAyahs: 286,
      );
      expect(download.progress, closeTo(0.5, 0.001));
    });

    test('toplam bilinmiyorsa ilerleme sıfır', () {
      // Sıfıra bölme yapılmamalı; indirme başlamadan önce toplam bilinmez.
      const download = AudioDownload(surahNumber: 2);
      expect(download.progress, 0);
    });

    test('ilerleme 1 değerini aşmaz', () {
      const download = AudioDownload(
        surahNumber: 1,
        completedAyahs: 9,
        totalAyahs: 7,
      );
      expect(download.progress, 1);
    });

    test('durum bayrakları birbirini dışlar', () {
      const ready = AudioDownload(
        surahNumber: 1,
        status: AudioDownloadStatus.ready,
      );
      expect(ready.isReady, isTrue);
      expect(ready.isDownloading, isFalse);
      expect(ready.hasFailed, isFalse);
    });

    test('copyWith hata mesajını taşımaz', () {
      // Hata mesajı bilerek taşınmaz: yeni bir duruma geçildiğinde eski hata
      // ekranda kalırsa kullanıcı çözülmüş bir sorunu görmeye devam eder.
      const failed = AudioDownload(
        surahNumber: 1,
        status: AudioDownloadStatus.failed,
        errorMessage: 'bağlantı yok',
      );

      final retried = failed.copyWith(
        status: AudioDownloadStatus.downloading,
      );

      expect(retried.errorMessage, isNull);
      expect(retried.status, AudioDownloadStatus.downloading);
    });

    test('copyWith sure numarasını korur', () {
      const download = AudioDownload(surahNumber: 36);
      expect(download.copyWith(completedAyahs: 5).surahNumber, 36);
    });

    test('hazır sure yeniden indirme istemez', () {
      // İndirilmiş bir surede oynat'a basınca indirme yaprağı açılmamalı.
      // Bu bayrak `_startAudio`'nun kararını verdiği yer.
      const ready = AudioDownload(
        surahNumber: 68,
        status: AudioDownloadStatus.ready,
      );
      expect(ready.isReady, isTrue);
    });

    test('indirme sürerken hazır sayılmaz', () {
      // Yaprak indirme boyunca açık kalır; bu durumda "indir" düğmesi değil
      // ilerleme çubuğu gösterilir.
      const downloading = AudioDownload(
        surahNumber: 68,
        status: AudioDownloadStatus.downloading,
        completedAyahs: 42,
        totalAyahs: 52,
      );
      expect(downloading.isReady, isFalse);
      expect(downloading.isDownloading, isTrue);
      expect(downloading.progress, closeTo(0.807, 0.01));
    });
  });
}
