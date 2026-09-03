import SwiftUI
import WidgetKit

struct StreakEntry: TimelineEntry {
    let date: Date
    let planName: String?
    let current: Int
    let longest: Int
    let route: String
    let todayDone: Bool
    let strings: WidgetStrings
}

struct StreakProvider: TimelineProvider {

    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(
            date: Date(),
            planName: "30 Günde Hatim",
            current: 7,
            longest: 12,
            route: "/planlar",
            todayDone: false,
            strings: WidgetStrings(languageCode: "tr")
        )
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (StreakEntry) -> Void
    ) {
        completion(context.isPreview ? placeholder(in: context) : readEntry())
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<StreakEntry>) -> Void
    ) {
        // Gün başında yenilenir: "bugün bekliyor" satırı gün dönümünde
        // yeniden doğru hale gelmeli, yoksa dün okumuş bir kullanıcı sabah
        // hâlâ "bugün tamam" görürdü.
        let nextMidnight = Calendar.current.date(
            byAdding: .minute,
            value: 2,
            to: Calendar.current.startOfDay(
                for: Calendar.current.date(
                    byAdding: .day, value: 1, to: Date()
                ) ?? Date()
            )
        ) ?? Date().addingTimeInterval(3600)

        completion(Timeline(entries: [readEntry()], policy: .after(nextMidnight)))
    }

    private func readEntry() -> StreakEntry {
        let store = WidgetStore()

        return StreakEntry(
            date: Date(),
            planName: store.string(WidgetKeys.streakPlanName),
            current: store.int(WidgetKeys.streakCurrent) ?? 0,
            longest: store.int(WidgetKeys.streakLongest) ?? 0,
            route: store.string(WidgetKeys.streakRoute) ?? "/planlar",
            todayDone: store.bool(WidgetKeys.streakTodayDone) ?? false,
            strings: WidgetStrings(
                languageCode: store.string(WidgetKeys.languageCode) ?? "tr"
            )
        )
    }
}

struct StreakWidgetView: View {
    var entry: StreakEntry

    @Environment(\.colorScheme) private var scheme
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                lockScreenCircular
            case .accessoryRectangular:
                lockScreenRectangular
            case .accessoryInline:
                Text("\(entry.current) \(entry.strings.streakDays)")
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
            HStack(spacing: 5) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 11))
                    .foregroundColor(WidgetTheme.accent(scheme))

                Text(entry.strings.streakLabel)
                    .font(.system(size: 10, weight: .bold))
                    .kerning(1.2)
                    .foregroundColor(WidgetTheme.inkFaint(scheme))
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            if entry.planName != nil {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(entry.current)")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(WidgetTheme.accent(scheme))

                    Text(entry.strings.streakDays)
                        .font(.system(size: 13))
                        .foregroundColor(WidgetTheme.inkMuted(scheme))
                }

                Text(entry.planName ?? "")
                    .font(.system(size: 13))
                    .foregroundColor(WidgetTheme.ink(scheme))
                    .lineLimit(1)

                // Bugünün durumu. Seri sayısı tek başına bilgi verir ama bir
                // şey yaptırmaz; bu satır seriyi kaybetmemek için ne
                // yapılması gerektiğini söyler.
                Text(
                    entry.todayDone
                        ? entry.strings.todayDone
                        : entry.strings.todayPending
                )
                .font(.system(size: 11))
                .foregroundColor(WidgetTheme.inkMuted(scheme))
                .lineLimit(1)
                .padding(.top, 4)
            } else {
                Text(entry.strings.streakEmpty)
                    .font(.system(size: 14))
                    .foregroundColor(WidgetTheme.inkMuted(scheme))
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
        .widgetContainerBackground(WidgetTheme.background(scheme))
    }

    /// Kilit ekranı halkası. Rakam ve altında alev simgesi.
    private var lockScreenCircular: some View {
        VStack(spacing: 0) {
            Text("\(entry.current)")
                .font(.system(size: 20, weight: .bold))

            Image(systemName: "flame.fill")
                .font(.system(size: 9))
        }
    }

    private var lockScreenRectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(
                "\(entry.current) \(entry.strings.streakDays)",
                systemImage: "flame.fill"
            )
            .font(.system(size: 13, weight: .semibold))
            .lineLimit(1)

            Text(
                entry.planName == nil
                    ? entry.strings.streakEmpty
                    : (entry.todayDone
                        ? entry.strings.todayDone
                        : entry.strings.todayPending)
            )
            .font(.system(size: 11))
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StreakWidget: Widget {
    let kind = "StreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            StreakWidgetView(entry: entry)
        }
        .configurationDisplayName("Okuma Serisi")
        .description("Plan serini takip et.")
        .supportedFamilies(supportedFamilies)
    }

    private var supportedFamilies: [WidgetFamily] {
        var families: [WidgetFamily] = [.systemSmall]
        if #available(iOS 16.0, *) {
            families.append(contentsOf: [
                .accessoryCircular, .accessoryRectangular, .accessoryInline,
            ])
        }
        return families
    }
}
