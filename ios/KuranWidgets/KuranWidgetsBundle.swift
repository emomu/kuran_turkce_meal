import SwiftUI
import WidgetKit

/// Araç paketinin giriş noktası.
///
/// Üç araç tek bir uzantıda toplanır; her biri için ayrı uzantı hedefi
/// açmak gereksiz — hepsi aynı veri deposunu okuyor ve aynı kodu paylaşıyor.
@main
struct KuranWidgetsBundle: WidgetBundle {
    var body: some Widget {
        DailyAyahWidget()
        ContinueReadingWidget()
        StreakWidget()
    }
}
