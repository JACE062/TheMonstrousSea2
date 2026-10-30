from pathlib import Path
import json,hashlib
from urllib.parse import urljoin
p=Path(__file__).resolve().parent
manifest=json.loads((p/'source-manifest.json').read_text())
for v,files in manifest.items():
 for f,h in files.items(): assert hashlib.sha256((p/v/f).read_bytes()).hexdigest()==h,(v,f)
 config=json.loads((p/v/'monstrous_sim/.dart_tool/package_config.json').read_text())
 for package in ['monstrous_core','monstrous_sim']:
  actual=next(x['rootUri'] for x in config['packages'] if x['name']==package)
  assert urljoin((p/v/'monstrous_sim/.dart_tool/package_config.json').as_uri(),actual).rstrip('/')==(p/v/package).as_uri()
 assert (p/v/'monstrous_sim/audit.dart').read_bytes()==(p/'audit.dart').read_bytes()
a=(p/'after/monstrous_core/lib/src/session/game_session.dart').read_text(); b=(p/'before/monstrous_core/lib/src/session/game_session.dart').read_text()
assert a.replace('      currentMonster!.obscuredAcMod = max(currentMonster!.obscuredAcMod, 10);\n','',1)==b
rows=[json.loads((p/f'results-{v}.json').read_text()) for v in ['before','after']]
assert len(rows[0])==len(rows[1])==500
for x,y in zip(*rows):
 assert (x['build'],x['hull'],x['seed'])==(y['build'],y['hull'],y['seed'])
 assert x['startRegion']==y['startRegion']==1
 assert y['firstPenalty']==max(x['firstPenalty'],10)
for aRows in rows:
 for r in aRows:
  assert r['error'] is None and not r['cap']
  assert r['clear'] != r['death']
  assert r['battles']>0 and r['hazeVerified']==r['battles']
for f in (p/'after').rglob('*.dart'):
 if 'lib' in f.parts:
  assert f.read_bytes()==(p.parents[1]/'packages'/f.relative_to(p/'after')).read_bytes(),f
print('Verified snapshot hashes, isolated configs, identical audit scripts, exact one-line baseline difference, all1000 Sargasso starts/terminal outcomes, and all battle-entry haze checks. After lib matches current production.')
