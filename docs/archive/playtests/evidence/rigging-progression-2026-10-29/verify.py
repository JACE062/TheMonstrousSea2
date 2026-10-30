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
a=(p/'after/monstrous_core/lib/src/traits/trait.dart').read_text(); b=(p/'before/monstrous_core/lib/src/traits/trait.dart').read_text()
assert b.replace('actor.currentEvasion = (actor.baseEvasion * 2).clamp(0, 100);','actor.currentEvasion = actor.evasiveRiggingEvasion;',1)==a
rows=[json.loads((p/f'results-{v}.json').read_text()) for v in ['before','after']]
freshDifferences=[]
for x,y in zip(*rows):
 assert (x['build'],x['quirk'],x['seed'])==(y['build'],y['quirk'],y['seed'])
 if x['build']=='hull1-mk1' and {k:v for k,v in x.items() if k!='version'}!={k:v for k,v in y.items() if k!='version'}:
  freshDifferences.append((x['quirk'],x['seed']))
assert freshDifferences==[('impatient',507)]
for version in ['before','after']:
 trace=json.loads((p/f'trace-{version}.json').read_text())[0]['utilityTrace']
 assert all(t['oldEvasion']==t['newEvasion']==50 for t in trace if t['level']==1)
 assert next(t for t in trace if t['step']==64)=={'step':64,'level':3,'baseEvasion':35,'utilityMark':1,'newEvasion':60,'oldEvasion':70}
print('Verified hashes, isolated bindings, identical scripts, exact one-assignment diff. Fresh rows149/150 identical; seed507 qualification verified by trace after normal hull upgrades.')
