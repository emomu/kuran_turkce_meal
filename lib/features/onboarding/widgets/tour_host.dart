import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/tour_provider.dart';
import 'coach_mark.dart';

/// Bir ekranı tanıtım katmanıyla sarmalar.
///
/// Tur yalnızca daha önce izlenmemişse ve [enabled] doğruysa açılır.
/// [enabled] veri beklemek için vardır: okuma ekranında ayetler yüklenmeden
/// tur başlarsa işaret edilecek ayet henüz ekranda olmaz ve delik açılamaz.
///
/// Katman ilk kare çizildikten sonra eklenir; hedef widget'ların yerleri
/// ancak çizim tamamlandığında ölçülebilir.
///
/// Karartma [Overlay]'e konur, ekranın kendi ağacına değil. `TourHost`
/// genellikle `Scaffold`'un `body`'sine sarılır; katman orada çizilseydi
/// yalnızca gövdeyi kaplar, `AppBar` aydınlık kalırdı. Üst çubuktaki bir
/// öğeyi (arama simgesi gibi) işaret eden adımda delik de açılamazdı.
class TourHost extends ConsumerStatefulWidget {
  const TourHost({
    super.key,
    required this.tour,
    required this.steps,
    required this.child,
    this.enabled = true,
  });

  final TourId tour;

  /// Adımlar her karede yeniden kurulabildiği için fonksiyon olarak alınır;
  /// böylece hedef anahtarlar en güncel hâliyle okunur.
  final List<TourStep> Function() steps;

  final Widget child;

  /// Turun başlayabilmesi için ekranın hazır olup olmadığı.
  final bool enabled;

  @override
  ConsumerState<TourHost> createState() => _TourHostState();
}

class _TourHostState extends ConsumerState<TourHost> {
  bool _isShowing = false;

  /// Karartmayı taşıyan katman girdisi.
  OverlayEntry? _entry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeStart();
  }

  @override
  void dispose() {
    // Ekran turdan önce kapatılırsa girdi ortada kalmamalı.
    _removeEntry();
    super.dispose();
  }

  @override
  void didUpdateWidget(TourHost old) {
    super.didUpdateWidget(old);
    // Veri sonradan geldiyse (yükleniyordan tamama geçiş) tur o an başlar.
    if (widget.enabled && !old.enabled) _maybeStart();
  }

  /// Turun daha önce izlenip izlenmediği.
  ///
  /// Tercih deposu kurulmamışsa (tekil widget testleri, önizleme aracı)
  /// tur hiç gösterilmez. Tanıtım, uğruna ekranın çökmesini göze alacak
  /// kadar kritik değil: ekran her koşulda açılmalı.
  bool get _alreadySeen {
    try {
      return ref.read(tourProvider).contains(widget.tour);
    } on Object {
      return true;
    }
  }

  void _maybeStart() {
    if (_isShowing || !widget.enabled) return;
    if (_alreadySeen) return;

    // Hedeflerin ölçülebilmesi için düzenin oturması beklenir; katman ilk
    // kare çizildikten sonra eklenir.
    //
    // Geri çağrının ardından açıkça yeni bir kare istenir: tur ayarlardan
    // sıfırlandığında ekranda başka bir animasyon olmayabilir ve o durumda
    // kendiliğinden kare üretilmez — istek olmadan geri çağrı hiç çalışmaz.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isShowing) return;
      if (_alreadySeen) return;
      _isShowing = true;
      _insertEntry();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  /// Karartmayı katmana ekler.
  ///
  /// En yakın katman kullanılır, kök katman değil. Sekmelerin her biri kendi
  /// `Navigator`'ına — dolayısıyla kendi `Overlay`'ine — sahip; kök katmana
  /// eklenseydi görünmeyen sekmenin turu da öne çıkardı. "İpuçlarını tekrar
  /// göster" tüm turları sıfırladığı için ana ekranın ipucu, kullanıcı
  /// ayarlardayken ayarların üstünde beliriyordu.
  ///
  /// Sayfa katmanı `Scaffold`'un tamamının üstünde olduğu için karartma
  /// `AppBar`'ı örtmeye devam eder.
  void _insertEntry() {
    if (_entry != null) return;

    final overlay = Overlay.maybeOf(context);
    // Katman yoksa (çıplak widget testi) tur sessizce atlanır; ekranın
    // kendisi her koşulda çalışmalı.
    if (overlay == null) {
      _isShowing = false;
      return;
    }

    _entry = OverlayEntry(
      builder: (_) => CoachMarkOverlay(
        steps: widget.steps(),
        onFinish: _finish,
      ),
    );
    overlay.insert(_entry!);
    // Tur boyunca gizlenmesi gereken öğeler (asistan düğmesi) haberdar olur;
    // bkz. [tourVisibilityProvider]. Depo kurulmamış olabilir (çıplak
    // widget testi); tur yine de gösterilir.
    try {
      ref.read(activeToursProvider.notifier).show(widget.tour);
    } on Object {
      // Yoksay.
    }
  }

  void _removeEntry() {
    if (_entry == null) return;
    _entry!.remove();
    _entry = null;
    // `dispose` sırasında da çağrılabilir; kapsam o an sökülmüş olabilir.
    // Sayacın güncellenememesi turun kapanmasını engellememeli.
    try {
      ref.read(activeToursProvider.notifier).hide(widget.tour);
    } on Object {
      // Yoksay.
    }
  }

  void _finish() {
    try {
      ref.read(tourProvider.notifier).markSeen(widget.tour);
    } on Object {
      // Depo yoksa işaret kaydedilemez; katmanın kapanması yine de olmalı.
    }
    _removeEntry();
    if (mounted) setState(() => _isShowing = false);
  }

  @override
  Widget build(BuildContext context) {
    // Turun yeniden gösterilebilmesi için (ayarlardan sıfırlandığında)
    // durum dinlenir.
    // Depo kurulmamışsa dinlemek de hata fırlatır; tur zaten kapalı.
    try {
      ref.listen<Set<TourId>>(tourProvider, (previous, next) {
        if (!next.contains(widget.tour)) _maybeStart();
      });
    } on Object {
      // Yoksay: tanıtım devre dışı, ekran normal çalışır.
    }

    // Karartma `Overlay`'de yaşadığı için burada sarmalayıcı gerekmez;
    // ekran olduğu gibi çizilir.
    return widget.child;
  }
}
