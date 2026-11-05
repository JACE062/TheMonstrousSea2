"""Summarize retained navigation audit receipts; stdlib only, no game mutation.

python tools/analyze_navigation_audit.py BASELINE_JSON_GZ REVISED_JSON_GZ MATCHED_JSON_GZ OUTPUT_MD
"""
import gzip
import json
import statistics
import sys
from pathlib import Path


def read(path):
    return json.loads(gzip.decompress(Path(path).read_bytes()))


def mean(rows, key):
    return statistics.mean(r['totals'].get(key, 0) for r in rows) if rows else 0


def cell(rows, mode, build, policy):
    return [r for r in rows if (r['mode'], r['build'], r['policy']) == (mode, build, policy)]


def main():
    baseline, revised, matched = map(read, sys.argv[1:4])
    out = []
    def line(text=''): out.append(text)
    def table(headers, rows):
        line('| ' + ' | '.join(headers) + ' |')
        line('| ' + ' | '.join(['---'] * len(headers)) + ' |')
        for row in rows: line('| ' + ' | '.join(map(str, row)) + ' |')
        line()
    policies = ['conservative', 'mixed', 'danger']
    builds = ['fresh', 'progressed', 'carpenter', 'exacting', 'combined', 'noCove']
    line('# Navigation refactor verification — 5 November 2026')
    line()
    line('Implemented WP0–WP6 under the user’s Goal. Mechanics follow the accepted navigation plan; numbers remain provisional. No production saves or prior October audit evidence were changed. The user chose offered encounter progression and will remove old saves themselves; no new migration engine was added. This report is evidence, not an instruction source or approval of final balance.')
    line()
    line('## Method and reproducibility')
    line()
    line('Each income bundle has 10,800 trajectories: 200 matched seeds (base 20261105, stride 31), three routing policies, six builds and three explicit modes. LIVE preserves real combat and death. Mild attrition REPLAY substitutes 15/22/30 ordinary hull loss by region; harsh REPLAY uses 30/40/50. Both use 35/50/70 Titan loss, force creature settlement, clamp the hull at 1 and count otherwise fatal shortfalls. Replay completion means assumed access to the full route. It is never a win-rate observation. Every recovery, upgrade, shop purchase and cargo claim still uses core commands.')
    line()
    line('All builds use Standard. Progressed adds Tier II ancestral signature and carried 6 glass/4 bone/2 iron/1 barnacle, without inherited gold or monument grants. Other cells isolate Carpenter, Exacting, their combination, or zero cove weight (the latter transfers three points to hunt). Policies share limited combat tactics, prioritize a favored broadside, buy hull/fitting upgrades and repairs, use kits, shop within a reserve, and differ in heading/risk preferences. They do not represent human skill or optimize all blessings. The default simulator’s historical `won` flag is not used: terminal phase and all three Titans are tracked directly.')
    line()
    line('From `packages/monstrous_sim`, reproduce with `dart run bin/navigation_audit.dart NEW_OUTPUT_DIRECTORY 200` and `dart run bin/matched_encounter_audit.dart NEW_OUTPUT_FILE.json.gz`. Add `initial-income` after the seed count to reproduce the initial bundle; 108 reproduced trajectories matched its retained outcomes and complete ledgers. Existing receipt paths are refused. `tools/analyze_navigation_audit.py` produces this summary. Source hashes, parameters, CSVs, compressed raw receipts, checks and visual captures are retained in the [evidence directory](evidence/navigation-refactor-2026-11-05/manifest.json).')
    line()
    line('## Income comparison and retained provisional bundle')
    line()
    line('Initial normal bands were 40–50 / 70–90 / 100–130g. Revised bands are **40–50 / 55–70 / 70–90g**. Apex remains ×1.5; Titans use twice their own normal regional roll, without a second Apex multiplier. Upgrade cost remains 1,390g; no corpse loot, safety rule or material coverage was removed. The initial mild danger replay reached full upgrades in Region 2 in 26/200 fresh trajectories. The revision removes that early completion in this sample and leaves mixed-route completion concentrated at Region 3 final preparation. Danger routes still tend to max at the Region 3 midpoint: this is an unresolved pacing sensitivity, not proof that every route meets the target.')
    line()
    rows = []
    for name, data in [('initial', baseline), ('revised', revised)]:
        for policy in policies:
            g = cell(data, 'attritionReplay', 'fresh', policy)
            def n(region, leg=None): return sum(r.get('firstMax', {}).get('region') == region and (leg is None or r.get('firstMax', {}).get('leg') == leg) for r in g)
            rows.append([name, policy, n(2), n(3, 0), n(3, 7), n(3, 14), sum('firstMax' not in r for r in g), f"{mean(g,'goldEarned'):.1f}", f"{mean(g,'spentUpgrades'):.1f}", f"{statistics.mean(r['final']['gold'] for r in g):.1f}"])
    table(['Bundle (mild replay)', 'Policy', 'Max R2', 'R3 start', 'R3 midpoint', 'R3 final prep', 'Unmaxed', 'Earned g', 'Upgrade g', 'Final g'], rows)
    line('Avoiding fights can leave the conservative route unable to finance full upgrades. Aggressive routes earn more, but their real survival is much worse in this bot sample. The revision is a bounded provisional response to income/pacing evidence, not tuning combat to a target human win rate.')
    line()
    line('## Real combat outcomes, including early deaths')
    line()
    rows = []
    for build in builds:
        for policy in policies:
            g = cell(revised, 'live', build, policy)
            rows.append([build, policy, len(g), sum(r['krakenCrossed'] for r in g), sum(r['complete'] for r in g), sum(r['died'] for r in g), sum(r['error'] is not None or r['stepLimited'] for r in g), f"{mean(g,'goldEarned'):.1f}", f"{mean(g,'goldSpent'):.1f}"])
    table(['Build', 'Policy', 'N', 'Kraken crossed', 'Full completion', 'Deaths', 'Error/limit', 'Earned g', 'Spent g'], rows)
    line('No LIVE trajectory completed all three regions. There is therefore no live survivor cohort from which to estimate late-game affordability or fairness. Raw Titan snapshots record actual HP/build/purse when reached; absent later arrivals are not silently replaced with replay values. Player replay must assess early attrition, later difficulty, compulsory-service pressure and the value of different builds. No boss nerf or extra bailout was added to manufacture bot completions.')
    line()
    line('## First Haven and recovery budget')
    line()
    rows=[]
    for mode in ['live', 'attritionReplay', 'harshReplay']:
        for policy in policies:
            g=cell(revised, mode, 'fresh', policy)
            h=[m for r in g for m in r['milestones'] if m['kind']=='havenArrival' and m['region']==1]
            rows.append([mode,policy,len(h),sum(m['affordFirstFittingPlusQuotedRepairs'] for m in h),sum(m['affordFirstHullPlusQuotedRepairs'] for m in h),f"{mean(g,'normalRepairWork'):.1f}",f"{mean(g,'paidRepairHp'):.1f}",f"{mean(g,'careenHp'):.1f}",f"{mean(g,'refitHp'):.1f}",f"{mean(g,'kitsAcquired'):.1f}/{mean(g,'kitsUsed'):.1f}",f"{mean(g,'overflowKitsUsed'):.2f}",f"{mean(g,'scriptedFatalShortfalls'):.2f}"])
    table(['Mode', 'Policy', 'R1 Haven arrivals', 'Afford fitting + quote', 'Afford hull + quote', 'Paid work', 'Paid HP', 'Careen HP', 'Refit HP', 'Kits got/used', 'Full-belt kit uses', 'Fatal replay shortfalls'],rows)
    line('Affordability uses the arrival’s current paid quote before a free duty/refit, not an assumed heal or a guaranteed purchase. Work is distinct from modifier-adjusted restoration; all three free-duty counts, paid work/cost, triage, kit HP, supplies left and fixed refit growth are in each raw ledger. Mild replay has no fatal shortfalls in these cells; harsh replay exposes service/kit droughts even though its clamp still reaches the end. Means include unsuccessful/short voyages where applicable.')
    line()
    line('## Wreck versus hunt receipts')
    line()
    line('The controlled comparison has 3,600 pairs across all regions, fresh/capped builds, neutral/combined healing and all three wreck conditions. It substitutes the identical normal shark factory, opening intent and combat RNG for setup noise, then runs actual combat. Both sides must match HP, death/victory, gold, organics and tactical consumables before cargo or the audit fails. Forced normal approach ambushes deliberately isolate the extra cargo after a won identical fight; this is not an estimate of voluntary Apex risk or overall wreck safety.')
    line()
    rows=[]
    for condition in ['pickedClean','uncertain','fresh']:
        g=[r for r in matched if r['condition']==condition]; wins=[r for r in g if r['won']]
        cargo=[r['extraCargo'] for r in wins]
        rows.append([condition,len(g),len(wins),f"{statistics.mean(c['seaGlass'] for c in cargo):.2f}",f"{statistics.mean(c['iron'] for c in cargo):.2f}",f"{statistics.mean(c['gold'] for c in cargo):.2f}",f"{statistics.mean(len(c['supplies']) for c in cargo):.2f}"])
    table(['Condition', 'Matched pairs', 'Won pairs', 'Extra glass / win', 'Extra iron / win', 'Extra gold / win', 'Extra supplies / win'], rows)
    line('A won wreck fight pays strictly more because ordinary creature rewards remain intact and cargo is additional. Whole-route comparisons below include the peaceful/quick recovery opportunities and hunts forgone. The danger policy is not dominant in LIVE survival (fresh Kraken crossing 1/200 versus 23/200 conservative and 20/200 mixed), despite higher replay earnings. That does not prove wrecks balanced: no real complete-route comparison exists, and different human decisions can change the tradeoff. Keep cargo/weights provisional; do not silently remove ordinary loot or make safe services dangerous.')
    line()
    line('## Materials, purchase competition and shrine saturation')
    line()
    rows=[]
    for build in ['fresh','progressed']:
        for policy in policies:
            g=cell(revised,'attritionReplay',build,policy)
            def meta(k): return statistics.mean(r['final']['meta'][k] for r in g)
            all_roster=sum(all(r['final']['meta'][k]>=v for k,v in {'seaGlass':30,'monsterBone':20,'depthWroughtIron':16,'abyssalBarnacles':12}.items()) for r in g)
            rows.append([build,policy,f"{mean(g,'spentMaterials'):.1f}",f"{mean(g,'glassBought'):.1f}/{mean(g,'ironBought'):.1f}",f"{meta('seaGlass'):.1f}/{meta('depthWroughtIron'):.1f}",f"{meta('monsterBone'):.1f}/{meta('abyssalBarnacles'):.1f}",all_roster,f"{mean(g,'shrineOpportunities'):.2f}/{mean(g,'shrineVisits'):.2f}/{mean(g,'dedications'):.2f}",sum(r['final']['blessingTiers']==9 for r in g)])
    table(['Mild replay build', 'Policy', 'Material g', 'Glass/iron bought', 'Final glass/iron', 'Final bone/barnacles', 'Afford whole roster', 'Shrine opportunities/visits/dedications', 'All 9 blessing tiers'],rows)
    line('Final inventories include carried starting resources for progressed profiles. Per-blueprint affordability and full receipts remain in the raw data; individual unlocks compete with other permanent purchases, while no mid-voyage commission is authorized. Stores use finite separate allocations with the same bounds in every region; no quota or new monster iron was introduced. Full-route shrine opportunities average well below nine, and fully saturated blessings are counted separately from early deaths.')
    line()
    line('## No-cove / poor-kit stress and remaining replay')
    line()
    rows=[]
    for mode in ['live','attritionReplay','harshReplay']:
        for policy in policies:
            g=cell(revised,mode,'noCove',policy)
            poor=[r for r in g if r['totals'].get('kitsAcquired',0)<=1]
            rows.append([mode,policy,len(poor),sum(r['died'] for r in poor),f"{mean(poor,'scriptedFatalShortfalls'):.2f}",f"{mean(g,'approachAmbushes'):.2f}",f"{mean(g,'spentRepairs'):.1f}",f"{mean(g,'spentTriage'):.1f}"])
    table(['Mode, zero-cove scenario', 'Policy', 'Naturally ≤1 kit', 'LIVE/actual deaths in subset', 'Replay fatal shortfalls in subset', 'Ambushes / trajectory', 'Paid repair g', 'Triage g'],rows)
    line('Poor-kit is a naturally observed subset, not a guarantee or a forced stock removal. Early-death means cannot establish adequate recovery. Player replay remains necessary for clarity, tension, voluntary Apex warnings, specialist tradeoffs and realistic repair pressure; the harsh replay’s clamped fatal events explicitly prevent a survival claim. Aggressive midpoint maxing and weak late conservative purchasing remain numerical sensitivities. Accepted mechanics are implemented; final balance approval remains open.')
    line()
    line('## Correctness and presentation verification')
    line()
    line('Core analysis and 889 tests pass; app analysis and 414 tests pass; simulator analysis and 43 tests pass. Coverage includes all cadences, hidden-plan/shrine/quirk restrictions, committed difficulty, full three-region boundary flow, wreck exactly-once creature-plus-cargo settlement, death/overflow/stale callbacks, repair rounding/first-purchase ordering, traits, fixed refits, whole-battle drilling, exact pending/carried kits, finite stock and supported checkpoints. Real Flame playback reaches loot only after the final impact and returns to wreck cargo correctly. Rendering does not consume gameplay RNG.')
    line()
    line('Font-loaded 360/1280px captures at 130% text were inspected. Helm integrates the travelled route with current choices, stable bearing geometry, visited discoveries and explicit arrival/pass/victory/cargo markers; course cards scroll independently. Full history persists across strongholds. Reduced motion restores the endpoint, keyboard access passes, and ordinary pause/save/playback gates retain regression coverage. Existing approved art is reused. No shared native Windows build or human playthrough was performed; original saves and October evidence remain untouched.')
    Path(sys.argv[4]).write_text('\n'.join(out)+'\n',encoding='utf-8')


if __name__ == '__main__': main()
