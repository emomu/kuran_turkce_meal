import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_typography.dart';
import '../../../data/models/audio_download.dart';
import '../../../data/models/surah.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../providers/download_provider.dart';

/// Bayt değerini kullanıcıya okunur biçimde verir. Örn. "38 MB".
///
/// Ondalık basamak kullanılmaz: kullanıcı "37,4 MB" ile "38 MB" arasında bir
/// karar vermiyor, kabaca ne kadar yer tutacağını bilmek istiyor.
String formatBytes(int bytes) {
  if (bytes < 1024 * 1024) {
    final kb = (bytes / 1024).round();
    return '$kb KB';
  }
  final mb = bytes / (1024 * 1024);
  if (mb < 10) return '${mb.toStringAsFixed(1)} MB';
  return '${mb.round()} MB';
}

/// Sureyi dinlemeden önce sesin indirilmesini isteyen yaprak.
///
/// Ses dosyaları uygulamayla gelmez ve indirme kullanıcının verisini harcar.
/// Bu yüzden indirme sessizce yapılmaz: ne kadar yer tutacağı ve kimin
/// okuduğu söylenip onay alınır. Uygulamanın ağ kullanan tek yeri burası
/// olduğu için bu onay, "tamamen çevrimdışı" vaadinin de sınırıdır.
class AudioDownloadSheet extends ConsumerWidget {
  const AudioDownloadSheet({super.key, required this.surah});

  final Surah surah;

  /// İndirmeyi yaprağın içinde yürütür ve bitince yaprağı kapatır.
  ///
  /// Kapanış değeri çağırana indirmenin başarılı olup olmadığını söyler:
  /// `true` ise ses çalınabilir, `false` ise kullanıcı vazgeçmiş ya da
  /// indirme başarısız olmuştur.
  Future<void> _startDownload(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final ok = await ref
        .read(surahDownloadProvider(surah.number).notifier)
        .download(surah.ayahCount);

    // Yaprak indirme sürerken kapatılmış olabilir (kullanıcı geri çekti);
    // kapanmış bir yaprağı yeniden kapatmaya çalışmak hata verir.
    if (!navigator.mounted) return;

    // Başarısızlıkta yaprak açık kalır: hata mesajı ve "yeniden dene"
    // düğmesi burada duruyor, kapatılsaydı kullanıcı ne olduğunu anlamazdı.
    if (ok) navigator.pop(true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reciter = ref.watch(selectedReciterProvider);
    final download = ref.watch(surahDownloadProvider(surah.number));
    final notifier = ref.read(surahDownloadProvider(surah.number).notifier);

    final estimated = reciter.estimatedBytesFor(surah.ayahCount);

    return AdaptiveSheet(
      child: SafeArea(
        top: false,
        child: Padding(
          // Üst dolgu dar: kapatma düğmesinin 44pt'lik dokunma alanı başlık
          // satırını zaten aşağı itiyor ve buraya tam dolgu konsaydı yaprağın
          // tepesinde ölü boşluk kalırdı.
          padding: horizontalSafeGutter(
            context,
          ).copyWith(top: Insets.xxs, bottom: Insets.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık ve kapatma aynı satırda. Kapatma sağ üstte: yaprağı
              // aşağı sürükleyerek kapatmak indirme sırasında devre dışı
              // (bkz. `isDismissible`), o yüzden görünür bir çıkış gerekiyor.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      // Başlık, yanındaki 44pt'lik düğmeyle görsel olarak
                      // hizalanır; kutu hizası eşitken metin yukarıda duruyor.
                      padding: const EdgeInsets.only(top: Insets.sm),
                      child: Text(
                        'audio.downloadTitle'.tr(
                          namedArgs: {
                            'surah': surah.nameFor(context.locale.languageCode),
                          },
                        ),
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ),
                  const SizedBox(width: Insets.xs),
                  Pressable(
                    // İndirme sürerken kapatma, indirmeyi de iptal eder:
                    // yaprak kapandıktan sonra arkada süren bir indirmenin
                    // ilerlemesi kullanıcıya hiçbir yerde görünmezdi.
                    onTap: () {
                      if (download.isDownloading) notifier.cancel();
                      Navigator.of(context).pop(false);
                    },
                    scale: 0.9,
                    child: SizedBox(
                      // Dokunma alanı 44pt'nin altına düşmemeli (Apple HIG).
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Insets.xs),
              Text(
                'audio.downloadBody'.tr(
                  namedArgs: {
                    'reciter': reciter.name,
                    'size': formatBytes(estimated),
                    'count': '${surah.ayahCount}',
                  },
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: Insets.sm),

              // Kayıtların nereden geldiği. Kullanıcı onay verirken neye onay
              // verdiğini bilmeli; ayrıntısı Ayarlar > Ses hakkında'da.
              Text(
                'audio.sourceNote'.tr(),
                style: theme.textTheme.bodySmall,
              ),

              // Mobil veri uyarısı yalnızca gerçekten mobil verideyken çıkar.
              // Her indirmede gösterilseydi kullanıcı onu okumayı bırakır ve
              // gerçekten önemli olduğu anda da görmezdi.
              if (ref.watch(isOnMobileDataProvider).valueOrNull ?? false) ...[
                const SizedBox(height: Insets.sm),
                _MobileDataNotice(),
              ],

              const SizedBox(height: Insets.md),

              // İndirme yaprağın içinde yürür ve bitince yaprak kendini
              // kapatır. Onay alınıp hemen kapatılsaydı kullanıcı ilerlemeyi
              // göremez, indirmenin sürdüğünü ancak ses başlayınca anlardı.
              if (download.isDownloading)
                _Progress(download: download, onCancel: notifier.cancel)
              else ...[
                if (download.hasFailed) ...[
                  _Failure(message: download.errorMessage),
                  const SizedBox(height: Insets.sm),
                ],
                _PrimaryButton(
                  label: download.hasFailed
                      ? 'audio.retry'.tr()
                      : 'audio.downloadAndPlay'.tr(),
                  onTap: () => _startDownload(context, ref),
                ),
                const SizedBox(height: Insets.xs),
                Center(
                  child: Pressable(
                    onTap: () => Navigator.of(context).pop(false),
                    scale: 0.98,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: Insets.sm,
                        horizontal: Insets.md,
                      ),
                      child: Text(
                        'audio.notNow'.tr(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// İndirme ilerlemesi. Yüzde değil ayet sayısı gösterilir — kullanıcı için
/// "112/286 ayet" soyut bir yüzdeden daha anlaşılır.
class _Progress extends StatelessWidget {
  const _Progress({required this.download, required this.onCancel});

  final AudioDownload download;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(Radii.pill),
          child: LinearProgressIndicator(
            value: download.progress,
            minHeight: 4,
            backgroundColor: theme.dividerColor,
          ),
        ),
        const SizedBox(height: Insets.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'audio.downloadProgress'.tr(
                namedArgs: {
                  'done': '${download.completedAyahs}',
                  'total': '${download.totalAyahs}',
                },
              ),
              style: theme.textTheme.labelMedium,
            ),
            Pressable(
              onTap: () {
                onCancel();
                Navigator.of(context).pop(false);
              },
              scale: 0.95,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Insets.xs),
                child: Text(
                  'audio.cancel'.tr(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Mobil veri uyarısı.
///
/// Hata değil bilgi olduğu için hata rengiyle değil, dikkat çeken ama
/// alarm vermeyen nötr bir yüzeyle çizilir: indirme engellenmiyor, kullanıcı
/// yalnızca bilgilendiriliyor.
class _MobileDataNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(Insets.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.signal_cellular_alt_rounded,
            size: 18,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: Insets.xs),
          Expanded(
            child: Text(
              'audio.mobileDataWarning'.tr(),
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(Insets.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 18,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: Insets.xs),
          Expanded(
            child: Text(
              'audio.downloadFailed'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Pressable(
      onTap: onTap,
      scale: 0.98,
      hapticOnTap: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: Insets.sm + 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}
