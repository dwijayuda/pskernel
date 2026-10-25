#!/usr/bin/env python3
"""Read-only T05 cohort artifact audit, executed only on a GitHub Linux runner.

This verifies archived evidence and exact Git inputs. It does not compile or run
the compiler/kernel, supply missing qualification, or certify full-kernel completion.
"""
import ast
import hashlib
import io
import json
import os
import pathlib
import re
import stat
import subprocess
import sys
import tarfile
import time
import urllib.error
import urllib.parse
import urllib.request
import zipfile

REPO = "dwijayuda/pskernel"
LEAN = "eb6cafb7290e8bd5f2937522d8d804f58f02bafc"
WORKFLOW = ".github/workflows/psc1-pskernel-t05-header.yml"
ENTRY = "packages/pskernel-core/src/Ps/KernelCore/SelfHost.lean"
EXPECTED_PROOFS = [
    ("PsKernelOrdinaryHeaderStateProofs",49,"header-state-proofs.log"),
    ("PsKernelOrdinaryOccurrenceProofs",15,"occurrence-proofs.log"),
    ("PsKernelCacheScopeProofs",60,"cache-scope-proofs.log"),
    ("PsKernelExprV2SessionProofs",14,"session-proofs.log"),
    ("PsKernelScalarHashWorkerRegression",11,"scalar-hash-native.log"),
    ("PsKernelClosedCacheAnalysisRegression",7,"closed-cache-analysis-proofs.log"),
    ("PsKernelKnotFuelProofs",16,"knot-fuel-proofs.log"),
    ("PsKernelExprV2MetadataProofs",8,"metadata-proofs.log"),
    ("PsKernelExprV2PagedModelProofs",17,"paged-model-proofs.log"),
    ("PsKernelOrdinaryConstructorParamsProofs",17,"constructor-params-proofs.log"),
    ("PsKernelOrdinaryConstructorResultProofs",16,"constructor-result-proofs.log"),
]
SCRIPT_NAMES = [
    "pskernel-ordinary-header-smoke.mjs",
    "pskernel-ordinary-constructor-params-smoke.mjs",
    "pskernel-ordinary-constructor-result-smoke.mjs",
    "pskernel-scalar-hash-worker-smoke.mjs",
    "pskernel-scalar-hash-short-entry-smoke.mjs",
    "pskernel-closed-cache-analysis-smoke.mjs",
    "pskernel-generated-smoke.mjs",
    "pskernel-expr-v2-dag-smoke.mjs",
    "pskernel-expr-v2-generated-prefix-smoke.mjs",
    "pskernel-invalid-recursor-occurrence-smoke.mjs",
]
HEADER_RESULT = {
    "assertions":1992,"headerCases":432,"positiveDirect":10,
    "occurrenceFuelCases":1026,"annotationFuelCases":75,
    "callbackSequences":3,"callbackFailures":24,
    "headerOnly":True,"fullAdmission":False,"publicFallbackUsed":False,
    "sectionAssertions":{"harness":1,"header":444,"occurrence":1378,
        "annotations":94,"state":47,"phases":20,"topCallbacks":8},
}
CACHE_RESULT = {
    "expressions":20,"states":2,"mapQueries":40,"pairQueries":800,
    "inferQueries":80,"assertions":1884,"smallAndIndexed":True,"openEntriesSeeded":True,
}
ROUTES = ("native","generated","canonical")
MAX_ARCHIVE = 512 * 1024 * 1024
MAX_EXPANDED = 2 * 1024 * 1024 * 1024
MAX_MEMBER = 256 * 1024 * 1024
API = "https://api.github.com/repos/" + REPO + "/"
TOKEN = os.environ.get("GH_TOKEN","")
SOURCE_ROOT = pathlib.Path(os.environ["PSC1_AUDIT_SOURCE_ROOT"]).resolve()
OUT = pathlib.Path(os.environ["PSC1_AUDIT_OUTPUT"]).resolve()
CONFIG = json.loads(pathlib.Path(sys.argv[1]).read_text())
SHA = CONFIG["sourceSha"]
RUN = CONFIG["runId"]
ATTEMPT = CONFIG["runAttempt"]
PROFILE = CONFIG.get("profile", "helpers")
RETAINED = PROFILE == "retained"
DEFERRED = PROFILE in ("deferred", "retained")
ADMISSION = PROFILE in ("admission", "deferred", "retained")
FIELDS = PROFILE in ("fields", "analysis", "loop", "admission", "deferred", "retained")
ANALYSIS = PROFILE in ("analysis", "loop", "admission", "deferred", "retained")
LOOP = PROFILE in ("loop", "admission", "deferred", "retained")
SOURCE_INPUT_COUNT = 92 if RETAINED else 82 if DEFERRED else 77 if ADMISSION else 59 if LOOP else 55 if ANALYSIS else 50 if FIELDS else 43
NATIVE_PROOF_TOTAL = 492 if RETAINED else 374 if DEFERRED else 371 if ADMISSION else 310 if LOOP else 296 if ANALYSIS else 277 if FIELDS else 230
NATIVE_PROOF_MODULES = len(EXPECTED_PROOFS) + (2 if FIELDS else 0) + (1 if ANALYSIS else 0) + (1 if LOOP else 0) + (3 if ADMISSION else 0) + (1 if DEFERRED else 0) + (10 if RETAINED else 0)
FIELDS_SECTIONS = {"harness":1,"fields":147,"recursive":105,"boundaries":8,"recursorGuard":7}
ANALYSIS_SECTIONS = {"harness":1,"matrix":84,"protocol":8}
LOOP_SECTIONS = {"harness":1,"matrix":56,"protocol":12}
ANALYSIS_ORACLE_PATH = "psc1/packages/pskernel-core/src/Ps/KernelCore/Admission/Inductive/Ordinary/ConstructorAdmission.lean"
ANALYSIS_ORACLE_SHA256 = "16cce0a367dfa144a56770f76bcb0605d3a370b360175c4f26583387cf2a1723"
ANALYSIS_ORACLE_GIT_BLOB = "cd3b659ad1e597b95a4ac7b69a1ebf126cab4a17"
if FIELDS:
    SCRIPT_NAMES.append("pskernel-ordinary-constructor-fields-smoke.mjs")
if ANALYSIS:
    SCRIPT_NAMES.append("pskernel-ordinary-constructor-analysis-smoke.mjs")
if LOOP:
    SCRIPT_NAMES.append("pskernel-ordinary-constructor-loop-smoke.mjs")
if ADMISSION:
    SCRIPT_NAMES.extend(["pskernel-ordinary-elimination-smoke.mjs",
        "pskernel-ordinary-admission-private-smoke.mjs","pskernel-ordinary-admission-public-smoke.mjs"])
if DEFERRED:
    SCRIPT_NAMES.append("pskernel-expr-v2-transform-delay-smoke.mjs")
DEFERRED_LATER_LOGS = {"deferred-transform.log"} if DEFERRED else set()
ADMISSION_LATER_LOGS = ({"elimination.log","ordinary-admission-private.log","ordinary-admission-public.log"} if ADMISSION else set()) | DEFERRED_LATER_LOGS
ELIMINATION_SECTIONS = {"harness":1,"policy":63,"raw":28,"member":12,"protocol":12}
PRIVATE_ADMISSION_SECTIONS = {"harness":1,"matrix":126,"protocol":16}
PUBLIC_ADMISSION_SECTIONS = {"harness":1,"routing":7,"boundary":4}
ADMISSION_PROOFS = [
    ("PsKernelOrdinaryEliminationProofs",26,"elimination-proofs.log"),
    ("PsKernelOrdinaryAdmissionProofs",27,"ordinary-admission-proofs.log"),
    ("PsKernelOrdinaryAdmissionPublicProofs",8,"ordinary-admission-public-proofs.log")]
ADMISSION_FROZEN_BLOBS = {
    "psc1/packages/pskernel-core/src/Ps/KernelCore/Admission/Inductive/Common/Elimination.lean":"7b896a50da30370d3a185b79f9ffeeaa379bbb9b",
    "psc1/packages/pskernel-core/src/Ps/KernelCore/Admission/Inductive/Common/RecursorValidation.lean":"ae0d498305cab3f253bd53f40d66ae0919420027",
    "psc1/packages/pskernel-core/src/Ps/KernelCore/Admission/Inductive/Ordinary/Recursor.lean":"0db1095805c4e6bc4d0025b073fec1807ebf2206"}
ADMISSION_ORACLE_LABELS = [
    "type-empty","enum-two","direct-recursive","reflexive","parameterized","dependent-index",
    "universe","prop-empty","prop-unit","prop-proof-field","prop-data-field","prop-two",
    "unsafe-reference","safe-prior-reference","duplicate-level-before-mvar",
    "late-wrong-result","negative-function","safe-unsafe-reference"]
PUBLIC_ADMISSION_LABELS = [
    "harness/rejection-active","routing/direct-owner-retained","routing/finish-carries-injected-suffix",
    "routing/decline-restarts-original","routing/hard-error-does-not-fallback","routing/resource-limit-failure",
    "routing/same-batch-recursor-check","routing/cross-call-checked-recursor",
    "boundary/private-generated-id-not-external","boundary/later-command-failure-atomic",
    "boundary/fallback-original-bounds","boundary/preflight-precedence"]
DEFERRED_BASELINE = "10144e2f9e8d223b5dcde275bd1f48d25df113b3"
DEFERRED_PREFIX = "psc1/packages/pskernel-core/src/Ps/KernelCore/Core/ExprV2/"
DEFERRED_MODULE = "PsKernelDeferredTransformProofs"
DEFERRED_PROOF = "psc1/test/" + DEFERRED_MODULE + ".lean"
DEFERRED_HARNESS = "pskernel-expr-v2-transform-delay-smoke.mjs"
DEFERRED_NAMES = [DEFERRED_MODULE+"."+name for name in
    ("transform_with_fuel_eq","count_with_fuel_eq","lift_with_fuel_eq")]
DEFERRED_WORKERS = [
    ("Transform.lean","8f50a74edf1d00288efee9c559a05a75b755acbf",
     "psKernelExprV2TransformWithFuel",
     "      let smaller := psKernelExprV2TransformWithFuel remaining;\n",
     "        (state : PsKernelExprV2TransformState) (source offset : Nat) =>\n",
     "        let smaller := psKernelExprV2TransformWithFuel remaining;\n"),
    ("TransformSupport.lean","7957a3aaf87f440b6fb09c2ee98eb574aeab6c72",
     "psKernelExprV2TransformCountWithFuel",
     "      let smaller := psKernelExprV2TransformCountWithFuel remaining;\n",
     "          (memo : List PsKernelExprV2TransformCountMemo) (root : Nat) =>\n",
     "        let smaller := psKernelExprV2TransformCountWithFuel remaining;\n"),
    ("Lift.lean","50a63d2729088039a3b01f75eda5c6e83f91e036",
     "psKernelExprV2PagedLiftWithFuel",
     "      let smaller :\n          PsKernelExprV2PagedLiftState -> Nat -> Nat -> Nat ->\n          Except String (PsKernelExprV2PagedLiftState × Nat) :=\n        psKernelExprV2PagedLiftWithFuel remaining;\n",
     "            fun (amount : Nat) =>\n",
     "              let smaller :\n                  PsKernelExprV2PagedLiftState -> Nat -> Nat -> Nat ->\n                  Except String (PsKernelExprV2PagedLiftState × Nat) :=\n                psKernelExprV2PagedLiftWithFuel remaining;\n"),
]
DEFERRED_BLOBS = {DEFERRED_PREFIX+short:oid for short,oid,*_ in DEFERRED_WORKERS}
DEFERRED_INPUTS = list(DEFERRED_BLOBS) + [DEFERRED_PROOF,"psc1/scripts/"+DEFERRED_HARNESS]
DEFERRED_SECTIONS = {"harness":1,"staged":3,"transform":6,"count":6,"lift":7}
DEFERRED_LABELS = [
    "harness-real-canonical-shared-app",
    "staged-transform-all-four-arrows",
    "staged-count-all-three-arrows",
    "staged-lift-all-four-arrows",
    "raw-transform-zero-preserves-owner-and-id",
    "raw-transform-zero-still-requires-root",
    "raw-transform-successor-root-before-memo",
    "raw-transform-successor-memo-preserves-full-owner",
    "raw-transform-one-retains-zero-budget-children",
    "raw-transform-two-threads-shared-child-memo-and-ids",
    "raw-count-zero-before-memo",
    "raw-count-zero-before-root-validation",
    "raw-count-one-leaf",
    "raw-count-one-child-exhaustion",
    "raw-count-one-invalid-root",
    "raw-count-successor-internal-memo-before-root",
    "raw-lift-zero-before-zero-amount",
    "raw-lift-successor-zero-amount-before-root",
    "raw-lift-successor-root-before-memo",
    "raw-lift-loose-range-prune-before-memo",
    "raw-lift-valid-memo-preserves-full-owner",
    "raw-lift-one-child-exhaustion",
    "raw-lift-two-threads-shared-child-memo-and-ids"
]

RETAINED_PROOFS = [(module,count,"retained-"+module+".log") for module,count in [
    ("PsKernelNatFuelProofs",5),("PsKernelExprEqualityProofs",4),
    ("PsKernelExprV2AdmissionGuardProofs",18),("PsKernelExprV2RecursorProofs",23),
    ("PsKernelExprV2RecursorMajorProofs",10),("PsKernelExprV2RecursorKProofs",6),
    ("PsKernelNameWorkerProofs",8),("PsKernelExprV2QuotOwnerProofs",21),
    ("PsKernelExprV2WhnfABIProofs",2),("PsKernelExprV2OwnedStateProofs",21)]]
RETAINED_INPUTS = ["psc1/test/"+module+".lean" for module,_,_ in RETAINED_PROOFS]

BLOBS = {}
REPORT = {
    "schema":"psc1-t05-artifact-audit-v1",
    "status":"in_progress","repository":REPO,"sourceSha":SHA,
    "runId":RUN,"runAttempt":ATTEMPT,
    "auditSourceSha":os.environ.get("GITHUB_SHA"),
    "auditRunId":os.environ.get("GITHUB_RUN_ID"),
    "auditRunAttempt":os.environ.get("GITHUB_RUN_ATTEMPT"),
    "sourceExecution":"none; artifact and Git-byte inspection only",
    **({"ordinaryAdmissionTarget":True,"fullKernel":False} if ADMISSION else {"fullAdmission":False}),
    "performanceQualified":False,"replayArenaModelBridgeEstablished":False,
    "canonicalClaim":"manifest closure, membership and content hashes; no new semantic equivalence proof",
    "routes":{},"errors":[],
}


def require(ok, message):
    if not ok:
        raise RuntimeError(message)


def exact(a, b):
    if type(a) is not type(b):
        return False
    if isinstance(a,dict):
        return a.keys() == b.keys() and all(exact(a[k],b[k]) for k in a)
    if isinstance(a,list):
        return len(a) == len(b) and all(exact(x,y) for x,y in zip(a,b))
    return a == b


def same(a, b, label):
    require(exact(a,b), "Mismatch: " + label)


def digest(raw):
    return {"bytes":len(raw),"sha256":hashlib.sha256(raw).hexdigest()}


def git_blob_sha(raw):
    return hashlib.sha1(b"blob " + str(len(raw)).encode() + b"\0" + raw).hexdigest()


def safe_path(name, tar=False, directory=False):
    require(isinstance(name,str) and bool(name),"Empty archive path")
    require("\\" not in name and "\0" not in name,"Invalid archive path separator")
    require(not name.startswith("/") and not re.match(r"^[A-Za-z]:",name),
            "Absolute archive path")
    if tar:
        while name.startswith("./"):
            name = name[2:]
        if name in ("",".") and directory:
            return ""
    name = name.rstrip("/") if directory else name
    require(name and all(p not in ("",".","..") for p in name.split("/")),
            "Unsafe archive path: " + name)
    return name


def git_bytes(path):
    path = safe_path(path)
    if path not in BLOBS:
        raw = subprocess.check_output(
            ["git","-C",str(SOURCE_ROOT),"cat-file","blob",SHA + ":" + path])
        oid = subprocess.check_output(
            ["git","-C",str(SOURCE_ROOT),"rev-parse",SHA + ":" + path],
            text=True).strip()
        require(git_blob_sha(raw) == oid,"Git blob object mismatch: " + path)
        BLOBS[path] = raw
    return BLOBS[path]


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def read_response(response, limit):
    length = response.headers.get("Content-Length")
    require(length is None or int(length) <= limit,"Download exceeds audit resource cap")
    raw = response.read(limit + 1)
    require(len(raw) <= limit,"Download exceeds audit resource cap")
    return raw


def request(path, limit=MAX_ARCHIVE):
    """Authenticate only to the GitHub API; never forward token to blob storage."""
    url = API + path
    req = urllib.request.Request(url,headers={
        "Accept":"application/vnd.github+json",
        "Authorization":"Bearer " + TOKEN,
        "X-GitHub-Api-Version":"2022-11-28",
        "User-Agent":"psc1-t05-artifact-audit",
    })
    for retry in range(4):
        try:
            with urllib.request.build_opener(NoRedirect).open(req,timeout=120) as response:
                return read_response(response,limit)
        except urllib.error.HTTPError as error:
            if error.code in (301,302,303,307,308):
                location = error.headers.get("Location","")
                parsed = urllib.parse.urlparse(location)
                require(parsed.scheme == "https" and parsed.hostname and
                        parsed.username is None and parsed.password is None,
                        "Invalid GitHub download redirect")
                unsigned = urllib.request.Request(location,headers={
                    "User-Agent":"psc1-t05-artifact-audit"})
                with urllib.request.urlopen(unsigned,timeout=180) as response:
                    return read_response(response,limit)
            if error.code in (429,500,502,503,504) and retry < 3:
                time.sleep(5 * (retry + 1))
                continue
            raise RuntimeError("GitHub GET failed: " + path + " HTTP " + str(error.code)) from None
        except (TimeoutError,urllib.error.URLError):
            if retry == 3:
                raise RuntimeError("GitHub GET failed after retry: " + path) from None
            time.sleep(5 * (retry + 1))


def api(path):
    return json.loads(request(path,16 * 1024 * 1024))


def pages(path, key):
    values = []
    for page in range(1,101):
        data = api(path + ("&" if "?" in path else "?") +
                   "per_page=100&page=" + str(page))
        current = data[key]
        values.extend(current)
        if len(current) < 100:
            return values
    raise RuntimeError("Unexpected GitHub pagination size")


def clean_terminal(raw):
    text = raw.decode("utf-8-sig")
    text = re.sub(r"\x1b\[[0-9;]*m","",text)
    return "\n".join(re.sub(r"^\d{4}-\d\d-\d\dT[\d:.]+Z ","",line)
                     for line in text.splitlines())


def one_json_line(text, prefix):
    rows = [json.loads(line[len(prefix):]) for line in text.splitlines()
            if line.startswith(prefix)]
    require(len(rows) == 1,"Expected one JSON marker: " + prefix)
    return rows[0]


def logged_json(text, prefix, expected):
    same(one_json_line(text,prefix),expected,"terminal " + prefix)


def line_marker(text, marker):
    require(text.splitlines().count(marker) == 1,
            "Expected one exact marker: " + marker)


def substring_marker(text, marker):
    require(marker in text,"Missing retained marker: " + marker)


def unzip(raw):
    result = {}
    seen = set()
    with zipfile.ZipFile(io.BytesIO(raw)) as archive:
        infos = archive.infolist()
        require(len(infos) <= 10000,"Unexpected ZIP member count")
        require(sum(info.file_size for info in infos) <= MAX_EXPANDED,"Expanded ZIP too large")
        for info in infos:
            name = safe_path(info.filename,directory=info.is_dir())
            require(name not in seen,"Duplicate ZIP member: " + name)
            seen.add(name)
            mode = info.external_attr >> 16
            require(stat.S_IFMT(mode) in (0,stat.S_IFREG,stat.S_IFDIR),
                    "ZIP links/special files prohibited")
            require(not info.flag_bits & 1,"Encrypted ZIP member prohibited")
            require(info.file_size <= MAX_MEMBER,"ZIP member exceeds cap")
            if not info.is_dir():
                result[name] = archive.read(info)  # zipfile checks this member's CRC.
        require(archive.testzip() is None,"ZIP CRC failure")
    require(result,"Empty artifact ZIP")
    return result


def untar(raw):
    result = {}
    seen = set()
    total = 0
    with tarfile.open(fileobj=io.BytesIO(raw),mode="r:gz") as archive:
        for member in archive:
            require(member.isfile() or member.isdir(),"Archive links/special files prohibited")
            name = safe_path(member.name,tar=True,directory=member.isdir())
            if name == "":
                continue
            require(name not in seen,"Duplicate tar member: " + name)
            seen.add(name)
            total += member.size
            require(member.size <= MAX_MEMBER and total <= MAX_EXPANDED,
                    "Expanded tar exceeds audit resource cap")
            if member.isfile():
                handle = archive.extractfile(member)
                require(handle is not None,"Unreadable archive member")
                raw_member = handle.read(MAX_MEMBER + 1)
                require(len(raw_member) == member.size,"Incomplete tar member")
                result[name] = raw_member
    return result


class Evidence:
    def __init__(self, files, route, terminal):
        self.files = files
        self.route = route
        self.terminal = terminal

    def raw(self, path):
        require(path in self.files,"Missing " + self.route + " file: " + path)
        return self.files[path]

    def text(self, path):
        return self.raw(path).decode("utf-8-sig")

    def json(self, path):
        return json.loads(self.raw(path))

    def check_digest(self, path, expected):
        same(digest(self.raw(path)),expected,self.route + ":" + path + " digest")

    def log_digests(self, records, expected_names=None):
        require(isinstance(records,dict) and bool(records),"Missing receipt log digests")
        if expected_names is not None:
            same(sorted(records),sorted(expected_names),"complete receipt log inventory")
        for name, expected in records.items():
            require("/" not in name and name.endswith(".log"),"Invalid receipt log name")
            self.check_digest(name,expected)

    def identity(self, value, job=True):
        expected = {"sourceSha":SHA,"runId":str(RUN),"runAttempt":str(ATTEMPT),
                    "route":self.route}
        if job:
            expected["job"] = "native-header" if self.route == "native" else "generated-header"
        for key, wanted in expected.items():
            same(value.get(key),wanted,self.route + " identity " + key)


def source_inventory(e, expected_paths, frozen):
    inv = e.json("source-inventory.json")
    same(inv.get("schema"),"psc1-t05-header-source-inventory-v1","source inventory schema")
    e.identity(inv)
    same(inv.get("repository"),REPO,"source inventory repository")
    same(inv.get("leanCommit"),LEAN,"source inventory Lean commit")
    records = inv["files"]
    same([r["path"] for r in records],expected_paths,"copied source path inventory")
    same(len(records),SOURCE_INPUT_COUNT,"source input count")
    expected_members = {"sources/" + p for p in expected_paths}
    same(sorted(k for k in e.files if k.startswith("sources/")),
         sorted(expected_members),"copied-source artifact membership")
    for record in records:
        path = record["path"]
        original = git_bytes(path)
        same(e.raw("sources/" + path),original,"source Git bytes " + path)
        same(record,{"path":path,**digest(original),"gitBlobSha":git_blob_sha(original)},
             "source inventory entry " + path)
        if path in frozen:
            same(digest(original)["sha256"],frozen[path],"frozen original " + path)
    logged_json(e.terminal,"PSC1_T05_SOURCE_INVENTORY ",inv)
    same(e.text("lean-githash.txt").strip(),LEAN,"Lean binary commit pin")
    require("4.35.0" in e.text("lean-version.txt"),"Lean version pin")
    require(re.fullmatch(r"v22\.\d+\.\d+",e.text("node-version.txt").strip()) is not None,
            "Node22 pin")
    return {"files":len(records),"allGitBytesMatched":True,
            "inventory":digest(e.raw("source-inventory.json")),
            "frozenReferences":len(frozen) + (3 if ADMISSION else 0)}


def proof_reports(source, raw, module, count):
    names = re.findall(r"^#print axioms ([A-Za-z0-9_.$]+)\s*$",source.decode(),re.M)
    names = [n if "." in n else module + "." + n for n in names]
    require(len(names) == count and len(set(names)) == count,
            "Exact unique proof source names: " + module)
    text = raw.decode()
    reports = re.findall(
        r"'([^']+)' (?:does not depend on any axioms|depends on axioms:\s*\[([^\]]*)\])",text)
    same([name for name,_ in reports],names,"ordered proof reports " + module)
    require(not any(x in text for x in ("sorryAx","Lean.ofReduceBool","Lean.trustCompiler")),
            "Forbidden proof dependency: " + module)
    require(not re.search(r"\.lean:\d+:\d+: error:",text),"Lean proof diagnostic")
    allowed = {"propext","Classical.choice","Quot.sound"}
    for name, used in reports:
        require({x.strip() for x in used.split(",") if x.strip()} <= allowed,
                "Unexpected proof axiom: " + name)
    return names


def native_audit(e):
    receipt = e.json("constructor-native-receipt.json")
    previous = e.json("native-receipt.json")
    e.identity(receipt)
    e.identity(previous)
    same(receipt.get("schema"),"psc1-t05-constructor-native-receipt-v1","native constructor schema")
    same(previous.get("schema"),"psc1-t05-header-native-receipt-v1","native header schema")
    for key, expected in {
        "status":"pass","newProofs":50,"retainedProofs":180,"totalProofs":230,
        "orderedUniqueReports":True,"allowedStandardAxiomsOnly":True,
        "headerOnly":False,"constructorHelpersOnly":True,"fullAdmission":False,
        "publicRoutingChanged":False,"replayArenaModelBridgeEstablished":False,
        "constructorNativeAssertions":{"params":284,"result":432},
    }.items():
        same(receipt.get(key),expected,"native constructor " + key)
    for key, expected in {
        "newProofs":64,"retainedProofs":108,"totalProofs":172,
        "orderedUniqueReports":True,"allowedStandardAxiomsOnly":True,
        "headerOnly":True,"fullAdmission":False,
    }.items():
        same(previous.get(key),expected,"native header " + key)
    audits = []
    prior = []
    for index,(module,count,filename) in enumerate(EXPECTED_PROOFS):
        source = git_bytes("psc1/test/" + module + ".lean")
        raw = e.raw(filename)
        names = proof_reports(source,raw,module,count)
        audits.append({"module":module,"proofs":count,"names":names,
                       "source":digest(source),"log":digest(raw)})
        if index < 7:
            prior.append({"module":module,"proofs":count,"names":names,
                          "logSha256":digest(raw)["sha256"]})
    same(receipt["proofs"],audits,"native230 proof audit receipt")
    same(previous["proofs"],prior,"retained172 proof audit receipt")
    same(e.text("constructor-proof-status.log").splitlines(),[
        "PSC1_T05_CONSTRUCTOR_PROOF_STATUS module=" + module + " count=" + str(count) +
        " countStatus=0 leanStatus=0" for module,count,_ in EXPECTED_PROOFS[-4:]
    ],"four native command statuses")
    line_marker(e.text("new-header-proof-status.log"),
                "PSC1_T05_NEW_PROOF_RESULTS stateCount=0 stateLean=0 occurrenceCount=0 occurrenceLean=0")
    e.check_digest("native-receipt.json",receipt["retainedHeaderReceipt"])
    e.log_digests(receipt["constructorNativeLogs"],
                  ["constructor-params-native.log","constructor-result-native.log"])
    e.check_digest("constructor-params-native-inventory.json",receipt["paramsNativeInventory"])
    params = e.json("constructor-params-native-inventory.json")
    e.identity(params,job=False)
    for key, expected in {
        "schema":"psc1-t05-constructor-params-native-inventory-v1",
        "assertions":284,"groupAssertions":{"direct":227,"owner":21,"boundaries":28,"faults":8},
        "directSuccess":11,"prefixOnly":True,"fullAdmission":False,
    }.items():
        same(params.get(key),expected,"native Params " + key)
    lines = e.text("constructor-params-native.log").splitlines()
    prefix = "PSC1_ORDINARY_CONSTRUCTOR_PARAMS_ASSERT "
    labels = [line[len(prefix):] for line in lines if line.startswith(prefix)]
    require(len(labels) == 284 and all(labels),"284 executed native Params assertions")
    same(params["assertionLabels"],labels,"native Params assertion labels")
    same(params["logSha256"],digest(e.raw("constructor-params-native.log"))["sha256"],
         "native Params log digest")
    groups = [
        (227,"PSC1_ORDINARY_CONSTRUCTOR_PARAMS_V1_NATIVE: PASS comparisons=216 directSuccess=11 assertions=227"),
        (21,"PSC1_ORDINARY_CONSTRUCTOR_PARAMS_OWNER_NATIVE: PASS ownerFields=10 callbacks=3 propagated=9 assertions=21"),
        (28,"PSC1_ORDINARY_CONSTRUCTOR_PARAMS_BOUNDARY_NATIVE: PASS boundaries=17 nonForall=11 assertions=28"),
        (8,"PSC1_ORDINARY_CONSTRUCTOR_PARAMS_FAULT_NATIVE: PASS injectedBrokenOwners=8 assertions=8"),
    ]
    start = -1
    for count,marker in groups:
        require(lines.count(marker) == 1,"Native Params group marker")
        end = lines.index(marker)
        require(end > start and sum(x.startswith(prefix) for x in lines[start+1:end]) == count,
                "Ordered native Params group count")
        start = end
    final = "PSC1_ORDINARY_CONSTRUCTOR_PARAMS_REGRESSION: PASS assertions=284 directSuccess=11 prefixOnly=true fullAdmission=false"
    require(lines.count(final) == 1 and lines.index(final) > start,"Native Params final marker")
    for marker in [
        "PSC1_ORDINARY_CONSTRUCTOR_RESULT_NATIVE: PASS assertions=432 selectorRows=46 occurrenceTerms=30 targets=2 fullAdmission=false",
        "PSC1_ORDINARY_CONSTRUCTOR_RESULT_SECTIONS: PASS harness=1 selector=138 consumer=26 occurrence=240 bounds=16 indexLists=7 precedence=4",
    ]:
        line_marker(e.text("constructor-result-native.log"),marker)
    for marker in [
        "PSC1_ORDINARY_HEADER_NATIVE: PASS matrix=432 positiveDirect=10 crossFault=2 headerOnly=true",
        "PSC1_ORDINARY_OCCURRENCE_NATIVE: PASS heads=171 fuelCases=1026 wrappers=171 sharedOffsets=2",
        "PSC1_ORDINARY_ANNOTATIONS_NATIVE: PASS fuelCases=75 wrappers=15 invalidIDs=2",
        "PSC1_ORDINARY_HEADER_STATE_NATIVE: PASS sequences=3 propagated=24 forkFields=all boundaries=3",
        "PSC1_ORDINARY_HEADER_ORACLE: PASS accepted=4 rejected=2 headerOnly=true",
        "PSC1_ORDINARY_HEADER_REGRESSION: PASS headerOnly=true fullAdmission=false",
    ]:
        line_marker(e.text("header-native.log"),marker)
    for marker in [
        "PSC1_SCALAR_HASH_WORKER_NATIVE: PASS cases=2730 strings=12",
        "PSC1_SCALAR_HASH_LONG_NATIVE: PASS cases=3",
    ]:
        line_marker(e.text("scalar-hash-native.log"),marker)
    for marker in [
        "PSKERNEL_KNOT_FUEL_PROOFS: PASS workers=15",
        "PSKERNEL_WHNFCACHE_MODE_PROOFS: PASS allModes=correctedEager fullMode=historical",
    ]:
        line_marker(e.text("knot-fuel-proofs.log"),marker)
    substring_marker(e.text("dag-native.log"),"PSC1_V2_DAG_REGRESSION: PASS")
    for marker in [
        "PSC1_V2_GENERATED_PREFIX: PASS new=24 recursors=7 direct=6 privateIDs=3",
        "PSC1_V2_GENERATED_PREFIX_OFFICIAL: PASS families=5 positive=6 negative=7",
        "PSC1_V2_SESSION_OWNERS: PASS kinds=8 direct=7 privateIDs=5 forks=2",
        "PSC1_V2_SESSION_OWNERS_OFFICIAL: PASS declarations=4 direct=7",
    ]:
        line_marker(e.text("prefix-native.log"),marker)
    logged_json(e.terminal,"PSC1_T05_HEADER_NATIVE_PROOFS: PASS ",previous)
    logged_json(e.terminal,"PSC1_T05_CONSTRUCTOR_NATIVE_PROOFS: PASS ",receipt)
    return {"reports":230,"sourceNamedOrderedUnique":True,"allowedStandardAxiomsOnly":True,
            "nativeParamsAssertions":284,"nativeResultAssertions":432,
            "retainedControls":True,"receipt":digest(e.raw("constructor-native-receipt.json"))}


def lean_closure():
    layout = git_bytes("psc1/scripts/workspace-layout.mjs").decode()
    packages = dict(re.findall(r'\["([A-Za-z0-9]+)", "([a-z0-9-]+)"\]',layout))
    require(packages.get("KernelCore") == "pskernel-core","Workspace package mapping")
    visited = set()

    def visit(path):
        if path in visited:
            return
        visited.add(path)
        text = git_bytes("psc1/" + path).decode()
        imports = re.findall(r"^\s*import\s+([A-Za-z0-9_.]+)\s*;?\s*$",text,re.M)
        for module in imports:
            parts = module.split(".")
            if parts[0] == "ProofScript":
                child = "stdlib/" + "/".join(parts) + ".lean"
            else:
                require(parts[0] == "Ps" and len(parts) > 1 and parts[1] in packages,
                        "Unknown closure import: " + module)
                child = "packages/" + packages[parts[1]] + "/src/" + "/".join(parts) + ".lean"
            visit(child)
    visit(ENTRY)
    return sorted(visited)


def closure_audit(e, closure):
    manifest = e.json("lean-source-manifest.json")
    e.identity(manifest,job=False)
    same(manifest.get("schema"),"psc1-t05-lean-source-closure-v1","Lean closure schema")
    same(manifest.get("entry"),ENTRY,"Lean closure entry")
    same(manifest.get("sourceCount"),len(closure),"Lean closure count")
    records = [{"path":p,**digest(git_bytes("psc1/" + p))} for p in closure]
    same(manifest.get("files"),records,"exact actual Lean import closure")
    expected_members = {"lean-source/" + p for p in closure}
    same(sorted(k for k in e.files if k.startswith("lean-source/")),
         sorted(expected_members),"Lean closure copied members")
    archive = untar(e.raw("lean-source.tar.gz"))
    same(sorted(archive),closure,"Lean source tar exact membership")
    for path in closure:
        original = git_bytes("psc1/" + path)
        same(e.raw("lean-source/" + path),original,"Lean closure Git bytes " + path)
        same(archive[path],original,"Lean tar Git bytes " + path)
    line_marker(e.terminal,"PSC1_T05_LEAN_SOURCE_CLOSURE: PASS modules=" + str(len(closure)))
    result = {"leanModules":len(closure),"actualImportClosure":True,
              "leanFilesAndArchiveMatchGit":True,"leanArchive":digest(e.raw("lean-source.tar.gz"))}
    if e.route == "canonical":
        canonical = e.json("canonical-manifest.json")
        ps_paths = sorted(p[:-5] + ".ps" for p in closure)
        for key,expected in {
            "schemaVersion":2,"generation":"bootstrap","entry":ENTRY[:-5]+".ps",
            "sourceCount":len(ps_paths),"generated":ps_paths,
        }.items():
            same(canonical.get(key),expected,"canonical manifest " + key)
        archive = untar(e.raw("canonical-source.tar.gz"))
        same(sorted(archive),sorted(ps_paths + [".proofscript-bootstrap.json"]),
             "canonical archive exact membership")
        same(archive[".proofscript-bootstrap.json"],e.raw("canonical-manifest.json"),
             "canonical embedded manifest bytes")
        value = hashlib.sha256()
        value.update(b"proofscript-bootstrap-closure-v2\0")
        value.update(canonical["entry"].encode())
        value.update(b"\0")
        canonical_files = []
        for path in ps_paths:
            text = archive[path].decode("utf-8")  # Reject invalid UTF-8 source bytes.
            value.update(path.encode())
            value.update(b"\0")
            value.update(text.encode())
            value.update(b"\0")
            canonical_files.append({"path":path,**digest(archive[path])})
        same(canonical.get("closureSha256"),value.hexdigest(),"canonical closure content hash")
        line_marker(e.terminal,"PSKERNEL_CANONICAL_PS_SOURCES: PASS modules=" + str(len(ps_paths)))
        result.update({"canonicalModules":len(ps_paths),"canonicalClosureSha256":value.hexdigest(),
                       "canonicalFiles":canonical_files,
                       "canonicalArchive":digest(e.raw("canonical-source.tar.gz"))})
    return result


def measurement(e, path):
    value = e.text(path).strip()
    match = re.fullmatch(r"peak_rss_kib=(\d+) wall_seconds=(\d+(?:\.\d+)?) exit_status=0",value)
    require(match is not None and float(match[2]) < 1500,
            "Expected successful runtime within retained 25-minute cap: " + path)
    return {"measurement":value,"peakRssKiB":int(match[1]),"wallSeconds":float(match[2])}


def route_controls(e):
    same(one_json_line(e.text("closed-cache-analysis.log"),
                       "PSC1_CLOSED_CACHE_ANALYSIS_JS: PASS "),CACHE_RESULT,"cache1884")
    line_marker(e.text("scalar-hash.log"),"PSC1_SCALAR_HASH_LONG_JS: PASS cases=3")
    require(any(x.startswith("PSC1_SCALAR_HASH_WORKER_JS: PASS ")
                for x in e.text("scalar-hash.log").splitlines()),"Scalar hash worker gate")
    short = 'PSC1_SCALAR_HASH_SHORT_ENTRY_JS: PASS {"cases":19,"assertions":38,"shortMaxPairs":4,"genericFallback":true}'
    line_marker(e.text("short-entry.log"),short)
    for marker in ["PSKERNEL_GENERATED_COMPLETE_CHECKER: PASS","PSKERNEL_GENERATED_SMOKE: PASS"]:
        line_marker(e.text("generated-smoke.log"),marker)
    require(re.search(r"^PSC1_INVALID_RECURSOR_OCCURRENCE_JS: PASS [0-9]+ invalid/reducible/nonrecursive/erased/unsafe/nested/resource/publication controls$",
                      e.text("invalid-recursor.log"),re.M) is not None,"Invalid recursor retained controls")
    for marker in [
        "PSC1_V2_GENERATED_PREFIX_JS: PASS new=24 recursors=7 direct=6 privateIDs=3",
        "PSC1_V2_SESSION_OWNERS_JS: PASS kinds=8 direct=7 privateIDs=5 forks=2",
    ]:
        line_marker(e.text("prefix.log"),marker)
    require(re.search(r"^PSC1_V2_GENERATED_PREFIX_CONTROLS_JS: PASS positive=6 negative=7 assertions=[0-9]+$",
                      e.text("prefix.log"),re.M) is not None,"Prefix retained positive/negative controls")
    dag = e.text("dag.log")
    for marker in [
        "PSC1_V2_DAG_JS: PASS",
        "PSC1_EXPR_EQUALITY_DELAYED_JS: PASS hostile=21 staged=2 sharedDepth=64",
        "PSC1_V2_TRANSFORM_JS: PASS",
    ]:
        substring_marker(dag,marker)
    line_marker(dag,"PSC1_V2_DAG_JS_WHNF_STAGED_ABI: PASS exports=2 partials=4 executions=6")
    controls = "ZETA BETA WHNF_STATE PUBLIC_CACHE QUICK_DEFEQ NAT_PROJECTION NESTED_OUTCOMES BINDER CHECK_APP DELTA CONSTANT_INDEX MUTUAL_INDEX CHECK_PROJECTION CHECK_LET LET_CACHE_SCOPE LET_LOCAL_WHNF STATEFUL_DEFEQ APP_CONVERSION APP_CONVERSION_CACHE APP_EAGER_CONTEXT SIMPLE_ADMISSION_MATRIX ADMISSION_SHARED_STATE ADMISSION_POLICY_SAFETY ADMISSION_FINAL_GUARDS THEOREM_ADMISSION_MATRIX THEOREM_ISPROP_STATE UNSAFE_ADMISSION UNSAFE_FRESH_BODY MUTUAL_ADMISSION MUTUAL_FRESH_MEMBER BINDER_SPINE BINDER_SPINE_BUDGET BINDER_SPINE_CACHE BINDER_SPINE_FALLBACK DEFEQ_PREFIX CHEAP_CORE_POLICY CHEAP_PROJECTION_POLICY DEFEQ_REFLECTION DEFEQ_PREFIX_GUARDS".split()
    for control in controls:
        substring_marker(dag,"PSC1_V2_DAG_JS_" + control + ": PASS")
    bounded = e.text("bounded/psc1-scalar-hash-probe.log")
    line_marker(bounded,short)
    same(one_json_line(e.text("bounded/psc1-closed-cache-analysis-probe.log"),
                       "PSC1_CLOSED_CACHE_ANALYSIS_JS: PASS "),CACHE_RESULT,"bounded cache1884")
    codegen = e.text("bounded/psc1-closed-cache-analysis-codegen.log")
    for marker in [
        "PSC1_CLOSED_CACHE_ANALYSIS_CODEGEN: PASS dataResult=true recursiveSites=11 oldHashCalls=0 oldHasFVarCalls=0 recurry=false",
        "PSC1_HASH_LEAF_CODEGEN: PASS byteStepGenerator=false byteStepStaging=false byteMixDispatch=false stagedFullEntry=false",
        "PSC1_HASH_DATA_RESULT_CODEGEN: PASS helpers=2",
        "PSC1_HASH_FUSED_ENTRY_CODEGEN: PASS stateDispatch=false scanDispatch=false resultStaging=0 pairFallbackSites=1 shortLeafSites=1 exclusiveBranches=true primitiveRemainder=1 structuralGeneratorBlocks=1",
        "PSC1_HASH_SHORT_PAIRS_CODEGEN: PASS pure=true generators=0 schedulerCalls=0 staging=0 primitiveTransitions=8 stepDispatches=0 selectedMaxPairs=4 genericFallback=true",
        "PSC1_HASH_LEVEL_LIST_ENTRY_CODEGEN: PASS empty=575 specializedArities=0,1,2 genericFallback=true stagedResult=false",
    ]:
        line_marker(codegen,marker)
        line_marker(e.terminal,marker)
    return {"header":1992,"cache":1884,"params":268,"result":432,
            "retainedControls":True,"boundedCodegenMarkers":6}



def bounded_codegen(e):
    """Recheck the archived bounded JavaScript bodies without executing them."""
    text = e.text("bounded/kernel.js")

    def implementations(prefix):
        return re.findall(r"^export function (" + prefix + r"[A-Za-z0-9_$]*)\(",text,re.M)

    def body_of(name):
        marker = "function* __ps$impl$" + name + "("
        if marker not in text:
            marker = "export function " + name + "("
        start = text.index(marker)
        end = text.find("\nexport ",start + len(marker))
        return text[start:] if end < 0 else text[start:end]

    analysis = "psKernelExprClosedCacheAnalysis"
    same(implementations(analysis),[analysis],"bounded closed-cache export")
    body = body_of(analysis)
    require(not any(x in body for x in
                    ("_$psc0SH","__ps$wrap","psKernelExprHash","psKernelExprHasFVar")),
            "Bounded closed-cache staging/old traversal")
    same(body.count("__ps$invoke(" + analysis + ","),11,"bounded structural recursion sites")
    for name,transitions in [
        ("psKernelCacheStringHashPairsWithFuel",2),
        ("psKernelCacheStringHashStateWithFuel",1),
    ]:
        same(implementations(name),[name],"bounded iterator export " + name)
        body = body_of(name)
        require(not any(x in body for x in
                        ("__ps$wrap","psKernelCacheStringHashStep","psKernelCacheMix")),
                "Bounded iterator transition staging")
        same(body.count("__ps$invoke("),1,"bounded iterator dispatch count")
        same(body.count("__ps$invoke(psKernelCacheStringHashPairsWithFuel,"),1,
             "bounded iterator target")
        same(len(re.findall(r"function\s*\*\s*\(",body)),1,"bounded iterator generator block")
        same(body.count("__ps$stringNext("),transitions,"bounded iterator next count")
        same(body.count("__ps$stringGet("),transitions,"bounded iterator get count")
    entry = body_of("psKernelCacheStringHash")
    forbidden = (
        "__ps$wrap","psKernelCacheStringHashWorker","psKernelCacheStringHashScan",
        "psKernelCacheStringHashStateWithFuel","psKernelCacheStringHashRemainderWithFuel",
        "psKernelCacheStringHashOctetsWithFuel","psKernelCacheStringHashStep","psKernelCacheMix",
    )
    require(not any(x in entry for x in forbidden),"Bounded hash entry dispatch")
    same(entry.count("__ps$invoke("),2,"bounded hash entry dispatch count")
    same(entry.count("__ps$invoke(psKernelCacheStringHashPairsWithFuel,"),1,"generic pair site")
    same(entry.count("__ps$invoke(psKernelCacheStringHashShortPairs,"),1,"short pair site")
    require("const paired = ((pairs <= 4n) ? (yield* __ps$invoke(psKernelCacheStringHashShortPairs," in entry
            and ": (yield* __ps$invoke(psKernelCacheStringHashPairsWithFuel," in entry,
            "Bounded hash exclusive branch threshold")
    same(len(re.findall(r"function\s*\*\s*\(",entry)),1,"hash entry generator block")
    same(entry.count("__ps$stringNext("),1,"hash odd remainder next")
    same(entry.count("__ps$stringGet("),1,"hash odd remainder get")
    short = body_of("psKernelCacheStringHashShortPairs")
    same(implementations("psKernelCacheStringHashShortPairs"),["psKernelCacheStringHashShortPairs"],
         "bounded pure short export")
    require(not any(x in short for x in (
        "function*","__ps$run","__ps$invoke","__ps$wrap","psKernelCacheStringHashPairsWithFuel",
        "psKernelCacheStringHashStep","psKernelCacheMix")),"Short leaf dispatch/staging")
    same(short.count("__ps$stringNext("),8,"short leaf next count")
    same(short.count("__ps$stringGet("),8,"short leaf get count")
    level = body_of("psKernelCacheLevelListHash")
    require("__ps$wrap" not in level and 'case "nil": return 575n;' in level,
            "Empty level list exact constant")
    same(level.count("__ps$invoke(psKernelCacheLevelListHashWorker,"),1,"generic level fallback")
    same(level.count("__ps$invoke(psKernelCacheLevelHash,"),3,"specialized level arities")
    step = body_of("psKernelCacheStringHashStep")
    require(not any(x in step for x in ("function*","__ps$run","__ps$invoke","__ps$wrap")),
            "Byte transition pure generated leaf")
    return {"archivedJavaScript":digest(e.raw("bounded/kernel.js")),
            "strictBodyChecksRecomputed":True}


def route_audit(e, closure):
    provenance = e.json("provenance.json")
    e.identity(provenance)
    for key,expected in {
        "schema":"psc1-t05-header-provenance-v1","repository":REPO,"leanCommit":LEAN,
        "typescript":"7.0.2","node":e.text("node-version.txt").strip(),
        "fuel":4096,"oldSpaceMiB":2048,"oldSpaceIsHardRssLimit":False,"emptyPATH":True,
        "headerOnly":False,
        **({"constructorHelpersOnly":False,"ordinaryAdmission":True,"fullOrdinaryAdmission":True,"fullKernel":False,
            "publicRoutingChanged":True,"publicFallbackRetained":True} if ADMISSION else
           {"constructorHelpersOnly":True,"fullAdmission":False,"publicFallbackUsed":False}),
    }.items():
        same(provenance.get(key),expected,"provenance " + key)
    if ADMISSION:
        require("fullAdmission" not in provenance and "publicFallbackUsed" not in provenance,
                "Public source provenance must not retain obsolete helper-only scope flags")
    same(e.text("typescript-version.txt").strip(),"Version 7.0.2","TypeScript pin")
    e.check_digest("source-inventory.json",provenance["sourceInventory"])
    e.check_digest("lean-source-manifest.json",provenance["leanSourceManifest"])
    e.check_digest("detached/kernel.mjs",provenance["kernel"])
    same(e.raw("detached/kernel.mjs"),e.raw("production/kernel.js"),
         "detached vs production kernel bytes")
    for suffix in (".js",".ts",".d.ts",".js.map"):
        require(bool(e.raw("production/kernel" + suffix)),"Missing production output " + suffix)
    mapping = e.json("production/kernel.js.map")
    require(mapping.get("version") == 3 and mapping.get("sources") and mapping.get("mappings"),
            "Complete generated source map")
    same(sorted(provenance["scripts"]),sorted(SCRIPT_NAMES),"detached script inventory")
    for script in SCRIPT_NAMES:
        e.check_digest("detached/" + script,provenance["scripts"][script])
        same(e.raw("detached/" + script),git_bytes("psc1/scripts/" + script),
             "executed harness source bytes " + script)
    e.check_digest("detached/pskernel-ordinary-header-smoke.mjs",provenance["harness"])
    if e.route == "canonical":
        e.check_digest("canonical-manifest.json",provenance["canonicalManifest"])
        e.check_digest("canonical-source.tar.gz",provenance["canonicalSourceArchive"])
    logged_json(e.terminal,"PSC1_T05_HEADER_PROVENANCE ",provenance)
    closure_result = closure_audit(e,closure)
    header = e.json("receipt.json")
    same(header.get("schema"),"psc1-t05-header-route-receipt-v1","header receipt schema")
    same(header.get("identity"),provenance,"header receipt identity/provenance")
    for key,expected in {"status":"pass","headerOnly":True,"fullAdmission":False,
                         "performanceQualified":False,"result":HEADER_RESULT}.items():
        same(header.get(key),expected,"header receipt " + key)
    same(one_json_line(e.text("header.log"),"PSC1_ORDINARY_HEADER_JS: PASS "),
         HEADER_RESULT,"actual header matrix")
    for key,expected in measurement(e,"header.memory").items():
        same(header.get(key),expected,"header measurement " + key)
    top_logs = {k for k in e.files if "/" not in k and k.endswith(".log")}
    later_logs = ({"constructor-fields.log"} if FIELDS else set()) | (
        {"constructor-analysis.log"} if ANALYSIS else set()) | (
        {"constructor-loop.log"} if LOOP else set()) | ADMISSION_LATER_LOGS
    e.log_digests(header["logs"],top_logs - {"constructor-params.log","constructor-result.log"} - later_logs)
    logged_json(e.terminal,"PSC1_T05_HEADER_ROUTE: PASS ",header)
    constructor = e.json("constructor-receipt.json")
    same(constructor.get("schema"),"psc1-t05-constructor-route-receipt-v1","constructor receipt schema")
    same(constructor.get("identity"),provenance,"constructor identity/provenance")
    for key,expected in {
        "status":"pass","retainedHeaderAssertions":1992,"headerOnly":False,
        "constructorHelpersOnly":True,"fullAdmission":False,
        "publicRoutingChanged":False,"performanceQualified":False,
    }.items():
        same(constructor.get(key),expected,"constructor receipt " + key)
    e.check_digest("receipt.json",constructor["retainedHeaderReceipt"])
    same(sorted(constructor["results"]),["params","result"],"constructor matrix inventory")
    kernel_path = "/home/runner/work/_temp/psc1-t05-" + e.route + "/detached/kernel.mjs"
    wanted = {
        "params":{
            "schema":"psc1-ordinary-constructor-params-v1","kernel":kernel_path,
            "assertions":268,"sectionAssertions":{"harness":1,"direct":227,"protocol":20,"boundaries":14,"faults":6},
            "directFixtures":18,"fuelValues":6,"interfaces":2,"directComparisons":216,"positiveDirect":11,
            "fullAdmission":False,"publicRoutingChanged":False,
        },
        "result":{
            "schema":"psc1-ordinary-constructor-result-v1","kernel":kernel_path,
            "assertions":432,"sectionAssertions":{"harness":1,"selector":138,"consumer":26,"occurrence":240,"bounds":16,"indexLists":7,"precedence":4},
            "selectorRows":46,"occurrenceTerms":30,"targetsPerOccurrence":2,
            "fullAdmission":False,"publicRoutingChanged":False,
        },
    }
    for name, expected in wanted.items():
        filename = "constructor-" + name + ".log"
        log = e.text(filename)
        rows = []
        for line in log.splitlines():
            if line.startswith("{"):
                value = json.loads(line)
                if value.get("schema") == expected["schema"]:
                    rows.append(value)
        same(rows,[expected],"executed constructor " + name + " JSON")
        line_marker(log,"PSC1_ORDINARY_CONSTRUCTOR_" + name.upper() +
                    "_JS: PASS assertions=" + str(expected["assertions"]) + " fullAdmission=false")
        result = constructor["results"][name]
        same(result.get("result"),expected,"constructor receipt matrix " + name)
        e.check_digest(filename,result["log"])
        e.check_digest("detached/pskernel-ordinary-constructor-" + name + "-smoke.mjs",
                       result["harness"])
        for key,value in measurement(e,"constructor-" + name + ".memory").items():
            same(result.get(key),value,"constructor measurement " + name + "." + key)
    e.log_digests(constructor["logs"],top_logs - later_logs)
    logged_json(e.terminal,"PSC1_T05_CONSTRUCTOR_ROUTE: PASS ",constructor)
    controls = route_controls(e)
    strict = bounded_codegen(e)
    return {"closure":closure_result,"boundedCodegen":strict,"assertions":controls,
            "kernel":digest(e.raw("detached/kernel.mjs")),
            "receipt":digest(e.raw("constructor-receipt.json")),
            "headerMeasurement":measurement(e,"header.memory"),
            "paramsMeasurement":measurement(e,"constructor-params.memory"),
            "resultMeasurement":measurement(e,"constructor-result.memory"),
            "allReceiptLogDigestsMatched":True,
            "allPrintedReceiptsMatched":True}


def fields_native_audit(e):
    r=e.json("fields-native-receipt.json")
    inv=e.json("fields-native-inventory.json")
    e.identity(r); e.identity(inv,job=False)
    wanted={"schema":"psc1-t05-fields-native-receipt-v1","status":"pass",
        "retainedProofs":230,"newProofs":47,"totalProofs":277,
        "orderedUniqueReports":True,"allowedStandardAxiomsOnly":True,
        "nativeAssertions":268,"constructorHelpersOnly":True,"fieldsAndPositivity":True,
        "fullAdmission":False,"publicRoutingChanged":False,"replayArenaModelBridgeEstablished":False}
    for k,v in wanted.items(): same(r.get(k),v,"fields native receipt "+k)
    specs=[("PsKernelOrdinaryRecursiveArgumentProofs",24,"recursive-argument-proofs.log"),
           ("PsKernelOrdinaryConstructorFieldsProofs",23,"constructor-fields-proofs.log")]
    audits=[]
    for module,count,name in specs:
        source=git_bytes("psc1/test/"+module+".lean"); raw=e.raw(name)
        names=proof_reports(source,raw,module,count)
        audits.append({"module":module,"proofs":count,"names":names,
                       "source":digest(source),"log":digest(raw)})
    same(r["proofs"],audits,"fields47 exact ordered reports")
    same(e.text("fields-proof-status.log").splitlines(),[
        "PSC1_T05_FIELDS_PROOF_STATUS module="+m+" count="+str(n)+" countStatus=0 leanStatus=0"
        for m,n,_ in specs],"fields proof command statuses")
    for path,key in [("constructor-native-receipt.json","retainedConstructorReceipt"),
                     ("fields-native-inventory.json","nativeInventory"),
                     ("constructor-fields-native.log","nativeLog")]:
        e.check_digest(path,r[key])
    wanted={"schema":"psc1-t05-fields-native-inventory-v1","assertions":268,
        "sectionAssertions":FIELDS_SECTIONS,"fieldRows":21,"recursiveRows":15,
        "fuelValues":6,"fullAdmission":False,"publicRoutingChanged":False}
    for k,v in wanted.items(): same(inv.get(k),v,"fields native inventory "+k)
    lines=e.text("constructor-fields-native.log").splitlines()
    prefix="PSC1_CONSTRUCTOR_FIELDS_ASSERT "
    labels=[line[len(prefix):] for line in lines if line.startswith(prefix)]
    require(len(labels)==len(set(labels))==268 and all(labels),"268 unique fields assertions")
    same(inv["assertionLabels"],labels,"native fields labels")
    same(inv["logSha256"],digest(e.raw("constructor-fields-native.log"))["sha256"],
         "native fields inventory log digest")
    previous=-1
    for group,count in FIELDS_SECTIONS.items():
        marker="PSC1_CONSTRUCTOR_FIELDS_SECTION "+group+"="+str(count)
        require(lines.count(marker)==1,"Native fields section "+group)
        end=lines.index(marker)
        group_labels=[line[len(prefix):] for line in lines[previous+1:end] if line.startswith(prefix)]
        require(end>previous and len(group_labels)==count and
                all(label.startswith(group+"/") for label in group_labels),"Ordered fields section "+group)
        previous=end
    for marker in [
        "PSC1_ORDINARY_CONSTRUCTOR_FIELDS_NATIVE: PASS assertions=268 fieldRows=21 recursiveRows=15 fuelValues=6 fullAdmission=false",
        "PSC1_ORDINARY_CONSTRUCTOR_FIELDS_NATIVE_SECTIONS: PASS harness=1 fields=147 recursive=105 boundaries=8 recursorGuard=7"]:
        require(lines.count(marker)==1 and lines.index(marker)>previous,"Native fields final marker")
    line_marker(e.terminal,"PSC1_T05_FIELDS_NATIVE_INVENTORY: PASS assertions=268 groups=5")
    logged_json(e.terminal,"PSC1_T05_FIELDS_NATIVE_PROOFS: PASS ",r)
    return {"newReports":47,"retainedReports":230,"totalReports":277,
            "nativeFieldsAssertions":268,"sections":FIELDS_SECTIONS,
            "receipt":digest(e.raw("fields-native-receipt.json"))}


def fields_route_audit(e):
    r=e.json("fields-receipt.json"); prov=e.json("provenance.json")
    same(r.get("identity"),prov,"fields route provenance")
    e.identity(r["identity"])
    for k,v in {"schema":"psc1-t05-fields-route-receipt-v1","status":"pass",
        "constructorHelpersOnly":True,"fieldsAndPositivity":True,"fullAdmission":False,
        "publicRoutingChanged":False,"performanceQualified":False}.items():
        same(r.get(k),v,"fields route receipt "+k)
    e.check_digest("constructor-receipt.json",r["retainedConstructorReceipt"])
    e.check_digest("constructor-fields.log",r["log"])
    e.check_digest("detached/pskernel-ordinary-constructor-fields-smoke.mjs",r["harness"])
    expected={"schema":"psc1-ordinary-constructor-fields-v1",
        "kernel":"/home/runner/work/_temp/psc1-t05-"+e.route+"/detached/kernel.mjs",
        "assertions":268,"sectionAssertions":FIELDS_SECTIONS,
        "fieldRows":21,"recursiveRows":15,"fuelValues":6,
        "positiveFields":16,"negativeFields":5,"positiveRecursive":10,"negativeRecursive":5,
        "fullAdmission":False,"publicRoutingChanged":False}
    log=e.text("constructor-fields.log")
    line_marker(log,"PSC1_ORDINARY_CONSTRUCTOR_FIELDS_JS: PASS assertions=268 fullAdmission=false")
    same([json.loads(line) for line in log.splitlines() if line.startswith("{")],
         [expected],"executed fields268 exact matrix")
    same(r["result"],expected,"fields receipt matrix")
    timing=measurement(e,"constructor-fields.memory")
    for k,v in timing.items(): same(r.get(k),v,"fields measurement "+k)
    top_logs={k for k in e.files if "/" not in k and k.endswith(".log")}
    later_logs = ({"constructor-analysis.log"} if ANALYSIS else set()) | (
        {"constructor-loop.log"} if LOOP else set()) | ADMISSION_LATER_LOGS
    e.log_digests(r["logs"],top_logs-later_logs)
    logged_json(e.terminal,"PSC1_T05_FIELDS_ROUTE: PASS ",r)
    return {"fieldsAssertions":268,"sections":FIELDS_SECTIONS,"measurement":timing,
            "receipt":digest(e.raw("fields-receipt.json")),
            "allFieldsReceiptLogDigestsMatched":True}


def analysis_native_audit(e):
    r=e.json("analysis-native-receipt.json")
    inv=e.json("analysis-native-inventory.json")
    e.identity(r); e.identity(inv,job=False)
    wanted={"schema":"psc1-t05-analysis-native-receipt-v1","status":"pass",
        "retainedProofs":277,"newProofs":19,"totalProofs":296,
        "orderedUniqueReports":True,"allowedStandardAxiomsOnly":True,
        "nativeAssertions":93,"constructorHelpersOnly":True,"singleConstructorAnalysis":True,
        "fullAdmission":False,"publicRoutingChanged":False,"replayArenaModelBridgeEstablished":False}
    for k,v in wanted.items(): same(r.get(k),v,"analysis native receipt "+k)
    module="PsKernelOrdinaryConstructorAnalysisProofs"
    source=git_bytes("psc1/test/"+module+".lean")
    raw=e.raw("constructor-analysis-proofs.log")
    names=proof_reports(source,raw,module,19)
    same(r["proofs"],[{"module":module,"proofs":19,"names":names,
         "source":digest(source),"log":digest(raw)}],"analysis19 exact ordered reports")
    same(e.text("analysis-proof-status.log").splitlines(),[
        "PSC1_T05_ANALYSIS_PROOF_STATUS module="+module+" count=19 countStatus=0 leanStatus=0"
    ],"analysis proof command status")
    for path,key in [("fields-native-receipt.json","retainedFieldsReceipt"),
                     ("analysis-native-inventory.json","nativeInventory"),
                     ("constructor-analysis-native.log","nativeLog")]:
        e.check_digest(path,r[key])
    wanted={"schema":"psc1-t05-analysis-native-inventory-v1","assertions":93,
        "sectionAssertions":ANALYSIS_SECTIONS,"rows":12,"fuelValues":6,
        "fullAdmission":False,"publicRoutingChanged":False}
    for k,v in wanted.items(): same(inv.get(k),v,"analysis native inventory "+k)
    lines=e.text("constructor-analysis-native.log").splitlines()
    prefix="PSC1_CONSTRUCTOR_ANALYSIS_ASSERT "
    labels=[line[len(prefix):] for line in lines if line.startswith(prefix)]
    require(len(labels)==len(set(labels))==93 and all(labels),"93 unique analysis assertions")
    same(inv["assertionLabels"],labels,"native analysis labels")
    same(inv["logSha256"],digest(e.raw("constructor-analysis-native.log"))["sha256"],
         "native analysis inventory log digest")
    previous=-1
    for group,count in ANALYSIS_SECTIONS.items():
        marker="PSC1_CONSTRUCTOR_ANALYSIS_SECTION "+group+"="+str(count)
        require(lines.count(marker)==1,"Native analysis section "+group)
        end=lines.index(marker)
        group_labels=[line[len(prefix):] for line in lines[previous+1:end] if line.startswith(prefix)]
        require(end>previous and len(group_labels)==count and
                all(label.startswith(group+"/") for label in group_labels),"Ordered analysis section "+group)
        previous=end
    marker="PSC1_ORDINARY_CONSTRUCTOR_ANALYSIS_NATIVE: PASS assertions=93 rows=12 fuelValues=6 fullAdmission=false"
    require(lines.count(marker)==1 and lines.index(marker)>previous,"Native analysis final marker")
    line_marker(e.terminal,"PSC1_T05_ANALYSIS_NATIVE_INVENTORY: PASS assertions=93 groups=3")
    logged_json(e.terminal,"PSC1_T05_ANALYSIS_NATIVE_PROOFS: PASS ",r)
    return {"newReports":19,"retainedReports":277,"totalReports":296,
            "nativeAnalysisAssertions":93,"sections":ANALYSIS_SECTIONS,
            "receipt":digest(e.raw("analysis-native-receipt.json"))}


def analysis_route_audit(e):
    r=e.json("analysis-receipt.json"); prov=e.json("provenance.json")
    same(r.get("identity"),prov,"analysis route provenance")
    e.identity(r["identity"])
    for k,v in {"schema":"psc1-t05-analysis-route-receipt-v1","status":"pass",
        "constructorHelpersOnly":True,"singleConstructorAnalysis":True,"fullAdmission":False,
        "publicRoutingChanged":False,"performanceQualified":False}.items():
        same(r.get(k),v,"analysis route receipt "+k)
    e.check_digest("fields-receipt.json",r["retainedFieldsReceipt"])
    e.check_digest("constructor-analysis.log",r["log"])
    e.check_digest("detached/pskernel-ordinary-constructor-analysis-smoke.mjs",r["harness"])
    expected={"schema":"psc1-ordinary-constructor-analysis-v1",
        "kernel":"/home/runner/work/_temp/psc1-t05-"+e.route+"/detached/kernel.mjs",
        "assertions":93,"sectionAssertions":ANALYSIS_SECTIONS,
        "rows":12,"fuelValues":6,"positive":6,"negative":6,
        "fullAdmission":False,"publicRoutingChanged":False}
    log=e.text("constructor-analysis.log")
    line_marker(log,"PSC1_ORDINARY_CONSTRUCTOR_ANALYSIS_JS: PASS assertions=93 fullAdmission=false")
    same([json.loads(line) for line in log.splitlines() if line.startswith("{")],
         [expected],"executed analysis93 exact matrix")
    same(r["result"],expected,"analysis receipt matrix")
    timing=measurement(e,"constructor-analysis.memory")
    for k,v in timing.items(): same(r.get(k),v,"analysis measurement "+k)
    top_logs={k for k in e.files if "/" not in k and k.endswith(".log")}
    e.log_digests(r["logs"],top_logs-(({"constructor-loop.log"} if LOOP else set()) | ADMISSION_LATER_LOGS))
    logged_json(e.terminal,"PSC1_T05_ANALYSIS_ROUTE: PASS ",r)
    return {"analysisAssertions":93,"sections":ANALYSIS_SECTIONS,"measurement":timing,
            "receipt":digest(e.raw("analysis-receipt.json")),
            "allAnalysisReceiptLogDigestsMatched":True}


def loop_native_audit(e):
    r=e.json("loop-native-receipt.json")
    inv=e.json("loop-native-inventory.json")
    e.identity(r); e.identity(inv,job=False)
    wanted={"schema":"psc1-t05-loop-native-receipt-v1","status":"pass",
        "retainedProofs":296,"newProofs":14,"totalProofs":310,
        "orderedUniqueReports":True,"allowedStandardAxiomsOnly":True,
        "nativeAssertions":69,"constructorHelpersOnly":True,"constructorLoopOnly":True,
        "fullAdmission":False,"publicRoutingChanged":False,"replayArenaModelBridgeEstablished":False}
    for k,v in wanted.items(): same(r.get(k),v,"loop native receipt "+k)
    module="PsKernelExprV2OrdinaryConstructorLoopProofs"
    source=git_bytes("psc1/test/"+module+".lean")
    raw=e.raw("constructor-loop-proofs.log")
    names=proof_reports(source,raw,module,14)
    same(r["proofs"],[{"module":module,"proofs":14,"names":names,
         "source":digest(source),"log":digest(raw)}],"loop14 exact ordered reports")
    same(e.text("loop-proof-status.log").splitlines(),[
        "PSC1_T05_LOOP_PROOF_STATUS module="+module+" count=14 countStatus=0 leanStatus=0"
    ],"loop proof command status")
    for path,key in [("analysis-native-receipt.json","retainedAnalysisReceipt"),
                     ("loop-native-inventory.json","nativeInventory"),
                     ("constructor-loop-native.log","nativeLog")]:
        e.check_digest(path,r[key])
    wanted={"schema":"psc1-t05-loop-native-inventory-v1","assertions":69,
        "sectionAssertions":LOOP_SECTIONS,"rows":8,"fuelValues":6,
        "fullAdmission":False,"publicRoutingChanged":False}
    for k,v in wanted.items(): same(inv.get(k),v,"loop native inventory "+k)
    lines=e.text("constructor-loop-native.log").splitlines()
    prefix="PSC1_CONSTRUCTOR_LOOP_ASSERT "
    labels=[line[len(prefix):] for line in lines if line.startswith(prefix)]
    require(len(labels)==len(set(labels))==69 and all(labels),"69 unique loop assertions")
    same(inv["assertionLabels"],labels,"native loop labels")
    same(inv["logSha256"],digest(e.raw("constructor-loop-native.log"))["sha256"],
         "native loop inventory log digest")
    previous=-1
    for group,count in LOOP_SECTIONS.items():
        marker="PSC1_CONSTRUCTOR_LOOP_SECTION "+group+"="+str(count)
        require(lines.count(marker)==1,"Native loop section "+group)
        end=lines.index(marker)
        group_labels=[line[len(prefix):] for line in lines[previous+1:end] if line.startswith(prefix)]
        require(end>previous and len(group_labels)==count and
                all(label.startswith(group+"/") for label in group_labels),"Ordered loop section "+group)
        previous=end
    marker="PSC1_ORDINARY_CONSTRUCTOR_LOOP_NATIVE: PASS assertions=69 rows=8 fuelValues=6 fullAdmission=false"
    require(lines.count(marker)==1 and lines.index(marker)>previous,"Native loop final marker")
    line_marker(e.terminal,"PSC1_T05_LOOP_NATIVE_INVENTORY: PASS assertions=69 groups=3")
    logged_json(e.terminal,"PSC1_T05_LOOP_NATIVE_PROOFS: PASS ",r)
    return {"newReports":14,"retainedReports":296,"totalReports":310,
            "nativeLoopAssertions":69,"sections":LOOP_SECTIONS,
            "receipt":digest(e.raw("loop-native-receipt.json"))}


def loop_route_audit(e):
    r=e.json("loop-receipt.json"); prov=e.json("provenance.json")
    same(r.get("identity"),prov,"loop route provenance")
    e.identity(r["identity"])
    for k,v in {"schema":"psc1-t05-loop-route-receipt-v1","status":"pass",
        "constructorHelpersOnly":True,"constructorLoopOnly":True,"fullAdmission":False,
        "publicRoutingChanged":False,"performanceQualified":False}.items():
        same(r.get(k),v,"loop route receipt "+k)
    e.check_digest("analysis-receipt.json",r["retainedAnalysisReceipt"])
    e.check_digest("constructor-loop.log",r["log"])
    e.check_digest("detached/pskernel-ordinary-constructor-loop-smoke.mjs",r["harness"])
    expected={"schema":"psc1-ordinary-constructor-loop-v1",
        "kernel":"/home/runner/work/_temp/psc1-t05-"+e.route+"/detached/kernel.mjs",
        "assertions":69,"sectionAssertions":LOOP_SECTIONS,
        "rows":8,"fuelValues":6,"positive":5,"negative":3,
        "fullAdmission":False,"publicRoutingChanged":False}
    log=e.text("constructor-loop.log")
    line_marker(log,"PSC1_ORDINARY_CONSTRUCTOR_LOOP_JS: PASS assertions=69 fullAdmission=false")
    same([json.loads(line) for line in log.splitlines() if line.startswith("{")],
         [expected],"executed loop69 exact matrix")
    same(r["result"],expected,"loop receipt matrix")
    timing=measurement(e,"constructor-loop.memory")
    for k,v in timing.items(): same(r.get(k),v,"loop measurement "+k)
    e.log_digests(r["logs"],{k for k in e.files if "/" not in k and k.endswith(".log")} - ADMISSION_LATER_LOGS)
    logged_json(e.terminal,"PSC1_T05_LOOP_ROUTE: PASS ",r)
    return {"loopAssertions":69,"sections":LOOP_SECTIONS,"measurement":timing,
            "receipt":digest(e.raw("loop-receipt.json")),
            "allLoopReceiptLogDigestsMatched":True}


def admission_native_inventory(e, name, total, sections, prefix, section_prefix, final,
                               extra, ordered=True):
    path=name+"-native-inventory.json"; logname=name+"-native.log"
    inv=e.json(path); e.identity(inv)
    wanted={"schema":"psc1-t05-"+name+"-native-inventory-v1",
            "assertions":total,"sectionAssertions":sections,**extra}
    for key,value in wanted.items(): same(inv.get(key),value,name+" native inventory "+key)
    lines=e.text(logname).splitlines()
    labels=[line[len(prefix):] for line in lines if line.startswith(prefix)]
    require(len(labels)==len(set(labels))==total and all(labels),name+" unique native assertions")
    same(inv["assertionLabels"],labels,name+" native executed labels")
    same(inv["logSha256"],digest(e.raw(logname))["sha256"],name+" native log digest")
    previous=-1
    first_section=None
    for group,count in sections.items():
        marker=section_prefix+group+"="+str(count)
        require(lines.count(marker)==1,name+" unique section marker "+group)
        end=lines.index(marker)
        require(end>previous,name+" section marker order")
        if first_section is None: first_section=end
        grouped=[label for label in labels if label.startswith(group+"/")]
        require(len(grouped)==count,name+" section label count "+group)
        if ordered:
            between=[line[len(prefix):] for line in lines[previous+1:end] if line.startswith(prefix)]
            same(between,grouped,name+" ordered section interval "+group)
        previous=end
    if not ordered:
        require(all(i<first_section for i,line in enumerate(lines) if line.startswith(prefix)),
                name+" terminal summary follows all assertions")
    require(lines.count(final)==1 and lines.index(final)>previous,name+" final native marker")
    return {"assertions":total,"sectionAssertions":sections,"assertionLabels":labels,
            "inventory":digest(e.raw(path)),"log":digest(e.raw(logname))}


def admission_native_audit(e):
    r=e.json("ordinary-admission-native-receipt.json"); e.identity(r)
    expected={"schema":"psc1-t05-ordinary-admission-native-receipt-v1","status":"pass",
        "retainedProofs":310,"newProofs":61,"totalProofs":371,
        "orderedUniqueReports":True,"allowedStandardAxiomsOnly":True,
        "nativeAssertions":{"elimination":116,"privateAdmission":143,"publicRouting":12},
        "ordinaryAdmission":True,"fullOrdinaryAdmission":True,"publicRoutingChanged":True,"fullKernel":False,
        "performanceQualified":False,"replayArenaModelBridgeEstablished":False}
    for key,value in expected.items(): same(r.get(key),value,"complete ordinary native receipt "+key)
    records=[]
    for module,count,filename in ADMISSION_PROOFS:
        source=git_bytes("psc1/test/"+module+".lean"); raw=e.raw(filename)
        names=proof_reports(source,raw,module,count)
        records.append({"module":module,"proofs":count,"names":names,
                        "source":digest(source),"log":digest(raw)})
    same(r["proofs"],records,"61 additional exact source-named proof reports")
    same(e.text("ordinary-admission-proof-status.log").splitlines(),[
        "PSC1_T05_ADMISSION_PROOF_STATUS module="+module+" count="+str(count)+
        " countStatus=0 leanStatus=0" for module,count,_ in ADMISSION_PROOFS],
        "three additional proof command statuses")
    e.check_digest("loop-native-receipt.json",r["retainedLoopReceipt"])
    e.check_digest("source-inventory.json",r["sourceInventory"])
    names=["elimination","ordinary-admission-private","ordinary-admission-public"]
    same(sorted(r["nativeInventories"]),sorted(names),"three native inventory receipts")
    same(sorted(r["nativeLogs"]),sorted(names),"three native log receipts")
    for name in names:
        e.check_digest(name+"-native-inventory.json",r["nativeInventories"][name])
        e.check_digest(name+"-native.log",r["nativeLogs"][name])
    e.log_digests(r["retainedNativeControls"],["dag-native.log","prefix-native.log"])
    prefix="PSC1_T05_ADMISSION_NATIVE_INVENTORY: PASS "
    printed=[json.loads(line[len(prefix):]) for line in e.terminal.splitlines() if line.startswith(prefix)]
    same(printed,[e.json(name+"-native-inventory.json") for name in names],
         "three printed native inventories match archived source-bound records")
    elimination=admission_native_inventory(e,"elimination",116,ELIMINATION_SECTIONS,
        "PSC1_ELIMINATION_ASSERT ","PSC1_ELIMINATION_SECTION ",
        "PSC1_ORDINARY_ELIMINATION_NATIVE: PASS assertions=116 policyRows=9 rawRows=4 fuelValues=6 fullAdmission=false",
        {"policyRows":9,"rawRows":4,"fuelValues":6,"fullAdmission":False,"publicRoutingChanged":False})
    private=admission_native_inventory(e,"ordinary-admission-private",143,PRIVATE_ADMISSION_SECTIONS,
        "PSC1_ORDINARY_ADMISSION_ASSERT ","PSC1_ORDINARY_ADMISSION_SECTION ",
        "PSC1_ORDINARY_ADMISSION_PRIVATE_NATIVE: PASS assertions=143 rows=18 fuelValues=6 privateAdmission=true fullAdmission=false",
        {"rows":18,"fuelValues":6,"positive":14,"negative":4,
         "privateAdmission":True,"fullAdmission":False,"publicRoutingChanged":False})
    public=admission_native_inventory(e,"ordinary-admission-public",12,PUBLIC_ADMISSION_SECTIONS,
        "PSC1_ADMISSION_PUBLIC_ASSERT ","PSC1_ADMISSION_PUBLIC_SECTION ",
        "PSC1_ORDINARY_ADMISSION_PUBLIC_NATIVE: PASS assertions=12 publicRoutingChanged=true ordinaryAdmission=true",
        {"ordinaryAdmission":True,"publicRoutingChanged":True,"fullKernel":False},ordered=False)
    private_labels=["harness/constructor-tags"]
    for label in ADMISSION_ORACLE_LABELS:
        private_labels.extend("matrix/"+label+"/fuel="+str(fuel) for fuel in (0,1,2,3,8,4096))
        private_labels.append("matrix/"+label+"/required-outcome")
    private_labels.extend("protocol/"+label for label in (
        "rec-type-error","rec-type-decline","rec-type-nonsort","rec-type-fresh-context",
        "first-rule-error","first-rule-decline","second-rule-error","second-rule-decline",
        "rule-defeq-error","rule-defeq-decline","rule-defeq-false","first-rule-fresh-context",
        "real-callbacks-match-wrapper","private-header-id-not-input","private-ctor-id-not-input",
        "retry-after-late-failure"))
    same(private["assertionLabels"],private_labels,"exact private18x6 outcomes and16 protocols")
    same(public["assertionLabels"],PUBLIC_ADMISSION_LABELS,"exact twelve public native controls")
    oracle=r["officialOracle"]
    for key,value in {"controls":18,"accepted":14,"rejected":4,"safeGenerated":13,"unsafeContract":1}.items():
        same(oracle.get(key),value,"independent Lean oracle "+key)
    lines=e.text("ordinary-admission-private-native.log").splitlines()
    prefix="PSC1_ORDINARY_ADMISSION_ORACLE_ASSERT "
    labels=[line[len(prefix):] for line in lines if line.startswith(prefix)]
    same(labels,ADMISSION_ORACLE_LABELS,"exact eighteen executed independent Lean controls")
    same(oracle["assertionLabels"],labels,"independent Lean receipt labels")
    e.check_digest("ordinary-admission-private-native.log",oracle["log"])
    marker="PSC1_ORDINARY_ADMISSION_ORACLE: PASS controls=18 accepted=14 rejected=4 safeGenerated=13 unsafeContract=1"
    line_marker(e.text("ordinary-admission-private-native.log"),marker)
    require(lines.index(marker)>max(i for i,line in enumerate(lines) if line.startswith(prefix)),
            "independent Lean oracle final marker follows all controls")
    # Terminal receipt markers are verified against the same archived JSON.
    logged_json(e.terminal,"PSC1_T05_ORDINARY_ADMISSION_NATIVE_PROOFS: PASS ",r)
    return {"newReports":61,"retainedReports":310,"totalReports":371,
        "elimination":elimination,"privateAdmission":private,"publicRouting":public,
        "officialOracle":{"controls":18,"accepted":14,"rejected":4,
                          "safeGenerated":13,"unsafeContract":1},
        "receipt":digest(e.raw("ordinary-admission-native-receipt.json"))}

def admission_route_audit(e):
    prov=e.json("provenance.json")
    kernel="/home/runner/work/_temp/psc1-t05-"+e.route+"/detached/kernel.mjs"
    specs=[
        {"name":"elimination","schema":"psc1-t05-elimination-route-receipt-v1",
         "prior":"loop-receipt.json","priorKey":"retainedLoopReceipt",
         "harness":"pskernel-ordinary-elimination-smoke.mjs",
         "result":{"schema":"psc1-ordinary-elimination-v1","kernel":kernel,
             "assertions":116,"sectionAssertions":ELIMINATION_SECTIONS,
             "policyRows":9,"rawRows":4,"fuelValues":6,"fullAdmission":False,"publicRoutingChanged":False},
         "marker":"PSC1_ORDINARY_ELIMINATION_JS: PASS assertions=116 fullAdmission=false",
         "receiptMarker":"PSC1_T05_ELIMINATION_ROUTE: PASS ",
         "later":{"ordinary-admission-private.log","ordinary-admission-public.log"}},
        {"name":"ordinary-admission-private","schema":"psc1-t05-ordinary-admission-private-route-receipt-v1",
         "prior":"elimination-receipt.json","priorKey":"retainedEliminationReceipt",
         "harness":"pskernel-ordinary-admission-private-smoke.mjs",
         "result":{"schema":"psc1-ordinary-admission-private-v1","kernel":kernel,
             "assertions":143,"sectionAssertions":PRIVATE_ADMISSION_SECTIONS,
             "rows":18,"fuelValues":6,"positive":14,"negative":4,
             "privateAdmission":True,"fullAdmission":False,"publicRoutingChanged":False},
         "marker":"PSC1_ORDINARY_ADMISSION_PRIVATE_JS: PASS assertions=143 privateAdmission=true fullAdmission=false",
         "receiptMarker":"PSC1_T05_ORDINARY_ADMISSION_PRIVATE_ROUTE: PASS ",
         "later":{"ordinary-admission-public.log"}},
        {"name":"ordinary-admission-public","schema":"psc1-t05-ordinary-admission-public-route-receipt-v1",
         "prior":"ordinary-admission-private-receipt.json","priorKey":"retainedPrivateAdmissionReceipt",
         "harness":"pskernel-ordinary-admission-public-smoke.mjs",
         "result":{"schema":"psc1-ordinary-admission-public-v1","kernel":kernel,
             "assertions":12,"sectionAssertions":PUBLIC_ADMISSION_SECTIONS,
             "assertionLabels":PUBLIC_ADMISSION_LABELS,"publicRoutingChanged":True,
             "ordinaryAdmission":True,"fullKernel":False,"performanceQualified":False},
         "marker":"PSC1_ORDINARY_ADMISSION_PUBLIC_JS: PASS assertions=12 publicRoutingChanged=true ordinaryAdmission=true",
         "receiptMarker":"PSC1_T05_ORDINARY_ADMISSION_PUBLIC_ROUTE: PASS ","later":set()}]
    results={}
    top_logs={name for name in e.files if "/" not in name and name.endswith(".log")}
    for spec in specs:
        name=spec["name"]; path=name+"-receipt.json"; r=e.json(path)
        same(r.get("identity"),prov,name+" route provenance"); e.identity(r["identity"])
        public=name=="ordinary-admission-public"
        for key,value in {"schema":spec["schema"],"status":"pass",
            "ordinaryAdmission":public,"fullOrdinaryAdmission":public,"publicRoutingChanged":public,
            "fullKernel":False,"performanceQualified":False}.items():
            same(r.get(key),value,name+" route receipt "+key)
        require("fullAdmission" not in r,name+" aggregate receipt uses precise ordinary/kernel scope")
        e.check_digest(spec["prior"],r[spec["priorKey"]])
        e.check_digest(name+".log",r["log"])
        e.check_digest("detached/"+spec["harness"],r["harness"])
        log=e.text(name+".log")
        line_marker(log,spec["marker"])
        same([json.loads(line) for line in log.splitlines() if line.startswith("{")],
             [spec["result"]],name+" actual generated runtime JSON")
        same(r["result"],spec["result"],name+" source-bound runtime receipt")
        if public:
            prefix="PSC1_ADMISSION_PUBLIC_ASSERT "
            labels=[line[len(prefix):] for line in log.splitlines() if line.startswith(prefix)]
            same(labels,PUBLIC_ADMISSION_LABELS,"exact executed public generated control labels")
            for group,count in PUBLIC_ADMISSION_SECTIONS.items():
                line_marker(log,"PSC1_ADMISSION_PUBLIC_SECTION "+group+"="+str(count))
        timing=measurement(e,name+".memory")
        for key,value in timing.items(): same(r.get(key),value,name+" measured resource "+key)
        e.log_digests(r["logs"],top_logs-DEFERRED_LATER_LOGS)
        logged_json(e.terminal,spec["receiptMarker"],r)
        results[name]={"assertions":spec["result"]["assertions"],
            "sections":spec["result"]["sectionAssertions"],"measurement":timing,
            "receipt":digest(e.raw(path)),"allReceiptLogDigestsMatched":True}
    return results

def deferred_production_sources():
    """Reconstruct the entire authenticated predecessor file from each sole move."""
    proof=git_bytes(DEFERRED_PROOF).decode("utf-8")
    require(proof.count("namespace Frozen\n")==1 and proof.count("\nend Frozen")==1,
            "exact frozen worker namespace")
    frozen=proof.split("namespace Frozen\n",1)[1].split("\nend Frozen",1)[0]
    def worker(text,name):
        found=re.search(r"(?ms)^def "+re.escape(name)+r"\n.*?(?=^def |\Z)",text)
        require(found is not None,"missing frozen worker "+name)
        return found
    records=[]
    for short,oid,name,remove,anchor,insert in DEFERRED_WORKERS:
        path=DEFERRED_PREFIX+short
        raw=git_bytes(path); after=raw.decode("utf-8")
        match=worker(after,name); body=match.group(0)
        successor="  | Nat.succ remaining =>\n"
        require(body.count(insert)==1 and body.count(successor)==1 and body.count(anchor)==1,
                "unique deferred worker relocation "+name)
        restored=body.replace(insert,"").replace(successor,successor+remove)
        before=after[:match.start()]+restored+after[match.end():]
        same(git_blob_sha(before.encode("utf-8")),oid,
             "reconstructed entire qualified predecessor file "+path)
        require(before.count(remove)==1 and before.count(anchor)==1,
                "unique predecessor relocation anchors "+path)
        same(before.replace(remove,"").replace(anchor,anchor+insert),after,
             "exact whole-file binding move "+path)
        predecessor=worker(before,name).group(0).rstrip()
        same(worker(frozen,name).group(0).rstrip(),predecessor,
             "frozen proof worker byte identity "+name)
        records.append({"path":path,"baselineGitBlob":oid,"targetGitBlob":git_blob_sha(raw),
            "target":digest(raw),"frozenWorker":digest(predecessor.encode("utf-8"))})
    return {"baselineSha":DEFERRED_BASELINE,"baselineBlobs":DEFERRED_BLOBS,
        "wholeFilesReconstructed":True,"exactBindingMovesOnly":True,
        "frozenBodiesMatch":True,"workers":records,"proof":digest(git_bytes(DEFERRED_PROOF))}


def deferred_native_audit(e):
    source=e.json("deferred-transform-source-audit.json"); e.identity(source)
    for key,value in {"schema":"psc1-t08-deferred-transform-source-v1",
        "baselineSha":DEFERRED_BASELINE,"baselineBlobs":DEFERRED_BLOBS,
        "frozenBodiesMatch":True,"exactBindingMovesOnly":True,
        "fullQualification":False,"performanceQualified":False}.items():
        same(source.get(key),value,"deferred source audit "+key)
    same(sorted(source["productionChanges"]),sorted(DEFERRED_BLOBS),
         "exact three production delta paths")
    files=DEFERRED_INPUTS+[WORKFLOW]
    same(source["sourceFiles"],{path:digest(git_bytes(path))["sha256"] for path in files},
         "six exact deferred source audit hashes")
    logged_json(e.terminal,"PSC1_T08_DEFERRED_TRANSFORM_SOURCE: PASS ",source)
    r=e.json("deferred-transform-native-receipt.json"); e.identity(r)
    for key,value in {"schema":"psc1-t08-deferred-transform-native-receipt-v1",
        "status":"pass","retainedProofs":371,"newProofs":3,"totalProofs":374,
        "orderedUniqueReports":True,"allowedStandardAxiomsOnly":True,
        "productionSemanticEquality":True,"deferredTransformConstruction":True,
        "fullOrdinaryAdmission":True,"fullKernel":False,"performanceQualified":False}.items():
        same(r.get(key),value,"deferred native receipt "+key)
    raw=e.raw("deferred-transform-proofs.log")
    names=proof_reports(git_bytes(DEFERRED_PROOF),raw,DEFERRED_MODULE,3)
    same(names,DEFERRED_NAMES,"three fixed worker equality proof names")
    same(r["proofs"],[{"module":DEFERRED_MODULE,"proofs":3,"names":names,
        "source":digest(git_bytes(DEFERRED_PROOF)),"log":digest(raw)}],
        "three exact deferred native proof records")
    e.check_digest("ordinary-admission-native-receipt.json",r["retainedAdmissionReceipt"])
    e.check_digest("deferred-transform-source-audit.json",r["sourceAudit"])
    e.check_digest("source-inventory.json",r["sourceInventory"])
    logged_json(e.terminal,"PSC1_T08_DEFERRED_TRANSFORM_NATIVE: PASS ",r)
    return {"retainedReports":371,"newReports":3,"totalReports":374,"proofNames":names,
        "sourceAudit":digest(e.raw("deferred-transform-source-audit.json")),
        "receipt":digest(e.raw("deferred-transform-native-receipt.json"))}


def deferred_route_audit(e):
    r=e.json("deferred-transform-receipt.json")
    prov=e.json("provenance.json")
    same(r.get("identity"),prov,"deferred route full provenance"); e.identity(r["identity"])
    for key,value in {"schema":"psc1-t08-deferred-transform-route-receipt-v1","status":"pass",
        "deferredTransformConstruction":True,"fullKernel":False,"performanceQualified":False}.items():
        same(r.get(key),value,"deferred route receipt "+key)
    e.check_digest("ordinary-admission-public-receipt.json",r["retainedPublicReceipt"])
    e.check_digest("deferred-transform.log",r["log"])
    e.check_digest("detached/"+DEFERRED_HARNESS,r["harness"])
    result={"assertions":23,"exports":3,"stagedArrows":11,
        "sectionAssertions":DEFERRED_SECTIONS,"assertionLabels":DEFERRED_LABELS}
    same(r["result"],result,"exact deferred23 runtime inventory")
    marker="PSC1_TRANSFORM_DELAY_RAW_JS: PASS assertions=23 exports=3 stagedArrows=11"
    prefix="PSC1_TRANSFORM_DELAY_ASSERT "
    expected=[prefix+label for label in DEFERRED_LABELS]+[marker]
    same(e.text("deferred-transform.log").splitlines(),expected,
         "exact complete deferred23 assertion transcript")
    same([line for line in e.terminal.splitlines() if line.startswith(prefix)],
         expected[:-1],"exact executed deferred23 terminal labels")
    line_marker(e.terminal,marker)
    timing=measurement(e,"deferred-transform.memory")
    for key,value in timing.items(): same(r.get(key),value,"deferred measured resource "+key)
    e.log_digests(r["logs"],{name for name in e.files if "/" not in name and name.endswith(".log")})
    logged_json(e.terminal,"PSC1_T08_DEFERRED_TRANSFORM_ROUTE: PASS ",r)
    return {"assertions":23,"exports":3,"stagedArrows":11,"sections":DEFERRED_SECTIONS,
        "assertionLabels":DEFERRED_LABELS,"measurement":timing,
        "receipt":digest(e.raw("deferred-transform-receipt.json")),
        "allReceiptLogDigestsMatched":True}


def retained_native_audit(e):
    r=e.json("retained-native-receipt.json"); e.identity(r)
    for key,value in {"schema":"psc1-retained-native-receipt-v1","status":"pass",
        "retainedProofs":374,"addedReports":118,"historicalReports":116,
        "newCompanionReports":2,"totalProofs":492,
        "orderedUniqueReports":True,"allowedStandardAxiomsOnly":True,
        "fullOrdinaryAdmission":True,"deferredTransformConstruction":True,
        "fullKernel":False,"performanceQualified":False}.items():
        same(r.get(key),value,"retained native receipt "+key)
    records=[]
    for module,count,filename in RETAINED_PROOFS:
        source=git_bytes("psc1/test/"+module+".lean"); raw=e.raw(filename)
        names=proof_reports(source,raw,module,count)
        records.append({"module":module,"proofs":count,"names":names,
                        "source":digest(source),"log":digest(raw)})
    same(len(records),10,"ten retained proof modules")
    same(sum(x["proofs"] for x in records),118,"118 additional retained reports")
    same(len({name for x in records for name in x["names"]}),118,
         "118 globally unique retained proof names")
    same(r["proofs"],records,"ten source-named retained native proof records")
    same(records[3]["names"][-2:],[
        "PsKernelExprV2RecursorProofs.generated_fallback_import_error_returns_no_owner",
        "PsKernelExprV2RecursorProofs.owned_command_error_prevents_batch_publication"],
        "two companion fallback and owned-command error obligations")
    same(e.text("retained-proof-status.log").splitlines(),[
        "PSC1_RETAINED_PROOF_STATUS module="+module+" count="+str(count)+
        " countStatus=0 leanStatus=0" for module,count,_ in RETAINED_PROOFS],
        "ten successful native proof commands in frozen order")
    e.check_digest("deferred-transform-native-receipt.json",r["retainedDeferredReceipt"])
    e.check_digest("source-inventory.json",r["sourceInventory"])
    e.check_digest("retained-proof-status.log",r["proofStatuses"])
    logged_json(e.terminal,"PSC1_RETAINED_NATIVE_PROOFS: PASS ",r)
    return {"retainedReports":374,"addedReports":118,"historicalReports":116,
        "newCompanionReports":2,"totalReports":492,"totalModules":29,
        "modules":[{"module":x["module"],"reports":x["proofs"]} for x in records],
        "proofStatuses":digest(e.raw("retained-proof-status.log")),
        "receipt":digest(e.raw("retained-native-receipt.json"))}


def wait_for_cohort():
    deadline = time.monotonic() + 75 * 60
    while True:
        run = api("actions/runs/" + str(RUN))
        same(run.get("head_sha"),SHA,"target workflow source")
        same(run.get("run_attempt"),ATTEMPT,"target run attempt")
        same(run.get("path"),WORKFLOW,"target workflow path")
        if run.get("status") == "completed":
            REPORT["targetWorkflow"] = {k:run.get(k) for k in (
                "id","head_sha","head_branch","run_attempt","status","conclusion","path",
                "created_at","updated_at","html_url")}
            require(run.get("conclusion") == "success","Target cohort did not succeed")
            return run
        require(time.monotonic() < deadline,"Target cohort did not finish within audit wait cap")
        print("PSC1_T05_ARTIFACT_AUDIT_WAIT source=" + SHA + " run=" + str(RUN) +
              " attempt=" + str(ATTEMPT) + " status=" + str(run.get("status")),flush=True)
        time.sleep(45)


def main():
    require(os.environ.get("RUNNER_OS") == "Linux","This audit runs on GitHub Linux only")
    require(os.environ.get("GITHUB_ACTIONS") == "true","GitHub Actions required")
    require(TOKEN,"Missing read-only GitHub token")
    require(PROFILE in ("helpers","fields","analysis","loop","admission","deferred","retained"),"Unknown audit profile")
    require(re.fullmatch(r"[0-9a-f]{40}",SHA) is not None,"Exact target source SHA required")
    require(type(RUN) is int and RUN > 0 and type(ATTEMPT) is int and ATTEMPT > 0,
            "Exact numeric run and attempt required")
    same(CONFIG.get("repository"),REPO,"target repository")
    actual = subprocess.check_output(["git","-C",str(SOURCE_ROOT),"rev-parse","HEAD"],
                                     text=True).strip()
    same(actual,SHA,"target checkout exact SHA")
    source_workflow = git_bytes(WORKFLOW).decode()
    path_lists = [ast.literal_eval(x) for x in
                  re.findall(r"^\s*paths = (\[.*\])$",source_workflow,re.M)]
    require(len(path_lists) == 2 and path_lists[0] == path_lists[1],
            "Native and route source inventory definitions agree")
    expected_paths = path_lists[0]
    if RETAINED:
        require(set(RETAINED_INPUTS) <= set(expected_paths),"ten explicit retained native proof inputs")
    if DEFERRED:
        require(set(DEFERRED_INPUTS) <= set(expected_paths),"five explicit deferred production/proof/harness inputs")
        REPORT["deferredTransformSources"] = deferred_production_sources()
    require(len(expected_paths) == SOURCE_INPUT_COUNT and len(set(expected_paths)) == SOURCE_INPUT_COUNT,
            "Expected exact configured source input count")
    frozen_lists = [ast.literal_eval(x) for x in
                    re.findall(r"^\s*frozen = (\{.*\})$",source_workflow,re.M)]
    require(len(frozen_lists) == 2 and frozen_lists[0] == frozen_lists[1],
            "Frozen-reference definitions agree")
    frozen = frozen_lists[0]
    same(len(frozen),7 if ANALYSIS else 6,"frozen reference count")
    if ANALYSIS:
        require(ANALYSIS_ORACLE_PATH in expected_paths,"Analysis V1 oracle source inventory")
        same(frozen.get(ANALYSIS_ORACLE_PATH),ANALYSIS_ORACLE_SHA256,"frozen analysis V1 oracle hash")
        same(git_blob_sha(git_bytes(ANALYSIS_ORACLE_PATH)),ANALYSIS_ORACLE_GIT_BLOB,
             "frozen analysis V1 oracle Git blob")
    if ADMISSION:
        blob_lists = [ast.literal_eval(x) for x in
            re.findall(r"^\s*frozen_blobs = (\{.*\})$",source_workflow,re.M)]
        require(len(blob_lists)==2 and blob_lists[0]==blob_lists[1],
                "Native and route frozen Git-blob definitions agree")
        frozen_blobs=blob_lists[0]
        same(frozen_blobs,ADMISSION_FROZEN_BLOBS,"three additional frozen oracle Git blobs")
        require(set(frozen).isdisjoint(frozen_blobs) and len(set(frozen)|set(frozen_blobs))==10,
                "Exactly ten distinct frozen reference paths")
        for path,oid in frozen_blobs.items():
            require(path in expected_paths,"Frozen oracle missing from source inventory")
            same(git_blob_sha(git_bytes(path)),oid,"frozen ordinary oracle "+path)
        REPORT["frozenOracleGitBlobs"]=frozen_blobs
    closure = lean_closure()
    REPORT["actualLeanClosureCount"] = len(closure)
    REPORT["targetWorkflowSource"] = digest(git_bytes(WORKFLOW))
    wait_for_cohort()
    jobs = pages("actions/runs/" + str(RUN) + "/attempts/" + str(ATTEMPT) + "/jobs","jobs")
    wanted_names = {"native":"native-header","generated":"generated-header (generated)",
                    "canonical":"generated-header (canonical)"}
    same(sorted(j["name"] for j in jobs),sorted(wanted_names.values()),"exact three cohort jobs")
    require(all(j.get("status") == "completed" and j.get("conclusion") == "success"
                for j in jobs),"All exact cohort jobs must succeed")
    job_map = {route:next(j for j in jobs if j["name"] == name)
               for route,name in wanted_names.items()}
    REPORT["jobs"] = [{k:j.get(k) for k in (
        "id","name","status","conclusion","run_id","head_sha","started_at","completed_at")}
        for j in jobs]
    artifacts = pages("actions/runs/" + str(RUN) + "/artifacts","artifacts")
    expected_names = {route:"psc1-t05-header-" + route + "-attempt-" + str(ATTEMPT)
                      for route in ROUTES}
    selected = [a for a in artifacts if a["name"] in expected_names.values()]
    same(sorted(a["name"] for a in selected),sorted(expected_names.values()),
         "exact three attempt-bound artifacts")
    for route in ROUTES:
        result = {"status":"in_progress"}
        REPORT["routes"][route] = result
        try:
            artifact = next(a for a in selected if a["name"] == expected_names[route])
            require(not artifact.get("expired"),"Expired artifact")
            same(artifact["workflow_run"]["id"],RUN,"artifact run binding")
            same(artifact["workflow_run"]["head_sha"],SHA,"artifact source binding")
            raw = request("actions/artifacts/" + str(artifact["id"]) + "/zip")
            same(len(raw),artifact["size_in_bytes"],"archive download length")
            same("sha256:" + digest(raw)["sha256"],artifact.get("digest"),"API archive SHA256")
            files = unzip(raw)
            job = job_map[route]
            same(job.get("run_id"),RUN,"job source run")
            same(job.get("head_sha"),SHA,"job source SHA")
            terminal_raw = request("actions/jobs/" + str(job["id"]) + "/logs")
            terminal = clean_terminal(terminal_raw)
            result.update({
                "artifactId":artifact["id"],"artifactName":artifact["name"],
                "archive":digest(raw),"apiDigest":artifact["digest"],
                "crcVerified":True,"safeUniqueArchivePaths":True,
                "jobId":job["id"],"terminalLog":digest(terminal_raw),
                "fileCount":len(files),
                "members":[{"path":name,**digest(content)}
                           for name,content in sorted(files.items())],
            })
            evidence = Evidence(files,route,terminal)
            result["sourceInventory"] = source_inventory(evidence,expected_paths,frozen)
            result["qualification"] = native_audit(evidence) if route == "native" else route_audit(evidence,closure)
            if FIELDS:
                result["fieldsQualification"] = fields_native_audit(evidence) if route == "native" else fields_route_audit(evidence)
            if ANALYSIS:
                result["analysisQualification"] = analysis_native_audit(evidence) if route == "native" else analysis_route_audit(evidence)
            if LOOP:
                result["loopQualification"] = loop_native_audit(evidence) if route == "native" else loop_route_audit(evidence)
            if ADMISSION:
                result["ordinaryAdmissionQualification"] = admission_native_audit(evidence) if route == "native" else admission_route_audit(evidence)
            if DEFERRED:
                result["deferredTransformQualification"] = deferred_native_audit(evidence) if route == "native" else deferred_route_audit(evidence)
            if RETAINED and route == "native":
                result["retainedNativeQualification"] = retained_native_audit(evidence)
            result["status"] = "pass"
            print("PSC1_T05_ARTIFACT_ROUTE: PASS route=" + route +
                  " artifact=" + str(artifact["id"]) + " files=" + str(len(files)),flush=True)
        except Exception as error:
            result["status"] = "fail"
            result["error"] = str(error)
            REPORT["errors"].append({"route":route,"error":str(error)})
    require(not REPORT["errors"],"One or more artifact audits failed")
    final_run = api("actions/runs/" + str(RUN))
    same(final_run.get("head_sha"),SHA,"final source binding")
    same(final_run.get("run_attempt"),ATTEMPT,"final attempt did not change")
    same(final_run.get("conclusion"),"success","final cohort conclusion")
    REPORT["status"] = "pass"
    REPORT["scope"] = {
        "constructorHelpersQualified":True,"fullT05AdmissionQualified":ADMISSION,
        "ordinaryAdmissionQualified":ADMISSION,"publicRoutingQualified":ADMISSION,"fullKernelQualified":False,
        "projectB":"OPEN","projectC":"FAIL","projectD":"OPEN",
        "nativeProofReports":NATIVE_PROOF_TOTAL,"nativeProofModules":NATIVE_PROOF_MODULES,
        "nativeAssertions":{"params":284,"result":432,
            **({"fields":268} if FIELDS else {}),**({"analysis":93} if ANALYSIS else {}),
            **({"loop":69} if LOOP else {}),
            **({"elimination":116,"privateAdmission":143,"publicRouting":12} if ADMISSION else {})},
        "eachGeneratedRouteAssertions":{"header":1992,"cache":1884,"params":268,"result":432,
            **({"fields":268} if FIELDS else {}),**({"analysis":93} if ANALYSIS else {}),
            **({"loop":69} if LOOP else {}),
            **({"elimination":116,"privateAdmission":143,"publicRouting":12} if ADMISSION else {}),
            **({"deferredTransform":23} if DEFERRED else {})},
        "constructorFieldsQualified":FIELDS,"singleConstructorAnalysisQualified":ANALYSIS,
        "constructorLoopQualified":LOOP,"profile":PROFILE,
        "deferredTransformQualified":DEFERRED,"retainedNativeProofsQualified":RETAINED,
        **({"independentLeanControls":{"controls":18,"accepted":14,"rejected":4,
                "safeGenerated":13,"unsafeContract":1}} if ADMISSION else {}),
    }


if __name__ == "__main__":
    OUT.mkdir(parents=True,exist_ok=True)
    code = 0
    try:
        main()
    except Exception as error:
        REPORT["status"] = "fail"
        REPORT["errors"].append({"error":str(error)})
        code = 1
    finally:
        REPORT["gitBlobsCompared"] = [
            {"path":path,"gitBlobSha":git_blob_sha(raw),**digest(raw)}
            for path,raw in sorted(BLOBS.items())]
        payload = json.dumps(REPORT,indent=2,ensure_ascii=False) + "\n"
        (OUT / "audit.json").write_text(payload)
        summary = {
            "schema":REPORT["schema"],"status":REPORT["status"],
            "sourceSha":SHA,"runId":RUN,"runAttempt":ATTEMPT,
            "routes":{r:{"status":v["status"],"artifactId":v.get("artifactId"),
                        "files":v.get("fileCount"),"error":v.get("error")}
                      for r,v in REPORT["routes"].items()},
            "nativeReports":NATIVE_PROOF_TOTAL if REPORT["status"] == "pass" else None,
            "nativeModules":NATIVE_PROOF_MODULES if REPORT["status"] == "pass" else None,
            "profile":PROFILE,
            **({"deferredTransformQualified":REPORT["status"] == "pass"} if DEFERRED else {}),
            **({"retainedNativeProofsQualified":REPORT["status"] == "pass"} if RETAINED else {}),
            "report":digest(payload.encode()),
            "errors":REPORT["errors"],
            **({"ordinaryAdmissionQualified":REPORT["status"] == "pass",
                "fullOrdinaryAdmission":REPORT["status"] == "pass","fullKernel":False}
               if ADMISSION else {"fullAdmission":False}),
            "performanceQualified":False,
        }
        (OUT / "summary.json").write_text(json.dumps(summary,indent=2) + "\n")
        print("PSC1_T05_ARTIFACT_AUDIT: " + REPORT["status"].upper() + " " +
              json.dumps(summary,separators=(",",":")),flush=True)
    sys.exit(code)
