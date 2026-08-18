# ECHO LOOP V10 — 1.0 Release Candidate

Release identity: **1.0.0 (Build 10)**

V10 closes the V1–V10 development cycle as a release candidate.

- Version/build synchronized across Xcode and AppConfig.
- Save schema finalized at V10 with backward migration.
- Long-run performance budget and adaptive effects integrated into real gameplay.
- EN/TR localization parity retained.
- StoreKit 2, Game Center, AdMob/UMP, privacy manifest and release guards retained.
- Added real Swift core compile/run smoke testing in addition to parse/static validation.
- Added Xcode build/test, archive, IPA export and App Store upload scripts.
- Added App Store submission preflight that refuses incomplete metadata, URLs, screenshots or production IDs.
- No Apple credentials or signing secrets are committed to the project.

The remaining submission blockers are account-specific production data, not hidden code TODOs: production AdMob IDs, Game Center IDs, public support/privacy URLs + email, StoreKit/App Store Connect records, screenshots captured from a real Simulator/device, and a signed Xcode 26+ archive.
