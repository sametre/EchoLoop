# ECHO LOOP V10 — Release Gates

## Development gate

`python3 Tools/validate_project.py` must return zero FAIL. Warnings for intentionally unresolved public production identifiers/URLs are acceptable during development.

## Binary production gate

`python3 Tools/release_preflight.py` must PASS. It blocks test AdMob IDs, Game Center placeholders, mismatched AdMob plist/AppConfig values, invalid optional Cloud configuration, StoreKit namespace errors, version mismatch and missing binary privacy/export metadata.

## App Store storefront gate

`python3 Tools/appstore_submission_preflight.py` must PASS. In addition to the binary gate it requires valid metadata limits, public HTTPS support/privacy URLs, resolved support email and actual screenshot files.

## Apple SDK gate

All release scripts call `Tools/check_xcode26.sh`. Xcode 26+ is required for the current App Store upload requirement.

## Device/TestFlight gate

A successful archive/upload is not approval to submit for review. The exact processed TestFlight build must pass the physical-device QA plan, IAP, ads/consent and Game Center checks before App Review.
