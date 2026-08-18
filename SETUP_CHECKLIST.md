# ECHO LOOP V10 — Local Setup

1. Install/select Xcode 26 or newer with an iOS 26+ Simulator runtime.
2. Open `EchoLoop.xcodeproj` and select your Apple Development Team.
3. Resolve Swift packages.
4. Run `Tools/mac_build_and_test.sh`.
5. For production, create/apply `ProductionConfig.json`.
6. Create matching Game Center/IAP records in App Store Connect.
7. Deploy public support/privacy pages and verify the URLs.
8. Capture App Store screenshots with `Tools/mac_capture_screenshots.sh` and export them to `AppStore/screenshots/`.
9. Pass both preflight scripts.
10. Export/upload a signed IPA and validate the processed build in TestFlight.
