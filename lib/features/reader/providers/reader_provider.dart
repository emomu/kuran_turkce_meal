import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../data/models/ayah.dart';
import '../../../data/models/surah.dart';
import '../../../data/models/user_marks.dart';
import '../../bookmarks/providers/bookmarks_provider.dart';
import '../../home/providers/home_provider.dart';
import '../../settings/providers/preferences_provider.dart';

/// Okuma ekranının metin verisi: sure künyesi ve ayetler.
///
/// Kullanıcının işaretleri (yer imi, vurgu, not) bilerek buraya dahil
/// edilmez; onların tek kaynağı [surahMarksProvider]'dır. İki yerde
/// tutulsalardı hangi kopyanın güncel olduğu yükleme sırasına bağlı kalır ve
/// yeni eklenen bir vurgu ekrana yansımayabilirdi.
class ReaderData {
  const ReaderData({required this.surah, required this.ayahs});

  final Surah surah;
  final List<Ayah> ayahs;
}

/// Bir sureyi okumak için gereken metni yükler.
///
/// Sure künyesi ve ayetler paralel çekilir; ayrı tablolardan gelirler ve
/// birbirlerini beklemeleri gerekmez.
final readerDataProvider =
    FutureProvider.family<ReaderData, int>((ref, surahNumber) async {
  final quran = ref.watch(quranRepositoryProvider);

  final results = await Future.wait([
    quran.surah(surahNumber),
    quran.ayahsOfSurah(surahNumber),
  ]);

  final surah = results[0] as Surah?;
  if (surah == null) {
    throw StateError('$surahNumber numaralı sure bulunamadı');
  }

  return ReaderData(surah: surah, ayahs: results[1] as List<Ayah>);
});

/// Okuma ilerlemesini kaydeder ve ana ekranı tazeler.
///
/// Ana ekrandaki ilerleme çubukları ile "kaldığın yer" kartı ayrı
/// sağlayıcılardan beslenir; kayıt sonrası geçersiz kılınmazlarsa kullanıcı
/// okuma ekranından çıktığında eski değerleri görür.
final saveProgressProvider = Provider((ref) => SaveProgress(ref));

class SaveProgress {
  SaveProgress(this._ref);
  final Ref _ref;

  Future<void> call(int surahNumber, int ayahNumber) async {
    await _ref
        .read(progressRepositoryProvider)
        .saveProgress(surahNumber, ayahNumber);

    _ref
      ..invalidate(surahProgressProvider)
      ..invalidate(lastReadProvider);
  }
}

/// Okuma akışında bu sureden sonra gelen sure.
///
/// Kullanıcının sıralama tercihini izler; tercih değişirse kendini yeniler.
/// Son surede null döner ve okuma ekranı bitiş kartını gösterir.
final nextSurahProvider =
    FutureProvider.family<Surah?, int>((ref, surahNumber) {
  final byRevelation = ref.watch(
    preferencesProvider.select((p) => p.sortByRevelation),
  );
  return ref.watch(quranRepositoryProvider).nextSurah(
        surahNumber,
        byRevelation: byRevelation,
      );
});

/// Okuma akışında bu sureden önce gelen sure.
///
/// [nextSurahProvider] ile aynı kural: sıralama tercihini izler. İlk surede
/// null döner ve okuma ekranı geri geçiş kartını göstermez.
final previousSurahProvider =
    FutureProvider.family<Surah?, int>((ref, surahNumber) {
  final byRevelation = ref.watch(
    preferencesProvider.select((p) => p.sortByRevelation),
  );
  return ref.watch(quranRepositoryProvider).previousSurah(
        surahNumber,
        byRevelation: byRevelation,
      );
});

/// Bir surenin işaretlerini tutar ve değişiklikleri veritabanına yazar.
///
/// Okuma ekranı bunu dinler; yer imi veya vurgu değiştiğinde tüm sure yeniden
/// yüklenmez, yalnızca ilgili ayet yeniden çizilir.
class SurahMarksNotifier extends StateNotifier<Map<int, AyahMark>> {
  SurahMarksNotifier(this._ref, this._surahNumber) : super(const {}) {
    _load();
  }

  final Ref _ref;
  final int _surahNumber;

  Future<void> _load() async {
    final marks =
        await _ref.read(marksRepositoryProvider).marksForSurah(_surahNumber);

    // Kullanıcı okuma bitmeden geri dönmüş olabilir; veritabanı okuması
    // sürerken ekran kapanırsa sağlayıcı da kapatılır ve kapatılmış bir
    // notifier'a yazmak hata fırlatır.
    if (!mounted) return;
    state = marks;
  }

  Future<void> toggleBookmark(int ayahId) async {
    final updated =
        await _ref.read(marksRepositoryProvider).toggleBookmark(ayahId);
    _apply(ayahId, updated);
  }

  Future<void> setHighlight(int ayahId, int? color) async {
    final updated =
        await _ref.read(marksRepositoryProvider).setHighlight(ayahId, color);
    _apply(ayahId, updated);
  }

  Future<void> setNote(int ayahId, String? note) async {
    final updated =
        await _ref.read(marksRepositoryProvider).setNote(ayahId, note);
    _apply(ayahId, updated);
  }

  /// Güncellenen işareti duruma yazar; işaret tamamen boşaldıysa haritadan
  /// çıkarır — böylece arayüz gereksiz rozet çizmez.
  ///
  /// Ayrıca aynı veriyi gösteren diğer ekranlar tazelenir: Kayıtlar sekmesi
  /// bu işaretleri kendi sorgusuyla okur ve haber verilmezse eski listeyi
  /// göstermeye devam ederdi.
  void _apply(int ayahId, AyahMark updated) {
    final next = Map<int, AyahMark>.from(state);
    if (updated.isEmpty) {
      next.remove(ayahId);
    } else {
      next[ayahId] = updated;
    }
    state = next;

    _ref.invalidate(savedEntriesProvider);
  }
}

final surahMarksProvider = StateNotifierProvider.family<SurahMarksNotifier,
    Map<int, AyahMark>, int>(
  (ref, surahNumber) => SurahMarksNotifier(ref, surahNumber),
);
