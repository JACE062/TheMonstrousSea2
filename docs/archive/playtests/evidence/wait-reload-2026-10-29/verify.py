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
assert b.replace('    ship!.currentEvasion = min(90, ship!.currentEvasion + 10);\n    events.add(CombatEffectsChanged.capture(ship!));\n','',1)==a
rows=[json.loads((p/f'results-{v}.json').read_text()) for v in ['before','after']]
for x,y in zip(*rows):
 if x['quirk']!='impatient':
  assert {k:v for k,v in x.items() if k!='version'}=={k:v for k,v in y.items() if k!='version'}
print('Verified snapshot hashes, isolated package bindings, identical audit scripts, exact two-statement source difference, and identical non-Impatient rows.')
