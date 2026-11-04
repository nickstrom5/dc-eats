// District of Columbia icon concepts for Nick's pick, in the shared Eats Ranked icon style (state-prompts/ICON-STYLE.md v1):
// one flat, level, centred food on a plain background; no scenery, tilt, texture, gloss or gradients.
// Usage (from dc-eats/): swift scripts/icon-concepts.swift   -> playbook/brand/concept-{a,b,c}-1024.png and -512, -180, -60 copies
//   A  half-smoke "all the way" (side elevation): a coarse, darker sausage in a soft bun under a band of chili, with a mustard wave, on
//      District flag red
//   B  jumbo slice (plan view): one huge slice, tip up, wider than the paper plate under it, so it hangs over both sides; on flag navy
//   C  injera platter (plan view): a round of injera topped with stews (red misir wat, yellow kik alicha, green gomen), on slate
// Palettes: A flag red #C8102E (no official hex is published; the common reproduction) with navy #041E42; B the same navy; C slate
// #1F3A4D (the cherry-blossom palette's text colour; its pink #F4B6C2 is a fill, too light behind a food). Food tones per concept.
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

func rgb(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: 1)
}
let RED: UInt32 = 0xC8102E, NAVY: UInt32 = 0x041E42, SLATE: UInt32 = 0x1F3A4D

// MARK: A, half-smoke (long food: side elevation, CoreGraphics y-up). A thick soft bun, the sausage lying in it and showing at both ends,
// a domed band of chili over the sausage, a mustard wave on the chili. 0.73 long, 0.35 tall. Tones: bun #F2CB8C (5.2:1 on the red),
// sausage #8E3A20, chili #5E2A12, mustard #F4C430.
func halfSmoke(_ c: CGContext, _ s: CGFloat) {
    func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }
    func R(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect { CGRect(x: x * s, y: y * s, width: w * s, height: h * s) }
    // sausage: a capsule, longer than the bun
    c.setFillColor(rgb(0x8E3A20))
    c.addPath(CGPath(roundedRect: R(0.135, 0.435, 0.73, 0.15), cornerWidth: 0.075 * s, cornerHeight: 0.075 * s, transform: nil)); c.fillPath()
    // bun: a pillowy block in front of the sausage's lower half
    c.setFillColor(rgb(0xF2CB8C))
    c.addPath(CGPath(roundedRect: R(0.17, 0.30, 0.66, 0.205), cornerWidth: 0.09 * s, cornerHeight: 0.09 * s, transform: nil)); c.fillPath()
    // chili: a low dome over the sausage's middle
    let chili = CGMutablePath()
    chili.move(to: P(0.215, 0.555))
    chili.addLine(to: P(0.785, 0.555))
    chili.addCurve(to: P(0.50, 0.655), control1: P(0.785, 0.63), control2: P(0.66, 0.655))
    chili.addCurve(to: P(0.215, 0.555), control1: P(0.34, 0.655), control2: P(0.215, 0.63))
    chili.closeSubpath()
    c.setFillColor(rgb(0x5E2A12)); c.addPath(chili); c.fillPath()
    // mustard: one wave, 34 px round caps, on the chili
    c.setStrokeColor(rgb(0xF4C430)); c.setLineWidth(0.034 * s); c.setLineCap(.round); c.setLineJoin(.round)
    let wave = CGMutablePath()
    wave.move(to: P(0.29, 0.595))
    for k in 0..<5 {
        let x0 = 0.29 + CGFloat(k) * 0.084
        wave.addQuadCurve(to: P(x0 + 0.084, 0.595), control: P(x0 + 0.042, k % 2 == 0 ? 0.625 : 0.565))
    }
    c.addPath(wave); c.strokePath()
}

// MARK: B, jumbo slice (plan view). A round paper plate is the backing shape (like Connecticut's sheet pan); the slice lies on it, tip down,
// its crust end wider than the plate, so it hangs over both sides. A 13 px navy ring separates slice from plate. Tones: plate #EEF0F2,
// crust #D98E3F, cheese #F6C453, pepperoni #B3261E.
func jumboSlice(_ c: CGContext, _ s: CGFloat) {
    // drawn tip down, then turned over so the tip points up and the heavy crust end sits low (the area centroid rule), 12 px up
    c.saveGState(); defer { c.restoreGState() }
    c.translateBy(x: 0, y: s * (1 + 0.012)); c.scaleBy(x: 1, y: -1)
    func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }
    c.setFillColor(rgb(0xEEF0F2))
    c.fillEllipse(in: CGRect(x: 0.215 * s, y: 0.205 * s, width: 0.57 * s, height: 0.57 * s))
    let slice = CGMutablePath()
    slice.move(to: P(0.50, 0.17))
    slice.addLine(to: P(0.865, 0.735))
    slice.addQuadCurve(to: P(0.135, 0.735), control: P(0.50, 0.80))
    slice.closeSubpath()
    let crust = CGMutablePath()
    crust.move(to: P(0.135, 0.735))
    crust.addQuadCurve(to: P(0.865, 0.735), control: P(0.50, 0.80))
    crust.addLine(to: P(0.865, 0.770))
    crust.addQuadCurve(to: P(0.135, 0.770), control: P(0.50, 0.855))
    crust.closeSubpath()
    // ring: the slice's and crust's silhouette in the background navy, under the fills
    c.setStrokeColor(rgb(NAVY)); c.setLineWidth(0.0254 * s); c.setLineJoin(.round); c.setLineCap(.round)
    c.addPath(slice); c.strokePath(); c.addPath(crust); c.strokePath()
    c.setFillColor(rgb(0xF6C453)); c.addPath(slice); c.fillPath()
    c.setFillColor(rgb(0xD98E3F)); c.addPath(crust); c.fillPath()
    c.setFillColor(rgb(0xB3261E))
    for (x, y, d) in [(0.31, 0.685, 0.062), (0.69, 0.685, 0.062), (0.42, 0.60, 0.075), (0.58, 0.60, 0.075), (0.50, 0.47, 0.068), (0.50, 0.33, 0.055)] as [(CGFloat, CGFloat, CGFloat)] {
        c.fillEllipse(in: CGRect(x: (x - d / 2) * s, y: (y - d / 2) * s, width: d * s, height: d * s))
    }
}

// MARK: C, injera platter (plan view): one round of injera, a touch wider than tall, with stews spooned on it: a big red misir wat in the
// middle and six smaller mounds around it, yellow and green alternating with red. Tones: injera #D3BD95, red #B4431F, yellow #E6B23A,
// green #5A8236.
func injera(_ c: CGContext, _ s: CGFloat) {
    c.setFillColor(rgb(0xD3BD95))
    c.fillEllipse(in: CGRect(x: 0.15 * s, y: 0.17 * s, width: 0.70 * s, height: 0.64 * s))
    let cx: CGFloat = 0.50, cy: CGFloat = 0.49
    c.setFillColor(rgb(0xB4431F))
    c.fillEllipse(in: CGRect(x: (cx - 0.105) * s, y: (cy - 0.105) * s, width: 0.21 * s, height: 0.21 * s))
    let tones: [UInt32] = [0xE6B23A, 0x5A8236, 0xB4431F, 0xE6B23A, 0x5A8236, 0xE6B23A]
    for k in 0..<6 {
        let a = CGFloat.pi / 2 + CGFloat(k) * CGFloat.pi / 3
        let x = cx + 0.215 * cos(a), y = cy + 0.19 * sin(a)
        c.setFillColor(rgb(tones[k]))
        c.fillEllipse(in: CGRect(x: (x - 0.072) * s, y: (y - 0.072) * s, width: 0.144 * s, height: 0.144 * s))
    }
}

// MARK: - main
let root = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().deletingLastPathComponent().path
let out = root + "/playbook/brand"
try? FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)
func canvas(_ n: Int) -> CGContext {
    let c = CGContext(data: nil, width: n, height: n, bitsPerComponent: 8, bytesPerRow: 0,
                      space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    c.setAllowsAntialiasing(true); c.setShouldAntialias(true); c.interpolationQuality = .high
    return c
}
func save(_ img: CGImage, _ name: String) {
    let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: out + "/" + name) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, img, nil)
    guard CGImageDestinationFinalize(dest) else { fatalError("could not write \(name)") }
}
for (key, bg, draw) in [("a", RED, halfSmoke), ("b", NAVY, jumboSlice), ("c", SLATE, injera)] as [(String, UInt32, (CGContext, CGFloat) -> Void)] {
    let c = canvas(1024)
    c.setFillColor(rgb(bg)); c.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))
    draw(c, 1024)
    let full = c.makeImage()!
    save(full, "concept-\(key)-1024.png")
    for n in [512, 180, 60] {
        let sm = canvas(n); sm.draw(full, in: CGRect(x: 0, y: 0, width: n, height: n)); save(sm.makeImage()!, "concept-\(key)-\(n).png")
    }
    print("wrote concept-\(key)")
}
