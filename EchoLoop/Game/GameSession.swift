import Combine
import Foundation

@MainActor
final class GameSession: ObservableObject {
    @Published var elapsed: TimeInterval = 0
    @Published var echoCount = 0
    @Published var closeCalls = 0
    @Published var shardsCollected = 0
    @Published var dashesUsed = 0
    @Published var hazardsDodged = 0
    @Published var specialEchoesCreated = 0
    @Published var arenaEventsSurvived = 0
    @Published var bossEncountersSurvived = 0
    @Published var activeArenaEventTitle: String?
    @Published var activeBossEncounterTitle: String?
    @Published var isTutorialRun = false
    @Published var difficultyStage = 1
    @Published var dashCooldownRemaining: TimeInterval = 0
    @Published var score = 0
    @Published var combo = 1
    @Published var isGameOver = false
    @Published var isPaused = false
    @Published var canRevive = true
    @Published var reviveToken = UUID()
    @Published private(set) var runCoinsEarned = 0
    @Published private(set) var runXPEarned = 0
    @Published private(set) var didSetNewBest = false
    @Published private(set) var didSetNewHighScore = false

    private var committed = false
    private var comboTimeout: TimeInterval = 0
    private let profile = PlayerProfile.shared

    var bestTime: TimeInterval { profile.bestTime }
    var bestScore: Int { profile.bestScore }
    var canDash: Bool { dashCooldownRemaining <= 0.01 && !isGameOver && !isPaused }
    var scoreMultiplier: Int { max(1, combo) }

    var currentEchoInterval: TimeInterval { GameRules.echoInterval(stage: difficultyStage) }

    var projectedReward: RunReward {
        profile.projectedReward(elapsed: elapsed, closeCalls: closeCalls, shards: shardsCollected, score: score)
    }

    func startNewRun(tutorial: Bool = false) {
        elapsed = 0
        echoCount = 0
        closeCalls = 0
        shardsCollected = 0
        dashesUsed = 0
        hazardsDodged = 0
        specialEchoesCreated = 0
        arenaEventsSurvived = 0
        bossEncountersSurvived = 0
        activeArenaEventTitle = nil
        activeBossEncounterTitle = nil
        isTutorialRun = tutorial
        difficultyStage = 1
        dashCooldownRemaining = 0
        score = 0
        combo = 1
        comboTimeout = 0
        isGameOver = false
        isPaused = false
        canRevive = true
        runCoinsEarned = 0
        runXPEarned = 0
        didSetNewBest = false
        didSetNewHighScore = false
        committed = false
        AnalyticsManager.shared.track(.runStarted)
    }

    func tick(delta: TimeInterval) {
        elapsed += delta
        updateStage()
        if combo > 1 {
            comboTimeout -= delta
            if comboTimeout <= 0 { combo = 1 }
        }
        score += Int(delta * GameRules.scorePointsPerSecond(stage: difficultyStage))
        if isTutorialRun, TutorialRunCoordinator.step(elapsed: elapsed, dashes: dashesUsed, shards: shardsCollected, echoes: echoCount) == .complete {
            profile.markTutorialRunCompleted()
        }
    }

    func registerEchoSpawn(kind: EchoKind = .classic) {
        echoCount += 1
        if kind.isSpecial { specialEchoesCreated += 1 }
        score += (25 * difficultyStage) + kind.spawnScoreBonus
    }

    func arenaEventStarted(_ kind: ArenaEventKind) {
        activeArenaEventTitle = kind.title
        AnalyticsManager.shared.track(.arenaEventStarted, properties: ["event": kind.rawValue, "stage": difficultyStage])
    }

    func arenaEventFinished(_ kind: ArenaEventKind, survived: Bool) {
        if activeArenaEventTitle == kind.title { activeArenaEventTitle = nil }
        guard survived else { return }
        arenaEventsSurvived += 1
        increaseCombo()
        score += 220 * scoreMultiplier
    }


    var tutorialStep: TutorialRunStep? {
        guard isTutorialRun else { return nil }
        return TutorialRunCoordinator.step(elapsed: elapsed, dashes: dashesUsed, shards: shardsCollected, echoes: echoCount)
    }

    func bossEncounterStarted(_ boss: BossEchoKind) {
        activeBossEncounterTitle = boss.title
        AnalyticsManager.shared.track(.arenaEventStarted, properties: ["boss": boss.rawValue, "stage": difficultyStage])
    }

    func bossEncounterFinished(_ boss: BossEchoKind, survived: Bool) {
        if activeBossEncounterTitle == boss.title { activeBossEncounterTitle = nil }
        guard survived else { return }
        bossEncountersSurvived += 1
        increaseCombo()
        score += boss.survivalScoreReward * scoreMultiplier
    }

    func registerShard() {
        shardsCollected += 1
        increaseCombo()
        score += 100 * scoreMultiplier
    }

    func registerCloseCall() {
        closeCalls += 1
        increaseCombo()
        score += 70 * scoreMultiplier
    }

    func registerDash() {
        dashesUsed += 1
        score += 12 * scoreMultiplier
    }

    func registerHazardDodge() {
        hazardsDodged += 1
        increaseCombo()
        score += 140 * scoreMultiplier
    }

    func finishLife() {
        guard !isGameOver else { return }
        isGameOver = true
        combo = 1
    }

    @discardableResult
    func commitRun() -> Bool {
        guard !committed, elapsed > 0.5 else { return false }
        committed = true
        let previousBest = profile.bestTime
        let previousScore = profile.bestScore
        let reward = profile.recordRun(
            elapsed: elapsed,
            echoes: echoCount,
            closeCalls: closeCalls,
            shards: shardsCollected,
            dashes: dashesUsed,
            stage: difficultyStage,
            score: score,
            specialEchoes: specialEchoesCreated,
            arenaEvents: arenaEventsSurvived,
            bossEncounters: bossEncountersSurvived
        )
        runCoinsEarned = reward.coins
        runXPEarned = reward.xp
        didSetNewBest = elapsed > previousBest
        didSetNewHighScore = score > previousScore
        GameCenterManager.shared.submitRun(seconds: elapsed, echoes: echoCount, closeCalls: closeCalls)
        GameCenterManager.shared.syncProfileAchievements(profile)
        CloudSyncManager.shared.schedulePush(reason: "run_completed")
        AnalyticsManager.shared.track(.runCompleted, properties: [
            "seconds": String(format: "%.2f", elapsed),
            "score": score,
            "stage": difficultyStage,
            "echoes": echoCount,
            "shards": shardsCollected,
            "close_calls": closeCalls,
            "special_echoes": specialEchoesCreated,
            "arena_events": arenaEventsSurvived,
            "boss_encounters": bossEncountersSurvived,
            "tutorial": isTutorialRun ? "true" : "false",
            "revived": canRevive ? "false" : "true"
        ])
        ReviewManager.shared.considerPrompt(totalRuns: profile.lifetimeRuns, bestTime: profile.bestTime)
        return true
    }

    func revive() {
        guard isGameOver, canRevive else { return }
        canRevive = false
        isGameOver = false
        isPaused = false
        dashCooldownRemaining = 0
        combo = 1
        reviveToken = UUID()
        AnalyticsManager.shared.track(.reviveUsed)
    }

    func updateStage() {
        difficultyStage = GameRules.stage(for: elapsed)
    }

    func pauseForInterruption() {
        guard !isGameOver else { return }
        isPaused = true
    }

    func formatted(_ value: TimeInterval) -> String {
        let safe = max(0, value)
        let minutes = Int(safe) / 60
        let seconds = Int(safe) % 60
        let centis = Int((safe - floor(safe)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, centis)
    }

    private func increaseCombo() {
        combo = min(AppConfig.Game.maximumCombo, combo + 1)
        comboTimeout = AppConfig.Game.comboLifetime
    }
}
