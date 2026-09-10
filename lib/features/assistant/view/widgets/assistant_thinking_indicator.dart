import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Asistan cevabı hazırlarken görünen gösterge.
///
/// Üç yanıp sönen nokta yerine, olan biteni söyleyen bir satır: bir aşama
/// etiketi ("Mealde aranıyor"), üzerinden geçen bir parıltı ve bir saniyeyi
/// aşarsa beliren süre sayacı.
///
/// NEDEN METİN
/// -----------
/// Noktalar bekleyişi gösterir ama bir şey anlatmaz. Asistan tek bir iş
/// yapmıyor — soruyu sınıflandırıyor, mealde arıyor, cevabı kuruyor — ve
/// bunu söylemek bekleyişi kısaltır. Aşama adı aynı zamanda dürüstlüktür:
/// kullanıcı asistanın "düşünmediğini", arama yaptığını görür.
///
/// SÜRE SAYACI
/// -----------
/// İlk saniye içinde gösterilmez. Yerel arama çoğunlukla o kadar hızlıdır
/// ki bir sayaç, olmayan bir bekleyişi varmış gibi gösterirdi. Uzarsa —
/// ilk açılışta veritabanı kuruluyorsa — sayaç belirir ve kullanıcı
/// uygulamanın donmadığını bilir.
class AssistantThinkingIndicator extends StatefulWidget {
  const AssistantThinkingIndicator({super.key});

  @override
  State<AssistantThinkingIndicator> createState() =>
      _AssistantThinkingIndicatorState();
}

class _AssistantThinkingIndicatorState extends State<AssistantThinkingIndicator>
    with SingleTickerProviderStateMixin {
  /// Parıltının metnin üzerinden geçme süresi.
  static const _sweepDuration = Duration(milliseconds: 1600);

  /// Sayacın belirdiği eşik. Bunun altındaki bekleyiş bekleyiş sayılmaz.
  static const _counterThreshold = Duration(seconds: 1);

  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: _sweepDuration,
  )..repeat();

  /// Gösterge belirdiğinden beri geçen süre.
  ///
  /// Ayrı bir `Timer` yerine parıltının kendi ticker'ından okunuyor.
  /// İkisi de aynı kareyle ilerler, ama tek bir kaynak olması iki şeyi
  /// kazandırıyor: fazladan bir zamanlayıcı yok, ve süre testte de
  /// gerçekte olduğu gibi akıyor — `DateTime.now()` sahte saat altında
  /// ilerlemez, ticker ilerler.
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _sweep.addListener(_onTick);
  }

  /// En son hangi saniye çizildi. Yeniden çizim buna bakarak kısılır.
  int _shownSecond = -1;

  void _onTick() {
    _elapsed = _sweep.lastElapsedDuration ?? _elapsed;

    // Parıltı `AnimatedBuilder` üzerinden zaten her karede çiziliyor;
    // buradaki `setState` yalnızca etiket ve sayaç için. Saniye
    // değişmediyse çizilecek yeni bir şey yok — her karede setState
    // çağırmak bütün satırı gereksizce yeniden kurardı.
    final second = _elapsed.inSeconds;
    if (second == _shownSecond) return;

    _shownSecond = second;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _sweep
      ..removeListener(_onTick)
      ..dispose();
    super.dispose();
  }

  /// Bekleyişin uzunluğuna göre aşama etiketi.
  ///
  /// Gerçek aşamalar ölçülmüyor; ölçülseydi de yerel arama o kadar hızlı
  /// biter ki etiket okunmadan değişirdi. Bunun yerine süreye bağlı bir
  /// yaklaşıklık kullanılıyor ve her etiket doğru bir şeyi söylüyor:
  /// asistan sırayla bu üç işi yapıyor.
  ///
  /// Eşikler tam saniyelerde: satır yalnızca saniye değişince yeniden
  /// çiziliyor, arada kalan bir eşik gecikmeli görünürdü.
  String get _label {
    final seconds = _elapsed.inSeconds;
    if (seconds < 1) return 'assistant.thinking'.tr();
    if (seconds < 3) return 'assistant.searching'.tr();
    return 'assistant.composing'.tr();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodySmall?.color ?? theme.hintColor;

    final showCounter = _elapsed >= _counterThreshold;

    return Padding(
      padding: const EdgeInsets.only(top: 18, left: 2),
      child: Row(
        children: [
          _SweepingText(
            text: _label,
            animation: _sweep,
            baseColor: base,
            highlightColor: theme.colorScheme.primary,
            style: theme.textTheme.bodySmall,
          ),

          // Sayaç yumuşak belirir: bir saniyede aniden sıçrayan bir rakam
          // gözü çeker ve bekleyişi olduğundan uzun gösterir.
          AnimatedOpacity(
            opacity: showCounter ? 1 : 0,
            duration: const Duration(milliseconds: 260),
            child: Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                '${_elapsed.inSeconds}s',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: base.withValues(alpha: 0.55),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Üzerinden bir parıltı geçen metin.
///
/// Parıltı bir gradyanla çizilir ve metnin genişliği boyunca kayar.
/// Yanıp sönmek yerine kaymak seçildi: yanıp sönen bir yazı uyarı gibi
/// durur, kayan parıltı ise sürmekte olan bir işi anlatır.
class _SweepingText extends StatelessWidget {
  const _SweepingText({
    required this.text,
    required this.animation,
    required this.baseColor,
    required this.highlightColor,
    this.style,
  });

  final String text;
  final Animation<double> animation;
  final Color baseColor;
  final Color highlightColor;
  final TextStyle? style;

  /// Parıltının metin genişliğine oranla yarı genişliği.
  ///
  /// Dar bir parıltı çizgi gibi geçer ve sinirli durur; geniş olan metnin
  /// tamamını aynı anda boyar ve hareket kaybolur. Üçte bir ikisinin
  /// arasında durur.
  static const _highlightWidth = 0.32;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Parıltının merkezi metnin solundan girip sağından çıkar.
        // Aralık [-w, 1+w]: kenarlardan başlamak, parıltının yarısının
        // dışarıda kalmasını ve geçişin kesik durmamasını sağlar.
        const w = _highlightWidth;
        final center = -w + animation.value * (1 + 2 * w);

        // Duraklar artan olmak zorunda; kırpma sırayı bozabildiği için
        // her biri bir öncekinden küçük olamayacak şekilde kurulur.
        final start = (center - w).clamp(0.0, 1.0);
        final mid = center.clamp(start, 1.0);
        final end = (center + w).clamp(mid, 1.0);

        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [baseColor, highlightColor, baseColor],
            stops: [start, mid, end],
          ).createShader(bounds),
          child: child,
        );
      },
      // Metin bir kez kurulur; her karede yeniden kurmanın anlamı yok.
      child: Text(
        text,
        style: (style ?? const TextStyle()).copyWith(
          color: baseColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
