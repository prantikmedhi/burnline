#!/usr/bin/env swift
import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assetDirectory = root.appending(path: "assets/brand")
let resourceDirectory = root.appending(path: "Resources")
let iconset = resourceDirectory.appending(path: "Burnline.iconset")
try FileManager.default.createDirectory(at: assetDirectory, withIntermediateDirectories: true)
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

func render(size: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }

    let scale = CGFloat(size) / 1024
    func rect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> NSRect {
        NSRect(x: x * scale, y: y * scale, width: width * scale, height: height * scale)
    }

    let tile = NSBezierPath(roundedRect: rect(32, 32, 960, 960), xRadius: 232 * scale, yRadius: 232 * scale)
    NSGraphicsContext.saveGraphicsState()
    tile.addClip()
    NSGradient(colors: [
        NSColor(calibratedRed: 0.47, green: 0.46, blue: 1.00, alpha: 1),
        NSColor(calibratedRed: 0.31, green: 0.30, blue: 0.79, alpha: 1),
        NSColor(calibratedRed: 0.12, green: 0.15, blue: 0.31, alpha: 1)
    ])!.draw(in: tile.bounds, angle: -52)

    let light = NSBezierPath(ovalIn: rect(430, 500, 720, 720))
    NSColor(calibratedRed: 0.39, green: 0.82, blue: 1.00, alpha: 0.24).setFill()
    light.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSColor.white.withAlphaComponent(0.16).setFill()
    let lens = NSBezierPath(roundedRect: rect(176, 230, 672, 578), xRadius: 195 * scale, yRadius: 195 * scale)
    lens.fill()
    NSColor.white.withAlphaComponent(0.30).setStroke()
    lens.lineWidth = 5 * scale
    lens.stroke()

    let highlight = NSBezierPath()
    highlight.move(to: NSPoint(x: 236 * scale, y: 682 * scale))
    highlight.curve(
        to: NSPoint(x: 785 * scale, y: 690 * scale),
        controlPoint1: NSPoint(x: 360 * scale, y: 822 * scale),
        controlPoint2: NSPoint(x: 650 * scale, y: 825 * scale)
    )
    NSColor.white.withAlphaComponent(0.22).setStroke()
    highlight.lineWidth = 14 * scale
    highlight.lineCapStyle = .round
    highlight.stroke()

    let wave = NSBezierPath()
    wave.move(to: NSPoint(x: 250 * scale, y: 494 * scale))
    wave.curve(
        to: NSPoint(x: 514 * scale, y: 510 * scale),
        controlPoint1: NSPoint(x: 334 * scale, y: 750 * scale),
        controlPoint2: NSPoint(x: 412 * scale, y: 250 * scale)
    )
    wave.curve(
        to: NSPoint(x: 776 * scale, y: 585 * scale),
        controlPoint1: NSPoint(x: 626 * scale, y: 744 * scale),
        controlPoint2: NSPoint(x: 690 * scale, y: 705 * scale)
    )
    NSColor.white.setStroke()
    wave.lineWidth = 56 * scale
    wave.lineCapStyle = .round
    wave.stroke()

    NSColor(calibratedRed: 0.57, green: 0.90, blue: 1.00, alpha: 1).setFill()
    let terminal = NSBezierPath(ovalIn: rect(732, 541, 88, 88))
    terminal.fill()
    NSColor.white.setStroke()
    terminal.lineWidth = 12 * scale
    terminal.stroke()

    return image
}

func png(_ image: NSImage) throws -> Data {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "Burnline.Icon", code: 1)
    }
    return data
}

let outputs = [
    (16, "icon_16x16.png"), (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"), (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"), (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"), (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"), (1024, "icon_512x512@2x.png")
]
for (size, name) in outputs {
    try png(render(size: size)).write(to: iconset.appending(path: name))
}
try png(render(size: 1024)).write(to: assetDirectory.appending(path: "app-icon.png"))

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", "-o", resourceDirectory.appending(path: "Burnline.icns").path, iconset.path]
try iconutil.run()
iconutil.waitUntilExit()
guard iconutil.terminationStatus == 0 else { exit(iconutil.terminationStatus) }
try FileManager.default.removeItem(at: iconset)
print("Generated Liquid Glass app-icon.png and Burnline.icns")
