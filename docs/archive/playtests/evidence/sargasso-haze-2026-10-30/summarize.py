from pathlib import Path
import json,collections,difflib
p=Path('.dart_tool/sargasso-haze-audit'); rows={v:json.loads((p/f'results-{v}.json').read_text()) for v in ['before','after']}
def stats(a):
 return {'starts':len(a),**{k:sum(r[k] for r in a) for k in ['clear','death','cap','monsters','battles','hazeVerified','shipAttacks','shipMisses']},'errors':sum(r['error'] is not None for r in a),'firstPenalties':dict(collections.Counter(r['firstPenalty'] for r in a))}
s={'aggregate':{v:stats(a) for v,a in rows.items()},'groups':[]}
for build in ['hull2-mk1','hull4-mk3']:
 for hull in ['standard','ironclad','clipper','bombardier','corsair']:
  g={'build':build,'hull':hull}
  for v,a in rows.items():g[v]=stats([r for r in a if r['build']==build and r['hull']==hull])
  s['groups'].append(g)
s['limitations']=['50 matched seeds per hull/build; one CautiousBot policy, descriptive evidence rather than player-balance prediction.','Synthetic Region2 arrival skips Region1 history/rewards. All hulls are factory-built with ancestral I, gold25, no starting traits/blessings/relics/pacts, and no free cargo. Only chosen blueprint plus always-owned Standard is unlocked.','Normal course selection, shrine rewards, combat, recovery and upgrades continue after setup. Haze checks validate obscurity at battle entry, before later flare/ink changes.','Stop at timesCompleted>=2 confirms World Serpent cleared; Kraken was skipped and is not scored.','Ship attack/miss counts use structured event side fields; misses are accuracy misses, distinct from monster dodges.']
(p/'summary.json').write_text(json.dumps(s,indent=2));print(json.dumps(s['aggregate'],indent=2))
for g in s['groups']:print(g['build'],g['hull'],'clear',g['before']['clear'],g['after']['clear'],'monsters',g['before']['monsters'],g['after']['monsters'])
print('Errors:',collections.Counter(r['error'] for a in rows.values() for r in a if r['error']))
a=(p/'after/monstrous_core/lib/src/session/game_session.dart').read_text();b=(p/'before/monstrous_core/lib/src/session/game_session.dart').read_text();(p/'source-diff.patch').write_text('\n'.join(difflib.unified_diff(a.splitlines(),b.splitlines(),fromfile='after',tofile='before',lineterm=''))+'\n')
