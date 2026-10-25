#!/usr/bin/env python3
"""Read-only audit of one native arena-model proof archive; no builds or benchmarks."""
import hashlib, io, json, os, pathlib, re, shutil, stat, subprocess, sys, zipfile, zlib
import urllib.error, urllib.parse, urllib.request

REPO = "dwijayuda/pskernel"
SOURCE = "150123e5fb8e17d8fab4d737a043705727ee1bcc"
RUN, ATTEMPT, JOB, ARTIFACT = 40191428231, 1, 121163053720, 12598157338
NAME, ZIP_SIZE = "psc1-arena-model-preflight-attempt-1", 59976
ZIP_SHA = "0db9ff75fd7191873847bdd06e987b577b8830d66e0bee10220251d315096a92"
BASE = "054edfce56eda28a166624ddc92dfac5af8499c0"
TREE = "e567685e5c441a5b0a78d8241f7bae151b48b5ca"
LEAN = "eb6cafb7290e8bd5f2937522d8d804f58f02bafc"
PRODUCER = ".github/workflows/psc1-pskernel-arena-model-preflight.yml"
WORKFLOW = ".github/workflows/psc1-pskernel-arena-model-artifact-audit.yml"
AUDITOR = ".github/psc1-arena-model-audit/audit.py"
DOWNLOAD = "actions/download-artifact@d3f86a106a0bac45b974a628896c90dbdf5c8093"
MODULES = [("PsKernelExprV2MetadataProofs", 8),
           ("PsKernelExprV2PagedModelProofs", 17),
           ("PsKernelExprV2ReplayMetadataProofs", 4),
           ("PsKernelExprV2SemanticPrefixProofs", 8),
           ("PsKernelExprV2DecodedNodeProofs", 2),
           ("PsKernelExprV2DecodedBridgeProofs", 12),
           ("PsKernelOrdinaryOccurrenceProofs", 15),
           ("PsKernelExprV2ArenaModelBridgeProofs", 7)]
BLOBS = {
    "psc1/test/PsKernelExprV2MetadataProofs.lean": "c97466b70bddb9867d05ab4282990a3f3e417779",
    "psc1/test/PsKernelExprV2PagedModelProofs.lean": "e9ed760c2394b908fd5632633572fb557261756a",
    "psc1/test/PsKernelExprV2ReplayMetadataProofs.lean": "0df4649698e7171d422be1c5b3dfc1a5d817502e",
    "psc1/test/PsKernelExprV2SemanticPrefixProofs.lean": "fc8fde4fa239f37c39d0766fe14d8111c2002995",
    "psc1/test/PsKernelExprV2DecodedNodeProofs.lean": "e41675f3a6eeb09805ca220b9085922828b76d71",
    "psc1/test/PsKernelExprV2DecodedBridgeProofs.lean": "b19223eb0d4d15bda070beee98722cf0cee44397",
    "psc1/test/PsKernelOrdinaryOccurrenceProofs.lean": "2034798a4de1b4ca25b2e6366a88020b97beed27",
    "psc1/test/PsKernelExprV2ArenaModelBridgeProofs.lean": "810485914392c739d2b0b15848d3e893b69c9e90",
    PRODUCER: "c91ad8edf86081dc61af237645f213ed98d4f3f5",
    "psc1/packages/pskernel-core/src/Ps/KernelCore/Core/ExprV2/Validation.lean": "b4b2855cc93ff7b886e283257203c7a4a3ef27ad",
    "psc1/packages/pskernel-core/src/Ps/KernelCore/Core/ExprV2/Decode.lean": "73ef143268f4c0deea2a24fdea250d95b428f5af",
    "psc1/packages/pskernel-core/src/Ps/KernelCore/Core/ExprV2/Paged.lean": "26ba0ae6bfef59a8cedec846f1164c73e468e86c",
    "psc1/packages/pskernel-core/src/Ps/KernelCore/Core/ExprV2/Builder.lean": "1e2a03c2a7cbdcca944e59957fab43166f184002",
    "psc1/packages/pskernel-core/src/Ps/KernelCore/Core/ExprV2/Node.lean": "24e3809b269526a897bb6c22b8467725bb30af77",
    "psc1/packages/pskernel-core/src/Ps/KernelCore/Research/ExprV2Validation.lean": "473a4c64c16079dde7a9c1bffdd24ef28cd3b9fd",
    "psc1/kernel-lakefile.lean": "6b1f3747b1fc6e4d391fc31fa6196851d31a5a24",
    "psc1/lean-toolchain": "a6aff065db2882c535684f8c5bcd4f16e9a23915",
    "psc1/scripts/install-lean435-ci.sh": "b53f59db9e2fbb45feeedea659244cae7e77b64b",
}
FLAGS = {
    "localReplayMetadataCorrespondenceEstablished": True,
    "replayNodeBranchesCovered": 12,
    "successfulReplayPreservesLayoutAndPriorLookups": True,
    "actualMetadataGuardTransfersCorrespondence": True,
    "consistentSharedSemanticPrefixEstablished": True,
    "freshMeaningPreservesPriorInterpretations": True,
    "sourceCanonicalNodeAlignmentEstablished": True,
    "wholeValidatorMetadataCorrespondenceEstablished": True,
    "decodedPrefixUsesActualRequire": True,
    "decodedNodeCorrespondenceEstablished": True,
    "decodedNodeConstructorBranchesCovered": 12,
    "decoderStoragePreservationEstablished": True,
    "decoderCorrespondenceEstablished": True,
    "decoderSuccessAfterPublicValidationEstablished": True,
    "decoderUsesActualCanonicalFuel": True,
    "untrustedSourceValidityAssumed": False,
    "replayArenaModelBridgeEstablished": True,
    "productionChanges": False, "fullQualification": False, "performanceQualified": False,
}
REPLAY_NAMES = ["replay_node_builds_corresponding_entry", "replay_node_preserves_layout_and_metadata",
                "bool_eq_true_iff", "portable_same_metadata_transfers_correspondence"]

PREFIX_NAMES = ["interpret_congr_below", "extend_meaning_preserves_old",
                "empty_semantic_prefix", "replay_success_inputs",
                "replay_preserves_semantic_prefix", "aligned_prefix_transfers_semantics",
                "validate_fuel_preserves_semantic_prefix", "validate_ok_establishes_semantic_prefixes"]

NODE_NAMES = ["decoded_node_interprets", "decoded_entry_interprets"]
BRIDGE_NAMES = ["decoded_empty_layout", "decoded_push_size", "decoded_push_layout",
                "decoded_push_require_old", "decoded_push_require_new", "decoded_empty_prefix",
                "decoded_prefix_push", "decoded_prefix_metadata",
                "decode_canonical_fuel_ok_preserves", "decode_canonical_fuel_succeeds",
                "decode_checked_succeeds_after_validate", "decode_checked_ok_corresponds"]

def proof_log_name(module):
    stem = ("model-" if module in ("PsKernelOrdinaryOccurrenceProofs", "PsKernelExprV2ArenaModelBridgeProofs")
            else "decoder-" if module in ("PsKernelExprV2DecodedNodeProofs", "PsKernelExprV2DecodedBridgeProofs")
            else "prefix-" if module == "PsKernelExprV2SemanticPrefixProofs" else "replay-")
    return stem + module + ".log"

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
                 "X-GitHub-Api-Version": "2022-11-28", "User-Agent": "psc1-arena-model-audit"})

def download(path, limit):
    """Read a bounded API body or its one signed redirect without leaking credentials."""
    opener = urllib.request.build_opener(NoRedirect)
    try:
        with opener.open(request(path), timeout=30) as response:
            raw = response.read(limit + 1)
    except urllib.error.HTTPError as error:
        require(error.code in (301, 302, 303, 307, 308), "GitHub download API failed")
        location = error.headers.get("Location", "")
        url = urllib.parse.urlsplit(location)
        require(url.scheme == "https" and url.hostname is not None and url.username is None
                and url.password is None and url.port in (None, 443)
                and (url.hostname.endswith(".blob.core.windows.net")
                     or url.hostname.endswith(".githubusercontent.com")),
                "unexpected signed download host")
        # Deliberately construct a new request with no Authorization header.
        with opener.open(urllib.request.Request(location,
                headers={"User-Agent": "psc1-arena-model-audit"}), timeout=30) as response:
            raw = response.read(limit + 1)
    require(len(raw) <= limit, "download exceeded its fixed byte limit")
    return raw

def api(path):
    return parse(download(path, 2_000_000))

def zip_bytes():
    raw = download("/actions/artifacts/" + str(ARTIFACT) + "/zip", ZIP_SIZE)
    require(len(raw) == ZIP_SIZE and hashlib.sha256(raw).hexdigest() == ZIP_SHA,
            "raw ZIP size or pinned SHA256 mismatch")
    return raw

def expected_members():
    names = {"sources/" + path for path in BLOBS}
    names.update(proof_log_name(module) for module, _ in MODULES)
    names.update(("native-build.log", "proof-status.log", "source-inventory.json", "native-receipt.json"))
    require(len(BLOBS) == 18 and len(names) == 30, "fixed source/member inventory changed")
    return names

def zip_members(raw):
    """Validate and read the raw archive independently of the official extraction."""
    expected = expected_members()
    members, entries = {}, []
    with zipfile.ZipFile(io.BytesIO(raw)) as archive:
        infos = archive.infolist()
        require(len(infos) == 30 and not archive.comment, "exact uncommented 30-member ZIP required")
        require(len({info.filename for info in infos}) == 30, "duplicate ZIP member names")
        require(len({info.header_offset for info in infos}) == 30, "duplicate ZIP local headers")
        require(sum(info.file_size for info in infos) <= 4_000_000, "ZIP expanded-size limit")
        for info in infos:
            name = info.filename
            path = pathlib.PurePosixPath(name)
            require(name == info.orig_filename and name in expected
                    and not name.startswith("/") and "\\" not in name and "\0" not in name
                    and ":" not in name and path.as_posix() == name
                    and all(part not in ("", ".", "..") for part in name.split("/")),
                    "noncanonical or unexpected ZIP path")
            mode = info.external_attr >> 16
            require(not info.is_dir() and stat.S_IFMT(mode) in (0, stat.S_IFREG)
                    and not (info.external_attr & 0x10), "nonregular ZIP member: " + name)
            require(info.compress_type in (zipfile.ZIP_STORED, zipfile.ZIP_DEFLATED)
                    and not (info.flag_bits & (1 | 0x40 | 0x2000)), "unsupported ZIP encoding: " + name)
            require(0 <= info.header_offset < len(raw) and 0 <= info.compress_size <= ZIP_SIZE
                    and 0 <= info.file_size <= 1_000_000, "invalid ZIP member bounds: " + name)
        # zipfile also checks local-header names, truncation, overlapping entries and CRCs.
        require(archive.testzip() is None, "ZIP CRC validation failed")
        for info in infos:
            value = archive.read(info)
            require(len(value) == info.file_size and (zlib.crc32(value) & 0xffffffff) == info.CRC,
                    "ZIP size/CRC mismatch: " + info.filename)
            members[info.filename] = value
            entries.append({"path": info.filename, "compressedBytes": info.compress_size,
                            "crc32": format(info.CRC, "08x"), **digest(value)})
    require(set(members) == expected, "exact raw ZIP inventory required")
    return members, sorted(entries, key=lambda row: row["path"])

def normalized_job_log(raw):
    text = raw.decode("utf-8-sig")
    text = re.sub(r"\x1b\[[0-9;]*m", "", text)
    return "\n".join(re.sub(r"^\d{4}-\d\d-\d\dT\S+ ", "", line) for line in text.splitlines())

def axiom_reports(text):
    pattern = r"(?m)^'([^']+)' (?:depends on axioms:\s*\[([^\]]*)\]|does not depend on any axioms)"
    found = re.findall(pattern, text)
    return [{"name": name, "axioms": sorted({a.strip() for a in used.split(",") if a.strip()})}
            for name, used in found]

def verify_job_log(raw, inventory, receipt, reports, statuses):
    text = normalized_job_log(raw)
    lines = text.splitlines()
    build = "Build completed successfully (147 jobs)."
    require(lines.count(build) == 1, "exact successful dependency build boundary required")
    require(lines.count("leanprover/lean4:v4.35.0 installed - Lean (version 4.35.0, "
            "x86_64-unknown-linux-gnu, commit " + LEAN + ", Release)") == 1, "actual pinned Lean log")
    proof_text = "\n".join(lines[lines.index(build) + 1:])
    require(exact(axiom_reports(proof_text), reports), "actual producer job reports differ from ZIP logs")
    require([line for line in lines if line.startswith("PSC1_ARENA_MODEL_PROOF_STATUS ")] == statuses,
            "actual producer job command statuses differ from ZIP")
    for marker, value in (("PSC1_ARENA_MODEL_PROOF_SOURCE: PASS ", inventory),
                          ("PSC1_ARENA_MODEL_PROOF_PREFLIGHT: PASS ", receipt)):
        matches = [line[len(marker):] for line in lines if line.startswith(marker)]
        require(len(matches) == 1 and exact(parse(matches[0]), value),
                "actual producer terminal JSON differs from ZIP: " + marker)
    upload = [
        "With the provided path, there will be 30 files uploaded",
        "Uploaded bytes " + str(ZIP_SIZE),
        "SHA256 digest of uploaded artifact zip is " + ZIP_SHA,
        "Artifact " + NAME + ".zip successfully finalized. Artifact ID " + str(ARTIFACT),
        "Artifact " + NAME + " has been successfully uploaded! Final size is "
            + str(ZIP_SIZE) + " bytes. Artifact ID is " + str(ARTIFACT),
        "Artifact download URL: https://github.com/" + REPO + "/actions/runs/"
            + str(RUN) + "/artifacts/" + str(ARTIFACT),
    ]
    require(all(lines.count(line) == 1 for line in upload), "exact producer upload evidence required")
    indices = [lines.index(line) for line in upload]
    receipt_at = next(i for i, line in enumerate(lines)
                      if line.startswith("PSC1_ARENA_MODEL_PROOF_PREFLIGHT: PASS "))
    require(receipt_at < indices[0] and indices == sorted(indices), "producer upload order")
    require(not re.search(r"\.lean:\d+:\d+: error:", text)
            and not any(line.startswith("##[error]") for line in lines), "producer error diagnostic")
    return {"bytes": len(raw), "sha256": hashlib.sha256(raw).hexdigest(),
            "orderedProofReports": len(reports), "proofCommandStatuses": 8,
            "sourceAndNativeReceiptsMatched": True, "artifactUploadMatched": True}

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
    _, entries = zip_members(raw)
    write_json(out / "raw-zip-members.json", entries)
    job_log = download("/actions/jobs/" + str(JOB) + "/logs", 2_000_000)
    job_log.decode("utf-8-sig")
    (out / "producer-job.log").write_bytes(job_log)
    for name in (WORKFLOW, AUDITOR):
        dest = out / "audit-sources" / name
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(audit / name, dest)
    prepared = {"auditIdentity": identity(audit), "targetSourceSha": SOURCE,
                "targetRunId": RUN, "targetRunAttempt": ATTEMPT, "artifactId": ARTIFACT,
                "apiMetadata": digest((out / "api-metadata.json").read_bytes()),
                "rawZip": digest(raw), "producerJobLog": digest(job_log),
                "zipReader": "python-stdlib-zipfile", "crcVerified": True, "zipMembers": 30}
    write_json(out / "prepared.json", prepared)
    print("PSC1_ARENA_MODEL_ARTIFACT_PREPARED " + json.dumps(prepared, separators=(",", ":")))

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
    members, entries = zip_members(raw)
    require(exact(read_json(out / "raw-zip-members.json"), entries), "raw ZIP member manifest changed")
    job_log = (out / "producer-job.log").read_bytes()
    require(exact(prepared["producerJobLog"], digest(job_log)), "producer job log changed")
    extracted = out / "extracted"
    require(extracted.is_dir() and not extracted.is_symlink(), "official extraction directory required")
    expected = expected_members()
    directories = {str(parent) for name in expected for parent in pathlib.PurePosixPath(name).parents
                   if str(parent) != "."}
    actual = set()
    for path in extracted.rglob("*"):
        name = path.relative_to(extracted).as_posix()
        require(not path.is_symlink(), "symlink in official extraction")
        if path.is_dir():
            require(name in directories, "unexpected extracted directory: " + name)
        else:
            require(stat.S_ISREG(path.stat().st_mode), "nonregular extracted member")
            actual.add(name)
    require(actual == expected, "exact 30 officially extracted files required")
    require(all((extracted / name).read_bytes() == members[name] for name in expected),
            "official extraction differs from independently read ZIP bytes")
    source_rows = []
    for name, expected_blob in BLOBS.items():
        value = members["sources/" + name]
        require(value == (target / name).read_bytes()
                and value == git(target, "show", "HEAD:" + name),
                "source bytes differ from exact Git target: " + name)
        require(blob(value) == expected_blob, "pinned Git blob mismatch: " + name)
        source_rows.append({"path": name, **digest(value), "gitBlobSha": blob(value)})
    inventory = parse(members["source-inventory.json"])
    expected_inventory = {"schema": "psc1-arena-model-proof-source-v1", "sourceSha": SOURCE,
        "runId": str(RUN), "runAttempt": str(ATTEMPT), "leanGitHash": LEAN, "baselineSha": BASE,
        "retainedReplaySha": "0b9d2086382cedddc8b8d9b9ab798e9525bf6ba1",
        "retainedLocalReplayProofUnchanged": True,
        "retainedSemanticPrefixSha": "58f900330404dfc8d441b856b1c22ca29145570e",
        "retainedSemanticPrefixProofUnchanged": True,
        "retainedDecodedNodeSha": "25cff6f2ad8fa6cd8b24b8c9241d9c6e3028089b",
        "retainedDecodedNodeProofUnchanged": True,
        "productionSourceTree": TREE, "productionAndRetainedProofsUnchanged": True, "files": source_rows}
    require(exact(inventory, expected_inventory), "source receipt differs from authenticated source inventory")
    proof_records, all_names, all_reports, statuses = [], [], [], []
    allowed = {"propext", "Classical.choice", "Quot.sound"}
    for module, count in MODULES:
        proof = members["sources/psc1/test/" + module + ".lean"]
        names = re.findall(r"(?m)^#print axioms ([A-Za-z0-9_.]+)[ \t]*$", proof.decode("utf-8"))
        names = [name if "." in name else module + "." + name for name in names]
        require(len(names) == count and len(set(names)) == count, "source proof inventory: " + module)
        if module == "PsKernelExprV2ReplayMetadataProofs":
            require(names == [module + "." + name for name in REPLAY_NAMES], "four exact local replay theorems")
        if module == "PsKernelExprV2SemanticPrefixProofs":
            require(names == [module + "." + name for name in PREFIX_NAMES], "eight exact semantic-prefix theorems")
        if module == "PsKernelExprV2DecodedNodeProofs":
            require(names == [module + "." + name for name in NODE_NAMES], "two exact production node theorems")
        if module == "PsKernelExprV2DecodedBridgeProofs":
            require(names == [module + "." + name for name in BRIDGE_NAMES], "twelve exact production decoder theorems")
        proof_log = members[proof_log_name(module)]
        text = proof_log.decode("utf-8")
        reports = axiom_reports(text)
        require([row["name"] for row in reports] == names, "ordered actual proof reports: " + module)
        require(not any(word in text for word in ("sorryAx", "Lean.ofReduceBool", "Lean.trustCompiler"))
                and not re.search(r"\.lean:\d+:\d+: error:", text), "forbidden proof diagnostic: " + module)
        require(all(set(row["axioms"]) <= allowed for row in reports), "nonstandard proof axiom: " + module)
        all_names.extend(names)
        all_reports.extend(reports)
        proof_records.append({"module": module, "proofs": count, "names": names,
                              "source": digest(proof), "log": digest(proof_log)})
        statuses.append("PSC1_ARENA_MODEL_PROOF_STATUS module=" + module
                        + " count=" + str(count) + " countStatus=0 leanStatus=0")
    require(len(all_names) == 73 and len(set(all_names)) == 73, "exact 73 distinct reports")
    require(members["proof-status.log"].decode("utf-8") == "\n".join(statuses) + "\n",
            "exact eight successful proof command statuses")
    build = members["native-build.log"].decode("utf-8")
    require("Build completed successfully (147 jobs)." in build
            and not re.search(r"\.lean:\d+:\d+: error:", build), "dependency build log did not succeed")
    receipt = parse(members["native-receipt.json"])
    expected_receipt = {"schema": "psc1-arena-model-preflight-v1", "sourceSha": SOURCE,
        "runId": str(RUN), "runAttempt": str(ATTEMPT), "status": "pass", "proofModules": 8,
        "totalProofs": 73, "proofs": proof_records, "sourceInventory": digest(members["source-inventory.json"]),
        "proofStatuses": digest(members["proof-status.log"]), "orderedUniqueReports": True,
        "allowedStandardAxiomsOnly": True, **FLAGS}
    require(exact(receipt, expected_receipt), "native receipt or truthful scope mismatch")
    log_evidence = verify_job_log(job_log, inventory, receipt, all_reports, statuses)
    validate_checkouts(target, audit)
    result = {"schema": "psc1-arena-model-artifact-content-audit-v1", "status": "pass",
        "auditIdentity": identity(audit), "targetSourceSha": SOURCE, "targetRunId": RUN,
        "targetRunAttempt": ATTEMPT, "targetJobId": JOB, "artifactId": ARTIFACT,
        "artifactName": NAME, "artifactZip": {"bytes": ZIP_SIZE, "sha256": ZIP_SHA},
        "officialDownloadAction": DOWNLOAD, "rawZipSha256Verified": True,
        "zipReader": "python-stdlib-zipfile", "crcVerified": True, "safeUniqueRegularPaths": True,
        "independentZipAudit": True, "officialExtractionBytesMatched": True,
        "extractedFiles": 30, "sourceFiles": 18, "proofModules": 8, "proofReports": 73,
        "productionAndRetainedProofsUnchanged": True, "scope": FLAGS,
        "producerJobEvidence": log_evidence, "proofInventory": proof_records,
        "nativeReceipt": digest(members["native-receipt.json"]),
        "sourceInventory": digest(members["source-inventory.json"]),
        "manifest": entries, "errors": []}
    write_json(out / "audit-result.json", result)
    print("PSC1_ARENA_MODEL_ARTIFACT_AUDIT: PASS " + json.dumps(result, separators=(",", ":")))

def main():
    require(len(sys.argv) == 5 and sys.argv[1] in ("prepare", "verify"), "usage: audit.py prepare|verify target audit out")
    target, audit, out = (pathlib.Path(p).resolve() for p in sys.argv[2:])
    workspace = pathlib.Path(os.environ["GITHUB_WORKSPACE"]).resolve()
    require(target == workspace / "target-source" and audit == workspace / "audit-source",
            "dedicated exact checkouts required")
    require(out == pathlib.Path(os.environ["RUNNER_TEMP"]).resolve() / "arena-model-artifact-audit",
            "writes must remain inside audit artifacts")
    (prepare if sys.argv[1] == "prepare" else verify)(target, audit, out)

if __name__ == "__main__":
    main()

