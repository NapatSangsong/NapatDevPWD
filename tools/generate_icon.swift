#!/usr/bin/env swift
// Renders the Napat Dev app icon (cornflower squircle + white key glyph) at
// 1024×1024 and writes the PNG to the given path. Drawing is done directly
// into a CGContext bitmap so the output is reliable across macOS versions.
//
//   swift tools/generate_icon.swift tools/icon_1024.png
//
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let size: Int = 1024
let sizeF = CGFloat(size)
let outURL = URL(fileURLWithPath: CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "AppIcon.png")

let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(
    data: nil,
    width: size, height: size,
    bitsPerComponent: 8, bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fputs("Couldn't allocate CGContext\n", stderr); exit(1)
}

// Clear
ctx.clear(CGRect(x: 0, y: 0, width: sizeF, height: sizeF))

// Squircle-ish rounded rect
let inset: CGFloat = sizeF * 0.09
let rect = CGRect(x: inset, y: inset, width: sizeF - inset * 2, height: sizeF - inset * 2)
let radius: CGFloat = rect.width * 0.224
let roundedPath = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)

// Gradient fill (cornflower)
ctx.saveGState()
ctx.addPath(roundedPath)
ctx.clip()
let gradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [
        CGColor(red: 0x5B/255, green: 0x7C/255, blue: 0xFA/255, alpha: 1),
        CGColor(red: 0x8A/255, green: 0xA1/255, blue: 0xFF/255, alpha: 1),
    ] as CFArray,
    locations: [0, 1]
)!
ctx.drawLinearGradient(
    gradient,
    start: CGPoint(x: inset, y: sizeF - inset),
    end:   CGPoint(x: sizeF - inset, y: inset),
    options: []
)

// Subtle top highlight
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.18))
ctx.setLineWidth(3)
ctx.addPath(CGPath(
    roundedRect: rect.insetBy(dx: 2, dy: 2),
    cornerWidth: radius, cornerHeight: radius, transform: nil
))
ctx.strokePath()
ctx.restoreGState()

// Draw the key glyph by rasterising an SF Symbol NSImage into a CGImage, then
// painting that CGImage into our context. Avoids the fragility of NSImage +
// lockFocus in command-line scripts.
let symbolConfig = NSImage.SymbolConfiguration(pointSize: sizeF * 0.58, weight: .bold)
    .applying(.init(paletteColors: [.white]))

guard
    let symbolImage = NSImage(systemSymbolName: "key.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(symbolConfig),
    let symbolCG = symbolImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
else {
    fputs("Couldn't rasterise SF Symbol key.fill\n", stderr); exit(1)
}

let glyphWidth = CGFloat(symbolCG.width)
let glyphHeight = CGFloat(symbolCG.height)
let glyphRect = CGRect(
    x: (sizeF - glyphWidth) / 2,
    y: (sizeF - glyphHeight) / 2,
    width: glyphWidth,
    height: glyphHeight
)

// Diagonal tilt + soft drop-shadow
ctx.saveGState()
ctx.translateBy(x: sizeF / 2, y: sizeF / 2)
ctx.rotate(by: -.pi / 10)
ctx.translateBy(x: -sizeF / 2, y: -sizeF / 2)
ctx.setShadow(
    offset: CGSize(width: 0, height: -12),
    blur: 30,
    color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.25)
)
ctx.draw(symbolCG, in: glyphRect)
ctx.restoreGState()

// Write PNG
guard let cgImage = ctx.makeImage() else {
    fputs("Couldn't finalise CGImage\n", stderr); exit(1)
}
guard let dest = CGImageDestinationCreateWithURL(
    outURL as CFURL,
    UTType.png.identifier as CFString,
    1, nil
) else {
    fputs("Couldn't create PNG destination\n", stderr); exit(1)
}
CGImageDestinationAddImage(dest, cgImage, nil)
guard CGImageDestinationFinalize(dest) else {
    fputs("PNG finalise failed\n", stderr); exit(1)
}
print("Wrote \(outURL.path)")
