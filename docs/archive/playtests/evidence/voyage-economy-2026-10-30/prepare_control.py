from pathlib import Path
p=Path('.dart_tool/gold-economy-audit/pilots')
s=(p/'candidate1/pilot.dart').read_text().replace("import 'monstrous_sim/lib/src/strategy/cautious_bot.dart';","import '../../../packages/monstrous_sim/lib/src/strategy/cautious_bot.dart';").replace("Directory('.dart_tool/gold-economy-audit/pilots/candidate1')","Directory('.dart_tool/gold-economy-audit/pilots/control')")
(p/'control.dart').write_text(s)
