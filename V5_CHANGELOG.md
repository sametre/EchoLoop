# ECHO LOOP V5 — Professional Gameplay & Sync Foundation

Version: **0.5.0 (Build 5)**

V5 builds on V4's hardening work. The focus is premium gameplay variety, testable deterministic systems, cross-device-sync readiness and automated UI validation without weakening the existing release gates.

## Gameplay

- Added `EchoKind` with Classic, Hunter, Mirror and Phase variants.
- Special Echo selection is deterministic by spawn index/stage for repeatable balancing and tests.
- Hunter uses increased pressure/speed characteristics.
- Mirror transforms the player's recorded path horizontally.
- Phase starts with delayed collision activation and a pulsing visual state.
- Added `ArenaEventDirector` with Signal Blackout, Echo Overdrive and Shard Storm.
- Arena events begin from Stage 4 and use deterministic timing/rotation rules.
- Added run/lifetime counters for special Echoes and survived arena events.

## Visual polish

- Added `VisualEffectsFactory` to centralize generated particle textures, bursts, special-Echo aura and arena-event pulse effects.
- Special Echoes receive distinct color/aura feedback.
- Arena events receive a central neon pulse cue.
- Reduced Motion is respected by V5 visual effects.

## Achievement progression

- Added local `AchievementCatalog` and `AchievementSnapshot` model.
- Added Achievements screen with progress presentation.
- Added milestones for survival, stage, shards, dashes, special Echoes and arena events.
- Game Center manager can synchronize profile-driven achievement progress.

## Persistence and CloudKit readiness

- Save schema upgraded to V5.
- Added `lifetimeSpecialEchoes`, `lifetimeArenaEvents`, `syncRevision` and `lastModified`.
- Preserved V2/V3/V4 migration and V4 primary/last-known-good recovery strategy.
- Added deterministic local/cloud merge logic and unit tests.
- Added `CloudSyncManager` using the player's private CloudKit database.
- CloudKit remains disabled until a real container/capability is configured, preventing generated-project signing breakage.

## Testability

- Expanded XCTest suite with Echo kind, arena event, achievement and cloud-merge tests.
- Added a dedicated XCUITest target.
- Added UI tests for main-menu launch, Achievements navigation and starting/pausing gameplay.
- Added UI-test launch environment that safely resets local test progress and skips Game Center/UMP/ad system popups.
- Shared scheme now includes unit and UI test bundles.

## Localization and validation

- Added EN/TR copy for achievements, Cloud status and arena events.
- Project validator now checks exact EN/TR localization-key parity and duplicate keys.
- Validator confirms app/unit/UI target membership and CloudKit staged configuration.

## Production configuration still required

- Replace official Google AdMob test identifiers with production values.
- Replace all Game Center `CHANGE_ME_*` identifiers.
- Create/verify StoreKit products in App Store Connect.
- Configure the final Apple Team/Bundle ID.
- Optionally configure the real iCloud container/capability before enabling Cloud sync.

`Tools/release_preflight.py` intentionally blocks production archive until the known mandatory identifier blockers are resolved.
