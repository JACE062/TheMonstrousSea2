import 'dart:convert';
import 'dart:io';
import 'package:monstrous_core/monstrous_core.dart';
import '../../packages/monstrous_sim/lib/src/strategy/cautious_bot.dart';

const slots=[HardpointType.broadside,HardpointType.signature,HardpointType.utility];
bool full(GameSession s)=>s.ship!.level==4 && slots.every((x)=>s.ship!.markForHardpoint(x)==3);
Map<String,dynamic> state(GameSession s)=>{'region':s.seaChart.currentRegionIndex+1,'leg':s.seaChart.currentLeg,'difficulty':s.seaChart.currentDifficulty,'gold':s.ship!.gold,'hp':s.ship!.currentHp,'maxHp':s.ship!.maxHp,'hull':s.ship!.level,'marks':[for(final x in slots)s.ship!.markForHardpoint(x)]};
String? shopKey(GameSession s)=>s.canUseVoyageShipwright?'${s.seaChart.currentRegionIndex+1}:${s.phase==SessionPhase.stronghold?'stronghold':'haven'}':null;
Command? purchase(GameSession s,String priority){
 final ship=s.ship!;
 Command? hull()=>ship.level<4 && ship.gold>=calculateShipUpgradeCost(ship.level)?const UpgradeShip():null;
 Command? fitting(){
  final candidates=slots.where((x)=>ship.markForHardpoint(x)<3).toList()..sort((a,b)=>ship.markForHardpoint(a).compareTo(ship.markForHardpoint(b)));
  for(final x in candidates){if(ship.gold>=calculateHardpointTemperCost(ship.markForHardpoint(x)))return TemperHardpoint(x);}
  return null;
 }
 return priority=='hull-first'?(hull()??fitting()):(fitting()??hull());
}
Command choose(GameSession s,String priority){
 if(s.phase==SessionPhase.stronghold){
  if(s.ship!.currentHp<s.ship!.maxHp && s.ship!.gold>=s.repairCostFor(1))return const RepairShip(1);
  return purchase(s,priority)??const TakeHelm();
 }
 if(s.phase==SessionPhase.respiteIsland && s.isCurrentIslandHaven && s.hasChosenIslandDuty)return purchase(s,priority)??const DepartIsland();
 final c=const CautiousBot().decideNextAction(s);
 if(c is EquipCargoWeapon)throw StateError('Legacy weapon command forbidden');
 if(c is BuyMerchantItem)throw StateError('Merchant purchase not part of policy');
 if(c is RepairShip && s.phase!=SessionPhase.smuggler && s.phase!=SessionPhase.port)throw StateError('Unexpected repair ${s.phase}');
 return c;
}
Map<String,dynamic> run(BlueprintId bp,bool progressed,String priority,int seed){
 final profile=ProfileData(unlockedBlueprints:{'standard',bp.name},activeBlueprintId:bp.name,blueprintArmamentTiers:progressed?{bp.name:2}:{},portCivicLevels:progressed?{HarborMonumentId.serpentEffigy.name:1}:{});
 final s=GameSession(rng:SeededGameRng(seed),profile:profile);
 s.dispatch(const NameCaptain('Audit Captain'));
 s.dispatch(ChooseShip(bp.shipClass));
 final start=state(s);
 s.dispatch(const VentureOutToSea());
 if(profile.armamentTierFor(bp)!=(progressed?2:1)||profile.monumentBountyGoldMultiplier!=(progressed?1.1:1)||s.ship!.level!=1||s.ship!.gold!=25||s.ship!.cargo.isNotEmpty||s.activeBoon!=null||s.activeQuirk!=null)throw StateError('Starting profile verification failed');
 final signature=s.ship!.equippedWeapons.firstWhere((w)=>w.isSignature).damage;
 final shops=<Map<String,dynamic>>[];
 final transactions=<Map<String,dynamic>>[];
 final gross=<String,int>{};
 final spent=<String,int>{};
 final battles=<Map<String,dynamic>>[];
 Map<String,dynamic>? firstMax;
 Map<String,dynamic>? currentShop;
 String? lastKey;
 int? incomingOffered;
 var steps=0;String? error;
 try{
 while(s.phase!=SessionPhase.death && s.phase!=SessionPhase.expeditionVictory && s.phase!=SessionPhase.ended && steps<2500){
  final key=shopKey(s);
  if(key!=lastKey){
   if(key!=null){currentShop={'key':key,'arrival':state(s),'incomingOfferedDifficulty':incomingOffered,'repairs':0,'hullSpend':0,'fittingSpend':0};shops.add(currentShop);}
   else{currentShop=null;}
   lastKey=key;
  }
  final c=choose(s,priority);
  if(key!=null && (c is UpgradeShip || c is TemperHardpoint || c is DepartIsland || c is TakeHelm))currentShop!['beforePurchases']??=state(s);
  final before=state(s);final phase=s.phase;
  if(c is SteerCourse){incomingOffered=s.seaChart.currentCourseOptions.where((o)=>o.bearing==c.bearing).firstOrNull?.difficultyLevel;}
  final events=s.dispatch(c);steps++;
  final delta=s.ship!.gold-(before['gold'] as int);
  if(delta!=0){
   String category;
   if(delta<0){category=c is RepairShip?'repair':c is UpgradeShip?'hull':c is TemperHardpoint?'fitting':c is BuyMerchantItem?'supplies':'other-spend';spent[category]=(spent[category]??0)-delta;}
   else{category=events.any((e)=>e is LootDropped)?'victory':c is SalvageShipwreck?'wreck':c is ForageShoalsAtIsland?'forage':c is SellCargoItem||c is SellAllTreasure?'sales':'other-income';gross[category]=(gross[category]??0)+delta;}
   transactions.add({'step':steps,'command':c.runtimeType.toString(),'phase':phase.name,'category':category,'delta':delta,'before':before,'after':state(s)});
   if(key!=null && delta<0){final f=c is RepairShip?'repairs':c is UpgradeShip?'hullSpend':'fittingSpend';currentShop![f]=(currentShop[f] as int)-delta;}
  }
  if(events.any((e)=>e is LootDropped))battles.add({'before':before,'after':state(s),'apex':s.currentMonster?.isApex,'species':s.currentMonster?.species.name,'gold':delta,'offeredDifficulty':incomingOffered});
  if(full(s)&&firstMax==null)firstMax={'shop':key,...state(s),'step':steps};
  if(key!=null)currentShop!['departure']=state(s);
 }
 }catch(e,st){error='$e\n$st';}
 final end=state(s);
 final earned=gross.values.fold(0,(a,b)=>a+b);final spending=spent.values.fold(0,(a,b)=>a+b);
 if(25+earned-spending!=s.ship!.gold)throw StateError('Ledger mismatch');
 return {'hull':bp.name,'profile':progressed?'progressed':'fresh','priority':priority,'seed':seed,'start':start,'startingSignatureDamage':signature,'startingAncestralTier':profile.armamentTierFor(bp),'startingIdolMultiplier':profile.monumentBountyGoldMultiplier,'terminal':s.phase.name,'capped':steps>=2500,'error':error,'steps':steps,'gross':gross,'spend':spent,'final':end,'firstMax':firstMax,'shops':shops,'transactions':transactions,'battles':battles};
}
void main(){
 final rows=<Map<String,dynamic>>[];
 for(final progressed in [false,true])for(final bp in BlueprintId.values)for(final priority in ['hull-first','fitting-first'])for(var i=0;i<30;i++){rows.add(run(bp,progressed,priority,42+31*i));}
 final dir=Directory('.dart_tool/gold-economy-audit');dir.createSync(recursive:true);
 File('${dir.path}/baseline_rows.jsonl').writeAsStringSync(rows.map(jsonEncode).join('\n')+'\n');
 double mean(Iterable<num> xs)=>xs.isEmpty?0:xs.reduce((a,b)=>a+b)/xs.length;
 final groups=<Map<String,dynamic>>[];
 for(final profile in ['fresh','progressed'])for(final bp in BlueprintId.values)for(final priority in ['hull-first','fitting-first']){
  final rs=rows.where((r)=>r['profile']==profile&&r['hull']==bp.name&&r['priority']==priority).toList();
  final coverage=<String,dynamic>{};
  for(final key in ['1:haven','2:stronghold','2:haven','3:stronghold','3:haven']){
   final visits=rs.expand((r)=>(r['shops'] as List).cast<Map<String,dynamic>>()).where((s)=>s['key']==key).toList();
   final maxCount=visits.where((s){final d=s['departure'] as Map;return d['hull']==4&&(d['marks'] as List).every((x)=>x==3);}).length;
   coverage[key]={'visits':visits.length,'maxAtDeparture':maxCount,'conditionalMaxRate':visits.isEmpty?null:maxCount/visits.length,'meanArrivalGold':mean(visits.map((s)=>s['arrival']['gold'] as int)),'meanBeforePurchaseGold':mean(visits.map((s)=>s['beforePurchases']?['gold'] as int? ?? s['departure']['gold'] as int))};
  }
  final milestones=<String,int>{};for(final r in rs){final k=r['firstMax']?['shop'] as String? ?? 'never';milestones[k]=(milestones[k]??0)+1;}
  groups.add({'profile':profile,'hull':bp.name,'priority':priority,'runs':rs.length,'wins':rs.where((r)=>r['terminal']=='expeditionVictory').length,'deaths':rs.where((r)=>r['terminal']=='death').length,'caps':rs.where((r)=>r['capped']==true).length,'errors':rs.where((r)=>r['error']!=null).length,'meanGross':mean(rs.map((r)=>(r['gross'] as Map).values.cast<int>().fold(0,(a,b)=>a+b))),'meanRepairSpend':mean(rs.map((r)=>r['spend']['repair'] as int? ?? 0)),'meanUpgradeSpend':mean(rs.map((r)=>(r['spend']['hull'] as int? ?? 0)+(r['spend']['fitting'] as int? ?? 0))),'meanFinalGold':mean(rs.map((r)=>r['final']['gold'] as int)),'firstMax':milestones,'coverage':coverage});
 }
 final summary={'runs':rows.length,'wins':rows.where((r)=>r['terminal']=='expeditionVictory').length,'deaths':rows.where((r)=>r['terminal']=='death').length,'caps':rows.where((r)=>r['capped']==true).length,'errors':rows.where((r)=>r['error']!=null).length,'groups':groups};
 File('${dir.path}/baseline_summary.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert(summary));
 print(jsonEncode(summary));
}
