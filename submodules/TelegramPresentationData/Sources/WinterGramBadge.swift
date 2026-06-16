import Foundation
import UIKit
import Display
import AppBundle
import TelegramCore
import TelegramUIPreferences

// Runtime-composed WinterGram badge.
//
// Instead of shipping a fixed-colour PNG, the badge is composed on demand from two white-on-transparent
// shape assets (a scalloped backplate + a snowflake) so the backplate can follow the current theme
// colour. Per the design spec (1024² canvas): the backplate fills 1024@(0,0), the snowflake is 756²
// at (134,134). Results are cached per backplate colour; because every badge view re-renders when the
// presentation theme changes, this naturally recomposes the badge for the new theme.

private let winterGramBadgeCacheLock = NSLock()
private var winterGramComposedBadgeCache: [UInt32: UIImage] = [:]

private func winterGramColorKey(_ color: UIColor) -> UInt32 {
    var r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0, a: CGFloat = 0.0
    color.getRed(&r, green: &g, blue: &b, alpha: &a)
    func channel(_ v: CGFloat) -> UInt32 { return UInt32(max(0.0, min(1.0, v)) * 255.0) }
    return (channel(r) << 16) | (channel(g) << 8) | channel(b)
}

/// Composes the badge image: a scalloped backplate filled with `backplateColor` and a white snowflake
/// on top, following the 1024 spec. Cached per colour.
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

/// The backplate colour for the current theme: the accent colour, slightly darkened.
public func winterGramBadgeBackplateColor(theme: PresentationTheme) -> UIColor {
    return theme.list.itemAccentColor.withMultipliedBrightnessBy(0.82)
}

/// The themed badge image for a peer, or nil if the peer carries no WinterGram badge.
/// Every official peer (developers and official channels) gets the composed backplate badge.
public func winterGramBadgeImage(for peer: EnginePeer, theme: PresentationTheme) -> UIImage? {
    guard isWinterGramOfficialPeer(peer) else {
        return nil
    }
    return winterGramComposedBadge(backplateColor: winterGramBadgeBackplateColor(theme: theme))
}
