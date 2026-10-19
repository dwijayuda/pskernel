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
    "Ps.Compiler.Pscv0Engine", "Ps.Compiler.Pscv0ModuleEngine", "Ps.Environment.InhabitedExpr", "Ps.Environment.ReprExpr",
]
ISOLATED_ROOTS = [
    "Ps.Environment.Bootstrap", "Ps.Environment.Fingerprint", "PsKernelLean.Replay", "Ps.Compiler.Engine",
    "Ps.Compiler.Pscv0Engine", "Ps.Compiler.Pscv0ModuleEngine", "Ps.Environment.InhabitedExpr", "Ps.Environment.ReprExpr",
]
INDEPENDENT_COMPILER_ROOTS = ["Ps.Compiler.Pscv0Engine"] + PORTABLE_ROOTS[1:]
INDEPENDENT_PROJECT_ROOTS = ["Ps.Compiler.Pscv0ModuleEngine"] + PORTABLE_ROOTS[1:]
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
    "while_tokens": r"\bwhile\b",
    "mutable_lets": r"\blet\s+mut\b", "where_tokens": r"\bwhere\b",
    "tactic_values": r":=\s*by\b",
}
HEAVY_NAMES = {
    "StandardFloatOperationsData.lean", "StandardFloatConversionsData.lean",
    "StandardUnsignedOperationsData.lean", "StandardPlatformWordsData.lean",
    "StandardPartialFixpointData.lean", "StandardWellFoundedData.lean",
}

def visible_lean(text):
    """Blank nested comments and Lean quoted/raw/character literals, preserving lines."""
    char_pattern = re.compile(r"'(?:\\(?:u\{[0-9a-fA-F]+\}|u[0-9a-fA-F]{4}|x[0-9a-fA-F]{2}|[^\r\n])|[^'\\\r\n])'")
    raw_pattern = re.compile(r'r(#+)"')
    out, pos, depth, string, raw_close = [], 0, 0, False, None
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
        elif raw_close is not None:
            if text.startswith(raw_close, pos):
                out.extend(" " * len(raw_close))
                pos += len(raw_close)
                raw_close = None
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
        else:
            literal = char_pattern.match(text, pos) if char == "'" else None
            raw = raw_pattern.match(text, pos) if char == "r" else None
            if literal:
                out.extend(" " * len(literal.group(0)))
                pos += len(literal.group(0))
            elif raw:
                raw_close = '"' + raw.group(1)
                out.extend(" " * len(raw.group(0)))
                pos += len(raw.group(0))
            elif char == '"':
                string = True
                out.append(" ")
                pos += 1
            else:
                out.append(char)
                pos += 1
    if depth or string or raw_close is not None:
        raise ValueError("unfinished comment/string in scanned Lean source")
    return "".join(out)

def module_name(path):
    # Current source owners only. Historical legacy copies are not native
    # compiler roots, and must not shadow the current package of the same name.
    value = path.as_posix()
    match = re.fullmatch(r"(?:packages/[^/]+/src|host/src)/(.+)\.lean", value)
    if match:
        return match.group(1).replace("/", ".")
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
            match = re.fullmatch(r"\s*(?:(?:public|meta)\s+)*import\s+(?:all\s+)?(.+?)\s*", line)
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
        "independentCompilerCandidate": closure(INDEPENDENT_COMPILER_ROOTS, modules),
        "independentProjectCandidate": closure(INDEPENDENT_PROJECT_ROOTS, modules),
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
    for name in ISOLATED_ROOTS:
        graph = candidate["rootClosures"][name]
        if graph["unresolvedProjectImports"]:
            raise ValueError("isolated seam has unresolved imports: " + name)
        forbidden = [item for item in graph["modules"] if
                     item in {"Ps.Environment.Prelude", "Ps.Environment.SelfHostPrelude",
                              "Ps.Environment.SelfHostProd", "PsKernelLean.Prelude"} or
                     item.startswith(("Ps.Environment.Standard", "Ps.Host."))]
        if forbidden:
            raise ValueError("isolated seam imports selected environment: " + repr(forbidden))
    for key in ["independentCompilerCandidate", "independentProjectCandidate"]:
        independent = candidate[key]
        if independent["unresolvedProjectImports"] or independent["externalImports"]:
            raise ValueError(key + " has an unresolved or host import")
        if any(name in {"Ps.Environment.Prelude", "Ps.Environment.SelfHostPrelude",
                         "Ps.Environment.SelfHostProd", "PsKernelLean.Prelude"} or
               name.startswith(("Ps.Environment.Standard", "Ps.Host.", "PsKernelLean."))
               for name in independent["modules"]):
            raise ValueError(key + " imports a Full or host composition")
    report = {
        "schema": "psc0-core-first-source-audit/1",
        "claim": "source/import/package inventory only; not semantic closure, selfhost or verified qualification",
        "moduleOwners": "current packages/*/src, host/src and pskernel-lean/provider; legacy copies excluded",
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
        for root_name in ISOLATED_ROOTS:
            graph = value["rootClosures"][root_name]
            print("PSC0_CORE_SEAM_IMPORTS " + json.dumps({
                "label": label, "root": root_name,
                **{key: graph[key] for key in ["moduleCount", "sourceBytes",
                    "externalImports", "unresolvedProjectImports", "fullCompositionImports"]}
            }, sort_keys=True))
        graph = value["independentCompilerCandidate"]
        print("PSC0_CORE_INDEPENDENT_COMPILER_IMPORTS " + json.dumps({
            "label": label,
            **{key: graph[key] for key in ["moduleCount", "sourceBytes",
                "environmentBytes", "externalImports", "unresolvedProjectImports",
                "fullCompositionImports"]}
        }, sort_keys=True))
        project = value["independentProjectCandidate"]
        print("PSC0_CORE_INDEPENDENT_PROJECT_IMPORTS " + json.dumps({
            "label": label, "roots": INDEPENDENT_PROJECT_ROOTS,
            **{key: project[key] for key in ["moduleCount", "sourceBytes",
                "environmentBytes", "externalImports", "unresolvedProjectImports",
                "fullCompositionImports"]}
        }, sort_keys=True))
        for name in value["portableCompiler"]["modules"]:
            record = value["modules"][name]
            print("PSC0_CORE_PORTABLE_MODULE " + json.dumps({
                "label": label, "module": name,
                **{key: record[key] for key in ["path", "bytes", "sha256",
                    "gitBlobSHA1", "imports"]}
            }, sort_keys=True))
        print("PSC0_CORE_FEATURE_SIGNALS " + json.dumps(
            {"label": label, "signals": value["portableFeatureSignals"]}, sort_keys=True))
        for asset in value["heavyAssets"]:
            print("PSC0_CORE_ASSET " + json.dumps({
                "label": label, "path": asset["path"], "bytes": asset["bytes"],
                "gitBlobSHA1": asset["gitBlobSHA1"], "sha256": asset["sha256"]}, sort_keys=True))
    print("PSC0_CORE_SOURCE_AUDIT_COMPLETE: inventory only; semantic/profile/selfhost gates remain open")

if __name__ == "__main__":
    main()
