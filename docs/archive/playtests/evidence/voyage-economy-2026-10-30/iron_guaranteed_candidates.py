"""Unapproved sensitivity only: guaranteed one iron per Search Hold.

Cost remains eight iron. Starting inventory zero; no spending; no traits,
Nemesis or pacts. Survival assumed through each stated endpoint. Uniform
heading choices or wreck-first choices; all visited wrecks use Search Hold.
Barnacles are not modeled, so iron affordability is not blueprint access.
Three Kraken voyages are independent, all start in region one, and the
profile retains iron between them. Titan rewards are added only after kills.
"""
import json
from pathlib import Path

def distribution(probabilities):
    values = [1.0]
    for probability in probabilities:
        following = [0.0] * (len(values) + 1)
        for k, value in enumerate(values):
            following[k] += value * (1-probability)
            following[k+1] += value * probability
        values = following
    return values

endpoints = [('R1_leg4',3,0,0),('Kraken',7,0,1),
             ('World_Serpent',16,1,2),('full_campaign',27,2,3),
             ('three_independent_Kraken_voyages',21,0,3)]
rows = []
for label, ordinary, entry, titans in endpoints:
    for policy in ['uniform','wreck_first']:
        q, qe = ((.15,.10) if policy == 'uniform' else
                 (1-.85**3,1-.85**2))
        probabilities = distribution([q]*ordinary+[qe]*entry)
        for candidate, titan_quantity in [('A',0),('B',1),('C',2)]:
            guaranteed = titans*titan_quantity
            rows.append(dict(endpoint=label, policy=policy, candidate=candidate,
                guaranteed_titan_iron=guaranteed,
                mean_iron=ordinary*q+entry*qe+guaranteed,
                probability_at_least_8=sum(probabilities[max(0,8-guaranteed):])))
result = dict(assumptions=__doc__, candidates={
    'A':'Guaranteed 1/Search Hold; zero/Titan',
    'B':'Guaranteed 1/Search Hold plus 1/Titan',
    'C':'Guaranteed 1/Search Hold plus 2/Titan'}, rows=rows)
Path(__file__).with_name('guaranteed_candidates.json').write_text(
    json.dumps(result,indent=2),encoding='utf-8')
print('Endpoint | Policy | A mean / P8+ | B mean / P8+ | C mean / P8+')
for label,*_ in endpoints:
    for policy in ['uniform','wreck_first']:
        cells = [f"{row['mean_iron']:.3f} / {row['probability_at_least_8']*100:.2f}%"
                 for row in rows if row['endpoint']==label and row['policy']==policy]
        print(' | '.join([label,policy]+cells))
