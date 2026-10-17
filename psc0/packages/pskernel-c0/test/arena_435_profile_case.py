#!/usr/bin/env python3
"""Materialize one SHA-locked Arena performance case for 4.35 hot-stack research.

Only the FIRST NDJSON metadata line is adapted. This is historical-body
compatibility, not an authentic source-generated Lean 4.35 export. It NEVER
asserts C0 acceptance or mutates the production kernel.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

from arena_conformance import check_archive
from arena_lean435_compat import adapt_legacy_envelope

TARGET_CASES = {
    "app-lam": "perf/app-lam.ndjson",
    "let-ladder": "perf/let-ladder.ndjson",
    "shared-subterm": "perf/shared-subterm.ndjson",
}


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--archive", type=Path, required=True)
    ap.add_argument("--case", choices=TARGET_CASES, required=True)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--marker-out", type=Path, required=True)
    ap.add_argument("--receipt", type=Path, required=True)
    a = ap.parse_args()
    matched = [(label, name, raw)
               for label, name, raw in check_archive(a.archive)
               if name == TARGET_CASES[a.case]]
    if len(matched) != 1 or matched[0][0] != "good":
        raise ValueError("expected exactly one original Arena valid performance case")
    label, name, original = matched[0]
    adapted, proof = adapt_legacy_envelope(original)
    records = [json.loads(line) for line in adapted.splitlines()]
    checked_records = [i for i, record in enumerate(records, 1)
                       if any(key in record for key in ("thm", "def", "opaque"))]
    if not checked_records:
        raise ValueError("selected performance case lacks a source definition or theorem")
    marker = "C0_REAL_EXPORT_DECL_BEGIN record=" + str(checked_records[-1])
    a.out.parent.mkdir(parents=True, exist_ok=True)
    a.out.write_bytes(adapted)
    a.marker_out.write_text(marker + "\n")
    receipt = {
        "case": name,
        "target_lean": "4.35.0",
        "historical_source_reexport": False,
        "source_type": "Arena archived 3.1.0 body, target-version header only",
        "expected_old_arena_label": label,
        "source_provenance": proof,
        "records": len(records),
        "checked_declaration_records": checked_records,
        "sampled_final_declaration_marker": marker,
        "kernel_acceptance_qualified": False,
    }
    a.receipt.write_text(json.dumps(receipt, indent=2) + "\n")
    print(f"C0_ARENA_PERF_INPUT case={name} records={len(records)} "
          f"last_checked_decl={checked_records[-1]} body_exact={proof['body_bytes_identical']}")
    print(f"C0_ARENA_PERF_MARKER {marker}")


if __name__ == "__main__":
    main()
