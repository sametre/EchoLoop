#!/usr/bin/env python3
from __future__ import annotations
import json, struct, subprocess, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
block=[]

p=subprocess.run([sys.executable,str(ROOT/'Tools/release_preflight.py')],cwd=ROOT,text=True,capture_output=True)
if p.returncode: block.append('Binary release preflight is not passing.\n'+p.stdout.strip())

for path in [ROOT/'AppStore/metadata/en-US.json',ROOT/'AppStore/metadata/tr-TR.json']:
    try: m=json.loads(path.read_text(encoding='utf-8'))
    except Exception as e: block.append(f'Invalid metadata file {path.name}: {e}'); continue
    for field,limit in {'name':30,'subtitle':30,'promotionalText':170,'description':4000}.items():
        value=m.get(field,'')
        if not value: block.append(f'{path.name}: {field} is empty')
        elif len(value)>limit: block.append(f'{path.name}: {field} exceeds {limit} characters ({len(value)})')
    kw=m.get('keywords','').encode('utf-8')
    if not kw: block.append(f'{path.name}: keywords empty')
    elif len(kw)>100: block.append(f'{path.name}: keywords exceed 100 bytes ({len(kw)})')
    for field in ('supportURL','privacyPolicyURL'):
        value=m.get(field,'')
        if 'REPLACE_WITH' in value or not value.startswith('https://'): block.append(f'{path.name}: {field} is not a production HTTPS URL')
    if 'REPLACE_WITH' in m.get('copyright','') or not m.get('copyright','').strip(): block.append(f'{path.name}: copyright owner is unresolved')

for page in [ROOT/'AppStore/website/privacy.html',ROOT/'AppStore/website/support.html']:
    if not page.exists(): block.append(f'Missing {page.relative_to(ROOT)}')
    elif 'REPLACE_WITH_SUPPORT_EMAIL' in page.read_text(encoding='utf-8'): block.append(f'{page.name}: support email placeholder remains')

def png_size(path:Path):
    b=path.read_bytes()[:24]
    if len(b)<24 or b[:8]!=b'\x89PNG\r\n\x1a\n' or b[12:16]!=b'IHDR': return None
    return struct.unpack('>II',b[16:24])

families={
    'iphone69': {(1260,2736),(1290,2796),(1320,2868)},
    'ipad13': {(2064,2752),(2048,2732)},
}
for family,accepted in families.items():
    directory=ROOT/'AppStore/screenshots'/family
    images=[p for p in directory.glob('*.png') if p.is_file()]
    if not images:
        block.append(f'No final {family} PNG screenshots in {directory.relative_to(ROOT)}/')
        continue
    if len(images)>10: block.append(f'{family}: App Store allows at most 10 screenshots; found {len(images)}')
    for image in images:
        size=png_size(image)
        if size not in accepted: block.append(f'{family}: {image.name} has unsupported portrait size {size}; accepted {sorted(accepted)}')

if block:
    print('ECHO LOOP APP STORE SUBMISSION PREFLIGHT: BLOCKED'); print('='*49)
    for x in block: print('[BLOCK]',x)
    sys.exit(2)
print('ECHO LOOP APP STORE SUBMISSION PREFLIGHT: PASS')
