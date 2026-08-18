import SwiftUI

enum AppRoute {
    case menu
    case game
    case shop
    case settings
    case challenges
    case profile
    case achievements
    case season
}

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var session = GameSession()
    @ObservedObject private var store = StoreManager.shared
    @ObservedObject private var profile = PlayerProfile.shared
    @ObservedObject private var settingsStore = SettingsStore.shared
    @State private var route: AppRoute = .menu

    var body: some View {
        Group {
            if !settingsStore.onboardingCompleted {
                OnboardingView()
            } else {
                routedContent
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                AudioManager.shared.syncMusicPreference()
            case .inactive, .background:
                AudioManager.shared.pauseMusic()
                if isGameRoute {
                    session.pauseForInterruption()
                }
            @unknown default:
                break
            }
        }
    }

    @ViewBuilder
    private var routedContent: some View {
        switch route {
        case .menu:
            MainMenuView(
                store: store,
                profile: profile,
                play: { startGame() },
                shop: {
                    AnalyticsManager.shared.track(.shopOpened)
                    route = .shop
                },
                challenges: { route = .challenges },
                profileAction: { route = .profile },
                achievements: { route = .achievements },
                season: { route = .season },
                practice: { startGame(tutorial: true) },
                settings: { route = .settings }
            )
        case .game:
            GameScreen(session: session, home: { route = .menu })
        case .shop:
            ShopView(store: store, profile: profile, close: { route = .menu })
        case .settings:
            SettingsView(close: { route = .menu })
        case .challenges:
            ChallengesView(profile: profile, close: { route = .menu })
        case .profile:
            ProfileView(profile: profile, close: { route = .menu })
        case .achievements:
            AchievementsView(profile: profile, close: { route = .menu })
        case .season:
            SeasonView(profile: profile, close: { route = .menu })
        }
    }

    private var isGameRoute: Bool {
        if case .game = route { return true }
        return false
    }

    private func startGame(tutorial: Bool = false) {
        AudioManager.shared.play(.tap)
        session.startNewRun(tutorial: tutorial)
        route = .game
    }
}
