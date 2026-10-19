#!/usr/bin/env python3
"""Authenticate the real selected PSC0 Core native external dependency graph.

Input is the immutable GitHub Actions artifact from native source commit
4e7ecea126c1f18977c86ce66e4fddb7df144aab / run 39193886098.
This is an inventory/strict replay gate, NOT a kernel admission certificate.
No source-owner, dependency or root may be silently omitted.
"""
import argparse
import hashlib
import json
from pathlib import Path
import sys

LEAN = "eb6cafb7290e8bd5f2937522d8d804f58f02bafc"
SOURCE = "4e7ecea126c1f18977c86ce66e4fddb7df144aab"
APPROVED = {"propext", "Quot.sound", "Classical.choice"}
IMPORTS = [
    "Ps.Compiler.Pscv0ModuleEngine",
    "Ps.BackendTs.Readable", "Ps.BackendRust.Module",
    "Ps.BackendWasm.Module", "Ps.CompilerIr.Checked",
    "Ps.Codegen.Api", "Ps.Codegen.Provenance",
]
SELECTED = {"sourceModules": 224, "sourceDeclarations": 21513,
            "externalRoots": 418, "externalClosure": 5619}
FULL = {"sourceModules": 322, "sourceDeclarations": 191633,
        "externalRoots": 458, "externalClosure": 5690}


def require(ok, reason):
    if not ok:
        raise ValueError(reason)


def canonical(item):
    require(isinstance(item, dict), "name must have canonical segments")
    label = item.get("display")
    parts = item.get("parts")
    require(isinstance(label, str) and label and
            all(c not in label for c in "\r\n\x00"),
            "malformed/display-injectable name")
    require(isinstance(parts, list) and parts, "missing canonical name")
    out = []
    for segment in parts:
        require(isinstance(segment, dict) and len(segment) == 1,
                "malformed canonical segment")
        key, value = next(iter(segment.items()))
        require((key == "str" and isinstance(value, str)) or
                (key == "num" and type(value) is int and value >= 0),
                "noncanonical name segment")
        out.append((key, value))
    return tuple(out)


def name_list(items, title):
    require(isinstance(items, list), f"{title}: not an array")
    names = [canonical(item) for item in items]
    require(len(set(names)) == len(names), f"{title}: duplicate canonical name")
    labels = [item["display"] for item in items]
    require(len(set(labels)) == len(labels), f"{title}: display collision")
    return set(names), labels


def verify(doc, comparison, raw_sha):
    require(doc.get("schema") == "pscv0-core-native-closure/1", "wrong graph schema")
    require(doc.get("leanCommit") == LEAN, "wrong Lean pin")
    require(doc.get("emptyBoundary") is True, "source boundary not empty")
    require(doc.get("annotationsErased") is False,
            "native raw source annotations unexpectedly erased")
    require(doc.get("candidateKernelAdmitted") is False,
            "inventory cannot authorize kernel admission")
    require(doc.get("unsafe") == [] and doc.get("partial") == [],
            "unsafe/partial native declaration")
    require(comparison.get("schema") == "psc0-selected-core-native-separation/1",
            "wrong cross-profile comparison")
    require(comparison.get("sourceCommit") == SOURCE, "wrong measured compiler commit")
    require(comparison.get("selected") == SELECTED, "selected audit totals changed")
    require(comparison.get("full") == FULL, "Full comparison audit changed")
    for key in ("selectedProfileInstalled", "c0KernelAdmitted", "coreCompilerSelfHost"):
        require(comparison.get(key) is False, f"unqualified status changed: {key}")
    modules, module_labels = name_list(doc.get("sourceModules"), "source modules")
    imports, import_labels = name_list(doc.get("importRoots"), "import roots")
    require(len(modules) == SELECTED["sourceModules"], "source module count")
    require(import_labels == IMPORTS and imports <= modules, "selected Core imports changed")
    require(doc.get("sourceDeclarations") == SELECTED["sourceDeclarations"],
            "source declaration count")
    roots, root_labels = name_list(doc.get("externalRoots"), "external roots")
    require(len(roots) == doc.get("externalRootCount") ==
            SELECTED["externalRoots"], "missing or extra Core root")
    entries = doc.get("closureDeclarations")
    require(isinstance(entries, list) and len(entries) ==
            doc.get("closureDeclarationCount") == SELECTED["externalClosure"],
            "incomplete external declaration closure")
    by_name = {}
    for entry in entries:
        key = canonical(entry["name"])
        require(key not in by_name, "duplicate external declaration")
        by_name[key] = entry
    closure = set(by_name)
    require(roots <= closure, "root absent from transitive dependency closure")
    witnesses = doc.get("rootWitnesses")
    require(isinstance(witnesses, list) and len(witnesses) == len(roots),
            "missing real compiler source witnesses")
    witnessed = set()
    for row in witnesses:
        root = canonical(row["root"])
        require(root in roots and root not in witnessed, "duplicate/alien witness")
        witnessed.add(root)
        require(canonical(row["sourceModule"]) in modules,
                "dependency not witnessed by a source-owned module")
        canonical(row["source"])
        require(row.get("edge") in ("type", "value", "family-or-rule"),
                "non-source dependency edge")
    require(witnessed == roots, "some external root lacks typed witness")
    kinds = {"axiom", "definition", "theorem", "opaque",
             "quotient-primitive", "inductive", "constructor", "recursor"}
    axiom_names = set()
    edges = 0
    for entry in entries:
        require(entry.get("kind") in kinds, "unsupported declaration kind")
        if entry["kind"] == "axiom":
            axiom_names.add(entry["name"]["display"])
        for field in ("typeDependencies", "valueDependencies",
                      "familyOrRuleDependencies", "dependencies"):
            require(isinstance(entry.get(field), list),
                    f"{field}: lost typed dependency edges")
        direct = set()
        for field in ("typeDependencies", "valueDependencies", "familyOrRuleDependencies"):
            direct.update(canonical(dep) for dep in entry[field])
        flattened = {canonical(dep) for dep in entry["dependencies"]}
        require(direct == flattened, "flattened dependency graph differs")
        require(flattened <= closure, "open reachable external dependency")
        owner = entry.get("module")
        if owner is not None:
            require(canonical(owner) not in modules, "compiler-owned declaration in external closure")
        edges += len(flattened)
    require(axiom_names == APPROVED, "unexpected/missing logical axioms")
    listed = {canonical(entry["name"]) for entry in doc.get("axioms", [])}
    require(listed == {canonical(entry["name"]) for entry in entries
                       if entry["kind"] == "axiom"}, "axiom inventory mismatch")
    require(edges > 0, "empty dependency edges")
    require(len(root_labels) == 418 and len(module_labels) == 224,
            "incorrect selected root population")
    return {
        "schema": "pskernel-c0-selected-native-roots/1",
        "compilerAuditCommit": SOURCE,
        "leanCommit": LEAN,
        "selected": SELECTED,
        "fullComparison": FULL,
        "graphSHA256": raw_sha,
        "externalRoots": root_labels,
        "rootCount": len(root_labels),
        "dependencyEdges": edges,
        "approvedLogicalAssumptions": sorted(APPROVED),
        "qualifiedChecker": False,
        "selectedCoreSelfHosted": False,
    }


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--selected", required=True, type=Path)
    p.add_argument("--comparison", required=True, type=Path)
    p.add_argument("--roots", required=True, type=Path)
    p.add_argument("--manifest", required=True, type=Path)
    args = p.parse_args()
    raw = args.selected.read_bytes()
    doc = json.loads(raw)
    comparison = json.loads(args.comparison.read_bytes())
    receipt = verify(doc, comparison, hashlib.sha256(raw).hexdigest())
    args.roots.parent.mkdir(parents=True, exist_ok=True)
    args.manifest.parent.mkdir(parents=True, exist_ok=True)
    args.roots.write_text("\n".join(receipt["externalRoots"]) + "\n", encoding="utf-8")
    args.manifest.write_text(json.dumps(receipt, sort_keys=True, indent=2) + "\n",
                             encoding="utf-8")
    print(f"C0_SELECTED_CORE_ROOTS=AUTHENTICATED count={receipt['rootCount']} "
          f"closure={SELECTED['externalClosure']} graph_sha256={receipt['graphSHA256']}")
    print("C0_SELECTED_CORE_STATUS=SOURCE_AUDIT_ONLY_NOT_ADMITTED")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, TypeError, KeyError, json.JSONDecodeError) as exc:
        print(f"C0_SELECTED_CORE_REFUSED: {exc}", file=sys.stderr)
        raise SystemExit(1)
