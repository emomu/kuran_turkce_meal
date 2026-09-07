import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../../core/providers/app_providers.dart';
import '../../../data/models/ayah.dart';
import '../../../data/models/reciter.dart';
import '../../../data/models/surah.dart';
import '../../settings/providers/preferences_provider.dart';
import '../../reader/providers/reader_provider.dart';

/// Tilavet oynatıcısının durumu.
///
/// Arayüzün ihtiyaç duyduğu her şey tek nesnede toplanır: hangi sure çalıyor,
/// hangi ayette, çalıyor mu duraklamış mı. Okuma ekranı bunu izleyip çalan
/// ayeti vurgular ve listeyi ona kaydırır.
class AudioState {
  const AudioState({
    this.surahNumber,
    this.currentAyahNumber,
    this.isPlaying = false,
    this.isLoading = false,
    this.speed = 1.0,
    this.errorMessage,
  });

  /// Çalınan ayetin suresi. Ses kapalıyken null.
  ///
  /// Kuyruğun tamamının suresi değil, o an duyulan ayetinki: plan gününde
  /// kuyruk birden çok sureye yayılır ve çalarken sure değişir.
  final int? surahNumber;

  /// Çalınan ayetin sure içindeki numarası.
  ///
  /// Birleşik meal bloklarında bu, o an duyulan ayettir — bloğun ilki
  /// olmayabilir. Vurgulama bloğun tamamını kapsar, bkz. [AudioState.isBlockActive].
  final int? currentAyahNumber;

  final bool isPlaying;

  /// Kuyruk hazırlanıyor ya da ilk ayet tamponlanıyor.
  final bool isLoading;

  final double speed;

  final String? errorMessage;

  /// Ses şu an bu ekranda etkin mi — çubuk buna göre görünür.
  bool get isActive => surahNumber != null;

  /// Verilen ayet bloğu şu an çalıyor mu.
  ///
  /// Blok karşılaştırması numara eşitliğiyle yapılamaz: birleşik meallerde bir
  /// blok birden çok ayeti kapsar (örn. Alak 9-10) ve o blok çalarken duyulan
  /// ayet 9 ya da 10 olabilir. İkisinde de aynı blok vurgulanmalı, aksi halde
  /// vurgu bloğun ortasında kaybolurdu.
  bool isBlockActive(Ayah ayah, int forSurah) {
    final current = currentAyahNumber;
    if (current == null || surahNumber != forSurah) return false;
    return current >= ayah.ayahNumber && current <= ayah.endAyahNumber;
  }
}

/// Tilaveti çalar.
///
/// Ayet dosyaları ayrı ayrı indirilir ama tek bir kesintisiz akış gibi çalınır:
/// [ConcatenatingAudioSource] sıradaki ayeti önceden tamponlar, aradaki geçiş
/// duyulmaz. Dosyaların ayrı olması sayesinde de metin ile ses tam senkron
/// kalır — tek dosya olsaydı hangi saniyede hangi ayetin okunduğunu bilmek
/// için ayrı bir zaman damgası verisi gerekirdi.
class AudioNotifier extends StateNotifier<AudioState> {
  AudioNotifier(this._ref) : super(const AudioState()) {
    _attachPlayer();
  }

  final Ref _ref;
  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<int?>? _indexSub;
  StreamSubscription<PlayerState>? _stateSub;

  /// Kuyruktaki her öğenin sure ve ayet numarası.
  ///
  /// Kuyruk indeksi ayet numarasına eşit değildir: kuyruk seçilen ayetten
  /// başlayabilir ve plan gününde birden çok sureye yayılır. Eşleme burada
  /// tutulur.
  List<({int surah, int ayah})> _queue = const [];

  bool _sessionConfigured = false;

  /// Çalma isteklerini ayırt eder.
  ///
  /// Kuyruk hazırlanması ayet sayısıyla orantılı sürer (her ayet için dosya
  /// yolu çözülür). Kullanıcı bu sırada başka bir şey başlatırsa eski istek
  /// tamamlanıp yeni kuyruğun üstüne yazabilirdi.
  int _playToken = 0;

  void _attachPlayer() {
    // Çalan öğe değiştikçe durum güncellenir; okuma ekranı bunu dinleyip
    // vurguyu ve kaydırmayı takip eder.
    _indexSub = _player.currentIndexStream.listen((index) {
      if (index == null || index >= _queue.length) return;
      final entry = _queue[index];
      // Sure de güncellenir: plan gününde kuyruk sure sınırını aşarak akar ve
      // vurgu ancak doğru sureyle birlikte doğru ayete düşer.
      state = AudioState(
        surahNumber: entry.surah,
        currentAyahNumber: entry.ayah,
        isPlaying: state.isPlaying,
        speed: state.speed,
      );
    });

    _stateSub = _player.playerStateStream.listen((playerState) {
      // Sure bitti: ses durur ve çubuk kapanır. Sıradaki sureye kendiliğinden
      // geçilmez — kullanıcı okumaya devam etmek isteyip istemediğine kendisi
      // karar verir; sure sonu kartı zaten oradadır.
      if (playerState.processingState == ProcessingState.completed) {
        _finish();
        return;
      }

      final isLoading =
          playerState.processingState == ProcessingState.loading ||
          playerState.processingState == ProcessingState.buffering;

      state = AudioState(
        surahNumber: state.surahNumber,
        currentAyahNumber: state.currentAyahNumber,
        isPlaying: playerState.playing,
        isLoading: isLoading,
        speed: state.speed,
      );
    });
  }

  /// Ses oturumunu bir kez yapılandırır.
  ///
  /// Bu olmadan tilavet, telefon geldiğinde susmaz, kulaklık çıkarıldığında
  /// hoparlörden bağırmaya devam eder ve başka bir uygulama ses çaldığında
  /// üst üste binerdi. Konuşma kategorisi seçildi: tilavet müzik değil,
  /// dinlenerek takip edilen bir okumadır.
  Future<void> _ensureSession() async {
    if (_sessionConfigured) return;
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    _sessionConfigured = true;
  }

  /// Bir sureyi çalar.
  ///
  /// [fromAyah] verilirse kuyruk o ayetten başlar. Ses dosyalarının cihazda
  /// hazır olduğu varsayılır — çağıran taraf indirmeyi önceden tamamlar.
  Future<void> playSurah({
    required Surah surah,
    required List<Ayah> ayahs,
    int? fromAyah,
  }) {
    if (ayahs.isEmpty) return Future.value();

    // Kuyruk blok listesi üzerinden değil ayet numaraları üzerinden kurulur:
    // birleşik meal bloklarında (örn. Alak 9-10) her ayetin ayrı bir ses
    // dosyası vardır ve ikisi de sırayla çalınmalıdır. Blok listesi
    // kullanılsaydı bloğun yalnızca ilk ayeti duyulur, kalanı atlanırdı.
    final start = fromAyah ?? 1;
    return playAyahs(
      entries: [
        for (var n = start; n <= surah.ayahCount; n++)
          (surah: surah.number, ayah: n, surahName: surah.name),
      ],
    );
  }

  /// Verilen ayetleri sırayla çalar.
  ///
  /// Kuyruk tek bir sureyle sınırlı değildir: plan günü birden çok sureye
  /// yayılabilir ve o gün baştan sona kesintisiz dinlenebilmelidir. Sure
  /// sınırı [ConcatenatingAudioSource] için bir anlam taşımaz; geçişler
  /// duyulmaz.
  Future<void> playAyahs({
    required List<({int surah, int ayah, String surahName})> entries,
  }) async {
    if (entries.isEmpty) return;

    final reciter = Reciter.byId(_ref.read(preferencesProvider).reciterId);
    final repository = _ref.read(audioRepositoryProvider);
    final speed = _ref.read(preferencesProvider).playbackSpeed;

    final first = entries.first;
    state = AudioState(
      surahNumber: first.surah,
      currentAyahNumber: first.ayah,
      isLoading: true,
      speed: speed,
    );

    // Bu çalma isteğinin kimliği. Kuyruk hazırlanırken kullanıcı başka bir
    // şey başlatmış olabilir; o durumda bu istek sessizce bırakılır.
    final token = ++_playToken;

    try {
      await _ensureSession();

      final queue = <({int surah, int ayah})>[];
      final sources = <AudioSource>[];

      for (final e in entries) {
        final path = await repository.filePathFor(reciter, e.surah, e.ayah);
        queue.add((surah: e.surah, ayah: e.ayah));
        sources.add(
          AudioSource.file(
            path,
            // Kilit ekranı ve bildirim çubuğu bu künyeyi gösterir. Kimlik
            // ayet referansından türetilir; kuyruk indeksinden türetilseydi
            // aynı ayet farklı başlangıçlarda farklı kimlik alırdı.
            //
            // Başlık sure adını taşır, ayet numarasını değil: kilit
            // ekranında en büyük puntoyla yazılan satır budur ve kullanıcı
            // orada "Bakara" görmek ister, "5. ayet" değil.
            tag: MediaItem(
              id: '${e.surah}:${e.ayah}',
              title: e.surahName,
              album: '${e.ayah}. ayet',
              artist: reciter.name,
            ),
          ),
        );
      }

      if (token != _playToken || !mounted) return;

      _queue = queue;

      await _player.setAudioSource(
        ConcatenatingAudioSource(children: sources),
      );
      await _player.setSpeed(speed);

      // Kuyruk hazırlanırken kullanıcı durdurmuş ya da başka bir şey
      // başlatmış olabilir; o zaman bu ses hiç başlamamalı.
      if (token != _playToken || !mounted) return;

      await _player.play();
    } catch (error) {
      if (token != _playToken || !mounted) return;
      state = AudioState(errorMessage: '$error');
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  /// Sıradaki ayete geçer. Kuyruğun sonundaysa hiçbir şey yapmaz.
  Future<void> next() async {
    if (_player.hasNext) await _player.seekToNext();
  }

  /// Önceki ayete döner.
  ///
  /// Ayetin başına sarmak yerine doğrudan önceki ayete geçilir: tilavette
  /// kullanıcı "geri" derken çoğunlukla kaçırdığı ayeti kastediyor.
  Future<void> previous() async {
    if (_player.hasPrevious) await _player.seekToPrevious();
  }

  /// Kuyruk içinde belirli bir ayete atlar.
  Future<void> seekToAyah(int surahNumber, int ayahNumber) async {
    final index = _queue.indexWhere(
      (e) => e.surah == surahNumber && e.ayah == ayahNumber,
    );
    if (index < 0) return;
    await _player.seek(Duration.zero, index: index);
  }

  Future<void> setSpeed(double speed) async {
    final clamped = speed.clamp(0.5, 2.0);
    await _player.setSpeed(clamped);
    _ref.read(preferencesProvider.notifier).setPlaybackSpeed(clamped);
    state = AudioState(
      surahNumber: state.surahNumber,
      currentAyahNumber: state.currentAyahNumber,
      isPlaying: state.isPlaying,
      isLoading: state.isLoading,
      speed: clamped,
    );
  }

  /// Sesi tamamen kapatır; çubuk gizlenir.
  Future<void> stop() async {
    _playToken++;
    await _player.stop();
    _queue = const [];
    if (mounted) state = const AudioState();
  }

  /// Kuyruk doğal olarak bittiğinde çağrılır.
  void _finish() {
    _queue = const [];
    _player.stop();
    if (mounted) state = const AudioState();
  }

  @override
  void dispose() {
    _indexSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}

/// Oynatıcı uygulama ömrü boyunca tektir.
///
/// Okuma ekranına bağlansaydı kullanıcı ekrandan çıktığında ses kesilirdi;
/// oysa arka planda dinlemek tilavetin en çok kullanılan biçimi.
final audioProvider = StateNotifierProvider<AudioNotifier, AudioState>(
  (ref) => AudioNotifier(ref),
);

/// Çalan surenin künyesi. Ses kapalıyken null.
///
/// Tilavet çubuğu uygulamanın her yerinde görünebildiği için sure adını
/// dışarıdan alamaz: kabuk hangi surenin çaldığını bilmez. Ad buradan
/// çözülür.
final playingSurahProvider = FutureProvider<Surah?>((ref) async {
  final surahNumber = ref.watch(
    audioProvider.select((state) => state.surahNumber),
  );
  if (surahNumber == null) return null;
  return ref.watch(quranRepositoryProvider).surah(surahNumber);
});

/// Okunan sureyi sesli çalmaya hazırlar: gerekirse indirir, sonra başlatır.
///
/// İndirme akışı arayüzde yürütülür (kullanıcı onayı gerekir); bu sağlayıcı
/// yalnızca dosyalar hazır olduğunda çağrılır.
final playSurahProvider = Provider((ref) => PlaySurah(ref));

class PlaySurah {
  const PlaySurah(this._ref);
  final Ref _ref;

  Future<void> call(int surahNumber, {int? fromAyah}) async {
    final data = await _ref.read(readerDataProvider(surahNumber).future);
    await _ref.read(audioProvider.notifier).playSurah(
      surah: data.surah,
      ayahs: data.ayahs,
      fromAyah: fromAyah,
    );
  }
}
