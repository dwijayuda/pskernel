#!/usr/bin/env python3
"""Statically authenticate one completed T05 ordinary-header route artifact.

This program reads JSON, ZIP/tar members, source text, maps, and Actions logs.
It never invokes Lean, JavaScript, PSC1, a generated kernel, or a project test.
See review-header-route-artifact.md for the exact command and input contract.
"""

import argparse
import ast
import datetime
import hashlib
import io
import json
import pathlib
import re
import stat
import sys
import tarfile
import zipfile


REPOSITORY = "dwijayuda/pskernel"
LEAN_COMMIT = "eb6cafb7290e8bd5f2937522d8d804f58f02bafc"
ENTRY = "packages/pskernel-core/src/Ps/KernelCore/SelfHost.lean"
CORE = "psc1/packages/pskernel-core/src/Ps/KernelCore/"
WORKFLOW = ".github/workflows/psc1-pskernel-t05-header.yml"
SCRIPTS = [
    "pskernel-ordinary-header-smoke.mjs",
    "pskernel-scalar-hash-worker-smoke.mjs",
    "pskernel-scalar-hash-short-entry-smoke.mjs",
    "pskernel-closed-cache-analysis-smoke.mjs",
    "pskernel-generated-smoke.mjs",
    "pskernel-expr-v2-dag-smoke.mjs",
    "pskernel-expr-v2-generated-prefix-smoke.mjs",
    "pskernel-invalid-recursor-occurrence-smoke.mjs",
]
SOURCE_PATHS = [
    WORKFLOW, "psc1/kernel-lakefile.lean", "psc1/lean-toolchain",
    "psc1/scripts/install-lean435-ci.sh",
    *[CORE + p + ".lean" for p in [
        "SelfHost", "API/DagAdmission", "API/DagOrdinaryHeaderTypes",
        "API/DagOrdinaryOccurrence", "API/DagOrdinaryAnnotations",
        "API/DagOrdinaryParameters", "API/DagOrdinaryHeader",
        "Checker/ExprV2/AdmissionHelpers",
    ]],
    *["psc1/test/" + p + ".lean" for p in [
        "PsKernelOrdinaryHeaderStateProofs", "PsKernelOrdinaryOccurrenceProofs",
        "PsKernelCacheScopeProofs", "PsKernelExprV2SessionProofs",
        "PsKernelScalarHashWorkerRegression", "PsKernelClosedCacheAnalysisRegression",
        "PsKernelKnotFuelProofs", "PsKernelOrdinaryHeaderRegression",
    ]],
    *["psc1/scripts/" + p for p in SCRIPTS],
    *[CORE + p + ".lean" for p in [
        "Admission/Inductive/Ordinary/Admission",
        "Admission/Inductive/Common/Parameters",
        "Admission/Inductive/Common/Occurrence", "Core/Expr",
    ]],
]
FROZEN = {
    CORE + "Admission/Inductive/Ordinary/Admission.lean":
        "63b3f93af8d1352037d40bbdc793471c3f2f3d80321ad24c680a3a897c402c05",
    CORE + "Admission/Inductive/Common/Parameters.lean":
        "7506663960991724551ae8af806996304a5e196db275fb22e168639028b803a3",
    CORE + "Admission/Inductive/Common/Occurrence.lean":
        "cc160e7cca9436170b64f845b393d0e8aa631ffb9ce61a74c0bedccb9587e9b0",
    CORE + "Core/Expr.lean":
        "068312a568ee3b1b86312d9a9e589a32813e45cf703d0830108efc1556666e51",
}
T05_MODULES = [
    "API/DagOrdinaryHeaderTypes", "API/DagOrdinaryOccurrence",
    "API/DagOrdinaryAnnotations", "API/DagOrdinaryParameters",
    "API/DagOrdinaryHeader", "Checker/ExprV2/AdmissionHelpers",
]
PACKAGE_BY_SECTION = {
    "Bootstrap": "bootstrap", "Foundation": "foundation", "Syntax": "syntax",
    "Core": "core", "Kernel": "pskernel-core", "KernelCore": "pskernel-core",
    "Environment": "environment", "Project": "project", "Meta": "meta",
    "Elab": "elab", "Bridge": "bridge", "CompilerIr": "compiler-ir",
    "Compiler": "compiler", "Erasure": "erasure", "BackendTs": "backend-ts",
    "BackendRust": "backend-rust", "BackendWasm": "backend-wasm",
}
HEADER_RESULT = {
    "assertions": 1992, "headerCases": 432, "positiveDirect": 10,
    "occurrenceFuelCases": 1026, "annotationFuelCases": 75,
    "callbackSequences": 3, "callbackFailures": 24,
    "headerOnly": True, "fullAdmission": False, "publicFallbackUsed": False,
    "sectionAssertions": {
        "harness": 1, "header": 444, "occurrence": 1378, "annotations": 94,
        "state": 47, "phases": 20, "topCallbacks": 8,
    },
}
CACHE_RESULT = {
    "expressions": 20, "states": 2, "mapQueries": 40, "pairQueries": 800,
    "inferQueries": 80, "assertions": 1884,
    "smallAndIndexed": True, "openEntriesSeeded": True,
}
SCALAR_RESULT = {
    "cases": 2730, "strings": 12, "stages": 8190, "assertions": 13665,
    "modulus": "65521", "algorithmChanged": False,
}
SHORT_RESULT = {
    "cases": 19, "assertions": 38, "shortMaxPairs": 4, "genericFallback": True,
}
DAG_CONTROLS = """
ZETA BETA WHNF_STATE PUBLIC_CACHE QUICK_DEFEQ NAT_PROJECTION NESTED_OUTCOMES
BINDER CHECK_APP DELTA CONSTANT_INDEX MUTUAL_INDEX CHECK_PROJECTION CHECK_LET
LET_CACHE_SCOPE LET_LOCAL_WHNF STATEFUL_DEFEQ APP_CONVERSION APP_CONVERSION_CACHE
APP_EAGER_CONTEXT SIMPLE_ADMISSION_MATRIX ADMISSION_SHARED_STATE ADMISSION_POLICY_SAFETY
ADMISSION_FINAL_GUARDS THEOREM_ADMISSION_MATRIX THEOREM_ISPROP_STATE UNSAFE_ADMISSION
UNSAFE_FRESH_BODY MUTUAL_ADMISSION MUTUAL_FRESH_MEMBER BINDER_SPINE BINDER_SPINE_BUDGET
BINDER_SPINE_CACHE BINDER_SPINE_FALLBACK DEFEQ_PREFIX CHEAP_CORE_POLICY CHEAP_PROJECTION_POLICY
DEFEQ_REFLECTION DEFEQ_PREFIX_GUARDS
""".split()
CODEGEN_MARKERS = [
    "PSC1_CLOSED_CACHE_ANALYSIS_CODEGEN: PASS dataResult=true recursiveSites=11 oldHashCalls=0 oldHasFVarCalls=0 recurry=false",
    "PSC1_HASH_LEAF_CODEGEN: PASS byteStepGenerator=false byteStepStaging=false byteMixDispatch=false stagedFullEntry=false",
    "PSC1_HASH_DATA_RESULT_CODEGEN: PASS helpers=2",
    "PSC1_HASH_FUSED_ENTRY_CODEGEN: PASS stateDispatch=false scanDispatch=false resultStaging=0 pairFallbackSites=1 shortLeafSites=1 exclusiveBranches=true primitiveRemainder=1 structuralGeneratorBlocks=1",
    "PSC1_HASH_SHORT_PAIRS_CODEGEN: PASS pure=true generators=0 schedulerCalls=0 staging=0 primitiveTransitions=8 stepDispatches=0 selectedMaxPairs=4 genericFallback=true",
    "PSC1_HASH_LEVEL_LIST_ENTRY_CODEGEN: PASS empty=575 specializedArities=0,1,2 genericFallback=true stagedResult=false",
]
STEP_NAMES = [
    "Verify exact route source, pins, frozen references and syntax",
    "Build authentic PSC1 for the bounded generation gate",
    "Install pinned TypeScript7.0.2",
    "Require retained bounded scalar and closed-cache strict generation plus1884matrix",
    "Check small structural occurrence and annotation closures before complete source",
    "Archive actual Lean closure and check complete authentic source after bounded gates",
    "Reconstruct and authenticate the complete canonical ProofScript closure",
    "Check and compile the independent complete route through TypeScript to JavaScript",
    "Retain controls and execute exact1992directheaderassertions with empty PATH",
    "Retain bounded gate artifacts on success or failure",
]
ROOT_FILES = {
    "compiler-build.log", "lean-version.txt", "lean-githash.txt", "node-version.txt",
    "typescript-version.txt", "source-inventory.json", "lean-source-manifest.json",
    "lean-source.tar.gz", "structural-occurrence-check.log",
    "structural-annotations-check.log", "complete-lean-check.log", "complete-build.log",
    "provenance.json", "scalar-hash.log", "closed-cache-analysis.log", "dag.memory",
    "dag.log", "prefix.memory", "prefix.log", "short-entry.log", "generated-smoke.log",
    "invalid-recursor.log", "header.memory", "header.log", "receipt.json",
}
CANONICAL_FILES = {
    "canonical-manifest.json", "canonical-source.tar.gz", "canonical-ps-check.log",
}
SUFFIXES = (".js", ".ts", ".d.ts", ".js.map")
BOUNDED_LOGS = {
    "psc1-scalar-hash-probe.log", "psc1-closed-cache-analysis-probe.log",
    "psc1-closed-cache-analysis-codegen.log",
}


class ReviewError(Exception):
    pass


def must(condition, message):
    if not condition:
        raise ReviewError(message)


def exact(left, right):
    """JSON equality with types preserved, including bool versus int."""
    if type(left) is not type(right):
        return False
    if isinstance(left, dict):
        return left.keys() == right.keys() and all(exact(left[k], right[k]) for k in left)
    if isinstance(left, list):
        return len(left) == len(right) and all(exact(a, b) for a, b in zip(left, right))
    return left == right


def digest(raw):
    return {"bytes": len(raw), "sha256": hashlib.sha256(raw).hexdigest()}


def git_blob(raw):
    return hashlib.sha1(b"blob " + str(len(raw)).encode() + b"\0" + raw).hexdigest()


def pairs_without_duplicates(pairs):
    result = {}
    for key, value in pairs:
        must(key not in result, "Duplicate JSON object key: " + key)
        result[key] = value
    return result


def parse_json(raw):
    return json.loads(raw, object_pairs_hook=pairs_without_duplicates)


def read_json(path):
    return parse_json(pathlib.Path(path).read_bytes())


def text(raw):
    return raw.decode("utf-8", errors="strict")


def normalized_log(raw):
    value = re.sub(r"\x1b\[[0-9;]*m", "", text(raw))
    return re.sub(r"^\d{4}-\d\d-\d\dT[^ ]+Z ?", "", value, flags=re.M)


def exact_line(lines, marker):
    must(lines.count(marker) == 1, "Expected one exact log marker: " + marker)


def one_record(lines, prefix):
    found = [line[len(prefix):] for line in lines if line.startswith(prefix)]
    must(len(found) == 1, "Expected one JSON log record: " + prefix)
    return parse_json(found[0])


def one_matching(lines, pattern):
    found = [line for line in lines if re.fullmatch(pattern, line)]
    must(len(found) == 1, "Expected one matching log marker: " + pattern)
    return found[0]


def safe_name(name):
    must(isinstance(name, str) and name and "\\" not in name and "\0" not in name,
         "Invalid archive path")
    p = pathlib.PurePosixPath(name)
    must(not p.is_absolute() and not re.match(r"^[A-Za-z]:", name),
         "Absolute archive path: " + name)
    must(all(part not in ("", ".", "..") for part in name.split("/")),
         "Noncanonical archive path: " + name)
    return name


def zip_members(path):
    files = {}
    with zipfile.ZipFile(path) as archive:
        seen = set()
        for info in archive.infolist():
            must(info.filename not in seen, "Duplicate ZIP member: " + info.filename)
            seen.add(info.filename)
            mode = (info.external_attr >> 16) & 0xFFFF
            must(not stat.S_ISLNK(mode), "ZIP symlink: " + info.filename)
            if info.is_dir():
                safe_name(info.filename.rstrip("/"))
                continue
            safe_name(info.filename)
            must(stat.S_IFMT(mode) in (0, stat.S_IFREG), "ZIP member is not regular")
            raw = archive.read(info)  # Includes CRC verification.
            must(len(raw) == info.file_size, "ZIP member size mismatch")
            files[info.filename] = raw
    return files


def tar_members(raw):
    files, seen = {}, set()
    with tarfile.open(fileobj=io.BytesIO(raw), mode="r:gz") as archive:
        for item in archive.getmembers():
            name = item.name.removeprefix("./")
            if item.isdir():
                if name not in ("", "."):
                    safe_name(name.rstrip("/"))
                continue
            safe_name(name)
            must(item.isfile() and not item.issym() and not item.islnk(),
                 "Tar member is not a regular file: " + name)
            must(name not in seen, "Duplicate tar member: " + name)
            seen.add(name)
            member = archive.extractfile(item)
            must(member is not None, "Unreadable tar member: " + name)
            data = member.read()
            must(len(data) == item.size, "Tar member size mismatch: " + name)
            files[name] = data
    return files


def api_pick(value, key, target):
    if key in value:
        matches = [v for v in value[key] if v.get("id") == target]
        must(len(matches) == 1, "API metadata must contain one requested " + key)
        return matches[0]
    must(value.get("id") == target, "Wrong API metadata id for " + key)
    return value


def seconds(start, end):
    parse = lambda value: datetime.datetime.fromisoformat(value.replace("Z", "+00:00"))
    result = (parse(end) - parse(start)).total_seconds()
    must(result >= 0, "Negative API interval")
    return result


def check_metadata(args):
    run = read_json(args.run_json)
    jobs = read_json(args.jobs_json)
    job = api_pick(jobs, "jobs", args.job_id)
    artifact = api_pick(read_json(args.artifact_json), "artifacts", args.artifact_id)
    must(run["id"] == args.run_id and run["run_attempt"] == args.attempt
         and run["head_sha"] == args.source_sha, "Run identity mismatch")
    must(run["repository"]["full_name"] == REPOSITORY, "Run repository mismatch")
    must(job["run_id"] == args.run_id and job["run_attempt"] == args.attempt
         and job["head_sha"] == args.source_sha, "Job identity mismatch")
    must(job["name"] == "generated-header (" + args.route + ")", "Job route mismatch")
    must(job["status"] == "completed" and job["conclusion"] == "success",
         "Route job has not completed successfully")
    must("ubuntu-latest" in job["labels"], "Route was not a GitHub Actions Linux job")
    must(job["run_url"] == "https://api.github.com/repos/" + REPOSITORY
         + "/actions/runs/" + str(args.run_id), "Job repository mismatch")
    must(artifact["workflow_run"]["id"] == args.run_id
         and artifact["workflow_run"]["head_sha"] == args.source_sha,
         "Artifact source/run mismatch")
    must(artifact["name"] == "psc1-t05-header-" + args.route + "-attempt-" + str(args.attempt),
         "Artifact route/attempt mismatch")
    must(artifact["expired"] is False, "Artifact is expired")
    archive_raw = pathlib.Path(args.zip).read_bytes()
    must(len(archive_raw) == artifact["size_in_bytes"], "Artifact ZIP size mismatch")
    must(artifact["digest"] == "sha256:" + digest(archive_raw)["sha256"],
         "Artifact ZIP SHA256 does not match API metadata")
    steps = job["steps"]
    selected = []
    for name in STEP_NAMES:
        found = [s for s in steps if s["name"] == name]
        must(len(found) == 1, "Missing/duplicate required route step: " + name)
        step = found[0]
        skip = args.route == "generated" and name == STEP_NAMES[6]
        must(step["status"] == "completed" and step["conclusion"] == ("skipped" if skip else "success"),
             "Required route step did not succeed: " + name)
        selected.append(step)
    must([s["number"] for s in selected] == sorted(set(s["number"] for s in selected)),
         "Route gates are out of order")
    active = [s for s in selected if s["conclusion"] == "success"]
    for before, after in zip(active, active[1:]):
        must(before["completed_at"] <= after["started_at"], "Required gate order was not sequential")
    runtime_step = selected[8]
    runtime_seconds = seconds(runtime_step["started_at"], runtime_step["completed_at"])
    must(runtime_seconds < 1500, "Runtime step exceeded the unchanged 25-minute cap")
    job_seconds = seconds(job["started_at"], job["completed_at"])
    must(job_seconds < 4500, "Route job exceeded its 75-minute workflow cap")
    must("jobs" in jobs, "--jobs-json must contain the native dependency as well")
    native = [j for j in jobs["jobs"] if j["name"] == "native-header"]
    must(len(native) == 1, "Missing/duplicate native-first dependency job")
    native = native[0]
    must(native["run_id"] == args.run_id and native["run_attempt"] == args.attempt
         and native["head_sha"] == args.source_sha and native["status"] == "completed"
         and native["conclusion"] == "success", "Native-first dependency is not successful at this source")
    must(native["completed_at"] <= job["started_at"], "Route began before native dependency completed")
    return run, job, artifact, digest(archive_raw), {
        "requiredSteps": selected, "runtimeStepSeconds": runtime_seconds,
        "wholeRouteJobSeconds": job_seconds, "nativeDependency": native,
        "nativeProofArtifactReauditedByThisScript": False,
    }


def derive_closure(members):
    visited, edges = set(), {}
    def visit(path):
        if path in visited:
            return
        must(path in members, "Missing imported Lean source: " + path)
        visited.add(path)
        imports = re.findall(r"^\s*import\s+([A-Za-z0-9_.]+)\s*;?\s*$",
                             text(members[path]), re.M)
        dependencies = []
        for name in imports:
            parts = name.split(".")
            if parts[0] == "ProofScript":
                dependency = "stdlib/" + "/".join(parts) + ".lean"
            elif parts[0] == "Ps" and len(parts) > 1 and parts[1] in PACKAGE_BY_SECTION:
                dependency = "packages/" + PACKAGE_BY_SECTION[parts[1]] + "/src/" + "/".join(parts) + ".lean"
            else:
                raise ReviewError("Unrecognized portable import: " + name)
            dependencies.append(dependency)
            visit(dependency)
        edges[path] = dependencies
    visit(ENTRY)
    must(visited == set(members), "Lean archive is not exactly the recursively imported closure")
    return edges


def check_codegen(raw, recorded_lines=None):
    """Independent text recheck of the unchanged strict bounded generated-body gate."""
    source = text(raw)
    bodies = {}
    def exports(prefix):
        return re.findall(r"^export function (" + re.escape(prefix) + r"[A-Za-z0-9_$]*)\(",
                          source, re.M)
    def body(name, direct=False):
        marker = ("export function " if direct else "function* __ps$impl$") + name + "("
        if marker not in source and not direct:
            marker = "export function " + name + "("
        must(source.count(marker) == 1, "Missing/duplicate generated body: " + name)
        start = source.index(marker)
        end = source.find("\nexport ", start + len(marker))
        result = source[start:] if end < 0 else source[start:end]
        bodies[name] = result
        return result
    def exclude(value, words, name):
        for word in words:
            must(word not in value, "Forbidden generated machinery in " + name + ": " + word)
    name = "psKernelExprClosedCacheAnalysis"
    must(exports(name) == [name], "Closed-cache worker was recurried")
    analysis = body(name)
    exclude(analysis, ("_$psc0SH", "__ps$wrap", "psKernelExprHash", "psKernelExprHasFVar"), name)
    must(analysis.count("__ps$invoke(" + name + ",") == 11, "Closed-cache recursion count changed")
    iterators = {
        "psKernelCacheStringHashPairsWithFuel": 2,
        "psKernelCacheStringHashStateWithFuel": 1,
    }
    for name, transitions in iterators.items():
        must(exports(name) == [name], "Iterator was recurried: " + name)
        value = body(name)
        exclude(value, ("__ps$wrap", "psKernelCacheStringHashStep", "psKernelCacheMix"), name)
        must(value.count("__ps$invoke(") == 1
             and value.count("__ps$invoke(psKernelCacheStringHashPairsWithFuel,") == 1,
             "Iterator dispatch count changed: " + name)
        must(len(re.findall(r"function\s*\*\s*\(", value)) == 1,
             "Iterator structural generator count changed: " + name)
        must(value.count("__ps$stringNext(") == transitions
             and value.count("__ps$stringGet(") == transitions,
             "Iterator primitive transition count changed: " + name)
    entry = body("psKernelCacheStringHash")
    exclude(entry, (
        "__ps$wrap", "psKernelCacheStringHashWorker", "psKernelCacheStringHashScan",
        "psKernelCacheStringHashStateWithFuel", "psKernelCacheStringHashRemainderWithFuel",
        "psKernelCacheStringHashOctetsWithFuel", "psKernelCacheStringHashStep", "psKernelCacheMix",
    ), "full entry")
    must(entry.count("__ps$invoke(") == 2
         and entry.count("__ps$invoke(psKernelCacheStringHashPairsWithFuel,") == 1
         and entry.count("__ps$invoke(psKernelCacheStringHashShortPairs,") == 1,
         "Full hash dispatch inventory changed")
    must("const paired = ((pairs <= 4n) ? (yield* __ps$invoke(psKernelCacheStringHashShortPairs," in entry
         and ": (yield* __ps$invoke(psKernelCacheStringHashPairsWithFuel," in entry,
         "Exact exclusive short-pair/generic branch changed")
    must(len(re.findall(r"function\s*\*\s*\(", entry)) == 1
         and entry.count("__ps$stringNext(") == 1 and entry.count("__ps$stringGet(") == 1,
         "Fused entry generator/remainder count changed")
    name = "psKernelCacheStringHashShortPairs"
    must(exports(name) == [name], "Short-pair leaf was recurried")
    short = body(name)
    exclude(short, ("function*", "__ps$run", "__ps$invoke", "__ps$wrap",
                   "psKernelCacheStringHashPairsWithFuel", "psKernelCacheStringHashStep",
                   "psKernelCacheMix"), name)
    must(short.count("__ps$stringNext(") == 8 and short.count("__ps$stringGet(") == 8,
         "Short-pair primitive count changed")
    level = body("psKernelCacheLevelListHash")
    must("__ps$wrap" not in level and 'case "nil": return 575n;' in level,
         "Level-list empty result changed")
    must(level.count("__ps$invoke(psKernelCacheLevelListHashWorker,") == 1
         and level.count("__ps$invoke(psKernelCacheLevelHash,") == 3,
         "Level-list specialization/fallback changed")
    step = body("psKernelCacheStringHashStep", direct=True)
    exclude(step, ("function*", "__ps$run", "__ps$invoke", "__ps$wrap"), "byte step")
    if recorded_lines is not None:
        for marker in CODEGEN_MARKERS:
            exact_line(recorded_lines, marker)
        recorded = {
            "psKernelExprClosedCacheAnalysis": "PSC1_CLOSED_CACHE_ANALYSIS_BODY ",
            "psKernelCacheStringHash": "PSC1_HASH_FUSED_ENTRY_BODY ",
            "psKernelCacheStringHashShortPairs": "PSC1_HASH_SHORT_PAIRS_BODY ",
            "psKernelCacheLevelListHash": "PSC1_HASH_LEVEL_LIST_ENTRY_BODY ",
            **{name: "PSC1_HASH_ITERATOR_BODY " + name + " " for name in iterators},
        }
        for name, prefix in recorded.items():
            found = [line[len(prefix):] for line in recorded_lines if line.startswith(prefix)]
            must(len(found) == 1, "Missing/duplicate emitted generated body: " + name)
            # Only parses Python string literals; never executes archive content.
            must(ast.literal_eval(found[0]) == bodies[name], "Emitted body differs from actual JS: " + name)
    return {
        "strictBodiesRechecked": True, "closedCacheStructuralRecursiveSites": 11,
        "closedCacheOldHashCalls": 0, "closedCacheOldFreeVariableCalls": 0,
        "bodyDigests": {name: digest(value.encode()) for name, value in bodies.items()},
        "recordedBodyBytesMatched": recorded_lines is not None,
    }


def check_quartet(files, prefix, basename):
    for suffix in SUFFIXES:
        name = prefix + "/kernel" + suffix
        must(name in files and len(files[name]) > 0, "Missing/empty generated output: " + name)
        text(files[name])
    mapping = parse_json(files[prefix + "/kernel.js.map"])
    must(type(mapping["version"]) is int and mapping["version"] == 3
         and mapping["file"] == basename + ".js"
         and mapping["sources"] == [basename + ".ts"]
         and mapping.get("sourceRoot") == ""
         and isinstance(mapping["mappings"], str) and mapping["mappings"],
         "Generated source map does not bind the expected TypeScript output")
    if "sourcesContent" in mapping:
        must(mapping["sourcesContent"] == [text(files[prefix + "/kernel.ts"])],
             "Embedded source-map TypeScript differs from archived source")
    must(text(files[prefix + "/kernel.js"]).rstrip().endswith(
        "//# sourceMappingURL=" + basename + ".js.map"), "Generated JS source-map reference mismatch")
    return {
        "files": {suffix: digest(files[prefix + "/kernel" + suffix]) for suffix in SUFFIXES},
        "mapVersion": 3, "mapFile": mapping["file"], "mapSources": mapping["sources"],
        "mapMappingsCharacters": len(mapping["mappings"]),
    }


def parse_measurement(raw):
    value = text(raw).strip()
    match = re.fullmatch(r"peak_rss_kib=(\d+) wall_seconds=(\d+(?:\.\d+)?) exit_status=0", value)
    must(match is not None, "Runtime measurement is not an exact successful time record")
    must(int(match[1]) > 0 and float(match[2]) < 1500,
         "Runtime measurement is invalid or exceeds 25 minutes")
    return {"measurement": value, "peakRssKiB": int(match[1]), "wallSeconds": float(match[2])}


def review(args):
    must(re.fullmatch(r"[0-9a-f]{40}", args.source_sha) is not None, "Expected exact source SHA")
    must(args.expected_source_count == 146, "This verifier is scoped to the 146-module header slice")
    must(len(SOURCE_PATHS) == len(set(SOURCE_PATHS)) == 32, "Internal copied-source inventory error")
    must(sum(HEADER_RESULT["sectionAssertions"].values()) == 1992, "Internal header inventory error")
    run, job, artifact, archive_digest, gate_order = check_metadata(args)
    files = zip_members(args.zip)
    terminal_raw = pathlib.Path(args.job_log).read_bytes()
    terminal = normalized_log(terminal_raw)
    terminal_lines = terminal.splitlines()
    must(not re.search(r"^.*(?:\.lean:\d+:\d+: error:|uncaught exception: PSC1_|##\[error\])",
                       terminal, re.M), "Terminal job log contains a compiler/Actions error")
    git_map_raw = pathlib.Path(args.git_blobs_json).read_bytes()
    git_map = parse_json(git_map_raw)
    must(git_map["sourceSha"] == args.source_sha, "Git blob map belongs to a different source")
    must(re.fullmatch(r"[0-9a-f]{40}", git_map["treeSha"]) is not None, "Missing authenticated tree SHA")
    blobs = git_map["gitBlobs"]
    identity = {
        "sourceSha": args.source_sha, "runId": str(args.run_id),
        "runAttempt": str(args.attempt), "route": args.route,
    }
    inventory = parse_json(files["source-inventory.json"])
    expected_inventory_keys = {
        "schema", "repository", *identity, "job", "leanCommit", "files",
    }
    must(set(inventory) == expected_inventory_keys, "Unexpected source inventory shape")
    for key, value in {
        "schema": "psc1-t05-header-source-inventory-v1", "repository": REPOSITORY,
        "job": "generated-header", "leanCommit": LEAN_COMMIT, **identity,
    }.items():
        must(exact(inventory[key], value), "Source inventory mismatch: " + key)
    must([f["path"] for f in inventory["files"]] == SOURCE_PATHS,
         "Copied source inventory is not the exact ordered 32-input inventory")
    source_records = []
    for record in inventory["files"]:
        path = record["path"]
        raw = files["sources/" + path]
        actual = {"path": path, **digest(raw), "gitBlobSha": git_blob(raw)}
        must(exact(record, actual), "Copied source content mismatch: " + path)
        must(blobs.get(path) == actual["gitBlobSha"], "Copied source Git blob mismatch: " + path)
        if path in FROZEN:
            must(actual["sha256"] == FROZEN[path], "Frozen V1 reference changed: " + path)
        source_records.append(actual)
    must(exact(one_record(terminal_lines, "PSC1_T05_SOURCE_INVENTORY "), inventory),
         "Terminal source inventory differs from archived inventory")
    must(text(files["sources/psc1/lean-toolchain"]).strip() == "leanprover/lean4:v4.35.0",
         "Lean toolchain changed")
    must(text(files["lean-githash.txt"]).strip() == LEAN_COMMIT, "Actual Lean commit changed")
    must(re.search(r"\bLean \(version 4\.35\.0(?:,|\))", text(files["lean-version.txt"])) is not None,
         "Actual Lean version changed")
    node_version = text(files["node-version.txt"]).strip()
    must(re.fullmatch(r"v22\.\d+\.\d+", node_version) is not None, "Actual Node major changed")
    must(text(files["typescript-version.txt"]).strip() == "Version 7.0.2", "TypeScript pin changed")
    workflow = text(files["sources/" + WORKFLOW])
    # The full workflow bytes are authenticated above; these tokens identify the
    # resource/source isolation relied on by the route's independently read receipt.
    for token in [
        "timeout-minutes: 75", "timeout-minutes: 25",
        "max-parallel: 2", "persist-credentials: false", "include-hidden-files: true",
        'env PATH="" "$PSC1_T05_NODE" --max-old-space-size=2048',
        "typescript@7.0.2", LEAN_COMMIT,
    ]:
        must(token in workflow, "Required authenticated workflow constraint missing: " + token)
    must(re.search(r"(?m)^    needs:\s*\n    - native-header$", workflow) is not None,
         "Native-first workflow dependency is missing")
    manifest = parse_json(files["lean-source-manifest.json"])
    expected_manifest = {
        "schema": "psc1-t05-lean-source-closure-v1", **identity, "entry": ENTRY,
        "sourceCount": args.expected_source_count, "files": manifest["files"],
    }
    must(exact(manifest, expected_manifest), "Lean closure manifest identity/shape mismatch")
    paths = [record["path"] for record in manifest["files"]]
    must(paths == sorted(set(paths)) and len(paths) == args.expected_source_count,
         "Lean source manifest is not exactly 146 unique ordered modules")
    lean = {}
    lean_records = []
    for record in manifest["files"]:
        path = safe_name(record["path"])
        must(path.endswith(".lean"), "Non-Lean source in Lean closure")
        raw = files["lean-source/" + path]
        must(exact(record, {"path": path, **digest(raw)}), "Lean source digest mismatch: " + path)
        actual_blob = git_blob(raw)
        must(blobs.get("psc1/" + path) == actual_blob, "Lean source Git blob mismatch: " + path)
        lean[path] = raw
        lean_records.append({**record, "gitBlobSha": actual_blob})
    lean_tar = tar_members(files["lean-source.tar.gz"])
    must(lean_tar == lean, "Lean tar differs from all individual archived Lean sources")
    edges = derive_closure(lean)
    for module in T05_MODULES:
        must(CORE.removeprefix("psc1/") + module + ".lean" in lean,
             "New T05 module missing from actual closure: " + module)
    must(not any("/test/" in path or "ConstructorParams" in path or "ConstructorResult" in path
                 or "ReplayModelProofs" in path for path in lean),
         "Future/test-only module unexpectedly entered the header production closure")
    exact_line(terminal_lines, "PSC1_T05_LEAN_SOURCE_CLOSURE: PASS modules=146")
    canonical_review = None
    canonical = args.route == "canonical"
    if canonical:
        canonical_tar = tar_members(files["canonical-source.tar.gz"])
        bootstrap = parse_json(files["canonical-manifest.json"])
        must(canonical_tar[".proofscript-bootstrap.json"] == files["canonical-manifest.json"],
             "Canonical tar and copied bootstrap manifest differ")
        generated = [path.removesuffix(".lean") + ".ps" for path in paths]
        must(type(bootstrap["schemaVersion"]) is int and bootstrap["schemaVersion"] == 2
             and bootstrap["generation"] == "bootstrap"
             and bootstrap["entry"] == ENTRY.removesuffix(".lean") + ".ps"
             and exact(bootstrap["sourceCount"], args.expected_source_count)
             and bootstrap["generated"] == generated,
             "Canonical manifest is not the exact 146-module Lean-derived .ps closure")
        must(set(canonical_tar) == set(generated) | {".proofscript-bootstrap.json"},
             "Canonical tar contains missing or extraneous files")
        closure = hashlib.sha256()
        closure.update(b"proofscript-bootstrap-closure-v2\0")
        closure.update(bootstrap["entry"].encode() + b"\0")
        for path in generated:
            safe_name(path)
            text(canonical_tar[path])
            closure.update(path.encode() + b"\0" + canonical_tar[path] + b"\0")
        must(closure.hexdigest() == bootstrap["closureSha256"], "Canonical closure hash mismatch")
        exact_line(terminal_lines, "PSKERNEL_CANONICAL_PS_SOURCES: PASS modules=146")
        exact_line(terminal_lines, "PSC2_BOOTSTRAP_PS_CLOSURE_SHA256: " + closure.hexdigest())
        canonical_review = {
            "manifest": bootstrap, "archive": digest(files["canonical-source.tar.gz"]),
            "manifestMatchesTarBytes": True, "matchesLeanClosurePaths": True,
            "independentClosureSha256": closure.hexdigest(),
            "files": [{"path": name, **digest(raw)} for name, raw in sorted(canonical_tar.items())],
        }
    else:
        must(not CANONICAL_FILES.intersection(files), "Generated route unexpectedly carries canonical artifacts")
    expected_files = (
        ROOT_FILES | (CANONICAL_FILES if canonical else set())
        | {"production/kernel" + suffix for suffix in SUFFIXES}
        | {"bounded/kernel" + suffix for suffix in SUFFIXES}
        | {"bounded/" + name for name in BOUNDED_LOGS}
        | {"detached/kernel.mjs"} | {"detached/" + name for name in SCRIPTS}
        | {"sources/" + path for path in SOURCE_PATHS}
        | {"lean-source/" + path for path in paths}
    )
    must(set(files) == expected_files,
         "Unexpected complete archive file set; missing=" + repr(sorted(expected_files - set(files)))
         + " extra=" + repr(sorted(set(files) - expected_files)))
    bounded_quartet = check_quartet(files, "bounded", "kernel")
    production_quartet = check_quartet(files, "production", "pskernel-core" if canonical else "kernel")
    must(files["production/kernel.js"] == files["detached/kernel.mjs"],
         "Executed detached kernel differs from compiled production kernel")
    for name in SCRIPTS:
        must(files["detached/" + name] == files["sources/psc1/scripts/" + name],
             "Detached executed script differs from exact-source input: " + name)
    public_exports = [
        "psKernelExprV2OrdinaryAnalyzeHeaderWith", "psKernelExprV2OrdinaryAnalyzeHeaderWithFuel",
        "psKernelExprV2OrdinaryOpenHeaderParamsWith", "psKernelExprV2OrdinaryOpenHeaderIndicesWith",
    ]
    for name in public_exports:
        must(re.search(r"^export function " + name + r"\(", text(files["production/kernel.js"]), re.M),
             "Complete production JS lacks T05 export: " + name)
        for suffix in (".ts", ".d.ts"):
            must(name in text(files["production/kernel" + suffix]),
                 "Generated TypeScript/declaration output lacks T05 symbol: " + name)
    codegen_lines = text(files["bounded/psc1-closed-cache-analysis-codegen.log"]).splitlines()
    bounded_bodies = check_codegen(files["bounded/kernel.js"], codegen_lines)
    complete_bodies = check_codegen(files["production/kernel.js"])
    for marker in CODEGEN_MARKERS:
        exact_line(terminal_lines, marker)
    provenance = parse_json(files["provenance.json"])
    expected_provenance = {
        "schema": "psc1-t05-header-provenance-v1", "repository": REPOSITORY, **identity,
        "job": "generated-header", "leanCommit": LEAN_COMMIT, "typescript": "7.0.2",
        "node": node_version, "fuel": 4096, "oldSpaceMiB": 2048,
        "oldSpaceIsHardRssLimit": False, "emptyPATH": True,
        "kernel": digest(files["detached/kernel.mjs"]),
        "harness": digest(files["detached/pskernel-ordinary-header-smoke.mjs"]),
        "sourceInventory": digest(files["source-inventory.json"]),
        "leanSourceManifest": digest(files["lean-source-manifest.json"]),
        "scripts": {name: digest(files["detached/" + name]) for name in SCRIPTS},
        "headerOnly": True, "fullAdmission": False, "publicFallbackUsed": False,
    }
    if canonical:
        expected_provenance.update({
            "canonicalManifest": digest(files["canonical-manifest.json"]),
            "canonicalSourceArchive": digest(files["canonical-source.tar.gz"]),
        })
    must(exact(provenance, expected_provenance), "Producer provenance differs from actual archive inputs")
    must(exact(one_record(terminal_lines, "PSC1_T05_HEADER_PROVENANCE "), provenance),
         "Terminal provenance differs from archived producer identity")
    gates = []
    def json_gate(filename, prefix, expected, terminal_count=None):
        lines = text(files[filename]).splitlines()
        result = one_record(lines, prefix)
        must(exact(result, expected), "Wrong exact runtime result in " + filename)
        if terminal_count is not None:
            actual = [parse_json(line[len(prefix):]) for line in terminal_lines if line.startswith(prefix)]
            must(len(actual) == terminal_count and all(exact(value, expected) for value in actual),
                 "Terminal runtime result inventory differs for " + prefix)
        gates.append({"file": filename, "prefix": prefix, "result": result})
        return result
    json_gate("bounded/psc1-closed-cache-analysis-probe.log",
              "PSC1_CLOSED_CACHE_ANALYSIS_JS: PASS ", CACHE_RESULT)
    json_gate("closed-cache-analysis.log", "PSC1_CLOSED_CACHE_ANALYSIS_JS: PASS ", CACHE_RESULT, 2)
    json_gate("bounded/psc1-scalar-hash-probe.log", "PSC1_SCALAR_HASH_WORKER_JS: PASS ", SCALAR_RESULT)
    json_gate("scalar-hash.log", "PSC1_SCALAR_HASH_WORKER_JS: PASS ", SCALAR_RESULT, 2)
    json_gate("bounded/psc1-scalar-hash-probe.log", "PSC1_SCALAR_HASH_SHORT_ENTRY_JS: PASS ", SHORT_RESULT)
    json_gate("short-entry.log", "PSC1_SCALAR_HASH_SHORT_ENTRY_JS: PASS ", SHORT_RESULT, 2)
    header_result = json_gate("header.log", "PSC1_ORDINARY_HEADER_JS: PASS ", HEADER_RESULT, 1)
    for name in ("bounded/psc1-scalar-hash-probe.log", "scalar-hash.log"):
        exact_line(text(files[name]).splitlines(), "PSC1_SCALAR_HASH_LONG_JS: PASS cases=3")
    must(terminal_lines.count("PSC1_SCALAR_HASH_LONG_JS: PASS cases=3") == 2,
         "Terminal bounded/full scalar long controls missing")
    dag_lines = text(files["dag.log"]).splitlines()
    dag_exact = [
        "PSC1_V2_DAG_JS_WHNF_STAGED_ABI: PASS exports=2 partials=4 executions=6",
        "PSC1_EXPR_EQUALITY_DELAYED_JS: PASS hostile=21 staged=2 sharedDepth=64",
    ]
    for marker in dag_exact:
        exact_line(dag_lines, marker)
        exact_line(terminal_lines, marker)
    dag_prefixes = ["PSC1_V2_DAG_JS: PASS", "PSC1_V2_TRANSFORM_JS: PASS"]
    dag_prefixes += ["PSC1_V2_DAG_JS_" + name + ": PASS" for name in DAG_CONTROLS]
    dag_markers = list(dag_exact)
    for prefix in dag_prefixes:
        marker = one_matching(dag_lines, re.escape(prefix) + r"(?: .*)?")
        exact_line(terminal_lines, marker)
        dag_markers.append(marker)
    gates.append({"file": "dag.log", "markers": dag_markers})
    prefix_lines = text(files["prefix.log"]).splitlines()
    prefix_markers = [
        "PSC1_V2_GENERATED_PREFIX_JS: PASS new=24 recursors=7 direct=6 privateIDs=3",
        "PSC1_V2_SESSION_OWNERS_JS: PASS kinds=8 direct=7 privateIDs=5 forks=2",
        one_matching(prefix_lines,
                     r"PSC1_V2_GENERATED_PREFIX_CONTROLS_JS: PASS positive=6 negative=7 assertions=[0-9]+"),
    ]
    for marker in prefix_markers:
        exact_line(prefix_lines, marker)
        exact_line(terminal_lines, marker)
    gates.append({"file": "prefix.log", "markers": prefix_markers})
    generated_markers = ["PSKERNEL_GENERATED_COMPLETE_CHECKER: PASS", "PSKERNEL_GENERATED_SMOKE: PASS"]
    for marker in generated_markers:
        exact_line(text(files["generated-smoke.log"]).splitlines(), marker)
        exact_line(terminal_lines, marker)
    gates.append({"file": "generated-smoke.log", "markers": generated_markers})
    invalid = one_matching(text(files["invalid-recursor.log"]).splitlines(),
                           r"PSC1_INVALID_RECURSOR_OCCURRENCE_JS: PASS [0-9]+ invalid/reducible/nonrecursive/erased/unsafe/nested/resource/publication controls")
    exact_line(terminal_lines, invalid)
    gates.append({"file": "invalid-recursor.log", "markers": [invalid]})
    measurements = {name: parse_measurement(files[name + ".memory"]) for name in ("header", "dag", "prefix")}
    for measurement in measurements.values():
        must(measurement["measurement"] in terminal_lines, "Actual timed measurement missing from terminal log")
    root_logs = {name: digest(raw) for name, raw in sorted(files.items())
                 if "/" not in name and name.endswith(".log")}
    receipt = parse_json(files["receipt.json"])
    expected_receipt = {
        "schema": "psc1-t05-header-route-receipt-v1", "status": "pass",
        "identity": provenance, "result": header_result, **measurements["header"],
        "logs": root_logs, "headerOnly": True, "fullAdmission": False,
        "performanceQualified": False,
    }
    must(exact(receipt, expected_receipt), "Runtime receipt is not exact actual identity/results/log hashes/timing")
    must(exact(one_record(terminal_lines, "PSC1_T05_HEADER_ROUTE: PASS "), receipt),
         "Terminal runtime receipt differs from original archived receipt")
    # Source checks are independently bound by their successful ordered Actions
    # steps and by every archived byte. Reject explicit compiler failures as well.
    compilation_logs = [
        "compiler-build.log", "structural-occurrence-check.log",
        "structural-annotations-check.log", "complete-lean-check.log", "complete-build.log",
    ] + (["canonical-ps-check.log"] if canonical else [])
    for name in compilation_logs:
        value = text(files[name])
        must(value.strip(), "Empty required compilation/check log: " + name)
        must(not re.search(r"uncaught exception:|PSC1_PROJECT_ELAB_FAILED|^error:|\.lean:\d+:\d+: error:",
                           value, re.M), "Compiler failure in " + name)
        must(value.rstrip() in terminal, "Archived compilation log differs from terminal output: " + name)
    inputs = {
        name: {"path": str(pathlib.Path(value)), **digest(pathlib.Path(value).read_bytes())}
        for name, value in {
            "artifactMetadata": args.artifact_json, "runMetadata": args.run_json,
            "jobsMetadata": args.jobs_json, "jobLog": args.job_log,
            "authenticatedGitBlobMap": args.git_blobs_json,
        }.items()
    }
    return {
        "schema": "psc1-t05-header-route-independent-artifact-review-v1",
        "status": "pass", "repository": REPOSITORY, **identity,
        "sourceTreeSha": git_map["treeSha"], "artifactId": args.artifact_id,
        "jobId": args.job_id, "runUrl": run["html_url"], "jobUrl": job["html_url"],
        "routeOnly": True, "wholeRunStatus": run["status"],
        "wholeRunConclusion": run["conclusion"],
        "localProjectExecutionPerformed": False,
        "verifier": {"path": str(pathlib.Path(__file__)), **digest(pathlib.Path(__file__).read_bytes())},
        "metadataInputs": inputs, "artifact": artifact, "archive": archive_digest,
        "fileCount": len(files), "files": [
            {"path": name, **digest(raw)} for name, raw in sorted(files.items())
        ],
        "allZipMembersReadAndCrcChecked": True,
        "copiedInputs": source_records, "copiedInputCount": len(source_records),
        "allCopiedInputsMatchAuthenticatedGitBlobs": True,
        "frozenV1References": FROZEN,
        "leanClosure": {
            "manifest": manifest, "moduleCount": len(lean), "importEdges": edges,
            "archive": digest(files["lean-source.tar.gz"]),
            "allIndividualSourcesEqualTarMembers": True,
            "allSourceBlobsMatchAuthenticatedGitTree": True,
            "independentlyDerivedImportClosureMatches": True, "files": lean_records,
        },
        "canonicalClosure": canonical_review,
        "boundedCompilation": {"outputs": bounded_quartet, "generatedBodies": bounded_bodies},
        "completeCompilation": {"outputs": production_quartet, "generatedBodies": complete_bodies,
                                "requiredHeaderExports": public_exports,
                                "executedKernelEqualsProductionJavaScript": True},
        "producerProvenance": provenance,
        "retainedRuntimeGates": gates, "headerMatrix": header_result,
        "measurements": measurements, "originalReceipt": receipt,
        "originalReceiptDigest": digest(files["receipt.json"]),
        "allRootLevelLogDigestsRecomputed": root_logs,
        "terminalLog": digest(terminal_raw), "orderedActionsGates": gate_order,
        "runtimeConstraints": {
            "leanVersion": "4.35.0", "leanCommit": LEAN_COMMIT, "typescript": "7.0.2",
            "node": node_version, "fuel": 4096, "oldSpaceMiB": 2048,
            "oldSpaceIsHardRssLimit": False, "emptyPATH": True,
            "runtimeStepCapMinutes": 25, "producerJobCapMinutes": 75,
        },
        "scope": {
            "headerOnly": True, "fullAdmission": False, "publicFallbackUsed": False,
            "performanceQualified": False, "otherRouteInferred": False,
            "replayArenaModelBridgeProved": False,
        },
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--zip", required=True, help="Downloaded original route ZIP")
    parser.add_argument("--artifact-json", required=True, help="Raw API artifact object or artifacts list")
    parser.add_argument("--artifact-id", required=True, type=int)
    parser.add_argument("--run-json", required=True, help="Raw API workflow run object")
    parser.add_argument("--jobs-json", required=True, help="Raw API jobs object including native-header")
    parser.add_argument("--job-id", required=True, type=int)
    parser.add_argument("--job-log", required=True, help="Decoded complete terminal route job log")
    parser.add_argument("--git-blobs-json", required=True, help="Authenticated source/tree/gitBlobs mapping")
    parser.add_argument("--source-sha", required=True)
    parser.add_argument("--run-id", required=True, type=int)
    parser.add_argument("--attempt", required=True, type=int)
    parser.add_argument("--route", required=True, choices=("generated", "canonical"))
    parser.add_argument("--expected-source-count", type=int, default=146)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    report = review(args)
    output = pathlib.Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({
        "status": report["status"], "sourceSha": args.source_sha,
        "runId": args.run_id, "attempt": args.attempt, "route": args.route,
        "artifactId": args.artifact_id, "files": report["fileCount"],
        "copiedSources": report["copiedInputCount"],
        "leanClosure": report["leanClosure"]["moduleCount"],
        "headerAssertions": report["headerMatrix"]["assertions"],
        "output": str(output), "outputDigest": digest(output.read_bytes()),
    }, sort_keys=True))


if __name__ == "__main__":
    try:
        main()
    except (ReviewError, KeyError, ValueError, OSError, zipfile.BadZipFile, tarfile.TarError) as error:
        print("PSC1_T05_ROUTE_STATIC_REVIEW: FAIL " + str(error), file=sys.stderr)
        sys.exit(1)
