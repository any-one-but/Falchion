import AppKit
import SwiftUI

struct FalchionShellView: View {
    @EnvironmentObject private var appState: FalchionAppState

    private let minSidebarWidth: CGFloat = 260
    private let maxSidebarWidth: CGFloat = 520

    @State private var dragStartSidebarWidth: CGFloat?
    @State private var keyMonitor: Any?

    var body: some View {
        ZStack {
            Color.falchionBackground.ignoresSafeArea()

            HStack(spacing: 0) {
                SidebarPaneView()
                    .frame(width: appState.sidebarWidth)

                divider

                PreviewPaneView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if appState.showMenuOverlay {
                FalchionMenuOverlayView()
                    .zIndex(20)
            }

            if appState.showViewerOverlay {
                FalchionViewerOverlayView()
                    .transition(.opacity.combined(with: .scale(scale: 0.985)))
                    .zIndex(30)
            }

            if appState.isIndexing {
                FalchionBusyOverlayView()
                    .zIndex(40)
            }
        }
        .frame(minWidth: 1120, minHeight: 720)
        .animation(.easeInOut(duration: 0.2), value: appState.showViewerOverlay)
        .task {
            await appState.bootstrapIfNeeded()
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

    private var divider: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 8)
            .overlay {
                Rectangle()
                    .fill(Color.falchionBorder)
                    .frame(width: 1)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if dragStartSidebarWidth == nil {
                            dragStartSidebarWidth = appState.sidebarWidth
                        }

                        let startWidth = dragStartSidebarWidth ?? appState.sidebarWidth
                        appState.sidebarWidth = min(
                            max(minSidebarWidth, startWidth + value.translation.width),
                            maxSidebarWidth
                        )
                    }
                    .onEnded { _ in
                        dragStartSidebarWidth = nil
                    }
            )
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
