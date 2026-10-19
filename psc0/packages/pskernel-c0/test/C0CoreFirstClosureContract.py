#!/usr/bin/env python3
"""Fail-closed, provenance-pinned audit of PSC0's *actual native compiler* closure.

This does not load the report into PSKernel-C0, admit any theorem, or prove a
self-host cycle. It prevents the 76-item seed from being called a complete
compiler environment and checks the fully generated external dependency graph.

Run only against an exact checked-out PSC0 Core-first SHA; Python stdlib only.
"""
import argparse
import hashlib
import json
import pathlib
import subprocess
import sys

PSC0_SHA = "53c28cfe3abd9e8fae93e7935357dbc4402c4b09"
LEAN_SHA = "eb6cafb7290e8bd5f2937522d8d804f58f02bafc"
APPROVED = {"propext", "Quot.sound", "Classical.choice"}
EXPECTED = {"sourceModules": 321, "sourceDeclarations": 191611,
            "externalRootCount": 458, "closureDeclarationCount": 5690}
BOOTSTRAP_SHA = "05fd8f7917054c52b66d8d448bdeeb8e9071fcd6d21d0a6ded088a758628da54"


def require(ok, message):
    if not ok:
        raise ValueError(message)


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def named(value):
    require(isinstance(value, dict) and isinstance(value.get("parts"), list),
            "missing canonical Lean.Name parts")
    require(isinstance(value.get("display"), str) and value["display"],
            "missing display name")
    parts = value["parts"]
    for item in parts:
        require(isinstance(item, dict) and len(item) == 1, "malformed Lean.Name segment")
        if "str" in item:
            require(isinstance(item["str"], str), "non-string name segment")
        elif "num" in item:
            require(isinstance(item["num"], int) and item["num"] >= 0,
                    "invalid numeric name segment")
        else:
            raise ValueError("unknown Lean.Name segment")
    return tuple((next(iter(seg)), next(iter(seg.values()))) for seg in parts)


def verify_source(root):
    actual = subprocess.check_output(
        ["git", "-C", str(root), "rev-parse", "HEAD"], text=True).strip()
    require(actual == PSC0_SHA, f"unqualified PSC0 head: {actual}")
    base = root / "psc0"
    manifest = read_json(base / "docs/PSC0_CORE_STANDARD_MANIFEST.json")
    authority = manifest["authority"]
    require(authority["leanCommit"] == LEAN_SHA and authority["leanVersion"] == "4.35.0",
            "Lean pin mismatch")
    require(set(authority["maximumApprovedLogicalAssumptions"]) == APPROVED,
            "approved logical assumption policy changed")
    require(authority["profileNestingIsAnUnfinishedGoal"] is True,
            "profile nesting cannot be declared complete")
    require("not a loadable" in manifest["purpose"],
            "design ledger must not become an unchecked loadable environment")
    ref = base / authority["reference"]
    # The document reference is relative to the repository root.
    if not ref.exists():
        ref = root / authority["reference"]
    require(ref.exists(), "reference missing")
    blob = subprocess.check_output(
        ["git", "-C", str(root), "hash-object", str(ref.resolve())],
        text=True).strip()
    require(blob == authority["referenceGitBlobSHA1"], "language authority blob changed")
    seed = read_json(base / "docs/PSC0_BOOTSTRAP_SEED_MANIFEST.json")
    source = base / "packages/environment/src/Ps/Environment/BootstrapData.lean"
    raw = source.read_bytes()
    require(hashlib.sha256(raw).hexdigest() == BOOTSTRAP_SHA, "bootstrap source changed")
    require(len(raw) == 118573, "bootstrap asset size mismatch")
    require(seed["schema"] == "pscv0-bootstrap-replay/1", "seed schema mismatch")
    require(seed["sourceSHA256"] == BOOTSTRAP_SHA and seed["sourceBytes"] == len(raw),
            "seed source identity mismatch")
    require(seed["nativeCommit"] == LEAN_SHA, "seed Lean pin changed")
    require(seed["declarations"] == 76 and len(seed["names"]) == 76,
            "seed name/count mismatch")
    require(len(set(seed["names"])) == 76, "duplicate Bootstrap declarations")
    require(seed["axioms"] == [] and seed["kernelTrustLevel"] == 0
            and seed["emptyBoundary"] is True, "Bootstrap trust boundary changed")
    require(seed["coreCompletenessClaimed"] is False and
            seed["compilerDefaultSelected"] is False, "seed mislabeled as full Core")
    require(seed["maxHeartbeatsPerDeclaration"] == 2000000
            and seed["maxRecDepthPerDeclaration"] == 20000,
            "source replay resource budget changed")
    evidence = read_json(base / "docs/core-first-evidence/e059-qualification.json")
    require(evidence["head"] == "e059098683d3388fc9f893ec12027b4998eafd52",
            "qualified predecessor changed")
    require(evidence["conclusion"] == "success" and len(evidence["jobs"]) == 4
            and all(job["conclusion"] == "success" for job in evidence["jobs"]),
            "prior source qualification is not the four-gate success")
    require(evidence["bootstrap"]["manifest"]["declarations"] == 76,
            "evidence disagrees with seed")
    return {"psc0Head": actual, "leanCommit": LEAN_SHA,
            "bootstrapSourceSHA256": BOOTSTRAP_SHA,
            "bootstrapDeclarations": 76, "compilerSufficient": False}


def verify_closure(report):
    require(report.get("schema") == "pscv0-core-native-closure/1", "closure schema mismatch")
    require(report.get("leanCommit") == LEAN_SHA, "closure Lean pin mismatch")
    for key, expected in EXPECTED.items():
        require(report.get(key) == expected, f"{key}: expected {expected}, got {report.get(key)}")
    require(report.get("emptyBoundary") is True, "closure must have an empty boundary")
    require(report.get("annotationsErased") is False, "raw closure annotations changed")
    require(report.get("candidateKernelAdmitted") is False,
            "inventory cannot claim candidate kernel admission")
    require(report.get("unsafe") == [] and report.get("partial") == [],
            "unsafe/partial entries in native compiler closure")

    modules = [named(x) for x in report["sourceModules"]]
    require(len(modules) == len(set(modules)) == EXPECTED["sourceModules"],
            "duplicate or missing source module")
    imports = [named(x) for x in report["importRoots"]]
    require(len(imports) == 7 and len(set(imports)) == 7
            and set(imports).issubset(set(modules)), "compiler import roots changed")

    entries = report["closureDeclarations"]
    require(len(entries) == EXPECTED["closureDeclarationCount"], "closure entries truncated")
    by_name = {}
    for entry in entries:
        key = named(entry["name"])
        require(key not in by_name, "duplicate declaration in closure")
        by_name[key] = entry
    closure_names = set(by_name)
    roots = [named(x) for x in report["externalRoots"]]
    require(len(roots) == len(set(roots)) == EXPECTED["externalRootCount"],
            "duplicate external roots")
    require(set(roots).issubset(closure_names), "external root missing in closure")
    witnesses = report["rootWitnesses"]
    require(len(witnesses) == len(roots), "missing external root witness")
    require(set(named(w["root"]) for w in witnesses) == set(roots),
            "root witness mismatch")
    for witness in witnesses:
        require(named(witness["sourceModule"]) in set(modules),
                "witness from unowned source")
        require(witness["edge"] in {"type", "value", "family-or-rule"},
                "unknown witness edge")

    seen_axioms = set()
    dep_edges = 0
    for key, entry in by_name.items():
        kind = entry["kind"]
        require(kind in {"axiom", "definition", "theorem", "opaque",
                         "quotient-primitive", "inductive", "constructor", "recursor"},
                "unexpected declaration kind")
        if kind == "axiom":
            seen_axioms.add(entry["name"]["display"])
        for field in ("typeDependencies", "valueDependencies",
                      "familyOrRuleDependencies", "dependencies"):
            require(isinstance(entry[field], list), "dependency field absent")
        deps = {named(d) for d in entry["dependencies"]}
        parts = {named(d) for field in ("typeDependencies", "valueDependencies",
                                      "familyOrRuleDependencies") for d in entry[field]}
        require(deps == parts, "flattened dependency edges differ from typed edges")
        require(deps.issubset(closure_names),
                f"open external dependency of {entry['name']['display']}")
        require(not named(entry["module"]) in set(modules)
                if entry["module"] is not None else True,
                "compiler-owned declaration incorrectly included as external")
        dep_edges += len(deps)
    require(seen_axioms == APPROVED,
            f"unexpected native logical assumption closure: {seen_axioms}")
    require({named(x["name"]) for x in report["axioms"]} ==
            {key for key, x in by_name.items() if x["kind"] == "axiom"},
            "axiom inventory disagrees with actual closure")
    require(dep_edges > 0, "closure has no dependency edges")
    return {"sourceModules": len(modules), "sourceDeclarations": report["sourceDeclarations"],
            "externalRoots": len(roots), "externalClosure": len(entries),
            "approvedAxiomsReached": sorted(seen_axioms), "dependencyEdges": dep_edges,
            "candidateKernelAdmitted": False, "selfHostQualified": False}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--psc0", type=pathlib.Path, required=True)
    parser.add_argument("--closure", type=pathlib.Path)
    parser.add_argument("--output", type=pathlib.Path)
    args = parser.parse_args()
    result = verify_source(args.psc0)
    if args.closure:
        raw = args.closure.read_bytes()
        result["measuredNativeClosure"] = verify_closure(json.loads(raw))
        result["nativeClosureSHA256"] = hashlib.sha256(raw).hexdigest()
        print("C0_CORE_NATIVE_CLOSURE=MEASURED_NOT_ADMITTED")
    else:
        print("C0_CORE_STATIC_CONTRACT=PASS_NOT_SELFHOST")
    result["schema"] = "c0-psc0-core-boundary-integrity/1"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n",
                               encoding="utf-8")
    print(json.dumps(result, sort_keys=True))


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, KeyError, TypeError, subprocess.CalledProcessError) as exc:
        print(f"C0_CORE_INTEGRITY_FAILURE: {exc}", file=sys.stderr)
        sys.exit(1)
