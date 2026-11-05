"""Exact source-derived iron opportunity model; no combat/saves/core mutations.

Assumes survival through each endpoint; starting iron 0; no spending, Nemesis,
pacts or captain traits; always Search Hold. Uniform means choose headings
without reference to type; wreck-first takes any available wreck. These are
opportunity models, not human/bot outcome estimates. R1 leg1 forced combat;
R2/R3 leg1 deadAhead forced combat while the two side offers are random.
"""
import json
from pathlib import Path

def distribution(probabilities, quantity=1):
    values = [1.0]
    for probability in probabilities:
        following = [0.0] * (len(values) + quantity)
        for k, value in enumerate(values):
            following[k] += value * (1-probability)
            following[k+quantity] += value * probability
        values = following
    return values

def evaluate(ordinary, entry, policy, chance=.25, quantity=1, cost=8):
    q, qe = ((.15, .10) if policy == 'uniform' else
             (1-.85**3, 1-.85**2))
    values = distribution([q*chance]*ordinary+[qe*chance]*entry, quantity)
    return dict(policy=policy, procedural_slots=ordinary+entry,
        expected_wrecks=ordinary*q+entry*qe,
        expected_iron=(ordinary*q+entry*qe)*chance*quantity,
        probability_zero=values[0], probability_afford_iron=sum(values[cost:]))

endpoints = [('R1_leg4_or_midpoint',3,0), ('Kraken',7,0),
             ('World_Serpent',16,1), ('full_campaign',27,2)]
baseline = {label:[evaluate(n,s,p) for p in ['uniform','wreck_first']]
            for label,n,s in endpoints}
candidates = {}
for label,chance,quantity,cost in [('chance50',.5,1,8),
    ('quantity2',.25,2,8),('cost4',.25,1,4)]:
    candidates[label] = {endpoint:evaluate(n,s,'wreck_first',chance,quantity,cost)
                        for endpoint,n,s in endpoints}
result = dict(assumptions=__doc__, baseline=baseline,
              unapproved_candidate_sensitivity=candidates,
              expected_searched_wrecks_for_8_at_baseline=32)
output=Path(__file__).with_name('access_model.json')
output.write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps(result,indent=2))
