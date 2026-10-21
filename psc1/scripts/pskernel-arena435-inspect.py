#!/usr/bin/env python3
"""Inspect all authenticated Arena inputs without changing checker outcomes."""
from __future__ import annotations

import argparse
from decimal import Decimal
import hashlib
import importlib.util
import json
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("arena_oracle", HERE / "pskernel-arena435-oracle.py")
ORACLE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ORACLE)


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def exact_json(value):
    # IDs and arbitrary-precision values must not become rounded JS Numbers.
    if isinstance(value, bool) or value is None or isinstance(value, str):
        return value
    if isinstance(value, (int, Decimal)):
        return str(value)
    if isinstance(value, list):
        return [exact_json(item) for item in value]
    if isinstance(value, dict):
        return {key: exact_json(item) for key, item in value.items()}
    raise TypeError(type(value).__name__)


def natural(value):
    if type(value) is not int or value < 0:
        raise ValueError("expected exact natural number")
    return value


def numeric_summary(value: int, identity: str) -> dict:
    digits = str(value)
    return {"id": identity, "bit_length": value.bit_length(),
            "decimal_digits": len(digits), "decimal_sha256": digest(digits.encode()),
            "decimal": digits if len(digits) <= 160 else None,
            "decimal_prefix": digits[:80], "decimal_suffix": digits[-80:]}


def inspect_case(index: int, label: str, name: str, payload: bytes) -> dict:
    names = {0: ()}
    largest_literals, largest_name_numbers, all_records, issues = [], [], [], []
    literal_count = numeric_name_count = parsed_records = 0

    def keep_largest(target, value, identity):
        target.append((value, identity))
        target.sort(key=lambda item: item[0], reverse=True)
        del target[5:]

    def resolve_name(identifier):
        identifier = natural(identifier)
        if identifier not in names:
            raise ValueError(f"unresolved name table ID {identifier}")
        return names[identifier]

    def describe_name(identifier):
        parts = resolve_name(identifier)
        return {"id": str(identifier),
                "segments": [{"kind": kind, "value": str(value)} for kind, value in parts]}

    lines = payload.decode("utf-8").splitlines()
    for line_number, line in enumerate(lines, 1):
        try:
            record = json.loads(line, parse_float=Decimal)
            parsed_records += 1
            if not isinstance(record, dict):
                raise ValueError("record is not an object")
            if "in" in record:
                identifier = natural(record["in"])
                if identifier in names:
                    raise ValueError(f"duplicate name table ID {identifier}")
                if "str" in record:
                    raw = record["str"]
                    if not isinstance(raw["str"], str):
                        raise ValueError("non-string name segment")
                    names[identifier] = resolve_name(raw["pre"]) + (("str", raw["str"]),)
                elif "num" in record:
                    raw = record["num"]
                    value = natural(raw["i"])
                    names[identifier] = resolve_name(raw["pre"]) + (("num", value),)
                    numeric_name_count += 1
                    keep_largest(largest_name_numbers, value, str(identifier))
            if "ie" in record and "natVal" in record:
                digits = record["natVal"]
                if not isinstance(digits, str) or re.fullmatch(r"[0-9]+", digits) is None:
                    raise ValueError("invalid natural literal text")
                literal_count += 1
                keep_largest(largest_literals, int(digits), str(natural(record["ie"])))
            for kind in ("def", "thm", "opaque"):
                if kind not in record:
                    continue
                raw = record[kind]
                own_name = resolve_name(raw["name"])
                if not isinstance(raw["all"], list):
                    raise ValueError("all metadata is not an array")
                all_names = [resolve_name(item) for item in raw["all"]]
                if all_names and all_names != [own_name]:
                    all_records.append({
                        "line": line_number, "kind": kind,
                        "name": describe_name(raw["name"]),
                        "all": [describe_name(item) for item in raw["all"]],
                        "safety": raw.get("safety"), "isUnsafe": raw.get("isUnsafe"),
                        "blocked_by_previous_all_guard": kind != "def" or raw.get("safety") == "safe",
                        "raw_record": line,
                    })
        except (ValueError, KeyError, TypeError, IndexError) as exc:
            issues.append({"line": line_number, "error": f"{type(exc).__name__}: {exc}"})
    return {"index": index, "label": label, "name": name,
            "source_sha256": digest(payload),
            "body_sha256": digest(payload.partition(b"\n")[2]),
            "parsed_records": parsed_records, "nat_literal_count": literal_count,
            "largest_nat_literals": [numeric_summary(value, identity) for value, identity in largest_literals],
            "numeric_name_count": numeric_name_count,
            "largest_numeric_name_segments": [numeric_summary(value, identity) for value, identity in largest_name_numbers],
            "noncanonical_all_records": all_records, "inspection_issues": issues}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", type=pathlib.Path, required=True)
    parser.add_argument("--out", type=pathlib.Path, required=True)
    args = parser.parse_args()
    if hasattr(sys, "set_int_max_str_digits"):
        sys.set_int_max_str_digits(0)
    # Only the size- and digest-authenticated fixed archive is parsed below.
    cases = ORACLE.read_archive(args.archive)
    results = []
    for index, (label, name, payload) in enumerate(cases):
        result = inspect_case(index, label, name, payload)
        results.append(result)
        summary = {key: result[key] for key in
                   ("index", "label", "name", "nat_literal_count", "largest_nat_literals", "numeric_name_count")}
        summary["noncanonical_all_count"] = len(result["noncanonical_all_records"])
        summary["inspection_issue_count"] = len(result["inspection_issues"])
        print("PSC1_ARENA435_INPUT " + json.dumps(summary, ensure_ascii=False), flush=True)
        for record in result["noncanonical_all_records"]:
            print("PSC1_ARENA435_ALL_METADATA " + json.dumps(
                {"index": index, "label": label, "case": name, **record}, ensure_ascii=False), flush=True)
    report = {"archive_sha256": ORACLE.ARCHIVE_SHA256,
              "scope": "input diagnostics only; no checker verdicts or qualification",
              "total": len(results), "excluded_cases": [], "tests": results}
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(exact_json(report), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"PSC1_ARENA435_INPUT_SUMMARY total={len(results)} "
          f"noncanonical_all_records={sum(len(item['noncanonical_all_records']) for item in results)} "
          f"inspection_issues={sum(len(item['inspection_issues']) for item in results)} "
          "checker_executed=false", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
