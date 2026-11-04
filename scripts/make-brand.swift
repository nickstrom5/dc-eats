// DC Eats brand: the app icon (Nick's pick 2026-10-27: concept B of scripts/icon-concepts.swift, a jumbo slice, tip up, hanging over a
// round paper plate on navy; the shared Eats Ranked icon style, state-prompts/ICON-STYLE.md, with the plate as the backing shape).
// Usage, from dc-eats/: swift scripts/make-brand.swift   -> DCEats/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png,
// docs/ favicons and touch icons, docs/og.png. scripts/make-site.py draws the same mark as its inline SVG: change both together.
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

func rgb(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: 1)
}
let NAVY: UInt32 = 0x041E42, RED: UInt32 = 0xC8102E

/// The jumbo slice (plan view). A round paper plate is the backing shape (like Connecticut's sheet pan); the slice lies on it, tip down,
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

func render(_ n: Int, _ path: String, background: Bool) {
    let ctx = CGContext(data: nil, width: n, height: n, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: background ? CGImageAlphaInfo.noneSkipLast.rawValue : CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.setShouldAntialias(true)
    if background { ctx.setFillColor(rgb(NAVY)); ctx.fill(CGRect(x: 0, y: 0, width: n, height: n)) }
    jumboSlice(ctx, CGFloat(n))
    let d = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(d, ctx.makeImage()!, nil)
    guard CGImageDestinationFinalize(d) else { fatalError("could not write \(path)") }
    print("wrote", path)
}
render(1024, "DCEats/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png", background: true)
try? FileManager.default.createDirectory(atPath: "docs", withIntermediateDirectories: true)
for (n, name) in [(512, "icon-512.png"), (192, "icon-192.png"), (180, "apple-touch-icon.png"), (32, "favicon-32.png")] {
    render(n, "docs/" + name, background: true)
}

/// The share image (1200 x 630): navy, the slice on its navy square at the left, the name and tagline at the right, and the flag's three
/// red stars over two red bars along the bottom.
func og(_ path: String) {
    let W = 1200, H = 630
    let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.setShouldAntialias(true)
    ctx.setFillColor(rgb(NAVY)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
    // the flag band (CoreGraphics y-up): two bars, three stars above them
    ctx.setFillColor(rgb(RED)); ctx.fill(CGRect(x: 0, y: 18, width: W, height: 12)); ctx.fill(CGRect(x: 0, y: 42, width: W, height: 12))
    for k in -1...1 {
        let cx = 600.0 + Double(k) * 64, cy = 92.0, r = 22.0
        let p = CGMutablePath()
        for i in 0..<10 {
            let a = Double.pi / 2 + Double(i) * Double.pi / 5, rr = i % 2 == 0 ? r : r * 0.382
            let pt = CGPoint(x: cx + rr * cos(a), y: cy + rr * sin(a))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath(); ctx.addPath(p); ctx.fillPath()
    }
    // the app icon's square with the slice, outlined so it reads on the navy page
    let sq = CGRect(x: 70, y: 170, width: 400, height: 400)
    ctx.saveGState(); ctx.addPath(CGPath(roundedRect: sq, cornerWidth: 88, cornerHeight: 88, transform: nil)); ctx.clip()
    ctx.setFillColor(rgb(NAVY)); ctx.fill(sq)
    ctx.translateBy(x: sq.minX, y: sq.minY); jumboSlice(ctx, 400)
    ctx.restoreGState()
    ctx.setStrokeColor(rgb(0x1C3A66)); ctx.setLineWidth(4)
    ctx.addPath(CGPath(roundedRect: sq, cornerWidth: 88, cornerHeight: 88, transform: nil)); ctx.strokePath()
    let ns = NSGraphicsContext(cgContext: ctx, flipped: false)
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = ns
    let title = NSFont(name: "AvenirNextCondensed-Heavy", size: 120) ?? NSFont.boldSystemFont(ofSize: 110)
    let sub = NSFont(name: "AvenirNextCondensed-DemiBold", size: 40) ?? NSFont.boldSystemFont(ofSize: 36)
    NSAttributedString(string: "DC EATS", attributes: [.font: title, .foregroundColor: NSColor.white]).draw(at: NSPoint(x: 520, y: 360))
    NSAttributedString(string: "HALF-SMOKES, INJERA & PUPUSAS", attributes: [.font: sub, .foregroundColor: NSColor(srgbRed: 0.973, green: 0.863, blue: 0.882, alpha: 1)]).draw(at: NSPoint(x: 524, y: 300))
    NSAttributedString(string: "Restaurants in all 8 wards", attributes: [.font: NSFont(name: "AvenirNext-Medium", size: 30) ?? NSFont.systemFont(ofSize: 30), .foregroundColor: NSColor.white]).draw(at: NSPoint(x: 524, y: 250))
    NSGraphicsContext.restoreGraphicsState()
    let d = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(d, ctx.makeImage()!, nil)
    guard CGImageDestinationFinalize(d) else { fatalError("could not write \(path)") }
    print("wrote", path)
}
og("docs/og.png")
