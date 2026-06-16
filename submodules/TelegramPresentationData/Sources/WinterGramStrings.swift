import Foundation
import PresentationStrings

// WinterGram's own UI strings live in `Telegram-iOS/en.lproj/Localizable.strings` under the
// `WinterGram.*` namespace and are consumed through Telegram's standard generated accessors
// (`strings.WinterGram_*`). English is served by the bundled `en.lproj` fallback baked into the
// generated `PresentationStrings`. Telegram's server language packs do not carry our fork keys,
// so to localize them we seed the active strings dictionary at construction time (see
// `PresentationData.swift`). This table is that seed: symbolic key -> translation. Add a new
// language by returning its table from `winterGramSeedStrings(languageCode:)`.
private let winterGramRussianSeed: [String: String] = [
    "WinterGram.APPEARANCE": "ОФОРМЛЕНИЕ",
    "WinterGram.AddVisualGift": "Добавить визуальный подарок",
    "WinterGram.AddVisuallyToProfile": "Добавить визуально в профиль",
    "WinterGram.AllowSavingRestrictedContent": "Сохранять защищённый контент",
    "WinterGram.Always": "Всегда",
    "WinterGram.Appearance": "Оформление",
    "WinterGram.AppearanceFooter": "Форма аватаров и сообщений, шрифты и пак иконок применяются во всём приложении.",
    "WinterGram.ApplyToBubbles": "Применять к сообщениям",
    "WinterGram.ApplyToChatList": "Применять к списку чатов",
    "WinterGram.ApplyToNavigationBars": "Применять к панелям навигации",
    "WinterGram.ApplyToTabBar": "Применять к таб-бару",
    "WinterGram.AutoMarkAsRead": "Авто-прочтение",
    "WinterGram.AutoPrivacy": "Автоконфиденциальность",
    "WinterGram.StashPrivacy.ProfilePhoto": "Аватарка",
    "WinterGram.StashPrivacy.PhoneNumber": "Номер телефона",
    "WinterGram.StashPrivacy.Presence": "Время захода",
    "WinterGram.StashPrivacy.Forwards": "Пересылка сообщений",
    "WinterGram.StashPrivacy.VoiceCalls": "Звонки",
    "WinterGram.StashPrivacy.Birthday": "День рождения",
    "WinterGram.StashPrivacy.GiftsAutoSave": "Подарки",
    "WinterGram.StashPrivacy.Bio": "О себе",
    "WinterGram.StashPrivacy.SavedMusic": "Сохранённая музыка",
    "WinterGram.StashPrivacy.GroupInvitations": "Приглашения",
    "WinterGram.Automatic": "Автоматически",
    "WinterGram.AvatarShape": "Форма аватара",
    "WinterGram.CoreMenu": "Ядро",
    "WinterGram.Core": "Ядро",
    "WinterGram.BadgeDeveloperRole": "— разработчик WinterGram.",
    "WinterGram.BadgeDeveloperSuffix": "поддержал(а) разработку WinterGram и получил(а) уникальный значок.",
    "WinterGram.BadgeOfficialChannelSuffix": "— официальный ресурс WinterGram.",
    "WinterGram.Beta": "Бета",
    "WinterGram.BubbleRadius": "Скругление сообщений",
    "WinterGram.CHAT": "ЧАТ",
    "WinterGram.Categories": "Категории",
    "WinterGram.Channel": "Канал",
    "WinterGram.AddTemplate": "Добавить шаблон",
    "WinterGram.LearnMore": "Подробнее",
    "WinterGram.Links": "Ссылки",
    "WinterGram.LinksFooter": "WinterGram\nВерсия: Beta v1.0.0",
    "WinterGram.MutualContact": "Взаимный контакт",
    "WinterGram.NotMutualContact": "Не взаимный контакт",
    "WinterGram.Other": "Прочее",
    "WinterGram.Releases": "Релизы",
    "WinterGram.ReadAfterAction": "Читать при действиях",
    "WinterGram.DontReadMessages": "Не читать сообщения",
    "WinterGram.DontReadStories": "Не читать истории",
    "WinterGram.DontSendOnline": "Не отправлять «онлайн»",
    "WinterGram.DontSendTyping": "Не отправлять «печатает»",
    "WinterGram.AutoOffline": "Автоматический «офлайн»",
    "WinterGram.Chat": "Чат",
    "WinterGram.ClearSavedDeletedMessages": "Очистить сохранённые удалённые",
    "WinterGram.ConfirmGIFs": "Подтверждать GIF",
    "WinterGram.ConfirmStickers": "Подтверждать стикеры",
    "WinterGram.ConfirmVoiceMessages": "Подтверждать голосовые",
    "WinterGram.ConfirmStoryView": "Предупреждать перед просмотром историй",
    "WinterGram.Custom": "Свой...",
    "WinterGram.CustomFont": "Свой шрифт",
    "WinterGram.Default": "По умолчанию",
    "WinterGram.Disabled": "Отключено",
    "WinterGram.DefaultReaction": "Реакция по умолчанию",
    "WinterGram.DefaultRealDevice": "Сбросить (реальное устройство)",
    "WinterGram.DeletedAndEditedMessagesAreKeptLocallyOnThisDeviceOnly": "Удалённые и изменённые сообщения хранятся только на этом устройстве.",
    "WinterGram.Desktop": "Десктоп",
    "WinterGram.DeletedMark": "Метка удаления",
    "WinterGram.NFTGift": "NFT",
    "WinterGram.RegularGift": "Обычный подарок",
    "WinterGram.DimDeletedMessages": "Затемнять удалённые сообщения",
    "WinterGram.ShowDeletionTime": "Показывать время удаления",
    "WinterGram.TopBanner": "Верхний баннер",
    "WinterGram.Solid": "Сплошной",
    "WinterGram.Glass": "Стекло",
    "WinterGram.Gradient": "Градиент",
    "WinterGram.Outline": "Контур",
    "WinterGram.DisableAds": "Отключить рекламу",
    "WinterGram.DisableOpenLinkWarning": "Без предупреждения о ссылках",
    "WinterGram.DoNotChange": "Не изменять",
    "WinterGram.EmptyNoPasscode": "Пусто = без пароля",
    "WinterGram.EnterNFTLinkEGHttpsTMeNftSlug": "Введите ссылку на NFT (напр. https://t.me/nft/slug)",
    "WinterGram.EnterPasscode": "Введите пароль",
    "WinterGram.Everything": "Всё",
    "WinterGram.FEATURES": "ФУНКЦИИ",
    "WinterGram.Features": "Функции",
    "WinterGram.ForwardWithoutAuthor": "Пересылка без автора",
    "WinterGram.GHOSTMODE": "РЕЖИМ ПРИЗРАКА",
    "WinterGram.GhostMode": "Режим призрака",
    "WinterGram.GiftAddedVisuallyToProfile": "Подарок добавлен визуально в профиль",
    "WinterGram.HIDDENARCHIVE": "СКРЫТЫЙ АРХИВ",
    "WinterGram.HISTORY": "ИСТОРИЯ",
    "WinterGram.Hidden": "Скрыто",
    "WinterGram.HiddenArchive": "Скрытый архив",
    "WinterGram.HideEditedMark": "Скрывать метку «изменено»",
    "WinterGram.HideFromStashedPeers": "Скрывать от скрытых чатов",
    "WinterGram.HidePremiumStatuses": "Скрыть Premium-статусы",
    "WinterGram.HideStories": "Скрыть истории",
    "WinterGram.History": "История",
    "WinterGram.INFORMATION": "ИНФОРМАЦИЯ",
    "WinterGram.IconPack": "Пак иконок",
    "WinterGram.InGhostMode": "В режиме призрака",
    "WinterGram.IncreaseWebViewHeight": "Увеличить высоту WebView",
    "WinterGram.Information": "Информация",
    "WinterGram.InfoFooter": "WinterGram · независимый iOS-клиент · GPLv2 © reekeer\n\nWntGram Beta · v1.0.0",
    "WinterGram.LocalPremium": "Локальный Premium",
    "WinterGram.LocalPremiumUnlocksPremiumOnlyUIOnThisDeviceItDoesNotGrantServerSidePremium": "Локальный Premium открывает Premium-интерфейс на этом устройстве, но не даёт серверный Premium.",
    "WinterGram.MessageTranslation": "Перевод сообщений",
    "WinterGram.Messages": "Сообщения",
    "WinterGram.MonospaceFont": "Моноширинный шрифт",
    "WinterGram.MuteNotifications": "Без уведомлений",
    "WinterGram.Never": "Никогда",
    "WinterGram.None": "Нет",
    "WinterGram.Off": "Выкл.",
    "WinterGram.OnlineTracker": "Трекер онлайна",
    "WinterGram.OnlyAddedEmojiStickers": "Только добавленные эмодзи и стикеры",
    "WinterGram.PrivacyFirstMessagingClient": "Приватный мессенджер",
    "WinterGram.ProfileName": "Имя профиля",
    "WinterGram.Plugins": "Плагины",
    "WinterGram.Restart": "Рестарт",
    "WinterGram.RestartRequired": "Нужен рестарт",
    "WinterGram.Round": "Круг",
    "WinterGram.Rounded": "Скруглённый",
    "WinterGram.SPOOFING": "ПОДМЕНА",
    "WinterGram.SPYMODE": "РЕЖИМ ШПИОНА",
    "WinterGram.SpyMode": "Режим шпиона",
    "WinterGram.SaveCurrentAsProfile": "Сохранить как профиль +",
    "WinterGram.SaveDeletedFromBots": "Сохранять удалённые от ботов",
    "WinterGram.SaveDeletedMessages": "Сохранять удалённые сообщения",
    "WinterGram.SaveEditHistory": "Сохранять историю правок",
    "WinterGram.SendWithoutSound": "Отправлять без звука",
    "WinterGram.ShowMessageSeconds": "Секунды в сообщениях",
    "WinterGram.ShowPeerID": "Показывать ID",
    "WinterGram.ShowRegistrationDate": "Показывать дату регистрации",
    "WinterGram.SingleCornerRadius": "Одиночное скругление",
    "WinterGram.SomeSettingsWillTakeEffectAfterRestart": "Некоторые настройки вступят в силу после перезапуска.",
    "WinterGram.SpoofAppVersion": "Версия приложения",
    "WinterGram.SpoofDeviceModel": "Модель устройства",
    "WinterGram.SpoofTheDeviceModelAppVersionAndWebViewPlatformReportedToTelegramAndMiniAppsAPIIDHashUseYourOwnCredentialsFromMyTelegramOrgChangingThemRequiresReLogin": "Подменяет модель устройства, версию приложения и платформу WebView, которые сообщаются Telegram и мини-приложениям. API ID/Hash — это ваши данные с my.telegram.org; их изменение требует повторного входа.",
    "WinterGram.Spoofing": "Подмена",
    "WinterGram.Square": "Квадрат",
    "WinterGram.Squircle": "Сквиркл",
    "WinterGram.StashPasscode": "Пароль скрытых",
    "WinterGram.StashedChats": "Скрытые чаты",
    "WinterGram.StashedChatsAreHiddenFromTheMainListAndAccessibleOnlyHere": "Скрытые чаты не показываются в основном списке и доступны только здесь.",
    "WinterGram.HiddenArchiveInfo": "Чаты в скрытом архиве не показываются в списке чатов. Зажмите чат в списке, чтобы скрыть или вернуть его.",
    "WinterGram.HiddenArchiveEmpty": "Скрытый архив пуст.",
    "WinterGram.Stories": "Истории",
    "WinterGram.System": "Системный",
    "WinterGram.Templates": "Шаблоны",
    "WinterGram.TrackOnlineStatus": "Отслеживать статус «в сети»",
    "WinterGram.TranslationProvider": "Сервис перевода",
    "WinterGram.TransparencyBlurAndTintCanBeFineTunedPerSurfaceTurnLiquidGlassOffForTheStandardOpaqueLook": "Прозрачность, блюр и оттенок настраиваются по каждой поверхности. Выключите Liquid Glass для обычного непрозрачного вида.",
    "WinterGram.UseDefaultTelegramBranding": "Стандартный бренд",
    "WinterGram.UseScheduledMessages": "Отложенная отправка",
    "WinterGram.Version": "Версия",
    "WinterGram.VisualGift": "Визуал. подарок",
    "WinterGram.WebViewPlatform": "Платформа WebView",
    "WinterGram.WhenGhostModeIsOnWinterGramStopsSendingReadReceiptsOnlineStatusAndTypingActivity": "Когда режим призрака включён, WinterGram не отправляет отметки о прочтении, статус «в сети» и набор текста.",
    "WinterGram.WinterGramWntIsAPrivacyFocusedMessagingClientForIPhoneANativePortOfTheAyuGramExperienceItAddsGhostModeSavedDeletedMessagesAndEditHistoryAHiddenArchiveLocalPremiumAdRemovalDeepCustomizationAndLiquidGlass": "Модифицированный клиент Telegram.",
    "WinterGram.Yandex": "Яндекс",
    "WinterGram.DeletedMessages.Title": "Удалённые сообщения",
    "WinterGram.DeletedMessages.Total": "Всего",
    "WinterGram.DeletedMessages.SelectTypes": "Выберите типы",
    "WinterGram.DeletedMessages.DeleteSelected": "Удалить выбранное",
    "WinterGram.DeletedMessages.ConfirmDelete": "Удалить выбранные сохранённые удалённые сообщения? Это нельзя отменить.",
    "WinterGram.DeletedMessages.Deleted": "Освобождено %@",
    "WinterGram.DeletedMessages.Text": "Сообщения",
    "WinterGram.DeletedMessages.Photos": "Фото",
    "WinterGram.DeletedMessages.Videos": "Видео",
    "WinterGram.DeletedMessages.Voice": "Голосовые",
    "WinterGram.DeletedMessages.VideoMessages": "Кружочки",
    "WinterGram.DeletedMessages.Music": "Музыка",
    "WinterGram.DeletedMessages.Stickers": "Стикеры",
    "WinterGram.DeletedMessages.Other": "Другое",
    "WinterGram.DeletedMessages.TopChats": "Топ чатов",
    "WinterGram.DeleteSelected": "Удалить выбранное",
]

/// Returns WinterGram's fork-string translations for the given base language code, to be merged
/// into the active `PresentationStrings` component dictionaries. Empty when the language has no
/// bundled translation (English is handled by the generated `en.lproj` fallback).
public func winterGramSeedStrings(languageCode: String) -> [String: String] {
    if languageCode.hasPrefix("ru") {
        return winterGramRussianSeed
    }
    return [:]
}

/// Localizes a WinterGram option/section label chosen at runtime (dropdown selections, section
/// titles) by routing the known English value to its generated accessor. Unknown values — user
/// input such as custom fonts, reactions or spoofed identifiers — are returned unchanged.
public func wntOption(_ english: String, _ strings: PresentationStrings) -> String {
    switch english {
    case "Off": return strings.WinterGram_Off
    case "Solid": return strings.WinterGram_Solid
    case "Glass": return strings.WinterGram_Glass
    case "Gradient": return strings.WinterGram_Gradient
    case "Outline": return strings.WinterGram_Outline
    case "Messages": return strings.WinterGram_Messages
    case "Stories": return strings.WinterGram_Stories
    case "Everything": return strings.WinterGram_Everything
    case "Disabled": return strings.WinterGram_Disabled
    case "Never": return strings.WinterGram_Never
    case "In Ghost Mode": return strings.WinterGram_InGhostMode
    case "Always": return strings.WinterGram_Always
    case "Hidden": return strings.WinterGram_Hidden
    case "Telegram API": return strings.WinterGram_TelegramAPI
    case "Bot API": return strings.WinterGram_BotAPI
    case "Telegram": return strings.WinterGram_Telegram
    case "Google": return strings.WinterGram_Google
    case "Yandex": return strings.WinterGram_Yandex
    case "System": return strings.WinterGram_System
    case "Automatic": return strings.WinterGram_Automatic
    case "iOS": return strings.WinterGram_IOS
    case "Android": return strings.WinterGram_Android
    case "macOS": return strings.WinterGram_MacOS
    case "Desktop": return strings.WinterGram_Desktop
    case "WinterGram": return strings.WinterGram_WinterGram
    case "Ayu": return strings.WinterGram_AyuGram
    case "exteraGram": return strings.WinterGram_ExteraGram
    case "Round": return strings.WinterGram_Round
    case "Squircle": return strings.WinterGram_Squircle
    case "Rounded": return strings.WinterGram_Rounded
    case "Square": return strings.WinterGram_Square
    case "Ghost Mode": return strings.WinterGram_GhostMode
    case "History": return strings.WinterGram_History
    case "Hidden Archive": return strings.WinterGram_HiddenArchive
    case "Features": return strings.WinterGram_Features
    case "Chat": return strings.WinterGram_Chat
    case "Appearance": return strings.WinterGram_Appearance
    case "Liquid Glass": return strings.WinterGram_LiquidGlass
    case "Spoofing": return strings.WinterGram_Spoofing
    case "Information": return strings.WinterGram_Information
    case "None": return strings.WinterGram_None
    case "Releases": return strings.WinterGram_Releases
    case "Channel": return strings.WinterGram_Channel
    case "Beta": return strings.WinterGram_Beta
    case "Other": return strings.WinterGram_Other
    case "Core": return strings.WinterGram_Core
    case "Core Menu": return strings.WinterGram_CoreMenu
    case "Default": return strings.WinterGram_Default
    case "Do Not Change": return strings.WinterGram_DoNotChange
    case "Hide From Stashed Peers": return strings.WinterGram_HideFromStashedPeers
    case "Add Template": return strings.WinterGram_AddTemplate
    case "Plugins": return strings.WinterGram_Plugins
    default: return english
    }
}
