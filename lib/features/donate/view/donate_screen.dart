import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../data/donation_links.dart';
import '../providers/donation_provider.dart';

/// "Destek ol" ekranı.
///
/// Ekranın tonu bilinçli olarak sakin: uygulamanın neden ücretsiz ve reklamsız
/// olduğunu anlatır, sonra bağış yollarını sıralar. Aciliyet dili ("son
/// şans", "yardım edin"), sayaç ya da hedef çubuğu yok — bunlar bir mushaf
/// uygulamasında yersiz durur ve kullanıcıyı borçlu hissettirir.
///
/// Karşılığında hiçbir şey vaat edilmez. Bu bir tercih değil, Google Play'in
/// ödeme politikasının şartı: gönüllü bağış istisnası ancak katkı karşılığı
/// uygulama içinde bir avantaj verilmediğinde geçerli (bkz. [DonationLinks]).
class DonateScreen extends ConsumerWidget {
  const DonateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(donationProvider);
    final channels = DonationLinks.active;

    return Scaffold(
      appBar: AppBar(
        title: Text('donate.title'.tr(), style: theme.textTheme.titleMedium),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: ListView(
          padding: centeredContentPadding(
            context,
            maxWidth: ContentWidth.reading,
            top: Insets.md,
            bottom: MediaQuery.paddingOf(context).bottom + Insets.xxl,
          ),
          children: [
            const _DonateHeader(),
            const SizedBox(height: Insets.lg),

            Text(
              'donate.explainTitle'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: Insets.xs),
            Text(
              'donate.explainBody'.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
            ),

            const SizedBox(height: Insets.lg),

            if (channels.isEmpty)
              _NoChannels(theme: theme)
            else ...[
              Text(
                'donate.waysTitle'.tr(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: Insets.xs),
              for (final channel in channels)
                Padding(
                  padding: const EdgeInsets.only(bottom: Insets.xs),
                  child: _ChannelTile(
                    channel: channel,
                    onTap: () => _openChannel(context, channel),
                  ),
                ),
            ],

            const SizedBox(height: Insets.lg),

            // Hatırlatmayı susturma. Ekranın altında durur: kullanıcı önce
            // bağış yollarını görür, susturma bir kaçış düğmesi gibi öne
            // çıkmaz. Zaten susturulmuşsa yerine bir teşekkür satırı gelir.
            if (state.isSilenced)
              _SilencedNote(theme: theme)
            else
              _SilenceActions(
                onDonated: () => _confirmDonated(context, ref),
                onNever: () => _confirmNever(context, ref),
              ),

            const SizedBox(height: Insets.md),
            Text(
              'donate.disclaimer'.tr(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Kanalı açar: bağlantıysa tarayıcıda, hesap numarasıysa panoya.
  Future<void> _openChannel(
    BuildContext context,
    DonationChannel channel,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);

    if (channel.kind == DonationKind.copy) {
      // Alıcı adı da kopyalanır: bankalar havalede adın IBAN'la eşleşmesini
      // istiyor, yalnızca numarayı kopyalayan kullanıcı adı ayrıca aramak
      // zorunda kalıyordu.
      final holder = channel.holder;
      final text =
          holder == null ? channel.value : '${channel.value}\n$holder';
      await Clipboard.setData(ClipboardData(text: text));
      messenger?.showSnackBar(
        SnackBar(
          content: Text('donate.copied'.tr()),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(channel.value);
    var opened = false;
    if (uri != null) {
      try {
        // Uygulama içi görünüm değil, cihazın tarayıcısı: ödeme akışı
        // uygulamanın dışında tamamlanmalı.
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        opened = false;
      }
    }

    if (!opened) {
      messenger?.showSnackBar(
        SnackBar(content: Text('donate.openFailed'.tr())),
      );
    }
  }

  Future<void> _confirmDonated(BuildContext context, WidgetRef ref) async {
    ref.read(donationProvider.notifier).markDonated();
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text('donate.thanks'.tr()),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _confirmNever(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('donate.neverConfirmTitle'.tr()),
        content: Text('donate.neverConfirmBody'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('donate.neverConfirmAction'.tr()),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      ref.read(donationProvider.notifier).dismissForever();
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text('donate.neverDone'.tr()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Ekranın başındaki görsel blok.
///
/// Bir ikon ve iki satır. Vurgu renginin çok hafif bir tonuyla dolgulanır —
/// dikkat çeker ama sayfayı bir kampanya afişine çevirmez.
class _DonateHeader extends StatelessWidget {
  const _DonateHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.md,
        vertical: Insets.lg,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(color: accent.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.volunteer_activism_outlined,
              size: 26,
              color: accent,
            ),
          ),
          const SizedBox(height: Insets.sm),
          Text(
            'donate.headline'.tr(),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: Insets.xxs),
          Text(
            'donate.subhead'.tr(),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tek bir bağış yolu.
class _ChannelTile extends StatelessWidget {
  const _ChannelTile({required this.channel, required this.onTap});

  final DonationChannel channel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCopy = channel.kind == DonationKind.copy;

    return Pressable(
      onTap: onTap,
      scale: 0.99,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.md,
          vertical: Insets.sm + 2,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: theme.dividerColor, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(
              isCopy
                  ? Icons.account_balance_outlined
                  : Icons.favorite_border_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: Insets.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(channel.titleKey.tr(), style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 1),
                  Text(
                    channel.subtitleKey.tr(),
                    style: theme.textTheme.bodySmall,
                  ),
                  // Hesap numarası ve alıcı adı, kopyalanan kanallarda
                  // ekranda da durur: kullanıcı kopyalamadan önce ne
                  // alacağını görmeli.
                  if (channel.kind == DonationKind.copy) ...[
                    const SizedBox(height: Insets.xxs),
                    Text(
                      channel.value,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (channel.holder != null)
                      Text(
                        '${'donate.holder'.tr()} ${channel.holder}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            // Simge eylemi söyler: kopyalanacak mı, dışarı mı çıkılacak.
            Icon(
              isCopy ? Icons.copy_rounded : Icons.open_in_new_rounded,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hiçbir kanal yapılandırılmamışsa. Kullanıcı bu ekranı normalde göremez
/// (giriş noktaları da gizlenir); bu yalnızca geliştirme sırasında bir
/// güvenlik ağı.
class _NoChannels extends StatelessWidget {
  const _NoChannels({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Text(
        'donate.noChannels'.tr(),
        style: theme.textTheme.bodySmall,
      ),
    );
  }
}

class _SilenceActions extends StatelessWidget {
  const _SilenceActions({required this.onDonated, required this.onNever});

  final VoidCallback onDonated;
  final VoidCallback onNever;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Divider(color: theme.dividerColor),
        const SizedBox(height: Insets.xs),
        // "Destekledim" doğrulanmaz — doğrulamak için sunucu ve kimlik
        // gerekirdi. Kullanıcının sözüne güvenilir.
        TextButton(
          onPressed: onDonated,
          child: Text('donate.alreadyDonated'.tr()),
        ),
        TextButton(
          onPressed: onNever,
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurface.withValues(
              alpha: 0.5,
            ),
          ),
          child: Text('donate.never'.tr()),
        ),
      ],
    );
  }
}

class _SilencedNote extends StatelessWidget {
  const _SilencedNote({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: Text(
              'donate.silenced'.tr(),
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
