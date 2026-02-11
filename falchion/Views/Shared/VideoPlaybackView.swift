import AVFoundation
import AVKit
import SwiftUI

enum VideoPlaybackLayout {
    case compact
    case expanded
}

struct VideoPlaybackView: View {
    let url: URL
    let layout: VideoPlaybackLayout

    @State private var player: AVPlayer?
    @State private var isPlaying: Bool = false
    @State private var isMuted: Bool = false
    @State private var isLooping: Bool = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var isScrubbing: Bool = false

    @State private var periodicObserverToken: Any?
    @State private var didFinishObserverToken: NSObjectProtocol?

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Color.black

                if let player {
                    VideoPlayer(player: player)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .onDisappear {
                            pause()
                        }
                } else {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .controlSize(.large)
                        .tint(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: layout == .compact ? 170 : nil)

            controls
        }
        .task(id: url.path) {
            configurePlayer()
        }
        .onDisappear {
            teardownObservers()
            player?.pause()
            player = nil
            isPlaying = false
        }
    }

    private var controls: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Button(isPlaying ? "Pause" : "Play") {
                    togglePlayPause()
                }
                .buttonStyle(FalchionMiniButtonStyle())

                Button("-5s") {
                    seek(by: -5)
                }
                .buttonStyle(FalchionMiniButtonStyle())

                Button("+5s") {
                    seek(by: 5)
                }
                .buttonStyle(FalchionMiniButtonStyle())

                Button(isMuted ? "Unmute" : "Mute") {
                    isMuted.toggle()
                    player?.isMuted = isMuted
                }
                .buttonStyle(FalchionMiniButtonStyle())

                Button(isLooping ? "Loop: On" : "Loop: Off") {
                    isLooping.toggle()
                }
                .buttonStyle(FalchionMiniButtonStyle())

                Spacer()

                Text(isPlaying ? "Playing" : "Paused")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.falchionTextSecondary)
            }

            HStack(spacing: 8) {
                Text(timeString(currentTime))
                    .font(.system(size: 10))
                    .foregroundStyle(Color.falchionTextSecondary)
                    .frame(width: 52, alignment: .leading)

                Slider(
                    value: Binding(
                        get: {
                            duration > 0 ? min(max(currentTime, 0), duration) : 0
                        },
                        set: { newValue in
                            currentTime = newValue
                        }
                    ),
                    in: 0...(duration > 0 ? duration : 1),
                    onEditingChanged: { editing in
                        isScrubbing = editing
                        if !editing {
                            seek(to: currentTime)
                        }
                    }
                )

                Text(timeString(duration))
                    .font(.system(size: 10))
                    .foregroundStyle(Color.falchionTextSecondary)
                    .frame(width: 52, alignment: .trailing)
            }
        }
    }

    private func configurePlayer() {
        teardownObservers()

        let nextPlayer = AVPlayer(url: url)
        nextPlayer.actionAtItemEnd = .pause
        nextPlayer.isMuted = isMuted
        player = nextPlayer
        currentTime = 0
        duration = nextPlayer.currentItem?.asset.duration.seconds.isFinite == true ? nextPlayer.currentItem?.asset.duration.seconds ?? 0 : 0
        isPlaying = false

        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        periodicObserverToken = nextPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            guard !isScrubbing else {
                return
            }

            currentTime = max(0, time.seconds.isFinite ? time.seconds : 0)
            if let total = nextPlayer.currentItem?.duration.seconds, total.isFinite {
                duration = max(total, 0)
            }
        }

        didFinishObserverToken = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nextPlayer.currentItem,
            queue: .main
        ) { _ in
            if isLooping {
                seek(to: 0)
                nextPlayer.play()
                isPlaying = true
            } else {
                isPlaying = false
                currentTime = duration
            }
        }
    }

    private func teardownObservers() {
        if let periodicObserverToken, let player {
            player.removeTimeObserver(periodicObserverToken)
            self.periodicObserverToken = nil
        }

        if let didFinishObserverToken {
            NotificationCenter.default.removeObserver(didFinishObserverToken)
            self.didFinishObserverToken = nil
        }
    }

    private func togglePlayPause() {
        guard let player else {
            return
        }

        if isPlaying {
            player.pause()
            isPlaying = false
            return
        }

        if duration > 0 && currentTime >= duration - 0.05 {
            seek(to: 0)
        }

        player.play()
        isPlaying = true
    }

    private func pause() {
        player?.pause()
        isPlaying = false
    }

    private func seek(by seconds: Double) {
        let target = min(max(currentTime + seconds, 0), max(duration, 0))
        seek(to: target)
    }

    private func seek(to seconds: Double) {
        guard let player else {
            return
        }

        let clamped = min(max(seconds, 0), max(duration, 0))
        let time = CMTime(seconds: clamped, preferredTimescale: 600)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = clamped
    }

    private func timeString(_ seconds: Double) -> String {
        guard seconds.isFinite && seconds >= 0 else {
            return "00:00"
        }

        let whole = Int(seconds.rounded(.down))
        let hours = whole / 3600
        let minutes = (whole % 3600) / 60
        let secs = whole % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }

        return String(format: "%02d:%02d", minutes, secs)
    }
}
