import SwiftUI

/// Araçların renk paleti.
///
/// Değerler lib/core/theme/app_colors.dart ile birebir aynı; araç ana
/// ekranda uygulamanın bir parçası gibi görünmeli. Palet değişirse iki
/// dosya birlikte güncellenmeli.
///
/// Renkler asset kataloğu yerine kodda tanımlandı: katalog kullanmak araç
/// hedefine ayrı bir kaynak paketi eklemeyi gerektiriyor ve bu dosyaların
/// Xcode'da elle hedefe bağlanması gerekiyordu. Kodda tanımlamak, hedefe
/// yalnızca Swift dosyalarını eklemeyi yeterli kılıyor.
enum WidgetTheme {

    // Açık tema — AppColors light karşılıkları.
    private static let lightBackground = Color(hex: 0xFFFEFB)
    private static let lightInk = Color(hex: 0x1C1B18)
    private static let lightInkMuted = Color(hex: 0x6B6862)
    private static let lightInkFaint = Color(hex: 0x9C9891)
    private static let lightAccent = Color(hex: 0x3F6B54)
    private static let lightTrack = Color(hex: 0xDFE7E1)

    // Koyu tema — AppColors dark karşılıkları.
    private static let darkBackground = Color(hex: 0x1D1C18)
    private static let darkInk = Color(hex: 0xEDEAE3)
    private static let darkInkMuted = Color(hex: 0x9A968D)
    private static let darkInkFaint = Color(hex: 0x6A665E)
    private static let darkAccent = Color(hex: 0x7FB394)
    private static let darkTrack = Color(hex: 0x33463C)

    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? darkBackground : lightBackground
    }

    static func ink(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? darkInk : lightInk
    }

    static func inkMuted(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? darkInkMuted : lightInkMuted
    }

    static func inkFaint(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? darkInkFaint : lightInkFaint
    }

    static func accent(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? darkAccent : lightAccent
    }

    static func track(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? darkTrack : lightTrack
    }
}

extension Color {
    /// 0xRRGGBB biçiminde bir sabitten renk kurar.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

/// Aracın zeminini boyar.
///
/// iOS 17'de araç zemini `containerBackground` ile verilmek zorunda; eski
/// yöntem (doğrudan `background`) iOS 17'de aracın kenarlarında beyaz bir
/// çerçeve bırakıyor. Eski sürümler bu API'yi tanımadığı için sürüm
/// ayrımı burada tek bir yerde yapılır.
extension View {
    @ViewBuilder
    func widgetContainerBackground(_ color: Color) -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(color, for: .widget)
        } else {
            background(color)
        }
    }
}
