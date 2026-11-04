import SwiftUI
import UIKit
import CoreText

/// District of Columbia flag palette (Nick's pick, 2026-10-27), light only: navy #041E42 (16.7:1 on white) for titles, tint and accents;
/// flag red #C8102E (5.9:1 on white, white on it 5.9:1; no official hex is published, this is the common reproduction) for the
/// hand-checked DC guide cards under white text and for MICHELIN chips; jumbo-slice cheese gold #F6C453 only as a pin and card fill under
/// dark text (never text). Not the Commanders' burgundy and gold. The names `green`/`gold` are kept from Wisconsin Eats so the shared
/// views read the same; here `green` is the navy and `gold` the flag red.
enum Theme {
    static let green = Color(hex: 0x041E42)      // navy: titles, tint, primary text accents
    static let green2 = Color(hex: 0x1C3A66)
    static let gold = Color(hex: 0xC8102E)       // flag red: card fills under white text, chips
    static let goldSoft = Color(hex: 0xF8DCE1)   // soft red
    static let lime = Color(hex: 0xF6C453)       // cheese gold, fills only (hand-checked pins), under dark text
    static let limeSoft = Color(hex: 0xFCEFC8)
    static let sand = Color(hex: 0xF4F6F9)       // the Home background, a cool off-white
    static let red = Color(hex: 0xC8102E)        // MICHELIN chips
    static let ink = Color(hex: 0x071A33)
    static let ink2 = Color(hex: 0x22344F)
    static let muted = Color(hex: 0x526079)
    static let surface = Color.white
    static let surface2 = Color(hex: 0xF2F4F8)
    static let surface3 = Color(hex: 0xE1E6EF)
    static let rule = Color(hex: 0xDCE2EC)
    static let rule2 = Color(hex: 0xB5C0D3)
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

/// A small uppercase label: "STONE CRAB", "1 MICHELIN STAR".
struct Chip: View {
    enum Style { case gold, green, red, plain, dashed }
    let text: String
    var style: Style = .plain

    var body: some View {
        Text(text.uppercased())
            .font(.caption2.weight(.bold))
            .tracking(0.4)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .foregroundStyle(style == .green || style == .red ? Color.white : style == .dashed ? Theme.muted : style == .gold ? Theme.ink : Theme.green)
            .background {
                RoundedRectangle(cornerRadius: 5).fill(style == .gold ? Theme.goldSoft : style == .green ? Theme.green : style == .red ? Theme.red
                                                       : style == .dashed ? .clear : Theme.surface2)
            }
            .overlay {
                if style == .dashed { RoundedRectangle(cornerRadius: 5).strokeBorder(Theme.rule2, style: StrokeStyle(lineWidth: 1, dash: [3, 2])) }
            }
            .accessibilityLabel(text)
    }
}

/// DC Eats' lettering: the system face drawn compressed and heavy for titles and guide names (like a show poster), and the
/// system monospaced face for numbers, dates and small labels. No bundled fonts.
struct DisplayFont: ViewModifier {
    let size: CGFloat
    var weight: Font.Weight = .black
    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

    func body(content: Content) -> some View {
        content.font(.system(size: size * min(scale, 1.6), weight: weight).width(.compressed))
    }
}

/// Numbers, dates and small labels in the system monospaced face, scaled like DisplayFont.
struct MonoFont: ViewModifier {
    let size: CGFloat
    var weight: Font.Weight = .semibold
    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

    func body(content: Content) -> some View {
        content.font(.system(size: size * min(scale, 1.6), weight: weight, design: .monospaced))
    }
}

extension View {
    func displayFont(_ size: CGFloat, weight: Font.Weight = .black) -> some View {
        modifier(DisplayFont(size: size, weight: weight))
    }

    func monoFont(_ size: CGFloat, weight: Font.Weight = .semibold) -> some View {
        modifier(MonoFont(size: size, weight: weight))
    }
}

/// The band under the Home title: the District flag's three red stars over two red bars (no seal, no team marks), as the leaderboard's
/// header draws it.
struct Stripes: View {
    var height: CGFloat = 6

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let bar = max(2, h * 0.13), gap = bar
            ctx.fill(Path(CGRect(x: 0, y: h - bar, width: w, height: bar)), with: .color(Theme.red))
            ctx.fill(Path(CGRect(x: 0, y: h - 2 * bar - gap, width: w, height: bar)), with: .color(Theme.red))
            // three five-point stars, centred, above the bars
            let r = (h - 2 * bar - 2 * gap) / 2, cy = r, step = r * 3.6
            for k in -1...1 {
                let cx = w / 2 + CGFloat(k) * step
                var p = Path()
                for i in 0..<10 {
                    let a = -CGFloat.pi / 2 + CGFloat(i) * .pi / 5, rr = i % 2 == 0 ? r : r * 0.382
                    let pt = CGPoint(x: cx + rr * cos(a), y: cy + rr * sin(a))
                    if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                }
                p.closeSubpath()
                ctx.fill(p, with: .color(Theme.red))
            }
        }
        .frame(height: height * 4)
        .accessibilityHidden(true)
    }
}

extension View {
    /// An inline navigation title in the display type. UINavigationBar.appearance() didn't reach every SwiftUI bar on iOS 27
    /// (the Map title went from compressed blue to plain black after a push and pop; place titles were always plain), so the
    /// title is our own view in the bar. The navigation title is still set, for the back button and VoiceOver.
    func inlineTitle(_ title: String) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title).displayFont(19, weight: .heavy).foregroundStyle(Theme.green)
                        .lineLimit(1).minimumScaleFactor(0.7)
                        .accessibilityAddTraits(.isHeader)
                }
            }
    }
}
