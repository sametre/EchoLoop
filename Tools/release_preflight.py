#!/usr/bin/env python3
from __future__ import annotations
from pathlib import Path
import plistlib, re, sys

ROOT=Path(__file__).resolve().parents[1]
CONFIG=ROOT/'EchoLoop/Config/AppConfig.swift'
INFO=ROOT/'EchoLoop/Info.plist'
PBX=ROOT/'EchoLoop.xcodeproj/project.pbxproj'
text=CONFIG.read_text(encoding='utf-8')
pbx=PBX.read_text(encoding='utf-8')
with INFO.open('rb') as f: info=plistlib.load(f)
blockers=[]

# Release identity/version.
if 'static let marketingVersion = "1.0.0"' not in text or 'static let buildNumber = 10' not in text:
    blockers.append('AppConfig is not release candidate 1.0.0 (10).')
if 'MARKETING_VERSION = 1.0.0;' not in pbx or 'CURRENT_PROJECT_VERSION = 10;' not in pbx:
    blockers.append('Xcode target version/build is not synchronized at 1.0.0 (10).')

# Ads: production IDs only, and Info.plist must match the assigned AppConfig value.
app_id=re.search(r'enum AdMob \{.*?static let appID = "([^"]+)"',text,re.S)
if not app_id:
    blockers.append('AdMob app ID could not be read from AppConfig.swift.')
else:
    assigned_app_id=app_id.group(1)
    if assigned_app_id.startswith('ca-app-pub-3940256099942544') or str(info.get('GADApplicationIdentifier','')).startswith('ca-app-pub-3940256099942544'):
        blockers.append('Google official TEST AdMob IDs are still configured.')
    if info.get('GADApplicationIdentifier') != assigned_app_id:
        blockers.append('Info.plist GADApplicationIdentifier does not match AppConfig.AdMob.appID.')

# Cloud configuration is optional when disabled.
cloud_enabled=re.search(r'enum Cloud \{.*?static let enabled = (true|false)',text,re.S)
cloud_container=re.search(r'static let containerIdentifier = "([^"]+)"',text)

# Game Center. Ignore the staged Cloud placeholder when Cloud sync is disabled.
placeholders=sorted(set(re.findall(r'CHANGE_ME_[A-Za-z0-9_.-]+',text)))
if not (cloud_enabled and cloud_enabled.group(1)=='true'):
    placeholders=[x for x in placeholders if not x.startswith('CHANGE_ME_iCloud')]
if placeholders: blockers.append('Production Game Center placeholders remain: '+', '.join(placeholders))
achievement_names=['survive60','survive120','echoes10','closeCalls15','stage6','shards100','dashes100','specialEchoes50','arenaEvents25','bossEncounters10']
for name in achievement_names:
    if not re.search(rf'static let {name} = "[^"]+"',text): blockers.append(f'Game Center achievement ID missing: {name}')
if not re.search(r'static let leaderboardID = "[^"]+"',text): blockers.append('Game Center leaderboard ID missing.')

# Cloud: optional, but enabled requires production container and entitlement capability configured separately.
if cloud_enabled and cloud_enabled.group(1)=='true':
    if not cloud_container or not cloud_container.group(1).startswith('iCloud.') or 'CHANGE_ME' in cloud_container.group(1):
        blockers.append('Cloud sync is enabled but the production iCloud container is not configured.')

# StoreKit namespace.
bundle=re.search(r'static let bundleIdentifier = "([^"]+)"',text)
products=re.findall(r'static let (?:removeAds|premiumNeon) = "([^"]+)"',text)
if bundle:
    bad=[p for p in products if not p.startswith(bundle.group(1)+'.')]
    if bad: blockers.append('StoreKit product IDs do not match bundle namespace: '+', '.join(bad))
else: blockers.append('Bundle identifier could not be read from AppConfig.swift.')

# App metadata that ships in the binary.
if info.get('ITSAppUsesNonExemptEncryption') is not False:
    blockers.append('ITSAppUsesNonExemptEncryption is not explicitly false; review export compliance before release.')
if not info.get('NSUserTrackingUsageDescription'):
    blockers.append('NSUserTrackingUsageDescription is missing while advertising SDK integration is enabled.')
if not info.get('SKAdNetworkItems'):
    blockers.append('SKAdNetworkItems is empty/missing.')

if blockers:
    print('ECHO LOOP V10 RELEASE PREFLIGHT: BLOCKED'); print('='*42)
    for item in blockers: print(f'[BLOCK] {item}')
    print('\nApply a real ProductionConfig.json, verify Apple capabilities, then rerun this command.')
    sys.exit(2)
print('ECHO LOOP V10 RELEASE PREFLIGHT: PASS')
print('No known binary production-configuration blockers were found.')
