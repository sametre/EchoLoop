import Combine
import Foundation

struct RunReward: Equatable {
    let coins: Int
    let xp: Int
}

enum ChallengeMetric: String, Codable, Hashable {
    case surviveSeconds
    case echoCount
    case closeCalls
    case shardsCollected
}

struct DailyChallenge: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let metric: ChallengeMetric
    let target: Int
    let reward: Int

    static let rotation: [DailyChallenge] = [
        .init(id: "survive_45", title: "STAY ALIVE", subtitle: "Survive 45 seconds in one run", symbol: "timer", metric: .surviveSeconds, target: 45, reward: 120),
        .init(id: "echo_8", title: "FACE YOUR PAST", subtitle: "Create 8 echoes in one run", symbol: "circle.grid.cross", metric: .echoCount, target: 8, reward: 100),
        .init(id: "close_6", title: "TOO CLOSE", subtitle: "Make 6 close calls in one run", symbol: "bolt.fill", metric: .closeCalls, target: 6, reward: 110),
        .init(id: "shard_8", title: "SHARD HUNTER", subtitle: "Collect 8 shards today", symbol: "diamond.fill", metric: .shardsCollected, target: 8, reward: 130),
        .init(id: "survive_75", title: "TIME BENDER", subtitle: "Survive 75 seconds in one run", symbol: "hourglass", metric: .surviveSeconds, target: 75, reward: 180),
        .init(id: "echo_12", title: "ECHO STORM", subtitle: "Create 12 echoes in one run", symbol: "hurricane", metric: .echoCount, target: 12, reward: 170)
    ]
}

@MainActor
final class PlayerProfile: ObservableObject {
    static let shared = PlayerProfile()

    @Published private(set) var save: SaveData
    @Published private(set) var recoveredFromBackup = false
    @Published private(set) var lastLoadSource = "new"
    @Published private(set) var lastSaveSucceeded = true

    struct SaveData: Codable, Equatable {
        var schemaVersion: Int = 10
        var coins: Int = 300
        var xp: Int = 0
        var bestTime: TimeInterval = 0
        var bestScore: Int = 0
        var lifetimeRuns: Int = 0
        var lifetimeSeconds: TimeInterval = 0
        var lifetimeShards: Int = 0
        var lifetimeCloseCalls: Int = 0
        var lifetimeDashes: Int = 0
        var highestStage: Int = 1
        var lifetimeSpecialEchoes: Int = 0
        var lifetimeArenaEvents: Int = 0
        var lifetimeBossEncounters: Int = 0
        var seasonID: String = SeasonProgression.seasonID
        var seasonXP: Int = 0
        var claimedSeasonTiers: Set<Int> = []
        var tutorialRunCompleted: Bool = false
        var syncRevision: Int = 0
        var lastModified: TimeInterval = 0

        var ownedOrbs: Set<String> = ["core"]
        var ownedTrails: Set<String> = ["ice"]
        var ownedArenas: Set<String> = ["deep_space"]
        var selectedOrbID: String = "core"
        var selectedTrailID: String = "ice"
        var selectedArenaID: String = "deep_space"

        var challengeDayKey: String = ""
        var challengeProgress: [String: Int] = [:]
        var claimedChallenges: Set<String> = []

        var lastDailyClaimKey: String = ""
        var loginStreak: Int = 0

        enum CodingKeys: String, CodingKey {
            case schemaVersion, coins, xp, bestTime, bestScore, lifetimeRuns, lifetimeSeconds
            case lifetimeShards, lifetimeCloseCalls, lifetimeDashes, highestStage
            case lifetimeSpecialEchoes, lifetimeArenaEvents, lifetimeBossEncounters
            case seasonID, seasonXP, claimedSeasonTiers, tutorialRunCompleted, syncRevision, lastModified
            case ownedOrbs, ownedTrails, ownedArenas, selectedOrbID, selectedTrailID, selectedArenaID
            case challengeDayKey, challengeProgress, claimedChallenges
            case lastDailyClaimKey, loginStreak
        }

        init() {}

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            schemaVersion = try c.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 2
            coins = try c.decodeIfPresent(Int.self, forKey: .coins) ?? 300
            xp = try c.decodeIfPresent(Int.self, forKey: .xp) ?? 0
            bestTime = try c.decodeIfPresent(TimeInterval.self, forKey: .bestTime) ?? 0
            bestScore = try c.decodeIfPresent(Int.self, forKey: .bestScore) ?? 0
            lifetimeRuns = try c.decodeIfPresent(Int.self, forKey: .lifetimeRuns) ?? 0
            lifetimeSeconds = try c.decodeIfPresent(TimeInterval.self, forKey: .lifetimeSeconds) ?? 0
            lifetimeShards = try c.decodeIfPresent(Int.self, forKey: .lifetimeShards) ?? 0
            lifetimeCloseCalls = try c.decodeIfPresent(Int.self, forKey: .lifetimeCloseCalls) ?? 0
            lifetimeDashes = try c.decodeIfPresent(Int.self, forKey: .lifetimeDashes) ?? 0
            highestStage = try c.decodeIfPresent(Int.self, forKey: .highestStage) ?? 1
            lifetimeSpecialEchoes = try c.decodeIfPresent(Int.self, forKey: .lifetimeSpecialEchoes) ?? 0
            lifetimeArenaEvents = try c.decodeIfPresent(Int.self, forKey: .lifetimeArenaEvents) ?? 0
            lifetimeBossEncounters = try c.decodeIfPresent(Int.self, forKey: .lifetimeBossEncounters) ?? 0
            seasonID = try c.decodeIfPresent(String.self, forKey: .seasonID) ?? SeasonProgression.seasonID
            seasonXP = try c.decodeIfPresent(Int.self, forKey: .seasonXP) ?? 0
            claimedSeasonTiers = try c.decodeIfPresent(Set<Int>.self, forKey: .claimedSeasonTiers) ?? []
            tutorialRunCompleted = try c.decodeIfPresent(Bool.self, forKey: .tutorialRunCompleted) ?? false
            syncRevision = try c.decodeIfPresent(Int.self, forKey: .syncRevision) ?? 0
            lastModified = try c.decodeIfPresent(TimeInterval.self, forKey: .lastModified) ?? 0
            ownedOrbs = try c.decodeIfPresent(Set<String>.self, forKey: .ownedOrbs) ?? ["core"]
            ownedTrails = try c.decodeIfPresent(Set<String>.self, forKey: .ownedTrails) ?? ["ice"]
            ownedArenas = try c.decodeIfPresent(Set<String>.self, forKey: .ownedArenas) ?? ["deep_space"]
            selectedOrbID = try c.decodeIfPresent(String.self, forKey: .selectedOrbID) ?? "core"
            selectedTrailID = try c.decodeIfPresent(String.self, forKey: .selectedTrailID) ?? "ice"
            selectedArenaID = try c.decodeIfPresent(String.self, forKey: .selectedArenaID) ?? "deep_space"
            challengeDayKey = try c.decodeIfPresent(String.self, forKey: .challengeDayKey) ?? ""
            challengeProgress = try c.decodeIfPresent([String: Int].self, forKey: .challengeProgress) ?? [:]
            claimedChallenges = try c.decodeIfPresent(Set<String>.self, forKey: .claimedChallenges) ?? []
            lastDailyClaimKey = try c.decodeIfPresent(String.self, forKey: .lastDailyClaimKey) ?? ""
            loginStreak = try c.decodeIfPresent(Int.self, forKey: .loginStreak) ?? 0
        }
    }

    private let saveKey = "echo.profile.v10"
    private let backupKey = "echo.profile.v10.backup"
    private let legacySaveKeys = ["echo.profile.v6", "echo.profile.v5", "echo.profile.v4", "echo.profile.v3", "echo.profile.v2"]
    private let defaults = UserDefaults.standard
    private let persistence = ProfilePersistence.shared

    private init() {
        let result: PersistenceLoadResult<SaveData> = persistence.load(
            SaveData.self,
            primaryKey: saveKey,
            backupKey: backupKey,
            legacyKeys: legacySaveKeys
        )

        if let loaded = result.value {
            save = loaded
        } else {
            save = SaveData()
            let legacyBest = defaults.double(forKey: "echo.best.seconds")
            if legacyBest > 0 { save.bestTime = legacyBest }
        }

        recoveredFromBackup = result.recoveredFromBackup
        lastLoadSource = result.source
        sanitizeState()
        prepareDailyChallenges()
        persist()
    }

    var coins: Int { save.coins }
    var xp: Int { save.xp }
    var bestTime: TimeInterval { save.bestTime }
    var bestScore: Int { save.bestScore }
    var lifetimeRuns: Int { save.lifetimeRuns }
    var lifetimeSeconds: TimeInterval { save.lifetimeSeconds }
    var lifetimeShards: Int { save.lifetimeShards }
    var lifetimeCloseCalls: Int { save.lifetimeCloseCalls }
    var lifetimeDashes: Int { save.lifetimeDashes }
    var highestStage: Int { save.highestStage }
    var lifetimeSpecialEchoes: Int { save.lifetimeSpecialEchoes }
    var lifetimeArenaEvents: Int { save.lifetimeArenaEvents }
    var lifetimeBossEncounters: Int { save.lifetimeBossEncounters }
    var seasonXP: Int { save.seasonXP }
    var seasonTier: Int { SeasonProgression.currentTier(for: save.seasonXP) }
    var seasonProgress: Double { SeasonProgression.progressToNextTier(for: save.seasonXP) }
    var tutorialRunCompleted: Bool { save.tutorialRunCompleted }
    var syncRevision: Int { save.syncRevision }
    var lastModified: TimeInterval { save.lastModified }
    var loginStreak: Int { save.loginStreak }
    var selectedOrb: OrbCosmetic { OrbCosmetic.item(save.selectedOrbID) }
    var selectedTrail: TrailCosmetic { TrailCosmetic.item(save.selectedTrailID) }
    var selectedArena: ArenaCosmetic { ArenaCosmetic.item(save.selectedArenaID) }

    var level: Int { max(1, save.xp / 500 + 1) }
    var xpIntoLevel: Int { save.xp % 500 }
    var levelProgress: Double { Double(xpIntoLevel) / 500.0 }

    var dailyRewardAvailable: Bool { save.lastDailyClaimKey != Self.dayKey(for: Date()) }
    var nextDailyReward: Int {
        let candidate = projectedStreakForToday
        let rewards = [50, 75, 100, 125, 150, 200, 300]
        return rewards[(max(1, candidate) - 1) % rewards.count]
    }

    var dailyChallenges: [DailyChallenge] {
        let all = DailyChallenge.rotation
        guard !all.isEmpty else { return [] }
        let seed = daySeed
        return (0..<3).map { all[(seed + $0 * 2) % all.count] }
    }

    func progress(for challenge: DailyChallenge) -> Int {
        min(save.challengeProgress[challenge.id] ?? 0, challenge.target)
    }

    func isClaimed(_ challenge: DailyChallenge) -> Bool { save.claimedChallenges.contains(challenge.id) }
    func canClaim(_ challenge: DailyChallenge) -> Bool { progress(for: challenge) >= challenge.target && !isClaimed(challenge) }

    @discardableResult
    func claim(_ challenge: DailyChallenge) -> Bool {
        guard canClaim(challenge) else { return false }
        save.claimedChallenges.insert(challenge.id)
        save.coins += challenge.reward
        persist()
        Haptics.success()
        AudioManager.shared.play(.shard)
        AnalyticsManager.shared.track(.missionClaimed, properties: ["mission": challenge.id, "reward": challenge.reward])
        return true
    }

    @discardableResult
    func claimDailyReward() -> Int? {
        guard dailyRewardAvailable else { return nil }
        let todayKey = Self.dayKey(for: Date())
        let reward = nextDailyReward
        save.loginStreak = projectedStreakForToday
        save.lastDailyClaimKey = todayKey
        save.coins += reward
        persist()
        Haptics.success()
        AudioManager.shared.play(.levelUp)
        AnalyticsManager.shared.track(.dailyRewardClaimed, properties: ["streak": save.loginStreak, "coins": reward])
        return reward
    }

    func projectedReward(elapsed: TimeInterval, closeCalls: Int, shards: Int, score: Int = 0) -> RunReward {
        RewardCalculator.reward(elapsed: elapsed, closeCalls: closeCalls, shards: shards, score: score)
    }

    @discardableResult
    func recordRun(elapsed: TimeInterval, echoes: Int, closeCalls: Int, shards: Int, dashes: Int, stage: Int, score: Int, specialEchoes: Int = 0, arenaEvents: Int = 0, bossEncounters: Int = 0) -> RunReward {
        prepareDailyChallenges()
        let reward = projectedReward(elapsed: elapsed, closeCalls: closeCalls, shards: shards, score: score)
        save.coins += reward.coins
        save.xp += reward.xp
        save.lifetimeRuns += 1
        save.lifetimeSeconds += max(0, elapsed)
        save.lifetimeShards += max(0, shards)
        save.lifetimeCloseCalls += max(0, closeCalls)
        save.lifetimeDashes += max(0, dashes)
        save.bestTime = max(save.bestTime, elapsed)
        save.bestScore = max(save.bestScore, score)
        save.highestStage = max(save.highestStage, stage)
        save.lifetimeSpecialEchoes += max(0, specialEchoes)
        save.lifetimeArenaEvents += max(0, arenaEvents)
        save.lifetimeBossEncounters += max(0, bossEncounters)
        if save.seasonID != SeasonProgression.seasonID {
            save.seasonID = SeasonProgression.seasonID
            save.seasonXP = 0
            save.claimedSeasonTiers = []
        }
        save.seasonXP += SeasonProgression.xpForRun(elapsed: elapsed, stage: stage, score: score, bossEncounters: bossEncounters)

        for challenge in dailyChallenges {
            let previous = save.challengeProgress[challenge.id] ?? 0
            let next: Int
            switch challenge.metric {
            case .surviveSeconds: next = max(previous, Int(max(0, elapsed)))
            case .echoCount: next = max(previous, max(0, echoes))
            case .closeCalls: next = max(previous, max(0, closeCalls))
            case .shardsCollected: next = previous + max(0, shards)
            }
            save.challengeProgress[challenge.id] = min(next, challenge.target)
        }
        persist()
        return reward
    }


    func isSeasonTierClaimed(_ tierID: Int) -> Bool {
        save.claimedSeasonTiers.contains(tierID)
    }

    @discardableResult
    func claimSeasonTier(_ tierID: Int) -> Bool {
        guard let tier = SeasonProgression.tiers.first(where: { $0.id == tierID }),
              save.seasonXP >= tier.requiredXP,
              !save.claimedSeasonTiers.contains(tierID) else { return false }
        save.claimedSeasonTiers.insert(tierID)
        save.coins += tier.coinReward
        persist()
        Haptics.success()
        AudioManager.shared.play(.levelUp)
        return true
    }

    func markTutorialRunCompleted() {
        guard !save.tutorialRunCompleted else { return }
        save.tutorialRunCompleted = true
        persist()
    }

    func ownsOrb(_ item: OrbCosmetic) -> Bool { save.ownedOrbs.contains(item.id) }
    func ownsTrail(_ item: TrailCosmetic) -> Bool { save.ownedTrails.contains(item.id) }
    func ownsArena(_ item: ArenaCosmetic) -> Bool { save.ownedArenas.contains(item.id) }

    @discardableResult
    func buyOrb(_ item: OrbCosmetic) -> Bool {
        guard !item.premiumOnly, !ownsOrb(item), save.coins >= item.price else { return false }
        save.coins -= item.price
        save.ownedOrbs.insert(item.id)
        save.selectedOrbID = item.id
        persist()
        Haptics.success()
        return true
    }

    @discardableResult
    func buyTrail(_ item: TrailCosmetic) -> Bool {
        guard !item.premiumOnly, !ownsTrail(item), save.coins >= item.price else { return false }
        save.coins -= item.price
        save.ownedTrails.insert(item.id)
        save.selectedTrailID = item.id
        persist()
        Haptics.success()
        return true
    }

    @discardableResult
    func buyArena(_ item: ArenaCosmetic) -> Bool {
        guard !item.premiumOnly, !ownsArena(item), save.coins >= item.price else { return false }
        save.coins -= item.price
        save.ownedArenas.insert(item.id)
        save.selectedArenaID = item.id
        persist()
        Haptics.success()
        return true
    }

    func selectOrb(_ item: OrbCosmetic, premiumUnlocked: Bool) {
        guard ownsOrb(item) || (item.premiumOnly && premiumUnlocked) else { return }
        save.selectedOrbID = item.id
        persist()
        Haptics.closeCall()
        AudioManager.shared.play(.tap)
    }

    func selectTrail(_ item: TrailCosmetic, premiumUnlocked: Bool) {
        guard ownsTrail(item) || (item.premiumOnly && premiumUnlocked) else { return }
        save.selectedTrailID = item.id
        persist()
        Haptics.closeCall()
        AudioManager.shared.play(.tap)
    }

    func selectArena(_ item: ArenaCosmetic, premiumUnlocked: Bool) {
        guard ownsArena(item) || (item.premiumOnly && premiumUnlocked) else { return }
        save.selectedArenaID = item.id
        persist()
        Haptics.closeCall()
        AudioManager.shared.play(.tap)
    }

    func resetProgressForDevelopment() {
        save = SaveData()
        recoveredFromBackup = false
        lastLoadSource = "debug-reset"
        prepareDailyChallenges()
        persist()
    }

    var nextLoginStreak: Int { projectedStreakForToday }

    private var projectedStreakForToday: Int {
        guard !save.lastDailyClaimKey.isEmpty else { return 1 }
        let calendar = Calendar.autoupdatingCurrent
        let today = calendar.startOfDay(for: Date())
        guard let previous = Self.date(fromDayKey: save.lastDailyClaimKey, calendar: calendar) else { return 1 }
        let previousDay = calendar.startOfDay(for: previous)
        let difference = calendar.dateComponents([.day], from: previousDay, to: today).day ?? 0
        if difference == 0 { return max(1, save.loginStreak) }
        if difference == 1 { return max(1, save.loginStreak + 1) }
        return 1
    }

    private func prepareDailyChallenges() {
        let key = Self.dayKey(for: Date())
        guard save.challengeDayKey != key else { return }
        save.challengeDayKey = key
        save.challengeProgress = [:]
        save.claimedChallenges = []
    }

    private func sanitizeState() {
        save.schemaVersion = 10
        save.coins = max(0, save.coins)
        save.xp = max(0, save.xp)
        save.bestTime = max(0, save.bestTime)
        save.bestScore = max(0, save.bestScore)
        save.lifetimeRuns = max(0, save.lifetimeRuns)
        save.lifetimeSeconds = max(0, save.lifetimeSeconds)
        save.lifetimeShards = max(0, save.lifetimeShards)
        save.lifetimeCloseCalls = max(0, save.lifetimeCloseCalls)
        save.lifetimeDashes = max(0, save.lifetimeDashes)
        save.highestStage = max(1, save.highestStage)
        save.lifetimeSpecialEchoes = max(0, save.lifetimeSpecialEchoes)
        save.lifetimeArenaEvents = max(0, save.lifetimeArenaEvents)
        save.lifetimeBossEncounters = max(0, save.lifetimeBossEncounters)
        save.seasonXP = max(0, save.seasonXP)
        if save.seasonID != SeasonProgression.seasonID {
            save.seasonID = SeasonProgression.seasonID
            save.seasonXP = 0
            save.claimedSeasonTiers = []
        }
        let validTierIDs = Set(SeasonProgression.tiers.map(\.id))
        save.claimedSeasonTiers = save.claimedSeasonTiers.intersection(validTierIDs)
        save.syncRevision = max(0, save.syncRevision)
        save.lastModified = max(0, save.lastModified)
        save.loginStreak = max(0, save.loginStreak)

        if !OrbCosmetic.all.contains(where: { $0.id == save.selectedOrbID }) { save.selectedOrbID = "core" }
        if !TrailCosmetic.all.contains(where: { $0.id == save.selectedTrailID }) { save.selectedTrailID = "ice" }
        if !ArenaCosmetic.all.contains(where: { $0.id == save.selectedArenaID }) { save.selectedArenaID = "deep_space" }
        save.ownedOrbs.insert("core")
        save.ownedTrails.insert("ice")
        save.ownedArenas.insert("deep_space")
    }

    private var daySeed: Int {
        let chars = save.challengeDayKey.unicodeScalars.map { Int($0.value) }
        return abs(chars.reduce(0) { ($0 &* 31) &+ $1 })
    }

    var achievementSnapshot: AchievementSnapshot {
        AchievementSnapshot(
            bestTime: save.bestTime,
            highestStage: save.highestStage,
            lifetimeShards: save.lifetimeShards,
            lifetimeDashes: save.lifetimeDashes,
            lifetimeSpecialEchoes: save.lifetimeSpecialEchoes,
            lifetimeArenaEvents: save.lifetimeArenaEvents,
            lifetimeBossEncounters: save.lifetimeBossEncounters
        )
    }

    func exportSaveData() -> SaveData { save }

    @discardableResult
    func mergeCloudSave(_ remote: SaveData) -> Bool {
        let merged = Self.merged(local: save, remote: remote)
        guard merged != save else { return false }
        save = merged
        sanitizeState()
        persist(touchRevision: true)
        return true
    }

    static func merged(local: SaveData, remote: SaveData) -> SaveData {
        let remoteIsNewer = remote.lastModified > local.lastModified || (remote.lastModified == local.lastModified && remote.syncRevision > local.syncRevision)
        var result = remoteIsNewer ? remote : local

        result.schemaVersion = 10
        result.xp = max(local.xp, remote.xp)
        result.bestTime = max(local.bestTime, remote.bestTime)
        result.bestScore = max(local.bestScore, remote.bestScore)
        result.lifetimeRuns = max(local.lifetimeRuns, remote.lifetimeRuns)
        result.lifetimeSeconds = max(local.lifetimeSeconds, remote.lifetimeSeconds)
        result.lifetimeShards = max(local.lifetimeShards, remote.lifetimeShards)
        result.lifetimeCloseCalls = max(local.lifetimeCloseCalls, remote.lifetimeCloseCalls)
        result.lifetimeDashes = max(local.lifetimeDashes, remote.lifetimeDashes)
        result.highestStage = max(local.highestStage, remote.highestStage)
        result.lifetimeSpecialEchoes = max(local.lifetimeSpecialEchoes, remote.lifetimeSpecialEchoes)
        result.lifetimeArenaEvents = max(local.lifetimeArenaEvents, remote.lifetimeArenaEvents)
        result.lifetimeBossEncounters = max(local.lifetimeBossEncounters, remote.lifetimeBossEncounters)
        if local.seasonID == remote.seasonID {
            result.seasonID = local.seasonID
            result.seasonXP = max(local.seasonXP, remote.seasonXP)
            result.claimedSeasonTiers = local.claimedSeasonTiers.union(remote.claimedSeasonTiers)
        } else {
            let newer = remoteIsNewer ? remote : local
            result.seasonID = newer.seasonID
            result.seasonXP = newer.seasonXP
            result.claimedSeasonTiers = newer.claimedSeasonTiers
        }
        result.tutorialRunCompleted = local.tutorialRunCompleted || remote.tutorialRunCompleted
        result.ownedOrbs = local.ownedOrbs.union(remote.ownedOrbs)
        result.ownedTrails = local.ownedTrails.union(remote.ownedTrails)
        result.ownedArenas = local.ownedArenas.union(remote.ownedArenas)

        if local.challengeDayKey == remote.challengeDayKey {
            var progress = local.challengeProgress
            for (key, value) in remote.challengeProgress { progress[key] = max(progress[key] ?? 0, value) }
            result.challengeDayKey = local.challengeDayKey
            result.challengeProgress = progress
            result.claimedChallenges = local.claimedChallenges.union(remote.claimedChallenges)
        }

        result.syncRevision = max(local.syncRevision, remote.syncRevision)
        result.lastModified = max(local.lastModified, remote.lastModified)
        return result
    }

    private func persist(touchRevision: Bool = true) {
        if touchRevision {
            save.syncRevision += 1
            save.lastModified = Date().timeIntervalSince1970
        }
        lastSaveSucceeded = persistence.save(save, primaryKey: saveKey, backupKey: backupKey)
    }

    private static func dayKey(for date: Date) -> String {
        let calendar = Calendar.autoupdatingCurrent
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    private static func date(fromDayKey key: String, calendar: Calendar) -> Date? {
        let pieces = key.split(separator: "-").compactMap { Int($0) }
        guard pieces.count == 3 else { return nil }
        var components = DateComponents()
        components.calendar = calendar
        components.year = pieces[0]
        components.month = pieces[1]
        components.day = pieces[2]
        return calendar.date(from: components)
    }
}
