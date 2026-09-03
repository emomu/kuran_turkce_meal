import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sure sonu geçiş mekaniğinin karar mantığı.
///
/// Okuma ekranındaki `_onScrollNotification` ile aynı kuralları uygular;
/// burada izole edilip gerçek bir kaydırılabilir liste üzerinde sınanır.
///
/// Taşma, bildirimden değil kaydırma konumundan ölçülür: yaylanan fizik
/// (BouncingScrollPhysics) sınırın ötesini normal kaydırma sayar ve
/// `OverscrollNotification` üretmez.
class _AdvanceDecider {
  /// Okuma ekranındaki eşiğin aynısı.
  static const threshold = 130.0;

  double overscroll = 0;
  bool isDragging = false;
  int advanceCount = 0;

  bool handle(ScrollNotification n) {
    double overscrollOf(ScrollMetrics m) =>
        (m.pixels - m.maxScrollExtent).clamp(0.0, double.infinity);

    switch (n) {
      case ScrollStartNotification(:final dragDetails):
        isDragging = dragDetails != null;

      // Yalnızca parmak ekrandayken sayılır; atalet kaydırması sayılsaydı
      // kullanıcı istemeden sure atlardı.
      case ScrollUpdateNotification(:final metrics, :final dragDetails):
        if (dragDetails == null) break;
        overscroll = overscrollOf(metrics);

      case ScrollEndNotification():
        final shouldAdvance = isDragging && overscroll >= threshold;
        isDragging = false;
        if (shouldAdvance) advanceCount++;
        overscroll = 0;

      default:
        break;
    }
    return false;
  }
}

void main() {
  late _AdvanceDecider decider;
  late ScrollController controller;

  /// Listeyi kurar ve sonuna konumlanır — sure sonundaki durumu taklit eder.
  Future<void> pumpList(WidgetTester tester) async {
    decider = _AdvanceDecider();
    controller = ScrollController();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NotificationListener<ScrollNotification>(
          onNotification: decider.handle,
          child: ListView.builder(
            controller: controller,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            itemCount: 20,
            itemBuilder: (_, i) => SizedBox(height: 100, child: Text('$i')),
          ),
        ),
      ),
    ));

    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();
  }

  /// Sure sonunda parmakla yukarı doğru çekip bırakır.
  Future<void> pullAndRelease(WidgetTester tester, {required int steps}) async {
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(ListView)));
    for (var i = 0; i < steps; i++) {
      await gesture.moveBy(const Offset(0, -25));
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();
  }

  group('Sure sonu geçiş kararı', () {
    testWidgets('eşiği aşan sürükleme bırakılınca geçiş tetiklenir',
        (tester) async {
      await pumpList(tester);
      await pullAndRelease(tester, steps: 12);

      expect(decider.advanceCount, 1);
    });

    testWidgets('eşiğin altında bırakılırsa geçmez', (tester) async {
      await pumpList(tester);
      await pullAndRelease(tester, steps: 2);

      expect(decider.advanceCount, 0);
      expect(decider.overscroll, 0, reason: 'Bırakınca sayaç sıfırlanmalı');
    });

    testWidgets('parmak kalkmışken gelen taşma sayılmaz', (tester) async {
      await pumpList(tester);

      // Atalet (fling) fazında `dragDetails` null gelir. Gerçek cihazda
      // kullanıcı savurup elini çektiğinde liste sona ataletle çarpar; o
      // taşma kullanıcının niyeti değildir ve sayılmamalıdır.
      //
      // Bunu doğrudan sınamak için sürükleme bilgisi taşımayan bir güncelleme
      // gönderilir.
      final position = controller.position;
      ScrollUpdateNotification(
        metrics: FixedScrollMetrics(
          minScrollExtent: position.minScrollExtent,
          maxScrollExtent: position.maxScrollExtent,
          // Eşiğin çok üstünde bir taşma.
          pixels: position.maxScrollExtent + 400,
          viewportDimension: position.viewportDimension,
          axisDirection: position.axisDirection,
          devicePixelRatio: 1,
        ),
        context: tester.element(find.byType(ListView)),
        // dragDetails verilmez: bu bir atalet güncellemesidir.
        depth: 0,
      ).dispatch(tester.element(find.byType(ListView)));

      await tester.pump();

      expect(decider.overscroll, 0,
          reason: 'Atalet taşması sayaca eklenmemeli');
      expect(decider.advanceCount, 0);
    });

    testWidgets('her bırakma en fazla bir geçiş üretir', (tester) async {
      await pumpList(tester);

      // Tek harekette zincirleme sure atlanmamalı; iki ayrı çekiş iki geçiş.
      await pullAndRelease(tester, steps: 12);
      await pullAndRelease(tester, steps: 12);

      expect(decider.advanceCount, 2);
    });

    testWidgets('eşiğe varmadan geri dönülürse geçmez', (tester) async {
      await pumpList(tester);

      final gesture =
          await tester.startGesture(tester.getCenter(find.byType(ListView)));
      // Önce aşağı çek (taşma birikir), sonra geri yukarı dön.
      for (var i = 0; i < 4; i++) {
        await gesture.moveBy(const Offset(0, -25));
        await tester.pump();
      }
      await gesture.moveBy(const Offset(0, 80));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(decider.advanceCount, 0);
    });
  });
}
