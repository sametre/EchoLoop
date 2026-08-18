# ECHO LOOP V7 — Performance & Rendering Polish

V7 focused on long-run stability rather than adding more game rules.

- Added `AdaptiveQualityController` with bounded high/balanced/low rendering quality.
- Added `SceneComplexityPolicy` for active Echo, star and particle budgets.
- `SKView` now ignores sibling ordering where safe, culls non-visible nodes and targets 60 FPS.
- Active Echo growth is bounded; oldest non-boss Echoes are retired when the quality-aware budget is exceeded.
- Particle/trail density adapts to sustained frame pressure and honors Reduced Motion.
- Added XCTest coverage plus a portable Swift smoke executable for the pure core rules.
