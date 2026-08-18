# ECHO LOOP — App Privacy Worksheet

Release candidate: 1.0.0 (10)  
Prepared: 2026-08-18

This is a preparation worksheet, not a legal determination. App Store Connect answers must include the practices of third-party SDKs and must be re-verified against the production AdMob/UMP configuration before submission.

## App-owned data

- No developer-operated login/account.
- Player progress and settings are stored locally with UserDefaults-backed persistence.
- CloudKit is disabled in the release candidate unless explicitly enabled with a real container.
- StoreKit entitlement state is obtained from Apple APIs.
- Game Center score/achievement submissions use Apple GameKit.

## Third-party advertising — verify in production

Google Mobile Ads and User Messaging Platform are integrated. Before publishing App Privacy answers, inspect the current Google Mobile Ads data-disclosure documentation and your AdMob settings/mediation partners. Do **not** select “No data collected” merely because the app itself has no backend.

Potential categories that can be relevant depending on consent/configuration include identifiers, product interaction/usage, diagnostics, advertising data, and approximate location. Confirm every category and purpose in App Store Connect against the final SDK and account configuration.

## Privacy policy

Deploy `AppStore/website/privacy.html` to a public HTTPS URL. Replace `REPLACE_WITH_SUPPORT_EMAIL` and set that public URL in both metadata JSON files.

## User privacy choices

The app exposes Google's UMP Privacy Options entry when required. A separate public User Privacy Choices URL is optional in App Store Connect; add one if your final policy/support site provides a durable web choice mechanism.
