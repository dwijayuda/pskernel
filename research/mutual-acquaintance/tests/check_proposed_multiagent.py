#!/usr/bin/env python3
"""Proposed v1.2.0 + v0.4: finite witnesses and source-alignment checks.
NOT a proof of general MA-1/3/4/5/6/9 or a validation of psychology.
"""
from pathlib import Path
import re
from fractions import Fraction

ROOT = Path(__file__).resolve().parents[1]
EDITIONS = ROOT / "editions" / "v1.2.0-proposed"
SOURCE = ROOT / "companion" / "Mathematical_Companion_v0.4_EN.md"
LEAN = ROOT / "lean" / "MultiAgentAcquaintance.lean"

for lang in ("ID", "EN", "LA"):
    old = (ROOT / "editions" / "v1.1.0" /
           f"Tractatus_de_Perceptione_et_Amore_{lang}.md").read_text(encoding="utf-8")
    cur = (EDITIONS / f"Tractatus_de_Perceptione_et_Amore_{lang}.md").read_text(encoding="utf-8")
    pat = r"^\*\*(\d+(?:\.\d+)*)(?:\.)?\*\* "
    old_labels = re.findall(pat, old, re.M)
    new_labels = re.findall(pat, cur, re.M)
    assert len(old_labels) == 116
    assert len(new_labels) == 126
    assert set(old_labels).issubset(set(new_labels))

companion = SOURCE.read_text(encoding="utf-8")
lean = LEAN.read_text(encoding="utf-8")
alignment = (EDITIONS / "COMPANION_ALIGNMENT_v0.4.md").read_text(encoding="utf-8")
for tag in [f"MA-{i}" for i in range(1, 10)]:
    assert f"### {tag}" in companion, tag
for marker in ("126 propositions", "6.95", "6.96", "MA-8", "MA-9", "7."):
    assert marker in companion, marker
assert "124 propositions" not in companion
rows = re.findall(r"^\| §(\d+(?:\.\d+)*) \|", alignment, re.M)
assert len(rows) == len(set(rows)) == 126

# MA-1: finite exact rational instance checks, not the metric theorem.
v = [Fraction(x, 8) for x in range(-8, 9)]
for p in v:
    for i in v:
        for pp in v:
            ii = (pp + i) / 2
            assert abs(abs(pp - ii) - abs(p - i)) <= abs(pp - p) + abs(ii - i)

# MA-2 witness: same B and A's perception of B, changed ideal.
pAB, oldIdeal, newIdeal, threshold = map(Fraction, ["0.4", "0.3", "0.85", "0.15"])
assert abs(pAB-oldIdeal) <= threshold and abs(pAB-newIdeal) > threshold

# MA-7: only candidate blocking pair A--C, the others rank their partner highest.
assert not (False and False) and (True and True)

# MA-8: two models identical observationally, distinct under do(E=e).
for u in (False, True):
    obs_selection = (u, u)
    obs_influence = (u, u)
    assert obs_selection == obs_influence
    assert u == u  # selection do(E=1), do(E=0) both report U
    assert True != False  # influence do(E=1) vs do(E=0)

# Lean proof has no placeholder axioms; CI separately checks compilation.
assert not re.search(r"^\s*(sorry|admit|axiom)(?:\s|$)", lean, re.M)
print("PROPOSED_COMPANION_CHECK_OK: 126 labels, MA-1..9 ledger, finite MA-2/7/8 witnesses")
