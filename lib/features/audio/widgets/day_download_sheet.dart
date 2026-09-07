import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_typography.dart';
import '../../../data/models/audio_download.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../providers/download_provider.dart';
import 'audio_download_sheet.dart' show formatBytes;

/// Bir plan gününü dinlemeden önce sesin indirilmesini isteyen yaprak.
///
/// Sure yaprağından ayrı: plan günü on altı sureye yayılabilir ve kullanıcı
/// tek tek sure indirmek istemez. Burada gün bir bütün olarak sunulur —
/// "8 sure, 205 ayet" — ve tek onayla iner.
///
/// Boyut, gün içindeki ayetlerin *eksik olanları* üzerinden hesaplanır: bir
/// surenin bir kısmı önceki günde inmiş olabilir ve kullanıcıya indirilmeyecek
/// dosyaların boyutunu söylemek yanıltıcı olurdu.
class DayDownloadSheet extends ConsumerWidget {
  const DayDownloadSheet({
    super.key,
    required this.dayLabel,
    required this.entries,
    required this.surahCount,
  });

  /// "1. gün · Alak 1–19" gibi, kullanıcının ekranda gördüğü künye.
  final String dayLabel;

  final List<({int surah, int ayah})> entries;

  /// Gün kaç sureye yayılıyor.
  final int surahCount;

  Future<void> _startDownload(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final ok = await ref
        .read(ayahSetDownloadProvider.notifier)
        .download(entries);

    if (!navigator.mounted) return;
    // Başarısızlıkta yaprak açık kalır: hata mesajı ve "yeniden dene"
    // düğmesi burada duruyor.
    if (ok) navigator.pop(true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reciter = ref.watch(selectedReciterProvider);
    final download = ref.watch(ayahSetDownloadProvider);
    final notifier = ref.read(ayahSetDownloadProvider.notifier);
    final missing = ref.watch(missingAyahCountProvider(entries)).valueOrNull;

    // Boyut bilinmiyorken (eksik sayımı sürerken) tahmin tüm ayetler
    // üzerinden verilir; hesap bitince gerçek eksik sayısına düşer.
    final countForSize = missing ?? entries.length;
    final estimated = reciter.estimatedBytesFor(countForSize);

    return AdaptiveSheet(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: horizontalSafeGutter(
            context,
          ).copyWith(top: Insets.xxs, bottom: Insets.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: Insets.sm),
                      child: Text(
                        'audio.dayDownloadTitle'.tr(
                          namedArgs: {'day': dayLabel},
                        ),
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ),
                  const SizedBox(width: Insets.xs),
                  Pressable(
                    onTap: () {
                      if (download.isDownloading) notifier.cancel();
                      Navigator.of(context).pop(false);
                    },
                    scale: 0.9,
                    child: SizedBox(
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
                'audio.dayDownloadBody'.tr(
                  namedArgs: {
                    'reciter': reciter.name,
                    'surahs': '$surahCount',
                    'count': '$countForSize',
                    'size': formatBytes(estimated),
                  },
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: Insets.sm),
              Text(
                'audio.sourceNote'.tr(),
                style: theme.textTheme.bodySmall,
              ),

              if (ref.watch(isOnMobileDataProvider).valueOrNull ?? false) ...[
                const SizedBox(height: Insets.sm),
                _MobileDataNotice(),
              ],

              const SizedBox(height: Insets.md),

              if (download.isDownloading)
                _Progress(download: download, onCancel: notifier.cancel)
              else ...[
                if (download.hasFailed) ...[
                  _Failure(),
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

class _Failure extends StatelessWidget {
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
