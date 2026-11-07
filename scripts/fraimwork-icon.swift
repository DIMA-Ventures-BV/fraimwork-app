// Draws the placeholder fraimwork icon.
// Usage: swift scripts/fraimwork-icon.swift <full.png> <glyph.png>
// full.png: 1024 px rounded tile with the "f_" mark (for AppIcon.appiconset).
// glyph.png: 1024 px "f_" mark on a clear background (for AppIcon.icon).
import AppKit

func render(size: CGFloat, tile: Bool, to path: String) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    if tile {
        let inset = size * 0.1
        let rect = NSRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset)
        let path = NSBezierPath(roundedRect: rect, xRadius: rect.width * 0.225, yRadius: rect.width * 0.225)
        NSGradient(
            starting: NSColor(calibratedRed: 0.11, green: 0.12, blue: 0.20, alpha: 1),
            ending: NSColor(calibratedRed: 0.27, green: 0.20, blue: 0.62, alpha: 1))!
            .draw(in: path, angle: -90)
    }

    let font = NSFont.monospacedSystemFont(ofSize: size * 0.40, weight: .bold)
    let text = NSMutableAttributedString(string: "f_", attributes: [
        .font: font,
        .foregroundColor: NSColor.white,
    ])
    text.addAttribute(.foregroundColor,
                      value: NSColor(calibratedRed: 0.45, green: 0.95, blue: 0.70, alpha: 1),
                      range: NSRange(location: 1, length: 1))
    let bounds = text.boundingRect(with: NSSize(width: size, height: size), options: [.usesLineFragmentOrigin])
    text.draw(at: NSPoint(x: (size - bounds.width) / 2, y: (size - bounds.height) / 2))

    NSGraphicsContext.restoreGraphicsState()
    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: path))
}

let args = CommandLine.arguments
guard args.count == 3 else {
    FileHandle.standardError.write("usage: fraimwork-icon.swift <full.png> <glyph.png>\n".data(using: .utf8)!)
    exit(2)
}
render(size: 1024, tile: true, to: args[1])
render(size: 1024, tile: false, to: args[2])
