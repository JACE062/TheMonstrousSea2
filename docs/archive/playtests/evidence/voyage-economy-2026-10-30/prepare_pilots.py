from pathlib import Path
import shutil,json,difflib,subprocess
root=Path.cwd()
base=root/'.dart_tool/gold-economy-audit'
pilots=base/'pilots'
source=(base/'baseline.dart').read_text()
config=json.loads((root/'packages/monstrous_sim/.dart_tool/package_config.json').read_text())
for candidate in ['candidate1','candidate2']:
 dest=pilots/candidate
 dest.mkdir(exist_ok=True)
 for package in ['monstrous_core','monstrous_sim']:
  shutil.copytree(root/'packages'/package/'lib',dest/package/'lib',dirs_exist_ok=True)
 loot=dest/'monstrous_core/lib/src/rules/loot.dart'
 original=loot.read_text()
 assert original.count('final base = 100 * pow(1.35, monsterLevel);')==1
 loot.write_text(original.replace('final base = 100 * pow(1.35, monsterLevel);','final base = 200 + 25 * (monsterLevel - 4);'))
 if candidate=='candidate2':
  ship=dest/'monstrous_core/lib/src/content/ships.dart'
  original=ship.read_text()
  assert original.count('2 => 120,')==1 and original.count('3 => 500,')==1
  ship.write_text(original.replace('2 => 120,','2 => 350,').replace('3 => 500,','3 => 1200,'))
 cfg=json.loads(json.dumps(config))
 for pkg in cfg['packages']:
  if pkg['name'] in ['monstrous_core','monstrous_sim']:pkg['rootUri']=(dest/pkg['name']).as_uri()
  elif not pkg['rootUri'].startswith('file:'):
   pkg['rootUri']=((root/'packages/monstrous_sim/.dart_tool')/pkg['rootUri']).resolve().as_uri()
 (dest/'package_config.json').write_text(json.dumps(cfg,indent=2))
 script=source.replace("import '../../packages/monstrous_sim/lib/src/strategy/cautious_bot.dart';","import 'monstrous_sim/lib/src/strategy/cautious_bot.dart';")
 script=script.replace("Directory('.dart_tool/gold-economy-audit')",f"Directory('.dart_tool/gold-economy-audit/pilots/{candidate}')")
 script=script.replace("final battles=<Map<String,dynamic>>[];","final battles=<Map<String,dynamic>>[];\n final repairShortfalls=<Map<String,dynamic>>[];")
 script=script.replace('final c=choose(s,priority);',"""final c=choose(s,priority);
  if(s.phase==SessionPhase.stronghold && s.ship!.currentHp<s.ship!.maxHp && s.ship!.gold<s.repairCostFor(1) && (c is UpgradeShip || c is TemperHardpoint || c is TakeHelm))repairShortfalls.add({'type':'stronghold-full-unaffordable','quotedCost':s.repairCostFor(1),'chosenCommand':c.runtimeType.toString(),...state(s)});
  if(s.phase==SessionPhase.smuggler && s.ship!.currentHp<s.ship!.maxHp*.75 && s.ship!.gold<s.repairCostFor(.25) && c is DepartSmuggler)repairShortfalls.add({'type':'smuggler-quarter-unaffordable','quotedCost':s.repairCostFor(.25),...state(s)});
""")
 script=script.replace("'battles':battles", "'battles':battles,'repairShortfalls':repairShortfalls")
 (dest/'pilot.dart').write_text(script)
 diffs=[];changed=[]
 for package in ['monstrous_core','monstrous_sim']:
  for f in (root/'packages'/package/'lib').rglob('*.dart'):
   copied=dest/package/f.relative_to(root/'packages'/package)
   a=f.read_text();b=copied.read_text()
   if a!=b:
    changed.append(str(f.relative_to(root)))
    diffs.extend(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile=str(f.relative_to(root)),tofile=str(copied.relative_to(root))))
 expected=['packages\\monstrous_core\\lib\\src\\rules\\loot.dart']
 if candidate=='candidate2':expected.append('packages\\monstrous_core\\lib\\src\\content\\ships.dart')
 assert sorted(changed)==sorted(expected),(candidate,changed)
 (dest/'source.diff').write_text(''.join(diffs))
 print(candidate,'only changed',changed)
 (dest/'manifest.json').write_text(json.dumps({'candidate':candidate,'unapproved':True,'productionHead':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),'sourceChangedFiles':changed,'seedFormula':'42+31*i; i=0..29','runs':600,'noFinalServiceAdded':True},indent=2))
