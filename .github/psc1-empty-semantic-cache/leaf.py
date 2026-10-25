#!/usr/bin/env python3
"""Source-bound paired CacheAnalysis leaves; no full kernel or benchmark."""
import hashlib, json, os, pathlib, re, shutil, stat, subprocess, sys
import urllib.error, urllib.parse, urllib.request

REPO = "dwijayuda/pskernel"
BASE = "20224a295359abb201f56c72395690bf0bfac9fa"
CANDIDATE = "e503972553ae2d41d5ba7a26d7739fb32ee86b96"
COMPILER_SOURCE = "80005bb250a7324772db76d51684d23fbf0fe6ed"
LEAN = "eb6cafb7290e8bd5f2937522d8d804f58f02bafc"
COMPILER_HASH = "13635a423d1343e9a4770be0b7e02d859a6b845b221a0363d19bfdfab8e3cc1c"
COMPILER_RECEIPT = "0c852d2948bf0310823bade83253a391977a10a7184d466a7b5245c1e0499b3b"
SRC = "psc1/packages/pskernel-core/src"
ENTRY = "psc1/packages/pskernel-core/src/Ps/KernelCore/Runtime/Acceleration/CacheAnalysis.lean"
WORKFLOW = ".github/workflows/psc1-empty-semantic-cache-leaf.yml"
DRIVER = ".github/psc1-empty-semantic-cache/leaf.py"
NEW = "psc1/scripts/pskernel-empty-semantic-cache-smoke.mjs"
RETAINED = "psc1/scripts/pskernel-closed-cache-analysis-smoke.mjs"
INPUTS = {
 "compiler": {
  "source": COMPILER_SOURCE, "run": 40149637831, "attempt": 1, "job": 121038541765,
  "jobName": "compiler", "artifact": 12581708293,
  "name": "psc1-transform-delay-compiler-attempt-1", "size": 2420207,
  "sha256": "c2d97da78b427c0f675c72568badb2897f041dabf1de82d145ada4cb9467c361",
  "workflow": ".github/workflows/psc1-pskernel-transform-delay-abba.yml"},
 "native": {
  "source": CANDIDATE, "run": 40157229337, "attempt": 1, "job": 121061091716,
  "jobName": "native", "artifact": 12585087010,
  "name": "psc1-empty-semantic-cache-preflight-attempt-1", "size": 36747,
  "sha256": "47507140e234f9aebb1ab7ecef289b78c579f330e696709529b3b60a3501d0fe",
  "workflow": ".github/workflows/psc1-empty-semantic-cache-preflight.yml"}
}
TREES = {
 "baseline": "57b209c4b29f7a9dd67bdae37e728cde4a0ac1ff",
 "candidate": "e567685e5c441a5b0a78d8241f7bae151b48b5ca"}
LEAF_BLOBS = {
 "Core/Name.lean": "37f385adeb6a80282dbd596d5ce5a464b0fb30e3",
 "Core/Level.lean": "1d6e3f7bbf7fa64081f66947b8c032f61859111b",
 "Core/ExprScalar.lean": "be1f345af6fd58a82f9ec93ef1fba29e57ff5f83",
 "Core/Expr.lean": "44d01196e8cdbb6d67db8a860dc73827c8cb206c",
 "Runtime/Acceleration/ScalarHash.lean": "86292c6e3cdf1981682cf8d701dfc972538a04d6",
 "Runtime/Acceleration/Cache.lean": "838f40f32baba7791b30484aa926b9e02e6effc2",
 "Runtime/Acceleration/CachePolicy.lean": "8cebe08ae7c88c5a2e45c31f6bdba683ce8c1af7"}
ENTRY_BLOBS = {
 "baseline": "4d5ca3d8e2a6136d5fcb35dec131e5c28e6b743b",
 "candidate": "d8f8fd5731d0473370a0028d4f484bcb845d9e57"}
TOOLS = {
 "psc1/scripts/bootstrap-project.mjs": "734db05bccdd777f3cb1fa95aa9904e36caa9926",
 "psc1/scripts/bootstrap-manifest.mjs": "ceb965192e6ba70046d7fe7769c9917063a4fb4e",
 "psc1/scripts/workspace-layout.mjs": "b6c1118174d685dd174c29c3c41c527f52182234",
 "psc1/psconfig.json": "25ce42bd1c585d926dee097575fd337274f619e5",
 "psc1/lean-toolchain": "a6aff065db2882c535684f8c5bcd4f16e9a23915",
 "psc1/scripts/install-lean435-ci.sh": "b53f59db9e2fbb45feeedea659244cae7e77b64b",
 RETAINED: "494647393a3e4b3bdb7ac11115dac470cef6061a"}
MODULES = [
 ("PsKernelCacheScopeProofs", 60, "cache-scope-proofs.log"),
 ("PsKernelClosedCacheAnalysisRegression", 7, "closed-cache-analysis-proofs.log"),
 ("PsKernelEmptySemanticCacheProofs", 2, "empty-semantic-cache-proofs.log")]
NATIVE_SCOPE = {
 "orderedUniqueReports": True, "allowedStandardAxiomsOnly": True,
 "emptySmallMapLookupGuard": True, "allRawCacheLookupResultsPreserved": True,
 "retainedProofStatementsUnchanged": True, "cachePolicyUnchanged": True,
 "cachePublicationUnchanged": True, "checkerFuelPolicyUnchanged": True,
 "heldTransformOptimizationAdopted": False, "churchAcceptanceFixed": False,
 "generatedQualification": False, "runtimeQualification": False,
 "fullQualification": False, "fullKernel": False, "performanceQualified": False}
RETAINED_RESULT = {
 "expressions":20, "states":2, "mapQueries":40, "pairQueries":800,
 "inferQueries":80, "assertions":1884, "smallAndIndexed":True, "openEntriesSeeded":True}
EMPTY_RESULT = {
 "schema":"psc1-empty-semantic-cache-v1", "assertions":21,
 "sectionAssertions":{"harness":1,"empty":20}, "coldQueries":20,
 "actualGeneratedConstructors":True, "inputsUnchanged":True,
 "helperOnly":True, "fullKernel":False, "performanceQualified":False}

def require(value, message):
    if not value:
        raise RuntimeError(message)

def exact(left, right):
    if type(left) is not type(right):
        return False
    if isinstance(left, dict):
        return left.keys() == right.keys() and all(exact(left[k], right[k]) for k in left)
    if isinstance(left, list):
        return len(left) == len(right) and all(exact(a, b) for a, b in zip(left, right))
    return left == right

def sha(raw):
    return hashlib.sha256(raw).hexdigest()

def digest(raw):
    return {"bytes":len(raw), "sha256":sha(raw)}

def blob(raw):
    return hashlib.sha1(b"blob " + str(len(raw)).encode() + b"\0" + raw).hexdigest()

def pairs(items):
    result = {}
    for key, value in items:
        require(key not in result, "duplicate JSON key")
        result[key] = value
    return result

def parse(raw):
    return json.loads(raw, object_pairs_hook=pairs,
        parse_constant=lambda _: (_ for _ in ()).throw(ValueError("nonfinite JSON")))

def read_json(path):
    return parse(path.read_bytes())

def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")

def git(root, *args):
    return subprocess.check_output(["git", "-C", str(root), *args])

def copy(source, destination):
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, destination)

def files(root):
    require(root.is_dir() and not root.is_symlink(), "regular artifact directory required")
    result = {}
    for p in root.rglob("*"):
        require(not p.is_symlink(), "symlink is not an artifact member")
        if p.is_dir():
            continue
        require(stat.S_ISREG(p.stat().st_mode), "nonregular artifact member")
        result[p.relative_to(root).as_posix()] = digest(p.read_bytes())
    return result

def checked_source(root, name, expected_blob=None):
    path = root / name
    require(path.is_file() and not path.is_symlink(), "missing or linked source: " + name)
    raw = path.read_bytes()
    require(raw == git(root, "show", "HEAD:" + name), "checkout differs from Git: " + name)
    actual_blob = blob(raw)
    if expected_blob is not None:
        require(actual_blob == expected_blob, "pinned source blob mismatch: " + name)
    return {"path":name, **digest(raw), "gitBlobSha":actual_blob}

def validate_checkouts(base, candidate, experiment):
    require(os.environ["GITHUB_REPOSITORY"] == REPO, "repository mismatch")
    for role, root, source in [
        ("baseline", base, BASE), ("candidate", candidate, CANDIDATE),
        ("experiment", experiment, os.environ["GITHUB_SHA"])]:
        require(git(root, "rev-parse", "HEAD").decode().strip() == source, role + " source mismatch")
        require(not git(root, "status", "--porcelain", "--untracked-files=no"),
                role + " tracked checkout was mutated")
        if role != "experiment":
            require(git(root, "rev-parse", "HEAD:" + SRC).decode().strip() == TREES[role],
                    role + " production tree mismatch")
    for name in (WORKFLOW, DRIVER, NEW):
        checked_source(experiment, name)

def experiment_identity(root):
    return {"sourceSha":os.environ["GITHUB_SHA"], "runId":os.environ["GITHUB_RUN_ID"],
        "runAttempt":os.environ["GITHUB_RUN_ATTEMPT"], "job":os.environ["GITHUB_JOB"],
        "files":[checked_source(root, name) for name in (WORKFLOW, DRIVER, NEW)]}

class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None

def request(path):
    token = os.environ.get("GH_TOKEN", "")
    require(bool(token), "read-only API token required")
    return urllib.request.Request("https://api.github.com/repos/" + REPO + path,
        headers={"Authorization":"Bearer " + token, "Accept":"application/vnd.github+json",
            "X-GitHub-Api-Version":"2022-11-28", "User-Agent":"psc1-empty-cache-leaf"})

def api(path):
    with urllib.request.build_opener(NoRedirect).open(request(path), timeout=30) as response:
        return parse(response.read(2_000_000))

def download_zip(spec):
    opener = urllib.request.build_opener(NoRedirect)
    try:
        with opener.open(request("/actions/artifacts/" + str(spec["artifact"]) + "/zip"),
                         timeout=30) as response:
            raw = response.read(spec["size"] + 1)
    except urllib.error.HTTPError as error:
        require(error.code in (301,302,303,307,308), "artifact download failed")
        location = error.headers.get("Location", "")
        url = urllib.parse.urlsplit(location)
        require(url.scheme == "https" and url.hostname is not None
            and (url.hostname.endswith(".blob.core.windows.net")
                 or url.hostname.endswith(".githubusercontent.com")), "unexpected signed host")
        with opener.open(urllib.request.Request(location,
                headers={"User-Agent":"psc1-empty-cache-leaf"}), timeout=30) as response:
            raw = response.read(spec["size"] + 1)
    require(len(raw) == spec["size"] and sha(raw) == spec["sha256"],
            "pinned artifact ZIP size/SHA256 mismatch")
    return raw

def validate_metadata(spec, meta):
    run, artifact, job = meta["run"], meta["artifact"], meta["job"]
    require(run["id"] == spec["run"] and run["run_attempt"] == spec["attempt"]
        and run["head_sha"] == spec["source"] and run["path"] == spec["workflow"]
        and run["repository"]["full_name"] == REPO
        and run["status"] == "completed" and run["conclusion"] == "success",
        "input run/attempt/source/status mismatch")
    require(artifact["id"] == spec["artifact"] and artifact["name"] == spec["name"]
        and artifact["size_in_bytes"] == spec["size"] and artifact["expired"] is False
        and artifact["digest"] == "sha256:" + spec["sha256"]
        and artifact["workflow_run"]["id"] == spec["run"]
        and artifact["workflow_run"]["head_sha"] == spec["source"],
        "input artifact metadata mismatch")
    require(job["id"] == spec["job"] and job["run_id"] == spec["run"]
        and job["run_attempt"] == spec["attempt"] and job["head_sha"] == spec["source"]
        and job["name"] == spec["jobName"] and job["status"] == "completed"
        and job["conclusion"] == "success", "input producer job mismatch")
    require(all(s["status"] == "completed" and s["conclusion"] == "success"
                for s in job["steps"]), "input producer step did not pass")

def prepare(base, candidate, experiment, out):
    require(not out.exists(), "fresh experiment output required")
    validate_checkouts(base, candidate, experiment)
    for root in (base, candidate, experiment):
        require(not git(root, "status", "--porcelain"), "fresh clean checkout required")
    out.mkdir(parents=True)
    for name, spec in INPUTS.items():
        dest = out / "inputs" / name
        dest.mkdir(parents=True)
        meta = {"run":api("/actions/runs/" + str(spec["run"]) + "/attempts/" + str(spec["attempt"])),
            "artifact":api("/actions/artifacts/" + str(spec["artifact"])),
            "job":api("/actions/jobs/" + str(spec["job"]))}
        validate_metadata(spec, meta)
        write_json(dest / "api-metadata.json", meta)
        (dest / "artifact.zip").write_bytes(download_zip(spec))
    for name in (WORKFLOW, DRIVER, NEW):
        copy(experiment / name, out / "experiment-sources" / name)
    write_json(out / "prepared.json", {"schema":"psc1-empty-cache-leaf-prepared-v1",
        "experiment":experiment_identity(experiment), "baselineSourceSha":BASE,
        "candidateSourceSha":CANDIDATE, "compilerSourceSha":COMPILER_SOURCE,
        "inputs":INPUTS, "rawZipSha256Verified":True, "independentZipParser":False})
    print("PSC1_EMPTY_CACHE_LEAF_PREPARED: PASS")

def verify_inputs(base, candidate, experiment, out):
    validate_checkouts(base, candidate, experiment)
    prepared = read_json(out / "prepared.json")
    require(exact(prepared["experiment"], experiment_identity(experiment))
        and prepared["baselineSourceSha"] == BASE
        and prepared["candidateSourceSha"] == CANDIDATE
        and prepared["compilerSourceSha"] == COMPILER_SOURCE
        and exact(prepared["inputs"], INPUTS), "prepared experiment identity changed")
    for name in (WORKFLOW, DRIVER, NEW):
        require((out / "experiment-sources" / name).read_bytes() == (experiment / name).read_bytes(),
                "archived experiment source changed")
    for name, spec in INPUTS.items():
        dest = out / "inputs" / name
        validate_metadata(spec, read_json(dest / "api-metadata.json"))
        raw = (dest / "artifact.zip").read_bytes()
        require(len(raw) == spec["size"] and sha(raw) == spec["sha256"], "input ZIP changed")
    compiler = out / "inputs/compiler/extracted"
    native = out / "inputs/native/extracted"
    c = read_json(compiler / "compiler-receipt.json")
    require(sha((compiler / "compiler-receipt.json").read_bytes()) == COMPILER_RECEIPT,
            "pinned compiler receipt mismatch")
    require(c["schema"] == "psc1-transform-delay-compiler-v1"
        and c["sourceSha"] == COMPILER_SOURCE and c["runId"] == "40149637831"
        and c["runAttempt"] == "1" and c["leanGitHash"] == LEAN
        and c["compilerSha256"] == COMPILER_HASH, "compiler receipt identity")
    expected_compiler = set(c["files"]) | {"compiler-receipt.json"}
    actual_compiler = files(compiler)
    require(len(expected_compiler) == 13 and set(actual_compiler) == expected_compiler,
            "exact 13 compiler artifact members required")
    for name, expected in c["files"].items():
        require(actual_compiler[name]["sha256"] == expected, "compiler artifact content: " + name)
    require(sha((compiler / "psc1").read_bytes()) == COMPILER_HASH, "compiler binary mismatch")

    inventory_path = native / "source-inventory.json"
    require(sha(inventory_path.read_bytes()) ==
        "8b0874cf6be298d6312b457072ef60a3d4a7089e36433fc0abd78ae9af0395cb",
        "native source inventory pin")
    inventory = read_json(inventory_path)
    require(inventory["schema"] == "psc1-empty-semantic-cache-source-v1"
        and inventory["sourceSha"] == CANDIDATE and inventory["runId"] == "40157229337"
        and inventory["runAttempt"] == "1" and inventory["branchBaseSha"] == BASE
        and inventory["targetProductionTree"] == TREES["candidate"]
        and inventory["productionChanges"] == [ENTRY]
        and inventory["exactLookupGuardAndCommentOnly"] is True
        and inventory["frozenLookupByteExact"] is True,
        "native source identity/scope")
    source_names = {
        INPUTS["native"]["workflow"], "psc1/kernel-lakefile.lean", "psc1/lean-toolchain",
        "psc1/scripts/install-lean435-ci.sh", ENTRY,
        SRC + "/Ps/KernelCore/Core/Expr.lean",
        SRC + "/Ps/KernelCore/Runtime/Acceleration/Cache.lean",
        SRC + "/Ps/KernelCore/Runtime/Acceleration/CachePolicy.lean",
        *("psc1/test/" + module + ".lean" for module, _, _ in MODULES)}
    require(len(source_names) == 11 and {r["path"] for r in inventory["files"]} == source_names,
            "native exact 11-source inventory")
    for row in inventory["files"]:
        name = row["path"]
        checked = checked_source(candidate, name)
        require(exact(row, checked) and (native / "sources" / name).read_bytes()
            == (candidate / name).read_bytes(), "native archived source/Git mismatch: " + name)
    expected_native = {"sources/" + name for name in source_names} | {
        "native-build.log", "proof-status.log", "source-inventory.json", "native-receipt.json",
        *(name for _, _, name in MODULES)}
    actual_native = files(native)
    require(len(expected_native) == 18 and set(actual_native) == expected_native,
            "exact 18 native evidence members required")
    reports, statuses, all_names = [], [], []
    pattern = r"'([^']+)' (?:depends on axioms:\s*\[([^\]]*)\]|does not depend on any axioms)"
    allowed = {"propext", "Classical.choice", "Quot.sound"}
    for module, count, log_name in MODULES:
        path = native / "sources" / ("psc1/test/" + module + ".lean")
        names = re.findall(r"(?m)^#print axioms (\S+)\s*$", path.read_text())
        names = [n if "." in n else module + "." + n for n in names]
        log = (native / log_name).read_text()
        actual = re.findall(pattern, log)
        require(len(names) == count and [n for n, _ in actual] == names,
                "ordered actual native proof reports: " + module)
        require(not any(w in log for w in ("sorryAx", "Lean.ofReduceBool", "Lean.trustCompiler"))
            and not re.search(r"\.lean:\d+:\d+: error:", log)
            and all({a.strip() for a in used.split(",") if a.strip()} <= allowed for _, used in actual),
            "native proof trust/diagnostic failure: " + module)
        reports.append({"module":module, "proofs":count, "names":names,
            "source":digest(path.read_bytes()), "log":digest((native / log_name).read_bytes())})
        all_names.extend(names)
        statuses.append("PSC1_EMPTY_SEMANTIC_CACHE_PROOF_STATUS module=" + module
            + " count=" + str(count) + " countStatus=0 leanStatus=0")
    require(len(all_names) == 69 and len(set(all_names)) == 69, "69 distinct native reports")
    require((native / "proof-status.log").read_text() == "\n".join(statuses) + "\n",
            "native proof command statuses")
    require(sha((native / "native-receipt.json").read_bytes()) ==
        "57c2beac55dd1ab5184df29176ca9cc6189032fbddbc9e2cdd40fe6cef635a74",
        "pinned native receipt mismatch")
    receipt = read_json(native / "native-receipt.json")
    require(receipt["schema"] == "psc1-empty-semantic-cache-preflight-v1"
        and receipt["sourceSha"] == CANDIDATE and receipt["runId"] == "40157229337"
        and receipt["runAttempt"] == "1" and receipt["status"] == "pass"
        and receipt["leanGitHash"] == LEAN and receipt["retainedProofs"] == 67
        and receipt["newProofs"] == 2 and receipt["totalProofs"] == 69
        and receipt["proofModules"] == 3 and exact(receipt["proofs"], reports)
        and exact(receipt["sourceInventory"], digest(inventory_path.read_bytes()))
        and exact(receipt["proofStatuses"], digest((native / "proof-status.log").read_bytes()))
        and exact(receipt["nativeBuild"], digest((native / "native-build.log").read_bytes()))
        and receipt["productionChanges"] == [ENTRY]
        and receipt["archiveFiles"] == 18 and receipt["archiveMembers"] == sorted(expected_native),
        "native receipt content mismatch")
    for name, value in NATIVE_SCOPE.items():
        require(receipt[name] is value, "native scope flag: " + name)
    require("Build completed successfully" in (native / "native-build.log").read_text(),
            "native build success missing")
    result = {"schema":"psc1-empty-cache-leaf-inputs-v1",
        "compilerSourceSha":COMPILER_SOURCE, "compilerSha256":COMPILER_HASH,
        "compilerReceipt":digest((compiler / "compiler-receipt.json").read_bytes()),
        "candidateNativeSourceSha":CANDIDATE, "candidateNativeProofs":69,
        "candidateNativeReceipt":digest((native / "native-receipt.json").read_bytes()),
        "rawZipSha256Verified":True, "extractedContentsVerified":True,
        "officialExtraction":True, "independentZipParser":False,
        "compilerFiles":actual_compiler, "nativeFiles":actual_native}
    write_json(out / "input-receipt.json", result)
    print("PSC1_EMPTY_CACHE_LEAF_INPUTS: PASS " + json.dumps(result, separators=(",", ":")))
    return compiler / "psc1"

def source_manifest(root, role):
    expected = {SRC + "/Ps/KernelCore/" + name: value for name, value in LEAF_BLOBS.items()}
    expected[ENTRY] = ENTRY_BLOBS[role]
    visited = set()
    def visit(name):
        if name in visited:
            return
        require(name in expected, "leaf imports an unexpected source: " + name)
        visited.add(name)
        checked_source(root, name, expected[name])
        for module in re.findall(r"(?m)^\s*import\s+([A-Za-z0-9_.]+)\s*;?\s*$",
                                 (root / name).read_text()):
            require(module.startswith("Ps.KernelCore."), "unexpected leaf import: " + module)
            visit(SRC + "/" + module.replace(".", "/") + ".lean")
    visit(ENTRY)
    require(visited == set(expected) and len(visited) == 8, "exact eight-source leaf closure")
    return {"kernelSourceSha":BASE if role == "baseline" else CANDIDATE,
        "entry":ENTRY, "productionTree":TREES[role],
        "sourceCount":8, "sources":[checked_source(root, p, expected[p]) for p in sorted(expected)],
        "tools":[checked_source(root, p, expected_blob) for p, expected_blob in sorted(TOOLS.items())],
        "heldKernelProductionImported":False}

def run(command, cwd, log, timeout=600, environment=None):
    env = os.environ.copy()
    env.pop("GH_TOKEN", None)
    env["NODE_OPTIONS"] = ""
    if environment:
        env.update(environment)
    log.parent.mkdir(parents=True, exist_ok=True)
    with log.open("wb") as output:
        try:
            result = subprocess.run([str(x) for x in command], cwd=cwd, env=env,
                stdout=output, stderr=subprocess.STDOUT, timeout=timeout, check=False)
        except subprocess.TimeoutExpired:
            print(log.read_text(), end="")
            raise RuntimeError("bounded command timed out: " + log.name)
    print(log.read_text(), end="")
    require(result.returncode == 0, "command failed; inspect " + str(log))
    return {"arguments":[str(x) for x in command], "cwd":str(cwd),
        "exitCode":result.returncode, "timeoutSeconds":timeout, "log":digest(log.read_bytes())}

def bootstrap_adapter(root, compiler):
    workspace = (root / "psc1").resolve()
    text = (root / "psc1/scripts/bootstrap-project.mjs").read_text()
    replacements = [
        ('from "./workspace-layout.mjs";',
         'from ' + json.dumps((workspace / "scripts/workspace-layout.mjs").as_uri()) + ';'),
        ('from "./bootstrap-manifest.mjs";',
         'from ' + json.dumps((workspace / "scripts/bootstrap-manifest.mjs").as_uri()) + ';'),
        ('const selfhostRoot = path.resolve(scriptDir, "..");',
         'const selfhostRoot = ' + json.dumps(str(workspace)) + ';'),
        ('    "lake",\n    [\n      "exe",\n      "psc1",\n',
         '    ' + json.dumps(str(compiler)) + ',\n    [\n')]
    for before, after in replacements:
        require(text.count(before) == 1, "bootstrap exact adaptation anchor")
        text = text.replace(before, after, 1)
    return text

def runtime_result(log, marker, expected):
    lines = log.read_text().splitlines()
    records = [parse(line[len(marker):]) for line in lines if line.startswith(marker)]
    require(len(records) == 1 and lines[-1].startswith(marker) and exact(records[0], expected),
            "exact runtime receipt mismatch: " + log.name)
    return records[0]

def build_variant(root, role, experiment, out, compiler, node, tsc):
    dest = out / role
    require(not dest.exists(), "fresh variant output required")
    dest.mkdir()
    source = source_manifest(root, role)
    write_json(dest / "source-manifest.json", source)
    for row in source["sources"] + source["tools"]:
        copy(root / row["path"], dest / "sources" / row["path"])
    copy(experiment / NEW, dest / "runtime" / pathlib.Path(NEW).name)
    copy(root / RETAINED, dest / "runtime" / pathlib.Path(RETAINED).name)
    work = (root / "psc1").resolve()
    generated = work / "dist/empty-semantic-cache-leaf"
    require(not generated.exists(), "fresh canonical workspace required")
    generated.mkdir(parents=True)
    workspace = generated / "workspace"
    relative_entry = ENTRY.removeprefix("psc1/")
    relative_workspace = "dist/empty-semantic-cache-leaf/workspace"
    relative_ps = relative_workspace + "/" + relative_entry.removesuffix(".lean") + ".ps"
    adapter = dest / "bootstrap-shared.mjs"
    adapter.write_text(bootstrap_adapter(root, compiler), encoding="utf-8")
    require(adapter.read_text() == bootstrap_adapter(root, compiler), "adapter source changed")
    adapter_record = {
        "source":source["tools"][next(i for i, r in enumerate(source["tools"])
            if r["path"] == "psc1/scripts/bootstrap-project.mjs")],
        "adapter":digest(adapter.read_bytes()), "replacementCount":4,
        "translatorSourceSha":COMPILER_SOURCE, "translatorSha256":COMPILER_HASH,
        "kernelSourceSha":source["kernelSourceSha"]}
    write_json(dest / "bootstrap-tools.json", adapter_record)
    steps = {}
    steps["adapterSyntax"] = run([node, "--check", adapter], work, dest / "adapter-syntax.log", 60)
    steps["authenticSource"] = run([compiler, "check", relative_entry],
        work, dest / "authentic-source.log")
    steps["translation"] = run([node, adapter, relative_entry, relative_workspace],
        work, dest / "bootstrap.log")
    manifest = read_json(workspace / ".proofscript-bootstrap.json")
    expected_paths = sorted(row["path"].removeprefix("psc1/").removesuffix(".lean") + ".ps"
                            for row in source["sources"])
    entry_ps = relative_entry.removesuffix(".lean") + ".ps"
    require(manifest["schemaVersion"] == 2 and manifest["generation"] == "bootstrap"
        and manifest["entry"] == entry_ps and manifest["sourceCount"] == 8
        and manifest["generated"] == expected_paths, "exact canonical leaf manifest")
    canonical_files = files(workspace)
    require(set(canonical_files) == set(expected_paths) | {".proofscript-bootstrap.json"},
            "exact canonical workspace members")
    closure = hashlib.sha256(b"proofscript-bootstrap-closure-v2\0" + entry_ps.encode() + b"\0")
    for name in expected_paths:
        raw = (workspace / name).read_bytes()
        raw.decode("utf-8")
        closure.update(name.encode() + b"\0" + raw + b"\0")
    require(closure.hexdigest() == manifest["closureSha256"], "canonical closure hash mismatch")
    check_script = (
        "import {readFileSync} from 'node:fs';\n"
        "import {assertBootstrapWorkspaceManifest} from "
        + json.dumps((work / "scripts/bootstrap-manifest.mjs").as_uri()) + ";\n"
        "const workspace=" + json.dumps(str(workspace)) + ";\n"
        "await assertBootstrapWorkspaceManifest(workspace,JSON.parse(readFileSync("
        "workspace+'/.proofscript-bootstrap.json','utf8')),'bootstrap');\n"
        "console.log('PSC1_EMPTY_CACHE_CANONICAL_CLOSURE: PASS sources=8');\n")
    (dest / "check-manifest.mjs").write_text(check_script)
    steps["canonicalManifest"] = run([node, dest / "check-manifest.mjs"],
        work, dest / "canonical-manifest.log", 60)
    steps["canonicalSource"] = run([compiler, "check", relative_ps],
        work, dest / "canonical-source.log")
    steps["generatedBuild"] = run([compiler, "build", relative_ps,
        "--out", "dist/empty-semantic-cache-leaf/kernel.js"],
        work, dest / "generated-build.log", environment={"PSC0_TSC":str(tsc)})
    for suffix in ("js", "ts", "d.ts", "js.map"):
        path = generated / ("kernel." + suffix)
        require(path.is_file() and path.stat().st_size > 0, "missing generated output: " + suffix)
        copy(path, dest / ("kernel." + suffix))
    require(exact(files(workspace), canonical_files),
            "canonical source bytes changed during checking or code generation")
    shutil.copytree(workspace, dest / "canonical")
    copy(dest / "kernel.js", dest / "runtime/kernel.mjs")
    steps["generatedSyntax"] = run([node, "--check", dest / "runtime/kernel.mjs"],
        dest, dest / "generated-syntax.log", 60)
    results = {}
    for label, script, marker, expected in [
        ("retained", pathlib.Path(RETAINED).name, "PSC1_CLOSED_CACHE_ANALYSIS_JS: PASS ", RETAINED_RESULT),
        ("empty", pathlib.Path(NEW).name, "PSC1_EMPTY_SEMANTIC_CACHE_JS: PASS ", EMPTY_RESULT)]:
        log = dest / (label + "-runtime.log")
        steps[label] = run([node, "--max-old-space-size=2048", dest / "runtime" / script,
            dest / "runtime/kernel.mjs"], dest / "runtime", log, 60,
            environment={"PATH":""})
        results[label] = runtime_result(log, marker, expected)
    text = (dest / "empty-runtime.log").read_text().splitlines()
    labels = [s.removeprefix("PSC1_EMPTY_SEMANTIC_CACHE_ASSERT ") for s in text
              if s.startswith("PSC1_EMPTY_SEMANTIC_CACHE_ASSERT ")]
    expected_labels = ["harness/rejection"] + ["empty/" + str(i).zfill(2) for i in range(20)]
    require(labels == expected_labels and len(set(labels)) == 21, "21 ordered distinct runtime labels")
    sections = [s for s in text if s.startswith("PSC1_EMPTY_SEMANTIC_CACHE_SECTION ")]
    require(sections == ["PSC1_EMPTY_SEMANTIC_CACHE_SECTION harness=1",
                         "PSC1_EMPTY_SEMANTIC_CACHE_SECTION empty=20"],
            "two exact runtime sections")
    require(text[:2] == ["PSC1_EMPTY_SEMANTIC_CACHE_ASSERT harness/rejection", sections[0]]
        and text[-2] == sections[1], "runtime section order")
    require(exact(source_manifest(root, role), source), "source bytes changed during execution")
    for row in source["sources"] + source["tools"]:
        require((dest / "sources" / row["path"]).read_bytes() == (root / row["path"]).read_bytes(),
                "archived execution source differs")
    require((dest / "runtime" / pathlib.Path(RETAINED).name).read_bytes() == (root / RETAINED).read_bytes()
        and (dest / "runtime" / pathlib.Path(NEW).name).read_bytes() == (experiment / NEW).read_bytes(),
        "executed harness bytes changed")
    require((dest / "kernel.js").read_bytes() == (dest / "runtime/kernel.mjs").read_bytes(),
            "runtime module differs from generated kernel")
    require(sha(compiler.read_bytes()) == COMPILER_HASH, "shared compiler changed during execution")
    require(adapter.read_text() == bootstrap_adapter(root, compiler), "executed adapter changed")
    write_json(dest / "command-statuses.json", steps)
    receipt = {"schema":"psc1-empty-cache-leaf-variant-v1", "status":"pass", "variant":role,
        "kernelSourceSha":source["kernelSourceSha"], "compilerSourceSha":COMPILER_SOURCE,
        "compilerSha256":COMPILER_HASH, "experiment":experiment_identity(experiment),
        "entry":ENTRY, "sourceCount":8, "sourceManifest":digest((dest / "source-manifest.json").read_bytes()),
        "bootstrapTools":digest((dest / "bootstrap-tools.json").read_bytes()),
        "canonicalClosureSha256":manifest["closureSha256"],
        "generatedKernel":digest((dest / "kernel.js").read_bytes()),
        "commandStatuses":digest((dest / "command-statuses.json").read_bytes()),
        "runtime":{"retained":results["retained"], "empty":results["empty"]},
        "assertions":1905, "retainedAssertions":1884, "newAssertions":21,
        "route":"canonical-ps-typescript-js-leaf", "helperOnly":True,
        "heldKernelProductionImported":False, "nativeProofsRerun":False,
        "fuelPolicyChanged":False, "fullKernelGenerated":False,
        "fullQualification":False, "fullKernel":False,
        "churchAcceptanceFixed":False, "performanceMeasured":False, "performanceQualified":False,
        "files":files(dest)}
    write_json(dest / "leaf-receipt.json", receipt)
    print("PSC1_EMPTY_CACHE_LEAF_VARIANT: PASS " + json.dumps(receipt, separators=(",", ":")))
    return receipt

def build(base, candidate, experiment, out):
    compiler = verify_inputs(base, candidate, experiment, out).resolve(strict=True)
    compiler.chmod(compiler.stat().st_mode | stat.S_IXUSR)
    node_name, lean_name = shutil.which("node"), shutil.which("lean")
    require(node_name is not None and lean_name is not None, "pinned tool executables missing")
    node, lean = pathlib.Path(node_name).resolve(), pathlib.Path(lean_name).absolute()
    tsc = pathlib.Path(os.environ["PSC0_TSC"]).resolve(strict=True)
    ts_root = out.parent / "empty-semantic-cache-ts"
    require(tsc == (ts_root / "node_modules/typescript/bin/tsc").resolve(), "unexpected TypeScript path")
    require(read_json(ts_root / "node_modules/typescript/package.json")["version"] == "7.0.2",
            "pinned TypeScript version")
    version = subprocess.check_output([node, "--version"], text=True).strip()
    require(re.fullmatch(r"v22\.\d+\.\d+", version) is not None, "Node22 required")
    lean_hash = subprocess.check_output([lean, "--githash"], cwd=candidate / "psc1", text=True).strip()
    require(lean_hash == LEAN, "pinned Lean runtime hash")
    copy(ts_root / "package-lock.json", out / "tool-sources/typescript-package-lock.json")
    copy(ts_root / "node_modules/typescript/package.json", out / "tool-sources/typescript-package.json")
    write_json(out / "tools.json", {"nodeVersion":version, "node":digest(node.read_bytes()),
        "leanGitHash":lean_hash, "typescriptVersion":"7.0.2",
        "typescriptEntry":digest(tsc.read_bytes()),
        "typescriptPackage":digest((ts_root / "node_modules/typescript/package.json").read_bytes()),
        "typescriptLock":digest((ts_root / "package-lock.json").read_bytes()),
        "compilerSourceSha":COMPILER_SOURCE,
        "compilerSha256":COMPILER_HASH})
    results = [build_variant(base, "baseline", experiment, out, compiler, node, tsc),
               build_variant(candidate, "candidate", experiment, out, compiler, node, tsc)]
    validate_checkouts(base, candidate, experiment)
    require(exact(results[0]["runtime"], results[1]["runtime"]), "paired semantic receipts differ")
    before = read_json(out / "baseline/source-manifest.json")
    after = read_json(out / "candidate/source-manifest.json")
    require([r["path"] for r in before["sources"]] == [r["path"] for r in after["sources"]],
            "paired closure paths differ")
    changed = [a["path"] for a, b in zip(before["sources"], after["sources"]) if not exact(a, b)]
    require(changed == [ENTRY] and exact(before["tools"], after["tools"]), "paired source delta mismatch")
    report = {"schema":"psc1-empty-cache-paired-leaf-v1", "status":"pass",
        "experiment":experiment_identity(experiment), "baselineSourceSha":BASE,
        "candidateSourceSha":CANDIDATE, "compilerSourceSha":COMPILER_SOURCE,
        "compilerSha256":COMPILER_HASH, "sourceClosureCountPerVariant":8,
        "leafSourceChanges":changed, "inputReceipt":digest((out / "input-receipt.json").read_bytes()),
        "tools":digest((out / "tools.json").read_bytes()),
        "variants":[{"variant":r["variant"], "kernelSourceSha":r["kernelSourceSha"],
            "receipt":digest((out / r["variant"] / "leaf-receipt.json").read_bytes()),
            "generatedKernel":r["generatedKernel"]} for r in results],
        "retainedAssertionsPerVariant":1884, "newAssertionsPerVariant":21,
        "totalAssertions":3810, "nativeCandidateProofs":69,
        "semanticReceiptsMatch":True, "actualSourceClosuresVerified":True,
        "explicitSharedTranslatorAdapter":True, "rawInputZipDigestsVerified":True,
        "downloadedInputContentsVerified":True, "independentZipParser":False,
        "heldKernelProductionImported":False, "nativeProofsRerun":False,
        "fullKernelGenerated":False, "fullQualification":False, "fullKernel":False,
        "churchAcceptanceFixed":False, "performanceMeasured":False, "performanceQualified":False}
    write_json(out / "paired-leaf-report.json", report)
    print("PSC1_EMPTY_CACHE_PAIRED_LEAF: PASS " + json.dumps(report, separators=(",", ":")))

def main():
    require(len(sys.argv) == 6 and sys.argv[1] in {"prepare","verify-inputs","build"},
            "usage: leaf.py <prepare|verify-inputs|build> baseline candidate experiment out")
    base, candidate, experiment, out = [pathlib.Path(p).resolve() for p in sys.argv[2:]]
    {"prepare":prepare, "verify-inputs":verify_inputs, "build":build}[sys.argv[1]](
        base, candidate, experiment, out)

if __name__ == "__main__":
    main()
