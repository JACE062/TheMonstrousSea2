from pathlib import Path
import json,collections,hashlib
p=Path(__file__).resolve().parent
rows={v:json.loads((p/f'results-{v}.json').read_text()) for v in ['before','after']}
keys=['kraken','worldSerpent','expedition','death','cap']
def stats(rs):
 return {'starts':len(rs),**{k:sum(r[k] for r in rs) for k in keys},'errors':sum(r['error'] is not None for r in rs),'passCommands':sum(r['passCommands'] for r in rs)}
summary={'aggregate':{v:stats(rs) for v,rs in rows.items()},'groups':[],'paired':{}}
for b in ['fresh','progressed']:
 for q in ['none','skirmisher','impatient']:
  group={'build':b,'quirk':q}
  for v,rs in rows.items(): group[v]=stats([r for r in rs if r['build']==b and r['quirk']==q])
  summary['groups'].append(group)
for b in ['fresh','progressed']:
 pairs=list(zip([r for r in rows['before'] if r['build']==b],[r for r in rows['after'] if r['build']==b]))
 for x,y in pairs: assert (x['build'],x['quirk'],x['hull'],x['seed'])==(y['build'],y['quirk'],y['hull'],y['seed'])
 summary['paired'][b]={'beforeOnlyFinalClear':sum(x['expedition'] and not y['expedition'] for x,y in pairs),'afterOnlyFinalClear':sum(y['expedition'] and not x['expedition'] for x,y in pairs),'sameFinalOutcome':sum(x['expedition']==y['expedition'] for x,y in pairs)}
summary['limitations']=['30 matched seeds per hull/quirk/build, one CautiousBot policy; descriptive sample, not a player-balance prediction.','Only the +10 Brace evasion and its effect event differ; the former Skirmisher UI exception is not simulated.','No-Boon, fixed none/Skirmisher/Impatient; default profile except all hull ownership. Ancestral I. Synthetic progressed hull IV/Mk III is assigned after departure to avoid normal home refit reset. Normal rewards and upgrades then continue.','Bot chooses no passes for none or Skirmisher in this sample; only Impatient exercises the changed bonus. CautiousBot still contains a stale low-health range comment referencing evasion; its actual decisions are identical in both snapshots.','Final clear means actual expeditionVictory phase, not SimulationRunner.won or only crossing Kraken; Kraken/WorldSerpent crossings use chart timesCompleted >=1/>=2.']
(p/'summary.json').write_text(json.dumps(summary,indent=2))
print(json.dumps(summary,indent=2))
