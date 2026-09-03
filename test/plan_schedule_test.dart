import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/data/models/plan_schedule.dart';

/// Plan takvim hesabını sınar.
///
/// Hesap saf olduğu için "bugün" testten verilir; sistem saatine bağlı bir
/// test yaz saati geçişlerinde ya da gece yarısına yakın koşturulduğunda
/// kendiliğinden kırılırdı.
void main() {
  group('calendarDaysBetween', () {
    test('aynı gün içinde fark yok', () {
      expect(
        calendarDaysBetween(
          DateTime(2026, 3, 10, 8, 0),
          DateTime(2026, 3, 10, 23, 59),
        ),
        0,
      );
    });

    test('gece yarısını geçmek bir gün sayılır', () {
      // Asıl mesele bu: aradan yalnızca iki dakika geçti ama takvim günü
      // değişti. Ham saat farkı kullanılsaydı sonuç 0 çıkardı.
      expect(
        calendarDaysBetween(
          DateTime(2026, 3, 10, 23, 59),
          DateTime(2026, 3, 11, 0, 1),
        ),
        1,
      );
    });

    test('günün saati fark sayısını etkilemez', () {
      // Akşam başlayıp sabah bakan kullanıcı: aradan 6 gün 13 saat geçti
      // ama takvimde 7 gün var. Ham inDays bu aralığı 6 sayardı — ölçüldü.
      //
      // Sınama saat diliminden bağımsız olsun diye yaz saati geçişi
      // kullanılMAZ: uygulamanın ana kitlesi Türkiye'de ve orada saatler
      // 2016'dan beri sabit (UTC+3), dolayısıyla böyle bir test geliştirme
      // makinesinde hiçbir şey ölçmezdi. Gün başına indirgeme yine de yaz
      // saati uygulayan ülkelerde doğru sonucu verir; burada sınanan,
      // o indirgemenin asıl kuralı: saat bilgisi atılır.
      expect(
        calendarDaysBetween(
          DateTime(2026, 1, 1, 20, 0),
          DateTime(2026, 1, 8, 9, 0),
        ),
        7,
      );
      expect(
        calendarDaysBetween(
          DateTime(2026, 1, 1, 23, 0),
          DateTime(2026, 1, 3, 1, 0),
        ),
        2,
      );
    });

    test('ay ve yıl sınırını aşar', () {
      expect(
        calendarDaysBetween(DateTime(2025, 12, 31), DateTime(2026, 1, 1)),
        1,
      );
      expect(
        calendarDaysBetween(DateTime(2024, 2, 28), DateTime(2024, 3, 1)),
        2,
        reason: '2024 artık yıl; 29 Şubat sayılmalı',
      );
    });

    test('geçmişe doğru negatif döner', () {
      expect(
        calendarDaysBetween(DateTime(2026, 3, 11), DateTime(2026, 3, 10)),
        -1,
      );
    });
  });

  group('PlanSchedule.from', () {
    PlanSchedule build({
      required DateTime start,
      required DateTime today,
      int completed = 0,
      int dayCount = 30,
    }) => PlanSchedule.from(
      startDate: start,
      today: today,
      completedDays: completed,
      dayCount: dayCount,
    );

    test('başlangıç günü 1. gündür', () {
      final s = build(
        start: DateTime(2026, 1, 1, 22, 0),
        today: DateTime(2026, 1, 1, 22, 30),
      );
      expect(s.currentDay, 1);
    });

    test('ertesi gün 2. gündür', () {
      expect(
        build(
          start: DateTime(2026, 1, 1),
          today: DateTime(2026, 1, 2),
        ).currentDay,
        2,
      );
    });

    test('gece yarısı sınırı: 23:59 başlangıç, 00:01 bakış 2. gün', () {
      expect(
        build(
          start: DateTime(2026, 1, 1, 23, 59),
          today: DateTime(2026, 1, 2, 0, 1),
        ).currentDay,
        2,
      );
    });

    test('100. gün', () {
      expect(
        build(
          start: DateTime(2026, 1, 1),
          today: DateTime(2026, 4, 10),
          dayCount: 365,
        ).currentDay,
        100,
      );
    });

    test('başlangıç ileri tarihliyse 1. güne sabitlenir', () {
      // Cihaz saati geri alınmış olabilir; negatif gün göstermek yerine
      // plan başlamamış gibi 1. günde durur.
      expect(
        build(
          start: DateTime(2026, 5, 1),
          today: DateTime(2026, 4, 1),
        ).currentDay,
        1,
      );
    });

    test('başlangıç tarihi gün başına indirgenir', () {
      final s = build(
        start: DateTime(2026, 1, 1, 17, 45),
        today: DateTime(2026, 1, 1),
      );
      expect(s.startDate, DateTime(2026, 1, 1));
    });
  });

  group('geride kalma', () {
    test('tam takvimde: 5. gün, 5 gün tamamlanmış', () {
      final s = PlanSchedule.from(
        startDate: DateTime(2026, 1, 1),
        today: DateTime(2026, 1, 5),
        completedDays: 5,
        dayCount: 30,
      );
      expect(s.currentDay, 5);
      expect(s.isBehind, isFalse);
      expect(s.daysBehind, 0);
    });

    test('geride: 10. gün, 7 gün tamamlanmış', () {
      final s = PlanSchedule.from(
        startDate: DateTime(2026, 1, 1),
        today: DateTime(2026, 1, 10),
        completedDays: 7,
        dayCount: 30,
      );
      expect(s.daysBehind, 3);
      expect(s.isBehind, isTrue);
    });

    test('ilerideyken geride sayılmaz ve negatif üretmez', () {
      final s = PlanSchedule.from(
        startDate: DateTime(2026, 1, 1),
        today: DateTime(2026, 1, 3),
        completedDays: 9,
        dayCount: 30,
      );
      expect(s.daysBehind, 0);
      expect(s.isBehind, isFalse);
    });

    test('planı bitiren kullanıcı süre dolduktan sonra geride görünmez', () {
      // Beklenti dayCount ile sınırlanmasaydı, 30 günlük planı bitirmiş
      // kullanıcı 60. günde "30 gün geride" derdi.
      final s = PlanSchedule.from(
        startDate: DateTime(2026, 1, 1),
        today: DateTime(2026, 3, 1),
        completedDays: 30,
        dayCount: 30,
      );
      expect(s.isPastEnd, isTrue);
      expect(s.daysBehind, 0);
    });

    test('süre dolmuş ama plan bitmemişse gecikme dayCount ile sınırlı', () {
      final s = PlanSchedule.from(
        startDate: DateTime(2026, 1, 1),
        today: DateTime(2026, 6, 1),
        completedDays: 12,
        dayCount: 30,
      );
      expect(s.daysBehind, 18);
    });
  });
}
