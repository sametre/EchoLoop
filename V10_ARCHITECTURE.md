# ECHO LOOP V10 — Release Architecture

## Runtime layers

- **SwiftUI app shell:** routing, onboarding, settings, shop, season, profile, achievements and game-over UI.
- **SpriteKit simulation:** player, Echo replay, shards, hazards, boss windows, arena events and visual effects.
- **Deterministic core:** game rules, Echo/boss/event selection, progression, reward math and tutorial rules.
- **Persistence:** versioned local profile with primary + backup recovery and deterministic merge primitives.
- **Platform services:** StoreKit 2, Game Center, Google Mobile Ads/UMP, haptics/audio, review prompting and optional CloudKit.
- **Release tooling:** portable smoke compiler, static project validator, production preflight, Xcode test/archive/export/upload scripts and App Store submission preflight.

## Performance contract

The scene does not allow unbounded Echo growth. `SceneComplexityPolicy` provides a quality/stage-aware active Echo ceiling and controls particle/star/trail density. `AdaptiveQualityController` reacts to a moving frame-time estimate with hysteresis so effects do not oscillate every frame. Gameplay rules remain independent of rendering quality.

## Release safety

Debug builds may use Google's official test AdMob units. Release builds refuse to start test advertising through the runtime validator, and the command-line preflight blocks an archive from being treated as production-ready until real AdMob and Game Center identifiers are applied.

CloudKit remains optional and disabled by default. Enabling it requires a real iCloud container plus Apple capability/provisioning configuration; the project does not silently enable an entitlement that could break signing.

## Testing layers

1. `swiftc -frontend -parse` over app/tests/UI tests.
2. Portable Swift core executable compiled and run on non-Apple hosts.
3. XCTest unit tests on macOS/Xcode.
4. XCUITest navigation/game-launch and screenshot capture on iOS Simulator.
5. Release preflight for production identifiers and binary metadata.
6. App Store submission preflight for storefront URLs, screenshots and localized metadata.
7. Physical-device + TestFlight smoke test before App Review.
