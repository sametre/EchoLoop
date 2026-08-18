import Foundation

enum ArenaEventKind: String, Codable, CaseIterable, Identifiable {
    case signalBlackout
    case overdrive
    case shardStorm

    var id: String { rawValue }

    var title: String {
        switch self {
        case .signalBlackout: return "SIGNAL BLACKOUT"
        case .overdrive: return "ECHO OVERDRIVE"
        case .shardStorm: return "SHARD STORM"
        }
    }

    var symbol: String {
        switch self {
        case .signalBlackout: return "moon.stars.fill"
        case .overdrive: return "bolt.horizontal.fill"
        case .shardStorm: return "diamond.fill"
        }
    }

    var duration: TimeInterval {
        switch self {
        case .signalBlackout: return 4.4
        case .overdrive: return 5.0
        case .shardStorm: return 4.0
        }
    }
}

struct ArenaEventDirector {
    static func interval(stage: Int) -> TimeInterval {
        max(15.0, 24.0 - Double(max(0, stage - 4)) * 1.35)
    }

    static func event(forIndex index: Int, stage: Int) -> ArenaEventKind {
        let events: [ArenaEventKind]
        if stage < 5 {
            events = [.shardStorm, .signalBlackout]
        } else {
            events = ArenaEventKind.allCases
        }
        return events[max(0, index) % events.count]
    }
}
