/// Bir surenin ses dosyalarının cihazdaki durumu.
enum AudioDownloadStatus {
  /// Hiç indirilmemiş ya da yarım kalıp temizlenmiş.
  absent,

  /// Şu anda iniyor.
  downloading,

  /// Tamamı cihazda; çevrimdışı çalınabilir.
  ready,

  /// İndirme başarısız oldu. Kısmi dosyalar silinmez — kullanıcı yeniden
  /// denediğinde mevcut olanlar atlanır ve indirme kaldığı yerden sürer.
  failed,
}

/// Sure ses indirmesinin anlık durumu.
///
/// Hem indirme ekranı hem oynatma çubuğu bunu dinler; ikisi de aynı kaynağı
/// okusun diye tek tip halinde tutuldu.
class AudioDownload {
  const AudioDownload({
    required this.surahNumber,
    this.status = AudioDownloadStatus.absent,
    this.completedAyahs = 0,
    this.totalAyahs = 0,
    this.errorMessage,
  });

  final int surahNumber;
  final AudioDownloadStatus status;

  /// Cihaza yazılmış ayet sayısı.
  final int completedAyahs;

  /// Surenin toplam ayet sayısı. İndirme başlamadan bilinmiyorsa 0.
  final int totalAyahs;

  /// Başarısızlık sebebi; arayüzde kullanıcıya gösterilir.
  final String? errorMessage;

  bool get isReady => status == AudioDownloadStatus.ready;
  bool get isDownloading => status == AudioDownloadStatus.downloading;
  bool get hasFailed => status == AudioDownloadStatus.failed;

  /// 0–1 arası ilerleme. Toplam bilinmiyorsa 0 döner; belirsiz ilerleme
  /// çubuğu bu durumda arayüz tarafında seçilir.
  double get progress {
    if (totalAyahs <= 0) return 0;
    return (completedAyahs / totalAyahs).clamp(0.0, 1.0);
  }

  AudioDownload copyWith({
    AudioDownloadStatus? status,
    int? completedAyahs,
    int? totalAyahs,
    String? errorMessage,
  }) => AudioDownload(
    surahNumber: surahNumber,
    status: status ?? this.status,
    completedAyahs: completedAyahs ?? this.completedAyahs,
    totalAyahs: totalAyahs ?? this.totalAyahs,
    // Hata mesajı bilinçli olarak taşınmaz: yeni bir duruma geçilirken eski
    // hata metni ekranda kalırsa kullanıcı çözülmüş bir sorunu görmeye devam
    // eder. Hata mesajı her seferinde açıkça verilmeli.
    errorMessage: errorMessage,
  );
}
