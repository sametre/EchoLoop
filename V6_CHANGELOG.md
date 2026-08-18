# ECHO LOOP V6 — Changelog

Version: **0.6.0 (Build 6)**

## Gameplay

- Added deterministic boss encounter rotation starting at Stage 7 and repeating every three stages.
- Added Chrono Warden, Prism Regent, and Void Sentinel boss profiles.
- Boss-enhanced Echoes use boss-specific scale, collision and timing multipliers.
- Boss encounters pause arena-event spawning to avoid stacked unfairness.
- Surviving a boss grants a large score bonus and increments lifetime boss progression.

## Progression

- Added Signal Zero, a 12-tier free season track.
- Added Signal XP calculation based on survival time, stage, score and boss survival.
- Added claimable coin rewards per unlocked season tier.
- Added Season screen and menu entry.
- Added boss achievement progression.

## Training

- Added a Practice/Training entry from the main menu.
- Added an in-run tutorial coach using the actual gameplay scene.
- Training progression checks movement time, dash usage, shard collection, Echo creation and survival.
- Tutorial completion is persisted in the V6 save.

## Persistence / sync

- Save schema upgraded from V5 to V6.
- New V6 primary + backup keys with migration from V5/V4/V3/V2.
- Added season state, claimed season tiers, tutorial completion and boss counters to save data.
- Cloud merge handles V6 season/boss/tutorial fields deterministically.
- Cloud profile record name advanced to `player-profile-v6`.

## Quality

- Added BossEncounterDirector tests.
- Added SeasonProgression tests.
- Added TutorialRunCoordinator tests.
- Added V6 Cloud merge coverage.
- Added Season navigation XCUITest coverage.
- UI-test reset now clears V6 save keys.
- Validator now enforces V6 source membership, migration path and minimum automated test floor.
