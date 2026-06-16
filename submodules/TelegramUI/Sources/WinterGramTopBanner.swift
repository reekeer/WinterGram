import UIKit
import Display
import TelegramUIPreferences

// WinterGram: a persistent branding banner shown at the very top, centred in the Dynamic Island /
// notch band. It is a purely decorative overlay added to the key window — `isUserInteractionEnabled`
// is false so it never intercepts touches. For now there is a single banner type (the bundled
// `WntGramBanner` image); `WinterGramTopBannerStyle.off` hides it, any other value shows it.
public final class WinterGramTopBannerView: UIView {
    private let bannerImageView = UIImageView()
    private var style: WinterGramTopBannerStyle = .off
    private var currentImageName: String?

    // wnt-banner.png is 1034×250.
    private let bannerAspect: CGFloat = 1034.0 / 250.0

    public init() {
        super.init(frame: .zero)
        self.isUserInteractionEnabled = false
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        self.bannerImageView.contentMode = .scaleAspectFit
        self.bannerImageView.image = UIImage(bundleImageName: "WntGramBanner")
        self.addSubview(self.bannerImageView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func update(style: WinterGramTopBannerStyle, imageName: String, text: String) {
        self.style = style
        self.isHidden = style == .off
        let resolvedImageName = imageName.isEmpty ? "WntGramBanner" : imageName
        if self.bannerImageView.image == nil || self.currentImageName != resolvedImageName {
            self.bannerImageView.image = UIImage(bundleImageName: resolvedImageName) ?? UIImage(bundleImageName: "WntGramBanner")
            self.currentImageName = resolvedImageName
        }
        self.setNeedsLayout()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        guard self.style != .off else {
            return
        }

        let bannerHeight: CGFloat = 24.0
        let bannerWidth = floor(bannerHeight * self.bannerAspect)

        // Vertically centre the banner in the top safe-area band (status bar / Dynamic Island region).
        let topInset = self.safeAreaInsets.top
        let bannerY = max(2.0, (topInset - bannerHeight) / 2.0 + 2.0)
        let bannerX = floor((self.bounds.width - bannerWidth) / 2.0)

        self.bannerImageView.frame = CGRect(x: bannerX, y: bannerY, width: bannerWidth, height: bannerHeight)
    }
}
