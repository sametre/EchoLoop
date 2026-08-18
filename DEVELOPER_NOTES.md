# ECHO LOOP V10 — Developer Notes

The 1.0 release candidate deliberately separates game rules from SpriteKit rendering so gameplay balance can be tested without an SKView. Do not reintroduce unbounded scene-node growth: all Echo/particle changes should pass through `SceneComplexityPolicy` or an equivalent bounded policy.

Release builds must never ship Google's official test ad IDs. Keep public IDs in `ProductionConfig.json` and apply them with the tooling; keep Apple credentials/API private keys outside the repository.

CloudKit is intentionally disabled until the real container/capability is provisioned. StoreKit product IDs are already final namespace candidates and should be created exactly in App Store Connect before submission.

The authoritative release checks are `Tools/validate_project.py`, `Tools/release_preflight.py`, `Tools/appstore_submission_preflight.py`, and the Xcode 26+ macOS scripts. Historical V2–V9 changelogs are informational only.
