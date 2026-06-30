import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import PresentationDataUtils
import AccountContext

private final class WinterGramMainSettingsArguments {
    let openCategory: (WinterGramSettingsSection) -> Void
    let openUrl: (String) -> Void
    let updateSettings: (@escaping (WinterGramSettings) -> WinterGramSettings) -> Void
    let appVersionString: String

    init(
        openCategory: @escaping (WinterGramSettingsSection) -> Void,
        openUrl: @escaping (String) -> Void,
        updateSettings: @escaping (@escaping (WinterGramSettings) -> WinterGramSettings) -> Void,
        appVersionString: String
    ) {
        self.openCategory = openCategory
        self.openUrl = openUrl
        self.updateSettings = updateSettings
        self.appVersionString = appVersionString
    }
}

private enum WinterGramMainSettingsSection: Int32 {
    case banner
    case categories
    case information
    case links
}

private struct WinterGramLink {
    let symbol: String
    let imageName: String?
    let title: String
    let value: String
    let url: String
    let color: UIColor

    init(symbol: String, imageName: String? = nil, title: String, value: String, url: String, color: UIColor = UIColor(rgb: 0x8E8E93)) {
        self.symbol = symbol
        self.imageName = imageName
        self.title = title
        self.value = value
        self.url = url
        self.color = color
    }
}

private let winterGramLinks: [WinterGramLink] = [
    WinterGramLink(symbol: "paperplane.fill", title: "Channel", value: "@wntgram", url: "https://t.me/wntgram", color: UIColor(rgb: 0x2AABEE)),
    WinterGramLink(symbol: "sparkles", title: "Beta", value: "@wntbeta", url: "https://t.me/wntbeta", color: UIColor(rgb: 0xFF9F0A)),
    WinterGramLink(symbol: "bubble.left.and.bubble.right.fill", title: "Chat", value: "@wntForum", url: "https://t.me/wntForum", color: UIColor(rgb: 0x34C759)),
    WinterGramLink(symbol: "puzzlepiece.extension.fill", title: "Plugins", value: "@wntPlugins", url: "https://t.me/wntPlugins", color: UIColor(rgb: 0xBF5AF2)),
    WinterGramLink(symbol: "link", imageName: "Item List/Icons/GitHub", title: "GitHub", value: "reekeer/WinterGram", url: "https://github.com/reekeer/WinterGram")
]

private enum WinterGramMainSettingsEntry: ItemListNodeEntry {
    case banner
    case categoriesHeader
    case ayugram
    case features
    case other
    case spoofing
    case hiddenArchive
    case informationHeader
    case infoAbout
    case infoUseDefaultBranding(Bool)
    case infoVersion
    case infoFooter
    case linksHeader
    case link(Int, WinterGramLink)
    case linksFooter

    var section: ItemListSectionId {
        switch self {
        case .banner:
            return WinterGramMainSettingsSection.banner.rawValue
        case .linksHeader, .link, .linksFooter:
            return WinterGramMainSettingsSection.links.rawValue
        case .informationHeader, .infoAbout, .infoUseDefaultBranding, .infoVersion, .infoFooter:
            return WinterGramMainSettingsSection.information.rawValue
        default:
            return WinterGramMainSettingsSection.categories.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .banner: return -1
        case .categoriesHeader: return 10
        case .ayugram: return 11
        case .features: return 12
        case .other: return 14
        case .spoofing: return 15
        case .hiddenArchive: return 16
        case .informationHeader: return 20
        case .infoAbout: return 21
        case .infoUseDefaultBranding: return 22
        case .infoVersion: return 23
        case .infoFooter: return 25
        case .linksHeader: return 30
        case let .link(index, _): return 31 + Int32(index)
        case .linksFooter: return 100
        }
    }

    static func ==(lhs: WinterGramMainSettingsEntry, rhs: WinterGramMainSettingsEntry) -> Bool {
        return lhs.stableId == rhs.stableId
    }

    static func <(lhs: WinterGramMainSettingsEntry, rhs: WinterGramMainSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! WinterGramMainSettingsArguments
        let accent = presentationData.theme.list.itemAccentColor
        let lang = presentationData.strings
        let category: WinterGramSettingsSection
        let title: String
        let iconName: String
        let iconColor: UIColor
        switch self {
        case .banner:
            return WinterGramBannerItem(theme: presentationData.theme, title: "WinterGram", subtitle: "", iconImage: UIImage(bundleImageName: "WinterGramDark"), sectionId: self.section)
        case .categoriesHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: presentationData.strings.WinterGram_Categories, sectionId: self.section)
        case .informationHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: lang.WinterGram_INFORMATION, sectionId: self.section)
        case .infoAbout:
            return ItemListTextItem(presentationData: presentationData, text: .plain(lang.WinterGram_WinterGramWntIsAPrivacyFocusedMessagingClientForIPhoneANativePortOfTheAyuGramExperienceItAddsGhostModeSavedDeletedMessagesAndEditHistoryAHiddenArchiveLocalPremiumAdRemovalDeepCustomizationAndLiquidGlass), sectionId: self.section)
        case let .infoUseDefaultBranding(value):
            return ItemListSwitchItem(presentationData: presentationData, title: lang.WinterGram_UseDefaultTelegramBranding, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { var s = $0; s.useDefaultBranding = value; return s }
            })
        case .infoVersion:
            return ItemListDisclosureItem(presentationData: presentationData, title: lang.WinterGram_Version, label: arguments.appVersionString, sectionId: self.section, style: .blocks, disclosureStyle: .none, action: nil)
        case .infoFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain(lang.WinterGram_InfoFooter), sectionId: self.section)
        case .linksHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: presentationData.strings.WinterGram_Links, sectionId: self.section)
        case .linksFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain(lang.WinterGram_LinksFooter), sectionId: self.section)
        case let .link(_, link):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                icon: winterGramCategoryIcon(symbolName: link.symbol, imageName: link.imageName, backgroundColor: link.color),
                title: wntOption(link.title, presentationData.strings),
                label: link.value,
                labelStyle: .coloredText(accent),
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .none,
                action: {
                    arguments.openUrl(link.url)
                }
            )
        case .ayugram:
            category = .ayugram; title = "Core"; iconName = "shield.fill"; iconColor = UIColor(rgb: 0x0A84FF)
        case .features:
            category = .antiFeatures; title = "Features"; iconName = "sparkles"; iconColor = UIColor(rgb: 0xFF9F0A)
        case .other:
            category = .other; title = "Other"; iconName = "ellipsis.circle"; iconColor = UIColor(rgb: 0x8E8E93)
        case .spoofing:
            category = .spoofing; title = "Spoofing"; iconName = "theatermasks.fill"; iconColor = UIColor(rgb: 0xBF5AF2)
        case .hiddenArchive:
            category = .stash; title = "Hidden Archive"; iconName = "tray.full.fill"; iconColor = UIColor(rgb: 0x30D158)
        }
        return ItemListDisclosureItem(
            presentationData: presentationData,
            icon: winterGramCategoryIcon(iconName, iconColor),
            title: wntOption(title, presentationData.strings),
            label: "",
            sectionId: self.section,
            style: .blocks,
            disclosureStyle: .arrow,
            action: {
                arguments.openCategory(category)
            }
        )
    }
}

private func winterGramCategoryIcon(_ symbolName: String, _ backgroundColor: UIColor) -> UIImage? {
    return winterGramCategoryIcon(symbolName: symbolName, imageName: nil, backgroundColor: backgroundColor)
}

private func winterGramCategoryIcon(symbolName: String, imageName: String?, backgroundColor: UIColor) -> UIImage? {
    // Match the iOS-Settings-style colored icons Telegram uses for settings rows: the image *is* the
    // rounded colored backplate (~30pt), centered by ItemListDisclosureItem in its icon column, with a
    // white glyph that has comfortable padding. The previous 44pt image held a small 34pt backplate, so
    // icons looked oversized/off-centre next to standard rows and the backplate looked too small.
    let size = CGSize(width: 32.0, height: 32.0)
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { _ in
        let bounds = CGRect(origin: .zero, size: size)
        // ~0.225 of the side gives the iOS app-icon "squircle" feel at this size.
        let backplate = UIBezierPath(roundedRect: bounds, cornerRadius: 7.5)
        backgroundColor.setFill()
        backplate.fill()
        let icon: UIImage?
        if let imageName = imageName {
            icon = UIImage(bundleImageName: imageName)?.withRenderingMode(.alwaysTemplate)
        } else {
            icon = UIImage(systemName: symbolName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 20.0, weight: .bold))?.withRenderingMode(.alwaysTemplate)
        }
        guard let symbol = icon?.withTintColor(.white, renderingMode: .alwaysOriginal) else {
            return
        }
        let maxIconSide: CGFloat = 21.0
        let symbolScale = min(maxIconSide / max(symbol.size.width, 1.0), maxIconSide / max(symbol.size.height, 1.0), 1.0)
        let symbolSize = CGSize(width: symbol.size.width * symbolScale, height: symbol.size.height * symbolScale)
        symbol.draw(in: CGRect(
            x: (size.width - symbolSize.width) / 2.0,
            y: (size.height - symbolSize.height) / 2.0,
            width: symbolSize.width,
            height: symbolSize.height
        ))
    }
}

private func winterGramMainSettingsEntries(settings: WinterGramSettings) -> [WinterGramMainSettingsEntry] {
    var entries: [WinterGramMainSettingsEntry] = [
        .banner,
        .categoriesHeader,
        .ayugram,
        .features,
        .other,
        .spoofing,
        .hiddenArchive,
        .linksHeader
    ]
    for (index, link) in winterGramLinks.enumerated() {
        entries.append(.link(index, link))
    }
    entries.append(.linksFooter)
    return entries
}

public func winterGramMainSettingsController(context: AccountContext) -> ViewController {
    var pushControllerImpl: ((ViewController) -> Void)?
    var getNavigationControllerImpl: (() -> NavigationController?)?

    let accountManager = context.sharedContext.accountManager
    let updateSettings: (@escaping (WinterGramSettings) -> WinterGramSettings) -> Void = { f in
        let _ = updateWinterGramSettingsInteractively(accountManager: accountManager, f).startStandalone()
    }

    let appVersionString: String = {
        let version = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? ""
        let build = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? ""
        return build.isEmpty ? version : "\(version) (\(build))"
    }()

    let arguments = WinterGramMainSettingsArguments(
        openCategory: { category in
            pushControllerImpl?(winterGramSettingsController(context: context, category: category))
        },
        openUrl: { url in
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            context.sharedContext.openExternalUrl(context: context, urlContext: .generic, url: url, forceExternal: false, presentationData: presentationData, navigationController: getNavigationControllerImpl?(), dismissInput: {})
        },
        updateSettings: updateSettings,
        appVersionString: appVersionString
    )

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        winterGramSettings(accountManager: context.sharedContext.accountManager)
    )
    |> deliverOnMainQueue
    |> map { presentationData, settings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("WinterGram"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: winterGramMainSettingsEntries(settings: settings),
            style: .blocks,
            animateChanges: true
        )
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    pushControllerImpl = { [weak controller] c in
        controller?.push(c)
    }
    getNavigationControllerImpl = { [weak controller] in
        return controller?.navigationController as? NavigationController
    }
    return controller
}
