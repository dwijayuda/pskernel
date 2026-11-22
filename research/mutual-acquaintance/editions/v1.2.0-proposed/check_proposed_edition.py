#!/usr/bin/env python3
"""Validate proposed v1.2.0 against frozen v1.1.0; no external packages."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent
FROZEN = ROOT.parent / "v1.1.0"
RE = re.compile(r"^\*\*(\d+(?:\.\d+)*)(?:\.)?\*\* (.+)$", re.M)
ADDED = {"1.6", "1.61", "3.7", "3.71", "6.23", "6.65", "6.66", "6.94", "6.95", "6.96"}
LABELS = None
for language in ("ID", "EN", "LA"):
    name = f"Tractatus_de_Perceptione_et_Amore_{language}.md"
    before = FROZEN.joinpath(name).read_text(encoding="utf-8")
    after = ROOT.joinpath(name).read_text(encoding="utf-8")
    orig, curr = dict(RE.findall(before)), dict(RE.findall(after))
    before_ids = [k for k, _ in RE.findall(before)]
    after_ids = [k for k, _ in RE.findall(after)]
    assert len(before_ids) == len(orig) == 116, (language, "old count")
    assert len(after_ids) == len(curr) == 126, (language, "new count")
    assert set(curr) - set(orig) == ADDED
    assert all(curr[k] == val for k, val in orig.items() if k != "7"), (language, "modified old text")
    assert [k for k in after_ids if k not in ADDED] == before_ids, (language, "old ID order")
    assert after_ids.index("6.94") < after_ids.index("6.95") < after_ids.index("6.96") < after_ids.index("7")
    assert "H(A,B,t) ⇒ W_A(B,t) ∧ W_B(A,t)" in after
    if LABELS is None: LABELS = after_ids
    else: assert LABELS == after_ids, ("translation mismatch", language)
    if language == "ID":
        assert "## 6. Tentang perubahan dan kemungkinan yang belum dialami" in after
        assert "## 7. Tentang batas pengetahuan" in after
        assert curr["6.95"] == "Apa yang dikatakan seseorang tentang dirinya atau orang lain adalah bagian dari apa yang dapat kita ketahui, tetapi bukan keseluruhannya."
        assert curr["6.96"] == "Ada hal yang dapat diketahui melalui penjelasan, ada yang baru tampak melalui tindakan dan pengalaman bersama. Namun apa yang tampak pun tidak selalu menentukan seluruh maksud atau sebabnya."
        assert curr["7"] == "Tentang apa yang belum dapat kita ketahui, kita tidak boleh berbicara seolah telah mengetahuinya."
print("PASS: 126 ID/EN/LA; old 115 intact, revised §7, 10 additions; approved Indonesian text")
