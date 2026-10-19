#!/usr/bin/env python3
"""Produce the complete source-owned PSC0 external root roster; never filter failures.

This is an integrity guard around independently measured native compiler
dependencies. It does not admit any declaration or close any self-host stage.
"""
import hashlib
import json
import pathlib
import sys

EXPECTED_SHA256 = "4fbd45b30ffbbb1c98f0da415d09d7b32abeea65ac37d62e2bea181096aeb02c"
EXPECTED_LEAN = "eb6cafb7290e8bd5f2937522d8d804f58f02bafc"
EXPECTED_IMPORTS = [
    "Ps.Compiler.Pscv0Modules", "Ps.BackendTs.Readable",
    "Ps.BackendRust.Module", "Ps.BackendWasm.Module",
    "Ps.CompilerIr.Checked", "Ps.Codegen.Api", "Ps.Codegen.Provenance"
]

def require(p, msg):
    if not p:
        raise ValueError(msg)

def main(argv):
    require(len(argv) == 3, "usage: native-closure.json roots.txt roots-summary.json")
    path, out, summary = map(pathlib.Path, argv)
    payload = path.read_bytes()
    digest = hashlib.sha256(payload).hexdigest()
    require(digest == EXPECTED_SHA256, f"closure SHA-256 mismatch: {digest}")
    doc = json.loads(payload)
    require(doc.get("schema") == "pscv0-core-native-closure/1", "wrong closure schema")
    require(doc.get("leanCommit") == EXPECTED_LEAN, "unpinned Lean")
    require(doc.get("sourceDeclarations") == 191611, "compiler source owner changed")
    require(doc.get("externalRootCount") == 458 and doc.get("closureDeclarationCount") == 5690,
            "incomplete or modified native closure")
    require(len(doc.get("sourceModules", [])) == 321, "compiler module closure changed")
    require([x.get("display") for x in doc.get("importRoots", [])] == EXPECTED_IMPORTS,
            "compiler entry-point set changed")
    require(doc.get("unsafe") == [] and doc.get("partial") == [],
            "nonlogical unsafe/partial closure")
    require(doc.get("candidateKernelAdmitted") is False, "false native admission receipt")
    require(doc.get("annotationsErased") is False, "raw declaration provenance changed")
    roots = doc.get("externalRoots")
    require(isinstance(roots, list) and len(roots) == 458, "root array incomplete")
    labels = []
    keys = set()
    for item in roots:
        require(isinstance(item, dict), "malformed native root")
        parts = item.get("parts")
        name = item.get("display")
        require(isinstance(parts, list) and parts, "anonymous/missing root")
        require(isinstance(name, str) and name and
                all(c not in name for c in "\r\n\x00"), "invalid root label")
        key = tuple((tuple(part.items())[0] if len(part) == 1 else None)
                    for part in parts)
        require(all(p is not None for p in key), "malformed name component")
        require(key not in keys, "duplicated canonical root")
        keys.add(key)
        labels.append(name)
    require(len(set(labels)) == 458, "name-render collision; export cannot be trusted")
    require("ByteArray.foldl" in labels, "known compiler source root missing")
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text("\n".join(labels) + "\n", encoding="utf-8")
    result = {"schema": "pskernel-c0-all-external-roots/1",
              "source": "psc0 native compiler at 53c28cfe3abd9e8fae93e7935357dbc4402c4b09",
              "sourceClosureSHA256": digest, "leanCommit": EXPECTED_LEAN,
              "sourceModules": 321, "sourceDeclarations": 191611,
              "selectedExternalRoots": len(labels), "excludedRoots": 0,
              "nativeExternalClosureDeclarations": 5690,
              "checkerAdmissionEstablished": False,
              "compilerSelfHostEstablished": False}
    summary.write_text(json.dumps(result, sort_keys=True, indent=2) + "\n",
                       encoding="utf-8")
    print("C0_ALL_ROOTS=458 EXACT_MEASURED_RAWSOURCE no_filters=true")
    print(json.dumps(result, sort_keys=True))

if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except (ValueError, KeyError, OSError, TypeError, json.JSONDecodeError) as exc:
        print(f"C0_ALL_ROOTS_REFUSED: {exc}", file=sys.stderr)
        raise SystemExit(1)
