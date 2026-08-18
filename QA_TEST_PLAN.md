# ECHO LOOP V10 — QA Test Plan

## Automated gates

Run on any host with Swift installed:

```bash
Tools/linux_core_smoke.sh
python3 Tools/validate_project.py
```

Run on macOS with Xcode 26+:

```bash
Tools/mac_build_and_test.sh
```

The shared scheme runs unit and UI tests. UI testing resets versioned local profile data and bypasses account-dependent prompts so navigation tests are deterministic.

## Gameplay smoke

- Fresh install → onboarding → menu.
- PLAY → movement, dash, shard pickup, first Echo, hazard, pause/resume.
- Run through stage progression; verify special Echo and arena event rotation.
- Reach boss-eligible stage in a debug/test session; verify boss window does not stack normal arena events.
- Verify long runs do not grow active Echo nodes without bound and adaptive effects can reduce rendering quality under sustained frame pressure.
- Kill run → reward calculation → Retry/Home.
- Rewarded revive: reward success, dismiss-without-reward, load failure, no-network path.

## Persistence

- Upgrade V6 save → V10 migration.
- Corrupt primary save → last-known-good backup recovery.
- Settings/profile survive relaunch.
- Delete/reinstall semantics understood; local save is not a developer cloud account.

## StoreKit

- Products load in Sandbox/TestFlight.
- Buy Remove Ads.
- Buy Premium Neon.
- Cancel, pending and error paths.
- Restore purchases after reinstall / on a second test device.
- Ads remain removed after entitlement refresh.

## Ads/privacy

- UMP flow by consent geography/debug configuration.
- Privacy Options appears when required.
- Release archive contains production, never Google test, IDs.
- Banner/interstitial/rewarded placements do not interrupt active input unexpectedly.

## Game Center

- Auth success/cancel/unavailable.
- Leaderboard score submission.
- All 10 achievements progress/complete using production identifiers.
- Gameplay remains available without authentication.

## Accessibility/device

- Reduced Motion.
- Haptic/sound/music toggles.
- Dynamic Type/readability spot check.
- VoiceOver navigation spot check on menu/settings/shop.
- Small supported iPhone + 6.9-inch iPhone layout.
- Background/foreground during active run pauses safely.

## Final physical/TestFlight gate

Install the exact uploaded TestFlight build on at least one physical iPhone. Complete purchase sandbox checks, ad consent/ad delivery, Game Center, interruption/backgrounding, thermal/performance smoke and a 5+ minute run before App Review.
