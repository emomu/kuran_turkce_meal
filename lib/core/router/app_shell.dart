import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_typography.dart';
import '../../features/audio/widgets/audio_player_bar.dart';
import '../../shared/widgets/responsive_layout.dart';

/// Alt sekme çubuğunu barındıran kabuk.
///
/// Sekme çubuğu yalnızca ana bölümlerde görünür; okuma ve plan detayı gibi
/// derinlemesine ekranlar kabuğun dışına itilir (bkz. router). Böylece okuma
/// ekranı tüm yüksekliği kullanır — uzun metin okurken sabit bir çubuk
/// ekranın altını yer.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Sekme çubuğunun yüksekliği (güvenli alan hariç).
  ///
  /// Dikey ritim: 7pt nefes + 28pt yastık(3+22+3) + 3pt + 12pt etiket
  /// + 7pt nefes. 52pt sıkışıktı (ikon ve etiket değiyordu); 56pt'de
  /// yastık içeriği yukarı itip altta ölü boşluk bırakıyordu.
  static const double barHeight = 62;

  // Etiketler çeviriden geldiği için liste `const` olamaz; dil değişince
  // yeniden hesaplanması da zaten gerekir.
  static List<({IconData icon, IconData activeIcon, String label})>
  get _destinations => [
    (
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book_rounded,
      label: 'nav.read'.tr(),
    ),
    (
      icon: Icons.search_outlined,
      activeIcon: Icons.search_rounded,
      label: 'nav.search'.tr(),
    ),
    (
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today_rounded,
      label: 'nav.plans'.tr(),
    ),
    (
      icon: Icons.bookmark_outline_rounded,
      activeIcon: Icons.bookmark_rounded,
      label: 'nav.saved'.tr(),
    ),
    (
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'nav.settings'.tr(),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Yatayda çentik solda ya da sağda kalır; sekmeler onun altına
    // kaymasın diye güvenli alan yatayda da uygulanır. Sekme şeridi ayrıca
    // çok geniş ekranlarda uçlara yayılmaz, ortada toplanır.
    final bar = SafeArea(
      top: false,
      child: SizedBox(
        height: barHeight,
        child: Center(
          child: ConstrainedBox(
            // Geniş ekranda beş sekme ekranın iki ucuna dağılırsa başparmakla
            // ulaşmak zorlaşır ve çubuk seyrek görünür; ortada toplanır.
            constraints: const BoxConstraints(maxWidth: ContentWidth.standard),
            child: Row(
              children: [
                for (var i = 0; i < _destinations.length; i++)
                  Expanded(
                    child: _NavItem(
                      destination: _destinations[i],
                      isSelected: navigationShell.currentIndex == i,
                      // Seçili sekmeye tekrar dokunmak o dalın köküne döner —
                      // iOS'ta beklenen davranış budur.
                      onTap: () => navigationShell.goBranch(
                        i,
                        initialLocation: i == navigationShell.currentIndex,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      // Boşluğa dokununca klavye kapanır.
      //
      // iOS'ta klavyeyi kapatmanın yerleşik bir yolu yok: Android'in geri
      // tuşu gibi bir çıkış bulunmadığı için kullanıcı arama alanına yazdıktan
      // sonra klavyeyle baş başa kalır ve listenin yarısı örtülü kalırdı.
      //
      // `onTap` yerine `onTapDown` kullanılır: dokunma tamamlanmadan kapanır,
      // böylece liste öğesine basıldığında klavye kapanışıyla gezinme aynı
      // anda başlar ve arada bir kare gecikme hissedilmez.
      //
      // `HitTestBehavior.translucent`: alttaki widget'lar dokunuşu almaya
      // devam eder. Opak olsaydı bu katman listenin dokunuşlarını yutar ve
      // hiçbir sureye girilemezdi.
      //
      // `GestureDetector` yerine `TapRegion` kullanılır: `GestureDetector`
      // widget ağacına bir katman ekliyor ve sekme çubuğunu ölçen testler
      // (bkz. app_shell_test.dart) `GestureDetector.first` ile artık o
      // katmanı buluyordu. `TapRegion` ayrıca doğru soruyu soruyor:
      // "dokunuş odaklanmış alanın dışında mı" — kaydırma ve liste
      // dokunuşlarını hiç engellemez.
      body: TapRegion(
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        child: navigationShell,
      ),
      // Tilavet çubuğu sekmelerin üstünde durur ve hangi sekmede olunursa
      // olunsun görünür: ses çalarken kullanıcı ana sayfaya ya da ayarlara
      // geçtiğinde onu durduramamak, kontrolü aramak için okuma ekranına
      // dönmeyi gerektirirdi.
      //
      // Sekme çubuğunun içine değil üstüne konur: sekmeler gezinme, bu ise
      // bir durum denetimi. İkisi tek şeritte birleşseydi hem yükseklik iki
      // katına çıkar hem de dokunma hedefleri birbirine yaklaşırdı.
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Kabuktaki çubuk sure numarası almaz: burada hangi sure çalıyorsa
          // onu yönetir.
          const AudioPlayerBar(applyBottomSafeArea: false),
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: theme.dividerColor, width: 0.5),
              ),
            ),
            child: bar,
          ),
        ],
      ),
    );
  }
}

/// Tek bir sekme.
///
/// Seçim geçişi üç ayrı hareketten oluşur ve hepsi aynı süre/eğriyi paylaşır,
/// böylece tek bir hareket gibi okunur:
///  - ikon dolu biçime geçer ve hafifçe büyür,
///  - renk vurguya döner,
///  - ikonun arkasında bir vurgu yastığı belirir.
///
/// Ölçek yaylanması bilinçlidir: Instagram ve iOS'un kendi sekmelerindeki
/// gibi, dokunuşun fiziksel bir karşılığı olduğunu hissettirir.
class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  final ({IconData icon, IconData activeIcon, String label}) destination;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  /// Dokunuşta hafif basılma; parmağın altında bir şey olduğu hissi.
  late final Animation<double> _press = Tween<double>(
    begin: 1,
    end: 0.88,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  bool _isPressed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
    if (value) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _handleTap() {
    if (!widget.isSelected) HapticFeedback.selectionClick();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = widget.isSelected;
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.45);

    return Semantics(
      button: true,
      selected: selected,
      label: widget.destination.label,
      child: GestureDetector(
        onTap: _handleTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _press,
          builder: (context, child) =>
              Transform.scale(scale: _press.value, child: child),
          child: _buildTab(theme, selected, color),
        ),
      ),
    );
  }

  /// Sekmenin içeriği: ikon üstte, etiket altta.
  Widget _buildTab(ThemeData theme, bool selected, Color color) {
    // Görsel merkez, kutu merkeziyle aynı yer değil.
    //
    // `Column` çocuklarının KUTULARINI ortalar; göz ise mürekkebi görür.
    // Etiketin kutusunda altta descender boşluğu, yastıkta üstte iç dolgu
    // var. Ölçüldü: kutular tam eşit dururken (10.5/10.5) görünen boşluk
    // üstte 16.5, altta 14.0 çıkıyordu — içerik yukarı kaymış görünüyordu.
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Vurgu yastığı — seçili sekmeyi ikon renginden bağımsız olarak da
        // belli eder; renk körlüğünde tek ipucu renk olmamalı.
        AnimatedContainer(
          duration: Motion.normal,
          curve: Motion.emphasized,
          padding: EdgeInsets.symmetric(
            horizontal: selected ? 14 : 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(Radii.pill),
          ),
          child: AnimatedSwitcher(
            duration: Motion.normal,
            switchInCurve: Motion.emphasized,
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: Tween<double>(begin: 0.82, end: 1).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Icon(
              selected
                  ? widget.destination.activeIcon
                  : widget.destination.icon,
              key: ValueKey(selected),
              size: 22,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 3),
        AnimatedDefaultTextStyle(
          duration: Motion.normal,
          curve: Motion.standard,
          style: theme.textTheme.labelSmall!.copyWith(
            fontSize: 12,
            // Satır yüksekliği sabitlenir; aksi halde yazı tipinin kendi
            // metrikleri satırı büyütüp dikey dengeyi kaydırır.
            height: 1.2,
            letterSpacing: 0,
            color: color,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
          child: Text(
            widget.destination.label,
            // Etiket tek satırda kalmalı; sarmasına izin verilirse içerik
            // çubuğun yüksekliğini aşar — ölçüldü: 390pt genişlikte
            // "Ayarlar" iki satıra düşüp çubuğu 3px taşırıyordu.
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
