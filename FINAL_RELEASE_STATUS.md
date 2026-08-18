# ECHO LOOP — Final Release Status

## Code/package status

- Release candidate version: **1.0.0 (10)**.
- Swift parser, Xcode project metadata, localization parity, resources, privacy manifest and portable Swift core smoke tests are automated.
- Unit and UI test targets are wired into the shared Xcode scheme.
- Production Swift sources are guarded against `print`, `try!` and `fatalError()` in the validator.
- Long-run Echo/particle budgets are bounded.
- Archive, IPA export, binary upload and screenshot-capture scripts are included.

## Expected blockers before a real App Store submission

These cannot be fabricated by the source package and must come from the production accounts or public infrastructure:

1. AdMob production App ID + banner/interstitial/rewarded unit IDs.
2. Game Center production leaderboard + 10 achievement IDs.
3. Public HTTPS Support URL and Privacy Policy URL.
4. Real support/privacy email.
5. App Store Connect app record and Apple signing Team/provisioning.
6. Both non-consumable IAP records in App Store Connect.
7. Real App Store screenshots captured from the submitted UI.
8. App Privacy and age-rating questionnaires completed against the final production SDK/account configuration.
9. Xcode 26+ signed archive, TestFlight validation and final review submission.

The release tooling blocks rather than guessing any of the values above.
