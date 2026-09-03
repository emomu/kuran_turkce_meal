/// Bir planın takvimle bağı: başlangıç tarihi, bugünün kaçıncı gün olduğu
/// ve kullanıcının geride kalıp kalmadığı.
///
/// Hesap saf tutulur (veritabanı ya da saat okuma yok) ki testten doğrudan
/// çağrılabilsin; "bugün" dışarıdan verilir.
library;

/// Bir tarihi yerel saat diliminde gün başına indirger.
///
/// Saat/dakika atılır çünkü plan günü takvim günüdür: 23:59'da başlayıp
/// 00:01'de bakan kullanıcı 2. güne geçmiş sayılmalı. Ham fark alınsaydı
/// (`difference(...).inDays`) bu kullanıcı hâlâ 1. günde görünürdü.
DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

/// İki tarih arasındaki takvim günü farkı.
///
/// `DateTime.difference().inDays` KULLANILMAZ: o mutlak süreyi 24 saate böler
/// ve yaz saati geçişlerinde bir gün 23 ya da 25 saat sürdüğü için sonuç
/// kayar. Burada iki tarih önce gün başına indirgenir, sonra fark UTC
/// üzerinden alınır — UTC'de yaz saati sıçraması olmadığı için gün sayısı
/// her zaman tam çıkar.
int calendarDaysBetween(DateTime from, DateTime to) {
  final a = startOfDay(from);
  final b = startOfDay(to);
  return DateTime.utc(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
}

/// Bir planın o anki takvim durumu.
class PlanSchedule {
  const PlanSchedule({
    required this.startDate,
    required this.currentDay,
    required this.completedDays,
    required this.dayCount,
  });

  /// Planın başladığı gün (gün başına indirgenmiş).
  final DateTime startDate;

  /// Bugünün planın kaçıncı günü olduğu. 1'den başlar.
  ///
  /// Plan süresi aşıldığında [dayCount] ile sınırlanmaz — kullanıcı 30 günlük
  /// planın 45. gününde olabilir; bunu gizlemek gecikmeyi de gizlerdi.
  final int currentDay;

  /// Bugüne kadar tamamlanmış gün sayısı.
  final int completedDays;

  final int dayCount;

  /// Kaç gün geride kalındığı. Geride değilse 0.
  ///
  /// Beklenen ilerleme, bugüne kadar geçen gün sayısıdır; ama plan bittikten
  /// sonra beklenti [dayCount] ile sınırlanır, yoksa planı bitiren kullanıcı
  /// her geçen gün daha da "geride" görünürdü.
  int get daysBehind {
    final expected = currentDay.clamp(0, dayCount);
    final behind = expected - completedDays;
    return behind > 0 ? behind : 0;
  }

  /// Plan takvimin gerisinde mi.
  bool get isBehind => daysBehind > 0;

  /// Planın son gününün de geçtiği durum — özet metni buna göre değişir.
  bool get isPastEnd => currentDay > dayCount;

  /// [startDate]'ten [today]'e göre durumu hesaplar.
  factory PlanSchedule.from({
    required DateTime startDate,
    required DateTime today,
    required int completedDays,
    required int dayCount,
  }) {
    // Başlangıç günü 1. gündür, 0. değil: kullanıcı planı başlattığı gün
    // zaten ilk okumasını yapabilir.
    final elapsed = calendarDaysBetween(startDate, today);
    return PlanSchedule(
      startDate: startOfDay(startDate),
      // Geçmişe dönük bir başlangıç tarihi (saat değişikliği, veri taşıma)
      // negatif gün üretmesin diye taban 1'dir.
      currentDay: elapsed < 0 ? 1 : elapsed + 1,
      completedDays: completedDays,
      dayCount: dayCount,
    );
  }
}

/// Okuma serisi: art arda kaç gün okunduğu.
///
/// Seri gün SAYISI değil GÜN sayısıdır: aynı gün iki plan günü tamamlansa
/// seri 1 artar. Kullanıcı bir oturuşta üç gün okuduğunda seriyi 3'e
/// çıkarmak, ertesi gün okumadığında da onu 3 kaybettirirdi; oysa alışkanlık
/// ölçülen şey "kaç ayrı günde okudun".
class ReadingStreak {
  const ReadingStreak({required this.current, required this.longest});

  /// Bugüne kadar kesintisiz süren seri.
  final int current;

  /// Tüm zamanların en uzun serisi.
  final int longest;

  static const empty = ReadingStreak(current: 0, longest: 0);

  bool get isEmpty => longest == 0;
}

/// Tamamlanma zamanlarından seriyi hesaplar.
///
/// [today] dışarıdan verilir ki test sistem saatine bağlı kalmasın.
ReadingStreak calculateStreak(
  Iterable<DateTime> completions, {
  required DateTime today,
}) {
  if (completions.isEmpty) return ReadingStreak.empty;

  // Aynı güne düşen tamamlamalar tek güne indirgenir — seriyi belirleyen
  // okuma sayısı değil, okunan ayrı günlerdir.
  final days = {for (final c in completions) startOfDay(c)}.toList()..sort();

  var longest = 1;
  var run = 1;
  for (var i = 1; i < days.length; i++) {
    // Ardışıklık takvim günü farkıyla ölçülür; ham saat farkı yaz saati
    // geçişlerinde seriyi haksız yere kırardı (bkz. calendarDaysBetween).
    if (calendarDaysBetween(days[i - 1], days[i]) == 1) {
      run++;
    } else {
      run = 1;
    }
    if (run > longest) longest = run;
  }

  // Güncel seri sondan geriye doğru sayılır.
  var current = 1;
  for (var i = days.length - 1; i > 0; i--) {
    if (calendarDaysBetween(days[i - 1], days[i]) != 1) break;
    current++;
  }

  // Bugün henüz okunmadıysa seri KIRILMIŞ SAYILMAZ: dün okunduysa sürüyor.
  //
  // Gerekçe: gün daha bitmedi. Sabah uygulamayı açan kullanıcıya "serin
  // koptu" demek, henüz olmamış bir başarısızlığı bildirmek olur ve
  // günün geri kalanında okuma isteğini kırar. Seri ancak bir gün tamamen
  // boş geçtiğinde, yani son okuma dünden eskiyse sıfırlanır.
  final sinceLast = calendarDaysBetween(days.last, today);
  if (sinceLast > 1) current = 0;

  return ReadingStreak(current: current, longest: longest);
}
