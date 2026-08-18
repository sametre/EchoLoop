import AVFoundation
import Foundation

@MainActor
final class AudioManager: ObservableObject {
    static let shared = AudioManager()

    enum Sound: String, CaseIterable {
        case tap = "ui_tap"
        case echoSpawn = "echo_spawn"
        case shard
        case dash
        case closeCall = "close_call"
        case levelUp = "level_up"
        case death
        case revive
    }

    private var musicPlayer: AVAudioPlayer?
    private var effectPlayers: [Sound: AVAudioPlayer] = [:]
    private var configured = false
    private var isDucked = false
    private var interruptionObserver: NSObjectProtocol?

    private init() {}

    deinit {
        if let interruptionObserver {
            NotificationCenter.default.removeObserver(interruptionObserver)
        }
    }

    func configure() {
        guard !configured else { return }
        configured = true

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            AppLogger.audio.error("Audio session setup failed: \(error.localizedDescription, privacy: .public)")
        }

        preparePlayers()
        observeInterruptions()
        syncMusicPreference()
    }

    func syncMusicPreference() {
        guard configured else { return }
        if SettingsStore.shared.musicEnabled {
            startMusic()
        } else {
            musicPlayer?.pause()
        }
    }

    func play(_ sound: Sound) {
        guard SettingsStore.shared.soundEffectsEnabled else { return }
        guard let player = effectPlayers[sound] else {
            AppLogger.audio.debug("Missing prepared sound: \(sound.rawValue, privacy: .public)")
            return
        }
        player.currentTime = 0
        player.play()
    }

    func startMusic() {
        guard SettingsStore.shared.musicEnabled else { return }
        guard let musicPlayer else { return }
        if musicPlayer.isPlaying { return }
        musicPlayer.numberOfLoops = -1
        musicPlayer.volume = isDucked ? 0.12 : 0.35
        musicPlayer.play()
    }

    func pauseMusic() {
        musicPlayer?.pause()
    }

    func duckMusic(_ ducked: Bool) {
        isDucked = ducked
        musicPlayer?.setVolume(ducked ? 0.12 : 0.35, fadeDuration: 0.18)
    }

    private func preparePlayers() {
        if let url = Bundle.main.url(forResource: "ambient_loop", withExtension: "wav") {
            do {
                musicPlayer = try AVAudioPlayer(contentsOf: url)
                musicPlayer?.prepareToPlay()
            } catch {
                AppLogger.audio.error("Music file failed to load: \(error.localizedDescription, privacy: .public)")
            }
        } else {
            AppLogger.audio.warning("ambient_loop.wav is missing from the app bundle.")
        }

        for sound in Sound.allCases {
            guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") else {
                AppLogger.audio.warning("Missing audio resource: \(sound.rawValue, privacy: .public).wav")
                continue
            }
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                effectPlayers[sound] = player
            } catch {
                AppLogger.audio.error("Failed to prepare \(sound.rawValue, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func observeInterruptions() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleInterruption(notification)
            }
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }

        switch type {
        case .began:
            pauseMusic()
            AppLogger.audio.notice("Audio interruption began.")
        case .ended:
            syncMusicPreference()
            AppLogger.audio.notice("Audio interruption ended.")
        @unknown default:
            break
        }
    }
}
