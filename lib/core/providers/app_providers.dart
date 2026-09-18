import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/db/app_database.dart';
import '../../data/repositories/audio_repository.dart';
import '../../data/repositories/marks_repository.dart';
import '../../data/repositories/prophet_repository.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/quran_repository.dart';
import '../../data/repositories/root_repository.dart';
import '../../data/repositories/segment_repository.dart';
import '../../data/repositories/topic_repository.dart';

/// Uygulama genelinde paylaşılan altyapı sağlayıcıları.

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);

final quranRepositoryProvider = Provider<QuranRepository>(
  (ref) => QuranRepository(ref.watch(databaseProvider)),
);

final marksRepositoryProvider = Provider<MarksRepository>(
  (ref) => MarksRepository(ref.watch(databaseProvider)),
);

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(
    ref.watch(databaseProvider),
    ref.watch(sharedPreferencesProvider),
  ),
);

/// Tilavet ses dosyalarının deposu.
///
/// Uygulama ömrü boyunca tektir; içindeki HTTP istemcisi bağlantıyı yeniden
/// kullanır ve her ayet için yeni bir istemci kurulmaz.
final audioRepositoryProvider = Provider<AudioRepository>((ref) {
  final repository = AudioRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

/// Peygamber-ayet eşleştirmesi. Asset'ten belleğe alınır (~8 KB).
final prophetRepositoryProvider = Provider<ProphetRepository>(
  (ref) => ProphetRepository(),
);

/// Peygamber verisinin yüklenmesini bekler.
final prophetDataProvider = FutureProvider<ProphetRepository>((ref) async {
  final repo = ref.watch(prophetRepositoryProvider);
  await repo.ensureLoaded();
  return repo;
});

/// Konu fihristi. Asset'ten belleğe alınır (~34 KB).
final topicRepositoryProvider = Provider<TopicRepository>(
  (ref) => TopicRepository(),
);

/// Fihrist verisinin yüklenmesini bekler. Keşfet ekranları bunu izler.
final topicDataProvider = FutureProvider<TopicRepository>((ref) async {
  final repo = ref.watch(topicRepositoryProvider);
  await repo.ensureLoaded();
  return repo;
});

/// Kelime kökü verisi. Asset'ten belleğe alınır; ilk kullanımda yüklenir.
final rootRepositoryProvider = Provider<RootRepository>(
  (ref) => RootRepository(),
);

/// Kök verisinin yüklenmesini bekler. Kök ekranları bunu izler.
final rootDataProvider = FutureProvider<RootRepository>((ref) async {
  final repo = ref.watch(rootRepositoryProvider);
  await repo.ensureLoaded();
  return repo;
});

/// Tilavet kelime zamanlamaları. Vurgu için gerekir; yoksa vurgu ayet
/// düzeyinde kalır.
final segmentRepositoryProvider = Provider<SegmentRepository>(
  (ref) => SegmentRepository(),
);

/// Zamanlama paketinin yüklenmesini bekler.
///
/// Yükleme başarısız olsa bile hata yayılmaz: paket yalnızca vurguyu
/// zenginleştirir, tilavetin çalışması ona bağlı değil.
final segmentDataProvider = FutureProvider<SegmentRepository>((ref) async {
  final repo = ref.watch(segmentRepositoryProvider);
  await repo.load();
  return repo;
});

/// SharedPreferences örneği. `main()` içinde çözülüp override edilir, böylece
/// tercihleri okuyan widget'lar asenkron beklemek zorunda kalmaz.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider main() içinde override edilmeli',
  ),
);

/// Meal verisinin yüklü olup olmadığı. İçerik ekranları bunu bekler.
final hasContentProvider = FutureProvider<bool>(
  (ref) => ref.watch(databaseProvider).hasContent(),
);
