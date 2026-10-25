#!/usr/bin/env python3
"""Same-runner, fresh-process A-B-B-A observation; not kernel qualification."""
from __future__ import annotations
import argparse
import hashlib
import importlib.util
import json
import os
import pathlib
import re
import shutil
import statistics
import subprocess
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location(
    "transform_delay_compare", HERE / "pskernel-arena435-compare.py")
COMPARE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(COMPARE)
ORACLE = COMPARE.ORACLE
CASES = (
    ("good", "perf/repeated-subproblem.ndjson",
     "16ad35530b3f5590d5160ad6ee5fb421b8f9629e49e340fc73016ef965785533"),
    ("good", "perf/church-numerals.ndjson",
     "85526c244d94e9710a6be432164c054c742d8f7c1d3ca0d8580d0874f7815a47"),
    ("good", "init-prelude.ndjson",
     "db35e7676c622a5da904e9cff32c761a05e389672dc5a8a5a344e1f31d378d08"),
    ("bad", "bugs/proj-of-stuck-prop.ndjson",
     "9930c5f92d12cca0ed0d4e132a2b3c7520fb2b1520de66c3bc24fdeb5895402f"),
)
SEMANTIC_KEYS = (
    "format", "sourceSha256", "verdict", "stage", "reason", "fuel",
    "coreInvoked", "records", "metadataCounts", "metadataCoverage",
    "sourceMutualBlockMetadata", "sourceMutualBlockMetadataRole",
    "exportedDeclarations", "admissionCommands", "arenaNodes",
    "containsUnsafeOrPartial", "metadataValidated",
    "officialReplaySkipsUnsafeOrPartial",
)
REQUIRED_FILES = {
    "kernel.js", "kernel.ts", "kernel.d.ts", "kernel.js.map",
    "bootstrap-manifest.json", "raw-abi.log", "dag-smoke.log",
    "paged-smoke.log", "arena-controls.log", "native-receipt.json",
    "native-source-audit.json", "native-proofs.log", "compiler-receipt.json",
    "authentic-source.log", "canonical-source.log", "generated-build.log", "producer-tools.json",
    "bootstrap-shared.mjs", "research-kernel.mjs", "research-build.log",
}
def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def authenticate(root, variant, source, baseline):
    receipt = json.loads((root / "receipt.json").read_text())
    if (receipt.get("schema") != "psc1-transform-delay-producer-v1"
        or receipt.get("variant") != variant
        or receipt.get("sourceSha") != source
        or receipt.get("baselineSha") != baseline
        or receipt.get("kernelSourceSha") != (baseline if variant == "baseline" else source)
        or receipt.get("compilerSourceSha") != source
        or receipt.get("runId") != os.environ["GITHUB_RUN_ID"]
        or receipt.get("runAttempt") != os.environ["GITHUB_RUN_ATTEMPT"]
        or receipt.get("leanGitHash") != "eb6cafb7290e8bd5f2937522d8d804f58f02bafc"):
        raise ValueError("producer identity mismatch: " + variant)
    files = receipt.get("files", {})
    if set(files) != REQUIRED_FILES:
        raise ValueError("producer file inventory mismatch: " + variant)
    for name, expected in files.items():
        if digest(root / name) != expected:
            raise ValueError("producer file digest mismatch: " + variant + "/" + name)
    native = json.loads((root / "native-receipt.json").read_text())
    if (native.get("schema") != "psc1-transform-delay-native-v1"
        or native.get("sourceSha") != source or native.get("baselineSha") != baseline
        or native.get("runId") != os.environ["GITHUB_RUN_ID"]
        or native.get("runAttempt") != os.environ["GITHUB_RUN_ATTEMPT"]
        or native.get("proofs") != 10):
        raise ValueError("native proof/compiler receipt mismatch")
    if (digest(root / "native-proofs.log") != native.get("proofLogSha256")
        or digest(root / "native-source-audit.json") != native.get("sourceAuditSha256")):
        raise ValueError("native log/source receipt mismatch")
    compiler = json.loads((root / "compiler-receipt.json").read_text())
    if (compiler.get("schema") != "psc1-transform-delay-compiler-v1"
        or compiler.get("sourceSha") != source or compiler.get("baselineSha") != baseline
        or compiler.get("runId") != os.environ["GITHUB_RUN_ID"]
        or compiler.get("runAttempt") != os.environ["GITHUB_RUN_ATTEMPT"]
        or compiler.get("leanGitHash") != receipt.get("leanGitHash")
        or compiler.get("nativeReceiptSha256") != digest(root / "native-receipt.json")
        or compiler.get("compilerSha256") != receipt.get("compilerSha256")):
        raise ValueError("shared compiler receipt mismatch")
    producer_tools = json.loads((root / "producer-tools.json").read_text())
    bootstrap = producer_tools.get("bootstrap", {})
    if (bootstrap.get("sourceGitBlob") != "734db05bccdd777f3cb1fa95aa9904e36caa9926"
        or bootstrap.get("sourceSha256") != digest(HERE / "bootstrap-project.mjs")
        or bootstrap.get("replacementCount") != 4
        or bootstrap.get("adapterSha256") != digest(root / "bootstrap-shared.mjs")
        or bootstrap.get("translatorSha256") != compiler.get("compilerSha256")
        or bootstrap.get("translatorSourceSha") != source):
        raise ValueError("shared bootstrap translator receipt mismatch")
    research = producer_tools.get("research", {})
    research_entry = "packages/pskernel-core/src/Ps/KernelCore/Research/ExprV2ResearchAll.lean"
    raw_entry = (HERE.parent / research_entry).read_bytes()
    entry_blob = hashlib.sha1(b"blob " + str(len(raw_entry)).encode() + b"\0" + raw_entry).hexdigest()
    if (research.get("entry") != research_entry
        or entry_blob != "3349d6d3b453297123095354bf25dcdcc4efa625"
        or research.get("entryGitBlob") != entry_blob
        or research.get("entrySha256") != hashlib.sha256(raw_entry).hexdigest()
        or research.get("sourceSha") != receipt.get("kernelSourceSha")
        or research.get("compilerSourceSha") != source
        or research.get("compilerSha256") != compiler.get("compilerSha256")
        or research.get("kernelFile") != "research-kernel.mjs"
        or research.get("kernelSha256") != digest(root / "research-kernel.mjs")
        or research.get("buildLogSha256") != digest(root / "research-build.log")
        or research.get("smokeLogSha256") != digest(root / "paged-smoke.log")
        or research.get("harnessSha256") != compiler["files"]["runtime/pskernel-expr-v2-generated-smoke.mjs"]
        or research.get("validatesSelfHost") is not False):
        raise ValueError("storage research entry/kernel/control receipt mismatch")
    if (root / "dag-smoke.log").read_text().splitlines().count("PSC1_V2_DAG_JS: PASS") != 1:
        raise ValueError("complete SelfHost DAG smoke did not finish")
    markers = {
        "raw-abi.log": "PSC1_TRANSFORM_DELAY_RAW_JS: PASS assertions=23 exports=3 stagedArrows=11",
        "dag-smoke.log": "PSC1_V2_TRANSFORM_JS: PASS",
        "paged-smoke.log": "PSC1_EXPR_V2_JS_SMOKE: PASS",
        "arena-controls.log": "PSC1_ARENA_REPLAY_CONTROLS: PASS count=138",
    }
    for name, marker in markers.items():
        if (root / name).read_text().splitlines().count(marker) != 1:
            raise ValueError("missing/duplicate retained runtime marker: " + name)
    return receipt

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline-root", type=pathlib.Path, required=True)
    parser.add_argument("--candidate-root", type=pathlib.Path, required=True)
    parser.add_argument("--baseline-sha", required=True)
    parser.add_argument("--archive", type=pathlib.Path, required=True)
    parser.add_argument("--official-project", type=pathlib.Path, required=True)
    parser.add_argument("--out", type=pathlib.Path, required=True)
    args = parser.parse_args()
    source, baseline = os.environ.get("GITHUB_SHA", ""), args.baseline_sha
    if any(re.fullmatch(r"[0-9a-f]{40}", s) is None for s in (source, baseline)):
        parser.error("exact source and baseline SHAs are required")
    node_path = shutil.which("node")
    if node_path is None:
        parser.error("Node.js is required")
    node = pathlib.Path(node_path).resolve(strict=True)
    roots = {"baseline": args.baseline_root.resolve(strict=True),
             "candidate": args.candidate_root.resolve(strict=True)}
    receipts = {v: authenticate(p, v, source, baseline) for v, p in roots.items()}
    if receipts["baseline"]["compilerSha256"] != receipts["candidate"]["compilerSha256"]:
        raise ValueError("variants did not use the same compiler binary")
    out, project = args.out.resolve(), args.official_project.resolve(strict=True)
    out.mkdir(parents=True, exist_ok=True)
    if digest(args.archive) != ORACLE.ARCHIVE_SHA256:
        raise ValueError("original Arena archive digest mismatch")
    corpus = {(label, name): raw for label, name, raw in ORACLE.read_archive(args.archive)}
    controls = []
    for accepted in (True, False):
        expected = "accepted" if accepted else "rejected"
        path = out / ("official-control-" + expected + ".ndjson")
        path.write_bytes(ORACLE.control_bytes(accepted))
        result = ORACLE.official(project, path, 300, out / (expected + ".official.txt"))
        if result.get("verdict") != expected:
            raise ValueError("official reference control failed")
        controls.append({"expected": expected, **result})
    prepared = []
    for index, (label, name, expected_body) in enumerate(CASES):
        adapted, adaptation = ORACLE.adapt_header(corpus[(label, name)])
        if (adaptation["original_body_sha256"] != expected_body
            or adaptation["adapted_body_sha256"] != expected_body):
            raise ValueError("authentic body changed: " + name)
        path = out / ("input-" + str(index) + ".ndjson")
        path.write_bytes(adapted)
        reference = ORACLE.official(project, path, 300,
            out / ("case-" + str(index) + ".official.txt"))
        if reference.get("verdict") != ("accepted" if label == "good" else "rejected"):
            raise ValueError("official reference changed: " + name)
        prepared.append((path, adaptation, reference))
    records, errors = [], []
    with tempfile.TemporaryDirectory(prefix="psc1-transform-delay-abba-") as directory:
        detached = pathlib.Path(directory)
        runtimes = {}
        for variant, root in roots.items():
            folder = detached / variant
            folder.mkdir()
            shutil.copyfile(root / "kernel.js", folder / "kernel.mjs")
            shutil.copyfile(HERE / "pskernel-arena-replay.mjs", folder / "replay.mjs")
            runtimes[variant] = (folder / "kernel.mjs", folder / "replay.mjs")
        for round_index, variant in enumerate(("baseline", "candidate", "candidate", "baseline")):
            kernel, replay = runtimes[variant]
            for index, (label, name, body_hash) in enumerate(CASES):
                case, adaptation, reference = prepared[index]
                logs = out / ("round-" + str(round_index)) / ("case-" + str(index))
                logs.mkdir(parents=True)
                observed = COMPARE.process_case(node, replay, kernel, case, 60, logs, index)
                classification = COMPARE.classify(reference, observed)
                if observed.get("verdict") == "driver_error" or classification in ("false_accept", "false_reject"):
                    errors.append(variant + ":" + name + ":" + classification)
                if name == "perf/church-numerals.ndjson":
                    if variant == "baseline":
                        if (observed.get("verdict") != "resource_exhausted"
                            or observed.get("stage") != "kernel-admission"
                            or "kernel reduction budget exhausted" not in observed.get("reason", "")):
                            errors.append("frozen Church baseline error changed")
                    elif (observed.get("verdict") != "accepted" or observed.get("metadataValidated") is not True
                        or observed.get("officialReplaySkipsUnsafeOrPartial") is not False):
                        errors.append("candidate did not restore original official Church acceptance")
                if name in ("perf/repeated-subproblem.ndjson", "bugs/proj-of-stuck-prop.ndjson"):
                    if observed.get("verdict") != reference.get("verdict"):
                        errors.append("retained complete control regressed: " + variant + ":" + name)
                record = {"round": round_index, "variant": variant, "index": index,
                          "label": label, "name": name, "bodySha256": body_hash,
                          "adaptation": adaptation, "reference": reference,
                          "observed": observed, "classification": classification}
                records.append(record)
                (logs / "record.json").write_text(json.dumps(record, indent=2) + "\n")
                print("PSC1_TRANSFORM_DELAY_OBSERVATION " + json.dumps({
                    "round": round_index, "variant": variant, "name": name,
                    "verdict": observed["verdict"],
                    "elapsedSeconds": observed.get("elapsed_seconds"),
                    "peakRssKiB": observed.get("peak_rss_kib"),
                    "lastProgress": observed.get("last_progress")}), flush=True)
    summaries = []
    for _, name, _ in CASES:
        groups = {v: [r["observed"] for r in records if r["name"] == name and r["variant"] == v]
                  for v in roots}
        complete = {v: [o for o in xs if o.get("verdict") != "timeout"
                         and o.get("stage") not in ("host-heap", "host-stack-or-allocation")]
                    for v, xs in groups.items()}
        for left in complete["baseline"]:
            for right in complete["candidate"]:
                keys = (("format","sourceSha256","fuel","coreInvoked","records","admissionCommands","arenaNodes",
                         "containsUnsafeOrPartial","exportedDeclarations")
                        if name == "perf/church-numerals.ndjson" else SEMANTIC_KEYS)
                if {k: left.get(k) for k in keys} != {k: right.get(k) for k in keys}:
                    errors.append("complete result mismatch: " + name)
        if len(complete["baseline"]) == 2 and len(complete["candidate"]) < 2:
            errors.append("new candidate host resource failure: " + name)
        if (any(o.get("stage") == "host-heap" for o in groups["candidate"])
            and not any(o.get("stage") == "host-heap" for o in groups["baseline"])):
            errors.append("new candidate heap exhaustion: " + name)
        bounded = all(len(xs) == 2 for xs in complete.values())
        elapsed = {v: statistics.median(o["elapsed_seconds"] for o in xs)
                   for v, xs in groups.items()}
        rss = {v: [o["peak_rss_kib"] for o in xs if "peak_rss_kib" in o]
               for v, xs in groups.items()}
        comparable = bounded and name != "perf/church-numerals.ndjson"
        ratio = elapsed["candidate"] / elapsed["baseline"] if comparable else None
        rss_ratio = (statistics.median(rss["candidate"]) / statistics.median(rss["baseline"])
                     if comparable and all(len(xs) == 2 for xs in rss.values()) else None)
        summaries.append({"name": name,
            "verdicts": {v: [o["verdict"] for o in xs] for v, xs in groups.items()},
            "elapsedSeconds": {v: [o["elapsed_seconds"] for o in xs] for v, xs in groups.items()},
            "peakRssKiB": rss, "uncensoredPair": bounded, "performanceComparable": comparable,
            "intendedChurchRecovery": name == "perf/church-numerals.ndjson",
            "candidateMedianTimeRatio": ratio, "candidateMedianRssRatio": rss_ratio,
            "timeRegressionOver10Percent": ratio is not None and ratio > 1.10,
            "rssRegressionOver15Percent": rss_ratio is not None and rss_ratio > 1.15})
    report = {"schema": "psc1-unary-spine-abba-v1", "sourceSha": source,
              "baselineSha": baseline, "runId": os.environ["GITHUB_RUN_ID"],
              "runAttempt": os.environ["GITHUB_RUN_ATTEMPT"], "producerReceipts": receipts,
              "archiveSha256": ORACLE.ARCHIVE_SHA256, "targetLean": ORACLE.TARGET,
              "driverSha256": digest(pathlib.Path(__file__)),
              "comparisonDriverSha256": digest(HERE / "pskernel-arena435-compare.py"),
              "oracleSha256": digest(HERE / "pskernel-arena435-oracle.py"),
              "replaySha256": digest(HERE / "pskernel-arena-replay.mjs"),
              "sequence": ["A", "B", "B", "A"], "freshProcessEachCase": True,
              "kernelFuel": 4096, "hostWallSeconds": 60,
              "nodeOldSpaceMiB": 2048, "runtimePathEmpty": True,
              "nodeVersion": subprocess.check_output([str(node), "--version"], text=True).strip(),
              "nodeSha256": digest(node),
              "controls": controls, "records": records, "summaries": summaries,
              "diagnosticsComplete": len(records) == 16 and all(
                  r["observed"].get("verdict") != "driver_error" for r in records),
              "errors": sorted(set(errors)),
              "fullArenaQualification": False, "performanceQualified": False}
    (out / "report.json").write_text(json.dumps(report, indent=2) + "\n")
    manifest = [{"path": str(p.relative_to(out)), "sha256": digest(p)}
                for p in sorted(out.rglob("*")) if p.is_file() and p.name != "sha256.json"]
    (out / "sha256.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print("PSC1_TRANSFORM_DELAY_ABBA: " + ("PASS" if not errors else "FAIL")
          + " observations=16 cases=4 kernelFuel=4096 fullArena=false performanceQualified=false")
    return 1 if errors else 0
if __name__ == "__main__":
    raise SystemExit(main())
