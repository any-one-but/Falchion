import AppKit
import Foundation

enum FileConflictPolicy: String, CaseIterable, Codable, Identifiable, Sendable {
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

enum FalchionThemeOption: String, CaseIterable, Codable, Identifiable, Sendable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
}

enum ThumbnailFitMode: String, CaseIterable, Codable, Identifiable, Sendable {
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

enum OnlineLoadMode: String, CaseIterable, Codable, Identifiable, Sendable {
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

enum KeybindAction: String, CaseIterable, Codable, Identifiable, Sendable {
    case nextMedia
    case previousMedia
    case openViewer
    case closeOverlay
    case nextDirectory
    case previousDirectory
    case enterDirectory
    case exitDirectory
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
        case .enterDirectory:
            return "Enter Folder"
        case .exitDirectory:
            return "Parent Folder"
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
        case .enterDirectory:
            return "Enter the selected folder in the sidebar."
        case .exitDirectory:
            return "Go up to the parent folder in the sidebar."
        case .toggleMenu:
            return "Open the options window."
        case .refresh:
            return "Re-scan all selected root folders."
        }
    }
}

struct KeyToken: RawRepresentable, Codable, Hashable, Identifiable, Sendable {
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

struct KeyBinding: Codable, Hashable, Identifiable, Sendable {
    let action: KeybindAction
    var token: KeyToken?

    var id: String { action.rawValue }
}

struct SavedResponseTemplate: Codable, Hashable, Identifiable, Sendable {
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

struct AppPreferences: Codable, Sendable {
    var theme: FalchionThemeOption = .system
    var showOptionDescriptions: Bool = true
    var showKeybindDescriptions: Bool = true

    var startAtLastRoot: Bool = true
    var reopenLastSelection: Bool = true
    var autoRefreshOnLaunch: Bool = true
    var confirmDeleteActions: Bool = true

    var compactSidebarRows: Bool = false
    var showPathsInSidebar: Bool = true
    var showMetadataBadges: Bool = true

    var autoplayVideosInPreview: Bool = true
    var muteVideosByDefault: Bool = true
    var loopVideosByDefault: Bool = true
    var preloadNeighborMedia: Bool = false
    var playbackStepSeconds: Int = 10

    var thumbnailFitMode: ThumbnailFitMode = .cover
    var previewCardSizeRaw: String = "small"
    var thumbnailPreloadCount: Int = 16
    var smoothImageTransitions: Bool = true

    var showFileExtensions: Bool = true
    var normalizeRenamedFilenames: Bool = false
    var preserveFilenameCase: Bool = true
    var defaultRenameTemplate: String = ""

    var onlineLoadMode: OnlineLoadMode = .asNeeded
    var listOnlineFoldersFirst: Bool = false

    var defaultConflictPolicy: FileConflictPolicy = .keepBoth
    var keyBindings: [KeyBinding] = [
        KeyBinding(action: .nextMedia, token: .rightArrow),
        KeyBinding(action: .previousMedia, token: .leftArrow),
        KeyBinding(action: .openViewer, token: .space),
        KeyBinding(action: .closeOverlay, token: .escape),
        KeyBinding(action: .nextDirectory, token: KeyToken(rawValue: "s")),
        KeyBinding(action: .previousDirectory, token: KeyToken(rawValue: "w")),
        KeyBinding(action: .enterDirectory, token: KeyToken(rawValue: "d")),
        KeyBinding(action: .exitDirectory, token: KeyToken(rawValue: "a")),
        KeyBinding(action: .toggleMenu, token: KeyToken(rawValue: "m")),
        KeyBinding(action: .refresh, token: KeyToken(rawValue: "r"))
    ]
    var savedResponses: [SavedResponseTemplate] = []

    // Legacy Electron options (kept in same key format for parity/persistence).
    var dirSortMode: String = "name"
    var folderScoreDisplay: String = "no-arrows"
    var onlineFeaturesEnabled: Bool = true
    var showFolderItemCount: Bool = true
    var showFolderSize: Bool = true
    var showDirFileTypeLabel: Bool = true
    var defaultFolderBehavior: String = "slide"
    var randomActionMode: String = "firstFileJump"
    var banicOpenWindow: Bool = true
    var showHiddenFolder: Bool = false
    var showUntaggedFolder: Bool = false
    var showTrashFolder: Bool = true

    var colorScheme: String = "classic"
    var hideOptionDescriptions: Bool = false
    var hideKeybindDescriptions: Bool = false
    var retroMode: Bool = false
    var mediaFilter: String = "off"
    var crtScanlinesEnabled: Bool = false
    var crtPixelateEnabled: Bool = false
    var crtPixelateResolution: Double = 4.0
    var crtGrainEnabled: Bool = false
    var crtGrainAmount: Double = 0.06
    var vhsOverlayEnabled: Bool = false
    var filmCornerOverlayEnabled: Bool = false
    var vhsBlurAmount: Double = 1.2
    var vhsChromaAmount: Double = 1.2
    var animatedMediaFilters: Bool = true

    var videoPreview: String = "muted"
    var videoGallery: String = "muted"
    var videoSkipStep: String = "10"
    var videoEndBehavior: String = "loop"
    var preloadNextMode: String = "off"
    var slideshowDefault: String = "cycle"

    var showPreviewFileTypeLabel: Bool = true
    var showPreviewFileName: Bool = true
    var showPreviewFolderItemCount: Bool = true
    var previewThumbFiltersEnabled: Bool = false
    var previewThumbFit: String = "cover"
    var imageThumbSize: String = "small"
    var videoThumbSize: String = "small"
    var mediaThumbUiSize: String = "small"
    var folderPreviewSize: String = "small"
    var previewMode: String = "grid"

    var hideFileExtensions: Bool = false
    var hideUnderscoresInNames: Bool = true
    var hideBeforeLastDashInFileNames: Bool = true
    var hideAfterFirstUnderscoreInFileNames: Bool = true
    var forceTitleCaps: Bool = true

    nonisolated static let `default` = AppPreferences()

    init() {}

    init(from decoder: Decoder) throws {
        self = AppPreferences.default
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let rawTheme = try container.decodeIfPresent(String.self, forKey: .theme) {
            theme = Self.theme(fromLegacyRawValue: rawTheme)
        } else if let decodedTheme = try container.decodeIfPresent(FalchionThemeOption.self, forKey: .theme) {
            theme = decodedTheme
        }

        showOptionDescriptions = try container.decodeIfPresent(Bool.self, forKey: .showOptionDescriptions) ?? !hideOptionDescriptions
        showKeybindDescriptions = try container.decodeIfPresent(Bool.self, forKey: .showKeybindDescriptions) ?? !hideKeybindDescriptions

        startAtLastRoot = try container.decodeIfPresent(Bool.self, forKey: .startAtLastRoot) ?? startAtLastRoot
        reopenLastSelection = try container.decodeIfPresent(Bool.self, forKey: .reopenLastSelection) ?? reopenLastSelection
        autoRefreshOnLaunch = try container.decodeIfPresent(Bool.self, forKey: .autoRefreshOnLaunch) ?? autoRefreshOnLaunch
        confirmDeleteActions = try container.decodeIfPresent(Bool.self, forKey: .confirmDeleteActions) ?? confirmDeleteActions

        compactSidebarRows = try container.decodeIfPresent(Bool.self, forKey: .compactSidebarRows) ?? compactSidebarRows
        showPathsInSidebar = try container.decodeIfPresent(Bool.self, forKey: .showPathsInSidebar) ?? showPathsInSidebar
        showMetadataBadges = try container.decodeIfPresent(Bool.self, forKey: .showMetadataBadges) ?? showMetadataBadges

        autoplayVideosInPreview = try container.decodeIfPresent(Bool.self, forKey: .autoplayVideosInPreview) ?? (videoPreview != "off")
        muteVideosByDefault = try container.decodeIfPresent(Bool.self, forKey: .muteVideosByDefault) ?? (videoPreview == "muted")
        loopVideosByDefault = try container.decodeIfPresent(Bool.self, forKey: .loopVideosByDefault) ?? (videoEndBehavior == "loop")
        preloadNeighborMedia = try container.decodeIfPresent(Bool.self, forKey: .preloadNeighborMedia) ?? (preloadNextMode != "off")
        playbackStepSeconds = try container.decodeIfPresent(Int.self, forKey: .playbackStepSeconds) ?? Int(videoSkipStep) ?? playbackStepSeconds

        if let mode = try container.decodeIfPresent(ThumbnailFitMode.self, forKey: .thumbnailFitMode) {
            thumbnailFitMode = mode
        }
        previewCardSizeRaw = try container.decodeIfPresent(String.self, forKey: .previewCardSizeRaw) ?? mediaThumbUiSize
        thumbnailPreloadCount = try container.decodeIfPresent(Int.self, forKey: .thumbnailPreloadCount) ?? thumbnailPreloadCount
        smoothImageTransitions = try container.decodeIfPresent(Bool.self, forKey: .smoothImageTransitions) ?? smoothImageTransitions

        showFileExtensions = try container.decodeIfPresent(Bool.self, forKey: .showFileExtensions) ?? !hideFileExtensions
        normalizeRenamedFilenames = try container.decodeIfPresent(Bool.self, forKey: .normalizeRenamedFilenames) ?? normalizeRenamedFilenames
        preserveFilenameCase = try container.decodeIfPresent(Bool.self, forKey: .preserveFilenameCase) ?? preserveFilenameCase
        defaultRenameTemplate = try container.decodeIfPresent(String.self, forKey: .defaultRenameTemplate) ?? defaultRenameTemplate

        onlineLoadMode = try container.decodeIfPresent(OnlineLoadMode.self, forKey: .onlineLoadMode) ?? onlineLoadMode
        listOnlineFoldersFirst = try container.decodeIfPresent(Bool.self, forKey: .listOnlineFoldersFirst) ?? listOnlineFoldersFirst

        defaultConflictPolicy = try container.decodeIfPresent(FileConflictPolicy.self, forKey: .defaultConflictPolicy) ?? defaultConflictPolicy
        keyBindings = try container.decodeIfPresent([KeyBinding].self, forKey: .keyBindings) ?? keyBindings
        savedResponses = try container.decodeIfPresent([SavedResponseTemplate].self, forKey: .savedResponses) ?? savedResponses

        dirSortMode = try container.decodeIfPresent(String.self, forKey: .dirSortMode) ?? dirSortMode
        folderScoreDisplay = try container.decodeIfPresent(String.self, forKey: .folderScoreDisplay) ?? folderScoreDisplay
        onlineFeaturesEnabled = try container.decodeIfPresent(Bool.self, forKey: .onlineFeaturesEnabled) ?? onlineFeaturesEnabled
        showFolderItemCount = try container.decodeIfPresent(Bool.self, forKey: .showFolderItemCount) ?? showFolderItemCount
        showFolderSize = try container.decodeIfPresent(Bool.self, forKey: .showFolderSize) ?? showFolderSize
        showDirFileTypeLabel = try container.decodeIfPresent(Bool.self, forKey: .showDirFileTypeLabel) ?? showDirFileTypeLabel
        defaultFolderBehavior = try container.decodeIfPresent(String.self, forKey: .defaultFolderBehavior) ?? defaultFolderBehavior
        randomActionMode = try container.decodeIfPresent(String.self, forKey: .randomActionMode) ?? randomActionMode
        banicOpenWindow = try container.decodeIfPresent(Bool.self, forKey: .banicOpenWindow) ?? banicOpenWindow
        showHiddenFolder = try container.decodeIfPresent(Bool.self, forKey: .showHiddenFolder) ?? showHiddenFolder
        showUntaggedFolder = try container.decodeIfPresent(Bool.self, forKey: .showUntaggedFolder) ?? showUntaggedFolder
        showTrashFolder = try container.decodeIfPresent(Bool.self, forKey: .showTrashFolder) ?? showTrashFolder

        colorScheme = try container.decodeIfPresent(String.self, forKey: .colorScheme) ?? colorScheme
        hideOptionDescriptions = try container.decodeIfPresent(Bool.self, forKey: .hideOptionDescriptions) ?? hideOptionDescriptions
        hideKeybindDescriptions = try container.decodeIfPresent(Bool.self, forKey: .hideKeybindDescriptions) ?? hideKeybindDescriptions
        retroMode = try container.decodeIfPresent(Bool.self, forKey: .retroMode) ?? retroMode
        mediaFilter = try container.decodeIfPresent(String.self, forKey: .mediaFilter) ?? mediaFilter
        crtScanlinesEnabled = try container.decodeIfPresent(Bool.self, forKey: .crtScanlinesEnabled) ?? crtScanlinesEnabled
        crtPixelateEnabled = try container.decodeIfPresent(Bool.self, forKey: .crtPixelateEnabled) ?? crtPixelateEnabled
        crtPixelateResolution = try container.decodeIfPresent(Double.self, forKey: .crtPixelateResolution) ?? crtPixelateResolution
        crtGrainEnabled = try container.decodeIfPresent(Bool.self, forKey: .crtGrainEnabled) ?? crtGrainEnabled
        crtGrainAmount = try container.decodeIfPresent(Double.self, forKey: .crtGrainAmount) ?? crtGrainAmount
        vhsOverlayEnabled = try container.decodeIfPresent(Bool.self, forKey: .vhsOverlayEnabled) ?? vhsOverlayEnabled
        filmCornerOverlayEnabled = try container.decodeIfPresent(Bool.self, forKey: .filmCornerOverlayEnabled) ?? filmCornerOverlayEnabled
        vhsBlurAmount = try container.decodeIfPresent(Double.self, forKey: .vhsBlurAmount) ?? vhsBlurAmount
        vhsChromaAmount = try container.decodeIfPresent(Double.self, forKey: .vhsChromaAmount) ?? vhsChromaAmount
        animatedMediaFilters = try container.decodeIfPresent(Bool.self, forKey: .animatedMediaFilters) ?? animatedMediaFilters

        videoPreview = try container.decodeIfPresent(String.self, forKey: .videoPreview) ?? videoPreview
        videoGallery = try container.decodeIfPresent(String.self, forKey: .videoGallery) ?? videoGallery
        videoSkipStep = try container.decodeIfPresent(String.self, forKey: .videoSkipStep) ?? videoSkipStep
        videoEndBehavior = try container.decodeIfPresent(String.self, forKey: .videoEndBehavior) ?? videoEndBehavior
        preloadNextMode = try container.decodeIfPresent(String.self, forKey: .preloadNextMode) ?? preloadNextMode
        slideshowDefault = try container.decodeIfPresent(String.self, forKey: .slideshowDefault) ?? slideshowDefault

        showPreviewFileTypeLabel = try container.decodeIfPresent(Bool.self, forKey: .showPreviewFileTypeLabel) ?? showPreviewFileTypeLabel
        showPreviewFileName = try container.decodeIfPresent(Bool.self, forKey: .showPreviewFileName) ?? showPreviewFileName
        showPreviewFolderItemCount = try container.decodeIfPresent(Bool.self, forKey: .showPreviewFolderItemCount) ?? showPreviewFolderItemCount
        previewThumbFiltersEnabled = try container.decodeIfPresent(Bool.self, forKey: .previewThumbFiltersEnabled) ?? previewThumbFiltersEnabled
        previewThumbFit = try container.decodeIfPresent(String.self, forKey: .previewThumbFit) ?? previewThumbFit
        imageThumbSize = try container.decodeIfPresent(String.self, forKey: .imageThumbSize) ?? imageThumbSize
        videoThumbSize = try container.decodeIfPresent(String.self, forKey: .videoThumbSize) ?? videoThumbSize
        mediaThumbUiSize = try container.decodeIfPresent(String.self, forKey: .mediaThumbUiSize) ?? mediaThumbUiSize
        folderPreviewSize = try container.decodeIfPresent(String.self, forKey: .folderPreviewSize) ?? folderPreviewSize
        previewMode = try container.decodeIfPresent(String.self, forKey: .previewMode) ?? previewMode

        hideFileExtensions = try container.decodeIfPresent(Bool.self, forKey: .hideFileExtensions) ?? !showFileExtensions
        hideUnderscoresInNames = try container.decodeIfPresent(Bool.self, forKey: .hideUnderscoresInNames) ?? hideUnderscoresInNames
        hideBeforeLastDashInFileNames = try container.decodeIfPresent(Bool.self, forKey: .hideBeforeLastDashInFileNames) ?? hideBeforeLastDashInFileNames
        hideAfterFirstUnderscoreInFileNames = try container.decodeIfPresent(Bool.self, forKey: .hideAfterFirstUnderscoreInFileNames) ?? hideAfterFirstUnderscoreInFileNames
        forceTitleCaps = try container.decodeIfPresent(Bool.self, forKey: .forceTitleCaps) ?? forceTitleCaps

        showOptionDescriptions = !hideOptionDescriptions
        showKeybindDescriptions = !hideKeybindDescriptions
        showFileExtensions = !hideFileExtensions
        thumbnailFitMode = previewThumbFit == "contain" ? .contain : .cover
        previewCardSizeRaw = mediaThumbUiSize
        playbackStepSeconds = Int(videoSkipStep) ?? playbackStepSeconds
        preloadNeighborMedia = preloadNextMode != "off"
    }

    enum CodingKeys: String, CodingKey {
        case theme
        case showOptionDescriptions
        case showKeybindDescriptions
        case startAtLastRoot
        case reopenLastSelection
        case autoRefreshOnLaunch
        case confirmDeleteActions
        case compactSidebarRows
        case showPathsInSidebar
        case showMetadataBadges
        case autoplayVideosInPreview
        case muteVideosByDefault
        case loopVideosByDefault
        case preloadNeighborMedia
        case playbackStepSeconds
        case thumbnailFitMode
        case previewCardSizeRaw
        case thumbnailPreloadCount
        case smoothImageTransitions
        case showFileExtensions
        case normalizeRenamedFilenames
        case preserveFilenameCase
        case defaultRenameTemplate
        case onlineLoadMode
        case listOnlineFoldersFirst
        case defaultConflictPolicy
        case keyBindings
        case savedResponses

        case dirSortMode
        case folderScoreDisplay
        case onlineFeaturesEnabled
        case showFolderItemCount
        case showFolderSize
        case showDirFileTypeLabel
        case defaultFolderBehavior
        case randomActionMode
        case banicOpenWindow
        case showHiddenFolder
        case showUntaggedFolder
        case showTrashFolder
        case colorScheme
        case hideOptionDescriptions
        case hideKeybindDescriptions
        case retroMode
        case mediaFilter
        case crtScanlinesEnabled
        case crtPixelateEnabled
        case crtPixelateResolution
        case crtGrainEnabled
        case crtGrainAmount
        case vhsOverlayEnabled
        case filmCornerOverlayEnabled
        case vhsBlurAmount
        case vhsChromaAmount
        case animatedMediaFilters
        case videoPreview
        case videoGallery
        case videoSkipStep
        case videoEndBehavior
        case preloadNextMode
        case slideshowDefault
        case showPreviewFileTypeLabel
        case showPreviewFileName
        case showPreviewFolderItemCount
        case previewThumbFiltersEnabled
        case previewThumbFit
        case imageThumbSize
        case videoThumbSize
        case mediaThumbUiSize
        case folderPreviewSize
        case previewMode
        case hideFileExtensions
        case hideUnderscoresInNames
        case hideBeforeLastDashInFileNames
        case hideAfterFirstUnderscoreInFileNames
        case forceTitleCaps
    }

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

    private static func theme(fromLegacyRawValue rawValue: String) -> FalchionThemeOption {
        if let current = FalchionThemeOption(rawValue: rawValue) {
            return current
        }

        switch rawValue {
        case "light", "retro90s":
            return .light
        case "classic", "superdark", "synthwave", "verdant", "azure", "ember", "amber", "retro90s-dark":
            return .dark
        default:
            return .system
        }
    }
}
