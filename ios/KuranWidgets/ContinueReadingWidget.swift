import SwiftUI
import WidgetKit

struct ContinueEntry: TimelineEntry {
    let date: Date
    let surahName: String?
    let ayahLabel: String?
    let route: String
    let percent: Int
    let strings: WidgetStrings
}

struct ContinueProvider: TimelineProvider {

    func placeholder(in context: Context) -> ContinueEntry {
        ContinueEntry(
            date: Date(),
            surahName: "Bakara",
            ayahLabel: "142. ayet",
            route: "/",
            percent: 49,
            strings: WidgetStrings(languageCode: "tr")
        )
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (ContinueEntry) -> Void
    ) {
        completion(context.isPreview ? placeholder(in: context) : readEntry())
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<ContinueEntry>) -> Void
    ) {
        // Günün ayetinin aksine burada zamana bağlı bir içerik yok: son
        // okunan yer yalnızca kullanıcı okudukça değişir ve uygulama o anda
        // aracı zaten kendisi tazeliyor (WidgetCenter.reloadAllTimelines).
        // Yine de bir yedek yenileme bırakılır; uygulama beklenmedik bir
        // şekilde tazeleyemezse araç sonsuza kadar donmuş kalmasın.
        let refresh = Date().addingTimeInterval(6 * 3600)
        completion(Timeline(entries: [readEntry()], policy: .after(refresh)))
    }

    private func readEntry() -> ContinueEntry {
        let store = WidgetStore()

        return ContinueEntry(
            date: Date(),
            surahName: store.string(WidgetKeys.continueSurahName),
            ayahLabel: store.string(WidgetKeys.continueAyahLabel),
            route: store.string(WidgetKeys.continueRoute) ?? "/",
            percent: min(max(store.int(WidgetKeys.continuePercent) ?? 0, 0), 100),
            strings: WidgetStrings(
                languageCode: store.string(WidgetKeys.languageCode) ?? "tr"
            )
        )
    }
}

struct ContinueWidgetView: View {
    var entry: ContinueEntry

    @Environment(\.colorScheme) private var scheme
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .accessoryRectangular:
                lockScreenRectangular
            case .accessoryInline:
                Text(entry.surahName ?? entry.strings.continueEmpty)
            default:
                homeScreen
            }
        }
        .widgetURL(
            URL(string: "homeWidget://\(String(entry.route.drop(while: { $0 == "/" })))")
        )
    }

    private var homeScreen: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(entry.strings.continueLabel)
                .font(.system(size: 10, weight: .bold))
                .kerning(1.2)
                .foregroundColor(WidgetTheme.inkFaint(scheme))
                .lineLimit(1)

            Spacer(minLength: 6)

            Text(entry.surahName ?? entry.strings.continueEmpty)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(WidgetTheme.ink(scheme))
                .lineLimit(1)

            if let label = entry.ayahLabel {
                Text(label)
                    .font(.system(size: 13))
                    .foregroundColor(WidgetTheme.inkMuted(scheme))
                    .lineLimit(1)
            }

            // İlerleme çubuğu yalnızca okuma başlamışsa gösterilir; boş bir
            // çubuk "başlanmış ama ilerlememiş" izlenimi verirdi.
            if entry.surahName != nil {
                progressBar
                    .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(16)
        .widgetContainerBackground(WidgetTheme.background(scheme))
    }

    /// İnce ilerleme çubuğu.
    ///
    /// `ProgressView` yerine elle çizildi: sistem bileşeni araç içinde
    /// kendi vurgu rengini kullanıyor ve uygulamanın yeşiline uymuyordu.
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(WidgetTheme.track(scheme))

                Capsule()
                    .fill(WidgetTheme.accent(scheme))
                    .frame(
                        width: geometry.size.width
                            * CGFloat(entry.percent) / 100
                    )
            }
        }
        .frame(height: 6)
    }

    private var lockScreenRectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.strings.continueLabel)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)

            Text(entry.surahName ?? entry.strings.continueEmpty)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)

            if let label = entry.ayahLabel {
                Text(label)
                    .font(.system(size: 11))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ContinueReadingWidget: Widget {
    let kind = "ContinueReadingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ContinueProvider()) { entry in
            ContinueWidgetView(entry: entry)
        }
        .configurationDisplayName("Devam Et")
        .description("Kaldığın yerden okumaya devam et.")
        .supportedFamilies(supportedFamilies)
    }

    private var supportedFamilies: [WidgetFamily] {
        var families: [WidgetFamily] = [.systemSmall, .systemMedium]
        if #available(iOS 16.0, *) {
            families.append(contentsOf: [.accessoryRectangular, .accessoryInline])
        }
        return families
    }
}
