#!/usr/bin/env python3
from __future__ import annotations
import json, plistlib, re, sys
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
CONFIG=ROOT/'EchoLoop/Config/AppConfig.swift'
INFO=ROOT/'EchoLoop/Info.plist'
META=[ROOT/'AppStore/metadata/en-US.json', ROOT/'AppStore/metadata/tr-TR.json']
PRIVACY=ROOT/'AppStore/website/privacy.html'
SUPPORT=ROOT/'AppStore/website/support.html'

if len(sys.argv)!=2:
    print('Usage: python3 Tools/apply_production_config.py ProductionConfig.json', file=sys.stderr); sys.exit(2)
p=Path(sys.argv[1]); data=json.loads(p.read_text(encoding='utf-8'))

def req(obj,path):
    cur=obj
    for part in path.split('.'):
        if part not in cur or cur[part] in (None,''):
            raise SystemExit(f'Missing required config value: {path}')
        cur=cur[part]
    return cur

ad={k:req(data,f'adMob.{k}') for k in ('appID','banner','interstitial','rewarded')}
if not re.fullmatch(r'ca-app-pub-\d{16}~\d{10}',ad['appID']): raise SystemExit('Invalid AdMob appID format')
for k in ('banner','interstitial','rewarded'):
    if not re.fullmatch(r'ca-app-pub-\d{16}/\d{10}',ad[k]): raise SystemExit(f'Invalid AdMob {k} format')
gc=req(data,'gameCenter'); leaderboard=req(data,'gameCenter.leaderboardID')
if 'CHANGE_ME' in leaderboard: raise SystemExit('Game Center leaderboard cannot be a placeholder')
achievement_names=['survive60','survive120','echoes10','closeCalls15','stage6','shards100','dashes100','specialEchoes50','arenaEvents25','bossEncounters10']
achievements={n:req(data,f'gameCenter.achievements.{n}') for n in achievement_names}
if any('CHANGE_ME' in v for v in achievements.values()): raise SystemExit('Game Center achievements contain placeholders')

text=CONFIG.read_text(encoding='utf-8')
def replace_static(name,value, text):
    pattern=rf'(static let {re.escape(name)} = )"[^"]*"'
    text2,n=re.subn(pattern, lambda m: m.group(1)+json.dumps(value), text, count=1)
    if n!=1: raise SystemExit(f'Could not patch static let {name}')
    return text2
text=replace_static('leaderboardID',leaderboard,text)
for k,v in achievements.items(): text=replace_static(k,v,text)
for k,v in ad.items(): text=replace_static(k,v,text)
cloud=data.get('cloud',{})
if bool(cloud.get('enabled',False)):
    cid=cloud.get('containerIdentifier','')
    if not cid.startswith('iCloud.') or 'CHANGE_ME' in cid: raise SystemExit('Cloud enabled but containerIdentifier is invalid')
    text=re.sub(r'(enum Cloud \{.*?static let enabled = )(?:true|false)',r'\g<1>true',text,flags=re.S,count=1)
    text=replace_static('containerIdentifier',cid,text)
else:
    text=re.sub(r'(enum Cloud \{.*?static let enabled = )(?:true|false)',r'\g<1>false',text,flags=re.S,count=1)
CONFIG.write_text(text,encoding='utf-8')

with INFO.open('rb') as f: info=plistlib.load(f)
info['GADApplicationIdentifier']=ad['appID']
with INFO.open('wb') as f: plistlib.dump(info,f,sort_keys=False)

storefront=data.get('storefront',{})
support_url=storefront.get('supportURL','')
privacy_url=storefront.get('privacyPolicyURL','')
email=storefront.get('supportEmail','')
copyright_owner=storefront.get('copyrightOwner','')
for label,url in [('supportURL',support_url),('privacyPolicyURL',privacy_url)]:
    if not url.startswith('https://'): raise SystemExit(f'{label} must be a public HTTPS URL')
if '@' not in email: raise SystemExit('supportEmail appears invalid')
if not copyright_owner: raise SystemExit('storefront.copyrightOwner is required')
for path in META:
    m=json.loads(path.read_text(encoding='utf-8'))
    m['supportURL']=support_url; m['privacyPolicyURL']=privacy_url; m['copyright']='2026 '+copyright_owner
    path.write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
for path in (PRIVACY,SUPPORT):
    s=path.read_text(encoding='utf-8').replace('REPLACE_WITH_SUPPORT_EMAIL',email)
    path.write_text(s,encoding='utf-8')
print('Production configuration applied. No secret credentials were stored in the Xcode project.')
