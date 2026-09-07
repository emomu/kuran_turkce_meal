import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../data/models/audio_download.dart';
import '../../../data/models/reciter.dart';
import '../../settings/providers/preferences_provider.dart';

/// Seçili kari. Tercih değişirse kendini yeniler.
final selectedReciterProvider = Provider<Reciter>((ref) {
  final id = ref.watch(preferencesProvider.select((p) => p.reciterId));
  return Reciter.byId(id);
});

/// İndirme mobil veri üzerinden mi yapılacak.
///
/// İndirme engellenmez, yalnızca kullanıcı uyarılır: kimin ne zaman mobil
/// verisini harcayacağına uygulama değil kullanıcı karar verir. Bağlantı
/// durumu okunamazsa uyarı gösterilmez — emin olmadan uyarmak, her indirmede
/// gereksiz bir uyarı göstermek demek olurdu.
final isOnMobileDataProvider = FutureProvider<bool>((ref) async {
  try {
    final result = await Connectivity().checkConnectivity();
    return result.contains(ConnectivityResult.mobile);
  } catch (_) {
    return false;
  }
});

/// Bir surenin ses indirme durumunu yürütür.
///
/// Sure başına ayrı bir notifier tutulur: kullanıcı bir sureyi indirirken
/// başka bir sureye bakabilmeli ve iki surenin ilerlemesi birbirine
/// karışmamalı.
class SurahDownloadNotifier extends StateNotifier<AudioDownload> {
  SurahDownloadNotifier(this._ref, this._surahNumber)
    : super(AudioDownload(surahNumber: _surahNumber)) {
    // Alanın kendisi kontrolü başlatır; burada yalnızca tetiklenir.
    _ready;
  }

  final Ref _ref;
  final int _surahNumber;

  /// Kullanıcı indirmeyi iptal etti mi. Depo her ayet öbeğinden önce sorar.
  bool _cancelled = false;

  /// İlk dosya kontrolü. Durum bu tamamlanana kadar güvenilir değil.
  ///
  /// Notifier kurulur kurulmaz `absent` durumuyla başlar ve dosya kontrolü
  /// asenkron sürer. Bu arada okunan durum "indirilmemiş" der; oynat'a basan
  /// kullanıcıya indirilmiş bir sure için yeniden indirme yaprağı açılırdı.
  late final Future<void> _ready = _refresh();

  /// Durumun diskten okunmasını bekler.
  ///
  /// Oynatmadan önce çağrılır: karar, gerçek dosya durumuna göre verilmeli.
  Future<AudioDownload> ensureLoaded() async {
    await _ready;
    return state;
  }

  /// Dosyaların cihazda olup olmadığını yeniden sorar.
  ///
  /// Kari değiştiğinde de çağrılır: aynı sure bir karide indirilmiş, diğerinde
  /// indirilmemiş olabilir.
  Future<void> _refresh() async {
    final reciter = _ref.read(selectedReciterProvider);
    final isReady = await _ref
        .read(audioRepositoryProvider)
        .isSurahDownloaded(reciter, _surahNumber);

    if (!mounted) return;
    state = AudioDownload(
      surahNumber: _surahNumber,
      status: isReady ? AudioDownloadStatus.ready : AudioDownloadStatus.absent,
    );
  }

  /// Sureyi indirir.
  ///
  /// Zaten hazırsa hiçbir şey yapmaz — kullanıcı oynat'a arka arkaya basmış
  /// olabilir ve indirilmiş bir sure tekrar indirilmemeli.
  Future<bool> download(int ayahCount) async {
    if (state.isReady || state.isDownloading) return state.isReady;

    _cancelled = false;
    state = AudioDownload(
      surahNumber: _surahNumber,
      status: AudioDownloadStatus.downloading,
      totalAyahs: ayahCount,
    );

    try {
      await _ref.read(audioRepositoryProvider).downloadSurah(
        reciter: _ref.read(selectedReciterProvider),
        surahNumber: _surahNumber,
        ayahCount: ayahCount,
        isCancelled: () => _cancelled || !mounted,
        onProgress: (completed) {
          if (!mounted) return;
          state = state.copyWith(completedAyahs: completed);
        },
      );

      if (!mounted) return false;

      // İptal edilmişse dosyalar eksik; hazır sayılmaz ama hata da değil.
      if (_cancelled) {
        state = AudioDownload(
          surahNumber: _surahNumber,
          status: AudioDownloadStatus.absent,
        );
        return false;
      }

      state = AudioDownload(
        surahNumber: _surahNumber,
        status: AudioDownloadStatus.ready,
        completedAyahs: ayahCount,
        totalAyahs: ayahCount,
      );
      return true;
    } catch (error) {
      if (!mounted) return false;
      state = state.copyWith(
        status: AudioDownloadStatus.failed,
        errorMessage: '$error',
      );
      return false;
    }
  }

  /// İndirmeyi durdurur. İnen dosyalar silinmez; sonraki denemede atlanır.
  void cancel() => _cancelled = true;

  /// Surenin ses dosyalarını siler.
  Future<void> delete() async {
    _cancelled = true;
    await _ref.read(audioRepositoryProvider).deleteSurah(
      _ref.read(selectedReciterProvider),
      _surahNumber,
    );
    if (!mounted) return;
    state = AudioDownload(
      surahNumber: _surahNumber,
      status: AudioDownloadStatus.absent,
    );
  }
}

final surahDownloadProvider =
    StateNotifierProvider.family<
      SurahDownloadNotifier,
      AudioDownload,
      int
    >((ref, surahNumber) {
      // Kari değişince indirme durumu yeniden sorulmalı; bu bağımlılık
      // notifier'ın yeniden kurulmasını sağlar.
      ref.watch(selectedReciterProvider);
      return SurahDownloadNotifier(ref, surahNumber);
    });

/// Bir ayet kümesinin indirme durumunu yürütür.
///
/// Sure indirmesinden ayrı tutuldu: plan günü on altı sureye yayılabilir ve
/// hiçbiri tam inmemiş olabilir. `.done` işaretine bakan sure mantığı burada
/// yanlış cevap verirdi — gün yalnızca kendi ayetlerini kapsar.
class AyahSetDownloadNotifier extends StateNotifier<AudioDownload> {
  AyahSetDownloadNotifier(this._ref)
    : super(const AudioDownload(surahNumber: 0));

  final Ref _ref;
  bool _cancelled = false;

  /// Verilen ayetlerden cihazda olmayanları indirir.
  ///
  /// Zaten inmiş ayetler atlanır; günlerin çakıştığı yerlerde ikinci indirme
  /// neredeyse bedavadır. Hepsi mevcutsa hiç ağa çıkılmaz.
  Future<bool> download(List<({int surah, int ayah})> entries) async {
    if (state.isDownloading) return false;

    _cancelled = false;
    final reciter = _ref.read(selectedReciterProvider);
    final repository = _ref.read(audioRepositoryProvider);

    final missing = await repository.missingAyahs(reciter, entries);
    if (!mounted) return false;

    if (missing.isEmpty) {
      state = AudioDownload(
        surahNumber: 0,
        status: AudioDownloadStatus.ready,
        completedAyahs: entries.length,
        totalAyahs: entries.length,
      );
      return true;
    }

    state = AudioDownload(
      surahNumber: 0,
      status: AudioDownloadStatus.downloading,
      totalAyahs: missing.length,
    );

    try {
      await repository.downloadAyahs(
        reciter: reciter,
        entries: missing,
        isCancelled: () => _cancelled || !mounted,
        onProgress: (completed) {
          if (!mounted) return;
          state = state.copyWith(completedAyahs: completed);
        },
      );

      if (!mounted) return false;

      if (_cancelled) {
        state = const AudioDownload(
          surahNumber: 0,
          status: AudioDownloadStatus.absent,
        );
        return false;
      }

      state = AudioDownload(
        surahNumber: 0,
        status: AudioDownloadStatus.ready,
        completedAyahs: missing.length,
        totalAyahs: missing.length,
      );
      return true;
    } catch (error) {
      if (!mounted) return false;
      state = state.copyWith(
        status: AudioDownloadStatus.failed,
        errorMessage: '$error',
      );
      return false;
    }
  }

  void cancel() => _cancelled = true;
}

/// Plan günü gibi sure sınırını aşan indirmeler için.
///
/// `autoDispose`: durum yaprağın ömrüyle sınırlı; yaprak kapandığında sıfırlanır
/// ve sonraki gün temiz bir durumla açılır.
final ayahSetDownloadProvider = StateNotifierProvider.autoDispose<
    AyahSetDownloadNotifier, AudioDownload>(
  AyahSetDownloadNotifier.new,
);

/// Bir ayet kümesinden cihazda bulunmayanların sayısı.
///
/// İndirme onayında gerçek boyutu göstermek için: gün içindeki surelerin bir
/// kısmı önceki günlerde inmiş olabilir.
final missingAyahCountProvider = FutureProvider.autoDispose
    .family<int, List<({int surah, int ayah})>>((ref, entries) async {
  final reciter = ref.watch(selectedReciterProvider);
  final missing = await ref
      .read(audioRepositoryProvider)
      .missingAyahs(reciter, entries);
  return missing.length;
});

/// Bu kari için indirilmiş surelerin numaraları. Ayarlar ekranı bunu listeler.
final downloadedSurahsProvider = FutureProvider<Set<int>>((ref) {
  final reciter = ref.watch(selectedReciterProvider);
  return ref.watch(audioRepositoryProvider).downloadedSurahs(reciter);
});

/// İndirilmiş seslerin toplam boyutu (bayt). Ayarlarda gösterilir.
final downloadedSizeProvider = FutureProvider<int>((ref) {
  final reciter = ref.watch(selectedReciterProvider);
  return ref.watch(audioRepositoryProvider).totalSizeOnDisk(reciter);
});
