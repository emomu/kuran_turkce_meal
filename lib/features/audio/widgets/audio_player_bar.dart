import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/pressable.dart';
import '../providers/audio_provider.dart';

/// Tilavet çubuğu.
///
/// Tasarım kararları:
///  - Çubuk yalnızca ses etkinken vardır. Kapalıyken uygulama hiç değişmemiş
///    gibi görünür; ses, metnin önüne geçen kalıcı bir arayüz öğesi değildir.
///  - Müzik çalar öğeleri (kapak görseli, süre çubuğu, ses seviyesi) bilerek
///    yok. Burada çalınan bir parça değil okunmakta olan bir metin; kullanıcı
///    saniyeyi değil ayeti takip eder. Bu yüzden konum bilgisi ayet referansı
///    olarak verilir.
///  - Renk kullanımı asgari: yüzey rengi kartlarla aynı, tek vurgu çalma
///    düğmesinde. Uzun okuma seansında ekranın altında duran bir öğe dikkat
///    çekmemeli.
///
/// Çubuk hem okuma ekranında hem de sekmeli kabukta kullanılır: ses çalarken
/// kullanıcı ana sayfaya ya da ayarlara geçtiğinde kontrolü kaybetmemeli.
/// Sure adı bu yüzden dışarıdan verilmez, çalan sureden okunur — kabuğun
/// hangi surenin çaldığını bilmesi gerekmez.
class AudioPlayerBar extends ConsumerWidget {
  const AudioPlayerBar({
    super.key,
    this.surahNumber,
    this.applyBottomSafeArea = true,
  });

  /// Verilirse çubuk yalnızca bu sure çalarken görünür.
  ///
  /// Okuma ekranı bunu verir: orada çubuk, okunan metnin altındaki bir
  /// kontroldür ve başka bir surenin sesini yönetmesi kafa karıştırır.
  /// Kabukta ise verilmez — orada çubuk, nerede olursan ol erişilebilen genel
  /// bir denetimdir.
  final int? surahNumber;

  /// Çubuğun altına sistem güvenli alanı eklenip eklenmeyeceği.
  ///
  /// Okuma ekranında çubuk ekranın en altındadır ve çentik/ana ekran
  /// çizgisinin üstünde kalmalıdır. Sekmeli kabukta ise altında zaten sekme
  /// çubuğu vardır ve o kendi güvenli alanını uygular; burada da uygulanırsa
  /// araya bir parmak boyu boşluk girer.
  final bool applyBottomSafeArea;

  /// Çubuğun yüksekliği (alt güvenli alan hariç).
  ///
  /// 1pt üst çizgi + 12pt nefes + 44pt denetim + 12pt nefes. Çubuğun üstünde
  /// duran öğeler (asistan düğmesi) bu payı kendileri bırakır: çubuk
  /// `bottomNavigationBar` yuvasında olmadığı ekranlarda `Scaffold` onu
  /// hesaba katmaz.
  static const double barHeight = 69;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioProvider);
    final isVisible =
        audio.isActive &&
        (surahNumber == null || audio.surahNumber == surahNumber);

    // Çubuk aşağıdan kayarak girer ve çıkar. Anlık belirseydi liste bir anda
    // yukarı sıçrar ve okunan satır kayardı.
    return AnimatedSlide(
      offset: isVisible ? Offset.zero : const Offset(0, 1),
      duration: Motion.normal,
      curve: Motion.standard,
      child: AnimatedOpacity(
        opacity: isVisible ? 1 : 0,
        duration: Motion.fast,
        child: isVisible
            ? _Bar(applyBottomSafeArea: applyBottomSafeArea)
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _Bar extends ConsumerWidget {
  const _Bar({required this.applyBottomSafeArea});

  final bool applyBottomSafeArea;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final audio = ref.watch(audioProvider);
    final notifier = ref.read(audioProvider.notifier);

    // Sure adı veritabanından gelir ve ilk karede henüz hazır olmayabilir.
    // Beklerken çubuk boş bir satır göstermez; ad gelene kadar yeri korunur.
    final surah = ref.watch(playingSurahProvider).valueOrNull;
    final surahName = surah?.nameFor(context.locale.languageCode) ?? '';

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          // Üstte metinden, altta sekme şeridinden ayıran ince çizgiler.
          // Alttaki yalnızca kabukta anlamlı ama her iki yerde de çizilir:
          // okuma ekranında çubuk zaten en altta olduğu için görünmez.
          top: BorderSide(color: theme.dividerColor, width: 1),
          bottom: BorderSide(color: theme.dividerColor, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: applyBottomSafeArea,
        child: Padding(
          // Yatayda ekran kenar boşluğuyla, dikeyde rahat bir nefes payıyla.
          // Daha dar denendi: künye ile denetimler birbirine değiyor ve
          // çubuk sekme şeridine yapışık görünüyordu.
          padding: const EdgeInsets.fromLTRB(
            Insets.screenGutter,
            Insets.sm,
            Insets.sm,
            Insets.sm,
          ),
          child: Row(
            children: [
              // Hangi ayetin okunduğu. Süre yerine ayet referansı verilir —
              // metni takip eden kullanıcının aradığı bilgi budur.
              //
              // Künyeye dokunmak okunan ayete götürür. Kullanıcı başka bir
              // sekmedeyken sesi duyup "bu neredeydi?" dediğinde geri dönüş
              // yolu bu; sureyi listeden yeniden aramak zorunda kalmaz.
              Expanded(
                child: Pressable(
                  onTap: () {
                    final number = audio.surahNumber;
                    if (number == null) return;
                    final ayah = audio.currentAyahNumber;
                    context.push(
                      ayah == null
                          ? '/sure/$number'
                          : '/sure/$number?ayet=$ayah',
                    );
                  },
                  scale: 0.99,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        surahName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        audio.currentAyahNumber == null
                            ? 'audio.preparing'.tr()
                            : 'audio.nowPlaying'.tr(
                                namedArgs: {
                                  'verse': '${audio.currentAyahNumber}',
                                },
                              ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ),

              // Künye ile denetimler arasında ayrım payı; metin uzun sure
              // adlarında düğmelere dayanmasın.
              const SizedBox(width: Insets.sm),

              _ControlButton(
                icon: Icons.skip_previous_rounded,
                onTap: notifier.previous,
                semanticLabel: 'audio.previous'.tr(),
              ),
              _PlayButton(
                isPlaying: audio.isPlaying,
                isLoading: audio.isLoading,
                onTap: notifier.togglePlayPause,
              ),
              _ControlButton(
                icon: Icons.skip_next_rounded,
                onTap: notifier.next,
                semanticLabel: 'audio.next'.tr(),
              ),

              // Kapatma, gezinme denetimlerinden ayrılır: yan yana dursaydı
              // sıradaki ayete geçmek isteyen parmak sesi kapatabilirdi.
              const SizedBox(width: Insets.xxs),
              _ControlButton(
                icon: Icons.close_rounded,
                onTap: notifier.stop,
                semanticLabel: 'audio.stop'.tr(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ortadaki çalma/duraklatma düğmesi. Tek vurgulu öğe.
class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.isPlaying,
    required this.isLoading,
    required this.onTap,
  });

  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Pressable(
      onTap: isLoading ? null : onTap,
      scale: 0.92,
      hapticOnTap: true,
      child: Container(
        width: 44,
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: Insets.xs),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: isLoading
            // Dosyalar cihazdan okunduğu için bekleme çok kısa; yine de
            // düğmenin tepkisiz göründüğü bir an olmasın.
            ? Padding(
                padding: const EdgeInsets.all(13),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onPrimary,
                ),
              )
            : Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: theme.colorScheme.onPrimary,
                size: 24,
              ),
      ),
    );
  }
}

/// Yan kontroller — sade, çerçevesiz.
class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Pressable(
        onTap: onTap,
        scale: 0.9,
        child: SizedBox(
          // Dokunma alanı 44pt'nin altına düşmemeli (Apple HIG).
          width: 44,
          height: 44,
          child: Icon(
            icon,
            size: 22,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
