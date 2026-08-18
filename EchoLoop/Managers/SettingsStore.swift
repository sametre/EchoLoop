import Combine
import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    @Published var hapticsEnabled: Bool { didSet { defaults.set(hapticsEnabled, forKey: Keys.haptics) } }
    @Published var reducedMotion: Bool { didSet { defaults.set(reducedMotion, forKey: Keys.reducedMotion) } }
    @Published var autoPerformance: Bool { didSet { defaults.set(autoPerformance, forKey: Keys.autoPerformance) } }
    @Published var tutorialHints: Bool { didSet { defaults.set(tutorialHints, forKey: Keys.tutorialHints) } }
    @Published var soundEffectsEnabled: Bool { didSet { defaults.set(soundEffectsEnabled, forKey: Keys.soundEffects) } }
    @Published var musicEnabled: Bool {
        didSet {
            defaults.set(musicEnabled, forKey: Keys.music)
            AudioManager.shared.syncMusicPreference()
        }
    }
    @Published var onboardingCompleted: Bool { didSet { defaults.set(onboardingCompleted, forKey: Keys.onboardingCompleted) } }

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let haptics = "echo.settings.haptics"
        static let reducedMotion = "echo.settings.reducedMotion"
        static let autoPerformance = "echo.settings.autoPerformance"
        static let tutorialHints = "echo.settings.tutorialHints"
        static let soundEffects = "echo.settings.soundEffects"
        static let music = "echo.settings.music"
        static let onboardingCompleted = "echo.settings.onboardingCompleted"
    }

    private init() {
        defaults.register(defaults: [
            Keys.haptics: true,
            Keys.reducedMotion: false,
            Keys.autoPerformance: true,
            Keys.tutorialHints: true,
            Keys.soundEffects: true,
            Keys.music: true,
            Keys.onboardingCompleted: false
        ])
        hapticsEnabled = defaults.bool(forKey: Keys.haptics)
        reducedMotion = defaults.bool(forKey: Keys.reducedMotion)
        autoPerformance = defaults.bool(forKey: Keys.autoPerformance)
        tutorialHints = defaults.bool(forKey: Keys.tutorialHints)
        soundEffectsEnabled = defaults.bool(forKey: Keys.soundEffects)
        musicEnabled = defaults.bool(forKey: Keys.music)
        onboardingCompleted = defaults.bool(forKey: Keys.onboardingCompleted)
    }

    func completeOnboarding() {
        onboardingCompleted = true
    }

    #if DEBUG
    func resetOnboardingForDevelopment() {
        onboardingCompleted = false
    }
    #endif
}
