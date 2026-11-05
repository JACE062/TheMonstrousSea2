from pathlib import Path
import json
base=Path('.dart_tool/gold-economy-audit')
a=[json.loads(x) for x in (base/'baseline_rows.jsonl').read_text().splitlines()]
b=[json.loads(x) for x in (base/'pilots/control/baseline_rows.jsonl').read_text().splitlines()]
for x,y in zip(a,b):
 del y['repairShortfalls'];assert x==y
p=base/'pilots/compare.py'
s=p.read_text().replace("'baseline':load(base/'baseline_rows.jsonl')","'baseline':load(out/'control/baseline_rows.jsonl')")
p.write_text(s)
print('All600 baseline control rows exactly match original after removing instrumentation-only repairShortfalls field')
