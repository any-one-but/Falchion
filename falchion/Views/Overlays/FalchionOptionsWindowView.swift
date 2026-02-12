import Foundation
import SwiftUI

private struct LegacyOptionChoice: Identifiable {
    let value: String
    let label: String

    var id: String { value }
}

struct FalchionOptionsWindowView: View {
    @EnvironmentObject private var appState: FalchionAppState

    @State private var responseTitleDraft: String = ""
    @State private var responseBodyDraft: String = ""

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            Group {
                switch appState.menuTab {
                case .options:
                    optionsContent
                case .keybinds:
                    keybindsContent
                case .online:
                    onlineContent
                case .responses:
                    responsesContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            footer
        }
        .frame(minWidth: 860, minHeight: 560)
        .background(Color.falchionPane)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Text("Falchion Options")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.falchionTextPrimary)

            Picker("", selection: Binding(
                get: { visibleMenuTabs.contains(appState.menuTab) ? appState.menuTab : .options },
                set: { appState.menuTab = $0 }
            )) {
                ForEach(visibleMenuTabs) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 420)

            Spacer(minLength: 0)

            Text(appState.optionsStatusText)
                .font(.system(size: 11))
                .foregroundStyle(Color.falchionTextSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.falchionCardSurface)
    }

    private var optionsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Option preferences are stored automatically.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.falchionTextSecondary)

                sectionHeader("General")
                optionSelectRow(
                    "Folder sort",
                    "Sort folders by name, score, recursive size, recursive count, or non-recursive count.",
                    selection: legacyStringBinding(\.dirSortMode),
                    choices: dirSortModeChoices
                )
                optionSelectRow(
                    "Folder scores",
                    "Choose how folder scores appear in lists + previews.",
                    selection: legacyStringBinding(\.folderScoreDisplay),
                    choices: folderScoreChoices
                )
                optionToggleRow(
                    "Show online features",
                    "Toggles the Online tab, URL bar, and online profile/post folders.",
                    isOn: legacyBoolBinding(\.onlineFeaturesEnabled)
                )
                optionToggleRow(
                    "Show folder item counts",
                    "Show the number of items on folders in the directories pane.",
                    isOn: legacyBoolBinding(\.showFolderItemCount)
                )
                optionToggleRow(
                    "Show folder size",
                    "Show total folder size on folders in the directories pane.",
                    isOn: legacyBoolBinding(\.showFolderSize)
                )
                optionToggleRow(
                    "Show file type labels (directories)",
                    "Show Image/Video labels for files in the directories pane.",
                    isOn: legacyBoolBinding(\.showDirFileTypeLabel)
                )
                optionSelectRow(
                    "Folder behavior",
                    "Sets how folders behave when browsing.",
                    selection: legacyStringBinding(\.defaultFolderBehavior),
                    choices: folderBehaviorChoices
                )
                optionSelectRow(
                    "Random action behavior",
                    "Choose what the Random action key does.",
                    selection: legacyStringBinding(\.randomActionMode),
                    choices: randomActionChoices
                )
                optionToggleRow(
                    "PANIC! opens decoy window",
                    "When enabled, PANIC! opens a harmless site in a new window.",
                    isOn: legacyBoolBinding(\.banicOpenWindow)
                )
                optionToggleRow(
                    "Show Hidden Folder",
                    "Display a dedicated hidden-folder tag near the top of the directories pane when tag folders are enabled.",
                    isOn: legacyBoolBinding(\.showHiddenFolder)
                )
                optionToggleRow(
                    "Show Untagged Folder",
                    "Display a dedicated untagged-folder tag near the top of the root directories pane when tag folders are enabled.",
                    isOn: legacyBoolBinding(\.showUntaggedFolder)
                )
                optionToggleRow(
                    "Show Trash Folder",
                    "Display a dedicated trash-folder entry near the top of the root directories pane when trash has items.",
                    isOn: legacyBoolBinding(\.showTrashFolder)
                )

                sectionHeader("Appearance")
                optionSelectRow(
                    "Color scheme",
                    "Switch the overall interface palette.",
                    selection: legacyStringBinding(\.colorScheme),
                    choices: colorSchemeChoices
                )
                optionToggleRow(
                    "Hide option descriptions",
                    "Hide helper text under each option in this tab.",
                    isOn: legacyBoolBinding(\.hideOptionDescriptions)
                )
                optionToggleRow(
                    "Hide key bind descriptions",
                    "Hide helper text under each keybind action in the keybinds tab.",
                    isOn: legacyBoolBinding(\.hideKeybindDescriptions)
                )
                optionToggleRow(
                    "Retro Mode",
                    "Pixelated, low-res UI styling across themes.",
                    isOn: legacyBoolBinding(\.retroMode)
                )
                optionSelectRow(
                    "Media filter",
                    "Apply a visual filter to media.",
                    selection: legacyStringBinding(\.mediaFilter),
                    choices: mediaFilterChoices
                )
                optionToggleRow(
                    "Scanline overlay",
                    "Add CRT scanlines over media.",
                    isOn: legacyBoolBinding(\.crtScanlinesEnabled)
                )
                optionToggleRow(
                    "Pixelated overlay",
                    "Pixelate media before applying filters.",
                    isOn: legacyBoolBinding(\.crtPixelateEnabled)
                )
                optionSliderRow(
                    "Pixelation resolution",
                    "Higher values mean chunkier pixels.",
                    value: legacyDoubleBinding(\.crtPixelateResolution),
                    range: 2...8,
                    step: 0.5
                ) { value in
                    formatRatioValue(value)
                }
                optionToggleRow(
                    "Film grain overlay",
                    "Adds film grain noise overlay.",
                    isOn: legacyBoolBinding(\.crtGrainEnabled)
                )
                optionSliderRow(
                    "Film grain amount",
                    "Strength of the grain overlay.",
                    value: legacyDoubleBinding(\.crtGrainAmount),
                    range: 0...0.25,
                    step: 0.01
                ) { value in
                    formatPercentValue(value)
                }
                optionToggleRow(
                    "VHS overlay",
                    "Soft, lo-def magnetic tape look.",
                    isOn: legacyBoolBinding(\.vhsOverlayEnabled)
                )
                optionToggleRow(
                    "Film corners overlay",
                    "Rounds media corners for an old film look.",
                    isOn: legacyBoolBinding(\.filmCornerOverlayEnabled)
                )
                optionSliderRow(
                    "VHS blur amount",
                    "Controls the fuzzy tape softness.",
                    value: legacyDoubleBinding(\.vhsBlurAmount),
                    range: 0...3,
                    step: 0.1
                ) { value in
                    String(format: "%.1fpx", value)
                }
                optionSliderRow(
                    "VHS chroma amount",
                    "Controls chromatic bleed/aberration.",
                    value: legacyDoubleBinding(\.vhsChromaAmount),
                    range: 0...3,
                    step: 0.1
                ) { value in
                    String(format: "%.1fpx", value)
                }
                optionToggleRow(
                    "Animated filters",
                    "When enabled, scanlines/grain/jitter animate.",
                    isOn: legacyBoolBinding(\.animatedMediaFilters)
                )

                sectionHeader("Playback")
                optionSelectRow(
                    "Video audio (preview)",
                    "Controls autoplay + mute in the in-pane preview player.",
                    selection: legacyStringBinding(\.videoPreview),
                    choices: videoAudioChoices
                )
                optionSelectRow(
                    "Video audio (gallery)",
                    "Controls autoplay + mute in fullscreen gallery mode.",
                    selection: legacyStringBinding(\.videoGallery),
                    choices: videoAudioChoices
                )
                optionSelectRow(
                    "Video skip step",
                    "Seek increment for video skip shortcuts.",
                    selection: legacyStringBinding(\.videoSkipStep),
                    choices: videoSkipChoices
                )
                optionSelectRow(
                    "Video end behavior",
                    "What happens when a video ends (outside slideshow).",
                    selection: legacyStringBinding(\.videoEndBehavior),
                    choices: videoEndChoices
                )
                optionSelectRow(
                    "Preload next item",
                    "Preload the next item for smoother browsing.",
                    selection: legacyStringBinding(\.preloadNextMode),
                    choices: preloadChoices
                )
                optionSelectRow(
                    "Slideshow speed",
                    "Controls slideshow timing when toggled.",
                    selection: legacyStringBinding(\.slideshowDefault),
                    choices: slideshowChoices
                )

                sectionHeader("Preview")
                optionToggleRow(
                    "Show file type labels (preview)",
                    "Show Image/Video labels under file thumbnails in the preview pane.",
                    isOn: legacyBoolBinding(\.showPreviewFileTypeLabel)
                )
                optionToggleRow(
                    "Show file names (preview)",
                    "Show file names under thumbnails in the preview pane.",
                    isOn: legacyBoolBinding(\.showPreviewFileName)
                )
                optionToggleRow(
                    "Show folder item counts (preview)",
                    "Show the number of items on folder cards in the preview pane.",
                    isOn: legacyBoolBinding(\.showPreviewFolderItemCount)
                )
                optionToggleRow(
                    "Apply filters to thumbnails (preview)",
                    "Apply media filters and overlays to preview thumbnails.",
                    isOn: legacyBoolBinding(\.previewThumbFiltersEnabled)
                )
                optionSelectRow(
                    "Thumbnail fit (preview)",
                    "Choose whether thumbnails crop to fill their card or fit inside it.",
                    selection: legacyStringBinding(\.previewThumbFit),
                    choices: thumbnailFitChoices
                )
                optionSelectRow(
                    "Image thumbnail size",
                    "Controls generated image thumbnail quality (smaller is faster).",
                    selection: legacyStringBinding(\.imageThumbSize),
                    choices: thumbnailQualityChoices
                )
                optionSelectRow(
                    "Video thumbnail size",
                    "Controls generated video thumbnail quality (smaller is faster).",
                    selection: legacyStringBinding(\.videoThumbSize),
                    choices: thumbnailQualityChoices
                )
                optionSelectRow(
                    "Media thumbnail scale",
                    "Controls how large media cards appear in the preview pane.",
                    selection: legacyStringBinding(\.mediaThumbUiSize),
                    choices: previewScaleChoices
                )
                optionSelectRow(
                    "Folder preview scale",
                    "Controls how large folder cards appear in the preview pane.",
                    selection: legacyStringBinding(\.folderPreviewSize),
                    choices: previewScaleChoices
                )
                optionSelectRow(
                    "Preview mode",
                    "Controls how folders are shown in the preview pane.",
                    selection: legacyStringBinding(\.previewMode),
                    choices: previewModeChoices
                )

                sectionHeader("Filenames")
                optionToggleRow(
                    "Hide file extensions",
                    "Hide .jpg / .mp4 in file names.",
                    isOn: legacyBoolBinding(\.hideFileExtensions)
                )
                optionToggleRow(
                    "Hide underscores from display names",
                    "Replace underscores with spaces.",
                    isOn: legacyBoolBinding(\.hideUnderscoresInNames)
                )
                optionToggleRow(
                    "Hide prefix before last ' - ' in file names",
                    "Show only text after the last ' - ' in file names.",
                    isOn: legacyBoolBinding(\.hideBeforeLastDashInFileNames)
                )
                optionToggleRow(
                    "Hide suffix after first underscore in file names",
                    "Show only text before the first underscore in file names.",
                    isOn: legacyBoolBinding(\.hideAfterFirstUnderscoreInFileNames)
                )
                optionToggleRow(
                    "Force title caps in display names",
                    "Apply Title Case to display names.",
                    isOn: legacyBoolBinding(\.forceTitleCaps)
                )
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var keybindsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Keybinds")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.falchionTextPrimary)

                ForEach(KeybindAction.allCases) { action in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(action.title)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.falchionTextPrimary)

                            if appState.preferences.showKeybindDescriptions {
                                Text(action.hint)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.falchionTextSecondary)
                            }
                        }

                        Spacer(minLength: 0)

                        Picker(action.title, selection: Binding<KeyToken?>(
                            get: { appState.keyToken(for: action) },
                            set: { appState.updateKeyBinding(action: action, token: $0) }
                        )) {
                            Text("Unassigned").tag(Optional<KeyToken>.none)
                            ForEach(KeyToken.allSelectable) { token in
                                Text(token.title).tag(Optional(token))
                            }
                        }
                        .labelsHidden()
                        .frame(width: 220)
                    }

                    Divider()
                }
            }
            .padding(14)
        }
    }

    private var onlineContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader("Online")

                optionRow("Media loading", "Choose how online profile media is fetched.") {
                    Picker("Media loading", selection: Binding(
                        get: { appState.preferences.onlineLoadMode },
                        set: { appState.setOnlineLoadMode($0) }
                    )) {
                        ForEach(OnlineLoadMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 220)
                }

                optionToggle("List online folders first", isOn: Binding(
                    get: { appState.preferences.listOnlineFoldersFirst },
                    set: { appState.setListOnlineFoldersFirst($0) }
                ))

                Text(appState.onlineProfileStatusText)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.falchionTextSecondary)

                if appState.onlineProfiles.isEmpty {
                    Text("No online profiles imported yet.")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.falchionTextSecondary)
                } else {
                    ForEach(appState.onlineProfiles) { profile in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(profile.descriptor.service.title): \(profile.descriptor.userID)")
                                .font(.system(size: 12, weight: .semibold))
                            Text("\(profile.fileCount) files • \(profile.postCount) posts")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.falchionTextSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color.falchionCardBase)
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.falchionBorder, lineWidth: 1)
                        }
                        .cornerRadius(6)
                    }
                }
            }
            .padding(14)
        }
    }

    private var responsesContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader("Responses")

                TextField("Template title", text: $responseTitleDraft)
                    .textFieldStyle(FalchionInputStyle())

                TextEditor(text: $responseBodyDraft)
                    .font(.system(size: 11, design: .monospaced))
                    .frame(height: 88)
                    .padding(4)
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.falchionBorder, lineWidth: 1)
                    }

                HStack(spacing: 8) {
                    Button("Add Template") {
                        appState.addSavedResponse(title: responseTitleDraft, body: responseBodyDraft)
                        responseTitleDraft = ""
                        responseBodyDraft = ""
                    }
                    .buttonStyle(FalchionMiniButtonStyle())

                    Button("Clear Templates") {
                        appState.resetSavedResponses()
                    }
                    .buttonStyle(FalchionMiniButtonStyle())
                }

                if appState.preferences.savedResponses.isEmpty {
                    Text("No saved response templates.")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.falchionTextSecondary)
                } else {
                    ForEach(appState.preferences.savedResponses) { template in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(template.title)
                                    .font(.system(size: 12, weight: .semibold))
                                Text(template.body)
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.falchionTextSecondary)
                                    .lineLimit(2)
                            }

                            Spacer()

                            Button("Delete") {
                                appState.removeSavedResponse(template.id)
                            }
                            .buttonStyle(FalchionMiniButtonStyle())
                        }
                        .padding(8)
                        .background(Color.falchionCardBase)
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.falchionBorder, lineWidth: 1)
                        }
                        .cornerRadius(6)
                    }
                }
            }
            .padding(14)
        }
    }

    private var footer: some View {
        HStack {
            Text(appState.keybindStatusText)
                .font(.system(size: 11))
                .foregroundStyle(Color.falchionTextSecondary)

            Spacer()

            Button("Reset Keybinds") {
                appState.resetKeyBindings()
            }
            .buttonStyle(FalchionMiniButtonStyle())

            Button("Reset Options") {
                appState.resetAllOptions()
            }
            .buttonStyle(FalchionMiniButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.falchionCardSurface)
    }

    private var visibleMenuTabs: [FalchionMenuTab] {
        if appState.preferences.onlineFeaturesEnabled {
            return FalchionMenuTab.allCases
        }

        return FalchionMenuTab.allCases.filter { $0 != .online }
    }

    private var showOptionHints: Bool {
        !appState.preferences.hideOptionDescriptions
    }

    private var dirSortModeChoices: [LegacyOptionChoice] {
        [
            LegacyOptionChoice(value: "name", label: "Name"),
            LegacyOptionChoice(value: "score", label: "Score"),
            LegacyOptionChoice(value: "size-desc", label: "Size"),
            LegacyOptionChoice(value: "count-recursive", label: "Item count recursive"),
            LegacyOptionChoice(value: "count-non-recursive", label: "Item count non-recursive")
        ]
    }

    private var folderScoreChoices: [LegacyOptionChoice] {
        [
            LegacyOptionChoice(value: "show", label: "Show score + arrows"),
            LegacyOptionChoice(value: "no-arrows", label: "Hide arrows"),
            LegacyOptionChoice(value: "hidden", label: "Hide score + arrows")
        ]
    }

    private var folderBehaviorChoices: [LegacyOptionChoice] {
        [
            LegacyOptionChoice(value: "stop", label: "Stop"),
            LegacyOptionChoice(value: "loop", label: "Loop"),
            LegacyOptionChoice(value: "slide", label: "Slide")
        ]
    }

    private var randomActionChoices: [LegacyOptionChoice] {
        [
            LegacyOptionChoice(value: "firstFileJump", label: "First file jump"),
            LegacyOptionChoice(value: "randomFileSort", label: "Random file sort")
        ]
    }

    private var colorSchemeChoices: [LegacyOptionChoice] {
        [
            LegacyOptionChoice(value: "classic", label: "Classic Dark"),
            LegacyOptionChoice(value: "light", label: "Light"),
            LegacyOptionChoice(value: "superdark", label: "OLED Dark"),
            LegacyOptionChoice(value: "synthwave", label: "Synthwave"),
            LegacyOptionChoice(value: "verdant", label: "Verdant"),
            LegacyOptionChoice(value: "azure", label: "Azure"),
            LegacyOptionChoice(value: "ember", label: "Ember"),
            LegacyOptionChoice(value: "amber", label: "Amber"),
            LegacyOptionChoice(value: "retro90s", label: "Retro 90s"),
            LegacyOptionChoice(value: "retro90s-dark", label: "Retro 90s Dark")
        ]
    }

    private var mediaFilterChoices: [LegacyOptionChoice] {
        [
            LegacyOptionChoice(value: "off", label: "Off"),
            LegacyOptionChoice(value: "vibrant", label: "Vibrant"),
            LegacyOptionChoice(value: "cinematic", label: "Cinematic"),
            LegacyOptionChoice(value: "orangeTeal", label: "Orange+Teal"),
            LegacyOptionChoice(value: "bw", label: "Black + White"),
            LegacyOptionChoice(value: "uv", label: "UV Camera"),
            LegacyOptionChoice(value: "infrared", label: "Infrared Camera")
        ]
    }

    private var videoAudioChoices: [LegacyOptionChoice] {
        [
            LegacyOptionChoice(value: "unmuted", label: "Auto-play unmuted"),
            LegacyOptionChoice(value: "muted", label: "Auto-play muted"),
            LegacyOptionChoice(value: "off", label: "No autoplay")
        ]
    }

    private var videoSkipChoices: [LegacyOptionChoice] {
        [
            LegacyOptionChoice(value: "3", label: "3 seconds"),
            LegacyOptionChoice(value: "5", label: "5 seconds"),
            LegacyOptionChoice(value: "10", label: "10 seconds"),
            LegacyOptionChoice(value: "30", label: "30 seconds")
        ]
    }

    private var videoEndChoices: [LegacyOptionChoice] {
        [
            LegacyOptionChoice(value: "loop", label: "Loop video"),
            LegacyOptionChoice(value: "next", label: "Advance to next item"),
            LegacyOptionChoice(value: "stop", label: "Stop at end")
        ]
    }

    private var preloadChoices: [LegacyOptionChoice] {
        [
            LegacyOptionChoice(value: "off", label: "Off"),
            LegacyOptionChoice(value: "on", label: "On"),
            LegacyOptionChoice(value: "ultra", label: "Ultra")
        ]
    }

    private var slideshowChoices: [LegacyOptionChoice] {
        [
            LegacyOptionChoice(value: "cycle", label: "Cycle speeds"),
            LegacyOptionChoice(value: "1", label: "Toggle 1s"),
            LegacyOptionChoice(value: "3", label: "Toggle 3s"),
            LegacyOptionChoice(value: "5", label: "Toggle 5s"),
            LegacyOptionChoice(value: "10", label: "Toggle 10s")
        ]
    }

    private var thumbnailFitChoices: [LegacyOptionChoice] {
        [
            LegacyOptionChoice(value: "cover", label: "Crop to fill"),
            LegacyOptionChoice(value: "contain", label: "Fit inside")
        ]
    }

    private var thumbnailQualityChoices: [LegacyOptionChoice] {
        [
            LegacyOptionChoice(value: "tiny", label: "Tiny"),
            LegacyOptionChoice(value: "small", label: "Small"),
            LegacyOptionChoice(value: "medium", label: "Medium"),
            LegacyOptionChoice(value: "high", label: "High")
        ]
    }

    private var previewScaleChoices: [LegacyOptionChoice] {
        [
            LegacyOptionChoice(value: "small", label: "Small"),
            LegacyOptionChoice(value: "medium", label: "Medium"),
            LegacyOptionChoice(value: "large", label: "Large")
        ]
    }

    private var previewModeChoices: [LegacyOptionChoice] {
        [
            LegacyOptionChoice(value: "grid", label: "Grid"),
            LegacyOptionChoice(value: "expanded", label: "Expanded")
        ]
    }

    private func formatRatioValue(_ value: Double) -> String {
        if abs(value.rounded() - value) < 0.001 {
            return "\(Int(value))x"
        }

        return String(format: "%.1fx", value)
    }

    private func formatPercentValue(_ value: Double) -> String {
        let percent = Int((value * 100).rounded())
        return "\(percent)%"
    }

    private func legacyStringBinding(_ keyPath: WritableKeyPath<AppPreferences, String>) -> Binding<String> {
        Binding(
            get: { appState.preferences[keyPath: keyPath] },
            set: { appState.setLegacyStringOption(keyPath, $0) }
        )
    }

    private func legacyBoolBinding(_ keyPath: WritableKeyPath<AppPreferences, Bool>) -> Binding<Bool> {
        Binding(
            get: { appState.preferences[keyPath: keyPath] },
            set: { appState.setLegacyBoolOption(keyPath, $0) }
        )
    }

    private func legacyDoubleBinding(_ keyPath: WritableKeyPath<AppPreferences, Double>) -> Binding<Double> {
        Binding(
            get: { appState.preferences[keyPath: keyPath] },
            set: { appState.setLegacyDoubleOption(keyPath, $0) }
        )
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(Color.falchionTextPrimary)
            .padding(.top, 4)
    }

    private func optionToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        optionRow(title, "") {
            Toggle("", isOn: isOn)
                .labelsHidden()
        }
    }

    private func optionToggleRow(_ title: String, _ hint: String, isOn: Binding<Bool>) -> some View {
        optionRow(title, hint) {
            Toggle("", isOn: isOn)
                .labelsHidden()
        }
    }

    private func optionSelectRow(_ title: String, _ hint: String, selection: Binding<String>, choices: [LegacyOptionChoice]) -> some View {
        optionRow(title, hint) {
            Picker(title, selection: selection) {
                ForEach(choices) { choice in
                    Text(choice.label).tag(choice.value)
                }
            }
            .labelsHidden()
            .frame(width: 240)
        }
    }

    private func optionSliderRow(
        _ title: String,
        _ hint: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        format: @escaping (Double) -> String
    ) -> some View {
        optionRow(title, hint) {
            VStack(alignment: .trailing, spacing: 3) {
                Slider(value: value, in: range, step: step)
                    .frame(width: 220)
                Text(format(value.wrappedValue))
                    .font(.system(size: 11))
                    .foregroundStyle(Color.falchionTextSecondary)
            }
        }
    }

    private func optionRow<Control: View>(_ title: String, _ hint: String, @ViewBuilder control: () -> Control) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: showOptionHints ? 2 : 0) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.falchionTextPrimary)

                if showOptionHints, !hint.isEmpty {
                    Text(hint)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.falchionTextSecondary)
                }
            }

            Spacer(minLength: 0)

            control()
        }
        .padding(.vertical, 3)
    }
}
