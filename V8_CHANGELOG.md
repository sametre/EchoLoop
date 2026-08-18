# ECHO LOOP V8 — Production Hardening

- Bumped the final persistence line to schema V10 while preserving V6/V5/V4/V3/V2 migration.
- Kept primary + last-known-good save recovery.
- Fixed production configuration validation to include the boss achievement ID.
- Added export-compliance metadata for the current exempt-encryption configuration.
- Added `ProductionConfig.example.json` and a no-secret `apply_production_config.py` workflow.
- Production preflight now verifies AppConfig/Xcode version synchronization, AdMob plist consistency, StoreKit namespace, Game Center placeholders, advertising plist metadata and optional CloudKit configuration.
