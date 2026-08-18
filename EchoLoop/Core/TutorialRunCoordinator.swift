import Foundation

enum TutorialRunStep: String, CaseIterable, Equatable {
    case move
    case dash
    case collectShard
    case meetEcho
    case survive
    case complete

    var title: String {
        switch self {
        case .move: return "MOVE THE ORB"
        case .dash: return "USE DASH"
        case .collectShard: return "COLLECT A SHARD"
        case .meetEcho: return "MEET YOUR PAST"
        case .survive: return "STAY ALIVE"
        case .complete: return "TRAINING COMPLETE"
        }
    }

    var detail: String {
        switch self {
        case .move: return "Drag anywhere to guide the orb."
        case .dash: return "Tap DASH to escape a dangerous line."
        case .collectShard: return "Touch a glowing shard to build score and combo."
        case .meetEcho: return "Your recorded path returns as an Echo. Never touch it."
        case .survive: return "Survive until the training signal stabilizes."
        case .complete: return "You are ready for the live loop."
        }
    }
}

enum TutorialRunCoordinator {
    static func step(elapsed: TimeInterval, dashes: Int, shards: Int, echoes: Int) -> TutorialRunStep {
        if elapsed < 2.5 { return .move }
        if dashes == 0 { return .dash }
        if shards == 0 { return .collectShard }
        if echoes == 0 { return .meetEcho }
        if elapsed < 24 { return .survive }
        return .complete
    }
}
