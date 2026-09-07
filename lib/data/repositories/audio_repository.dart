import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/reciter.dart';

/// Tilavet dosyalarının cihazdaki deposu.
///
/// Uygulama başka hiçbir yerde ağa çıkmaz; buradaki indirme yalnızca
/// kullanıcının açıkça onayladığı sure için, onayladığı anda yapılır. Bu
/// sınırın korunması önemli: uygulamanın "tamamen çevrimdışı" vaadi ses
/// eklendikten sonra da geçerli kalmalı, ses yalnızca kullanıcının bilerek
/// getirdiği bir ek olmalı.
///
/// Dosya düzeni:
/// ```
/// <appSupport>/audio/<reciterId>/<surahNumber>/001001.mp3
///                                             /.done
/// ```
/// `.done` işareti sure tamamlandığında yazılır. Varlığı "bu sure eksiksiz"
/// demektir; dosya sayısını her seferinde saymaktan hem daha hızlı hem de
/// daha doğru — yarım kalmış bir indirme doğru sayıda dosya bırakmış olsa
/// bile (son dosya yarım yazılmışsa) hazır sayılmaz.
class AudioRepository {
  AudioRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Kök dizin bir kez çözülüp saklanır; her ayet için yeniden sormak
  /// gereksiz platform çağrısı demek.
  Directory? _rootCache;

  static const _doneMarker = '.done';

  /// Aynı anda kaç ayetin indirileceği.
  ///
  /// Sıralı indirmede 286 ayetlik bir sure kabul edilemez sürede iner; sınırsız
  /// paralellikte ise sunucu istekleri reddetmeye başlar ve cihazın ağ yığını
  /// tıkanır. Altı, ev bağlantısında bant genişliğini doyuran ama sunucuyu
  /// zorlamayan bir orta yol.
  static const _concurrency = 6;

  Future<Directory> _root() async {
    final cached = _rootCache;
    if (cached != null) return cached;

    // Destek dizini seçildi, belgeler dizini değil: bu dosyalar kullanıcının
    // göz atacağı içerik değil, uygulamanın yeniden indirebileceği önbellek.
    // iOS'ta belgeler dizini iCloud'a yedeklenir ve yüzlerce megabaytlık ses
    // kullanıcının yedeğini şişirirdi.
    final base = await getApplicationSupportDirectory();
    final root = Directory(p.join(base.path, 'audio'));
    await root.create(recursive: true);
    _rootCache = root;
    return root;
  }

  Future<Directory> _surahDirectory(Reciter reciter, int surahNumber) async {
    final root = await _root();
    return Directory(p.join(root.path, reciter.id, '$surahNumber'));
  }

  /// Bir ayetin cihazdaki dosya yolu. Dosya var olmayabilir.
  Future<String> filePathFor(
    Reciter reciter,
    int surahNumber,
    int ayahNumber,
  ) async {
    final dir = await _surahDirectory(reciter, surahNumber);
    return p.join(dir.path, Reciter.fileName(surahNumber, ayahNumber));
  }

  /// Sure eksiksiz indirilmiş mi.
  Future<bool> isSurahDownloaded(Reciter reciter, int surahNumber) async {
    final dir = await _surahDirectory(reciter, surahNumber);
    return File(p.join(dir.path, _doneMarker)).exists();
  }

  /// Bu kari için indirilmiş surelerin numaraları.
  Future<Set<int>> downloadedSurahs(Reciter reciter) async {
    final root = await _root();
    final dir = Directory(p.join(root.path, reciter.id));
    if (!await dir.exists()) return {};

    final result = <int>{};
    await for (final entry in dir.list()) {
      if (entry is! Directory) continue;
      final number = int.tryParse(p.basename(entry.path));
      if (number == null) continue;
      if (await File(p.join(entry.path, _doneMarker)).exists()) {
        result.add(number);
      }
    }
    return result;
  }

  /// Bir surenin cihazda kapladığı gerçek yer (bayt).
  Future<int> sizeOnDisk(Reciter reciter, int surahNumber) async {
    final dir = await _surahDirectory(reciter, surahNumber);
    if (!await dir.exists()) return 0;

    var total = 0;
    await for (final entry in dir.list()) {
      if (entry is File) total += await entry.length();
    }
    return total;
  }

  /// Bu karinin indirilmiş tüm seslerinin toplam boyutu.
  Future<int> totalSizeOnDisk(Reciter reciter) async {
    final root = await _root();
    final dir = Directory(p.join(root.path, reciter.id));
    if (!await dir.exists()) return 0;

    var total = 0;
    await for (final entry in dir.list(recursive: true)) {
      if (entry is File) total += await entry.length();
    }
    return total;
  }

  /// Bir surenin ses dosyalarını siler.
  Future<void> deleteSurah(Reciter reciter, int surahNumber) async {
    final dir = await _surahDirectory(reciter, surahNumber);
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  /// Bu karinin tüm indirilmiş seslerini siler.
  Future<void> deleteAll(Reciter reciter) async {
    final root = await _root();
    final dir = Directory(p.join(root.path, reciter.id));
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  /// Bir sureyi indirir.
  ///
  /// [onProgress] her tamamlanan ayetten sonra çağrılır; arayüz ilerlemeyi
  /// buradan gösterir. [isCancelled] her ayet öbeğinden önce sorulur — kullanıcı
  /// vazgeçtiğinde indirme bir sonraki öbekte durur, o ana kadar inenler
  /// silinmez ve sonraki denemede atlanır.
  ///
  /// Zaten cihazda olan ayetler tekrar indirilmez; yarım kalmış bir indirme bu
  /// sayede kaldığı yerden sürer.
  Future<void> downloadSurah({
    required Reciter reciter,
    required int surahNumber,
    required int ayahCount,
    void Function(int completed)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final dir = await _surahDirectory(reciter, surahNumber);
    await dir.create(recursive: true);

    // Yeniden indirmede işaret önce kaldırılır: indirme yarıda kesilirse
    // sure "hazır" görünmemeli.
    final marker = File(p.join(dir.path, _doneMarker));
    if (await marker.exists()) await marker.delete();

    var completed = 0;

    for (var start = 1; start <= ayahCount; start += _concurrency) {
      if (isCancelled?.call() ?? false) return;

      final end = (start + _concurrency - 1).clamp(1, ayahCount);
      final batch = <Future<void>>[];

      for (var ayah = start; ayah <= end; ayah++) {
        batch.add(
          _downloadAyah(reciter, surahNumber, ayah, dir).then((_) {
            completed++;
            onProgress?.call(completed);
          }),
        );
      }

      // Öbekteki herhangi bir ayet inemezse indirme durur ve hata yukarı
      // taşınır: eksik bir sure çalınmaya başlarsa kullanıcı tilavetin
      // ortasında sessizlikle karşılaşır.
      await Future.wait(batch);
    }

    if (isCancelled?.call() ?? false) return;

    await marker.writeAsString('');
  }

  /// Verilen ayetleri indirir.
  ///
  /// Sure sınırından bağımsızdır: bir plan günü on altı sureye yayılabilir ve
  /// kullanıcı o günü tek bir onayla indirebilmelidir. Sure klasörleri yine
  /// ayrı ayrı doldurulur; yalnızca `.done` işareti konmaz, çünkü sureler
  /// eksik kalıyor olabilir — gün yalnızca kendi ayetlerini kapsar.
  ///
  /// Zaten cihazda olan ayetler tekrar indirilmez. Bu, günlerin çakıştığı
  /// yerlerde (bir sure iki güne bölündüğünde) ikinci indirmeyi neredeyse
  /// bedava yapar.
  Future<void> downloadAyahs({
    required Reciter reciter,
    required List<({int surah, int ayah})> entries,
    void Function(int completed)? onProgress,
    bool Function()? isCancelled,
  }) async {
    // Sure klasörleri önden açılır; her ayette dizin varlığını sınamak
    // gereksiz dosya sistemi çağrısı demek.
    final directories = <int, Directory>{};
    for (final surah in entries.map((e) => e.surah).toSet()) {
      final dir = await _surahDirectory(reciter, surah);
      await dir.create(recursive: true);
      directories[surah] = dir;
    }

    var completed = 0;

    for (var start = 0; start < entries.length; start += _concurrency) {
      if (isCancelled?.call() ?? false) return;

      final end = (start + _concurrency).clamp(0, entries.length);
      final batch = <Future<void>>[];

      for (final e in entries.sublist(start, end)) {
        batch.add(
          _downloadAyah(reciter, e.surah, e.ayah, directories[e.surah]!)
              .then((_) {
            completed++;
            onProgress?.call(completed);
          }),
        );
      }

      await Future.wait(batch);
    }
  }

  /// Verilen ayetlerden cihazda bulunmayanlar.
  ///
  /// İndirme onayında gerçek boyutu tahmin etmek için kullanılır: gün içindeki
  /// surelerin bir kısmı önceki günlerde inmiş olabilir ve kullanıcıya
  /// indirilmeyecek dosyaların boyutunu söylemek yanıltıcı olurdu.
  Future<List<({int surah, int ayah})>> missingAyahs(
    Reciter reciter,
    List<({int surah, int ayah})> entries,
  ) async {
    final missing = <({int surah, int ayah})>[];
    for (final e in entries) {
      final path = await filePathFor(reciter, e.surah, e.ayah);
      final file = File(path);
      if (!await file.exists() || await file.length() == 0) missing.add(e);
    }
    return missing;
  }

  /// Tek bir ayeti indirir. Dosya zaten varsa hiçbir şey yapmaz.
  Future<void> _downloadAyah(
    Reciter reciter,
    int surahNumber,
    int ayahNumber,
    Directory dir,
  ) async {
    final file = File(
      p.join(dir.path, Reciter.fileName(surahNumber, ayahNumber)),
    );
    if (await file.exists() && await file.length() > 0) return;

    final response = await _client.get(
      Uri.parse(reciter.urlFor(surahNumber, ayahNumber)),
    );

    if (response.statusCode != 200) {
      throw AudioDownloadException(
        'Ses dosyası indirilemedi ($surahNumber:$ayahNumber) '
        '— sunucu ${response.statusCode} döndü.',
      );
    }

    // Önce geçici ada yazılıp sonra taşınır. Doğrudan yazılsaydı indirme
    // dosyanın ortasında kesildiğinde geride yarım bir MP3 kalırdı; bir
    // sonraki denemede "dosya var" diye atlanır ve o ayet hep bozuk çalardı.
    final temp = File('${file.path}.part');
    await temp.writeAsBytes(response.bodyBytes);
    await temp.rename(file.path);
  }

  void dispose() => _client.close();
}

/// Ses indirmesinin başarısızlığı. Arayüz bunu yakalayıp kullanıcıya
/// anlaşılır bir mesaj gösterir.
class AudioDownloadException implements Exception {
  const AudioDownloadException(this.message);
  final String message;

  @override
  String toString() => message;
}
