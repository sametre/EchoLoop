# ECHO LOOP V4 — Hardened Build

Version: **0.4.0 (4)**

V4 focuses on stability, recoverability, testability and release safety rather than simply adding more screens.

## Architecture and gameplay

- Centralized time/stage/difficulty formulas in `Core/GameRules.swift`.
- Centralized deterministic run rewards in `Core/RewardCalculator.swift`.
- Lifecycle-safe pause behavior when the app becomes inactive or enters the background.
- SpriteKit frame delta is clamped to avoid large simulation jumps after stalls/resume.
- Existing Echo, dash, shard, combo and pulse-hazard mechanics are preserved.

## Persistence hardening

- Save schema upgraded to **V4**.
- Primary + last-known-good backup save strategy.
- The first successful save seeds a recovery copy.
- Corrupted primary data automatically falls back to backup data.
- V3/V2 save keys are still decoded and migrated.
- Invalid/negative progress values and missing cosmetic selections are sanitized.
- Diagnostics exposes save source and backup-recovery state.

## Monetization hardening

- UMP remains the gate before AdMob initialization.
- Google test IDs are accepted in Debug but blocked from ad initialization in Release.
- Rewarded revive completion is resolved on reward, dismissal-without-reward, or presentation failure.
- Duplicate interstitial/rewarded loads are prevented.
- StoreKit purchase, restore, entitlement refresh, and transaction updates are handled separately.
- Release preflight refuses to archive while Google test IDs or Game Center placeholder IDs remain.

## Observability

- Replaced ad-hoc `print` logging with Apple unified logging (`Logger`).
- Added categories for app, gameplay, persistence, ads, StoreKit, Game Center, audio, privacy and analytics.
- Added a DEBUG-only Diagnostics screen and release-readiness summary.

## Testing and validation

- Added a real `EchoLoopTests` XCTest target to the Xcode project.
- Tests cover game rules, reward calculation, legacy save decoding and persistence backup recovery.
- Shared `EchoLoop` scheme builds the app and runs the unit-test target.
- `Tools/validate_project.py` validates Swift syntax, project membership, assets, WAVs, localization, privacy metadata, versions and release guards.
- `Tools/mac_build_and_test.sh` performs package resolution, simulator build and XCTest on macOS.
- `Tools/mac_archive_release.sh` runs release preflight before creating an archive.

## Localization

- Added English and Turkish `Localizable.strings` resources.
- Major static SwiftUI labels resolve through the localization table.
- Dynamic copy should continue moving to explicit localization keys as new screens are added.

## Production configuration still required

The source intentionally keeps Google official test AdMob IDs and Game Center placeholder IDs until the real values are supplied. StoreKit product identifiers are already namespaced but must also exist in App Store Connect before production testing.
