import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/notifications/daily_ayah_notifications.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/reader_preferences.dart';
import '../../../data/models/reciter.dart';
import '../../audio/providers/download_provider.dart';
import '../../audio/widgets/audio_download_sheet.dart';
import '../../donate/data/donation_links.dart';
import '../../donate/widgets/support_banner.dart';
import '../../../shared/widgets/pressable.dart';
import '../providers/preferences_provider.dart';
import '../../onboarding/providers/tour_provider.dart';
import '../../../shared/widgets/tab_bar_inset.dart';
import '../../../shared/widgets/responsive_layout.dart';

/// Ayarlar ekranı.
///
/// Bölümler iOS'un Ayarlar uygulamasındaki gibi gruplanır: her grup kendi
/// yüzeyinde, üstünde küçük bir başlıkla. Bu düzen uzun listeleri taranabilir
/// kılar ve kullanıcı için tanıdıktır.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final prefs = ref.watch(preferencesProvider);
    final notifier = ref.read(preferencesProvider.notifier);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        left: false,
        right: false,
        child: ListView(
          // Geniş/yatay ekranda ayar grupları ekranın tamamına yayılmaz;
          // ortada okunabilir bir sütunda kalır.
          padding: centeredContentPadding(
            context,
            top: Insets.md,
            bottom: bottomInsetFor(context) + Insets.lg,
          ),
          children: [
            Text('nav.settings'.tr(), style: theme.textTheme.displaySmall),
            const SizedBox(height: Insets.lg),

            // Destek çağrısı listenin en başında, kendi bölümü olmadan.
            // Bir ayar değil — bir davet; bu yüzden ayar gruplarının
            // biçimini taklit etmez, kendi yüzeyinde durur. Bağış kanalı
            // yapılandırılmamışsa hiç çizilmez.
            if (DonationLinks.isConfigured) ...[
              const SupportBanner(),
              const SizedBox(height: Insets.lg),
            ],

            _Section(
              title: 'settings.appearance'.tr(),
              children: [
                _ThemeRow(
                  value: prefs.themeMode,
                  onChanged: notifier.setThemeMode,
                ),
              ],
            ),

            _Section(
              title: 'settings.language'.tr(),
              children: [
                _LanguageRow(
                  value: context.locale,
                  onChanged: (locale) => context.setLocale(locale),
                ),
              ],
            ),

            _Section(
              title: 'settings.reading'.tr(),
              children: [
                _SliderTile(
                  label: 'settings.fontSize'.tr(),
                  value: prefs.fontScale,
                  min: 0.8,
                  max: 1.6,
                  divisions: 8,
                  displayValue: '%${(prefs.fontScale * 100).round()}',
                  onChanged: notifier.setFontScale,
                ),
                _SliderTile(
                  label: 'settings.lineHeight'.tr(),
                  value: prefs.lineHeight,
                  min: 1.4,
                  max: 2.2,
                  divisions: 8,
                  displayValue: prefs.lineHeight.toStringAsFixed(1),
                  onChanged: notifier.setLineHeight,
                ),
                // Punto ve satır aralığı soyut sayılardır; "%120" ya da "1.8"
                // metnin ekranda nasıl duracağını anlatmaz. Örnek satır,
                // ayarın sonucunu okuma ekranına gitmeden gösterir.
                _ReadingPreview(prefs: prefs),
                _SwitchTile(
                  label: 'settings.showArabic'.tr(),
                  subtitle: 'settings.showArabicHint'.tr(),
                  value: prefs.showArabic,
                  onChanged: notifier.setShowArabic,
                ),
                _SwitchTile(
                  label: 'settings.sortByRevelation'.tr(),
                  subtitle: 'settings.sortByRevelationHint'.tr(),
                  value: prefs.sortByRevelation,
                  onChanged: notifier.setSortByRevelation,
                ),
              ],
            ),

            // Ses bölümü okuma ayarlarının hemen ardından: ikisi de okuma
            // deneyimini biçimlendirir, bildirim ve yasal başlıklar ise
            // uygulamanın çeperinde kalır.
            _Section(
              // Bölüm başlığı `audio.listen`'den ayrı bir anahtar: o metin
              // okuma ekranındaki düğmenin ipucu ("Dinle") ve orada büyük
              // harf yanlış olurdu. Buradaki başlıklar ise diğer bölümlerle
              // aynı biçimde, büyük harfle yazılır.
              title: 'settings.audioSection'.tr(),
              children: [
                _ReciterRow(
                  selectedId: prefs.reciterId,
                  onSelect: notifier.setReciter,
                ),
                _SliderTile(
                  label: 'audio.playbackSpeed'.tr(),
                  value: prefs.playbackSpeed,
                  min: 0.5,
                  max: 2.0,
                  divisions: 6,
                  displayValue: '${prefs.playbackSpeed.toStringAsFixed(2)}×',
                  onChanged: notifier.setPlaybackSpeed,
                ),
                _SwitchTile(
                  label: 'audio.autoScroll'.tr(),
                  subtitle: 'audio.autoScrollDescription'.tr(),
                  value: prefs.autoScrollWithAudio,
                  onChanged: notifier.setAutoScrollWithAudio,
                ),
                _SwitchTile(
                  label: 'audio.highlightWords'.tr(),
                  subtitle: 'audio.highlightWordsDescription'.tr(),
                  value: prefs.highlightWords,
                  onChanged: notifier.setHighlightWords,
                ),
                const _DownloadedAudioTile(),
                // Kaynak ve indirme koşulları. Ayarların içinde durur çünkü
                // kullanıcı bu bilgiyi telif sayfasında değil, sesi yönettiği
                // yerde arar.
                _ActionTile(
                  label: 'audio.about'.tr(),
                  subtitle: 'audio.aboutHint'.tr(),
                  onTap: () => context.push('/ses-hakkinda'),
                ),
              ],
            ),

            _Section(
              title: 'home.verseOfDay'.tr(),
              children: [
                _SwitchTile(
                  label: 'settings.notification'.tr(),
                  subtitle: 'settings.notificationHint'.tr(),
                  value: prefs.dailyAyahEnabled,
                  onChanged: (value) => _setNotification(
                    context,
                    notifier,
                    value,
                    time: prefs.dailyAyahTime,
                  ),
                ),
                if (prefs.dailyAyahEnabled)
                  _TimeTile(
                    label: 'settings.notificationTime'.tr(),
                    value: prefs.dailyAyahTime,
                    onChanged: (time) {
                      notifier.setDailyAyahTime(time);
                      // Saat değişince kayıt yeniden kurulur; aksi halde
                      // bildirim eski saatte düşmeye devam ederdi.
                      _scheduleDailyAyah(context, time);
                    },
                  ),
              ],
            ),

            _Section(
              title: 'settings.resetSection'.tr(),
              children: [
                _ActionTile(
                  label: 'settings.resetReading'.tr(),
                  subtitle: 'settings.resetReadingHint'.tr(),
                  onTap: () => _confirmReset(context, notifier),
                ),
                // İpuçları bir kez gösterilip kapanır; kullanıcı uygulamayı
                // birine anlatırken ya da unuttuğunda geri çağırabilmeli.
                _ActionTile(
                  label: 'tour.replay'.tr(),
                  subtitle: 'tour.replayHint'.tr(),
                  onTap: () {
                    ref.read(tourProvider.notifier).resetAll();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('tour.replayDone'.tr()),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Mağazalar gizlilik politikası ve kullanım şartlarının uygulama
            // içinden erişilebilir olmasını şart koşar.
            _Section(
              title: 'settings.legal'.tr(),
              children: [
                _ActionTile(
                  label: 'settings.privacy'.tr(),
                  onTap: () => context.push('/gizlilik'),
                ),
                _ActionTile(
                  label: 'settings.terms'.tr(),
                  onTap: () => context.push('/kosullar'),
                ),
                _ActionTile(
                  label: 'settings.sources'.tr(),
                  onTap: () => context.push('/kaynaklar'),
                ),
                _ActionTile(
                  label: 'settings.licenses'.tr(),
                  onTap: () => _showLicenses(context),
                ),
                const _VersionTile(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Bildirim anahtarı. Açılırken önce izin istenir; kullanıcı reddederse
  /// ayar açık bırakılmaz — çalışmayan bir anahtar göstermek yanıltıcı olur.
  Future<void> _setNotification(
    BuildContext context,
    PreferencesNotifier notifier,
    bool value, {
    required TimeOfDay time,
  }) async {
    final messenger = ScaffoldMessenger.maybeOf(context);

    if (!value) {
      notifier.setDailyAyahEnabled(false);
      await DailyAyahNotifications.instance.cancel();
      return;
    }

    final granted = await DailyAyahNotifications.instance.requestPermission();
    if (!granted) {
      notifier.setDailyAyahEnabled(false);
      messenger?.showSnackBar(
        SnackBar(content: Text('settings.notificationDenied'.tr())),
      );
      return;
    }

    notifier.setDailyAyahEnabled(true);
    if (context.mounted) _scheduleDailyAyah(context, time);
  }

  void _scheduleDailyAyah(BuildContext context, TimeOfDay time) {
    DailyAyahNotifications.instance.schedule(
      hour: time.hour,
      minute: time.minute,
      title: 'settings.dailyAyahTitle'.tr(),
      body: 'settings.dailyAyahBody'.tr(),
    );
  }

  /// Kullanılan açık kaynak paketlerin lisansları. Flutter'ın hazır ekranı
  /// tüm bağımlılıkları toplayıp listeler.
  void _showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'app.title'.tr(),
      applicationLegalese: 'settings.footer'.tr(),
    );
  }

  Future<void> _confirmReset(
    BuildContext context,
    PreferencesNotifier notifier,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('settings.resetConfirmTitle'.tr()),
        content: Text('settings.resetConfirmBody'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('common.reset'.tr()),
          ),
        ],
      ),
    );

    if (confirmed ?? false) notifier.resetReadingDefaults();
  }
}

/// Başlıklı ayar grubu.
/// Bölüm içinde kendi zemini olan öğeler bunu uygular.
///
/// [_Section] satırların arasına ayırıcı koyar; bu ayırıcı, kendi kartı olan
/// bir öğenin (örnek metin kutusu gibi) üst kenarına yapışıp çakışıyordu.
/// Ayırıcı iki düz satırı ayırmak içindir — zaten kendi çerçevesi olan bir
/// öğenin sınırını ayrıca çizmeye gerek yok.
abstract interface class _SelfContained {}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  /// [i] ile bir önceki çocuğun arasına ayırıcı gerekip gerekmediği.
  bool _needsDivider(int i) {
    if (i == 0) return false;
    return children[i] is! _SelfContained &&
        children[i - 1] is! _SelfContained;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: Insets.xs,
              bottom: Insets.xs,
            ),
            child: Text(
              title,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(Radii.lg),
              border: Border.all(color: theme.dividerColor, width: 0.5),
            ),
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (_needsDivider(i))
                    Divider(
                      height: 1,
                      color: theme.dividerColor,
                      indent: Insets.md,
                    ),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.md,
        vertical: Insets.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(subtitle!, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          const SizedBox(width: Insets.sm),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// Okuma ayarlarının canlı örneği.
///
/// Ayarlar ekranından okuma ekranına gidip geri dönmeden, seçilen punto ve
/// satır aralığının gerçek metinde nasıl durduğunu gösterir. Örnek metin
/// gerçek bir ayet mealidir — uydurma bir "Lorem ipsum" satırı, asıl
/// kullanımdaki satır uzunluğunu ve kelime ritmini yansıtmazdı.
class _ReadingPreview extends StatelessWidget implements _SelfContained {
  const _ReadingPreview({required this.prefs});

  final ReaderPreferences prefs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      // Üstte de boşluk var: ayırıcı kaldırıldığı için (bkz. [_SelfContained])
      // kutu bir üstteki satıra yapışık dururdu.
      padding: const EdgeInsets.fromLTRB(
        Insets.md,
        Insets.sm,
        Insets.md,
        Insets.sm,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Insets.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'settings.previewLabel'.tr(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: Insets.xs),
            // Ayarlar anında yansısın; kullanıcı sürüklerken sonucu görür.
            AnimatedDefaultTextStyle(
              duration: Motion.fast,
              curve: Motion.standard,
              style: AppTypography.reading(
                fontSize: prefs.translationFontSize,
                color: theme.colorScheme.onSurface,
                height: prefs.lineHeight,
              ),
              child: Text('settings.previewText'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

/// Punto ve satır aralığı gibi sürekli değerler için kaydırıcı satırı.
///
/// Material'ın varsayılan kaydırıcısı tema dışında kalıyordu: adım noktaları
/// (tick) rayı benekli gösteriyor, beyaz topuz koyu temada parlıyor ve ray
/// ekranın kenarına kadar uzanıyordu. Burada ray inceltilip yuvarlatıldı,
/// topuz yüzey rengiyle çevrelendi ve noktalar kaldırıldı — değer zaten
/// sağdaki etiketle okunuyor, rayın kendisi sessiz kalmalı.
class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayValue,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayValue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Insets.md,
        Insets.sm,
        Insets.md,
        Insets.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: theme.textTheme.bodyLarge),
              const Spacer(),
              // Değer rozeti — sayı, etiketten görsel olarak ayrılsın.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Insets.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Text(
                  displayValue,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                    // Sürüklerken sayı genişliği değişmesin, düzen zıplamasın.
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.xxs),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              trackShape: const RoundedRectSliderTrackShape(),
              // Adım noktaları kaldırılır; ray tek bir sakin çizgi olur.
              tickMarkShape: SliderTickMarkShape.noTickMark,
              // Hazır yuvarlak topuz; yarıçapı büyütülüp ray inceltilince
              // topuz raydan yeterince ayrılıyor, özel bir biçime gerek yok.
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 10,
                elevation: 0,
                pressedElevation: 0,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              activeTrackColor: theme.colorScheme.primary,
              inactiveTrackColor: theme.colorScheme.surfaceContainer,
              overlayColor: theme.colorScheme.primary.withValues(alpha: 0.10),
              // Topuz vurgu renginde; beyaz topuz koyu temada parlıyordu.
              thumbColor: theme.colorScheme.primary,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Pressable(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: value,
          // 24 saat biçimi Türkiye'de standart.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      scale: 0.99,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.md,
          vertical: Insets.md,
        ),
        child: Row(
          children: [
            Text(label, style: theme.textTheme.bodyLarge),
            const Spacer(),
            Text(
              '${value.hour.toString().padLeft(2, '0')}:'
              '${value.minute.toString().padLeft(2, '0')}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: Insets.xxs),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sürüm numarası satırı.
///
/// Mağaza incelemesinde ve kullanıcı hata bildirirken hangi yapının
/// çalıştığını görmek gerekir. Değer paketten okunur; elle yazılan bir
/// sürüm numarası zamanla pubspec ile ayrışırdı.
class _VersionTile extends StatefulWidget {
  const _VersionTile();

  @override
  State<_VersionTile> createState() => _VersionTileState();
}

class _VersionTileState extends State<_VersionTile> {
  String? _version;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _version = '${info.version} (${info.buildNumber})');
    } catch (_) {
      // Testlerde ve platform kanalı olmayan ortamlarda sürüm okunamaz;
      // satır sessizce boş kalır, ayarlar ekranı yine de açılır.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.md,
        vertical: Insets.md,
      ),
      child: Row(
        children: [
          Text('settings.version'.tr(), style: theme.textTheme.bodyLarge),
          const Spacer(),
          Text(
            _version ?? '—',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Pressable(
      onTap: onTap,
      scale: 0.99,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.md,
          vertical: Insets.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodyLarge),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(subtitle!, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tema seçimi — üç seçenek yan yana.
class _ThemeRow extends StatelessWidget {
  const _ThemeRow({required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(Insets.md),
      child: Row(
        children: [
          for (final (mode, label, icon) in [
            (ThemeMode.light, 'settings.light'.tr(), Icons.light_mode_rounded),
            (ThemeMode.dark, 'settings.dark'.tr(), Icons.dark_mode_rounded),
            (ThemeMode.system, 'settings.system'.tr(), Icons.phone_iphone_rounded),
          ]) ...[
            Expanded(
              child: Pressable(
                onTap: () => onChanged(mode),
                scale: 0.96,
                child: AnimatedContainer(
                  duration: Motion.fast,
                  curve: Motion.standard,
                  padding: const EdgeInsets.symmetric(vertical: Insets.sm),
                  decoration: BoxDecoration(
                    color: value == mode
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(Radii.md),
                    border: Border.all(
                      color: value == mode
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        icon,
                        size: 19,
                        color: value == mode
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 0,
                          fontWeight: FontWeight.w600,
                          color: value == mode
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (mode != ThemeMode.system) const SizedBox(width: Insets.xs),
          ],
        ],
      ),
    );
  }
}


/// Uygulama dili seçimi.
///
/// İki dil olduğu için segmentli düğme kullanıldı; açılır menü tek bir
/// seçeneği gizler ve gereksiz bir dokunuş ekler.
class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.value, required this.onChanged});

  final Locale value;
  final ValueChanged<Locale> onChanged;

  static const _options = <(Locale, String)>[
    (Locale('tr'), 'Türkçe'),
    (Locale('en'), 'English'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(Insets.md),
      child: Row(
        children: [
          for (final (locale, label) in _options) ...[
            Expanded(
              child: Pressable(
                onTap: () => onChanged(locale),
                scale: 0.96,
                child: AnimatedContainer(
                  duration: Motion.fast,
                  curve: Motion.standard,
                  padding: const EdgeInsets.symmetric(vertical: Insets.sm),
                  decoration: BoxDecoration(
                    color: value.languageCode == locale.languageCode
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(Radii.md),
                    border: Border.all(
                      color: value.languageCode == locale.languageCode
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: value.languageCode == locale.languageCode
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ),
            if (locale != _options.last.$1) const SizedBox(width: Insets.xs),
          ],
        ],
      ),
    );
  }
}

/// Kari seçimi.
///
/// Liste açılır menü yerine satır olarak verilir: seçenek sayısı az ve her
/// birinin adı uzun. Açılır menüde adlar kırpılır, satırda tamamı okunur.
///
/// Kari değiştirmek indirilmiş sesleri geçersiz kılmaz ama yeni kari için
/// ses yeniden indirilmelidir; bu yüzden seçim altında kısa bir uyarı durur.
class _ReciterRow extends StatelessWidget {
  const _ReciterRow({required this.selectedId, required this.onSelect});

  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = Reciter.byId(selectedId);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.md,
        vertical: Insets.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('audio.reciter'.tr(), style: theme.textTheme.bodyLarge),
          const SizedBox(height: 2),
          // "Kari" terimi herkese tanıdık değil; seçimin ne işe yaradığı
          // başlığın altında bir cümleyle söylenir. Diğer ayar satırları da
          // aynı desende (bkz. `_SwitchTile` alt yazısı).
          Text(
            'audio.reciterHint'.tr(),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: Insets.sm),
          for (final reciter in Reciter.all)
            Pressable(
              onTap: () => onSelect(reciter.id),
              scale: 0.99,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Insets.xs),
                child: Row(
                  children: [
                    Icon(
                      reciter.id == selected.id
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 19,
                      color: reciter.id == selected.id
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(width: Insets.sm),
                    Expanded(
                      child: Text(
                        reciter.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: reciter.id == selected.id
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// İndirilmiş seslerin toplamı ve toplu silme.
///
/// Yüzlerce megabaytlık ses, kullanıcının cihazında uygulamanın kapladığı
/// yerin çoğunu oluşturabilir. Nereden silineceğinin bulunabilir olması bu
/// yüzden önemli: aksi halde kullanıcı yer açmak için uygulamayı siler.
class _DownloadedAudioTile extends ConsumerWidget {
  const _DownloadedAudioTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final size = ref.watch(downloadedSizeProvider).valueOrNull ?? 0;
    final surahs = ref.watch(downloadedSurahsProvider).valueOrNull ?? const {};

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.md,
        vertical: Insets.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'audio.downloads'.tr(),
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  surahs.isEmpty
                      ? 'audio.noDownloads'.tr()
                      : 'audio.downloadsSize'.tr(
                          namedArgs: {'size': formatBytes(size)},
                        ),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (surahs.isNotEmpty)
            Pressable(
              onTap: () => _confirmDeleteAll(context, ref),
              scale: 0.96,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Insets.xs,
                  vertical: Insets.xs,
                ),
                child: Text(
                  'audio.deleteAll'.tr(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('audio.deleteAll'.tr()),
        content: Text('audio.deleteAllConfirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('audio.delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final reciter = ref.read(selectedReciterProvider);
    await ref.read(audioRepositoryProvider).deleteAll(reciter);

    // Boyut ve liste yeniden okunur; silinen sesler ekranda kalmamalı.
    ref
      ..invalidate(downloadedSizeProvider)
      ..invalidate(downloadedSurahsProvider);
  }
}
