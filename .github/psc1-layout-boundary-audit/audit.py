#!/usr/bin/env python3
"""Read-only API/byte/content audit; the official action performs ZIP extraction."""
import hashlib, json, os, pathlib, re, shutil, stat, subprocess, sys
import urllib.error, urllib.parse, urllib.request

REPO = "dwijayuda/pskernel"
SOURCE = "9c48af315d254b0263f4013eb3f0183e27b662af"
RUN, ATTEMPT, JOB, ARTIFACT = 40154659804, 1, 121053355557, 12583768183
NAME, ZIP_SIZE = "psc1-layout-boundary-preflight-attempt-1", 26125
ZIP_SHA = "c601465fd3b980775d7c8cb03e29479df68d5130b1aa605eca148eca0aacd9be"
BASE = "80005bb250a7324772db76d51684d23fbf0fe6ed"
TREE = "aa634d87ef51856bf0aaf68363836d2fb9cf215a"
LEAN = "eb6cafb7290e8bd5f2937522d8d804f58f02bafc"
PRODUCER = ".github/workflows/psc1-pskernel-layout-boundary-preflight.yml"
WORKFLOW = ".github/workflows/psc1-pskernel-layout-boundary-artifact-audit.yml"
AUDITOR = ".github/psc1-layout-boundary-audit/audit.py"
DOWNLOAD = "actions/download-artifact@d3f86a106a0bac45b974a628896c90dbdf5c8093"
MODULES = [("PsKernelExprV2MetadataProofs", 8),
           ("PsKernelExprV2PagedModelProofs", 17),
           ("PsKernelExprV2LayoutBoundaryProofs", 5)]
BLOBS = {
    "psc1/test/PsKernelExprV2MetadataProofs.lean": "c97466b70bddb9867d05ab4282990a3f3e417779",
    "psc1/test/PsKernelExprV2PagedModelProofs.lean": "e9ed760c2394b908fd5632633572fb557261756a",
    "psc1/test/PsKernelExprV2LayoutBoundaryProofs.lean": "923d74270fdc307e58922ad78c44887eaf4041a7",
    PRODUCER: "70c4ff14e2c53bd5aa355a38a46075ff4fea6233",
    "psc1/packages/pskernel-core/src/Ps/KernelCore/Core/ExprV2/Validation.lean": "b4b2855cc93ff7b886e283257203c7a4a3ef27ad",
    "psc1/packages/pskernel-core/src/Ps/KernelCore/Core/ExprV2/Paged.lean": "26ba0ae6bfef59a8cedec846f1164c73e468e86c",
    "psc1/packages/pskernel-core/src/Ps/KernelCore/Core/ExprV2/Builder.lean": "1e2a03c2a7cbdcca944e59957fab43166f184002",
    "psc1/kernel-lakefile.lean": "6b1f3747b1fc6e4d391fc31fa6196851d31a5a24",
    "psc1/lean-toolchain": "a6aff065db2882c535684f8c5bcd4f16e9a23915",
    "psc1/scripts/install-lean435-ci.sh": "b53f59db9e2fbb45feeedea659244cae7e77b64b",
}
FLAGS = {
    "shapeGuardEstablishesSourceLayout": True,
    "successfulValidatorEstablishesSourceLayout": True,
    "replayNodePreservesCanonicalLayout": True,
    "validateFuelPreservesCanonicalLayout": True,
    "canonicalOutputLayoutEstablished": True,
    "metadataCorrespondenceEstablished": False,
    "decoderCorrespondenceEstablished": False,
    "replayArenaModelBridgeEstablished": False,
    "productionChanges": False, "fullQualification": False, "performanceQualified": False,
}
BOUNDARY_NAMES = ["shape_valid_establishes_layout", "validate_ok_establishes_source_layout",
                  "replay_node_ok_preserves_layout", "validate_fuel_ok_preserves_layout",
                  "validate_ok_establishes_canonical_layout"]

def require(ok, message):
    if not ok:
        raise RuntimeError(message)

def exact(left, right):
    if type(left) is not type(right):
        return False
    if isinstance(left, dict):
        return left.keys() == right.keys() and all(exact(left[k], right[k]) for k in left)
    if isinstance(left, list):
        return len(left) == len(right) and all(exact(a, b) for a, b in zip(left, right))
    return left == right

def digest(raw):
    return {"bytes": len(raw), "sha256": hashlib.sha256(raw).hexdigest()}

def blob(raw):
    return hashlib.sha1(b"blob " + str(len(raw)).encode() + b"\0" + raw).hexdigest()

def pairs(items):
    result = {}
    for key, value in items:
        require(key not in result, "duplicate JSON key: " + key)
        result[key] = value
    return result

def parse(raw):
    return json.loads(raw, object_pairs_hook=pairs,
                      parse_constant=lambda _: (_ for _ in ()).throw(ValueError("nonfinite JSON")))

def read_json(path):
    return parse(path.read_bytes())

def write_json(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n")

def git(root, *args):
    return subprocess.check_output(["git", "-C", str(root), *args])

class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None

def request(path):
    token = os.environ.get("GH_TOKEN", "")
    require(bool(token), "read-only GitHub token required")
    return urllib.request.Request("https://api.github.com/repos/" + REPO + path,
        headers={"Authorization": "Bearer " + token, "Accept": "application/vnd.github+json",
                 "X-GitHub-Api-Version": "2022-11-28", "User-Agent": "psc1-layout-content-audit"})

def api(path):
    with urllib.request.build_opener(NoRedirect).open(request(path), timeout=30) as response:
        return parse(response.read(2_000_000))

def zip_bytes():
    opener = urllib.request.build_opener(NoRedirect)
    try:
        with opener.open(request("/actions/artifacts/" + str(ARTIFACT) + "/zip"), timeout=30) as response:
            raw = response.read(ZIP_SIZE + 1)
    except urllib.error.HTTPError as error:
        require(error.code in (301, 302, 303, 307, 308), "artifact download API failed")
        location = error.headers.get("Location", "")
        url = urllib.parse.urlsplit(location)
        require(url.scheme == "https" and url.hostname is not None
                and (url.hostname.endswith(".blob.core.windows.net")
                     or url.hostname.endswith(".githubusercontent.com")),
                "unexpected signed artifact host")
        # Never forward the API Authorization header to the signed download host.
        with opener.open(urllib.request.Request(location,
                headers={"User-Agent": "psc1-layout-content-audit"}), timeout=30) as response:
            raw = response.read(ZIP_SIZE + 1)
    require(len(raw) == ZIP_SIZE and hashlib.sha256(raw).hexdigest() == ZIP_SHA,
            "raw ZIP size or pinned SHA256 mismatch")
    return raw

def validate_metadata(meta):
    run, artifact, jobs = meta["run"], meta["artifact"], meta["jobs"]
    require(run["id"] == RUN and run["run_attempt"] == ATTEMPT and run["head_sha"] == SOURCE
            and run["path"] == PRODUCER and run["repository"]["full_name"] == REPO
            and run["status"] == "completed" and run["conclusion"] == "success",
            "target run/attempt/source did not pass")
    require(artifact["id"] == ARTIFACT and artifact["name"] == NAME
            and artifact["size_in_bytes"] == ZIP_SIZE and artifact["expired"] is False
            and artifact["digest"] == "sha256:" + ZIP_SHA
            and artifact["workflow_run"]["id"] == RUN
            and artifact["workflow_run"]["head_sha"] == SOURCE,
            "artifact API identity/digest mismatch")
    require(jobs["total_count"] == 1 and len(jobs["jobs"]) == 1, "exact native job required")
    job = jobs["jobs"][0]
    require(job["id"] == JOB and job["run_id"] == RUN and job["run_attempt"] == ATTEMPT
            and job["head_sha"] == SOURCE and job["name"] == "native"
            and job["status"] == "completed" and job["conclusion"] == "success",
            "native job identity/status mismatch")
    require(all(s["status"] == "completed" and s["conclusion"] == "success" for s in job["steps"]),
            "all native job steps must pass")

def identity(audit):
    return {"repository": REPO, "sourceSha": os.environ["GITHUB_SHA"],
            "runId": os.environ["GITHUB_RUN_ID"], "runAttempt": os.environ["GITHUB_RUN_ATTEMPT"],
            "job": os.environ["GITHUB_JOB"], "workflow": WORKFLOW,
            "files": {p: digest((audit / p).read_bytes()) for p in (WORKFLOW, AUDITOR)}}

def validate_checkouts(target, audit):
    require(os.environ["GITHUB_REPOSITORY"] == REPO, "unexpected audit repository")
    require(git(target, "rev-parse", "HEAD").decode().strip() == SOURCE, "target checkout SHA")
    require(git(audit, "rev-parse", "HEAD").decode().strip() == os.environ["GITHUB_SHA"],
            "audit checkout SHA")
    require(not git(target, "status", "--porcelain") and not git(audit, "status", "--porcelain"),
            "both checkouts must remain clean")
    require(git(target, "rev-parse", "HEAD:psc1/packages/pskernel-core/src").decode().strip() == TREE,
            "target production tree changed")

def prepare(target, audit, out):
    require(not out.exists(), "fresh audit output required")
    out.mkdir(parents=True)
    validate_checkouts(target, audit)
    meta = {"run": api("/actions/runs/" + str(RUN) + "/attempts/" + str(ATTEMPT)),
            "artifact": api("/actions/artifacts/" + str(ARTIFACT)),
            "jobs": api("/actions/runs/" + str(RUN) + "/attempts/" + str(ATTEMPT) + "/jobs?per_page=100")}
    validate_metadata(meta)
    write_json(out / "api-metadata.json", meta)
    raw = zip_bytes()
    (out / "target-artifact.zip").write_bytes(raw)
    for name in (WORKFLOW, AUDITOR):
        dest = out / "audit-sources" / name
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(audit / name, dest)
    prepared = {"auditIdentity": identity(audit), "targetSourceSha": SOURCE,
                "targetRunId": RUN, "targetRunAttempt": ATTEMPT, "artifactId": ARTIFACT,
                "apiMetadata": digest((out / "api-metadata.json").read_bytes()),
                "rawZip": digest(raw), "rawZipParserImplemented": False}
    write_json(out / "prepared.json", prepared)
    print("PSC1_LAYOUT_ARTIFACT_PREPARED " + json.dumps(prepared, separators=(",", ":")))

def verify(target, audit, out):
    validate_checkouts(target, audit)
    prepared = read_json(out / "prepared.json")
    require(exact(prepared["auditIdentity"], identity(audit)), "executed auditor identity changed")
    for name in (WORKFLOW, AUDITOR):
        require((out / "audit-sources" / name).read_bytes() == (audit / name).read_bytes(),
                "archived auditor source changed: " + name)
    require(prepared["targetSourceSha"] == SOURCE and prepared["targetRunId"] == RUN
            and prepared["targetRunAttempt"] == ATTEMPT and prepared["artifactId"] == ARTIFACT,
            "prepared target identity changed")
    require(exact(prepared["apiMetadata"], digest((out / "api-metadata.json").read_bytes())),
            "prepared API metadata changed")
    validate_metadata(read_json(out / "api-metadata.json"))
    raw = (out / "target-artifact.zip").read_bytes()
    require(len(raw) == ZIP_SIZE and hashlib.sha256(raw).hexdigest() == ZIP_SHA
            and exact(prepared["rawZip"], digest(raw)), "prepared raw ZIP changed")
    extracted = out / "extracted"
    logs = ["layout-" + module + ".log" for module, _ in MODULES]
    expected = {"sources/" + path for path in BLOBS} | set(logs) | {
        "native-build.log", "proof-status.log", "source-inventory.json", "native-receipt.json"}
    require(len(expected) == 17, "auditor member inventory")
    directories = {str(parent) for name in expected for parent in pathlib.PurePosixPath(name).parents
                   if str(parent) != "."}
    actual = set()
    for path in extracted.rglob("*"):
        name = path.relative_to(extracted).as_posix()
        require(not path.is_symlink(), "symlink in extracted artifact")
        if path.is_dir():
            require(name in directories, "unexpected extracted directory: " + name)
        else:
            require(stat.S_ISREG(path.stat().st_mode), "nonregular extracted member")
            actual.add(name)
    require(actual == expected, "exact 17 extracted files required")
    source_rows = []
    for name, expected_blob in BLOBS.items():
        raw = (extracted / "sources" / name).read_bytes()
        require(raw == (target / name).read_bytes()
                and raw == git(target, "show", "HEAD:" + name), "source bytes differ from exact Git target: " + name)
        require(blob(raw) == expected_blob, "pinned Git blob mismatch: " + name)
        source_rows.append({"path": name, **digest(raw), "gitBlobSha": blob(raw)})
    inventory_path = extracted / "source-inventory.json"
    inventory = read_json(inventory_path)
    expected_inventory = {"schema": "psc1-layout-boundary-proof-source-v1", "sourceSha": SOURCE,
        "runId": str(RUN), "runAttempt": str(ATTEMPT), "leanGitHash": LEAN, "baselineSha": BASE,
        "productionSourceTree": TREE, "productionAndRetainedProofsUnchanged": True, "files": source_rows}
    require(exact(inventory, expected_inventory), "source receipt differs from authenticated source inventory")
    proof_records, all_names, statuses = [], [], []
    allowed = {"propext", "Classical.choice", "Quot.sound"}
    pattern = r"'([^']+)' (?:depends on axioms:\s*\[([^\]]*)\]|does not depend on any axioms)"
    for module, count in MODULES:
        proof_path = extracted / "sources" / ("psc1/test/" + module + ".lean")
        names = re.findall(r"(?m)^#print axioms (\S+)\s*$", proof_path.read_text())
        names = [name if "." in name else module + "." + name for name in names]
        require(len(names) == count and len(set(names)) == count, "source proof inventory: " + module)
        if module == "PsKernelExprV2LayoutBoundaryProofs":
            require(names == [module + "." + name for name in BOUNDARY_NAMES], "five exact boundary theorems")
        log_path = extracted / ("layout-" + module + ".log")
        text = log_path.read_text()
        reports = re.findall(pattern, text)
        require([name for name, _ in reports] == names, "ordered actual proof reports: " + module)
        require(not any(word in text for word in ("sorryAx", "Lean.ofReduceBool", "Lean.trustCompiler"))
                and not re.search(r"\.lean:\d+:\d+: error:", text), "forbidden proof diagnostic: " + module)
        require(all({a.strip() for a in used.split(",") if a.strip()} <= allowed for _, used in reports),
                "nonstandard proof axiom: " + module)
        all_names.extend(names)
        proof_records.append({"module": module, "proofs": count, "names": names,
                              "source": digest(proof_path.read_bytes()), "log": digest(log_path.read_bytes())})
        statuses.append("PSC1_LAYOUT_BOUNDARY_PROOF_STATUS module=" + module
                        + " count=" + str(count) + " countStatus=0 leanStatus=0")
    require(len(all_names) == 30 and len(set(all_names)) == 30, "exact 30 distinct reports")
    status_path = extracted / "proof-status.log"
    require(status_path.read_text() == "\n".join(statuses) + "\n", "exact successful command statuses")
    build = (extracted / "native-build.log").read_text()
    require("Build completed successfully" in build and not re.search(r"\.lean:\d+:\d+: error:", build),
            "native production build log did not succeed")
    receipt_path = extracted / "native-receipt.json"
    expected_receipt = {"schema": "psc1-layout-boundary-preflight-v1", "sourceSha": SOURCE,
        "runId": str(RUN), "runAttempt": str(ATTEMPT), "status": "pass", "proofModules": 3,
        "totalProofs": 30, "proofs": proof_records, "sourceInventory": digest(inventory_path.read_bytes()),
        "proofStatuses": digest(status_path.read_bytes()), "orderedUniqueReports": True,
        "allowedStandardAxiomsOnly": True, **FLAGS}
    require(exact(read_json(receipt_path), expected_receipt), "native receipt or truthful scope mismatch")
    result = {"schema": "psc1-layout-boundary-artifact-content-audit-v1", "status": "pass",
        "auditIdentity": identity(audit), "targetSourceSha": SOURCE, "targetRunId": RUN,
        "targetRunAttempt": ATTEMPT, "targetJobId": JOB, "artifactId": ARTIFACT,
        "artifactName": NAME, "artifactZip": {"bytes": ZIP_SIZE, "sha256": ZIP_SHA},
        "officialDownloadAction": DOWNLOAD, "rawZipSha256Verified": True,
        "independentArtifactContentAudit": True, "independentRawZipParser": False,
        "independentZipAudit": False, "extractedFiles": 17, "sourceFiles": 10, "proofReports": 30,
        "productionAndRetainedProofsUnchanged": True, "scope": FLAGS,
        "nativeReceipt": digest(receipt_path.read_bytes()), "sourceInventory": digest(inventory_path.read_bytes()),
        "manifest": [{"path": name, **digest((extracted / name).read_bytes())} for name in sorted(expected)]}
    write_json(out / "audit-result.json", result)
    print("PSC1_LAYOUT_BOUNDARY_ARTIFACT_AUDIT: PASS " + json.dumps(result, separators=(",", ":")))

def main():
    require(len(sys.argv) == 5 and sys.argv[1] in ("prepare", "verify"), "usage: audit.py prepare|verify target audit out")
    target, audit, out = (pathlib.Path(p).resolve() for p in sys.argv[2:])
    workspace = pathlib.Path(os.environ["GITHUB_WORKSPACE"]).resolve()
    require(target == workspace / "target-source" and audit == workspace / "audit-source",
            "dedicated exact checkouts required")
    require(out == pathlib.Path(os.environ["RUNNER_TEMP"]).resolve() / "layout-boundary-artifact-audit",
            "writes must remain inside audit artifacts")
    (prepare if sys.argv[1] == "prepare" else verify)(target, audit, out)

if __name__ == "__main__":
    main()
