import Foundation

struct AchievementDefinition: Identifiable, Hashable {
    enum Metric: Hashable {
        case bestTime(Double)
        case highestStage(Int)
        case lifetimeShards(Int)
        case lifetimeDashes(Int)
        case lifetimeSpecialEchoes(Int)
        case lifetimeArenaEvents(Int)
        case lifetimeBossEncounters(Int)
    }

    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let metric: Metric

    func progress(using snapshot: AchievementSnapshot) -> Double {
        switch metric {
        case .bestTime(let target): return min(1, snapshot.bestTime / max(1, target))
        case .highestStage(let target): return min(1, Double(snapshot.highestStage) / Double(max(1, target)))
        case .lifetimeShards(let target): return min(1, Double(snapshot.lifetimeShards) / Double(max(1, target)))
        case .lifetimeDashes(let target): return min(1, Double(snapshot.lifetimeDashes) / Double(max(1, target)))
        case .lifetimeSpecialEchoes(let target): return min(1, Double(snapshot.lifetimeSpecialEchoes) / Double(max(1, target)))
        case .lifetimeArenaEvents(let target): return min(1, Double(snapshot.lifetimeArenaEvents) / Double(max(1, target)))
        case .lifetimeBossEncounters(let target): return min(1, Double(snapshot.lifetimeBossEncounters) / Double(max(1, target)))
        }
    }

    func currentValue(using snapshot: AchievementSnapshot) -> String {
        switch metric {
        case .bestTime(let target): return "\(Int(snapshot.bestTime))/\(Int(target))s"
        case .highestStage(let target): return "\(snapshot.highestStage)/\(target)"
        case .lifetimeShards(let target): return "\(snapshot.lifetimeShards)/\(target)"
        case .lifetimeDashes(let target): return "\(snapshot.lifetimeDashes)/\(target)"
        case .lifetimeSpecialEchoes(let target): return "\(snapshot.lifetimeSpecialEchoes)/\(target)"
        case .lifetimeArenaEvents(let target): return "\(snapshot.lifetimeArenaEvents)/\(target)"
        case .lifetimeBossEncounters(let target): return "\(snapshot.lifetimeBossEncounters)/\(target)"
        }
    }
}

struct AchievementSnapshot: Equatable {
    let bestTime: TimeInterval
    let highestStage: Int
    let lifetimeShards: Int
    let lifetimeDashes: Int
    let lifetimeSpecialEchoes: Int
    let lifetimeArenaEvents: Int
    let lifetimeBossEncounters: Int
}

enum AchievementCatalog {
    static let all: [AchievementDefinition] = [
        .init(id: "survive60", title: "FIRST MINUTE", subtitle: "Survive for 60 seconds", symbol: "timer", metric: .bestTime(60)),
        .init(id: "survive120", title: "TIME BENDER", subtitle: "Survive for 120 seconds", symbol: "hourglass", metric: .bestTime(120)),
        .init(id: "stage6", title: "DEEP LOOP", subtitle: "Reach stage 6", symbol: "waveform.path.ecg", metric: .highestStage(6)),
        .init(id: "shards100", title: "SHARD ARCHIVE", subtitle: "Collect 100 shards", symbol: "diamond.fill", metric: .lifetimeShards(100)),
        .init(id: "dashes100", title: "PHASE RUNNER", subtitle: "Use dash 100 times", symbol: "forward.fill", metric: .lifetimeDashes(100)),
        .init(id: "specialEchoes50", title: "STRANGE PAST", subtitle: "Create 50 special echoes", symbol: "sparkles", metric: .lifetimeSpecialEchoes(50)),
        .init(id: "arenaEvents25", title: "STORM WALKER", subtitle: "Survive 25 arena events", symbol: "bolt.circle.fill", metric: .lifetimeArenaEvents(25)),
        .init(id: "bossEncounters10", title: "WARDEN BREAKER", subtitle: "Survive 10 boss encounters", symbol: "crown.fill", metric: .lifetimeBossEncounters(10))
    ]
}
