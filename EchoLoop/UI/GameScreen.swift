import SwiftUI
import SpriteKit

struct GameScreen: View {
    @ObservedObject var session: GameSession
    @ObservedObject private var settings = SettingsStore.shared
    @State private var scene: EchoScene
    @State private var adRegisteredForRun = false
    @State private var isStarting = true
    @State private var countdown = 3
    @State private var countdownGeneration = UUID()
    let home: () -> Void

    init(session: GameSession, home: @escaping () -> Void) {
        self.session = session
        self.home = home
        _scene = State(initialValue: EchoScene(session: session))
    }

    var body: some View {
        ZStack {
            SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                .ignoresSafeArea()
                .accessibilityIdentifier("game.sprite")
                .background(Color.black)

            hud

            if isStarting { countdownOverlay }
            if session.isPaused && !session.isGameOver && !isStarting { pauseOverlay }
            if session.isGameOver { gameOverOverlay }
        }
        .onAppear { beginCountdown() }
        .onDisappear {
            countdownGeneration = UUID()
            AudioManager.shared.duckMusic(false)
        }
        .onChange(of: session.reviveToken) { _ in
            scene.revivePlayer()
            scene.isPaused = false
            AudioManager.shared.duckMusic(false)
        }
        .onChange(of: session.isPaused) { paused in
            if !session.isGameOver {
                scene.isPaused = paused
                AudioManager.shared.duckMusic(paused)
            }
        }
        .onChange(of: session.isGameOver) { isOver in
            if isOver {
                scene.isPaused = true
                AudioManager.shared.duckMusic(true)
                if !session.canRevive { _ = session.commitRun() }
            }
        }
    }

    private var hud: some View {
        VStack {
            HStack(alignment: .top, spacing: 11) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(session.formatted(session.elapsed))
                        .font(.system(size: 26, weight: .light, design: .monospaced))
                    Text("BEST  \(session.formatted(session.bestTime))")
                        .font(.caption2.weight(.semibold)).foregroundStyle(.pink)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(session.score)")
                        .font(.system(.headline, design: .monospaced).bold())
                        .foregroundStyle(.yellow)
                    if session.combo > 1 {
                        Text("x\(session.combo) COMBO")
                            .font(.caption2.bold()).foregroundStyle(.cyan)
                    } else {
                        Text("STAGE \(session.difficultyStage)")
                            .font(.caption2.bold()).foregroundStyle(.purple)
                    }
                }

                Button {
                    session.isPaused.toggle()
                    scene.isPaused = session.isPaused
                    AudioManager.shared.duckMusic(session.isPaused)
                } label: {
                    Image(systemName: session.isPaused ? "play.fill" : "pause.fill")
                        .padding(11).background(.black.opacity(0.45), in: Circle())
                }
                .foregroundStyle(.white)
                .disabled(isStarting)
                .accessibilityIdentifier("game.pause")
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            HStack(spacing: 12) {
                metric("circle.grid.cross.fill", "\(session.echoCount)", .cyan)
                metric("diamond.fill", "\(session.shardsCollected)", .yellow)
                metric("bolt.fill", "\(session.closeCalls)", .orange)
                if session.difficultyStage >= AppConfig.Game.hazardStartStage {
                    metric("scope", "\(session.hazardsDodged)", .pink)
                }
                Spacer()
            }
            .padding(.horizontal, 16)

            if let boss = session.activeBossEncounterTitle {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                    Text(LocalizedStringKey(boss)).font(.caption.bold()).tracking(1.4)
                }
                .foregroundStyle(.pink)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(.black.opacity(0.58), in: Capsule())
                .overlay(Capsule().stroke(.pink.opacity(0.55), lineWidth: 1))
                .shadow(color: .pink.opacity(0.35), radius: 12)
                .accessibilityIdentifier("game.bossEncounter")
            }

            if let event = session.activeArenaEventTitle {
                HStack(spacing: 8) {
                    Image(systemName: "wave.3.right.circle.fill")
                    Text(LocalizedStringKey(event)).font(.caption.bold()).tracking(1.4)
                }
                .foregroundStyle(.yellow)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(.black.opacity(0.52), in: Capsule())
                .overlay(Capsule().stroke(.yellow.opacity(0.4), lineWidth: 1))
                .shadow(color: .yellow.opacity(0.25), radius: 10)
                .accessibilityIdentifier("game.arenaEvent")
            }

            Spacer()

            if let tutorialStep = session.tutorialStep, tutorialStep != .complete {
                VStack(spacing: 4) {
                    Text(LocalizedStringKey(tutorialStep.title)).font(.caption.bold()).foregroundStyle(.green)
                    Text(LocalizedStringKey(tutorialStep.detail)).font(.caption2).foregroundStyle(.white.opacity(0.68))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.black.opacity(0.48), in: RoundedRectangle(cornerRadius: 15))
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(.green.opacity(0.38), lineWidth: 1))
                .padding(.horizontal, 24)
                .accessibilityIdentifier("game.tutorialCoach")
            }

            HStack(alignment: .bottom) {
                if settings.tutorialHints {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(session.difficultyStage >= AppConfig.Game.hazardStartStage ? "PINK PULSES ARE LETHAL" : "DRAG TO MOVE")
                            .font(.caption2.bold())
                        Text("Echo every \(session.currentEchoInterval, specifier: "%.1f")s")
                            .font(.caption2).foregroundStyle(.white.opacity(0.48))
                    }
                    .padding(10)
                    .background(.black.opacity(0.32), in: RoundedRectangle(cornerRadius: 14))
                }
                Spacer()
                dashButton
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 18)
        }
        .foregroundStyle(.white)
    }

    private func metric(_ symbol: String, _ value: String, _ color: Color) -> some View {
        Label(value, systemImage: symbol)
            .font(.caption.bold())
            .foregroundStyle(color)
    }

    private var dashButton: some View {
        Button { scene.performDash() } label: {
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(session.canDash ? 0.2 : 0.08))
                    .frame(width: 72, height: 72)
                    .overlay(Circle().stroke(Color.cyan.opacity(session.canDash ? 0.95 : 0.25), lineWidth: 1.5))
                    .shadow(color: .cyan.opacity(session.canDash ? 0.6 : 0.12), radius: 12)
                if session.canDash {
                    Image(systemName: "forward.fill").font(.title2)
                } else {
                    Text(String(format: "%.1f", session.dashCooldownRemaining))
                        .font(.system(.subheadline, design: .monospaced).bold())
                }
            }
        }
        .foregroundStyle(.white)
        .disabled(!session.canDash || isStarting)
        .accessibilityLabel("Dash")
        .accessibilityIdentifier("game.dash")
    }

    private var countdownOverlay: some View {
        ZStack {
            Color.black.opacity(0.28).ignoresSafeArea()
            VStack(spacing: 10) {
                Text(countdown > 0 ? "\(countdown)" : "RUN")
                    .font(.system(size: 76, weight: .black, design: .rounded))
                    .foregroundStyle(countdown > 0 ? .white : .cyan)
                    .shadow(color: .cyan, radius: 18)
                Text("YOUR PAST STARTS RECORDING NOW")
                    .font(.caption.bold()).tracking(2).foregroundStyle(.white.opacity(0.6))
            }
        }
        .allowsHitTesting(false)
    }

    private var pauseOverlay: some View {
        ZStack {
            Color.black.opacity(0.68).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("PAUSED").font(.largeTitle.bold())
                Text("Simulation time is frozen with your echoes.")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.55))
                Button("RESUME") {
                    AudioManager.shared.play(.tap)
                    session.isPaused = false
                    scene.isPaused = false
                    AudioManager.shared.duckMusic(false)
                }
                .buttonStyle(NeonButtonStyle(tint: .cyan))

                Button("ABANDON RUN") { transitionHome() }
                    .buttonStyle(NeonButtonStyle(tint: .purple))
            }
            .padding(32)
        }
    }

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.84).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 15) {
                    Text(isPotentialRecord ? "NEW RECORD" : "GAME OVER")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(isPotentialRecord ? .yellow : .pink)
                        .shadow(color: isPotentialRecord ? .yellow : .pink, radius: 10)

                    VStack(spacing: 8) {
                        stat("SCORE", "\(session.score)")
                        stat("TIME SURVIVED", session.formatted(session.elapsed))
                        stat("STAGE", "\(session.difficultyStage)")
                        stat("ECHOS CREATED", "\(session.echoCount)")
                        stat("SHARDS", "\(session.shardsCollected)")
                        stat("CLOSE CALLS", "\(session.closeCalls)")
                        stat("HAZARDS DODGED", "\(session.hazardsDodged)")
                        stat("SPECIAL ECHOS", "\(session.specialEchoesCreated)")
                        stat("ARENA EVENTS", "\(session.arenaEventsSurvived)")
                        stat("BOSS ENCOUNTERS", "\(session.bossEncountersSurvived)")
                    }
                    .padding(18)
                    .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 22))

                    rewardCard

                    if session.canRevive {
                        Button { session.revive() } label: {
                            Label(reviveLabel, systemImage: "heart.fill")
                        }
                        .buttonStyle(NeonButtonStyle(tint: .pink))
                    }

                    Button("RETRY") { transitionToRetry() }
                        .buttonStyle(NeonButtonStyle(tint: .cyan))
                        .accessibilityIdentifier("game.retry")
                    Button("HOME") { transitionHome() }
                        .buttonStyle(NeonButtonStyle(tint: .purple))
                        .accessibilityIdentifier("game.home")
                }
                .padding(28)
                .padding(.top, 28)
            }
        }
    }

    private var isPotentialRecord: Bool {
        session.didSetNewBest || session.didSetNewHighScore || session.elapsed > session.bestTime || session.score > session.bestScore
    }

    private var rewardCard: some View {
        let projected = session.projectedReward
        let coins = session.runCoinsEarned > 0 ? session.runCoinsEarned : projected.coins
        let xp = session.runXPEarned > 0 ? session.runXPEarned : projected.xp
        return HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(session.runCoinsEarned > 0 ? "RUN REWARD" : "PROJECTED REWARD")
                    .font(.caption2.bold()).foregroundStyle(.white.opacity(0.48))
                HStack(spacing: 5) {
                    Image(systemName: "hexagon.fill").foregroundStyle(.yellow)
                    Text("+\(coins)").font(.headline.monospacedDigit())
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text("XP").font(.caption2.bold()).foregroundStyle(.white.opacity(0.48))
                Text("+\(xp)").font(.headline.monospacedDigit()).foregroundStyle(.cyan)
            }
        }
        .padding(16)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 18))
    }

    private var reviveLabel: String { "FREE REVIVE" }

    private func beginCountdown() {
        let token = UUID()
        countdownGeneration = token
        isStarting = true
        countdown = 3
        session.isPaused = true
        scene.isPaused = true
        AudioManager.shared.duckMusic(false)

        Task { @MainActor in
            for value in [3, 2, 1] {
                guard countdownGeneration == token else { return }
                countdown = value
                Haptics.echoSpawn()
                AudioManager.shared.play(.tap)
                try? await Task.sleep(nanoseconds: 650_000_000)
            }
            guard countdownGeneration == token else { return }
            countdown = 0
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard countdownGeneration == token else { return }
            isStarting = false
            session.isPaused = false
            scene.isPaused = false
        }
    }

    private func transitionToRetry() {
        finalizeRunTransition()
        session.startNewRun(tutorial: session.isTutorialRun)
        adRegisteredForRun = false
        scene.resetSceneState()
        scene.isPaused = true
        AudioManager.shared.duckMusic(false)
        beginCountdown()
    }

    private func transitionHome() {
        finalizeRunTransition()
        AudioManager.shared.duckMusic(false)
        home()
    }

    private func finalizeRunTransition() {
        let wasGameOver = session.isGameOver
        _ = session.commitRun()
        guard wasGameOver, !adRegisteredForRun else { return }
        adRegisteredForRun = true
    }

    private func stat(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).font(.caption).foregroundStyle(.white.opacity(0.58))
            Spacer()
            Text(value).font(.headline.monospacedDigit())
        }
    }
}
