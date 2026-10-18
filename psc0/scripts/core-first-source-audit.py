#!/usr/bin/env python3
"""Read-only source inventory. This is not declaration closure or compiler qualification."""
import argparse
import collections
import hashlib
import json
import pathlib
import re
import resource
import subprocess
import time

PORTABLE_ROOTS = [
    "Ps.Compiler.Pscv0Modules", "Ps.BackendTs.Readable", "Ps.BackendRust.Module",
    "Ps.BackendWasm.Module", "Ps.CompilerIr.Checked", "Ps.Codegen.Api",
    "Ps.Codegen.Provenance",
]
OTHER_ROOTS = [
    "Ps.Compiler.Api", "Ps.Bootstrap.SelfHost", "Ps.BackendTs.Compiler",
    "Ps.Host.NativeV7", "PsKernelLean.Prelude", "Ps.Compiler.Engine",
    "Ps.Compiler.Core", "Ps.Environment.Bootstrap", "Ps.Environment.Core",
    "Ps.Environment.Full", "Ps.Environment.Fingerprint", "PsKernelLean.Replay",
]
FEATURES = {
    "mutual_blocks": r"(?m)^\s*mutual\b",
    "inductive_declarations": r"(?m)^\s*(?:(?:private|protected)\s+)?inductive\b",
    "structure_declarations": r"(?m)^\s*(?:(?:private|protected)\s+)?structure\b",
    "class_declarations": r"(?m)^\s*(?:(?:private|protected)\s+)?class\b",
    "instance_declarations": r"(?m)^\s*(?:(?:private|protected)\s+)?instance\b",
    "theorem_declarations": r"(?m)^\s*(?:(?:private|protected)\s+)?theorem\b",
    "axiom_declarations": r"(?m)^\s*(?:(?:private|protected)\s+)?axiom\b",
    "opaque_declarations": r"(?m)^\s*(?:(?:private|protected)\s+)?opaque\b",
    "partial_definitions": r"(?m)^\s*(?:(?:private|protected)\s+)?partial\s+def\b",
    "fixedpoint_suffixes": r"(?m)^\s*partial_fixpoint\b",
    "termination_suffixes": r"(?m)^\s*termination_by\b",
    "deriving_clauses": r"\bderiving\b",
    "do_tokens": r"\bdo\b", "for_tokens": r"\bfor\b",
    "mutable_lets": r"\blet\s+mut\b", "where_tokens": r"\bwhere\b",
    "tactic_values": r":=\s*by\b",
}
HEAVY_NAMES = {
    "StandardFloatOperationsData.lean", "StandardFloatConversionsData.lean",
    "StandardUnsignedOperationsData.lean", "StandardPlatformWordsData.lean",
    "StandardPartialFixpointData.lean", "StandardWellFoundedData.lean",
}

def visible_lean(text):
    """Blank nested comments/string literals, preserving physical line positions."""
    out, pos, depth, string = [], 0, 0, False
    while pos < len(text):
        pair, char = text[pos:pos + 2], text[pos]
        if depth:
            if pair == "/-":
                depth += 1
                out.extend("  ")
                pos += 2
            elif pair == "-/":
                depth -= 1
                out.extend("  ")
                pos += 2
            else:
                out.append("\n" if char == "\n" else " ")
                pos += 1
        elif string:
            if char == "\\" and pos + 1 < len(text):
                out.extend("\n" if value == "\n" else " " for value in text[pos:pos + 2])
                pos += 2
            else:
                if char == '"':
                    string = False
                out.append("\n" if char == "\n" else " ")
                pos += 1
        elif pair == "/-":
            depth = 1
            out.extend("  ")
            pos += 2
        elif pair == "--":
            end = text.find("\n", pos)
            end = len(text) if end < 0 else end
            out.extend(" " * (end - pos))
            pos = end
        elif char == '"':
            string = True
            out.append(" ")
            pos += 1
        else:
            out.append(char)
            pos += 1
    if depth or string:
        raise ValueError("unfinished comment/string in scanned Lean source")
    return "".join(out)

def module_name(path):
    value = path.as_posix()
    if "/src/" in value:
        return value.split("/src/", 1)[1][:-5].replace("/", ".")
    if value.startswith("packages/pskernel-lean/provider/"):
        return value.split("/provider/", 1)[1][:-5].replace("/", ".")
    return None

def closure(roots, modules):
    pending, seen, external, missing = list(roots), set(), set(), set()
    while pending:
        name = pending.pop()
        if name in seen:
            continue
        if name not in modules:
            (missing if name.startswith(("Ps.", "PsKernelLean.")) else external).add(name)
            continue
        seen.add(name)
        pending.extend(modules[name]["imports"])
    return {
        "roots": roots, "moduleCount": len(seen),
        "sourceBytes": sum(modules[name]["bytes"] for name in seen),
        "modules": sorted(seen), "externalImports": sorted(external),
        "unresolvedProjectImports": sorted(missing),
        "environmentModules": sorted(name for name in seen if name.startswith("Ps.Environment.")),
        "environmentBytes": sum(modules[name]["bytes"] for name in seen
                                if name.startswith("Ps.Environment.")),
        "fullCompositionImports": sorted(name for name in seen if name in {
            "Ps.Environment.SelfHostProd", "Ps.Environment.StandardSnapshot",
            "Ps.Host.StandardManifest", "PsKernelLean.Prelude"}),
    }

def audit(repository):
    started = time.perf_counter()
    root = repository / "psc0"
    head = subprocess.check_output(
        ["git", "-C", str(repository), "rev-parse", "HEAD"], text=True).strip()
    modules, assets = {}, []
    for path in sorted(root.rglob("*.lean")):
        relative = path.relative_to(root)
        name = module_name(relative)
        if not name:
            continue
        if name in modules:
            raise ValueError("duplicate module owner: " + name)
        data = path.read_bytes()
        code = visible_lean(data.decode("utf-8"))
        imports = []
        for line in code.splitlines():
            match = re.fullmatch(r"\s*(?:public\s+)?(?:meta\s+)?import\s+(.+?)\s*", line)
            if match:
                imports.extend(match.group(1).split())
        record = {
            "path": "psc0/" + relative.as_posix(), "bytes": len(data),
            "sha256": hashlib.sha256(data).hexdigest(),
            "gitBlobSHA1": hashlib.sha1(
                b"blob " + str(len(data)).encode("ascii") + b"\0" + data).hexdigest(),
            "imports": imports,
            "featureSignals": {key: len(re.findall(pattern, code))
                               for key, pattern in FEATURES.items()},
        }
        modules[name] = record
        if path.name in HEAVY_NAMES:
            assets.append({"module": name, **record})
    portable = closure(PORTABLE_ROOTS, modules)
    signals = collections.Counter()
    for name in portable["modules"]:
        signals.update(modules[name]["featureSignals"])
    packages = []
    for path in sorted(root.rglob("package.json")):
        if any(part in {"node_modules", ".lake", "dist"} for part in path.relative_to(root).parts):
            continue
        data = path.read_bytes()
        package = json.loads(data)
        packages.append({
            "path": "psc0/" + path.relative_to(root).as_posix(),
            "manifestSHA256": hashlib.sha256(data).hexdigest(),
            **{key: package.get(key) for key in [
                "name", "version", "private", "files", "dependencies",
                "optionalDependencies", "peerDependencies", "bundledDependencies"]},
        })
    return {
        "head": head, "moduleCount": len(modules),
        "sourceBytes": sum(item["bytes"] for item in modules.values()),
        "portableCompiler": portable,
        "portableFeatureSignals": dict(sorted(signals.items())),
        "rootClosures": {name: closure([name], modules) for name in OTHER_ROOTS},
        "heavyAssets": assets, "packages": packages, "modules": modules,
        "sourceAuditSeconds": time.perf_counter() - started,
    }

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--stage0", required=True, type=pathlib.Path)
    parser.add_argument("--candidate", required=True, type=pathlib.Path)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    args = parser.parse_args()
    stage0, candidate = audit(args.stage0), audit(args.candidate)
    if stage0["head"] != "33676076bcda7b0de5ec1f9803f49b8b1d28a058":
        raise ValueError("the audited qualified Stage 0 changed")
    for label, report in [("stage0", stage0), ("candidate", candidate)]:
        if report["portableCompiler"]["unresolvedProjectImports"]:
            raise ValueError(label + " has unresolved portable compiler imports: " +
                             repr(report["portableCompiler"]["unresolvedProjectImports"]))
    report = {
        "schema": "psc0-core-first-source-audit/1",
        "claim": "source/import/package inventory only; not semantic closure, selfhost or verified qualification",
        "stage0": stage0, "candidate": candidate,
        "auditPeakResidentBytes": resource.getrusage(resource.RUSAGE_SELF).ru_maxrss * 1024,
        "unmeasured": [
            "native compiler build time and peak memory",
            "generated compiler/runtime artifact bytes",
            "installed npm package bytes",
            "declaration/type/proof/registration closure",
            "Bootstrap/Core/Full semantic inclusion",
            "v7.2 compiler fixed point",
        ],
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    for label, value in [("stage0", stage0), ("candidate", candidate)]:
        summary = {key: value["portableCompiler"][key] for key in [
            "moduleCount", "sourceBytes", "environmentBytes", "externalImports",
            "unresolvedProjectImports", "fullCompositionImports"]}
        print("PSC0_CORE_SOURCE_AUDIT " + json.dumps(
            {"label": label, "head": value["head"], **summary}, sort_keys=True))
        print("PSC0_CORE_FEATURE_SIGNALS " + json.dumps(
            {"label": label, "signals": value["portableFeatureSignals"]}, sort_keys=True))
        for asset in value["heavyAssets"]:
            print("PSC0_CORE_ASSET " + json.dumps({
                "label": label, "path": asset["path"], "bytes": asset["bytes"],
                "gitBlobSHA1": asset["gitBlobSHA1"], "sha256": asset["sha256"]}, sort_keys=True))
    print("PSC0_CORE_SOURCE_AUDIT_COMPLETE: inventory only; semantic/profile/selfhost gates remain open")

if __name__ == "__main__":
    main()
