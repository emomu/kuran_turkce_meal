/// Sesli soru girişi.
///
/// Kur'an uygulamasında yazmak herkes için kolay değil: yaşlı kullanıcılar,
/// gözü zayıf olanlar ve Türkçe klavyeyle arası iyi olmayanlar sorularını
/// söyleyerek sorabilmeli. Tanıma cihazın kendi motoruyla yapılır — ses
/// buluta gitmez, uygulamanın çevrimdışı ve hesapsız çalışma sözü bozulmaz.
///
/// Tanınan metin doğrudan gönderilmez, yazı alanına konur. Sebep basit:
/// konuşma tanıma yanılır ve "sabır" yerine "sabun" yazabilir. Kullanıcı
/// göndermeden önce görmeli ve düzeltebilmeli.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Dinlemenin hangi aşamada olduğu.
enum VoiceStatus {
  /// Kullanılabilir ama dinlemiyor.
  idle,

  /// Şu anda dinliyor.
  listening,

  /// Cihazda konuşma tanıma yok ya da izin verilmedi.
  unavailable,
}

/// Ses girişinin durumu.
class VoiceInputState {
  const VoiceInputState({
    this.status = VoiceStatus.idle,
    this.transcript = '',
    this.soundLevel = 0,
  });

  final VoiceStatus status;

  /// O ana kadar tanınan metin. Dinleme sürerken güncellenir.
  final String transcript;

  /// Mikrofon ses seviyesi. Dalga göstergesini canlandırmak için;
  /// kullanıcı uygulamanın kendisini duyduğunu görmeli.
  final double soundLevel;

  bool get isListening => status == VoiceStatus.listening;

  VoiceInputState copyWith({
    VoiceStatus? status,
    String? transcript,
    double? soundLevel,
  }) =>
      VoiceInputState(
        status: status ?? this.status,
        transcript: transcript ?? this.transcript,
        soundLevel: soundLevel ?? this.soundLevel,
      );
}

class VoiceInputNotifier extends StateNotifier<VoiceInputState> {
  VoiceInputNotifier() : super(const VoiceInputState());

  final _speech = SpeechToText();
  bool _initialized = false;

  /// Tanıma motorunu bir kez hazırlar.
  ///
  /// İzin istemi burada çıkar. Uygulama açılışında değil ilk mikrofon
  /// dokunuşunda çağrılır: izni sormadan önce kullanıcının onu neden
  /// istediğimizi anlamış olması gerekir.
  Future<bool> _ensureReady() async {
    if (_initialized) return _speech.isAvailable;

    final available = await _speech.initialize(
      // Hata ve durum geri çağrıları sessiz tutulur: kullanıcıya teknik
      // bir hata metni göstermenin karşılığı yok, gösterge zaten durumu
      // anlatıyor.
      onError: (_) => _stopped(),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') _stopped();
      },
    );

    _initialized = true;
    if (!mounted) return available;

    state = state.copyWith(
      status: available ? VoiceStatus.idle : VoiceStatus.unavailable,
    );
    return available;
  }

  /// Dinlemeye başlar.
  ///
  /// [languageCode] arayüz dili; tanıma o dilde yapılır. Türkçe arayüzde
  /// İngilizce tanıma çalıştırmak "sabır" kelimesini tanınmaz kılardı.
  Future<void> start({required String languageCode}) async {
    if (state.isListening) return;
    if (!await _ensureReady()) return;
    if (!mounted) return;

    state = state.copyWith(
      status: VoiceStatus.listening,
      transcript: '',
      soundLevel: 0,
    );

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        state = state.copyWith(transcript: result.recognizedWords);
      },
      onSoundLevelChange: (level) {
        if (!mounted) return;
        state = state.copyWith(soundLevel: level);
      },
      listenOptions: SpeechListenOptions(
        localeId: languageCode == 'en' ? 'en_US' : 'tr_TR',
        // Ara sonuçlar açık: kullanıcı konuşurken kelimelerin belirmesi,
        // tanımanın çalıştığını gösteren en doğrudan geri bildirim.
        partialResults: true,
        cancelOnError: true,
        // Bir soru uzun sürmez. Süre sınırı, kullanıcı susmayı unutursa
        // mikrofonun açık kalmasını önler.
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      ),
    );
  }

  /// Dinlemeyi bitirir ve tanınan metni verir.
  Future<String> stop() async {
    if (!state.isListening) return state.transcript;

    await _speech.stop();
    final text = state.transcript;
    _stopped();
    return text;
  }

  /// Dinlemeyi iptal eder; tanınan metin atılır.
  Future<void> cancel() async {
    await _speech.cancel();
    if (!mounted) return;
    state = const VoiceInputState();
  }

  void _stopped() {
    if (!mounted) return;
    if (state.status != VoiceStatus.listening) return;
    state = state.copyWith(status: VoiceStatus.idle, soundLevel: 0);
  }

  @override
  void dispose() {
    // Ekrandan çıkılırken mikrofon açık kalmamalı.
    if (_initialized) _speech.cancel();
    super.dispose();
  }
}

final voiceInputProvider =
    StateNotifierProvider<VoiceInputNotifier, VoiceInputState>(
  (ref) => VoiceInputNotifier(),
);
