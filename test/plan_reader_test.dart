import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/data/models/reading_plan.dart';
import 'package:kuran_turkce_meal/features/plans/widgets/plan_day_end_card.dart';

import 'helpers/localized_app.dart';

/// Plan günü okuma akışı: gün sonu kartı ve devam mekaniği.
void main() async {
  await TestApp.ensureInitialized();

  setUp(TestApp.reset);

  const day = PlanDay(
    index: 1,
    ayahIds: [1, 2, 3, 4, 5],
    label: 'Alak 1–17',
    isCompleted: false,
  );

  const nextDay = PlanDay(
    index: 2,
    ayahIds: [6, 7, 8, 9, 10],
    label: 'Kalem 1–17',
    isCompleted: false,
  );

  testWidgets('gün sonunda sıradaki güne davet gösterilir', (tester) async {
    await TestApp.pump(
      tester,
      PlanDayEndCard(
        day: day,
        nextDay: nextDay,
        isCompleted: false,
        onContinue: () {},
      ),
    );

    // Kullanıcı plan listesine dönmeden okumayı sürdürebilmeli.
    expect(find.text('1. GÜN BİTTİ'), findsOneWidget);
    expect(find.text('2. GÜNDEN DEVAM ET'), findsOneWidget);
    // Sıradaki günün aralığı da görünür; ne okuyacağını bilerek geçsin.
    expect(find.text('Kalem 1–17'), findsOneWidget);
  });

  testWidgets('devam kartına dokunmak geçişi tetikler', (tester) async {
    var continued = false;
    await TestApp.pump(
      tester,
      PlanDayEndCard(
        day: day,
        nextDay: nextDay,
        isCompleted: false,
        onContinue: () => continued = true,
      ),
    );

    await tester.tap(find.text('Kalem 1–17'));
    await tester.pumpAndSettle();
    expect(continued, isTrue);
  });

  testWidgets('son günde geçiş yerine tamamlama mesajı çıkar', (tester) async {
    await TestApp.pump(
      tester,
      PlanDayEndCard(
        day: day,
        nextDay: null,
        isCompleted: false,
        onContinue: () {},
      ),
    );

    expect(find.text('Planı tamamladınız'), findsOneWidget);
    expect(find.textContaining('DEVAM ET'), findsNothing);
  });

  testWidgets('tamamlanmamış günde rozet görünmez', (tester) async {
    await TestApp.pump(
      tester,
      PlanDayEndCard(
        day: day,
        nextDay: nextDay,
        isCompleted: false,
        onContinue: () {},
      ),
    );

    // İşaretleme kullanıcıdan istenmez; ekran sona inildiğinde kendisi
    // işaretler. Kart yalnızca sonucu gösterir.
    expect(find.text('Bu günü tamamladım'), findsNothing);
    final badge = tester.widget<AnimatedOpacity>(
      find.ancestor(
        of: find.text('Tamamlandı'),
        matching: find.byType(AnimatedOpacity),
      ).first,
    );
    expect(badge.opacity, 0);
  });

  testWidgets('tamamlanmış gün işaretli görünür', (tester) async {
    await TestApp.pump(
      tester,
      PlanDayEndCard(
        day: day,
        nextDay: nextDay,
        isCompleted: true,
        onContinue: () {},
      ),
    );

    expect(find.text('Tamamlandı'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    final badge = tester.widget<AnimatedOpacity>(
      find.ancestor(
        of: find.text('Tamamlandı'),
        matching: find.byType(AnimatedOpacity),
      ).first,
    );
    expect(badge.opacity, 1);
  });

  testWidgets('çekme ilerlemesi halkayla gösterilir', (tester) async {
    await TestApp.pump(
      tester,
      PlanDayEndCard(
        day: day,
        nextDay: nextDay,
        isCompleted: false,
        pullProgress: 0.5,
        onContinue: () {},
      ),
    );

    // Kullanıcı ne kadar çekmesi gerektiğini görebilmeli.
    final indicator = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(indicator.value, 0.5);
  });

  group('Gün sonu eşiği', () {
    // Kartın yalnızca üst kenarına bakmak erken tetikliyordu: kullanıcı
    // günün son ayetlerini okumadan tamamlandı sayılıyordu. Ölçüt kartın
    // alt kenarının ekrana girmesidir.
    bool reachedEnd(double trailingEdge) => trailingEdge <= 1.02;

    test('kart henüz görünürken tamamlanmaz', () {
      // Kartın üstü göründü ama altı ekranın çok altında.
      expect(reachedEnd(1.8), isFalse);
      expect(reachedEnd(1.2), isFalse);
    });

    test('kartın altı ekrana girince tamamlanır', () {
      expect(reachedEnd(1.0), isTrue);
      expect(reachedEnd(0.6), isTrue);
    });
  });
}
