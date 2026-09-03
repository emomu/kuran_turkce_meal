import SwiftUI
import WidgetKit

/// Günün ayeti aracının tek bir zaman dilimi girdisi.
struct DailyAyahEntry: TimelineEntry {
    let date: Date
    let text: String?
    let reference: String?
    let route: String
    let strings: WidgetStrings

    /// Verinin bugüne ait olup olmadığı. Bayat veri gösterilmez: kullanıcı
    /// uygulamayı günlerdir açmadıysa aynı ayeti tekrar tekrar görüp aracın
    /// bozuk olduğunu düşünürdü.
    let isFresh: Bool
}

struct DailyAyahProvider: TimelineProvider {

    func placeholder(in context: Context) -> DailyAyahEntry {
        // Galeri önizlemesi. Gerçek veri okunmaz — kullanıcı aracı henüz
        // eklemedi, deposu boş olabilir.
        DailyAyahEntry(
            date: Date(),
            text: "Rabbimiz! Bize dünyada da iyilik ver, ahirette de iyilik ver.",
            reference: "Bakara 201",
            route: "/",
            strings: WidgetStrings(languageCode: "tr"),
            isFresh: true
        )
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (DailyAyahEntry) -> Void
    ) {
        completion(context.isPreview ? placeholder(in: context) : readEntry())
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<DailyAyahEntry>) -> Void
    ) {
        // Tek girdi yazılır ve bir sonraki gün başında yenilenmesi istenir.
        //
        // İçerik günde bir kez değişiyor; daha sık yenileme istemek sistemin
        // araca ayırdığı bütçeyi boşa harcar ve iOS bir süre sonra istekleri
        // görmezden gelmeye başlar. Gün başına birkaç dakika eklenir ki
        // yenileme anı ile gün hesabı arasındaki saniyelik fark araca bir
        // gün eski veri çizdirmesin.
        let entry = readEntry()

        let nextMidnight = Calendar.current.date(
            byAdding: .minute,
            value: 2,
            to: Calendar.current.startOfDay(
                for: Calendar.current.date(
                    byAdding: .day, value: 1, to: Date()
                ) ?? Date()
            )
        ) ?? Date().addingTimeInterval(3600)

        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }

    private func readEntry() -> DailyAyahEntry {
        let store = WidgetStore()

        return DailyAyahEntry(
            date: Date(),
            text: store.string(WidgetKeys.dailyAyahText),
            reference: store.string(WidgetKeys.dailyAyahReference),
            route: store.string(WidgetKeys.dailyAyahRoute) ?? "/",
            strings: WidgetStrings(
                languageCode: store.string(WidgetKeys.languageCode) ?? "tr"
            ),
            isFresh: store.int(WidgetKeys.dailyAyahDay) == todayDayNumber()
        )
    }
}

struct DailyAyahWidgetView: View {
    var entry: DailyAyahEntry

    @Environment(\.colorScheme) private var scheme
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            // Kilit ekranı aileleri tek renk çizilir; sistem her şeyi
            // beyaza indirger. Bu yüzden renk ve ikincil metin yerine
            // yalnızca en gerekli bilgi gösterilir.
            case .accessoryRectangular:
                lockScreenRectangular
            case .accessoryInline:
                Text(entry.isFresh ? (entry.reference ?? "") : entry.strings.empty)
            default:
                homeScreen
            }
        }
        .widgetURL(URL(string: "homeWidget://\(routePath)"))
    }

    /// Aracın açacağı yol. Veri bayatsa ayete değil ana sayfaya gidilir;
    /// dünün ayetine götürmek kullanıcıyı yanıltırdı.
    private var routePath: String {
        let target = entry.isFresh ? entry.route : "/"
        return String(target.drop(while: { $0 == "/" }))
    }

    private var homeScreen: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(entry.strings.dailyAyahLabel)
                .font(.system(size: 10, weight: .bold))
                .kerning(1.2)
                .foregroundColor(WidgetTheme.inkFaint(scheme))
                .lineLimit(1)

            if entry.isFresh, let text = entry.text {
                Text(text)
                    .font(.system(size: 15))
                    .lineSpacing(3)
                    .foregroundColor(WidgetTheme.ink(scheme))
                    .padding(.top, 8)
                    // Sığmayan metin kırpılır. Araç yüksekliği aileye göre
                    // değiştiği için sabit satır sayısı verilmez; kalan
                    // alanı doldurup taşan kısım kesilir.
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 6)

                Text(entry.reference ?? "")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(WidgetTheme.accent(scheme))
                    .lineLimit(1)
            } else {
                Spacer()
                Text(entry.strings.empty)
                    .font(.system(size: 14))
                    .foregroundColor(WidgetTheme.inkMuted(scheme))
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
        .widgetContainerBackground(WidgetTheme.background(scheme))
    }

    /// Kilit ekranı görünümü.
    ///
    /// Alan çok dar: künye üstte, metnin ilk iki satırı altta. Meal metnini
    /// tamamen göstermeye çalışmak burada okunmaz bir blok üretirdi.
    private var lockScreenRectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            if entry.isFresh {
                Text(entry.reference ?? "")
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)

                Text(entry.text ?? "")
                    .font(.system(size: 12))
                    .lineLimit(2)
            } else {
                Text(entry.strings.empty)
                    .font(.system(size: 12))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DailyAyahWidget: Widget {
    let kind = "DailyAyahWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyAyahProvider()) { entry in
            DailyAyahWidgetView(entry: entry)
        }
        .configurationDisplayName("Günün Ayeti")
        .description("Her gün yeni bir ayet.")
        .supportedFamilies(supportedFamilies)
    }

    /// Desteklenen boyutlar.
    ///
    /// Kilit ekranı aileleri iOS 16'da geldi; eski sürümlerde listeye
    /// eklemek aracın hiç görünmemesine yol açar.
    private var supportedFamilies: [WidgetFamily] {
        var families: [WidgetFamily] = [.systemSmall, .systemMedium, .systemLarge]
        if #available(iOS 16.0, *) {
            families.append(contentsOf: [.accessoryRectangular, .accessoryInline])
        }
        return families
    }
}
