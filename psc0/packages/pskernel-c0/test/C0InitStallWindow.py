#!/usr/bin/env python3
"""Locate names of declarations near a stalled exact-byte Init NDJSON replay.

Diagnostic only: this does not verify a term, change a kernel verdict, or
interpret any untrusted expression as a proof. Physical records are 1-based.
"""
import argparse
import json
from pathlib import Path

DECLS = frozenset(("thm", "def", "opaque", "axiom", "inductive", "quot"))


def decoded_name(entry, names):
    if "str" in entry:
        part = entry["str"]
        parent = names[part["pre"]]
        suffix = part["str"]
        if not isinstance(suffix, str):
            raise ValueError("non-string name suffix")
    elif "num" in entry:
        part = entry["num"]
        parent = names[part["pre"]]
        suffix = str(part["i"])
    else:
        raise ValueError("unsupported exported name")
    return (parent + "." if parent else "") + suffix


def scan(path, start, end, after):
    if not (1 <= start <= end and 0 <= after <= end):
        raise ValueError("invalid record window")
    names = {0: ""}
    prior = []
    candidates = []
    last = 0
    with Path(path).open("r", encoding="utf8", buffering=4 * 1024 * 1024) as stream:
        for record, raw in enumerate(stream, 1):
            if record > end:
                break
            last = record
            if '"in"' in raw[:24]:
                obj = json.loads(raw)
                if "in" in obj:
                    idx = obj["in"]
                    if idx != len(names):
                        raise ValueError(f"nonsequential name index {idx} at {record}")
                    names[idx] = decoded_name(obj, names)
                    continue
            # Avoid constructing any of the millions of exported expressions.
            if not any(f'"{tag}"' in raw[:24] for tag in DECLS):
                continue
            if record < start - 100000:
                continue
            obj = json.loads(raw)
            tag = next(iter(obj))
            if tag not in DECLS:
                continue
            payload = obj[tag]
            if tag == "inductive":
                label = ",".join(names[t["name"]] for t in payload["types"])
            else:
                label = names[payload["name"]]
            item = {"record": record, "kind": tag, "name": label}
            if record < start:
                prior.append(item)
                prior = prior[-20:]
            elif record > after:
                candidates.append(item)
    if last != end:
        raise ValueError(f"truncated export at record {last}, expected {end}")
    return {
        "start": start, "end": end, "after": after,
        "prior_declarations": prior, "candidate_declarations": candidates,
        "name_handles_scanned": len(names),
        "diagnostic_only": True,
    }


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("export")
    ap.add_argument("--start", type=int, default=5060000)
    ap.add_argument("--end", type=int, default=5070000)
    ap.add_argument("--after", type=int, default=5064933)
    ap.add_argument("--output", type=Path)
    args = ap.parse_args()
    report = json.dumps(scan(args.export, args.start, args.end, args.after),
                        indent=2, ensure_ascii=False)
    print(report)
    if args.output:
        args.output.write_text(report + "\n", encoding="utf8")


if __name__ == "__main__":
    main()
