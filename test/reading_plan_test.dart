import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/data/models/reading_plan.dart';

void main() {
  group('ReadingPlans', () {
    test('her planın kimliği benzersiz', () {
      final ids = ReadingPlans.all.map((p) => p.id).toSet();
      expect(ids.length, ReadingPlans.all.length);
    });

    test('byId tanımlı planı bulur, tanımsıza null döner', () {
      expect(ReadingPlans.byId('mushaf_30')?.dayCount, 30);
      expect(ReadingPlans.byId('yok'), isNull);
    });

    test('günlük ayet sayısı planı kapsayacak kadar büyük', () {
      for (final plan in ReadingPlans.all) {
        expect(plan.ayahsPerDay * plan.dayCount, greaterThanOrEqualTo(6236),
            reason: '${plan.id} planı Kur\'an\'ı bitirmiyor');
      }
    });
  });

  group('PlanDay', () {
    test('ayet sayısı kimlik listesinin uzunluğudur', () {
      final day = PlanDay(
        index: 1,
        ayahIds: [for (var i = 1; i <= 17; i++) i],
        label: 'test',
        isCompleted: false,
      );
      expect(day.ayahCount, 17);
      expect(day.startAyahId, 1);
      expect(day.endAyahId, 17);
    });
  });
}
