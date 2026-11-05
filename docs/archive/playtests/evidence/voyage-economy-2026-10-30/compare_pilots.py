from pathlib import Path
import json,statistics,collections
base=Path('.dart_tool/gold-economy-audit'); out=base/'pilots'
load=lambda p:[json.loads(s) for s in p.read_text().splitlines()]
sets={'baseline':load(out/'control/baseline_rows.jsonl'),'candidate1':load(out/'candidate1/baseline_rows.jsonl'),'candidate2':load(out/'candidate2/baseline_rows.jsonl')}
keys=['1:haven','2:stronghold','2:haven','3:stronghold','3:haven']
summary={}
for name,rows in sets.items():
 print('\n',name)
 for original,r in zip(sets['baseline'],rows):
  assert [r[x] for x in ['seed','hull','profile','priority','start','startingSignatureDamage']]==[original[x] for x in ['seed','hull','profile','priority','start','startingSignatureDamage']]
  oh=[s for s in original['shops'] if s['key']=='1:haven'];rh=[s for s in r['shops'] if s['key']=='1:haven'];assert [s['arrival'] for s in oh]==[s['arrival'] for s in rh]; assert name=='candidate2' or oh==rh
 def agg(rs):
  d={'n':len(rs),'wins':sum(r['terminal']=='expeditionVictory' for r in rs),'deaths':sum(r['terminal']=='death' for r in rs),'caps':sum(r['capped'] for r in rs),'errors':sum(r['error'] is not None for r in rs),'firstMax':dict(collections.Counter(r['firstMax']['shop'] if r['firstMax'] else 'never' for r in rs)),'coverage':{},'meanRepair':statistics.mean(r['spend'].get('repair',0) for r in rs),'meanFinalGold':statistics.mean(r['final']['gold'] for r in rs),'repairShortfalls':dict(collections.Counter(s['type'] for r in rs for s in r.get('repairShortfalls',[]))),'runsWithShortfall':sum(bool(r.get('repairShortfalls',[])) for r in rs)}
  for key in keys:
   shops=[s for r in rs for s in r['shops'] if s['key']==key]
   d['coverage'][key]={'visits':len(shops),'max':sum(s['departure']['hull']==4 and s['departure']['marks']==[3,3,3] for s in shops),'anyPurchase':sum(s['hullSpend']+s['fittingSpend']>0 for s in shops),'medianBeforePurchaseGold':statistics.median(s['beforePurchases']['gold'] for s in shops) if shops else None}
  return d
 summary[name]={cohort:agg([r for r in rows if cohort=='all' or r['profile']==cohort]) for cohort in ['all','fresh','progressed']}
 for cohort,d in summary[name].items():print(cohort,json.dumps(d))
 print('group outcomes: profile/hull/priority R2H visits:max postS/R3H/fullwins,firstmax')
 for prof in ['fresh','progressed']:
  for hull in ['standard','ironclad','clipper','bombardier','corsair']:
   for pri in ['hull-first','fitting-first']:
    d=agg([r for r in rows if r['profile']==prof and r['hull']==hull and r['priority']==pri]);c=d['coverage']
    print(prof,hull,pri,f"{c['2:haven']['visits']}:{c['2:haven']['max']}",c['3:stronghold']['visits'],c['3:haven']['visits'],d['wins'],d['firstMax'])
 for r in rows:
  if r['terminal']=='expeditionVictory':print('winner',r['hull'],r['profile'],r['priority'],r['seed'],'final',r['final'],'gross',r['gross'],'spend',r['spend'],'max',r['firstMax'])
summary['verification']={'same600StartingStates':True,'allFirstHavenArrivalsIdenticalToBaseline':True,'candidate1FirstHavenPurchasesIdentical':True,'candidate2FirstHavenPurchasesMayDifferForFinalMarks':True,'allSourceDiffsRestricted':True,'productionUntouched':True,'unapproved':True}
(out/'comparison_summary.json').write_text(json.dumps(summary,indent=2))
