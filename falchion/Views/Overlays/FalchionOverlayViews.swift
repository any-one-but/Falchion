import AppKit
import SwiftUI

struct FalchionMenuOverlayView: View {
    @EnvironmentObject private var appState: FalchionAppState

    @State private var responseTitleDraft: String = ""
    @State private var responseBodyDraft: String = ""
    @State private var pendingDeleteProfile: OnlineProfileRecord?

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.opacity(0.12)
                .ignoresSafeArea()
                .onTapGesture {
                    appState.showMenuOverlay = false
                }

            VStack(spacing: 0) {
                header
                bodyContent
                footer
            }
            .frame(width: 840, height: 560)
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.falchionBorder, lineWidth: 1)
            }
            .cornerRadius(4)
            .padding(.leading, 90)
            .padding(.top, 50)
        }
        .confirmationDialog("Delete this profile import and local folder structure?", isPresented: Binding(
            get: { pendingDeleteProfile != nil },
            set: { if !$0 { pendingDeleteProfile = nil } }
        )) {
            Button("Delete", role: .destructive) {
                guard let pendingDeleteProfile else {
                    return
                }
                Task {
                    await appState.deleteOnlineProfile(pendingDeleteProfile)
                }
                self.pendingDeleteProfile = nil
            }

            Button("Cancel", role: .cancel) {
                pendingDeleteProfile = nil
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Text("Menu")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.falchionTextPrimary)

            HStack(spacing: 4) {
                ForEach(FalchionMenuTab.allCases) { tab in
                    Button(tab.title) {
                        appState.menuTab = tab
                    }
                    .buttonStyle(FalchionMiniButtonStyle(isActive: appState.menuTab == tab))
                }
            }

            Spacer(minLength: 8)

            Button("X") {
                appState.showMenuOverlay = false
            }
            .buttonStyle(FalchionMiniButtonStyle())
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(Color.falchionPane)
    }

    private var bodyContent: some View {
        Group {
            switch appState.menuTab {
            case .options:
                optionsTab
            case .keybinds:
                keybindsTab
            case .online:
                onlineTab
            case .responses:
                responsesTab
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(12)
        .background(Color.falchionPane)
    }

    @ViewBuilder
    private var footer: some View {
        switch appState.menuTab {
        case .options:
            HStack {
                Text(appState.optionsStatusText)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.falchionTextSecondary)

                Spacer()

                Button("Reset defaults") {
                    appState.resetAllOptions()
                }
                .buttonStyle(FalchionMiniButtonStyle())

                Button("Done") {
                    appState.showMenuOverlay = false
                }
                .buttonStyle(FalchionMiniButtonStyle())
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
            .background(Color.falchionPane)

        case .keybinds:
            HStack {
                Text(appState.keybindStatusText)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.falchionTextSecondary)

                Spacer()

                Button("Reset defaults") {
                    appState.resetKeyBindings()
                }
                .buttonStyle(FalchionMiniButtonStyle())

                Button("Done") {
                    appState.showMenuOverlay = false
                }
                .buttonStyle(FalchionMiniButtonStyle())
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
            .background(Color.falchionPane)

        case .online, .responses:
            EmptyView()
        }
    }

    private var optionsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Options")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.falchionTextPrimary)

                optionRow(
                    title: "Appearance",
                    hint: "Choose System to follow macOS or force Light/Dark."
                ) {
                    Picker("Appearance", selection: Binding(
                        get: { appState.preferences.theme },
                        set: { appState.setTheme($0) }
                    )) {
                        ForEach(FalchionThemeOption.allCases) { theme in
                            Text(theme.title).tag(theme)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 180)
                }

                optionRow(
                    title: "Thumbnail Fit",
                    hint: "Controls whether preview thumbnails crop or fit within cards."
                ) {
                    Picker("Thumbnail Fit", selection: Binding(
                        get: { appState.preferences.thumbnailFitMode },
                        set: { appState.setThumbnailFitMode($0) }
                    )) {
                        ForEach(ThumbnailFitMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 230)
                }

                optionRow(
                    title: "Preview Card Size",
                    hint: "Controls media/folder card density in the preview grid."
                ) {
                    Picker("Preview Size", selection: Binding(
                        get: { appState.previewCardSize },
                        set: { appState.setPreviewCardSizePreference($0) }
                    )) {
                        ForEach(PreviewCardSizeOption.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 180)
                }

                optionRow(
                    title: "Default Conflict Policy",
                    hint: "Defines rename/move import behavior when destination names already exist."
                ) {
                    Picker("Conflict", selection: Binding(
                        get: { appState.preferences.defaultConflictPolicy },
                        set: { appState.setConflictPolicy($0) }
                    )) {
                        ForEach(FileConflictPolicy.allCases) { policy in
                            Text(policy.title).tag(policy)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 220)
                }

                optionRow(
                    title: "Online Loading",
                    hint: "As-needed fetches fewer pages; preload fetches deeper post history."
                ) {
                    Picker("Online Loading", selection: Binding(
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

                optionRow(
                    title: "List Online Folders First",
                    hint: "Moves imported online folders above local folders in directory sorting."
                ) {
                    Toggle("", isOn: Binding(
                        get: { appState.preferences.listOnlineFoldersFirst },
                        set: { appState.setListOnlineFoldersFirst($0) }
                    ))
                    .labelsHidden()
                }

                optionRow(
                    title: "Show Option Hints",
                    hint: "Displays helper descriptions in this tab."
                ) {
                    Toggle("", isOn: Binding(
                        get: { appState.preferences.showOptionDescriptions },
                        set: { appState.setOptionDescriptionsVisible($0) }
                    ))
                    .labelsHidden()
                }

                optionRow(
                    title: "Show Keybind Hints",
                    hint: "Displays helper descriptions in the keybind tab."
                ) {
                    Toggle("", isOn: Binding(
                        get: { appState.preferences.showKeybindDescriptions },
                        set: { appState.setKeybindDescriptionsVisible($0) }
                    ))
                    .labelsHidden()
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var keybindsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Keybinds")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.falchionTextPrimary)

                Text("Unassigned actions are ignored. Duplicate bindings clear the old action automatically.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.falchionTextSecondary)

                ForEach(KeybindAction.allCases) { action in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .center, spacing: 8) {
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
                        .padding(.vertical, 6)

                        Rectangle()
                            .fill(Color.falchionBorder)
                            .frame(height: 1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var onlineTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Online")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.falchionTextPrimary)

                Text("\(appState.onlineProfileStatusText)")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.falchionTextSecondary)

                optionRow(title: "Media Loading", hint: "Controls adapter paging depth during profile ingestion.") {
                    Picker("Loading", selection: Binding(
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

                optionRow(title: "List Online Folders First", hint: "Sort imported online folders before local folders.") {
                    Toggle("", isOn: Binding(
                        get: { appState.preferences.listOnlineFoldersFirst },
                        set: { appState.setListOnlineFoldersFirst($0) }
                    ))
                    .labelsHidden()
                }

                Text("Profiles")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.falchionTextPrimary)

                if appState.onlineProfiles.isEmpty {
                    Text("No online profiles imported yet.")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.falchionTextSecondary)
                } else {
                    ForEach(appState.onlineProfiles) { profile in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .top, spacing: 8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(profile.descriptor.service.title): \(profile.descriptor.userID)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(Color.falchionTextPrimary)
                                    Text(profile.descriptor.sourceURL)
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color.falchionTextSecondary)
                                        .lineLimit(1)
                                    Text("\(profile.fileCount) files - \(profile.postCount) posts - \(profile.importMode.title) mode")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Color.falchionTextSecondary)
                                }

                                Spacer(minLength: 0)

                                HStack(spacing: 6) {
                                    Button("Replace") {
                                        Task {
                                            await appState.replaceOnlineProfile(profile)
                                        }
                                    }
                                    .buttonStyle(FalchionMiniButtonStyle())

                                    Button("Refresh") {
                                        Task {
                                            await appState.refreshOnlineProfile(profile)
                                        }
                                    }
                                    .buttonStyle(FalchionMiniButtonStyle())

                                    Button("Delete") {
                                        pendingDeleteProfile = profile
                                    }
                                    .buttonStyle(FalchionMiniButtonStyle())
                                }
                            }

                            Rectangle()
                                .fill(Color.falchionBorder)
                                .frame(height: 1)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var responsesTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Responses")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.falchionTextPrimary)

                    Spacer()

                    Button("Clear Log") {
                        appState.clearOnlineResponses()
                    }
                    .buttonStyle(FalchionMiniButtonStyle())
                }

                if appState.onlineResponseLog.isEmpty {
                    Text("No API responses captured yet.")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.falchionTextSecondary)
                } else {
                    ForEach(appState.onlineResponseLog.reversed(), id: \.id) { response in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(response.url)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.falchionTextPrimary)
                                .lineLimit(1)

                            Text("\(response.timestamp.formatted(date: .abbreviated, time: .standard)) - \(response.source) - HTTP \(response.statusCode) - \(response.parseOK ? "Parsed" : "Raw")")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.falchionTextSecondary)

                            Text(response.responsePreview.isEmpty ? "(empty response body)" : response.responsePreview)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(Color.falchionTextSecondary)
                                .textSelection(.enabled)
                                .lineLimit(6)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.falchionCardBase)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(Color.falchionBorder, lineWidth: 1)
                                }
                                .cornerRadius(3)
                        }
                    }
                }

                Rectangle()
                    .fill(Color.falchionBorderStrong)
                    .frame(height: 1)

                Text("Saved Responses")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.falchionTextPrimary)

                TextField("Template title", text: $responseTitleDraft)
                    .textFieldStyle(FalchionInputStyle())

                TextEditor(text: $responseBodyDraft)
                    .font(.system(size: 11, design: .monospaced))
                    .frame(height: 80)
                    .padding(4)
                    .overlay {
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.falchionBorder, lineWidth: 1)
                    }

                HStack {
                    Button("Add Template") {
                        appState.addSavedResponse(title: responseTitleDraft, body: responseBodyDraft)
                        responseTitleDraft = ""
                        responseBodyDraft = ""
                    }
                    .buttonStyle(FalchionMiniButtonStyle())
                    .disabled(responseTitleDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && responseBodyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

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
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(template.title)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color.falchionTextPrimary)
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
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.falchionBorder, lineWidth: 1)
                        }
                        .cornerRadius(3)
                    }
                }

                Rectangle()
                    .fill(Color.falchionBorderStrong)
                    .frame(height: 1)

                Text("Config Snapshot")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.falchionTextPrimary)

                Text(appState.configurationSummaryJSON)
                    .font(.system(size: 10, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.falchionCardBase)
                    .overlay {
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.falchionBorder, lineWidth: 1)
                    }
                    .cornerRadius(3)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private func optionRow<Control: View>(title: String, hint: String, @ViewBuilder control: () -> Control) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.falchionTextPrimary)

                if appState.preferences.showOptionDescriptions {
                    Text(hint)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.falchionTextSecondary)
                }
            }

            Spacer(minLength: 0)

            control()
        }
        .padding(.vertical, 2)
    }
}

struct FalchionViewerOverlayView: View {
    @EnvironmentObject private var appState: FalchionAppState

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let media = appState.selectedMediaItem {
                ViewerMediaSurfaceView(item: media)
                    .padding(0)
            }
        }
        .onTapGesture(count: 2) {
            appState.closeViewer()
        }
    }
}

private struct ViewerMediaSurfaceView: View {
    let item: MediaItem

    var body: some View {
        Group {
            if item.kind == .video {
                PlainVideoSurfaceView(url: item.url)
            } else {
                PreloadedImageView(url: item.url)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity.combined(with: .scale(scale: 0.985)))
    }
}

struct FalchionBusyOverlayView: View {
    @EnvironmentObject private var appState: FalchionAppState

    var body: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.large)
                    .tint(.white)

                Text("Working...")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .textCase(.uppercase)

                Text(appState.statusMessage)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(1)
            }
        }
    }
}
