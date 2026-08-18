# ECHO LOOP V3 — Professional Build Changelog

Version: 0.3.0 (build 3)

## Gameplay

- Added score and combo systems.
- Added high-score tracking.
- Added Stage 3+ pulse-mine hazards with warning/active phases.
- Added hazard-dodge statistics/rewards.
- Added pause-safe simulation time so echoes/hazards don't jump forward after pause.
- Added 3-2-1 run countdown.
- Expanded Game Over stats with score, stage and hazard dodges.
- Added audio/haptic feedback for gameplay events.

## Retention & progression

- Added daily login reward.
- Added login streak tracking.
- Added lifetime dash count and highest-stage stat.
- Added V3 save schema and V2 migration path.
- Kept missions, XP, coins and cosmetics from V2.

## UX

- Added first-launch onboarding with Skip/Continue flow.
- Added music setting.
- Added richer Settings diagnostics.
- Added privacy-options action when required.
- Added review-request policy hook after meaningful engagement.

## Monetization / privacy

- Added Google UMP Swift Package dependency.
- Consent info is updated before AdMob startup.
- Required consent form is presented before ad requests.
- AdMob initializes only after `canRequestAds` permits requests.
- Full-screen ad presentation ducks game audio.
- Added app PrivacyInfo.xcprivacy resource.
- Google test IDs remain intentionally enabled for development.

## Engineering

- Added `AudioManager`.
- Added `AnalyticsManager` provider-neutral hook layer.
- Added `PrivacyConsentManager`.
- Added `ReviewManager`.
- Added generated local WAV resources.
- Google Mobile Ads minimum package version raised to 13.7.0.
- Marketing version raised to 0.3.0, build 3.
