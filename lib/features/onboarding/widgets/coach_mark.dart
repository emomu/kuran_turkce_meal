import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';

/// Tanıtımın tek bir adımı.
///
/// [targetKey] verilirse o widget'ın ekrandaki yeri ölçülür ve karartmada
/// o alan kadar bir delik açılır; verilmezse baloncuk ekranın ortasında
/// tek başına gösterilir (bir jesti değil, genel bir fikri anlatan adım).
class TourStep {
  const TourStep({
    required this.title,
    required this.body,
    this.targetKey,
    this.icon,
    this.shape = SpotlightShape.rounded,
  });

  /// Adımın başlığı — ne yapılacağı, emir kipinde.
  final String title;

  /// Kısa açıklama — neden yapılacağı.
  final String body;

  /// İşaret edilecek widget.
  final GlobalKey? targetKey;

  /// Baloncukta başlığın yanında görünen ikon.
  final IconData? icon;

  final SpotlightShape shape;
}

/// Deliğin biçimi. Yuvarlak ikonlar için daire, metin blokları için
/// köşeleri yumuşatılmış dikdörtgen daha doğru görünür.
enum SpotlightShape { rounded, circle }

/// Ekranın üstüne serilen tanıtım katmanı.
///
/// Karartma tüm ekranı kaplar, işaret edilen öğenin bulunduğu yer delik
/// olarak açık kalır. Böylece kullanıcı anlatılan şeyin ekranda tam olarak
/// neresi olduğunu görür — ekrandan kopuk bir tanıtım karesi bunu yapamaz.
///
/// Katman gerçek arayüzün üstünde durur ve dokunuşları yutar; altındaki
/// ekranla yanlışlıkla etkileşime girilmez.
class CoachMarkOverlay extends StatefulWidget {
  const CoachMarkOverlay({
    super.key,
    required this.steps,
    required this.onFinish,
  });

  final List<TourStep> steps;

  /// Tur bittiğinde ya da atlandığında çağrılır.
  final VoidCallback onFinish;

  @override
  State<CoachMarkOverlay> createState() => _CoachMarkOverlayState();
}

class _CoachMarkOverlayState extends State<CoachMarkOverlay>
    with SingleTickerProviderStateMixin {
  int _index = 0;

  /// İşaret edilen öğenin ölçülmüş karesi.
  ///
  /// Ölçüm `build` içinde yapılamaz: `localToGlobal` o sırada bir önceki
  /// karenin yerleşimini okur. Yazı tipleri ağdan yüklendiğinde (Google
  /// Fonts) metin sonradan yeniden yerleşir ve ayet kayar; `build` içinde
  /// ölçülen delik o eski yere açılır, ekranda ayetle örtüşmeyen bir kutu
  /// olarak görünür. Bu yüzden ölçüm her karenin *sonunda* yapılır ve
  /// değiştiğinde katman yeniden çizilir.
  Rect? _target;

  /// Deliği yeniden boyatan sinyal.
  ///
  /// Boyama yerleşimden sonra çalıştığı için delik, hedefin o karedeki
  /// gerçek yerine çizilir. Hedef sonradan kayarsa (yazı tipi ağdan
  /// yüklendi, ekran döndü) bu sinyal boyamayı tazeler.
  final _repaint = ValueNotifier<int>(0);

  /// Karartma tuvalinin kendi anahtarı.
  ///
  /// Hedef ekranın (global) koordinatında ölçülür, tuval ise kendi yerel
  /// koordinatında boyanır. Boyayıcı bu anahtarla aradaki farkı hesaplayıp
  /// deliği doğru yere koyar; bkz. [_SpotlightPainter.overlayKey].
  final _overlayKey = GlobalKey();

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.normal,
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Motion.standard,
  );

  @override
  void initState() {
    super.initState();
    _scheduleMeasure();
  }

  @override
  void dispose() {
    _repaint.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Hedefi her karenin sonunda ölçer ve yer değiştirdiyse yeniden çizer.
  ///
  /// Katman açık kaldığı sürece izleme sürer. Tek seferlik ölçüm yetmiyor:
  /// yazı tipleri ağdan yüklendiğinde (Google Fonts) metin yeniden yerleşir
  /// ve ayet kayar; ekran döndürüldüğünde de her şey yeniden konumlanır.
  /// Ölçüm bir kez alınıp bırakılırsa delik eski yerde kalır ve kullanıcı
  /// ayetin yanında boş bir kutu görür.
  void _scheduleMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final measured = _measure(widget.steps[_index]);
      if (measured != _target) {
        setState(() => _target = measured);
        // Delik de yeni konuma boyansın.
        _repaint.value++;
      }

      // Ölçüm henüz oturmadıysa bir kare daha beklenir. Sabitlendiğinde
      // döngü durur; aksi halde her karede yeni kare istenir ve ekran
      // hiç boşa çıkmaz (testlerde `pumpAndSettle` de sonsuza dek döner).
      if (measured != _target) _scheduleMeasure();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  /// Ölçülmüş delik karesi — testlerin deliğin hedefle örtüştüğünü
  /// doğrulayabilmesi için açılır.
  @visibleForTesting
  Rect? get measuredTargetForTest => _target;

  bool get _isLast => _index == widget.steps.length - 1;

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    // Adım değişirken kısa bir solma; delik yeni yerine ışınlanmış gibi
    // görünmesin.
    _controller.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _index++;
        // Yeni adımın hedefi hemen ölçülür. `null` bırakılsaydı baloncuk
        // bir kare boyunca "hedefsiz" sanılıp ekranın ortasına konur,
        // ölçüm gelince yerine sıçrardı.
        _target = _measure(widget.steps[_index]);
      });
      _scheduleMeasure();
      _controller.forward();
    });
  }

  void _finish() {
    _controller.reverse().then((_) {
      if (mounted) widget.onFinish();
    });
  }

  /// İşaret edilen widget'ın ekrandaki dikdörtgeni.
  ///
  /// Widget henüz çizilmediyse (liste o öğeye kaydırılmamış olabilir) null
  /// döner ve adım deliksiz, ortada gösterilir.
  Rect? _measure(TourStep step) {
    final key = step.targetKey;
    if (key == null) return null;

    final context = key.currentContext;
    if (context == null) return null;

    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;

    final offset = box.localToGlobal(Offset.zero);
    return offset & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_index];
    final target = _target;

    // Ekran döndüğünde ya da üstteki yerleşim değiştiğinde katman yeniden
    // kurulur; ölçüm o zaman da tazelenmeli. Döngü ölçüm sabitlendiğinde
    // durduğu için bu ek istek sonsuz kareye yol açmaz.
    _scheduleMeasure();

    return FadeTransition(
      opacity: _fade,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          // Hedefsiz adımda baloncuk `Positioned` değil; `Stack` yayılmazsa
          // böyle bir çocuk sol üste hizalanır ve baloncuk saatin/çentiğin
          // altına yapışırdı.
          fit: StackFit.expand,
          children: [
            // Karartma + delik. Boşluğa dokunmak sonraki adıma geçirir;
            // kullanıcı her seferinde küçük bir düğme aramak zorunda kalmaz.
            Positioned.fill(
              child: GestureDetector(
                onTap: _next,
                behavior: HitTestBehavior.opaque,
                child: CustomPaint(
                  key: _overlayKey,
                  painter: _SpotlightPainter(
                    targetKey: step.targetKey,
                    shape: step.shape,
                    overlayKey: _overlayKey,
                    // Hedef kımıldadıkça yeniden boyanması için ölçüm
                    // dinleyicisine bağlanır.
                    repaint: _repaint,
                  ),
                ),
              ),
            ),

            _StepBubble(
              step: step,
              target: target,
              index: _index,
              total: widget.steps.length,
              onNext: _next,
              onSkip: _finish,
              isLast: _isLast,
            ),
          ],
        ),
      ),
    );
  }
}

/// Karartmayı çizer ve hedefin yerinde delik bırakır.
class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({
    required this.targetKey,
    required this.shape,
    required this.overlayKey,
    required Listenable repaint,
  }) : super(repaint: repaint);

  /// İşaret edilen widget. Delik, boyanma anında bu anahtardan ölçülür.
  ///
  /// Ölçümü boyamaya bırakmak bilinçli: boyama her zaman yerleşimden sonra
  /// çalışır, dolayısıyla okunan kare o karenin gerçek konumudur. Ölçüm
  /// `build` sırasında alınsaydı bir önceki karenin yerleşimi okunurdu ve
  /// yazı tipi ağdan yüklenip metin yeniden yerleştiğinde (Google Fonts)
  /// delik ayetin eski yerinde kalırdı.
  final GlobalKey? targetKey;

  final SpotlightShape shape;

  /// Katmanın kendi konumunu okumak için kullanılan anahtar.
  ///
  /// Hedef, ekranın (global) koordinatında ölçülür; tuval ise katmanın
  /// yerel koordinatında boyanır. `AppBar`'lı bir ekranda katman gövdenin
  /// içinde başladığı için ikisi arasında çubuk yüksekliği kadar fark
  /// oluşuyor ve delik tam o kadar aşağı kayıyordu. Bu anahtar farkı
  /// hesaplayıp hedefi katmanın koordinatına taşımayı sağlar.
  final GlobalKey overlayKey;

  /// Anahtarın katman koordinatındaki karesi; çizilmediyse null.
  Rect? get target {
    final context = targetKey?.currentContext;
    if (context == null) return null;

    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;

    final overlayBox =
        overlayKey.currentContext?.findRenderObject() as RenderBox?;
    if (overlayBox == null || !overlayBox.hasSize || !overlayBox.attached) {
      return null;
    }

    // Hedefin sol üstü, katmanın kendi koordinat sistemine çevrilir.
    final topLeft = overlayBox.globalToLocal(box.localToGlobal(Offset.zero));
    return topLeft & box.size;
  }

  /// Delik hedefin biraz dışından geçer; öğe karartmaya yapışık durmasın.
  static const double _padding = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = Colors.black.withValues(alpha: 0.72);
    final screen = Offset.zero & size;

    if (target == null) {
      canvas.drawRect(screen, scrim);
      return;
    }

    final hole = target!.inflate(_padding);

    // Ekranın tamamından deliği çıkararak tek bir yol elde edilir; iki ayrı
    // dikdörtgen çizmek kenarlarda dikiş izi bırakırdı.
    final holePath = Path();
    if (shape == SpotlightShape.circle) {
      holePath.addOval(
        Rect.fromCircle(
          center: hole.center,
          radius: hole.longestSide / 2,
        ),
      );
    } else {
      holePath.addRRect(
        RRect.fromRectAndRadius(hole, const Radius.circular(Radii.md)),
      );
    }

    final scrimPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(screen),
      holePath,
    );

    canvas.drawPath(scrimPath, scrim);

    // İnce bir kenar çizgisi deliği belirginleştirir; koyu temada karartma
    // ile ekran arasındaki sınır aksi halde kaybolur.
    canvas.drawPath(
      holePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.targetKey != targetKey ||
      old.shape != shape ||
      old.overlayKey != overlayKey;
}

/// Adımı anlatan baloncuk.
///
/// Hedefin altına yerleşir; altta yer kalmadıysa üstüne geçer. Böylece
/// baloncuk hiçbir zaman işaret ettiği şeyin üstünü örtmez.
class _StepBubble extends StatelessWidget {
  const _StepBubble({
    required this.step,
    required this.target,
    required this.index,
    required this.total,
    required this.onNext,
    required this.onSkip,
    required this.isLast,
  });

  final TourStep step;
  final Rect? target;
  final int index;
  final int total;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final bool isLast;

  /// Baloncuğun hedefe olan uzaklığı.
  static const double _gap = 16;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);

    final bubble = Container(
      // Not: burada `alignment` verilmez. `Container`'a hizalama vermek onu
      // gevşek kısıt altında bütün alana yaymaya zorluyor; baloncuk ekranın
      // tamamı kadar büyüyüp içeriğini tepeye itiyordu (başlık saatin
      // altında kalıyordu). Genişlik sınırı tek başına yeterli.
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(Insets.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(Radii.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (step.icon != null) ...[
                Icon(step.icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: Insets.xs),
              ],
              Expanded(
                child: Text(step.title, style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: Insets.xs),
          Text(
            step.body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.45,
            ),
          ),
          const SizedBox(height: Insets.md),

          Row(
            children: [
              // İlerleme noktaları — turun ne kadar sürdüğünü baştan gösterir.
              //
              // Dar ekranda (ya da büyük sistem puntosunda) düğmeler yer
              // kaplar; noktalar esneyerek taşmayı önler, gerekirse kendi
              // içinde kaydırılır. Taşarsa satır sarı-siyah şeritle çizilir
              // ve düğmelerin bir kısmı ekran dışında kalırdı.
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var i = 0; i < total; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: AnimatedContainer(
                            duration: Motion.normal,
                            curve: Motion.standard,
                            width: i == index ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == index
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(Radii.pill),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: Insets.xs),

              // Düğmeler her zaman tam görünmeli; taşma olursa kısalan
              // taraf noktalar olur, düğmeler değil.
              if (!isLast)
                TextButton(
                  onPressed: onSkip,
                  child: Text('tour.skip'.tr()),
                ),
              const SizedBox(width: Insets.xxs),
              FilledButton(
                onPressed: onNext,
                child: Text(isLast ? 'tour.done'.tr() : 'tour.next'.tr()),
              ),
            ],
          ),
        ],
      ),
    );

    // Hedef yoksa baloncuk ekranın ortasında durur.
    //
    // `Positioned.fill` şart: `Stack`'in konumlandırılmamış çocukları sol
    // üste hizalanır ve baloncuk saatin/çentiğin altına yapışırdı.
    if (target == null) {
      return Positioned.fill(
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(
              left: Insets.screenGutter + media.padding.left,
              right: Insets.screenGutter + media.padding.right,
              top: media.padding.top,
              bottom: media.padding.bottom,
            ),
            child: bubble,
          ),
        ),
      );
    }

    // Baloncuk hedefin altına ya da üstüne konur; hangisinde daha çok yer
    // varsa oraya. Sabit bir eşikle karar vermek yetmiyordu: baloncuğun
    // gerçek yüksekliği metne göre değişiyor ve tahminden büyük olduğunda
    // hedefin üstünü örtüyordu.
    final safeTop = media.padding.top;
    final safeBottom = media.padding.bottom;
    final spaceBelow = media.size.height - safeBottom - target!.bottom - _gap;
    final spaceAbove = target!.top - safeTop - _gap;
    final showBelow = spaceBelow >= spaceAbove;

    // Baloncuğa ayrılan alan; içeriği sığmazsa kendi içinde kaydırılır,
    // böylece hiçbir durumda hedefin üstüne taşmaz.
    final available = (showBelow ? spaceBelow : spaceAbove)
        .clamp(0.0, media.size.height);

    return Positioned(
      left: Insets.screenGutter + media.padding.left,
      right: Insets.screenGutter + media.padding.right,
      top: showBelow ? target!.bottom + _gap : null,
      bottom: showBelow ? null : media.size.height - target!.top + _gap,
      // `Positioned` sol ve sağ verildiği için genişlik zaten kesin;
      // baloncuk doğrudan konur. Araya `Align` koymak gevşek kısıt
      // yaratıp satırın kendi doğal genişliğine şişmesine ve taşmasına
      // yol açıyordu.
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: available),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          // Alta yerleşiyorsa içerik yukarıdan, üste yerleşiyorsa aşağıdan
          // başlasın; kırpılan taraf her zaman hedeften uzak olan olsun.
          reverse: !showBelow,
          child: bubble,
        ),
      ),
    );
  }
}
