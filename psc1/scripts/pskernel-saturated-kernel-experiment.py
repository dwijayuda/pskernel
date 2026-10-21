#!/usr/bin/env python3
"""Opt-in emitter experiment; kernel source, checked workers and verdicts stay fixed."""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import io
import json
import os
import pathlib
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import time
import zipfile

KERNEL_SOURCE = "384f3395036ba7022e6eea9d3ff77f37aacd62ca"
FOCUSED_SOURCE = "282317394863dca222f9bebe79a64e05b30d0cd4"
HELPER_SOURCE = "7ae480eedcc7c6c67e63ebdb7a6f4eedcf7ddaa4"
LEAN_COMMIT = "eb6cafb7290e8bd5f2937522d8d804f58f02bafc"
REPOSITORY = "dwijayuda/pskernel"
WORKFLOW = ".github/workflows/psc1-ts-saturation-kernel.yml"
EXPERIMENTAL_MODULE = "psc1/packages/backend-ts/src/Ps/BackendTs/Saturate.lean"
REQUIRED_WORKERS = (
    "psKernelExprV2WhnfCacheIndexBucketWorker_$psc0SH_0",
    "psKernelExprV2WhnfCacheIndexSetWorker_$psc0SH_0",
)
FOCUSED_FILES = (
    EXPERIMENTAL_MODULE, "psc1/scripts/SaturatedSourceCompile.lean",
    "psc1/test/PsBackendTsSaturateFixture.lean",
    "psc1/test/PsBackendTsSaturateRegression.lean",
    "psc1/test/PsBackendTsSaturateProofs.lean",
    "psc1/scripts/backend-ts-saturate-smoke.mjs", "psc1/lakefile.lean",
)
DEPLOYMENT_FILES = (
    "kernel.ts", "kernel.js", "kernel.d.ts", "kernel.js.map",
    "scripts/pskernel-canonical-provider.mjs",
    "npm-runtime/canonical-admissions-wire.mjs", "package.json", "README.md",
)
LABELS = {"baseline": "original", "candidate": "optimized"}
EXTRA_SCRIPTS = (
    "pskernel-generated-smoke.mjs", "pskernel-expr-v2-dag-bench.mjs",
    "pskernel-expr-v2-admission-bench.mjs", "pskernel-whole-js-bench.mjs",
    "pskernel-js-memory-probe.mjs", "pskernel-generated-profile.mjs",
    "pskernel-canonical-provider.mjs", "pskernel-arena-replay.mjs",
    "pskernel-arena-replay-controls.mjs",
)
GATE_WORKFLOW = ".github/workflows/psc1-pskernel-expr-v2-integration.yml"
FROZEN_MISC = (
    GATE_WORKFLOW,
    "psc1/lean-toolchain", "psc1/kernel-lakefile.lean",
    "psc1/check-psc1-source.mjs", "psc1/scripts/source-profile-opaque.mjs",
    "psc1/scripts/bootstrap-project.mjs", "psc1/scripts/bootstrap-manifest.mjs",
    "psc1/scripts/workspace-layout.mjs", "psc1/scripts/install-lean435-ci.sh",
    "psc1/scripts/pskernel-arena435-oracle.py",
    "psc1/scripts/pskernel-arena435-compare.py",
    "psc1/packages/pskernel-core/PROVIDER.md",
)

def require(condition, message):
    if condition is not True:
        raise ValueError(message)

def digest(data):
    return hashlib.sha256(data).hexdigest()

def read_json(path):
    result = json.loads(path.read_text(encoding="utf-8"))
    require(isinstance(result, dict), "expected JSON object: " + str(path))
    return result

def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_text(json.dumps(value, ensure_ascii=False, indent=2, allow_nan=False) + "\n",
                         encoding="utf-8")
    temporary.replace(path)

def load_module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    require(spec is not None and spec.loader is not None, "cannot load exact helper: " + str(path))
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result

def git(repo, *arguments):
    return subprocess.check_output(["git", "-C", str(repo), *arguments])

def tracked(repo, revision):
    result = {}
    for record in git(repo, "ls-tree", "-r", "-z", revision, "--", "psc1", GATE_WORKFLOW).split(b"\0"):
        if not record:
            continue
        metadata, name = record.split(b"\t", 1)
        mode, kind, oid = metadata.decode().split()
        require(kind == "blob" and mode in ("100644", "100755"), "nonregular source object: " + name.decode())
        result[name.decode()] = oid
    return result

def protected(path):
    if path.startswith("psc1/packages/pskernel-core/"):
        return path.startswith("psc1/packages/pskernel-core/src/")
    return (path.startswith("psc1/packages/") or path.startswith("psc1/host/")
            or path.startswith("psc1/host-tools/") or path.startswith("psc1/stdlib/")
            or path.startswith("psc1/npm-runtime/"))

def compiler_sha(repo):
    value = git(repo, "rev-parse", "HEAD").decode().strip()
    require(value == os.environ.get("GITHUB_SHA") and re.fullmatch(r"[0-9a-f]{40}", value) is not None,
            "checkout and actual workflow source differ")
    return value

def source_identity(repo):
    current = compiler_sha(repo)
    old, now, focus = (tracked(repo, ref) for ref in (KERNEL_SOURCE, current, FOCUSED_SOURCE))
    old_protected = {p: oid for p, oid in old.items() if protected(p)}
    new_protected = {p: oid for p, oid in now.items() if protected(p)}
    require(EXPERIMENTAL_MODULE not in old_protected, "experimental module must remain additive")
    require(new_protected.pop(EXPERIMENTAL_MODULE, None) == focus[EXPERIMENTAL_MODULE],
            "experimental module differs from focused qualification")
    require(old_protected == new_protected,
            "original tracked kernel/compiler/backend/elaborator/erasure/runtime source changed")
    required = set(FROZEN_MISC)
    required.update("psc1/scripts/" + item["script"] for item in suite_definitions(repo))
    required.update("psc1/scripts/" + name for name in EXTRA_SCRIPTS)
    for path in required:
        require(path in old and now.get(path) == old[path], "retained harness/policy changed: " + path)
    for path in FOCUSED_FILES:
        require(now.get(path) == focus.get(path) and path in focus,
                "experimental source differs from qualified focused prototype: " + path)
    paths = sorted(set(old_protected) | required | set(FOCUSED_FILES))
    subprocess.run(["git", "-C", str(repo), "diff", "--quiet", "HEAD", "--", *paths], check=True)
    extra = git(repo, "ls-files", "--others", "--exclude-standard", "--",
                "psc1/packages", "psc1/host", "psc1/stdlib", "psc1/npm-runtime").strip()
    require(not bool(extra), "untracked source/runtime could change actual import resolution")
    records = [{"path": path, "gitBlob": now[path], "sha256": digest((repo / path).read_bytes())}
               for path in paths]
    return {"schema": "psc1-saturation-source-identity-v1", "compilerSourceSha": current,
            "kernelSourceSha": KERNEL_SOURCE, "focusedPrototypeSourceSha": FOCUSED_SOURCE,
            "allOriginalTrackedSourceIdentical": True,
            "additiveExperimentalModule": EXPERIMENTAL_MODULE,
            "defaultCompilerChanged": False, "kernelChanged": False,
            "protectedOriginalFileCount": len(old_protected), "files": records}

def suite_definitions(repo):
    # Read assertion DATA from the unchanged, source-pinned workflow. No shell
    # block or fetched source text is executed by this inventory parser.
    raw = (repo / GATE_WORKFLOW).read_bytes()
    require(raw == git(repo, "show", KERNEL_SOURCE + ":" + GATE_WORKFLOW),
            "retained gate inventory differs from qualified384 source")
    source = raw.decode("utf-8")
    require(source.count("\n  generated-dag-integration:") == 1, "generated job inventory missing")
    generated = source.split("\n  generated-dag-integration:", 1)[1]
    result = []
    for block in generated.split("\n      - name: ")[1:]:
        scripts = set(re.findall(r"scripts/(pskernel-[a-z0-9-]+\.mjs)", block))
        if len(scripts) != 1:
            continue
        script = next(iter(scripts))
        if not script.endswith("-smoke.mjs"):
            continue
        markers = [{"regex": flag in ("Eq", "q"), "exact": flag.endswith("x"), "text": text}
                   for flag, text in re.findall(r"grep -(Fq[x]?|Eq|q) '([^']+)'", block)]
        require(bool(markers), "retained script has no assertion markers: " + script)
        result.append({"script": script, "markers": markers, "gc": "--expose-gc" in block})
    expected = {
        "pskernel-expr-v2-" + name + "-smoke.mjs" for name in (
            "dag", "infer-only", "proof-irrelevance", "lazy-nat", "lazy-delta",
            "full-shape", "final-rules", "admission-guard", "quot", "recursor",
            "recursor-k", "string-projection", "whnf-cache", "owned-state")
    } | {"pskernel-provider-smoke.mjs", "pskernel-nat-runtime-smoke.mjs"}
    require(len(result) == 16 and {item["script"] for item in result} == expected
            and sum(len(item["markers"]) for item in result) == 82,
            "full retained generated suite inventory is incomplete")
    def exact(text):
        return {"regex": False, "exact": True, "text": text}
    return [{"script": "pskernel-generated-smoke.mjs",
             "markers": [exact("PSKERNEL_GENERATED_COMPLETE_CHECKER: PASS"),
                         exact("PSKERNEL_GENERATED_SMOKE: PASS")]}] + result + [
        {"script": "pskernel-arena-replay-controls.mjs",
         "markers": [exact("PSC1_ARENA_REPLAY_CONTROLS: PASS count=138")]}
    ]

def node_path():
    found = shutil.which("node")
    require(found is not None, "Node executable missing")
    node = pathlib.Path(found).resolve(strict=True)
    version = subprocess.check_output([str(node), "--version"], text=True).strip()
    require(re.fullmatch(r"v22\.[0-9]+\.[0-9]+", version) is not None, "Node22 required")
    return node, version

def empty_environment(work):
    scratch = work / "tmp"
    scratch.mkdir(exist_ok=True)
    return {"PATH": "", "LC_ALL": "C", "TZ": "UTC", "TMPDIR": str(scratch)}

def execute(command, work, logs, label, timeout):
    logs.mkdir(parents=True, exist_ok=True)
    stdout_path, stderr_path = (logs / (label + suffix) for suffix in (".stdout.log", ".stderr.log"))
    started = time.monotonic()
    timed_out = False
    with stdout_path.open("wb") as stdout, stderr_path.open("wb") as stderr:
        child = subprocess.Popen(command, cwd=work, env=empty_environment(work),
                                 start_new_session=True, stdout=stdout, stderr=stderr)
        try:
            returncode = child.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            timed_out = True
            try:
                os.killpg(child.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            returncode = child.wait()
    receipt = {"label": label, "returncode": returncode, "hostTimedOut": timed_out,
               "wallSeconds": time.monotonic() - started, "hostDeadlineSeconds": timeout,
               "pathEmpty": True, "stdout": stdout_path.name, "stderr": stderr_path.name}
    write_json(logs / (label + ".process.json"), receipt)
    if timed_out or returncode != 0:
        for path in (stdout_path, stderr_path):
            print(path.name + "\n" + path.read_text(errors="replace")[-24000:], flush=True)
        raise ValueError("actual generated gate failed: " + label)
    return receipt, stdout_path.read_text(encoding="utf-8")

def markers_pass(output, markers):
    lines = output.splitlines()
    for marker in markers:
        if marker["regex"]:
            passed = re.search(marker["text"], output, re.M) is not None
        elif marker["exact"]:
            passed = marker["text"] in lines
        else:
            passed = marker["text"] in output
        require(passed, "missing retained assertion marker: " + marker["text"])

def files_in(root):
    records = []
    for path in sorted(root.rglob("*")):
        require(not path.is_symlink(), "symlink in deployment/experiment output")
        if path.is_file() and path.relative_to(root).as_posix() not in ("manifest.json", "manifest.json.tmp"):
            data = path.read_bytes()
            records.append({"path": path.relative_to(root).as_posix(),
                            "bytes": len(data), "sha256": digest(data)})
    return records

ABI_SOURCE = r"""
import assert from "node:assert/strict";
import {pathToFileURL} from "node:url";
assert.equal(process.env.PATH, "");
const left=await import(pathToFileURL(process.argv[2]).href);
const right=await import(pathToFileURL(process.argv[3]).href);
const names=Object.keys(left).sort();
assert.deepEqual(Object.keys(right).sort(), names);
let functions=0, constructorFunctions=0;
for(const name of names){
  assert.equal(typeof right[name],typeof left[name],name);
  if(typeof left[name]==="function"){
    assert.equal(right[name].length,left[name].length,name);functions++;
  }else if(left[name]!==null&&typeof left[name]==="object"){
    assert.notEqual(right[name],null,name);
    assert.deepEqual(Object.keys(right[name]).sort(),Object.keys(left[name]).sort(),name);
    for(const field of Object.keys(left[name]))if(typeof left[name][field]==="function"){
      assert.equal(typeof right[name][field],"function",name+"."+field);
      assert.equal(right[name][field].length,left[name][field].length,name+"."+field);
      constructorFunctions++;
    }
  }
}
console.log("PSC1_SATURATION_KERNEL_ABI "+JSON.stringify({
 exports:names.length,functions,constructorFunctions,exportSetsIdentical:true,
 functionEntryAritiesIdentical:true,privateHelpersNotExported:true,pathEmpty:true
}));
"""

def check_map(bundle):
    source_map = read_json(bundle / "kernel.js.map")
    require(source_map.get("version") == 3 and source_map.get("file") == "kernel.js"
            and isinstance(source_map.get("sources"), list) and bool(source_map["sources"])
            and isinstance(source_map.get("mappings"), str) and bool(source_map["mappings"]),
            "compiler source map is missing or invalid")
    require(source_map.get("sourceRoot", "") in ("", "."), "source map escapes deployment")
    for index, name in enumerate(source_map["sources"]):
        require(isinstance(name, str) and name == "kernel.ts", "source map dependency is not deployed")
        contents = source_map.get("sourcesContent", [])
        if index < len(contents) and isinstance(contents[index], str):
            require(contents[index] == (bundle / "kernel.ts").read_text(),
                    "embedded map source differs from readable checked TypeScript")
    require(json.loads((bundle / "package.json").read_text()) == {"private": True, "type": "module"},
            "runtime package scope differs")

def deploy(source, output, mode):
    bundle = output / "bundles" / mode
    bundle.mkdir(parents=True, exist_ok=True)
    for name in ("kernel.ts", "kernel.js", "kernel.d.ts", "kernel.js.map"):
        value = (output / mode / name).read_bytes()
        require(bool(value), "missing compiler artifact: " + mode + "/" + name)
        (bundle / name).write_bytes(value)
    for origin, name in (
        ("scripts/pskernel-canonical-provider.mjs", "scripts/pskernel-canonical-provider.mjs"),
        ("npm-runtime/canonical-admissions-wire.mjs", "npm-runtime/canonical-admissions-wire.mjs"),
        ("packages/pskernel-core/PROVIDER.md", "README.md"),
    ):
        target = bundle / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes((source / origin).read_bytes())
    (bundle / "package.json").write_text('{"private":true,"type":"module"}\n')
    require({p.relative_to(bundle).as_posix() for p in bundle.rglob("*") if p.is_file()}
            == set(DEPLOYMENT_FILES), "deployment contains missing or extra runtime dependencies")
    check_map(bundle)
    return bundle

def qualifying_receipt(output, route):
    receipt = read_json(output / "optimized/kernel.ts.receipt.json")
    require(receipt.get("schema") == "psc1-saturated-checked-backend-v1"
            and receipt.get("sourceKind") == route
            and receipt.get("originalChecked") is True
            and receipt.get("candidateChecked") is True
            and receipt.get("candidateTargetChecked") is True
            and receipt.get("declarationsIdentical") is True
            and receipt.get("typescriptVersion") == "7.0.2"
            and type(receipt.get("declarations")) is int and receipt["declarations"] > 0
            and type(receipt.get("helpers")) is int and receipt["helpers"] >= 2
            and type(receipt.get("rewrittenCalls")) is int and receipt["rewrittenCalls"] > 0,
            "complete kernel checked-emission receipt missing or declined")
    expected_input = ("packages/pskernel-core/src/Ps/KernelCore/SelfHost.lean" if route == "lean"
                      else "dist/saturation-kernel/canonical/packages/pskernel-core/src/Ps/KernelCore/SelfHost.ps")
    require(receipt.get("input") == expected_input, "emitter did not compile the complete canonical kernel entry")
    workers = receipt.get("workers", [])
    require(len(workers) == receipt["helpers"]
            and len({row.get("name") for row in workers}) == len(workers),
            "selected worker identity enumeration incomplete")
    for name in REQUIRED_WORKERS:
        rows = [row for row in workers if row.get("name") == name]
        require(len(rows) == 1 and rows[0].get("stages") == 2
                and type(rows[0].get("rewrittenCalls")) is int and rows[0]["rewrittenCalls"] > 0,
                "actual two-stage recursive radix worker not specialized: " + name)
    return receipt

def qualify(repo, output, route):
    source = repo / "psc1"
    identity = source_identity(repo)
    require(read_json(output / "identity.json") == identity, "source changed during actual compilation")
    receipt = qualifying_receipt(output, route)
    node, version = node_path()
    bundles = {mode: deploy(source, output, mode) for mode in ("original", "optimized")}
    require((bundles["original"] / "kernel.d.ts").read_bytes()
            == (bundles["optimized"] / "kernel.d.ts").read_bytes(), "public declaration bytes changed")
    suites = suite_definitions(repo)
    report = {"schema": "psc1-saturation-kernel-functional-v1",
              "compilerSourceSha": identity["compilerSourceSha"], "kernelSourceSha": KERNEL_SOURCE,
              "sourceRoute": route, "node": version, "typescript": "7.0.2",
              "kernelFuel": 4096, "complete": False, "gates": [], "emission": receipt,
              "runtimePathEmpty": True, "wholeKernelSourceUnchanged": True,
              "defaultCompilerChanged": False, "all193ConformanceEstablished": False,
              "globalCompilerPreservationProven": False, "hardRssLimitClaim": False}
    write_json(output / "functional.json", report)
    with tempfile.TemporaryDirectory(prefix="psc1-saturation-kernel-detached-") as temporary:
        work = pathlib.Path(temporary)
        detached = {}
        script_names = {item["script"] for item in suites} | set(EXTRA_SCRIPTS)
        for mode, bundle in bundles.items():
            target = work / mode
            shutil.copytree(bundle, target)
            for name in script_names:
                destination = target / "scripts" / name
                destination.parent.mkdir(exist_ok=True)
                destination.write_bytes((source / "scripts" / name).read_bytes())
            # Unchanged benchmark drivers report this pinned configuration file.
            # It is metadata only; no Lean executable or source is copied.
            (target / "lean-toolchain").write_bytes((source / "lean-toolchain").read_bytes())
            detached[mode] = target
        abi_script = work / "abi.mjs"
        abi_script.write_text(ABI_SOURCE)
        process, text = execute([str(node), str(abi_script),
                                 str(detached["original"] / "kernel.js"),
                                 str(detached["optimized"] / "kernel.js")],
                                work, output / "logs", "export-abi", 180)
        lines = [line for line in text.splitlines() if line.startswith("PSC1_SATURATION_KERNEL_ABI ")]
        require(len(lines) == 1, "missing complete public ABI receipt")
        report["abi"] = json.loads(lines[0].split(" ", 1)[1])
        require(report["abi"].get("exportSetsIdentical") is True
                and report["abi"].get("functionEntryAritiesIdentical") is True
                and report["abi"].get("privateHelpersNotExported") is True
                and report["abi"].get("pathEmpty") is True, "public ABI gate did not complete")
        report["gates"].append({"mode": "both", "kind": "abi", **process})
        for mode, target in detached.items():
            logs = output / "logs" / mode
            kernel = str(target / "kernel.js")
            for item in suites:
                name = item["script"]
                arguments = ["js", kernel] if name == "pskernel-provider-smoke.mjs" else [kernel]
                process, text = execute(
                    [str(node), *(["--expose-gc"] if item.get("gc") else []),
                     str(target / "scripts" / name), *arguments],
                    target, logs, name.removesuffix(".mjs"), 900)
                markers_pass(text, item["markers"])
                if name == "pskernel-arena-replay-controls.mjs":
                    require(sum(line.startswith("PSC1_ARENA_CONTROL_PASS ")
                                for line in text.splitlines()) == 138, "all138 replay controls required")
                report["gates"].append({"mode": mode, "kind": "retained-smoke",
                                         "script": name, "markers": len(item["markers"]), **process})
                write_json(output / "functional.json", report)
                print("PSC1_SATURATION_KERNEL_GATE " + json.dumps(
                    {"route": route, "emitterMode": mode, "script": name, "status": "PASS"}), flush=True)
            strict = (
                ("pskernel-expr-v2-dag-bench.mjs", [], "PSC1_V2_DAG_BENCH: PASS", 900, True),
                ("pskernel-expr-v2-admission-bench.mjs", [], "PSC1_DAG_ADMISSION_BENCH: PASS", 720, True),
                ("pskernel-whole-js-bench.mjs", [mode], "PSC1_JS_WHOLE_SUMMARY", 900, False),
                ("pskernel-js-memory-probe.mjs", [mode, "warm_infer"], "PSC1_JS_WHOLE_SUMMARY", 900, True),
            )
            for name, arguments, marker, deadline, gc in strict:
                process, text = execute(
                    [str(node), *(["--expose-gc"] if gc else []),
                     str(target / "scripts" / name), kernel, *arguments],
                    target, logs, name.removesuffix(".mjs"), deadline)
                require(marker in text, "missing complete-workload marker: " + marker)
                if name == "pskernel-expr-v2-admission-bench.mjs":
                    require(sum(line.startswith("PSC1_ADMISSION_SAMPLE ")
                                for line in text.splitlines()) == 24, "all24 unchanged admission samples required")
                report["gates"].append({"mode": mode, "kind": "retained-complete-workload",
                                         "script": name, **process})
                write_json(output / "functional.json", report)
                print("PSC1_SATURATION_KERNEL_GATE " + json.dumps(
                    {"route": route, "emitterMode": mode, "script": name, "status": "PASS"}), flush=True)
            for shape, depth, operation in (("fn-unique", 128, "whnf"),
                                             ("fn-collision", 128, "whnf"), ("zeta", 24, "check")):
                for variant in ("legacy", "dag"):
                    label = "profile-" + variant + "-" + shape + "-" + str(depth)
                    process, text = execute(
                        [str(node), "--expose-gc", str(target / "scripts/pskernel-expr-v2-dag-bench.mjs"),
                         kernel, "profile", variant, shape, str(depth), "1", operation,
                         str(output / "profiles" / mode)], target, logs, label, 180)
                    require(text.splitlines().count("PSC1_V2_DAG_PROFILE: PASS") == 1,
                            "actual strict profile failed: " + label)
                    report["gates"].append({"mode": mode, "kind": "retained-profile", **process})
                    write_json(output / "functional.json", report)
    require(len(report["gates"]) == 57, "missing one of the57 whole-kernel gates")
    report["complete"] = True
    report["scope"] = ("Original and opt-in complete384 kernel;18 unchanged smoke/control scripts, "
                       "4 complete-workload gates and6 profiles per emitter; no compiler global theorem.")
    write_json(output / "functional.json", report)
    manifest = {
        "schema": "psc1-saturation-kernel-artifact-v1", "repository": REPOSITORY,
        "compilerSourceSha": identity["compilerSourceSha"], "kernelSourceSha": KERNEL_SOURCE,
        "focusedPrototypeSourceSha": FOCUSED_SOURCE, "sourceRoute": route,
        "runId": int(os.environ["GITHUB_RUN_ID"]), "runAttempt": int(os.environ["GITHUB_RUN_ATTEMPT"]),
        "lean": "4.35.0", "leanCommit": LEAN_COMMIT, "typescript": "7.0.2", "node": version,
        "kernelFuel": 4096, "functionalComplete": True, "kernelChanged": False,
        "defaultCompilerChanged": False, "globalCompilerPreservationProven": False,
        "fullV2ReplacementEstablished": False, "all193ConformanceEstablished": False,
        "sourceIdentitySha256": digest((output / "identity.json").read_bytes()),
        "functionalReceiptSha256": digest((output / "functional.json").read_bytes()),
        "emission": receipt, "files": files_in(output),
    }
    write_json(output / "manifest.json", manifest)
    print("PSC1_SATURATION_KERNEL_FUNCTIONAL " + json.dumps(
        {"route": route, "gates": len(report["gates"]), "complete": True,
         "compilerSourceSha": identity["compilerSourceSha"], "kernelSourceSha": KERNEL_SOURCE,
         "manifestSha256": digest((output / "manifest.json").read_bytes()),
         "emitterModules": {mode: digest((bundle / "kernel.js").read_bytes())
                            for mode, bundle in bundles.items()}}), flush=True)

def helpers(support):
    require(git(support, "rev-parse", "HEAD").decode().strip() == HELPER_SOURCE,
            "measurement helper checkout is not the immutable 7ae source")
    names = ("psc1/scripts/pskernel-paired-artifacts.py", "psc1/scripts/pskernel-paired-performance.py")
    subprocess.run(["git", "-C", str(support), "diff", "--quiet", "HEAD", "--", *names], check=True)
    paired = load_module("saturation_unchanged_paired_helpers",
                         support / "psc1/scripts/pskernel-paired-performance.py")
    return paired, paired.ARTIFACTS

def authenticate_routes(repo, support, output):
    paired, artifacts = helpers(support)
    current = compiler_sha(repo)
    run_id, attempt = int(os.environ["GITHUB_RUN_ID"]), int(os.environ["GITHUB_RUN_ATTEMPT"])
    run = artifacts.api("/actions/runs/" + str(run_id))
    require(run.get("id") == run_id and run.get("head_sha") == current
            and run.get("run_attempt") == attempt and run.get("path") == WORKFLOW
            and run.get("repository", {}).get("full_name") == REPOSITORY
            and run.get("head_repository", {}).get("full_name") == REPOSITORY
            and run.get("status") in ("in_progress", "completed"),
            "current functional producer workflow identity differs")
    response = artifacts.api(f"/actions/runs/{run_id}/attempts/{attempt}/jobs?per_page=100")
    jobs = response.get("jobs", [])
    require(isinstance(jobs, list) and response.get("total_count") == len(jobs),
            "current producer job enumeration incomplete")
    required = []
    for route in ("lean", "canonical-ps"):
        chosen = [job for job in jobs if job.get("name") == "kernel-" + route]
        require(len(chosen) == 1 and chosen[0].get("status") == "completed"
                and chosen[0].get("conclusion") == "success",
                "dependent measurements require both exact functional jobs PASS: " + route)
        required.append({key: chosen[0][key] for key in ("id", "name", "conclusion", "html_url")})
    routes = {}
    expected_identity = source_identity(repo)
    authentication_dir = output / "authentication"
    authentication_dir.mkdir(parents=True, exist_ok=True)
    for route in ("lean", "canonical-ps"):
        name = f"psc1-saturation-kernel-{route}-{run_id}-{attempt}"
        metadata, raw = artifacts.artifact(run_id, current, None, name)
        (authentication_dir / (route + ".zip")).write_bytes(raw)
        destination = output / "authenticated" / route
        destination.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(io.BytesIO(raw)) as archive:
            members = artifacts.safe_members(archive)
            manifest_name = artifacts.unique_member(members, "manifest.json")
            prefix = manifest_name[:-len("manifest.json")]
            manifest_bytes = archive.read(manifest_name)
            manifest = json.loads(manifest_bytes)
            require(manifest.get("schema") == "psc1-saturation-kernel-artifact-v1"
                    and manifest.get("repository") == REPOSITORY
                    and manifest.get("compilerSourceSha") == current
                    and manifest.get("kernelSourceSha") == KERNEL_SOURCE
                    and manifest.get("focusedPrototypeSourceSha") == FOCUSED_SOURCE
                    and manifest.get("sourceRoute") == route
                    and manifest.get("runId") == run_id and manifest.get("runAttempt") == attempt
                    and manifest.get("lean") == "4.35.0" and manifest.get("leanCommit") == LEAN_COMMIT
                    and manifest.get("typescript") == "7.0.2" and manifest.get("kernelFuel") == 4096
                    and re.fullmatch(r"v22\.[0-9]+\.[0-9]+", manifest.get("node", "")) is not None
                    and manifest.get("functionalComplete") is True
                    and manifest.get("kernelChanged") is False
                    and manifest.get("defaultCompilerChanged") is False
                    and manifest.get("globalCompilerPreservationProven") is False,
                    "producer manifest source, toolchain, scope or gate differs")
            records = manifest.get("files", [])
            require(isinstance(records, list) and bool(records)
                    and len({row.get("path") for row in records}) == len(records),
                    "missing or duplicate producer file manifest")
            require({prefix + row["path"] for row in records} | {manifest_name} == set(members),
                    "ZIP members are not completely covered by producer manifest")
            for record in records:
                relative = record["path"]
                require(isinstance(relative, str) and not relative.startswith("/")
                        and "\\" not in relative and ".." not in pathlib.PurePosixPath(relative).parts,
                        "unsafe producer file path")
                data = archive.read(prefix + relative)
                require(len(data) == record.get("bytes") and digest(data) == record.get("sha256"),
                        "producer file identity differs: " + relative)
                target = destination / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(data)
            (destination / "manifest.json").write_bytes(manifest_bytes)
        identity_bytes = (destination / "identity.json").read_bytes()
        functional_bytes = (destination / "functional.json").read_bytes()
        require(digest(identity_bytes) == manifest["sourceIdentitySha256"]
                and json.loads(identity_bytes) == expected_identity
                and digest(functional_bytes) == manifest["functionalReceiptSha256"],
                "source/functional receipt was not bound by authenticated artifact")
        functional = json.loads(functional_bytes)
        gates = functional.get("gates", [])
        require(functional.get("complete") is True and len(gates) == 57
                and all(row.get("returncode") == 0 and row.get("hostTimedOut") is False
                        and row.get("pathEmpty") is True for row in gates),
                "full generated functional gate did not finish")
        for mode in ("original", "optimized"):
            for kind, count in (("retained-smoke", 18), ("retained-complete-workload", 4),
                                ("retained-profile", 6)):
                require(sum(row.get("mode") == mode and row.get("kind") == kind for row in gates) == count,
                        "functional scope is incomplete: " + mode + "/" + kind)
            check_map(destination / "bundles" / mode)
        require(qualifying_receipt(destination, route) == manifest["emission"],
                "worker/call eligibility receipt differs after transport")
        routes[route] = {
            "artifactId": metadata["id"], "artifactZipBytes": len(raw),
            "artifactZipSha256": digest(raw), "manifestSha256": digest(manifest_bytes),
            "sourceRoute": route, "functionalComplete": True,
            "emitterModules": {mode: digest((destination / "bundles" / mode / "kernel.js").read_bytes())
                               for mode in ("original", "optimized")},
        }
    receipt = {"schema": "psc1-saturation-pair-authentication-v1",
               "compilerSourceSha": current, "kernelSourceSha": KERNEL_SOURCE,
               "runId": run_id, "runAttempt": attempt, "requiredProducerJobs": required,
               "workflowStatusAtCollection": run["status"], "routes": routes,
               "helperSourceSha": HELPER_SOURCE,
               "helpers": {name: digest((support / "psc1/scripts" / name).read_bytes())
                           for name in ("pskernel-paired-performance.py", "pskernel-paired-artifacts.py")}}
    write_json(authentication_dir / "runtimes.json", receipt)
    return paired, artifacts, receipt

def authenticate_reference(artifacts, output):
    run, jobs = artifacts.run_identity(artifacts.REFERENCE_RUN, artifacts.BASELINE_SOURCE, integration=False)
    rows = [job for job in jobs if job.get("id") == artifacts.REFERENCE_JOB
            and job.get("name") == "official-arena-reference"]
    require(len(rows) == 1 and rows[0].get("status") == "completed"
            and rows[0].get("conclusion") == "success", "pinned official reference job did not pass")
    metadata, raw = artifacts.artifact(artifacts.REFERENCE_RUN, artifacts.BASELINE_SOURCE,
                                      artifacts.REFERENCE_ARTIFACT, "psc1-arena435-official-reference")
    require(len(raw) == artifacts.REFERENCE_ZIP_BYTES and digest(raw) == artifacts.REFERENCE_ZIP_SHA256,
            "official reference artifact differs from exact pinned receipt")
    result = artifacts.restore_reference(raw, output / "authentication/official-reference.zip",
                                          output / "authentication/official-reference.json")
    result["producerJobUrl"] = rows[0]["html_url"]
    result["producerWorkflowConclusion"] = run["conclusion"]
    return result

def semantic_envelope(observed, logs):
    # Compare only genuine complete envelopes. Host limits are unresolved,
    # never a substitute for either a successful or a refused kernel decision.
    if observed.get("returncode") != 0 or observed.get("stage", "").startswith("host"):
        return None
    if observed.get("verdict") not in ("accepted", "rejected", "malformed", "unsupported", "resource_exhausted"):
        return None
    path = logs / observed["stdout"]
    records = [line[len("PSC1_ARENA_REPLAY "):] for line in path.read_text().splitlines()
               if line.startswith("PSC1_ARENA_REPLAY ")]
    require(len(records) == 1, "complete replay envelope missing during semantic comparison")
    return json.loads(records[0])

def paired_summary(output, report):
    lines = [
        "# Identical-kernel emitter comparison", "",
        "Kernel source: " + KERNEL_SOURCE + ". Compiler/experiment source: " + report["compiler_source_sha"] + ".",
        "Baseline means the original emitter; candidate means the opt-in saturated emitter. Both use the same kernel source.",
        "Only the Lean-source runtime pair is timed. Both full Lean-source and canonical-source functional pairs passed first.",
        "Each worker is detached with empty PATH and a 60-second deadline. 2048MiB is a V8 old-space setting, not an RSS cap.",
        "Two observations per emitter are descriptive; this is not a global compiler proof, full V2 replacement or 193-case qualification.",
        "The complete-admission timer excludes the unchanged worker's independent assertions/direct diagnostics; whole-process CPU/RSS includes them.",
        "", "| Fixture | API | Original warm ms/batch | Saturated warm ms/batch | Original/saturated | Original peak KiB | Saturated peak KiB |",
        "|---|---|---:|---:|---:|---:|---:|",
    ]
    for row in report["admission_summary"]:
        metrics = row["metric_means"]
        warm, peak = metrics.get("warm_admission_ms_per_batch", {}), metrics.get("process_peak_rss_kib", {})
        def value(mapping, key):
            return f"{mapping[key]:.6f}" if key in mapping else "incomplete"
        ratio = row["baseline_over_candidate_latency_ratio"]
        lines.append("| " + " | ".join((row["shape"] + str(row["declarations_per_batch"]), row["variant"],
                                        value(warm, "baseline"), value(warm, "candidate"),
                                        f"{ratio:.6f}" if ratio is not None else "unavailable",
                                        value(peak, "baseline"), value(peak, "candidate"))) + " |")
    lines.extend(["", "## Authentic original bodies",
                  "| Case | Original outcomes | Saturated outcomes | Matching completed envelopes |",
                  "|---|---|---|---|"])
    for row, parity in zip(report["authentic_summary"], report["completed_envelope_parity"]):
        lines.append("| " + " | ".join((row["label"] + "/" + row["name"],
            ", ".join(row["classifications"]["baseline"]), ", ".join(row["classifications"]["candidate"]),
            str(parity["completedEnvelopesAgree"]) + " (observed " + str(parity["completedEnvelopes"]) + "/4)")) + " |")
    lines.extend(["", "Exact per-worker values, cold latency, construction, retained heap, CPU/RSS, input hashes, resource results and receipts are in report.json.",
                  "A host timeout/heap failure contributes no accepted/rejected latency ratio. Unresolved cases remain explicitly incomplete.", ""])
    (output / "summary.md").write_text("\n".join(lines), encoding="utf-8")

def paired_measure(repo, support, archive, output):
    require(not (output / "report.json").exists(), "refusing to overwrite an existing paired report")
    paired, artifacts, authentication = authenticate_routes(repo, support, output)
    current = compiler_sha(repo)
    identity = source_identity(repo)
    write_json(output / "source-identity.json", identity)
    reference_receipt = authenticate_reference(artifacts, output)
    source = repo / "psc1"
    harness = {}
    for relative in paired.UNCHANGED:
        observed = (source / relative).read_bytes()
        frozen = git(support, "show", HELPER_SOURCE + ":psc1/" + relative)
        require(observed == frozen, "paired worker/policy changed: " + relative)
        harness[relative] = digest(observed)
    compare = load_module("saturation_unchanged_arena_compare",
                          source / "scripts/pskernel-arena435-compare.py")
    corpus = compare.ORACLE.read_archive(archive)
    reference = read_json(output / "authentication/official-reference.json")
    references = {(row["label"], row["name"]): row for row in reference["tests"]}
    require(len(corpus) == len(reference["tests"]) == len(references) == 193
            and set(references) == {(label, name) for label, name, _ in corpus},
            "official reference and authenticated archive identities differ")
    lookup = {(label, name): (index, raw) for index, (label, name, raw) in enumerate(corpus)}
    require(set(paired.AUTHENTIC) <= set(lookup), "unchanged authentic subset missing")
    selected = []
    inputs = output / "inputs"
    inputs.mkdir()
    for label, name in paired.AUTHENTIC:
        index, original = lookup[(label, name)]
        adapted, receipt = compare.ORACLE.adapt_header(original)
        require(all(references[(label, name)]["adaptation"].get(field) == receipt[field] for field in
                    ("original_sha256", "adapted_sha256", "original_body_sha256",
                     "adapted_body_sha256", "body_bytes_identical")),
                "authentic body/header receipt differs: " + name)
        target = inputs / f"case-{index:03d}.ndjson"
        target.write_bytes(adapted)
        selected.append({"label": label, "name": name, "corpus_index": index, "adaptation": receipt,
                         "official": references[(label, name)]["official"], "path": target})
    node, version = node_path()
    require(pathlib.Path("/usr/bin/time").is_file(), "GNU time required for unchanged paired workers")
    modules = authentication["routes"]["lean"]["emitterModules"]
    require(modules["original"] != modules["optimized"], "specialization emitted an identical runtime")
    report = {
        "format": "psc1-same-kernel-emitter-performance-v1",
        "compiler_source_sha": current, "kernel_source_sha": KERNEL_SOURCE,
        "focused_prototype_source_sha": FOCUSED_SOURCE,
        "workflow_run": f"https://github.com/{REPOSITORY}/actions/runs/{os.environ['GITHUB_RUN_ID']}",
        "workflow_run_attempt": int(os.environ["GITHUB_RUN_ATTEMPT"]),
        "started_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "authentication": authentication, "official_reference": reference_receipt,
        "source_comparison": {"original_kernel_identical": True, "default_compiler_identical": True,
                              "kernel_source_sha": KERNEL_SOURCE, "compiler_source_sha": current,
                              "helper_source_sha": HELPER_SOURCE, "unchanged_harnesses": harness},
        "harness_sha256": digest(pathlib.Path(__file__).read_bytes()),
        "node_version": version, "node_executable_sha256": digest(node.read_bytes()),
        "host_cpu_models": sorted({line.partition(":")[2].strip() for line in
                                  pathlib.Path("/proc/cpuinfo").read_text().splitlines()
                                  if line.startswith("model name")}),
        "host_workers": 1, "source_order_per_group": list(paired.ABBA),
        "emitter_labels": LABELS, "kernel_modules_sha256": modules, "measured_source_route": "lean",
        "functional_source_routes": ["lean", "canonical-ps"],
        "runtime_path_empty": True,
        "runtime_working_directory_contains_no_Lean_or_repository_sources": True,
        "kernel_fuel": 4096, "host_deadline_seconds_per_process": paired.DEADLINE,
        "v8_old_space_limit_mib": paired.OLD_SPACE_MIB, "hard_rss_limit_enforced": False,
        "rss_scope": "measured KiB; V8 old-space limit is not a total-process memory limit",
        "archive_sha256": compare.ORACLE.ARCHIVE_SHA256, "target_lean": compare.ORACLE.TARGET,
        "native_435_reexport": False, "declaration_body_bytes_unchanged": True,
        "subset_identities": [{"label": label, "name": name} for label, name in paired.AUTHENTIC],
        "corpus_cases_not_measured": 193 - len(paired.AUTHENTIC), "all_193_conformance_established": False,
        "full_v2_replacement_established": False, "global_compiler_preservation_proven": False,
        "entry_points": {"legacy": "psKernelV1AdmitDeclaration", "dag": "psKernelV1RunDag",
                         "authentic": "psKernelV1RunDag"},
        "dag_entry_scope": "transitional DAG checker with acknowledged whole-operation V1 fallbacks",
        "comparison_scope": "same kernel source; original versus opt-in emitter; each legacy source field names an emitter label",
        "cold_scope": "first valid batch after mandatory negative sentinel; process setup recorded separately",
        "warm_scope": "five worker warmups; every timed batch still has a fresh semantic session",
        "controls": [], "admission_observations": [], "authentic_observations": [],
        "admission_summary": [], "authentic_summary": [], "completed_envelope_parity": [],
        "collection_complete": False,
    }
    paired.write_report(output, report)
    logs = {phase: output / ("logs-" + phase) for phase in ("controls", "admission", "authentic")}
    for path in logs.values():
        path.mkdir()
    with tempfile.TemporaryDirectory(prefix="psc1-same-kernel-emitter-") as temporary:
        work = pathlib.Path(temporary)
        bundles = {}
        for label, mode in LABELS.items():
            original = output / "authenticated/lean/bundles" / mode
            require({path.relative_to(original).as_posix() for path in original.rglob("*") if path.is_file()}
                    == set(DEPLOYMENT_FILES), "unexpected deployment closure before timed worker")
            bundle = work / label
            shutil.copytree(original, bundle)
            for name in ("pskernel-arena-replay.mjs", "pskernel-arena-replay-controls.mjs",
                         "pskernel-expr-v2-admission-bench.mjs"):
                (bundle / "scripts" / name).write_bytes((source / "scripts" / name).read_bytes())
            require(digest((bundle / "kernel.js").read_bytes()) == modules[mode],
                    "timed kernel differs from authenticated functional output")
            bundles[label] = bundle
        for label, bundle in bundles.items():
            observed, stdout = paired.process(
                [str(node), "--max-old-space-size=2048",
                 str(bundle / "scripts/pskernel-arena-replay-controls.mjs"), str(bundle / "kernel.js")],
                bundle, logs["controls"], label)
            markers = [line for line in stdout.splitlines() if line.startswith("PSC1_ARENA_REPLAY_CONTROLS:")]
            valid = (observed["status"] == "completed"
                     and markers == ["PSC1_ARENA_REPLAY_CONTROLS: PASS count=138"]
                     and sum(line.startswith("PSC1_ARENA_CONTROL_PASS ") for line in stdout.splitlines()) == 138)
            report["controls"].append({"source": label, "emitterMode": LABELS[label], "valid": valid,
                                        "expected_assertions": 138, **observed})
            paired.write_report(output, report)
            if not valid:
                report["failure"] = "fresh unchanged replay controls failed: " + label
                paired.write_report(output, report)
                paired.output_digests(output)
                print("PSC1_SATURATION_PAIRED_CONTROLS_FAILED " + label, flush=True)
                return 1
        for shape, count, calls in paired.CASES:
            for variant in ("legacy", "dag"):
                for label in paired.ABBA:
                    index = len(report["admission_observations"])
                    observed = paired.admission_observation(
                        node, bundles[label], logs["admission"], index, label, variant, shape, count, calls)
                    observed.update(emitterMode=LABELS[label], kernelSourceSha=KERNEL_SOURCE,
                                    compilerSourceSha=current, kernelModuleSha256=modules[LABELS[label]])
                    report["admission_observations"].append(observed)
                    paired.write_report(output, report)
                    print("PSC1_SATURATION_PAIRED_ADMISSION " + json.dumps(
                        {key: observed[key] for key in ("index", "source", "emitterMode", "variant",
                                                       "shape", "declarations_per_batch", "status", "valid")}),
                          flush=True)
        for case in selected:
            for label in paired.ABBA:
                index = len(report["authentic_observations"])
                bundle = bundles[label]
                with paired.only_runtime_environment(bundle):
                    observed = compare.process_case(
                        node, bundle / "scripts/pskernel-arena-replay.mjs", bundle / "kernel.js",
                        case["path"], paired.DEADLINE, logs["authentic"], index)
                observed.update(paired.time_metrics(logs["authentic"] / f"case-{index:03d}-time.txt"))
                row = {key: value for key, value in case.items() if key != "path"}
                row.update(index=index, source=label, emitterMode=LABELS[label],
                           kernelSourceSha=KERNEL_SOURCE, compilerSourceSha=current,
                           kernelModuleSha256=modules[LABELS[label]], pskernel=observed,
                           classification=compare.classify(case["official"], observed))
                report["authentic_observations"].append(row)
                paired.write_report(output, report)
                print("PSC1_SATURATION_PAIRED_AUTHENTIC " + json.dumps(
                    {key: row[key] for key in ("index", "source", "emitterMode", "label", "name", "classification")}),
                      flush=True)
    report["admission_summary"] = paired.admission_summary(report["admission_observations"])
    report["authentic_summary"] = paired.authentic_summary(report["authentic_observations"])
    for label, name in paired.AUTHENTIC:
        rows = [row for row in report["authentic_observations"] if row["label"] == label and row["name"] == name]
        complete = [(row, semantic_envelope(row["pskernel"], logs["authentic"])) for row in rows]
        envelopes = [(row, value) for row, value in complete if value is not None]
        agree = all(value == envelopes[0][1] for _, value in envelopes) if envelopes else None
        report["completed_envelope_parity"].append({
            "label": label, "name": name, "completedEnvelopes": len(envelopes),
            "completedEnvelopesAgree": agree,
            "bothEmittersCompleted": {row["source"] for row, _ in envelopes} == {"baseline", "candidate"},
            "allFourCompleted": len(envelopes) == 4,
            "unresolvedHostObservations": len(rows) - len(envelopes),
            "envelopes": [{"index": row["index"], "emitterMode": row["emitterMode"], "value": value}
                          for row, value in envelopes],
        })
    report["all_admission_samples_valid"] = (len(report["admission_observations"]) == 48
                                            and all(row["valid"] for row in report["admission_observations"]))
    forbidden = {"false_accept", "false_reject", "pskernel_driver_error", "pskernel_internal_error"}
    report["unexpected_authentic_failures"] = [
        {"index": row["index"], "source": row["source"], "name": row["name"],
         "classification": row["classification"]} for row in report["authentic_observations"]
        if row["classification"] in forbidden or row["pskernel"].get("invalid_progress_snapshots", 0) != 0]
    report["completed_semantic_mismatches"] = [
        {"label": row["label"], "name": row["name"]} for row in report["completed_envelope_parity"]
        if row["completedEnvelopesAgree"] is False]
    report["collection_complete"] = (len(report["controls"]) == 2
                                     and all(row["valid"] for row in report["controls"])
                                     and len(report["admission_observations"]) == 48
                                     and len(report["authentic_observations"]) == 16)
    report["collection_protocol_valid"] = (report["collection_complete"]
                                           and report["all_admission_samples_valid"]
                                           and not report["unexpected_authentic_failures"]
                                           and not report["completed_semantic_mismatches"])
    report["finished_utc"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    paired.write_report(output, report)
    paired_summary(output, report)
    paired.output_digests(output)
    raw = (output / "report.json").read_bytes()
    require(len(raw) <= 512 * 1024, "complete paired report exceeds bounded console receipt")
    print("PSC1_SATURATION_PAIRED_REPORT_BEGIN " + json.dumps(
        {"bytes": len(raw), "sha256": digest(raw)}), flush=True)
    print(raw.decode("utf-8"), end="", flush=True)
    print("PSC1_SATURATION_PAIRED_REPORT_END", flush=True)
    print((output / "summary.md").read_text(), flush=True)
    print("PSC1_SATURATION_PAIRED_COLLECTION " + json.dumps({
        "complete": report["collection_complete"], "protocol_valid": report["collection_protocol_valid"],
        "kernelSourceSha": KERNEL_SOURCE, "compilerSourceSha": current,
        "admission_samples": len(report["admission_observations"]),
        "authentic_processes": len(report["authentic_observations"]),
        "all_193_conformance_established": False, "hard_rss_limit_enforced": False}), flush=True)
    return 0 if report["collection_protocol_valid"] else 1

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    for name in ("verify", "qualify", "pair"):
        command = commands.add_parser(name)
        command.add_argument("--repo", type=pathlib.Path, required=True)
        command.add_argument("--out", type=pathlib.Path, required=True)
        if name == "qualify":
            command.add_argument("--route", choices=("lean", "canonical-ps"), required=True)
        elif name == "pair":
            command.add_argument("--support", type=pathlib.Path, required=True)
            command.add_argument("--archive", type=pathlib.Path, required=True)
    args = parser.parse_args()
    repo, output = args.repo.resolve(strict=True), args.out.resolve()
    output.mkdir(parents=True, exist_ok=True)
    if args.command == "verify":
        identity = source_identity(repo)
        write_json(output / "identity.json", identity)
        print("PSC1_SATURATION_KERNEL_SOURCE " + json.dumps(
            {key: value for key, value in identity.items() if key != "files"}), flush=True)
        return 0
    if args.command == "qualify":
        qualify(repo, output, args.route)
        return 0
    return paired_measure(repo, args.support.resolve(strict=True),
                          args.archive.resolve(strict=True), output)

if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, OSError, KeyError, TypeError, subprocess.SubprocessError) as error:
        print("PSC1_SATURATION_KERNEL_EXPERIMENT_ERROR " + type(error).__name__ + ": " + str(error),
              file=sys.stderr, flush=True)
        sys.exit(1)
