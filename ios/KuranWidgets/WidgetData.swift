import Foundation

/// Araçların okuduğu ortak veri.
///
/// Uygulama ile araçlar ayrı süreçlerde çalışır ve birbirinin belleğine
/// erişemez; aralarındaki tek köprü App Group üzerinden paylaşılan
/// UserDefaults'tur. Flutter tarafı (home_widget eklentisi) değerleri
/// oraya yazar, araç buradan okur.
///
/// Bu sayede araç Flutter motorunu hiç başlatmaz: ana ekranda anında
/// görünür ve arka planda pil harcamaz.
///
/// Anahtar adları lib/core/widgets_bridge/home_widget_keys.dart ile birebir
/// aynı olmalı. Bir taraf değişip diğeri değişmezse araç sessizce boş kalır,
/// derleme hatası vermez.
enum WidgetKeys {
    /// Xcode'da hem Runner hem de araç hedefinde tanımlı olmalı; yoksa
    /// araç veriyi hiç göremez.
    static let appGroup = "group.com.emirhansoylu.kuranmeal"

    /// Anahtarlar önekle değil, olduğu gibi yazılır.
    ///
    /// Eklentinin bazı sürümleri iOS'ta `flutter.` öneki kullanıyor; bu
    /// sürüm kullanmıyor — öykünücüde paylaşılan depo okunarak doğrulandı.
    /// Yine de her iki biçim de denenir (bkz. `WidgetStore.value`): önek
    /// varsayımını yanlış yapmak, aracın sessizce boş kalması demek ve bu
    /// derleme hatası vermeyen, ancak cihazda fark edilen bir arıza.
    static let legacyPrefix = "flutter."

    static let dailyAyahText = "daily_ayah_text"
    static let dailyAyahReference = "daily_ayah_reference"
    static let dailyAyahRoute = "daily_ayah_route"
    static let dailyAyahDay = "daily_ayah_day"

    static let continueSurahName = "continue_surah_name"
    static let continueAyahLabel = "continue_ayah_label"
    static let continueRoute = "continue_route"
    static let continuePercent = "continue_percent"

    static let streakPlanName = "streak_plan_name"
    static let streakCurrent = "streak_current"
    static let streakLongest = "streak_longest"
    static let streakRoute = "streak_route"
    static let streakTodayDone = "streak_today_done"

    static let languageCode = "language_code"
}

/// Paylaşılan depodan okuma.
///
/// Anahtar önce olduğu gibi, bulunamazsa `flutter.` önekiyle aranır.
/// Eklentinin sürümleri arasında bu konuda fark var ve yanlış varsayım
/// aracın sessizce boş kalmasına yol açıyor — derleme hatası vermeyen,
/// yalnızca cihazda görülen bir arıza. İki biçimi de denemek, eklenti
/// güncellemesinin araçları bozmasını da engelliyor.
struct WidgetStore {
    private let defaults: UserDefaults?

    init(appGroup: String = WidgetKeys.appGroup) {
        defaults = UserDefaults(suiteName: appGroup)
    }

    /// Anahtarın değerini iki biçimi de deneyerek okur.
    private func value(_ key: String) -> Any? {
        defaults?.object(forKey: key)
            ?? defaults?.object(forKey: WidgetKeys.legacyPrefix + key)
    }

    func string(_ key: String) -> String? {
        guard let text = value(key) as? String,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return nil }
        return text
    }

    func int(_ key: String) -> Int? {
        // Flutter sayıları platforma göre Int ya da NSNumber olarak yazar.
        (value(key) as? NSNumber)?.intValue
    }

    func bool(_ key: String) -> Bool? {
        (value(key) as? NSNumber)?.boolValue
    }
}

/// Bugünün epoch gün sayısı.
///
/// `DailyAyahWidgetData.dayNumberOf` ile aynı hesap: yerel gün başı alınır
/// ve gün uzunluğuna bölünür. Araç bu değeri uygulamanın yazdığıyla
/// karşılaştırıp verinin bayatlayıp bayatlamadığını anlar — kullanıcı
/// uygulamayı günlerdir açmasa bile araç yanlış bir "günün ayeti"
/// göstermesin diye.
func todayDayNumber(_ date: Date = Date()) -> Int {
    let startOfDay = Calendar.current.startOfDay(for: date)
    let millis = Int(startOfDay.timeIntervalSince1970 * 1000)
    return Int(floor(Double(millis) / 86_400_000.0))
}

/// Araç metinleri.
///
/// Araçlar Flutter çeviri katmanına erişemez. Uygulamanın yazdığı dil kodu
/// okunur ve karşılığı buradan seçilir; böylece araç uygulamanın dil
/// ayarını izler (Android'de sistem dili izlenir — orada araç kaynakları
/// sistemin dil seçimine bağlı).
struct WidgetStrings {
    let languageCode: String

    private var isEnglish: Bool { languageCode == "en" }

    var dailyAyahLabel: String {
        isEnglish ? "VERSE OF THE DAY" : "GÜNÜN AYETİ"
    }

    var continueLabel: String {
        isEnglish ? "WHERE YOU LEFT OFF" : "KALDIĞIN YER"
    }

    var continueEmpty: String { isEnglish ? "Start reading" : "Okumaya başla" }

    var streakLabel: String { isEnglish ? "STREAK" : "SERİ" }

    var streakEmpty: String { isEnglish ? "Choose a plan" : "Bir plan seç" }

    var streakDays: String { isEnglish ? "days" : "gün" }

    var todayDone: String { isEnglish ? "Done today" : "Bugün tamam" }

    var todayPending: String { isEnglish ? "Pending today" : "Bugün bekliyor" }

    var empty: String { isEnglish ? "Open the app" : "Uygulamayı açın" }
}
