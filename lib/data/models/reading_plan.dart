/// Bir okuma planı: Kur'an'ı belirli bir sürede bitirmek için günlere
/// bölünmüş okuma programı.
///
/// Planlar uygulama içinde tanımlıdır (bkz. [ReadingPlans]); kullanıcı plan
/// oluşturmaz, hazır olanlardan birini seçer. İlerleme yerel olarak tutulur.
class ReadingPlan {
  const ReadingPlan({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.dayCount,
    required this.order,
  });

  final String id;

  /// Başlık ve açıklama çeviri anahtarıdır; görünen metin arayüz dilinden
  /// gelir. Sabit metin tutulsaydı plan kartları dil değişince Türkçe kalırdı.
  final String titleKey;
  final String descriptionKey;

  final int dayCount;

  /// Planın hangi sıralamayı izlediği. İniş sırası planları kronolojik
  /// okuma sunar; mushaf planları geleneksel sırayı izler.
  final PlanOrder order;

  /// Günlük ortalama ayet sayısı — plan kartında gösterilir.
  int get ayahsPerDay => (6236 / dayCount).ceil();
}

enum PlanOrder { revelation, mushaf }

/// Uygulamanın sunduğu hazır okuma planları.
abstract final class ReadingPlans {
  static const all = <ReadingPlan>[
    ReadingPlan(
      id: 'revelation_365',
      titleKey: 'plans.revelation365',
      descriptionKey: 'plans.revelation365Desc',
      dayCount: 365,
      order: PlanOrder.revelation,
    ),
    ReadingPlan(
      id: 'revelation_180',
      titleKey: 'plans.revelation180',
      descriptionKey: 'plans.revelation180Desc',
      dayCount: 180,
      order: PlanOrder.revelation,
    ),
    ReadingPlan(
      id: 'mushaf_30',
      titleKey: 'plans.mushaf30',
      descriptionKey: 'plans.mushaf30Desc',
      dayCount: 30,
      order: PlanOrder.mushaf,
    ),
    ReadingPlan(
      id: 'mushaf_90',
      titleKey: 'plans.mushaf90',
      descriptionKey: 'plans.mushaf90Desc',
      dayCount: 90,
      order: PlanOrder.mushaf,
    ),
  ];

  static ReadingPlan? byId(String id) {
    for (final plan in all) {
      if (plan.id == id) return plan;
    }
    return null;
  }
}

/// Bir planın tek bir gününde okunacak ayet aralığı.
class PlanDay {
  const PlanDay({
    required this.index,
    required this.ayahIds,
    required this.label,
    required this.isCompleted,
  });

  /// Gün numarası. 1'den başlar.
  final int index;

  /// Gün içinde okunacak ayet kimlikleri, okuma sırasında.
  ///
  /// Aralık (başlangıç–bitiş) yerine liste tutulur. İniş sırasındaki planlarda
  /// bir gün mushafta bitişik olmayan sureleri kapsayabilir; aralık olarak
  /// verilseydi arada kalan bütün sureler de okunacakmış gibi görünürdü.
  /// Ölçüldü: 365 günlük iniş planında 78 gün böyle, en kötüsünde 17 ayet
  /// yerine 169 ayet gelirdi.
  final List<int> ayahIds;

  /// İnsan okuyabilir aralık. Örn. "Alak 1 – Kalem 12".
  final String label;

  final bool isCompleted;

  int get ayahCount => ayahIds.length;

  /// Okumanın başladığı ayet — plan listesinden girişte kullanılır.
  int get startAyahId => ayahIds.first;

  /// Okumanın bittiği ayet.
  int get endAyahId => ayahIds.last;

  PlanDay copyWith({bool? isCompleted}) => PlanDay(
    index: index,
    ayahIds: ayahIds,
    label: label,
    isCompleted: isCompleted ?? this.isCompleted,
  );
}
