#!/usr/bin/env swift
import Foundation
import CoreGraphics
import ImageIO

let projectRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let backplateURL = projectRoot.appendingPathComponent("branding/backplate_badge.png")
let snowflakeURL = projectRoot.appendingPathComponent("branding/snowflake_monochrome.png")
let outputDir = projectRoot.appendingPathComponent("submodules/TelegramUI/Images.xcassets/Item List/Icons/WinterGram.imageset")

func loadImage(url: URL) -> CGImage? {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(source, 0, nil)
}

func saveImage(_ image: CGImage, url: URL) {
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypePNG, 1, nil) else {
        fatalError("Cannot create PNG destination for \(url.path)")
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        fatalError("Failed to write \(url.path)")
    }
}

func composedBadge(backplate: CGImage, snowflake: CGImage, pixelSize: CGFloat) -> CGImage? {
    let size = CGSize(width: pixelSize, height: pixelSize)
    guard let context = CGContext(
        data: nil,
        width: Int(pixelSize),
        height: Int(pixelSize),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    context.clear(CGRect(origin: .zero, size: size))

    // Backplate fills the badge canvas (matches the runtime badge composition).
    context.draw(backplate, in: CGRect(origin: .zero, size: size))

    // Snowflake is 756/1024 of the badge, centred.
    let snowflakeSize = pixelSize * 756.0 / 1024.0
    let snowflakeOffset = (pixelSize - snowflakeSize) / 2.0
    context.draw(snowflake, in: CGRect(x: snowflakeOffset, y: snowflakeOffset, width: snowflakeSize, height: snowflakeSize))

    return context.makeImage()
}

guard let backplate = loadImage(url: backplateURL) else {
    fatalError("Cannot load backplate at \(backplateURL.path)")
}
guard let snowflake = loadImage(url: snowflakeURL) else {
    fatalError("Cannot load snowflake at \(snowflakeURL.path)")
}

let sizes: [(name: String, px: CGFloat)] = [
    ("wintergram_snowflake_30@2x.png", 60.0),
    ("wintergram_snowflake_30@3x.png", 90.0)
]

for (name, px) in sizes {
    guard let image = composedBadge(backplate: backplate, snowflake: snowflake, pixelSize: px) else {
        fatalError("Failed to compose \(name)")
    }
    let url = outputDir.appendingPathComponent(name)
    saveImage(image, url: url)
    print("Wrote \(url.path)")
}
