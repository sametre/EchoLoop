# ECHO LOOP — iOS 1.0 Release Candidate

**Version:** 1.0.0  
**Build:** 10  
**Stack:** SwiftUI + SpriteKit + StoreKit 2 + GameKit + Google Mobile Ads/UMP  
**Bundle ID:** `com.sameter.echoloop`

ECHO LOOP is a neon survival game where the player's recorded movement returns as hostile Echoes. The project includes special Echo types, arena events, hazards, boss encounters, season progression, missions, cosmetics, Game Center, optional rewarded revive, StoreKit purchases, adaptive rendering quality, local save recovery, EN/TR localization and production release gates.

## Open in Xcode

Open `EchoLoop.xcodeproj`, select your Apple Development Team, resolve packages, then run:

```bash
Tools/mac_build_and_test.sh
```

Current App Store uploads require Xcode 26+ / iOS 26 SDK+, so the macOS release scripts enforce Xcode 26 or newer.

## Production configuration

Never commit credentials. Copy the example and fill only public production identifiers/URLs:

```bash
cp ProductionConfig.example.json ProductionConfig.json
python3 Tools/apply_production_config.py ProductionConfig.json
python3 Tools/release_preflight.py
```

`ProductionConfig.json` is gitignored. App Store Connect API private keys, Apple account passwords, and signing secrets are **not** stored in the Xcode project.

## Final test/archive/upload

```bash
Tools/mac_build_and_test.sh
Tools/mac_capture_screenshots.sh
python3 Tools/appstore_submission_preflight.py
Tools/mac_export_ipa.sh
Tools/mac_upload_appstore.sh
```

Or, after production configuration is complete:

```bash
UPLOAD=1 Tools/mac_release_pipeline.sh
```

The upload script supports App Store Connect API key environment variables (`ASC_API_KEY`, `ASC_API_ISSUER`) with the matching `.p8` key in an Apple-supported Transporter key location, or Apple ID + app-specific password environment variables.

## Important release blockers in the source package

The distributed release candidate intentionally keeps Google test ad IDs and Game Center placeholders until the account-specific production identifiers are supplied. Storefront support/privacy URLs and email are also placeholders. `Tools/release_preflight.py` and `Tools/appstore_submission_preflight.py` are expected to block until those are resolved.

See `AppStore/RELEASE_CHECKLIST.md`, `V10_ARCHITECTURE.md`, `V10_CHANGELOG.md` and `FINAL_RELEASE_STATUS.md`.
