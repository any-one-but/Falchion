import AppKit
import SwiftUI

struct FalchionShellView: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var appState: FalchionAppState

    @State private var keyMonitor: Any?

    var body: some View {
        ZStack {
            Color.falchionBackground.ignoresSafeArea()

            HSplitView {
                SidebarPaneView()
                    .frame(minWidth: 260, idealWidth: 340, maxWidth: 540)

                PreviewPaneView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if appState.showViewerOverlay {
                FalchionViewerOverlayView()
                    .transition(.opacity)
                    .zIndex(30)
            }

            if appState.isIndexing {
                FalchionBusyOverlayView()
                    .zIndex(40)
            }
        }
        .frame(minWidth: 1120, minHeight: 720)
        .animation(.easeInOut(duration: 0.12), value: appState.showViewerOverlay)
        .task {
            await appState.bootstrapIfNeeded()
        }
        .onChange(of: appState.showMenuOverlay) { _, shouldOpen in
            guard shouldOpen else {
                return
            }

            openWindow(id: "falchion-options")
            appState.showMenuOverlay = false
        }
        .onAppear {
            installKeyboardMonitor()
        }
        .onDisappear {
            removeKeyboardMonitor()
        }
        .confirmationDialog("Delete selected media?", isPresented: $appState.showDeleteMediaConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    await appState.confirmDeleteSelectedMedia()
                }
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This moves the selected file to Trash.")
        }
        .confirmationDialog("Delete selected folder?", isPresented: $appState.showDeleteDirectoryConfirmation) {
            Button("Delete Folder", role: .destructive) {
                Task {
                    await appState.confirmDeleteSelectedDirectory()
                }
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This moves the selected folder to Trash.")
        }
        .alert(appState.operationAlertTitle, isPresented: $appState.showOperationAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(appState.operationAlertMessage)
        }
    }

    private func installKeyboardMonitor() {
        guard keyMonitor == nil else {
            return
        }

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if shouldSkipKeyboardHandling(event) {
                return event
            }

            if handleKeyboardEvent(event) {
                return nil
            }

            return event
        }
    }

    private func removeKeyboardMonitor() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }

    private func shouldSkipKeyboardHandling(_ event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command) || event.modifierFlags.contains(.control) || event.modifierFlags.contains(.option) {
            return true
        }

        if let responder = NSApp.keyWindow?.firstResponder, responder is NSTextView {
            return true
        }

        return false
    }

    private func handleKeyboardEvent(_ event: NSEvent) -> Bool {
        appState.handleKeyboardEvent(event)
    }
}
