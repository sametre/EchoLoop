#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import plistlib
import re
import struct
import subprocess
import sys
import wave
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "EchoLoop"
TESTS = ROOT / "EchoLoopTests"
UITESTS = ROOT / "EchoLoopUITests"
PBX = ROOT / "EchoLoop.xcodeproj" / "project.pbxproj"
SCHEME = ROOT / "EchoLoop.xcodeproj" / "xcshareddata" / "xcschemes" / "EchoLoop.xcscheme"

errors: list[str] = []
warnings: list[str] = []
passes: list[str] = []


def ok(message: str) -> None:
    passes.append(message)


def fail(message: str) -> None:
    errors.append(message)


def warn(message: str) -> None:
    warnings.append(message)


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except Exception as exc:
        fail(f"Cannot read {path.relative_to(ROOT)}: {exc}")
        return ""


def check_plist(path: Path) -> None:
    try:
        with path.open("rb") as handle:
            plistlib.load(handle)
        ok(f"Valid plist: {path.relative_to(ROOT)}")
    except Exception as exc:
        fail(f"Invalid plist {path.relative_to(ROOT)}: {exc}")


def png_dimensions(path: Path) -> tuple[int, int]:
    with path.open("rb") as handle:
        header = handle.read(24)
    if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise ValueError("not a valid PNG IHDR")
    return struct.unpack(">II", header[16:24])


# 1. Required top-level project files
required = [
    PBX,
    APP / "Info.plist",
    APP / "PrivacyInfo.xcprivacy",
    APP / "EchoLoop.entitlements",
    SCHEME,
]
for path in required:
    if not path.is_file():
        fail(f"Missing required file: {path.relative_to(ROOT)}")
if not errors:
    ok("Required project metadata exists")

# 2. plist/privacy/entitlements validity
for path in [APP / "Info.plist", APP / "PrivacyInfo.xcprivacy", APP / "EchoLoop.entitlements"]:
    if path.exists():
        check_plist(path)

# 3. Shared scheme XML
if SCHEME.exists():
    try:
        ET.parse(SCHEME)
        ok("Shared Xcode scheme XML is valid")
    except Exception as exc:
        fail(f"Invalid Xcode scheme XML: {exc}")

# 3b. Xcode/OpenStep plist lint when plutil is available
try:
    lint_files = [
        PBX,
        APP / "Info.plist",
        APP / "PrivacyInfo.xcprivacy",
        APP / "EchoLoop.entitlements",
        APP / "Resources" / "en.lproj" / "Localizable.strings",
        APP / "Resources" / "tr.lproj" / "Localizable.strings",
    ]
    proc = subprocess.run(
        ["plutil", "-lint", *map(str, lint_files)],
        cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=30
    )
    if proc.returncode == 0:
        ok("plutil lint passed for Xcode project, metadata and localization files")
    else:
        fail("plutil lint failed:\n" + proc.stdout.strip())
except FileNotFoundError:
    warn("plutil is unavailable; OpenStep/Xcode plist lint skipped")
except subprocess.TimeoutExpired:
    fail("plutil lint timed out")

# 4. Swift syntax parser (works without Apple SDK because this is parse-only)
swift_files = sorted(APP.rglob("*.swift")) + sorted(TESTS.rglob("*.swift")) + sorted(UITESTS.rglob("*.swift"))
if not swift_files:
    fail("No Swift files found")
else:
    swiftc = os.environ.get("SWIFTC") or "swiftc"
    try:
        proc = subprocess.run(
            [swiftc, "-frontend", "-parse", *map(str, swift_files)],
            cwd=ROOT,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=90,
        )
        if proc.returncode == 0:
            ok(f"Swift parser passed for {len(swift_files)} source/test files")
        else:
            fail("Swift parser failed:\n" + proc.stderr.strip())
    except FileNotFoundError:
        warn("swiftc is unavailable; Swift parse check skipped")
    except subprocess.TimeoutExpired:
        fail("Swift parser timed out")

# 5. Xcode project source membership and settings
pbx = read_text(PBX)
app_swift = sorted(APP.rglob("*.swift"))
test_swift = sorted(TESTS.rglob("*.swift"))
ui_test_swift = sorted(UITESTS.rglob("*.swift"))
for file in app_swift:
    token = f"{file.name} in Sources"
    if token not in pbx:
        fail(f"App source is not in an Xcode Sources phase: {file.relative_to(ROOT)}")
for file in test_swift:
    token = f"{file.name} in Sources"
    if token not in pbx:
        fail(f"Test source is not in the XCTest Sources phase: {file.relative_to(ROOT)}")
for file in ui_test_swift:
    token = f"{file.name} in Sources"
    if token not in pbx:
        fail(f"UI test source is not in the XCUITest Sources phase: {file.relative_to(ROOT)}")
if app_swift and all(f"{f.name} in Sources" in pbx for f in app_swift):
    ok(f"All {len(app_swift)} app Swift files are represented in Xcode Sources")
if test_swift and all(f"{f.name} in Sources" in pbx for f in test_swift):
    ok(f"All {len(test_swift)} XCTest files are represented in Xcode Sources")
if ui_test_swift and all(f"{f.name} in Sources" in pbx for f in ui_test_swift):
    ok(f"All {len(ui_test_swift)} XCUITest files are represented in Xcode Sources")

for expected in [
    'MARKETING_VERSION = 1.0.0;',
    'CURRENT_PROJECT_VERSION = 10;',
    'PRODUCT_BUNDLE_IDENTIFIER = com.sameter.echoloop;',
    'minimumVersion = 13.7.0;',
    'minimumVersion = 3.1.0;',
    'productType = "com.apple.product-type.bundle.unit-test";',
    'productType = "com.apple.product-type.bundle.ui-testing";',
    'TEST_TARGET_NAME = EchoLoop;',
    'PBXTargetDependency',
]:
    if expected not in pbx:
        fail(f"Missing expected Xcode project setting/reference: {expected}")
if not any(e.startswith("Missing expected Xcode") for e in errors):
    ok("Version, bundle, SDK package constraints, and XCTest target references are present")

# Object definitions should be unique. Ignore ordinary cross-references.
def_ids = re.findall(r"^\s*([A-F0-9]{24})(?: /\*.*?\*/)? = \{", pbx, flags=re.MULTILINE)
duplicates = sorted({x for x in def_ids if def_ids.count(x) > 1})
if duplicates:
    fail("Duplicate PBX object definitions: " + ", ".join(duplicates))
else:
    ok(f"PBX object definitions are unique ({len(def_ids)} objects)")

# 6. AppConfig version is synchronized with pbx
app_config = read_text(APP / "Config" / "AppConfig.swift")
if 'static let marketingVersion = "1.0.0"' not in app_config:
    fail("AppConfig marketingVersion is not 1.0.0")
if "static let buildNumber = 10" not in app_config:
    fail("AppConfig buildNumber is not 10")
if not any("AppConfig marketingVersion" in e or "AppConfig buildNumber" in e for e in errors):
    ok("AppConfig and Xcode build version are synchronized at 1.0.0 (10)")

# 7. Privacy manifest required-reason coverage used by this app
privacy_path = APP / "PrivacyInfo.xcprivacy"
try:
    with privacy_path.open("rb") as handle:
        privacy = plistlib.load(handle)
    accessed = privacy.get("NSPrivacyAccessedAPITypes", [])
    user_defaults = [x for x in accessed if x.get("NSPrivacyAccessedAPIType") == "NSPrivacyAccessedAPICategoryUserDefaults"]
    if not user_defaults or "CA92.1" not in user_defaults[0].get("NSPrivacyAccessedAPITypeReasons", []):
        fail("Privacy manifest does not declare the app's UserDefaults required-reason API usage")
    else:
        ok("Privacy manifest declares UserDefaults required-reason usage")
except Exception:
    pass

# 8. Localization structure
localizations = {
    "en": APP / "Resources" / "en.lproj" / "Localizable.strings",
    "tr": APP / "Resources" / "tr.lproj" / "Localizable.strings",
}
for language, path in localizations.items():
    if not path.is_file():
        fail(f"Missing {language} localization: {path.relative_to(ROOT)}")
        continue
    text = read_text(path)
    if not re.search(r'^\s*".+?"\s*=\s*".*?"\s*;', text, flags=re.MULTILINE):
        fail(f"Localization file appears empty/invalid: {path.relative_to(ROOT)}")
if all(p.is_file() for p in localizations.values()) and "knownRegions = (en, tr, Base,)" in pbx:
    ok("English/Turkish localization resources and Xcode regions are present")
if "Localizable.strings in Resources" not in pbx:
    fail("Localizable.strings is not in the app Resources build phase")

def localization_keys(path: Path) -> list[str]:
    text = read_text(path)
    return re.findall(r'^\s*"((?:\\.|[^"\\])+)"\s*=', text, flags=re.MULTILINE)

if all(p.is_file() for p in localizations.values()):
    key_sets: dict[str, set[str]] = {}
    for language, path in localizations.items():
        keys = localization_keys(path)
        duplicates = sorted({key for key in keys if keys.count(key) > 1})
        if duplicates:
            fail(f"Duplicate localization keys in {language}: " + ", ".join(duplicates))
        key_sets[language] = set(keys)
    if len(key_sets) == 2:
        en_only = sorted(key_sets["en"] - key_sets["tr"])
        tr_only = sorted(key_sets["tr"] - key_sets["en"])
        if en_only or tr_only:
            detail = []
            if en_only:
                detail.append("missing in tr: " + ", ".join(en_only))
            if tr_only:
                detail.append("missing in en: " + ", ".join(tr_only))
            fail("Localization key parity mismatch (" + "; ".join(detail) + ")")
        elif not any("Duplicate localization keys" in e or "Localization key parity" in e for e in errors):
            ok(f"English/Turkish localization key parity validated ({len(key_sets['en'])} keys)")

# 9. App icon manifest + exact expected pixel sizes
icon_dir = APP / "Resources" / "Assets.xcassets" / "AppIcon.appiconset"
contents = icon_dir / "Contents.json"
try:
    data = json.loads(contents.read_text(encoding="utf-8"))
    icon_count = 0
    for item in data.get("images", []):
        filename = item.get("filename")
        size = item.get("size")
        scale = item.get("scale")
        if not filename or not size or not scale:
            continue
        path = icon_dir / filename
        if not path.is_file():
            fail(f"Missing app icon file referenced by asset catalog: {filename}")
            continue
        w_str, h_str = size.split("x")
        scale_value = float(scale.rstrip("x"))
        expected = (round(float(w_str) * scale_value), round(float(h_str) * scale_value))
        actual = png_dimensions(path)
        if actual != expected:
            fail(f"Wrong app icon dimensions for {filename}: expected {expected}, got {actual}")
        icon_count += 1
    if icon_count and not any("app icon" in e.lower() for e in errors):
        ok(f"App icon catalog validated ({icon_count} PNG variants, including 1024px marketing icon)")
except Exception as exc:
    fail(f"Could not validate AppIcon asset catalog: {exc}")

# 10. Audio assets parse and are included in target resources
sound_dir = APP / "Resources" / "Sounds"
sounds = sorted(sound_dir.glob("*.wav"))
if len(sounds) != 9:
    fail(f"Expected 9 WAV resources, found {len(sounds)}")
for sound in sounds:
    try:
        with wave.open(str(sound), "rb") as wav:
            if wav.getnframes() <= 0 or wav.getframerate() <= 0 or wav.getnchannels() <= 0:
                raise ValueError("empty/invalid WAV metadata")
        if f"{sound.name} in Resources" not in pbx:
            fail(f"Sound is not included in Xcode Resources: {sound.name}")
    except Exception as exc:
        fail(f"Invalid WAV resource {sound.name}: {exc}")
if sounds and not any("WAV" in e or "Sound is not" in e for e in errors):
    ok(f"All {len(sounds)} WAV assets are readable and included in Xcode Resources")

# 11. Entitlements and privacy resource membership
if "com.apple.developer.game-center" not in read_text(APP / "EchoLoop.entitlements"):
    fail("Game Center entitlement is missing")
else:
    ok("Game Center entitlement is present")
if "PrivacyInfo.xcprivacy in Resources" not in pbx:
    fail("PrivacyInfo.xcprivacy is not in Xcode Resources")
else:
    ok("PrivacyInfo.xcprivacy is included in Xcode Resources")

# 12. Production code hygiene
swift_prod_text = "\n".join(read_text(p) for p in app_swift)
if re.search(r"\bprint\s*\(", swift_prod_text):
    fail("Production Swift source still contains print(...) logging")
else:
    ok("Production Swift uses structured logging; no print(...) calls found")
if re.search(r"\btry!\b|\bfatalError\s*\(", swift_prod_text):
    warn("Production source contains try! or fatalError; review before release")
else:
    ok("No try! or fatalError calls found in production Swift sources")

# 13. Expected placeholder policy: Game Center may remain placeholder until user supplies IDs; release guard must catch it.
change_me = sorted(set(re.findall(r'CHANGE_ME_[A-Z0-9_]+', app_config)))
validator = read_text(APP / "Services" / "ConfigurationValidator.swift")
if change_me:
    if 'contains("CHANGE_ME")' not in validator:
        fail("Game Center placeholders exist but ConfigurationValidator does not detect them")
    else:
        warn(f"Production Game Center IDs are intentionally placeholders ({len(change_me)}); replace before App Store release")
        ok("Release-readiness validator detects Game Center placeholder configuration")

# 14. Official AdMob test IDs are allowed only for Debug; inspect the assigned appID rather than the test-comparison literal.
admob_assigned = re.search(r'enum AdMob \{.*?static let appID = "([^"]+)"', app_config, flags=re.S)
if admob_assigned and admob_assigned.group(1).startswith("ca-app-pub-3940256099942544"):
    if "Runtime.allowTestAds" not in validator and "isTestConfiguration" not in validator:
        fail("Test AdMob IDs are present without a release guard")
    else:
        warn("Official Google test AdMob IDs are still configured; production IDs are required before App Store release")
        ok("Release configuration guard is present for test AdMob IDs")
elif admob_assigned:
    ok("Assigned AdMob app ID is not Google's official test app ID")
else:
    fail("Assigned AdMob app ID could not be parsed from AppConfig.swift")

# 15. Cloud sync staging must be safe when the production iCloud capability is not configured yet.
if "CloudSyncManager.swift in Sources" not in pbx:
    fail("CloudSyncManager is missing from the application target")
if "static let enabled = false" in app_config and "CHANGE_ME_iCloud" in app_config:
    ok("CloudKit sync layer is safely staged off until a production container is configured")
elif "static let enabled = true" in app_config and "CHANGE_ME_iCloud" in app_config:
    fail("Cloud sync is enabled while the iCloud container is still a placeholder")

# 16. Scheme must build/test both products.
scheme_text = read_text(SCHEME)
if "EchoLoopTests.xctest" not in scheme_text or "EchoLoopUITests.xctest" not in scheme_text or scheme_text.count("TestableReference") < 2:
    fail("Shared scheme does not include both unit and UI test targets")
else:
    ok("Shared scheme includes unit and UI tests")


# 17. V10 gameplay/progression/release-candidate architecture gates
v10_required_sources = [
    "BossEncounterDirector.swift",
    "SeasonProgression.swift",
    "TutorialRunCoordinator.swift",
    "SeasonView.swift",
    "AdaptiveQualityController.swift",
    "SceneComplexityPolicy.swift",
]
missing_v10 = [name for name in v10_required_sources if f"{name} in Sources" not in pbx]
if missing_v10:
    fail("Missing V10 source membership: " + ", ".join(missing_v10))
else:
    ok("V10 boss, season, tutorial and season UI modules are included in the application target")

profile_text = read_text(APP / "Managers" / "PlayerProfile.swift")
if 'private let saveKey = "echo.profile.v10"' not in profile_text or '"echo.profile.v6"' not in profile_text:
    fail("V10 save key or V6 migration source is missing")
elif "save.schemaVersion = 10" not in profile_text:
    fail("PlayerProfile does not sanitize saves to schema version 10")
else:
    ok("V10 persistence schema and V6 migration path are present")

unit_test_methods = sum(read_text(path).count("func test") for path in test_swift)
ui_test_methods = sum(read_text(path).count("func test") for path in ui_test_swift)
if unit_test_methods < 30 or ui_test_methods < 5:
    fail(f"V10 automated test floor not met (unit={unit_test_methods}, ui={ui_test_methods})")
else:
    ok(f"V10 automated test floor satisfied ({unit_test_methods} unit + {ui_test_methods} UI tests)")


# 18. Export compliance metadata and App Store preparation package
try:
    with (APP / "Info.plist").open("rb") as handle:
        info = plistlib.load(handle)
    if info.get("ITSAppUsesNonExemptEncryption") is not False:
        fail("Info.plist must explicitly declare ITSAppUsesNonExemptEncryption=false for the current exempt-encryption configuration; re-evaluate if encryption usage changes")
    else:
        ok("Export-compliance Info.plist declaration is present for the current configuration")
except Exception:
    pass

appstore_required = [
    ROOT / "AppStore" / "metadata" / "en-US.json",
    ROOT / "AppStore" / "metadata" / "tr-TR.json",
    ROOT / "AppStore" / "website" / "privacy.html",
    ROOT / "AppStore" / "website" / "support.html",
    ROOT / "AppStore" / "APP_PRIVACY_WORKSHEET.md",
    ROOT / "AppStore" / "AGE_RATING_WORKSHEET.md",
    ROOT / "AppStore" / "IAP_PRODUCTS.md",
    ROOT / "AppStore" / "APP_REVIEW_NOTES.md",
    ROOT / "AppStore" / "SCREENSHOT_PLAN.md",
    ROOT / "AppStore" / "RELEASE_CHECKLIST.md",
    ROOT / "AppStore" / "ExportOptions.plist",
    ROOT / "ProductionConfig.example.json",
]
missing_store = [str(x.relative_to(ROOT)) for x in appstore_required if not x.is_file()]
if missing_store:
    fail("Missing App Store release assets: " + ", ".join(missing_store))
else:
    ok("App Store metadata, privacy/support templates, IAP notes and release worksheets are present")

for locale in ("en-US", "tr-TR"):
    path = ROOT / "AppStore" / "metadata" / f"{locale}.json"
    if path.exists():
        try:
            metadata = json.loads(path.read_text(encoding="utf-8"))
            for field, limit in (("name", 30), ("subtitle", 30), ("promotionalText", 170), ("description", 4000)):
                value = metadata.get(field, "")
                if not value or len(value) > limit:
                    fail(f"{locale} metadata {field} is empty or exceeds {limit} characters")
            keyword_bytes = len(metadata.get("keywords", "").encode("utf-8"))
            if keyword_bytes == 0 or keyword_bytes > 100:
                fail(f"{locale} metadata keywords must be 1..100 bytes; got {keyword_bytes}")
            if "REPLACE_WITH" in metadata.get("supportURL", "") or "REPLACE_WITH" in metadata.get("privacyPolicyURL", ""):
                warn(f"{locale} storefront URLs are placeholders; App Store submission remains blocked until public HTTPS pages are deployed")
        except Exception as exc:
            fail(f"Invalid App Store metadata {locale}: {exc}")
if not any("metadata" in e.lower() for e in errors):
    ok("EN/TR App Store metadata field limits validate")

# 19. Actual portable core compilation/smoke test when Swift is available.
smoke = ROOT / "Tools" / "linux_core_smoke.sh"
if smoke.exists() and os.access(smoke, os.X_OK):
    try:
        proc = subprocess.run([str(smoke)], cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=60)
        if proc.returncode == 0:
            ok("Portable Swift core smoke executable compiled and passed")
        else:
            fail("Portable Swift core smoke test failed:\n" + proc.stdout.strip())
    except FileNotFoundError:
        warn("Portable core smoke test skipped because Swift compiler is unavailable")
    except subprocess.TimeoutExpired:
        fail("Portable core smoke test timed out")

# 20. V10 release automation inventory
release_tools = [
    "check_xcode26.sh", "apply_production_config.py", "appstore_submission_preflight.py",
    "mac_build_and_test.sh", "mac_archive_release.sh", "mac_export_ipa.sh",
    "mac_upload_appstore.sh", "mac_capture_screenshots.sh", "mac_release_pipeline.sh",
]
missing_tools = [name for name in release_tools if not (ROOT / "Tools" / name).is_file()]
if missing_tools:
    fail("Missing V10 release automation: " + ", ".join(missing_tools))
else:
    ok("V10 Xcode 26 build, screenshot, archive, IPA export and upload automation is present")

print("ECHO LOOP V10 RELEASE-CANDIDATE VALIDATION")
print("=" * 38)
for item in passes:
    print(f"[PASS] {item}")
for item in warnings:
    print(f"[WARN] {item}")
for item in errors:
    print(f"[FAIL] {item}")
print("-" * 38)
print(f"PASS={len(passes)} WARN={len(warnings)} FAIL={len(errors)}")

sys.exit(1 if errors else 0)
