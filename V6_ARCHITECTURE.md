# ECHO LOOP V6 — Architecture Notes

## 1. Keep scene rendering separate from rules

`EchoScene` owns SpriteKit nodes and real-time simulation. Rules that must be deterministic live outside the scene:

- `GameRules` — stage timing and difficulty math.
- `EchoKind` — normal special-Echo selection.
- `ArenaEventDirector` — arena event ordering.
- `BossEncounterDirector` — boss-stage eligibility and boss rotation.
- `SeasonProgression` — Signal XP and tier thresholds.
- `TutorialRunCoordinator` — training step progression.

This separation is deliberate: balance logic remains unit-testable without needing an SKView.

## 2. Boss encounters

Bosses are survival encounters, not health-bar combat. During a boss window, newly created Echoes inherit the boss profile. This preserves the core identity of ECHO LOOP: the threat still comes from the player's recorded movement.

Normal arena events do not start during a boss encounter. This is both a fairness rule and a performance guard.

## 3. Season progression

Signal Zero is free progression only. V6 does not introduce a paid season pass. This keeps StoreKit complexity out of the retention experiment and prevents progression balance from being tied to monetization before real player data exists.

## 4. Training

Training uses the normal `GameSession` and `EchoScene`. There is no second fake tutorial engine. A tutorial run is flagged on `GameSession`, and `TutorialRunCoordinator` derives the current coaching step from real gameplay counters.

## 5. Save schema V6

V6 adds:

- lifetime boss encounter count
- season ID / season XP
- claimed season tier IDs
- tutorial completion

Primary/backup persistence remains local-first. Cloud merge uses monotonic max/union behavior only for fields where that cannot mint duplicated rewards; selection and other conflict-prone values continue to use the newer record policy.

## 6. CloudKit

Cloud sync remains capability-gated. Do not enable `AppConfig.Cloud.enabled` until the production iCloud container exists and the entitlement/provisioning profile is configured.

The current layer is intentionally isolated so it can later be migrated toward a more advanced `CKSyncEngine`-based implementation without rewriting gameplay or profile APIs.

## 7. Testing

V6 keeps three layers:

- static project validator
- XCTest logic/persistence tests
- XCUITest navigation/game-launch flows

The macOS script remains the final local gate because only an Apple SDK environment can run iOS type-checking, linking, Simulator tests and signing.
