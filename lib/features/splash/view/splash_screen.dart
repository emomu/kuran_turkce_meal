import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../core/theme/app_colors.dart';

/// Açılış ekranı.
///
/// Ekranda yalnızca ay-yıldız animasyonu döner: yazı, logo tipografisi ve
/// ilerleme göstergesi bilinçli olarak yok. İlerleme barı, kullanıcıya
/// bekleyeceği bir süre olduğunu ima eder; oysa açılış bir saniyeden kısa
/// sürüyor ve barın kendisi bekleyişi uzun hissettiriyor.
///
/// Animasyon tek bir JSON dosyasından gelir; açık ve koyu temaya renk
/// dosyayı çoğaltarak değil, çalışma anında [ValueDelegate] ile uyarlanır
/// (bkz. [_tintDelegates]).
/// Açılışın ekranda kalma süresi.
///
/// Animasyon döngüde olduğu için ekranın ne zaman kapanacağını bu süre
/// belirler.
const _splashDuration = Duration(seconds: 2);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.nextRoute = '/'});

  /// Animasyon bittiğinde gidilecek yol.
  final String nextRoute;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// Açılışı kapatan zamanlayıcı. Ekran erken bırakılırsa iptal edilir.
  Timer? _holdTimer;

  /// Geçişin iki kez tetiklenmesini önler — animasyon bitişi ve güvenlik
  /// zamanlayıcısı aynı anda düşebilir.
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _holdTimer?.cancel();
    GoRouter.of(context).go(widget.nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final accent = isDark ? AppColors.accentDark : AppColors.accentLight;

    // Animasyon karesi ekranın kısa kenarına oranlanır; küçük telefonda
    // taşmaz, tablette de kaybolmaz.
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final size = (shortestSide * 0.52).clamp(160.0, 320.0);

    return Scaffold(
      backgroundColor: background,
      body: Center(
        child: SizedBox.square(
          dimension: size,
          child: Lottie.asset(
            'assets/lottie/splash_moon_star.json',
            controller: _controller,
            delegates: LottieDelegates(values: _tintDelegates(accent)),
            fit: BoxFit.contain,
            // Animasyon süresi dosyadan okunur; burada sabitlenirse
            // dosya değiştiğinde hız bozulur.
            onLoaded: (composition) {
              _controller.duration = composition.duration;

              // Animasyon kesintisiz döner. Tek sefer oynatılıp dondurulsaydı
              // son karede duran bir resim kalırdı; yörünge dönüşü de tam tur
              // olduğu için başa sarma dikişi görünmez.
              _controller.repeat();

              // Geçiş, animasyonun bitişine değil sabit bir süreye bağlanır —
              // animasyon döngüde olduğu için kendiliğinden bitmez.
              _holdTimer = Timer(_splashDuration, _goNext);
            },
            // Dosya bir şekilde okunamazsa kullanıcı boş ekranda kalmasın.
            errorBuilder: (context, error, stackTrace) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _goNext());
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  /// Lottie dosyasındaki tüm dolgu ve çizgi renklerini temaya göre boyar.
  ///
  /// Dosya açık tema rengiyle üretildi; koyu temada aynı yeşil zeminde
  /// söner. Renkleri burada geçersiz kılmak, iki ayrı JSON tutmaktan hem
  /// daha küçük hem de paletin tek kaynaktan (AppColors) gelmesini sağlıyor.
  List<ValueDelegate> _tintDelegates(Color accent) {
    return [
      ValueDelegate.color(const ['**', 'Fill'], value: accent),
      ValueDelegate.color(const ['**', 'Stroke'], value: accent),
      ValueDelegate.colorFilter(
        const ['**'],
        value: ColorFilter.mode(accent, BlendMode.srcATop),
      ),
    ];
  }
}
