#!/usr/bin/env python3
"""Check the canonical Tractatus v1.1.0 and active research-companion references.

Standard-library-only structural test. It checks files and provenance, NOT
philosophical truth, proof soundness, empirical validity, or PDF rendering.
"""
from __future__ import annotations

from hashlib import sha256
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
LABEL = re.compile(r"^\*\*(\d+(?:\.\d+)?)(?:\.)?\*\* ", re.MULTILINE)
INDEX_ROW = re.compile(r"^\| (\d+(?:\.\d+)?) \|", re.MULTILINE)
REMOVED = {"2.52", "4.31", "4.42", "5.51", "6.11", "6.52"}
ADDED = {"2.72", "4.54", "6.93"}
EXPECTED_HEADS = ["1", "2", "3", "4", "5", "6", "7"]
VERIFIED_LEAN_SHA256 = {
    "MutualAcquaintance.lean": "98439818fa421e9d9c55fcecb06dc02da48e761ecc50c1d0393ddcd46c23f2ac",
    "MutualAcquaintanceDynamics.lean": "64e6f8ce53bad966f950ce5c47fa7f4259e16f6fb1d2ca04521d7ec837f0a4ca",
    "MutualAcquaintanceIdentification.lean": "28d8f35e4060739d6e0c3ef22e4c5e3b7c76791d2c25a6ee178c3e20a3865baa",
}
ARCHIVES = {
    "v2.0.0-draft.1": 74,
    "v2.0.0-draft.2": 78,
    "v2.0.0-draft.1-alt66": 66,
}


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def require(ok: bool, message: str) -> None:
    if not ok:
        raise AssertionError(message)


def labels(text: str) -> list[str]:
    return LABEL.findall(text)


def main() -> None:
    edition_by_lang = {}
    for lang in ("ID", "EN", "LA"):
        filename = f"Tractatus_de_Perceptione_et_Amore_{lang}.md"
        active = read(f"tractatus/{filename}")
        frozen = read(f"editions/v1.1.0/{filename}")
        require(active == frozen, f"{lang}: active and frozen v1.1.0 differ")
        current = labels(active)
        require(len(current) == 116, f"{lang}: expected 116 propositions; got {len(current)}")
        require(len(set(current)) == 116, f"{lang}: duplicate proposition ID")
        require([s for s in current if "." not in s] == EXPECTED_HEADS,
                f"{lang}: seven chapter identifiers are not 1..7 in order")
        require(set(current).isdisjoint(REMOVED), f"{lang}: retired ID is active")
        require(ADDED <= set(current), f"{lang}: some v1.1.0 additions are missing")
        require("H(A,B,t) ⇒ W_A(B,t) ∧ W_B(A,t)" in active,
                f"{lang}: §5.31 formula changed")
        edition_by_lang[lang] = current

    require(edition_by_lang["ID"] == edition_by_lang["EN"] ==
            edition_by_lang["LA"], "ID, EN and LA use different proposition IDs")

    index = INDEX_ROW.findall(read("paper/PROPOSITION_INDEX.md"))
    require(index == edition_by_lang["ID"],
            "Active proposition index IDs or sequence differ from canonical v1.1.0")

    paper = read("paper/A_Dynamic_Epistemic_Model_of_Mutual_Acquaintance_WORKING_DRAFT.md")
    for marker in ("v1.1.0", "2.72", "4.54", "6.8", "6.93"):
        require(marker in paper, f"Paper missing alignment marker {marker}")
    require("Latest Indonesian literary edition, 18 November 2026" not in paper,
            "Paper still presents the 18 November literary edition as latest")
    require("119 philosophical propositions" not in read("paper/README.md"),
            "Paper reader guide still calls 119 propositions active")

    registry = read("editions/README.md")
    require("Current canonical philosophical edition: v1.1.0" in registry,
            "Edition registry no longer designates v1.1.0 current")
    for label, count in ARCHIVES.items():
        archived = read(
            f"editions/archive/{label}/Tractatus_de_Perceptione_et_Amore_ID.md"
        )
        require(len(labels(archived)) == count,
                f"Archive {label} has unexpected proposition count")
        require(label in registry, f"Version registry omits archive {label}")

    for name, historical_sha in VERIFIED_LEAN_SHA256.items():
        actual_sha = sha256((ROOT / "lean" / name).read_bytes()).hexdigest()
        if actual_sha == historical_sha:
            print(f"LEAN_SOURCE_MATCHES_2026_11_18_SUCCESS {name} {actual_sha}")
        else:
            print(
                f"LEAN_SOURCE_CHANGED_NEW_CI_REQUIRED {name} {actual_sha}",
                file=sys.stderr
            )

    print("TRACTATUS_V1_1_0_COMPANION_ALIGNMENT_OK: 116 ID/EN/LA/INDEX, "
          "3 archived drafts, versioned paper references")
    print("SCOPE: structural/textual consistency only; PDF equivalence, "
          "empirical validity and Lean kernel execution are separate checks.")


if __name__ == "__main__":
    main()
