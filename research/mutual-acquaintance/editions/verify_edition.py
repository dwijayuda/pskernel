#!/usr/bin/env python3
"""Verify provenance and proposition mapping across Tractatus editions.

Run from repository root:
    python research/mutual-acquaintance/editions/verify_edition.py

This verifies edition structure only. It never certifies argument validity,
the fidelity of conceptual mappings, translations, or empirical claims.
"""
from __future__ import annotations

import csv
import hashlib
from pathlib import Path
import re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
BASELINE = ROOT / "tractatus" / "Tractatus_de_Perceptione_et_Amore_ID.md"
EXPECTED_BASELINE_BLOB = "8611cb3403afa77ca59b1ac583ba806c6361ab7e"
EXPECTED_DRAFT_1_BLOB = "96285c8103315775da33bc267fb726b92ff3bb51"

# A Git blob identifier is SHA-1("blob " + byte-length + NUL + contents).
# These pins prevent silent rewriting of the retrospective baseline and
# previously released draft.1 while proposed draft.2 evolves.
def git_blob_id(path: Path) -> str:
    data = path.read_bytes()
    return hashlib.sha1(
        b"blob " + str(len(data)).encode("ascii") + b"\x00" + data
    ).hexdigest()


PATTERN = re.compile(r"^\*\*(\d+(?:\.\d+)*)\.?\*\*\s+(.+)$", re.MULTILINE)


def propositions(path: Path) -> tuple[list[str], dict[str, str]]:
    content = path.read_text(encoding="utf-8")
    matches = PATTERN.findall(content)
    ids = [p for p, _ in matches]
    assert len(ids) == len(set(ids)), f"duplicate identifiers: {path}"
    assert [p for p in ids if "." not in p] == [
        "1", "2", "3", "4", "5", "6", "7"
    ], f"unexpected major sections: {path}"
    assert content.startswith("# Tractatus de Perceptione et Amore")
    return ids, dict(matches)


def check_crosswalk(version: str, old: list[str], new: list[str]) -> None:
    target = HERE / version / "PROPOSITION_CROSSWALK.csv"
    with target.open(newline="", encoding="utf-8-sig") as handle:
        rows = list(csv.DictReader(handle))
    assert len(rows) == len(old) == 119, (version, len(rows))
    assert [r["old_proposition"] for r in rows] == old, version
    assert all(r["new_proposition"] in new for r in rows), version
    assert all(r["old_version"] == "v1.0.0-baseline" for r in rows)
    assert all(r["new_version"] == version for r in rows)
    assert all(r["editorial_note"].strip() for r in rows)
    lookup = {r["old_proposition"]: r["new_proposition"] for r in rows}
    for source, destination in {
        "2.7": "2.3", "3.23": "3.2", "4.53": "4.12",
        "5.31": "5.2", "6.63": "4.2", "6.92": "4.3", "7": "7"
    }.items():
        assert lookup[source] == destination, (version, source)


def verify() -> None:
    assert git_blob_id(BASELINE) == EXPECTED_BASELINE_BLOB, (
        "v1 source changed; preserve the cited historical baseline"
    )
    old, _ = propositions(BASELINE)
    assert len(old) == 119

    draft1 = HERE / "v2.0.0-draft.1" / "Tractatus_de_Perceptione_et_Amore_ID.md"
    draft2 = HERE / "v2.0.0-draft.2" / "Tractatus_de_Perceptione_et_Amore_ID.md"
    assert git_blob_id(draft1) == EXPECTED_DRAFT_1_BLOB, (
        "draft.1 changed; make a new version for substantive edits"
    )

    ids1, text1 = propositions(draft1)
    ids2, text2 = propositions(draft2)
    assert len(ids1) == 74 and len(ids2) == 78
    assert [p for p in ids2 if p in text1] == ids1
    assert set(ids2) - set(ids1) == {"1.13", "4.32", "4.33", "4.42"}
    assert all(text1[p] == text2[p] for p in ids1), (
        "draft.2 must not silently rewrite an existing proposition"
    )

    for version, identifiers in (
        ("v2.0.0-draft.1", ids1),
        ("v2.0.0-draft.2", ids2),
    ):
        check_crosswalk(version, old, identifiers)

    for name in ("RESEARCH_PROGRAM.md", "EDITORIAL_AUDIT.md"):
        assert (HERE / "v2.0.0-draft.1" / name).is_file()
    assert (HERE / "v2.0.0-draft.2" / "EDITORIAL_ADDENDUM.md").is_file()

    print("PASS: baseline=119 (immutable Git blob)")
    print("PASS: v2.0.0-draft.1=74 (immutable Git blob)")
    print("PASS: v2.0.0-draft.2=78 (exactly four added propositions)")
    print("PASS: both crosswalks map all 119 source identifiers")
    print("Scope: structure/provenance only; human philosophical review open")


if __name__ == "__main__":
    verify()
