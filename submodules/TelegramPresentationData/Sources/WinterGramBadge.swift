import Foundation
import UIKit
import Display
import AppBundle
import TelegramCore
import TelegramUIPreferences

private let winterGramBadgeCacheLock = NSLock()
private var winterGramComposedBadgeCache: [UInt32: UIImage] = [:]

private func winterGramColorKey(_ color: UIColor) -> UInt32 {
    var r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0, a: CGFloat = 0.0
    color.getRed(&r, green: &g, blue: &b, alpha: &a)
    func channel(_ v: CGFloat) -> UInt32 { return UInt32(max(0.0, min(1.0, v)) * 255.0) }
    return (channel(r) << 16) | (channel(g) << 8) | channel(b)
}

public func winterGramComposedBadge(backplateColor: UIColor) -> UIImage? {
    let key = winterGramColorKey(backplateColor)
    winterGramBadgeCacheLock.lock()
    if let cached = winterGramComposedBadgeCache[key] {
        winterGramBadgeCacheLock.unlock()
        return cached
    }
    winterGramBadgeCacheLock.unlock()

    guard let backplate = UIImage(bundleImageName: "WntGramBackplateShape"), let snowflake = UIImage(bundleImageName: "WntGramSnowflakeShape") else {
        return nil
    }
    let size = CGSize(width: 36.0, height: 36.0)
    let renderer = UIGraphicsImageRenderer(size: size)
    let image = renderer.image { _ in
        backplate.withTintColor(backplateColor, renderingMode: .alwaysOriginal).draw(in: CGRect(origin: .zero, size: size))
        let snowflakeSize = size.width * 756.0 / 1024.0
        let snowflakeOffset = size.width * 134.0 / 1024.0
        snowflake.withTintColor(.white, renderingMode: .alwaysOriginal).draw(in: CGRect(x: snowflakeOffset, y: snowflakeOffset, width: snowflakeSize, height: snowflakeSize))
    }
    winterGramBadgeCacheLock.lock()
    winterGramComposedBadgeCache[key] = image
    winterGramBadgeCacheLock.unlock()
    return image
}

public func winterGramBadgeBackplateColor(theme: PresentationTheme) -> UIColor {
    return theme.list.itemAccentColor.withMultipliedBrightnessBy(0.82)
}

private var winterGramComposedBadgeCacheV2: [String: UIImage] = [:]

private func winterGramLayerImage(source: String) -> UIImage? {
    if let url = WinterGramBadgeManager.shared.localAssetFileURL(forSource: source), let image = UIImage(contentsOfFile: url.path) {
        return image
    }
    return UIImage(bundleImageName: source)
}

public func winterGramComposedBadge(for badge: WinterGramBadgeDef, canvas: Double, themeColor: UIColor, size: CGSize) -> UIImage? {
    let canvasValue = canvas > 0.0 ? canvas : 1024.0
    let version = WinterGramBadgeManager.shared.manifest.version
    let key = "\(badge.id)|\(version)|\(winterGramColorKey(themeColor))|\(Int(size.width))x\(Int(size.height))"
    winterGramBadgeCacheLock.lock()
    if let cached = winterGramComposedBadgeCacheV2[key] {
        winterGramBadgeCacheLock.unlock()
        return cached
    }
    winterGramBadgeCacheLock.unlock()

    let renderer = UIGraphicsImageRenderer(size: size)
    let image = renderer.image { _ in
        for layer in badge.layers {
            if layer.isLottie {
                continue
            }
            guard let layerImage = winterGramLayerImage(source: layer.source) else {
                continue
            }
            let rect = CGRect(
                x: layer.x / canvasValue * size.width,
                y: layer.y / canvasValue * size.height,
                width: layer.width / canvasValue * size.width,
                height: layer.height / canvasValue * size.height
            )
            switch layer.tint {
            case .theme:
                layerImage.withTintColor(themeColor, renderingMode: .alwaysOriginal).draw(in: rect)
            case let .hex(value):
                layerImage.withTintColor(UIColor(rgb: value), renderingMode: .alwaysOriginal).draw(in: rect)
            case .original:
                layerImage.draw(in: rect)
            }
        }
    }
    winterGramBadgeCacheLock.lock()
    winterGramComposedBadgeCacheV2[key] = image
    winterGramBadgeCacheLock.unlock()
    return image
}

public func winterGramBadgeImage(for peer: EnginePeer, theme: PresentationTheme) -> UIImage? {
    guard let badge = WinterGramBadgeManager.shared.badge(for: peer) else {
        return nil
    }
    let manifest = WinterGramBadgeManager.shared.manifest
    return winterGramComposedBadge(for: badge, canvas: manifest.canvas, themeColor: winterGramBadgeBackplateColor(theme: theme), size: CGSize(width: 36.0, height: 36.0))
}
