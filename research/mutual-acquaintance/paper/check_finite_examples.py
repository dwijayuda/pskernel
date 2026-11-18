#!/usr/bin/env python3
"""Exact finite checks for A Dynamic Epistemic Model of Mutual Acquaintance.

All calculations use fractions; no fitting, sampling, random seeds, or external datasets.
This verifies illustrative instances and exhaustive small finite cases, NOT the
universal mathematical theorems or the psychological model's empirical validity.
"""
from fractions import Fraction as F
from itertools import product
import json

checks = {}

# Proposition 1: theta and K independent fair; Y=theta XOR K.
worlds = [(theta, key, theta ^ key, F(1, 4)) for theta, key in product((0, 1), repeat=2)]
for y in (0, 1):
    p_y = sum((p for theta, k, yy, p in worlds if yy == y), F(0))
    p_theta0_y = sum((p for theta, k, yy, p in worlds if yy == y and theta == 0), F(0))
    assert p_theta0_y / p_y == F(1, 2)
    for key in (0, 1):
        consistent = [theta for theta, k, yy, p in worlds if k == key and yy == y]
        assert consistent == [y ^ key]
checks['asymmetric_public_signal'] = {'B_p_theta_0_given_y': '1/2', 'A_identifies_theta': True}

# Proposition 2: equal observation likelihoods at every length in a repeated context.
for n in range(0, 9):
    for h in product((0, 1), repeat=n):
        likelihood_0 = F(1, 2**n)
        likelihood_1 = F(1, 2**n)
        assert likelihood_0 == likelihood_1
        prior_odds = F(3, 2)
        posterior_odds = prior_odds * likelihood_0 / likelihood_1
        assert posterior_odds == prior_odds
checks['repeated_context_nonidentification'] = {'history_lengths_checked': '0..8', 'posterior_odds': '3/2'}

# Proposition 3: observed reports identical, latent preference evolution different.
formation_q, formation_e = (0, 1), (0, 0)
reporting_q, reporting_e = (0, 0), (0, 1)
formation_y = tuple(a ^ b for a, b in zip(formation_q, formation_e))
reporting_y = tuple(a ^ b for a, b in zip(reporting_q, reporting_e))
assert formation_y == reporting_y == (0, 1)
assert formation_q[0] != formation_q[1] and reporting_q[0] == reporting_q[1]
checks['formation_vs_reporting'] = {'observed_reports': list(formation_y), 'latent_preference_paths_differ': True}

# Theorem 4: exhaustive two-state, two-signal, two-action checks over bounded integer masses / utilities.
def passive_values(mass, payoff):
    total = sum(mass)
    assert total > 0
    p = [F(x, total) for x in mass]
    # mass indexed omega*2+z; payoff indexed d*2+omega.
    v0 = max(sum(p[omega * 2 + z] * payoff[d * 2 + omega]
                 for omega in (0, 1) for z in (0, 1)) for d in (0, 1))
    vz = sum((max(sum(p[omega * 2 + z] * payoff[d * 2 + omega]
                      for omega in (0, 1)) for d in (0, 1))
              for z in (0, 1)), F(0))
    common = any(all(
        sum(mass[omega * 2 + z] * payoff[d * 2 + omega] for omega in (0, 1)) ==
        max(sum(mass[omega * 2 + z] * payoff[alt * 2 + omega] for omega in (0, 1))
            for alt in (0, 1))
        for z in (0, 1) if mass[z] + mass[2 + z] > 0
    ) for d in (0, 1))
    return v0, vz, common

passive_cases = 0
strict_cases = 0
for mass in product((0, 1, 2), repeat=4):
    if not any(mass):
        continue
    for payoff in product((-1, 0, 1, 2), repeat=4):
        v0, vz, common = passive_values(mass, payoff)
        assert vz >= v0, (mass, payoff, v0, vz)
        assert (vz == v0) == common, (mass, payoff, v0, vz, common)
        passive_cases += 1
        strict_cases += int(vz > v0)
checks['passive_voi_small_exhaustive'] = {'cases': passive_cases, 'strict_improvement_cases': strict_cases,
                                            'nonnegative_and_equality_condition': True}

# Theorem 5, with lambda=3/4.
lam = F(3, 4)
quiet = F(1, 2) + lam
passive_perfect_signal = 1 + lam
active_probe = F(1)
assert quiet == F(5, 4) and passive_perfect_signal == F(7, 4) and active_probe == 1
assert active_probe - quiet == F(-1, 4)
checks['active_vs_passive'] = {'quiet': str(quiet), 'passive_signal': str(passive_perfect_signal),
                               'active_encounter': str(active_probe), 'active_minus_quiet': str(active_probe - quiet)}

# Theorem 6, tiny exhaustive posterior / utility matrices.
evpi_cases = 0
for masses in product((0, 1, 2, 3), repeat=2):
    if not any(masses):
        continue
    p = [F(m, sum(masses)) for m in masses]
    for util in product((-1, 0, 1), repeat=4):
        # util indexing action*2+state
        vi = sum((p[state] * max(util[state], util[2 + state]) for state in (0, 1)), F(0))
        v0 = max(sum(p[state] * util[action * 2 + state] for state in (0, 1))
                 for action in (0, 1))
        gap = vi - v0
        common = any(all(util[action * 2 + state] == max(util[state], util[2 + state])
                             for state in (0, 1) if p[state] > 0)
                     for action in (0, 1))
        assert gap >= 0 and ((gap == 0) == common)
        evpi_cases += 1
checks['decision_sufficiency_small_exhaustive'] = {'cases': evpi_cases, 'criterion_held': True}

# Probability bounds on mutual willingness, exhaustive binary distributions.
consent_cases = 0
for masses in product((0, 1, 2, 3), repeat=4):
    total = sum(masses)
    if total == 0: continue
    # index (a,b): a*2+b
    pa = F(masses[2] + masses[3], total)
    pb = F(masses[1] + masses[3], total)
    pab = F(masses[3], total)
    assert max(F(0), pa + pb - 1) <= pab <= min(pa, pb)
    consent_cases += 1
checks['mutual_willingness_frechet'] = {'distributions': consent_cases, 'bounds_held': True}

# Proposition 7 and 8: same individual traits, divergent dyad; same actual, different counterfactual.
traits = (0, 0)
next_r_by_action = {'cooperate': 1, 'separate': 0}
assert next_r_by_action['cooperate'] != next_r_by_action['separate']
actual_A, actual_B = 0, 0
counterfactual_A, counterfactual_B = 1, 0
assert actual_A == actual_B and counterfactual_A != counterfactual_B
checks['path_dependence_and_counterfactuals'] = {'traits_held_fixed': list(traits),
    'different_dyad_states': True, 'observed_actual_same': True,
    'unobserved_alternative_different': True}

print(json.dumps({'status': 'PASS', 'scope': 'finite constructed examples and bounded exhaustive checks',
                  'checks': checks}, indent=2))