// Draws the Number Snake icon with CoreGraphics and writes PNGs.
// Usage: make-icon <output-dir>   (writes icon_<pixels>.png for every size an .icns needs)
//
// Every size is drawn natively from the same layout rather than shrunk from
// the big one, and all edges are snapped to whole pixels so the squares stay crisp.
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255,
            blue: CGFloat(hex & 255) / 255, alpha: a)
}

let blue = rgb(0x2f6fe4), cyan = rgb(0x5cd0e0), violet = rgb(0x9d8df5), mint = rgb(0xa9f2d4)
let navy = rgb(0x18245e), nucleus = rgb(0x35208c), red = rgb(0xe3122b), black = rgb(0x0a0a0a)
let paper = rgb(0xf6f4ef), gridLine = rgb(0xd8d4ca)

// The picture on a 10 x 10 grid: (column, row) from the top left.
// The creature heads up and to the right; its trail thins away to the lower left.
typealias Cell = (Int, Int, CGColor)
let cells: [Cell] = [
    // infection it is heading for
    (7, 1, red), (8, 1, black), (6, 2, black), (7, 2, red), (8, 2, red), (7, 3, black), (8, 3, red),
    // trail, oldest and thinnest first
    (1, 8, navy), (1, 7, mint), (2, 8, mint),
    (2, 6, violet), (2, 7, violet), (3, 7, violet),
    // body (fresh blue, brighter cyan at the front)
    (3, 4, blue), (4, 4, blue), (5, 4, cyan),
    (2, 5, blue), (3, 5, blue), (4, 5, blue), (5, 5, blue), (6, 5, cyan),
    (3, 6, blue), (4, 6, blue), (5, 6, blue),
]
let nucleusCell = (4, 5)
let gridCount = 10

func render(pixels s: Int) -> CGImage {
    let ctx = CGContext(data: nil, width: s, height: s, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.translateBy(x: 0, y: CGFloat(s)); ctx.scaleBy(x: 1, y: -1)   // draw with y pointing down
    let S = CGFloat(s)

    // macOS icon shape: an 824/1024 rounded square, centred, with a soft shadow beneath
    let side = (S * 824 / 1024).rounded()
    let margin = ((S - side) / 2).rounded()
    let body = CGRect(x: margin, y: margin, width: side, height: side)
    let radius = side * 0.2237
    let shape = CGPath(roundedRect: body, cornerWidth: radius, cornerHeight: radius, transform: nil)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -S * 0.010), blur: S * 0.02, color: rgb(0x000000, 0.28))
    ctx.setFillColor(paper)
    ctx.addPath(shape); ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(shape); ctx.clip()
    ctx.setFillColor(paper); ctx.fill(body)

    // grid lines (edges snapped to whole pixels)
    func edge(_ i: Int) -> CGFloat { margin + (side * CGFloat(i) / CGFloat(gridCount)).rounded() }
    let lineW = max(1, (S / 512).rounded())
    ctx.setFillColor(gridLine)
    for i in 1..<gridCount {
        ctx.fill(CGRect(x: edge(i) - lineW / 2, y: margin, width: lineW, height: side))
        ctx.fill(CGRect(x: margin, y: edge(i) - lineW / 2, width: side, height: lineW))
    }

    // cells: a hair of paper between neighbours once the icon is big enough
    let gap: CGFloat = s >= 128 ? (side / CGFloat(gridCount) * 0.07).rounded() : 0
    func rect(_ c: Int, _ r: Int, inset: CGFloat) -> CGRect {
        CGRect(x: edge(c) + inset, y: edge(r) + inset,
               width: edge(c + 1) - edge(c) - inset * 2, height: edge(r + 1) - edge(r) - inset * 2)
    }
    for (c, r, colour) in cells {
        ctx.setFillColor(colour); ctx.fill(rect(c, r, inset: gap))
    }
    // the nucleus: a small dark square inside the body, leaning toward the infection
    let nc = rect(nucleusCell.0, nucleusCell.1, inset: 0)
    let n = max(1, (nc.width * 0.62).rounded())
    ctx.setFillColor(nucleus)
    ctx.fill(CGRect(x: (nc.midX - n / 2 + nc.width * 0.08).rounded(), y: (nc.midY - n / 2 - nc.height * 0.08).rounded(), width: n, height: n))

    // faint outline so the icon sits cleanly on light and dark backgrounds
    ctx.restoreGState()
    ctx.setStrokeColor(rgb(0x000000, 0.12)); ctx.setLineWidth(max(1, S / 512))
    ctx.addPath(shape); ctx.strokePath()
    return ctx.makeImage()!
}

let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
for s in [16, 32, 64, 128, 256, 512, 1024] {
    let url = out.appendingPathComponent("icon_\(s).png")
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else { fatalError("cannot write \(url.path)") }
    CGImageDestinationAddImage(dest, render(pixels: s), nil)
    guard CGImageDestinationFinalize(dest) else { fatalError("cannot finish \(url.path)") }
}
print("icon PNGs written to \(out.path)")
