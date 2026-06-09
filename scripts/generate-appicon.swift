#!/usr/bin/env swift

import AppKit

let sizes: [(filename: String, px: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

let outputDir = URL(fileURLWithPath: CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "Globemaster/Assets.xcassets/AppIcon.appiconset")

guard let symbol = NSImage(systemSymbolName: "globe", accessibilityDescription: nil) else {
    print("Error: symbol not found"); exit(1)
}

for (filename, px) in sizes {
    let bmp = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: px, pixelsHigh: px,
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bmp)
    symbol.draw(in: NSRect(x: 0, y: 0, width: px, height: px))
    NSGraphicsContext.restoreGraphicsState()

    let data = bmp.representation(using: .png, properties: [:])!
    let dest = outputDir.appendingPathComponent(filename)
    try! data.write(to: dest)
    print("✓ \(filename)")
}
print("Done.")
