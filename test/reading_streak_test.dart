import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/data/models/plan_schedule.dart';

/// Seri hesabını sınar.
///
/// "Bugün" testten verilir; sistem saatine bağlı bir test gece yarısına
/// yakın koşturulduğunda kendiliğinden kırılırdı.
void main() {
  final today = DateTime(2026, 1, 20);

  ReadingStreak streakOf(List<DateTime> days) =>
      calculateStreak(days, today: today);

  group('Seri', () {
    test('hiç okuma yoksa seri sıfır', () {
      expect(streakOf([]), ReadingStreak.empty);
      expect(streakOf([]).isEmpty, isTrue);
    });

    test('tek gün okuma seriyi 1 yapar', () {
      expect(streakOf([DateTime(2026, 1, 20)]).current, 1);
      expect(streakOf([DateTime(2026, 1, 20)]).longest, 1);
    });

    test('art arda beş gün', () {
      final s = streakOf([for (var d = 16; d <= 20; d++) DateTime(2026, 1, d)]);
      expect(s.current, 5);
      expect(s.longest, 5);
    });

    test('arada boşluk seriyi keser', () {
      // 10-11-12 okundu, 13-14 boş, 19-20 okundu.
      final s = streakOf([
        DateTime(2026, 1, 10),
        DateTime(2026, 1, 11),
        DateTime(2026, 1, 12),
        DateTime(2026, 1, 19),
        DateTime(2026, 1, 20),
      ]);
      expect(s.current, 2, reason: 'güncel seri son kesintisiz blok');
      expect(s.longest, 3, reason: 'en uzun blok baştaki üç gün');
    });

    test('bugün okunmamış ama dün okunmuşsa seri sürer', () {
      // Asıl karar bu: gün daha bitmedi, seri kırılmış sayılmaz.
      final s = streakOf([
        DateTime(2026, 1, 17),
        DateTime(2026, 1, 18),
        DateTime(2026, 1, 19),
      ]);
      expect(s.current, 3);
    });

    test('son okuma dünden eskiyse seri sıfırlanır', () {
      // Bir gün tamamen boş geçti; artık gerçekten koptu.
      final s = streakOf([
        DateTime(2026, 1, 16),
        DateTime(2026, 1, 17),
        DateTime(2026, 1, 18),
      ]);
      expect(s.current, 0);
      expect(s.longest, 3, reason: 'en uzun seri geçmişte kalsa da korunur');
    });

    test('aynı gün iki tamamlama seriyi 1 artırır, 2 değil', () {
      // Kullanıcı bir oturuşta iki plan gününü bitirdi; bu iki günlük
      // alışkanlık değil, tek günlük okuma.
      final s = streakOf([
        DateTime(2026, 1, 20, 9, 0),
        DateTime(2026, 1, 20, 21, 30),
      ]);
      expect(s.current, 1);
      expect(s.longest, 1);
    });

    test('serinin ortasında tekrarlanan gün seriyi kesmez', () {
      // Asıl sınama bu. Aynı günü iki kez saymak yalnızca seriyi şişirmez,
      // ONU KIRAR: 19'u iki kez listede olduğunda ardışıklık 19→19 adımında
      // koparır ve 18-19-20 serisi 3 yerine 2 çıkar. Ölçüldü.
      final s = streakOf([
        DateTime(2026, 1, 18, 9, 0),
        DateTime(2026, 1, 19, 9, 0),
        DateTime(2026, 1, 19, 20, 0),
        DateTime(2026, 1, 20, 9, 0),
      ]);
      expect(s.current, 3);
      expect(s.longest, 3);
    });

    test('aynı gün çok tamamlama uzun seriyi şişirmez', () {
      final s = streakOf([
        DateTime(2026, 1, 18, 8, 0),
        DateTime(2026, 1, 18, 12, 0),
        DateTime(2026, 1, 18, 20, 0),
        DateTime(2026, 1, 19, 9, 0),
        DateTime(2026, 1, 20, 9, 0),
      ]);
      expect(s.longest, 3, reason: '18-19-20, altı tamamlama değil');
      expect(s.current, 3);
    });

    test('en uzun seri güncelden farklı olabilir', () {
      // Geçmişte 6 günlük seri, şimdi 2 günlük.
      final s = streakOf([
        for (var d = 1; d <= 6; d++) DateTime(2026, 1, d),
        DateTime(2026, 1, 19),
        DateTime(2026, 1, 20),
      ]);
      expect(s.longest, 6);
      expect(s.current, 2);
      expect(s.longest, greaterThan(s.current));
    });

    test('sıralama bozuk gelse de doğru hesaplanır', () {
      // Sorgu completed_at'e göre sıralı geliyor ama hesap buna güvenmemeli.
      final s = streakOf([
        DateTime(2026, 1, 20),
        DateTime(2026, 1, 18),
        DateTime(2026, 1, 19),
      ]);
      expect(s.current, 3);
      expect(s.longest, 3);
    });

    test('ay sınırını aşan seri', () {
      final s = calculateStreak([
        DateTime(2025, 12, 30),
        DateTime(2025, 12, 31),
        DateTime(2026, 1, 1),
      ], today: DateTime(2026, 1, 1));
      expect(s.current, 3);
      expect(s.longest, 3);
    });

    test('gün içi saat farkı ardışıklığı bozmaz', () {
      // 18'inde gece 23:50, 19'unda sabah 07:10 okundu: aradan 7 saat geçti
      // ama iki ayrı takvim günü. Ham saat farkıyla ardışık sayılmazdı.
      final s = calculateStreak([
        DateTime(2026, 1, 18, 23, 50),
        DateTime(2026, 1, 19, 7, 10),
      ], today: DateTime(2026, 1, 19));
      expect(s.current, 2);
    });
  });
}
