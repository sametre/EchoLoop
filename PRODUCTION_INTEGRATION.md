# ECHO LOOP V10 — Production Integration

## 1. Public identifiers

Copy `ProductionConfig.example.json` to `ProductionConfig.json`, enter production AdMob IDs, Game Center IDs, public support/privacy URLs and support email, then run:

```bash
python3 Tools/apply_production_config.py ProductionConfig.json
python3 Tools/release_preflight.py
```

The config file is gitignored. Do not put Apple private keys/passwords in it.

## 2. AdMob / UMP

Create the iOS app in AdMob for bundle `com.sameter.echoloop` and create banner, interstitial and rewarded units. Review UMP messages/privacy options and final data disclosures. The app initializes ads only after the consent layer permits requests.

## 3. Game Center

Create one leaderboard and the ten achievement identifiers represented in `AppConfig.Game.Achievements`. Apply the exact IDs with the production-config tool and test all submissions with a Game Center sandbox/TestFlight user.

## 4. StoreKit

Create two Non-Consumables with the exact code product IDs:

- `com.sameter.echoloop.removeads`
- `com.sameter.echoloop.premiumneon`

Complete pricing, localizations and review metadata. Test with StoreKit/Sandbox/TestFlight and add the first non-consumables to the first app-version review submission.

## 5. CloudKit

Optional. The release candidate is local-first and CloudKit is disabled. If enabling, create the real iCloud container, add iCloud/CloudKit capability to the App ID/Xcode target, update provisioning, apply the production container ID and run multi-device merge tests before release.

## 6. Public support/privacy pages

Deploy `AppStore/website/support.html` and `privacy.html` under public HTTPS URLs. Replace the support email and apply those URLs to the localized metadata.

## 7. Apple signing/TestFlight

Use Xcode 26+ with iOS 26 SDK+, select the production Apple Team and run the full macOS pipeline. Upload to TestFlight first, smoke-test the processed build, then select the build in the 1.0 App Store version and submit it with the IAPs.
