from pathlib import Path
import json,collections,hashlib
p=Path(__file__).resolve().parent
rows={v:json.loads((p/f'results-{v}.json').read_text()) for v in ['before','after']}
keys=['kraken','worldSerpent','expedition','death','cap']
def stats(rs):
 return {'starts':len(rs),**{k:sum(r[k] for r in rs) for k in keys},'errors':sum(r['error'] is not None for r in rs),'utilityUses':sum(r['utilityUses'] for r in rs),'passCommands':sum(r['passCommands'] for r in rs)}
summary={'aggregate':{v:stats(rs) for v,rs in rows.items()},'groups':[],'paired':{}}
for b in ['hull1-mk1','hull4-mk2','hull4-mk3']:
 for q in ['none','recklessHelmsman','impatient']:
  group={'build':b,'quirk':q}
  for v,rs in rows.items(): group[v]=stats([r for r in rs if r['build']==b and r['quirk']==q])
  summary['groups'].append(group)
for b in ['hull1-mk1','hull4-mk2','hull4-mk3']:
 pairs=list(zip([r for r in rows['before'] if r['build']==b],[r for r in rows['after'] if r['build']==b]))
 for x,y in pairs: assert (x['build'],x['quirk'],x['hull'],x['seed'])==(y['build'],y['quirk'],y['hull'],y['seed'])
 summary['paired'][b]={'beforeOnlyFinalClear':sum(x['expedition'] and not y['expedition'] for x,y in pairs),'afterOnlyFinalClear':sum(y['expedition'] and not x['expedition'] for x,y in pairs),'sameFinalOutcome':sum(x['expedition']==y['expedition'] for x,y in pairs)}
summary['freshParity']={'identicalRows':149,'rows':150,'exception':{'seed':507,'quirk':'impatient','reason':'Normal stronghold hull upgrades reach hull III/base35 with Mk I utility; old doubling is70, approved additive rule is60. Initial hull I/base25 activations both50.','trace':'trace-before.json / trace-after.json'}}
summary['progressedInputs']={'hullIVBaseEvasion':40,'oldAllMarks':80,'newMkII':80,'newMkIII':95}
summary['limitations']=['50 matched seeds per build/trait; one CautiousBot policy, descriptive evidence rather than player-balance prediction.','No Boon; fixed none/Reckless Helmsman/Impatient; Clipper ownership only (core also always owns Standard), gold25 and ancestral I. Synthetic hull IV/Mk II or III assigned after departure to avoid home refit reset; subsequent rewards/upgrades normal.','Before retains new getters but activation restores old doubling. Current range modifier removal and Wait & Reload no-evasion behavior remain in both.','Final clear requires expeditionVictory; Kraken/World Serpent crossings use chart timesCompleted >=1/>=2.']
(p/'summary.json').write_text(json.dumps(summary,indent=2))
print(json.dumps(summary,indent=2))
