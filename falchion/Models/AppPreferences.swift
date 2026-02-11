import AppKit
import Foundation

enum FileConflictPolicy: String, CaseIterable, Codable, Identifiable {
    case abort
    case keepBoth
    case replace

    var id: String { rawValue }

    var title: String {
        switch self {
        case .abort:
            return "Abort"
        case .keepBoth:
            return "Keep Both"
        case .replace:
            return "Replace"
        }
    }
}

enum FalchionThemeOption: String, CaseIterable, Codable, Identifiable {
    case classic
    case light
    case superdark
    case synthwave
    case verdant
    case azure
    case ember
    case amber
    case retro90s
    case retro90sDark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic:
            return "Classic Dark"
        case .light:
            return "Light"
        case .superdark:
            return "OLED Dark"
        case .synthwave:
            return "Synthwave"
        case .verdant:
            return "Verdant"
        case .azure:
            return "Azure"
        case .ember:
            return "Ember"
        case .amber:
            return "Amber"
        case .retro90s:
            return "Retro 90s"
        case .retro90sDark:
            return "Retro 90s Dark"
        }
    }
}

enum ThumbnailFitMode: String, CaseIterable, Codable, Identifiable {
    case cover
    case contain

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cover:
            return "Crop to Fill"
        case .contain:
            return "Fit Inside"
        }
    }
}

enum OnlineLoadMode: String, CaseIterable, Codable, Identifiable {
    case asNeeded
    case preload

    var id: String { rawValue }

    var title: String {
        switch self {
        case .asNeeded:
            return "As Needed"
        case .preload:
            return "Preload"
        }
    }
}

enum KeybindAction: String, CaseIterable, Codable, Identifiable {
    case nextMedia
    case previousMedia
    case openViewer
    case closeOverlay
    case nextDirectory
    case previousDirectory
    case toggleMenu
    case refresh

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nextMedia:
            return "Next Media"
        case .previousMedia:
            return "Previous Media"
        case .openViewer:
            return "Open Viewer"
        case .closeOverlay:
            return "Close Overlay"
        case .nextDirectory:
            return "Next Folder"
        case .previousDirectory:
            return "Previous Folder"
        case .toggleMenu:
            return "Toggle Menu"
        case .refresh:
            return "Refresh Library"
        }
    }

    var hint: String {
        switch self {
        case .nextMedia:
            return "Move selection to the next visible media item."
        case .previousMedia:
            return "Move selection to the previous visible media item."
        case .openViewer:
            return "Open the fullscreen viewer for the selected media item."
        case .closeOverlay:
            return "Close the viewer or menu overlay."
        case .nextDirectory:
            return "Jump to the next visible folder."
        case .previousDirectory:
            return "Jump to the previous visible folder."
        case .toggleMenu:
            return "Open or close the settings/menu overlay."
        case .refresh:
            return "Re-scan all selected root folders."
        }
    }
}

struct KeyToken: RawRepresentable, Codable, Hashable, Identifiable {
    var rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawValue = try container.decode(String.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    var id: String { rawValue }

    static let leftArrow = KeyToken(rawValue: "leftArrow")
    static let rightArrow = KeyToken(rawValue: "rightArrow")
    static let upArrow = KeyToken(rawValue: "upArrow")
    static let downArrow = KeyToken(rawValue: "downArrow")
    static let escape = KeyToken(rawValue: "escape")
    static let `return` = KeyToken(rawValue: "return")
    static let space = KeyToken(rawValue: "space")
    static let leftBracket = KeyToken(rawValue: "[")
    static let rightBracket = KeyToken(rawValue: "]")

    static var allSelectable: [KeyToken] {
        var out: [KeyToken] = [
            .leftArrow,
            .rightArrow,
            .upArrow,
            .downArrow,
            .escape,
            .return,
            .space,
            .leftBracket,
            .rightBracket
        ]

        for scalar in UnicodeScalar("a").value...UnicodeScalar("z").value {
            if let scalarValue = UnicodeScalar(scalar) {
                out.append(KeyToken(rawValue: String(Character(scalarValue))))
            }
        }

        for digit in 0...9 {
            out.append(KeyToken(rawValue: String(digit)))
        }

        return out
    }

    var title: String {
        switch rawValue {
        case KeyToken.leftArrow.rawValue:
            return "Left Arrow"
        case KeyToken.rightArrow.rawValue:
            return "Right Arrow"
        case KeyToken.upArrow.rawValue:
            return "Up Arrow"
        case KeyToken.downArrow.rawValue:
            return "Down Arrow"
        case KeyToken.escape.rawValue:
            return "Escape"
        case KeyToken.return.rawValue:
            return "Return"
        case KeyToken.space.rawValue:
            return "Space"
        case KeyToken.leftBracket.rawValue:
            return "["
        case KeyToken.rightBracket.rawValue:
            return "]"
        default:
            return rawValue.uppercased()
        }
    }

    static func from(event: NSEvent) -> KeyToken? {
        switch event.keyCode {
        case 123:
            return .leftArrow
        case 124:
            return .rightArrow
        case 125:
            return .downArrow
        case 126:
            return .upArrow
        case 53:
            return .escape
        case 36:
            return .return
        case 49:
            return .space
        default:
            break
        }

        guard let chars = event.charactersIgnoringModifiers?.lowercased(), !chars.isEmpty else {
            return nil
        }

        if chars == "[" {
            return .leftBracket
        }

        if chars == "]" {
            return .rightBracket
        }

        if chars.count == 1 {
            return KeyToken(rawValue: chars)
        }

        return nil
    }
}

struct KeyBinding: Codable, Hashable, Identifiable {
    let action: KeybindAction
    var token: KeyToken?

    var id: String { action.rawValue }
}

struct SavedResponseTemplate: Codable, Hashable, Identifiable {
    let id: UUID
    var title: String
    var body: String
    var updatedAt: Date

    init(id: UUID = UUID(), title: String, body: String, updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.body = body
        self.updatedAt = updatedAt
    }
}

struct AppPreferences: Codable {
    var theme: FalchionThemeOption
    var retroMode: Bool
    var showOptionDescriptions: Bool
    var showKeybindDescriptions: Bool
    var thumbnailFitMode: ThumbnailFitMode
    var previewCardSizeRaw: String
    var onlineLoadMode: OnlineLoadMode
    var listOnlineFoldersFirst: Bool
    var defaultConflictPolicy: FileConflictPolicy
    var keyBindings: [KeyBinding]
    var savedResponses: [SavedResponseTemplate]

    static let `default` = AppPreferences(
        theme: .classic,
        retroMode: false,
        showOptionDescriptions: true,
        showKeybindDescriptions: true,
        thumbnailFitMode: .cover,
        previewCardSizeRaw: "medium",
        onlineLoadMode: .asNeeded,
        listOnlineFoldersFirst: false,
        defaultConflictPolicy: .keepBoth,
        keyBindings: [
            KeyBinding(action: .nextMedia, token: .rightArrow),
            KeyBinding(action: .previousMedia, token: .leftArrow),
            KeyBinding(action: .openViewer, token: .space),
            KeyBinding(action: .closeOverlay, token: .escape),
            KeyBinding(action: .nextDirectory, token: .rightBracket),
            KeyBinding(action: .previousDirectory, token: .leftBracket),
            KeyBinding(action: .toggleMenu, token: KeyToken(rawValue: "m")),
            KeyBinding(action: .refresh, token: KeyToken(rawValue: "r"))
        ],
        savedResponses: []
    )

    func token(for action: KeybindAction) -> KeyToken? {
        keyBindings.first(where: { $0.action == action })?.token
    }

    func action(for token: KeyToken) -> KeybindAction? {
        keyBindings.first(where: { $0.token == token })?.action
    }

    mutating func setBinding(_ token: KeyToken?, for action: KeybindAction) {
        if let collisionIndex = keyBindings.firstIndex(where: { $0.action != action && $0.token == token }) {
            keyBindings[collisionIndex].token = nil
        }

        if let index = keyBindings.firstIndex(where: { $0.action == action }) {
            keyBindings[index].token = token
        } else {
            keyBindings.append(KeyBinding(action: action, token: token))
        }

        keyBindings.sort { $0.action.rawValue < $1.action.rawValue }
    }
}
