# ECHO LOOP 1.0 — App Store Release Checklist

## Apple account / App Store Connect
- [ ] Explicit App ID exists for `com.sameter.echoloop`.
- [ ] App record exists in App Store Connect for ECHO LOOP.
- [ ] Xcode 26+ is selected and the build uses the iOS 26 SDK or later.
- [ ] Signing Team is selected and Release archive signs successfully.
- [ ] Agreements/tax/banking requirements relevant to paid IAP are active.

## Production configuration
- [ ] Real AdMob App ID, banner, interstitial, rewarded IDs applied.
- [ ] Real Game Center leaderboard + 10 achievement identifiers applied.
- [ ] Google UMP/AdMob production account configuration reviewed.
- [ ] CloudKit remains disabled, or a real iCloud container/capability is configured and tested.
- [ ] `Tools/release_preflight.py` passes.

## StoreKit
- [ ] Remove Ads non-consumable created and Ready to Submit.
- [ ] Premium Neon non-consumable created and Ready to Submit.
- [ ] Prices/localizations/review screenshots entered.
- [ ] Purchase, cancel, pending, restore, reinstall entitlement flows tested in Sandbox/TestFlight.

## Product page
- [ ] EN/TR metadata reviewed.
- [ ] Support page publicly reachable over HTTPS.
- [ ] Privacy policy publicly reachable over HTTPS.
- [ ] Support email placeholder removed.
- [ ] 6.9-inch iPhone screenshots uploaded (1–10; recommended 5).
- [ ] 13-inch iPad screenshots uploaded (required because target supports iPad; 1–10, recommended 5).
- [ ] Primary/secondary categories confirmed.
- [ ] Age-rating questionnaire completed.
- [ ] App Privacy questionnaire completed using final third-party SDK disclosures.
- [ ] Copyright and App Review notes entered.

## QA / binary
- [ ] `Tools/mac_build_and_test.sh` passes on Xcode 26+.
- [ ] Physical-device smoke test passes.
- [ ] No TEST AdMob ID appears in Release archive.
- [ ] Game Center production leaderboard/achievements verified.
- [ ] Release IPA validates with Apple.
- [ ] TestFlight build installed and smoke-tested before App Review.

## Submission
- [ ] Build processed in App Store Connect.
- [ ] Build selected for version 1.0.
- [ ] First non-consumable IAP products added to the same submission.
- [ ] Add for Review, then Submit for Review.
