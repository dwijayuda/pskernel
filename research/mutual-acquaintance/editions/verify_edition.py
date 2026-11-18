#!/usr/bin/env python3
"""Verify ID continuity and editorial crosswalk for Tractatus editions.

Run from any directory:
  python research/mutual-acquaintance/editions/verify_edition.py

This checks *structural provenance only*. It does not test philosophy, empirical
validity, proof correspondence, or translation quality.
"""
from __future__ import annotations

import csv
from pathlib import Path
import re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
OLD = ROOT / "tractatus" / "Tractatus_de_Perceptione_et_Amore_ID.md"
NEW = HERE / "v2.0.0-draft.1" / "Tractatus_de_Perceptione_et_Amore_ID.md"
MAP = HERE / "v2.0.0-draft.1" / "PROPOSITION_CROSSWALK.csv"
PATTERN = re.compile(r"^\*\*(\d+(?:\.\d+)*)\.?\*\*(?=\s)", re.MULTILINE)


def identifiers(path: Path) -> list[str]:
    content = path.read_text(encoding="utf-8")
    result = PATTERN.findall(content)
    assert len(result) == len(set(result)), f"duplicate proposition in {path}"
    assert [item for item in result if "." not in item] == [
        "1", "2", "3", "4", "5", "6", "7"
    ], f"incorrect principal proposition sequence in {path}"
    assert content.startswith("# Tractatus de Perceptione et Amore"), path
    return result


def verify() -> None:
    old = identifiers(OLD)
    new = identifiers(NEW)
    assert len(old) == 119, f"baseline unexpectedly changed: {len(old)}"
    assert len(new) == 74, f"new edition unexpectedly changed: {len(new)}"
    with MAP.open(encoding="utf-8-sig", newline="") as handle:
        table = list(csv.DictReader(handle))
    assert len(table) == len(old), f"crosswalk row count: {len(table)}"
    assert set(table[0]) == {
        "old_version", "old_proposition", "new_version",
        "new_proposition", "editorial_note"
    }
    old_mapped = [row["old_proposition"] for row in table]
    assert old_mapped == old, "crosswalk must follow the original edition in order"
    assert all(row["new_proposition"] in new for row in table), "invalid v2 destination"
    assert all(row["old_version"] == "v1.0.0-baseline" for row in table)
    assert all(row["new_version"] == "v2.0.0-draft.1" for row in table)
    assert all(row["editorial_note"].strip() for row in table)
    mappings = {row["old_proposition"]: row["new_proposition"] for row in table}
    for before, after in {
        "2.7": "2.3", "3.23": "3.2", "4.53": "4.12",
        "5.31": "5.2", "6.63": "4.2", "6.92": "4.3", "7": "7",
    }.items():
        assert mappings[before] == after, (before, mappings[before])
    assert all((HERE / "v2.0.0-draft.1" / name).is_file() for name in (
        "RESEARCH_PROGRAM.md", "EDITORIAL_AUDIT.md"
    ))
    print(
        f"PASS: baseline={len(old)} new={len(new)} crosswalk={len(table)}; "
        "seven main propositions, one-to-one old-ID coverage, valid new targets."
    )
    print("Scope: structure only; semantic mapping requires human review.")


if __name__ == "__main__":
    verify()
