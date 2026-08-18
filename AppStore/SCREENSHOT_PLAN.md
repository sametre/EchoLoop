# ECHO LOOP — App Store Screenshot Plan

The Xcode target supports both iPhone and iPad, so prepare both required families.

## iPhone 6.9-inch — required primary family

Use portrait PNGs at one accepted size:

- 1260 × 2736
- 1290 × 2796
- 1320 × 2868

## iPad 13-inch — required because the app runs on iPad

Use portrait PNGs at one accepted size:

- 2064 × 2752
- 2048 × 2732

App Store Connect accepts 1–10 screenshots per family. The release preflight expects final images in:

- `AppStore/screenshots/iphone69/`
- `AppStore/screenshots/ipad13/`

Recommended five-frame story for each family:

1. **OUTRUN YOUR PAST** — menu/brand hero.
2. **YOUR MOVES COME BACK** — core gameplay with visible Echoes.
3. **MASTER THE LOOP** — dash/shard/combo/hazard.
4. **FACE ELITE ECHOES** — special Echo or boss encounter.
5. **BUILD YOUR SIGNAL** — season/achievement progression.

Run `Tools/mac_capture_screenshots.sh`; it runs the XCUITest screenshot flow on a large iPhone and a 13-inch iPad simulator and exports XCTest attachments when the installed Xcode supports the attachment-export command. Review every image before copying it from the `raw/` subfolder to the final family folder.
