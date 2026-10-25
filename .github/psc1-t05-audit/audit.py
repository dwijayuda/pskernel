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
EMPTY_CACHE = PROFILE == "empty-cache"
VALIDATOR = CONFIG.get("validator", False)
if VALIDATOR is not False and VALIDATOR is not True:
    raise RuntimeError("Validator profile must be boolean")
if VALIDATOR and not EMPTY_CACHE:
    raise RuntimeError("Validator extension requires all retained empty-cache checks")
LAYOUT = PROFILE in ("layout", "empty-cache")
RESTORED = PROFILE in ("restored", "layout", "empty-cache")
RETAINED = PROFILE in ("retained", "restored", "layout", "empty-cache")
DEFERRED = PROFILE in ("deferred", "retained", "restored", "layout", "empty-cache")
ADMISSION = PROFILE in ("admission", "deferred", "retained", "restored", "layout", "empty-cache")
FIELDS = PROFILE in ("fields", "analysis", "loop", "admission", "deferred", "retained", "restored", "layout", "empty-cache")
ANALYSIS = PROFILE in ("analysis", "loop", "admission", "deferred", "retained", "restored", "layout", "empty-cache")
LOOP = PROFILE in ("loop", "admission", "deferred", "retained", "restored", "layout", "empty-cache")
SOURCE_INPUT_COUNT = 96 if EMPTY_CACHE else 93 if LAYOUT else 92 if RETAINED else 82 if DEFERRED else 77 if ADMISSION else 59 if LOOP else 55 if ANALYSIS else 50 if FIELDS else 43
NATIVE_PROOF_TOTAL = 499 if EMPTY_CACHE else 497 if LAYOUT else 492 if RETAINED else 374 if DEFERRED else 371 if ADMISSION else 310 if LOOP else 296 if ANALYSIS else 277 if FIELDS else 230
NATIVE_PROOF_MODULES = len(EXPECTED_PROOFS) + (2 if FIELDS else 0) + (1 if ANALYSIS else 0) + (1 if LOOP else 0) + (3 if ADMISSION else 0) + (1 if DEFERRED else 0) + (10 if RETAINED else 0) + (1 if LAYOUT else 0) + (1 if EMPTY_CACHE else 0)
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
if EMPTY_CACHE:
    SCRIPT_NAMES.append("pskernel-empty-semantic-cache-smoke.mjs")
EMPTY_LATER_LOGS = {"empty-semantic-cache.log"} if EMPTY_CACHE else set()
DEFERRED_LATER_LOGS = ({"deferred-transform.log"} if DEFERRED else set()) | EMPTY_LATER_LOGS
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
RESTORED_PRODUCTION_ROOT = "psc1/packages/pskernel-core/src"
RESTORED_PRODUCTION_TREE = "57b209c4b29f7a9dd67bdae37e728cde4a0ac1ff"
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

LAYOUT_MODULE = "PsKernelExprV2LayoutBoundaryProofs"
LAYOUT_PROOF = "psc1/test/" + LAYOUT_MODULE + ".lean"
LAYOUT_PROOF_BLOB = "923d74270fdc307e58922ad78c44887eaf4041a7"
LAYOUT_PROOF_DIGEST = {"bytes":11733,
    "sha256":"7a56146d72dcd6b6ea8515be962eaba49a1af392d868e76eff6f68ca9fa03c3b"}
LAYOUT_NAMES = [LAYOUT_MODULE+"."+name for name in (
    "shape_valid_establishes_layout",
    "validate_ok_establishes_source_layout",
    "replay_node_ok_preserves_layout",
    "validate_fuel_ok_preserves_layout",
    "validate_ok_establishes_canonical_layout")]
LAYOUT_SCOPE = {
    "shapeGuardEstablishesSourceLayout":True,
    "successfulValidatorEstablishesSourceLayout":True,
    "replayNodePreservesCanonicalLayout":True,
    "validateFuelPreservesCanonicalLayout":True,
    "canonicalOutputLayoutEstablished":True,
    "metadataCorrespondenceEstablished":False,
    "decoderCorrespondenceEstablished":False,
    "replayArenaModelBridgeEstablished":False,
}

EMPTY_BASELINE = "20224a295359abb201f56c72395690bf0bfac9fa"
EMPTY_PRODUCTION_TREE = "62d48691ff7d9680878cf668862017d1061f2ebd"
EMPTY_PRODUCTION = RESTORED_PRODUCTION_ROOT + "/Ps/KernelCore/Runtime/Acceleration/CacheAnalysis.lean"
EMPTY_RETAINED = "psc1/test/PsKernelClosedCacheAnalysisRegression.lean"
EMPTY_MODULE = "PsKernelEmptySemanticCacheProofs"
EMPTY_PROOF = "psc1/test/" + EMPTY_MODULE + ".lean"
EMPTY_HARNESS = "pskernel-empty-semantic-cache-smoke.mjs"
EMPTY_INPUTS = [EMPTY_PRODUCTION,EMPTY_PROOF,"psc1/scripts/"+EMPTY_HARNESS]
EMPTY_NAMES = [EMPTY_MODULE+"."+name for name in
    ("semantic_map_get_eq_before","empty_lookup_ignores_expression")]
EMPTY_PINS = {
    EMPTY_PRODUCTION:(9740,"462d8d839b1e5fd5b5f0620cb18b860d789247aabb4d14c677a0bc69cbc3c16e",
        "d8f8fd5731d0473370a0028d4f484bcb845d9e57"),
    EMPTY_RETAINED:(6106,"ecb1da642bacc61f60806bf0875d4461ac1b6090058edff9d9cd9b94d7d1c61c",
        "0e137de5672d6b63dd8a157cfadc398ca1691d59"),
    EMPTY_PROOF:(1917,"abb7e3dd6b93dec51f9e315e6bd6289ce1869c75744da3beb8a9627edac9606d",
        "57a6e6f2a339fdfddb077baa28e344309812cfc5"),
    "psc1/scripts/"+EMPTY_HARNESS:(4508,"0cce9ce96ace90dcd6ac9cfe1c7a5352d4aca3f05a842fa76e89112961277721",
        "8791063bc6850dec0af726afad8563f78cb63d7e")}
EMPTY_OLD_PRODUCTION = {"path":EMPTY_PRODUCTION,"bytes":9629,
    "sha256":"fe26126cae9c7757d29b3b2193d9530a2de0dc7d5e76a591abb6f2a4b35421bf",
    "gitBlobSha":"4d5ca3d8e2a6136d5fcb35dec131e5c28e6b743b"}
EMPTY_OLD_RETAINED = {"path":EMPTY_RETAINED,"bytes":5877,
    "sha256":"56589278e2918e58b86e7f8d0fe49fe6363a12a71e64ac2c7f44190b4d2406b0",
    "gitBlobSha":"010333b5d6ac53c60c558c89906b02d7358fb0c0"}
EMPTY_OLD_LOOKUP = {"bytes":546,
    "sha256":"d069d0935b36278cf9bcebeeaa23136be12705c23fd68225e4a5aadc01373a22"}
EMPTY_NEW_LOOKUP = {"bytes":648,
    "sha256":"ac51a9646a111fc01442391b53543ea60b778b90e2eb167c956f779f18f22f5a"}
EMPTY_RESULT = {"schema":"psc1-empty-semantic-cache-v1","assertions":21,
    "sectionAssertions":{"harness":1,"empty":20},"coldQueries":20,
    "actualGeneratedConstructors":True,"inputsUnchanged":True,
    "helperOnly":True,"fullKernel":False,"performanceQualified":False}
EMPTY_LABELS = ["harness/rejection"]+["empty/"+str(i).zfill(2) for i in range(20)]
EMPTY_FILE_COUNTS = {"native":172,"generated":337,"canonical":340}

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

def restored_receipt_flags(value,label):
    if RESTORED:
        same(value.get("baselineTransformConstructionRestored"),True,label+" restoration flag")
        same(value.get("deferredTransformConstruction"),False,label+" deferred flag")


def restored_production_sources():
    """Require the complete qualified production tree and exact frozen workers."""
    actual_tree=subprocess.check_output(
        ["git","-C",str(SOURCE_ROOT),"rev-parse",SHA+":"+RESTORED_PRODUCTION_ROOT],
        text=True).strip()
    same(actual_tree,EMPTY_PRODUCTION_TREE if EMPTY_CACHE else RESTORED_PRODUCTION_TREE,
         "entire reviewed empty-cache production tree" if EMPTY_CACHE else
         "entire restored production tree equals qualified10144")
    proof=git_bytes(DEFERRED_PROOF).decode("utf-8")
    require(proof.count("namespace Frozen\n")==1 and proof.count("\nend Frozen")==1,
            "exact frozen worker namespace")
    frozen=proof.split("namespace Frozen\n",1)[1].split("\nend Frozen",1)[0]
    def worker(text,name):
        found=re.search(r"(?ms)^def "+re.escape(name)+r"\n.*?(?=^def |\Z)",text)
        require(found is not None,"missing restored/frozen worker "+name)
        return found.group(0).rstrip()
    records=[]
    for short,oid,name,*_ in DEFERRED_WORKERS:
        path=DEFERRED_PREFIX+short
        raw=git_bytes(path)
        same(git_blob_sha(raw),oid,"entire restored qualified predecessor file "+path)
        body=worker(raw.decode("utf-8"),name)
        same(worker(frozen,name),body,"frozen proof worker byte identity "+name)
        records.append({"path":path,"baselineGitBlob":oid,"targetGitBlob":git_blob_sha(raw),
            "target":digest(raw),"frozenWorker":digest(body.encode("utf-8"))})
    return {"baselineSha":DEFERRED_BASELINE,"baselineBlobs":DEFERRED_BLOBS,
        "productionRoot":RESTORED_PRODUCTION_ROOT,"baselineProductionTree":RESTORED_PRODUCTION_TREE,
        "targetProductionTree":actual_tree,"wholeFilesMatch":True,
        "baselineTransformConstructionRestored":True,"deferredTransformConstruction":False,
        "productionChanges":UNARY_FULL_DELTA if EMPTY_CACHE else [],
        **({"productionChangePolicy":"empty-semantic-cache-plus-unary-spines"} if EMPTY_CACHE else {}),
        "exactBindingMovesOnly":False,"frozenBodiesMatch":True,
        "workers":records,"proof":digest(git_bytes(DEFERRED_PROOF))}


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
        "frozenBodiesMatch":True,"exactBindingMovesOnly":not RESTORED,
        "fullQualification":False,"performanceQualified":False}.items():
        same(source.get(key),value,"deferred source audit "+key)
    if RESTORED:
        restored_receipt_flags(source,"restored source audit")
        if EMPTY_CACHE:
            same(source["productionChanges"],UNARY_FULL_DELTA,"only authenticated cache production delta")
            same(source.get("productionChangePolicy"),"empty-semantic-cache-plus-unary-spines","explicit cache change policy")
            e.check_digest("empty-semantic-cache-source-audit.json",source["emptySemanticCacheSourceAudit"])
        else:
            same(source["productionChanges"],[],"no production delta paths after restoration")
    else:
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
        "restoredTransformSemanticEquality":True,"deferredTransformConstruction":not RESTORED,
        "fullOrdinaryAdmission":True,"fullKernel":False,"performanceQualified":False}.items():
        same(r.get(key),value,"deferred native receipt "+key)
    restored_receipt_flags(r,"restored native374 receipt")
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
        "deferredTransformConstruction":not RESTORED,"fullKernel":False,"performanceQualified":False}.items():
        same(r.get(key),value,"deferred route receipt "+key)
    restored_receipt_flags(r,"restored route receipt")
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
    e.log_digests(r["logs"],{name for name in e.files
        if "/" not in name and name.endswith(".log")} - EMPTY_LATER_LOGS)
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
        "fullOrdinaryAdmission":True,"deferredTransformConstruction":not RESTORED,
        "fullKernel":False,"performanceQualified":False}.items():
        same(r.get(key),value,"retained native receipt "+key)
    restored_receipt_flags(r,"restored native492 receipt")
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


def layout_boundary_native_audit(e):
    """Verify only the five physical-layout obligations and their retained492 parent."""
    require(e.route=="native","Layout proof receipt belongs to native route")
    source=git_bytes(LAYOUT_PROOF)
    same(git_blob_sha(source),LAYOUT_PROOF_BLOB,"exact checked layout proof Git blob")
    same(digest(source),LAYOUT_PROOF_DIGEST,"exact checked layout proof source digest")
    same(e.raw("sources/"+LAYOUT_PROOF),source,"archived layout proof equals exact target")
    raw=e.raw("layout-boundary-proofs.log")
    names=proof_reports(source,raw,LAYOUT_MODULE,5)
    same(names,LAYOUT_NAMES,"five fixed physical-layout theorem names")
    terminal_names=[name for name,_ in re.findall(
        r"'([^']+)' (?:does not depend on any axioms|depends on axioms:\s*\[([^\]]*)\])",
        e.terminal) if name.startswith(LAYOUT_MODULE+".")]
    same(terminal_names,LAYOUT_NAMES,"five actual ordered terminal layout reports")
    status="PSC1_LAYOUT_BOUNDARY_PROOF_STATUS module="+LAYOUT_MODULE+" count=5 countStatus=0 leanStatus=0"
    same(e.raw("layout-boundary-proof-status.log"),(status+"\n").encode(),
         "exact successful layout proof command status")
    line_marker(e.terminal,status)
    records=[]
    for path in ("constructor-native-receipt.json","fields-native-receipt.json",
                 "analysis-native-receipt.json","loop-native-receipt.json",
                 "ordinary-admission-native-receipt.json",
                 "deferred-transform-native-receipt.json","retained-native-receipt.json"):
        records.extend(e.json(path)["proofs"])
    same(len(records),29,"all retained29 proof module records")
    same(sum(record["proofs"] for record in records),492,"all retained492 proof records")
    prior_names=[name for record in records for name in record["names"]]
    require(len(prior_names)==492 and len(set(prior_names))==492,
            "all retained492 theorem names are distinct")
    modules=[record["module"] for record in records]+[LAYOUT_MODULE]
    require(len(modules)==30 and len(set(modules))==30,"all30 proof modules are distinct")
    require(set(prior_names).isdisjoint(names) and len(set(prior_names+names))==497,
            "all497 theorem names are distinct")
    r=e.json("layout-boundary-native-receipt.json"); e.identity(r)
    expected={"schema":"psc1-t05-layout-boundary-native-receipt-v1",
        "sourceSha":SHA,"runId":str(RUN),"runAttempt":str(ATTEMPT),
        "job":"native-header","route":"native","status":"pass",
        "retainedProofs":492,"newProofs":5,"totalProofs":497,"proofModules":30,
        "proofs":[{"module":LAYOUT_MODULE,"proofs":5,"names":names,
                   "source":digest(source),"log":digest(raw)}],
        "orderedUniqueReports":True,"allowedStandardAxiomsOnly":True,
        "retainedNativeReceipt":digest(e.raw("retained-native-receipt.json")),
        "sourceInventory":digest(e.raw("source-inventory.json")),
        "proofStatuses":digest(e.raw("layout-boundary-proof-status.log")),
        **LAYOUT_SCOPE,"fullOrdinaryAdmission":True,
        "baselineTransformConstructionRestored":True,
        "deferredTransformConstruction":False,
        "productionChanges":UNARY_FULL_DELTA if EMPTY_CACHE else False,
        **({"layoutProofProductionChanges":False,
            "emptySemanticCacheSourceAudit":digest(e.raw("empty-semantic-cache-source-audit.json"))}
           if EMPTY_CACHE else {}),
        "fullKernel":False,"performanceQualified":False}
    same(r,expected,"exact layout497 receipt and truthful physical-layout scope")
    logged_json(e.terminal,"PSC1_T05_LAYOUT_BOUNDARY_NATIVE: PASS ",r)
    return {"retainedReports":492,"newReports":5,"totalReports":497,"totalModules":30,
        "allTheoremNamesDistinct":True,"proofNames":names,"physicalLayoutOnly":True,
        **LAYOUT_SCOPE,"source":digest(source),"sourceGitBlob":git_blob_sha(source),
        "retainedNativeReceipt":digest(e.raw("retained-native-receipt.json")),
        "sourceInventory":digest(e.raw("source-inventory.json")),
        "proofStatuses":digest(e.raw("layout-boundary-proof-status.log")),
        "receipt":digest(e.raw("layout-boundary-native-receipt.json"))}


def empty_cache_sources(expected_paths):
    """Authenticate the sole cache change against exact baseline Git bytes."""
    def git(*args):
        return subprocess.check_output(["git","-C",str(SOURCE_ROOT),*args])
    baseline_available=subprocess.run(
        ["git","-C",str(SOURCE_ROOT),"cat-file","-e",EMPTY_BASELINE+"^{commit}"],
        stdout=subprocess.PIPE,stderr=subprocess.PIPE).returncode==0
    if not baseline_available:
        fetched=subprocess.run(["git","-C",str(SOURCE_ROOT),"fetch","--no-tags","--depth=1",
            "origin",EMPTY_BASELINE],stdout=subprocess.PIPE,stderr=subprocess.PIPE)
        require(fetched.returncode==0,"fetch exact baseline Git objects without changing the checkout")
    same(git("rev-parse","HEAD").decode().strip(),SHA,"target HEAD preserved by baseline object fetch")
    same(git("status","--porcelain"),b"","audit target checkout remains clean")
    same(git("rev-parse",EMPTY_BASELINE+"^{commit}").decode().strip(),EMPTY_BASELINE,
         "exact baseline commit object")
    baseline_tree=git("rev-parse",EMPTY_BASELINE+":"+RESTORED_PRODUCTION_ROOT).decode().strip()
    target_tree=git("rev-parse",SHA+":"+RESTORED_PRODUCTION_ROOT).decode().strip()
    same(baseline_tree,RESTORED_PRODUCTION_TREE,"complete qualified20224 production tree")
    same(target_tree,EMPTY_PRODUCTION_TREE,"complete reviewed empty-cache production tree")
    changed=git("diff","--name-only",EMPTY_BASELINE,SHA,"--",RESTORED_PRODUCTION_ROOT).decode().splitlines()
    same(changed,UNARY_FULL_DELTA,"exact one-path production difference")
    baseline=git("show",EMPTY_BASELINE+":"+EMPTY_PRODUCTION)
    prior=git("show",EMPTY_BASELINE+":"+EMPTY_RETAINED)
    same({"path":EMPTY_PRODUCTION,**digest(baseline),"gitBlobSha":git_blob_sha(baseline)},
         EMPTY_OLD_PRODUCTION,"complete qualified predecessor cache file")
    same({"path":EMPTY_RETAINED,**digest(prior),"gitBlobSha":git_blob_sha(prior)},
         EMPTY_OLD_RETAINED,"complete qualified predecessor seven-proof file")
    def section(text,start,end):
        require(text.count(start)==1 and text.count(end)==1,"unique authenticated source section")
        return text[text.index(start):text.index(end,text.index(start))]
    before=baseline.decode("utf-8")
    old=section(before,"def psKernelSemanticExprMapGet\n","\n/- None means")
    after=git_bytes(EMPTY_PRODUCTION).decode("utf-8")
    current=section(after,"def psKernelSemanticExprMapGet\n","\n/- None means")
    old_branch=("  | Option.none =>\n"
        "      if psKernelSemanticCacheEligible expr then\n"
        "        psKernelExprMapGetIn expr cache.small\n"
        "      else\n"
        "        Option.none")
    new_branch=("  | Option.none =>\n"
        "      match cache.small with\n"
        "      | List.nil => Option.none\n"
        "      | List.cons _ _ =>\n"
        "          if psKernelSemanticCacheEligible expr then\n"
        "            psKernelExprMapGetIn expr cache.small\n"
        "          else\n"
        "            Option.none")
    require(old.count(old_branch)==1,"unique old lookup eligibility branch")
    same(current,old.replace(old_branch,new_branch,1),"exact empty-small early-return body")
    same(digest(old.encode()),EMPTY_OLD_LOOKUP,"exact546-byte predecessor lookup")
    same(digest(current.encode()),EMPTY_NEW_LOOKUP,"exact648-byte current lookup")
    expected=before.replace(old,current,1)
    old_comment="/- Small caches retain their original eligibility scan and promotion path."
    new_comment="/- Nonempty small caches retain their original eligibility scan and promotion path."
    require(expected.count(old_comment)==1,"unique reviewed comment correction")
    same(after,expected.replace(old_comment,new_comment,1),"whole production file has only guard and comment changes")
    prior_text=prior.decode("utf-8")
    prior_theorem=section(prior_text,"theorem semantic_map_get_eq\n","\ntheorem semantic_map_insert_eq\n")
    current_proof=git_bytes(EMPTY_RETAINED).decode("utf-8")
    current_theorem=section(current_proof,"theorem semantic_map_get_eq\n","\ntheorem semantic_map_insert_eq\n")
    old_case="  | none => rfl\n  | some index =>"
    new_case=("  | none =>\n"
        "      cases small with\n"
        "      | nil =>\n"
        "          cases h : psKernelSemanticCacheEligible expr <;>\n"
        "            simp [psKernelSemanticExprMapGet, psKernelExprMapGet,\n"
        "              psKernelExprMapGetIn, h]\n"
        "      | cons entry rest => rfl\n"
        "  | some index =>")
    require(prior_theorem.count(old_case)==1,"one retained proof-body case split")
    same(current_theorem,prior_theorem.replace(old_case,new_case,1),"exact sound retained proof repair")
    same(current_theorem.split(":= by",1)[0],prior_theorem.split(":= by",1)[0],
         "retained universal theorem statement unchanged")
    same(current_proof,prior_text.replace(prior_theorem,current_theorem,1),
         "all six other retained proof bodies and declarations unchanged")
    records=[]
    for path,(size,sha,oid) in EMPTY_PINS.items():
        raw=git_bytes(path)
        same(digest(raw),{"bytes":size,"sha256":sha},"pinned empty-cache source "+path)
        same(git_blob_sha(raw),oid,"pinned empty-cache Git blob "+path)
        records.append({"path":path,**digest(raw),"gitBlobSha":oid})
    proof=git_bytes(EMPTY_PROOF).decode("utf-8")
    require(proof.count("namespace Frozen\n\n")==1 and proof.count("\nend Frozen")==1,
            "one literal frozen predecessor helper")
    same(proof.split("namespace Frozen\n\n",1)[1].split("\nend Frozen",1)[0],old,
         "frozen helper byte-identical to authenticated predecessor")
    require(not re.search(r"\b(?:sorry|admit|unsafe|axiom)\b",proof),"no proof escape declarations")
    same(re.findall(r"(?m)^#print axioms (\S+)\s*$",proof),EMPTY_NAMES,
         "two exact universal source declarations")
    baseline_workflow=git("show",EMPTY_BASELINE+":"+WORKFLOW)
    same(git_blob_sha(baseline_workflow),"93ee11a6d2cbb2ffd1188843f01101067fb0b4d1",
         "qualified497 baseline workflow Git blob")
    lists=[ast.literal_eval(value) for value in
        re.findall(r"(?m)^\s*paths = (\[.*\])$",baseline_workflow.decode())]
    require(len(lists)==2 and lists[0]==lists[1] and len(lists[0])==93,
            "qualified93 source inventory definitions")
    same(expected_paths,lists[0]+EMPTY_INPUTS,"exact ordered96 source inventory extension")
    unchanged=[]
    for path in lists[0]:
        if path not in (WORKFLOW,EMPTY_RETAINED):
            old_raw=git("show",EMPTY_BASELINE+":"+path)
            same(git_bytes(path),old_raw,"every other retained source input unchanged "+path)
            unchanged.append({"path":path,"gitBlobSha":git_blob_sha(old_raw),**digest(old_raw)})
    return {"baselineSha":EMPTY_BASELINE,"baselineProductionTree":baseline_tree,
        "targetProductionTree":target_tree,"productionChanges":changed,
        "exactCacheLookupGuardAndCommentOnly":True,"baselineProduction":EMPTY_OLD_PRODUCTION,
        "predecessorLookup":EMPTY_OLD_LOOKUP,"candidateLookup":EMPTY_NEW_LOOKUP,
        "frozenLookupByteExact":True,"retainedProofStatementAndOtherBodiesUnchanged":True,
        "retainedProofBaseline":EMPTY_OLD_RETAINED,"allOtherRetainedInputsUnchanged":True,
        "sourceInputs":96,"proofNames":EMPTY_NAMES,"files":records,
        "otherRetainedInputs":unchanged,"baselineWorkflow":digest(baseline_workflow),
        "baselineObjectsFetched":not baseline_available}


def empty_cache_source_receipt(e):
    require(e.route=="native","empty-cache source authentication is a native receipt")
    checked=REPORT["emptySemanticCacheSources"]
    expected={"schema":"psc1-t09-empty-semantic-cache-source-v1",
        "sourceSha":SHA,"runId":str(RUN),"runAttempt":str(ATTEMPT),
        "job":"native-header","route":"native",
        **{key:checked[key] for key in (
            "baselineSha","baselineProductionTree","targetProductionTree","productionChanges",
            "exactCacheLookupGuardAndCommentOnly","baselineProduction","predecessorLookup","candidateLookup",
            "frozenLookupByteExact","retainedProofStatementAndOtherBodiesUnchanged",
            "retainedProofBaseline","allOtherRetainedInputsUnchanged","sourceInputs","proofNames","files")},
        "sourceInventory":digest(e.raw("source-inventory.json")),
        "baselineTransformConstructionRestored":True,"deferredTransformConstruction":False,
        "fullQualification":False,"performanceQualified":False}
    source=e.json("empty-semantic-cache-source-audit.json");e.identity(source)
    same(source,expected,"whole empty-cache source audit matches independent Git authentication")
    logged_json(e.terminal,"PSC1_T09_EMPTY_SEMANTIC_CACHE_SOURCE: PASS ",source)
    return {"exactThreeProductionPaths":True,"allOtherRetainedInputsUnchanged":True,
        "frozenLookupByteExact":True,"sourceInputs":96,
        "receipt":digest(e.raw("empty-semantic-cache-source-audit.json"))}


def empty_cache_native_audit(e):
    source=git_bytes(EMPTY_PROOF);raw=e.raw("empty-semantic-cache-proofs.log")
    names=proof_reports(source,raw,EMPTY_MODULE,2)
    same(names,EMPTY_NAMES,"two actual ordered empty-cache equations")
    terminal_names=[name for name,_ in re.findall(
        r"'([^']+)' (?:does not depend on any axioms|depends on axioms:\s*\[([^\]]*)\])",
        e.terminal) if name.startswith(EMPTY_MODULE+".")]
    same(terminal_names,EMPTY_NAMES,"two actual executed terminal proof reports")
    status="PSC1_EMPTY_SEMANTIC_CACHE_PROOF_STATUS module="+EMPTY_MODULE+" count=2 countStatus=0 leanStatus=0"
    same(e.raw("empty-semantic-cache-proof-status.log"),(status+"\n").encode(),
         "exact successful empty-cache proof command status")
    line_marker(e.terminal,status)
    records=[]
    for path in ("constructor-native-receipt.json","fields-native-receipt.json",
        "analysis-native-receipt.json","loop-native-receipt.json",
        "ordinary-admission-native-receipt.json","deferred-transform-native-receipt.json",
        "retained-native-receipt.json","layout-boundary-native-receipt.json"):
        previous=e.json(path);e.identity(previous)
        records.extend(previous["proofs"])
    same(len(records),30,"all30 retained proof modules")
    same(sum(row["proofs"] for row in records),497,"all497 retained proof reports")
    prior_names=[name for row in records for name in row["names"]]
    require(len(prior_names)==497 and len(set(prior_names))==497,"497 distinct retained theorem names")
    require(len({row["module"] for row in records}|{EMPTY_MODULE})==31
        and len(set(prior_names+names))==499,"31 distinct modules and499 distinct theorem names")
    expected={"schema":"psc1-t09-empty-semantic-cache-native-receipt-v1",
        "sourceSha":SHA,"runId":str(RUN),"runAttempt":str(ATTEMPT),
        "job":"native-header","route":"native","status":"pass",
        "retainedProofs":497,"newProofs":2,"totalProofs":499,"proofModules":31,
        "proofs":[{"module":EMPTY_MODULE,"proofs":2,"names":names,"source":digest(source),"log":digest(raw)}],
        "orderedUniqueReports":True,"allowedStandardAxiomsOnly":True,
        "retainedLayoutReceipt":digest(e.raw("layout-boundary-native-receipt.json")),
        "sourceAudit":digest(e.raw("empty-semantic-cache-source-audit.json")),
        "sourceInventory":digest(e.raw("source-inventory.json")),
        "proofStatuses":digest(e.raw("empty-semantic-cache-proof-status.log")),
        "productionChanges":UNARY_FULL_DELTA,"emptySemanticCacheSemanticEquality":True,
        "frozenLookupByteExact":True,"retainedProofStatementAndOtherBodiesUnchanged":True,
        "emptySemanticCacheHelperOnly":True,"fullOrdinaryAdmission":True,
        "baselineTransformConstructionRestored":True,"deferredTransformConstruction":False,
        "canonicalOutputLayoutEstablished":True,"metadataCorrespondenceEstablished":False,
        "decoderCorrespondenceEstablished":False,"replayArenaModelBridgeEstablished":False,
        "fullKernel":False,"performanceQualified":False}
    r=e.json("empty-semantic-cache-native-receipt.json");e.identity(r)
    same(r,expected,"exact499 native receipt and unchanged scope limits")
    logged_json(e.terminal,"PSC1_T09_EMPTY_SEMANTIC_CACHE_NATIVE: PASS ",r)
    return {"retainedReports":497,"newReports":2,"totalReports":499,"totalModules":31,
        "allTheoremNamesDistinct":True,"proofNames":names,
        "sourceAudit":digest(e.raw("empty-semantic-cache-source-audit.json")),
        "retainedLayoutReceipt":digest(e.raw("layout-boundary-native-receipt.json")),
        "receipt":digest(e.raw("empty-semantic-cache-native-receipt.json"))}


def empty_cache_route_audit(e):
    r=e.json("empty-semantic-cache-receipt.json")
    provenance=e.json("provenance.json");e.identity(provenance)
    raw=e.raw("empty-semantic-cache.log")
    prefix="PSC1_EMPTY_SEMANTIC_CACHE_ASSERT ";marker="PSC1_EMPTY_SEMANTIC_CACHE_JS: PASS "
    lines=raw.decode("utf-8").splitlines()
    expected_lines=[prefix+EMPTY_LABELS[0],"PSC1_EMPTY_SEMANTIC_CACHE_SECTION harness=1"]
    expected_lines.extend(prefix+name for name in EMPTY_LABELS[1:])
    expected_lines.append("PSC1_EMPTY_SEMANTIC_CACHE_SECTION empty=20")
    same(lines[:-1],expected_lines,"exact ordered21 labels and2 section markers")
    require(len(lines)==24 and lines[-1].startswith(marker),"exact24-line empty-cache runtime transcript")
    same(one_json_line(raw.decode("utf-8"),marker),EMPTY_RESULT,"actual exact21 runtime result")
    same([line for line in e.terminal.splitlines() if line.startswith(prefix)],
         [prefix+name for name in EMPTY_LABELS],"all21 actual terminal labels")
    logged_json(e.terminal,marker,EMPTY_RESULT)
    timing=measurement(e,"empty-semantic-cache.memory")
    logs={name:digest(content) for name,content in sorted(e.files.items())
          if "/" not in name and name.endswith(".log")}
    expected={"schema":"psc1-t09-empty-semantic-cache-route-receipt-v1","status":"pass",
        "identity":provenance,"retainedDeferredReceipt":digest(e.raw("deferred-transform-receipt.json")),
        "result":EMPTY_RESULT,"assertionLabels":EMPTY_LABELS,
        "log":digest(raw),"harness":digest(e.raw("detached/"+EMPTY_HARNESS)),
        **timing,"logs":logs,"emptySemanticCacheHelperOnly":True,
        "baselineTransformConstructionRestored":True,"deferredTransformConstruction":False,
        "fullKernel":False,"performanceQualified":False}
    same(r,expected,"whole final empty-cache route receipt and resource/log chains")
    e.log_digests(r["logs"],set(logs))
    logged_json(e.terminal,"PSC1_T09_EMPTY_SEMANTIC_CACHE_ROUTE: PASS ",r)
    return {"assertions":21,"sections":EMPTY_RESULT["sectionAssertions"],
        "assertionLabels":EMPTY_LABELS,"measurement":timing,"allReceiptLogDigestsMatched":True,
        "receipt":digest(e.raw("empty-semantic-cache-receipt.json")),
        "semanticQualificationOnly":True,"performanceQualified":False}


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



VALIDATOR_MODULES = [
    ("PsKernelExprV2ReplayMetadataProofs", 4),
    ("PsKernelExprV2SemanticPrefixProofs", 8),
    ("PsKernelExprV2DecodedNodeProofs", 2),
    ("PsKernelExprV2DecodedBridgeProofs", 12),
    ("PsKernelExprV2ArenaModelBridgeProofs", 7),
]
VALIDATOR_PROOF_PINS = {
    "PsKernelExprV2ReplayMetadataProofs": "bcf3abfdb5d2cee6513ff7db81000fcf8dd6accb16bf9b4761280f08acd20e46",
    "PsKernelExprV2SemanticPrefixProofs": "358dedf8b06be615d2f86ea3738d91b19966469f72dc33c77047e1af7136ea6e",
    "PsKernelExprV2DecodedNodeProofs": "0720db5abc1922656c47d1f2b251efa9f4b23fafc8d12932dbaec0a822a25d27",
    "PsKernelExprV2DecodedBridgeProofs": "c97baa13eea76cd5ef5076a4277f517a1748014ee3a49d06f4b5ef68765085b3",
    "PsKernelExprV2ArenaModelBridgeProofs": "2699f6a6bd9d8d0d793a8eb2d398293f43255d79bd8f5c84d1033be393d72af3",
}
VALIDATOR_LAYERS = [
    "constructor-native-receipt.json", "fields-native-receipt.json",
    "analysis-native-receipt.json", "loop-native-receipt.json",
    "ordinary-admission-native-receipt.json", "deferred-transform-native-receipt.json",
    "retained-native-receipt.json", "layout-boundary-native-receipt.json",
    "empty-semantic-cache-native-receipt.json",
]
VALIDATOR_NATIVE_COPY = None


def validator_audit(e):
    """Read archive bytes directly; never execute the producer verifier."""
    global VALIDATOR_NATIVE_COPY
    source_paths = ["psc1/test/" + module + ".lean" for module, _ in VALIDATOR_MODULES[:-1]]
    source_paths += ["psc1/packages/pskernel-core/src/Ps/KernelCore/Core/ExprV2/" + name + ".lean"
                     for name in ["Builder", "Decode", "Node", "Paged", "Validation"]]
    source_paths += ["psc1/test/PsKernelExprV2MetadataProofs.lean",
                     "psc1/test/PsKernelExprV2PagedModelProofs.lean",
                     "psc1/test/PsKernelExprV2ArenaModelBridgeProofs.lean",
                     "psc1/test/PsKernelOrdinaryOccurrenceProofs.lean",
                     "psc1/scripts/pskernel-validator-qualification.py", WORKFLOW]
    expected_members = {"validator/sources/" + path for path in source_paths}
    expected_members |= {"validator/" + module + ".log" for module, _ in VALIDATOR_MODULES}
    expected_members |= {"validator/source-inventory.json", "validator/proof-status.json",
                         "validator/native-receipt.json"}
    if e.route != "native":
        expected_members.add("validator/route-receipt.json")
    same({name for name in e.files if name.startswith("validator/")}, expected_members,
         "complete exact validator artifact membership")
    source_inventory = e.json("validator/source-inventory.json")
    rows = []
    for path in source_paths:
        original = git_bytes(path)
        same(e.raw("validator/sources/" + path), original, "validator exact Git source " + path)
        rows.append({"path": path, **digest(original)})
    for module, _ in VALIDATOR_MODULES:
        same(digest(git_bytes("psc1/test/" + module + ".lean"))["sha256"],
             VALIDATOR_PROOF_PINS[module], "isolated audited proof bytes " + module)
    expected_inventory = {
        "schema": "psc1-validator-source-v1", "sourceSha": SHA,
        "runId": str(RUN), "runAttempt": str(ATTEMPT),
        "isolatedProofSource": "e652d02a69ebcaaeb5b4fe0b391e368efebf18e7",
        "arenaModelProofSource": "150123e5fb8e17d8fab4d737a043705727ee1bcc",
        "productionSource": "dbd9db47bd8ef184583bcd5ae3feb38f3ce612c5",
        "productionTree": "62d48691ff7d9680878cf668862017d1061f2ebd", "files": rows}
    same(source_inventory, expected_inventory, "entire independent validator source inventory")
    statuses = [{"module": module, "count": count, "exitCode": 0}
                for module, count in VALIDATOR_MODULES]
    same(e.json("validator/proof-status.json"), statuses, "four successful new proof commands")
    added = []
    for module, count in VALIDATOR_MODULES:
        source = git_bytes("psc1/test/" + module + ".lean")
        raw = e.raw("validator/" + module + ".log")
        names = proof_reports(source, raw, module, count)
        if e.route == "native":
            terminal_names = [name for name, _ in re.findall(
                r"'([^']+)' (?:does not depend on any axioms|depends on axioms:\s*\[([^\]]*)\])",
                e.terminal) if name.startswith(module + ".")]
            same(terminal_names, names, "actual terminal new proof reports " + module)
        added.append({"module": module, "proofs": count, "names": names,
                      "source": digest(source), "log": digest(raw)})
    native = e.json("validator/native-receipt.json")
    if e.route == "native":
        retained = []
        layers = {}
        for path in VALIDATOR_LAYERS:
            retained.extend(e.json(path)["proofs"])
            layers[path] = digest(e.raw(path))
        same(len(retained), 31, "all retained native modules")
        expected_native = {
            "schema": "psc1-validator-native-v1", "sourceSha": SHA,
            "runId": str(RUN), "runAttempt": str(ATTEMPT), "status": "pass",
            "retainedProofs": 499, "newProofs": 33, "totalProofs": 532, "proofModules": 36,
            "proofs": retained + added, "retainedLayers": layers,
            "sourceInventory": digest(e.raw("validator/source-inventory.json")),
            "proofStatuses": digest(e.raw("validator/proof-status.json")),
            "productionTree": "62d48691ff7d9680878cf668862017d1061f2ebd", "productionChanges": UNARY_DELTA,
            "metadataCorrespondenceEstablished": True, "decoderCorrespondenceEstablished": True,
            "untrustedSourceValidityAssumed": False, "replayArenaModelBridgeEstablished": True,
            "fullKernel": False, "performanceQualified": False}
        same(native, expected_native, "entire532 native receipt")
        names = [name for row in native["proofs"] for name in row["names"]]
        same(len(names), 532, "532 actual reports")
        same(len(set(names)), 532, "532 globally distinct theorem names")
        same(len({row["module"] for row in native["proofs"]}), 36, "36 globally distinct modules")
        logged_json(e.terminal, "PSC1_VALIDATOR_NATIVE532: PASS ", native)
        VALIDATOR_NATIVE_COPY = {name: data for name, data in e.files.items() if name.startswith("validator/")}
    else:
        require(VALIDATOR_NATIVE_COPY is not None, "Native actual ZIP must be audited first")
        for name, data in VALIDATOR_NATIVE_COPY.items():
            same(e.raw(name), data, "cross-route same native artifact bytes " + name)
        expected_route = {
            "schema": "psc1-validator-route-v1", "sourceSha": SHA,
            "runId": str(RUN), "runAttempt": str(ATTEMPT), "status": "pass",
            "route": e.route, "nativeProofs": 532,
            "nativeReceipt": digest(e.raw("validator/native-receipt.json")),
            "retainedRouteReceipt": digest(e.raw("empty-semantic-cache-receipt.json")),
            "kernel": e.json("provenance.json")["kernel"], "productionChanges": UNARY_DELTA,
            "metadataCorrespondenceEstablished": True, "decoderCorrespondenceEstablished": True,
            "replayArenaModelBridgeEstablished": True, "fullKernel": False, "performanceQualified": False}
        same(e.json("validator/route-receipt.json"), expected_route, "entire source-bound validator route receipt")
        logged_json(e.terminal, "PSC1_VALIDATOR_ROUTE532: PASS ", expected_route)
    return {"status": "pass", "nativeReports": 532, "nativeModules": 36,
            "additionalSourceInputs": 15, "addedReports": 33,
            "crossRouteNativeBytesVerified": e.route != "native",
            "metadataCorrespondenceEstablished": True, "decoderCorrespondenceEstablished": True,
            "replayArenaModelBridgeEstablished": True, "fullKernel": False, "performanceQualified": False}



UNARY_DELTA = ["psc1/packages/pskernel-core/src/Ps/KernelCore/Checker/ExprV2/DefEq/FullShape.lean","psc1/packages/pskernel-core/src/Ps/KernelCore/Checker/ExprV2/DefEq/UnarySpines.lean"]
UNARY_FULL_DELTA = ["psc1/packages/pskernel-core/src/Ps/KernelCore/Checker/ExprV2/DefEq/FullShape.lean","psc1/packages/pskernel-core/src/Ps/KernelCore/Checker/ExprV2/DefEq/UnarySpines.lean","psc1/packages/pskernel-core/src/Ps/KernelCore/Runtime/Acceleration/CacheAnalysis.lean"]
UNARY_PINS = {"psc1/packages/pskernel-core/src/Ps/KernelCore/Checker/ExprV2/DefEq/FullShape.lean":{"bytes":20939,"sha256":"bd66aa2e8cc039406b76d8e24459d3d9107e579c7e17ed5432cf192b38e3e2d2"},"psc1/packages/pskernel-core/src/Ps/KernelCore/Checker/ExprV2/DefEq/UnarySpines.lean":{"bytes":3754,"sha256":"0a5eb430466bff2fa3f3f00384b5ac7f22dc62bbc0505429ca52494259a8e26e"},"psc1/test/PsKernelUnarySpineProofs.lean":{"bytes":11532,"sha256":"4098607f1b2d5874f998d69bb732ab9150a5031c1ab584e4e524b23d0a6340c2"},"psc1/test/PsKernelChurchSource.lean":{"bytes":21080,"sha256":"5f723e4b184c9134128552fe8186064dd0b291a42e54ecc575d210d339dd0a30"},"psc1/test/PsKernelChurchStageProbe.lean":{"bytes":6043,"sha256":"3601231d19268d33474697a2058a7ada58918ce5a8d11b56da263b4377e41a32"},"psc1/scripts/pskernel-unary-spine-smoke.mjs":{"bytes":5583,"sha256":"9053a5bfc66687c7d1529c6f18179bfb97ced1e41ac0dd3d24ae039d60612d2b"},"psc1/scripts/pskernel-church-fixture.py":{"bytes":5437,"sha256":"9053ae13a6df9fd542ab9f76177f4daea4835fa68c661b1d1c1b446c06608ddf"},"psc1/scripts/pskernel-church-stages.mjs":{"bytes":4798,"sha256":"d008052b8bb6ecab9c0b0fc5c7c43a2de66304da03e34016c0396cfee947f11d"}}
UNARY_NATIVE_COPY = None
UNARY_PROOF_NAMES = ["psKernelUnaryPlanZero","psKernelUnaryPlanStops","psKernelUnaryPlanPreserves","psKernelUnaryPlanSkippedBound","psKernelUnaryViewHasSharedHead","psKernelUnaryPlanExpressionCongruence","psKernelUnaryContextZero","psKernelUnaryPlanTerminates","psKernelUnaryCallbackOwner"]
UNARY_LABELS = ['harness/rejection','arena/canonical','view/shared-head','view/different-head',
    'view/distinct-id-conservative','view/non-fvar','plan/zero','plan/structural-exhaustion',
    'plan/exact-residual','plan/canonical-depth-bound','callback/exact-owner-once',
    'shortcut/positive-only','fallback/false','fallback/decline','fallback/error',
    'shortcut/one-layer-declines','resource/depth-guard','resource/three-scopes',
    'boundary/invalid-id','ownership/inputs-unchanged']

def unary_source_authentication():
    baseline='dbd9db47bd8ef184583bcd5ae3feb38f3ce612c5'
    def git(*args):
        return subprocess.check_output(['git','-C',str(SOURCE_ROOT),*args])
    if subprocess.run(['git','-C',str(SOURCE_ROOT),'cat-file','-e',baseline+'^{commit}'],
            stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL).returncode:
        subprocess.run(['git','-C',str(SOURCE_ROOT),'fetch','--no-tags','--depth=1','origin',baseline],check=True)
    same(git('status','--porcelain'),b'','clean independent source checkout')
    same(git('rev-parse',baseline+':psc1/packages/pskernel-core/src').decode().strip(),
        'e567685e5c441a5b0a78d8241f7bae151b48b5ca','qualified unary baseline production tree')
    same(git('diff','--name-only',baseline,SHA,'--','psc1/packages/pskernel-core/src').decode().splitlines(),
        UNARY_DELTA,'complete independently authenticated unary production delta')
    for path,pin in UNARY_PINS.items():
        same(digest(git_bytes(path)),pin,'independent reviewed unary source pin '+path)
    path=UNARY_DELTA[0]
    current=git_bytes(path).decode()
    start=current.index('/- A positive congruence shortcut.')
    end=current.index('def psKernelExprV2DefEqFullShapeEtaOwnedWith\n',start)
    restored=current[:start]+current[end:]
    restored=restored.replace('import Ps.KernelCore.Checker.ExprV2.DefEq.UnarySpines\n','',1)
    restored=restored.replace('def psKernelExprV2DefEqFullShapeAppOriginalWith\n',
        'def psKernelExprV2DefEqFullShapeAppWith\n',1)
    same(restored.encode(),git('show',baseline+':'+path),'entire retained full-shape rule unchanged beneath positive wrapper')
    return {'baseline':baseline,'productionTree':EMPTY_PRODUCTION_TREE,
        'productionChanges':UNARY_DELTA,'retainedFullShapeBodyByteIdentical':True,
        'reviewedSourcePins':UNARY_PINS}

def unary_church(e,label,runtime,mode):
    base='unary/'+label
    status=e.json(base+'.status.json')
    same(status.get('timedOut'),False,'Church actual host limit')
    same(status.get('exitCode'),0,'Church actual exit0')
    require(type(status.get('seconds')) in (int,float) and 0<=status['seconds']<60,'bounded original process duration')
    measurement=e.text(base+'.time').strip()
    require(re.fullmatch(r'peak_rss_kib=\d+ wall_seconds=\d+(?:\.\d+)? exit_status=0',measurement) is not None,
        'actual Church process measurement')
    text=e.text(base+'.stdout')
    marker='PSC1_ARENA_REPLAY ' if runtime!='native' and mode=='baseline' else 'PSC1_CHURCH_RESULT '
    result=one_json_line(text,marker)
    same(result.get('verdict'),'accepted','actual original Church acceptance')
    same(str(result.get('fuel')),'4096','unchanged authentic Church fuel')
    if mode=='stages':
        stages=[json.loads(line.split(' ',1)[1]) for line in text.splitlines() if line.startswith('PSC1_CHURCH_STAGE ')]
        same([(x['stage'],x['status']) for x in stages],
            [(s,'ok') for s in ['header','is-prop','body-static','body-check','final-defeq']],
            'all five actual owner-threaded stages accepted')
        prefix=one_json_line(text,'PSC1_CHURCH_PREFIX ')
        same({k:str(v) for k,v in prefix.items()},
            {'requests':'3','sourceNodes':'197','ownedNodes':'249','declarations':'5'},'actual independently admitted prefix')
    return result

def unary_audit(e):
    global UNARY_NATIVE_COPY
    paths=list(UNARY_PINS)+[
        'psc1/scripts/pskernel-unary-spine-qualification.py',WORKFLOW,
        'psc1/scripts/pskernel-validator-qualification.py',
        'psc1/scripts/pskernel-arena-replay.mjs','psc1/scripts/pskernel-arena435-oracle.py',
        'psc1/kernel-lakefile.lean','psc1/lean-toolchain']
    rows=[{'path':p,**digest(git_bytes(p))} for p in paths]
    expected_source={'schema':'psc1-unary-source-v1','sourceSha':SHA,'runId':str(RUN),
        'runAttempt':str(ATTEMPT),'productionTree':EMPTY_PRODUCTION_TREE,
        'baselineSource':'dbd9db47bd8ef184583bcd5ae3feb38f3ce612c5',
        'baselineProductionTree':'e567685e5c441a5b0a78d8241f7bae151b48b5ca',
        'productionChanges':UNARY_DELTA,'files':rows,'fuel':4096}
    same(e.json('unary/source-inventory.json'),expected_source,'entire actual unary source inventory')
    for p in paths:
        same(e.raw('unary/sources/'+p),git_bytes(p),'unary archived Git source '+p)
    members={'unary/sources/'+p for p in paths}|{'unary/source-inventory.json'}
    if e.route=='native':
        members|={'unary/'+n for n in ['proof.log','arena.tar.gz','input.ndjson',
            'input-provenance.json','native-lakefile.lean','native-build.log','native-receipt.json']}
        for mode in ['baseline','stages']:
            members|={'unary/church-native-'+mode+s for s in ['.stdout','.stderr','.time','.status.json']}
        require('Build completed successfully' in e.text('unary/native-build.log'),'actual complete native probe build')
        expected_config=git_bytes('psc1/kernel-lakefile.lean').decode()+'''
lean_lib PsKernelChurchLiteralSource where
  srcDir := "test"
  roots := #[`PsKernelChurchSource]

lean_exe psc1_kernel_church_stages where
  srcDir := "test"
  root := `PsKernelChurchStageProbe
'''
        same(e.text('unary/native-lakefile.lean'),expected_config,'exact append-only native build configuration')
        corpus=e.raw('unary/arena.tar.gz')
        same(digest(corpus),{'bytes':3497743,'sha256':'98a69742b538296c5f413d0527dfeef8c4d1815fe64b12c8623cd33de63bee0d'},
            'actual original pinned corpus archive')
        data=e.raw('unary/input.ndjson')
        same(digest(data)['sha256'],'443428491e773dc131b1655bf72312517ddc29010112bb8bb241a48ab55c51c1','actual original adapted Church input')
        same(digest(data.partition(b'\n')[2])['sha256'],'85526c244d94e9710a6be432164c054c742d8f7c1d3ca0d8580d0874f7815a47','actual unchanged Church declaration body')
        source=git_bytes('psc1/test/PsKernelUnarySpineProofs.lean').decode()
        same(re.findall(r'(?m)^#print axioms (\S+)\s*$',source),UNARY_PROOF_NAMES,'exact nine universal source statements')
        log=e.text('unary/proof.log')
        reports=re.findall(r"'([^']+)' (?:depends on axioms:\s*\[([^\]]*)\]|does not depend on any axioms)",log)
        same([n for n,_ in reports],UNARY_PROOF_NAMES,'nine actual ordered reports')
        require(not any(x in log for x in ['sorryAx','Lean.ofReduceBool','Lean.trustCompiler']), 'no trusted computation or unfinished proof dependency')
        require(not re.search(r'\.lean:\d+:\d+: error',log),'no actual new proof diagnostic')
        for _,used in reports:
            require({a.strip() for a in used.split(',') if a.strip()}<={'propext','Classical.choice','Quot.sound'},'standard axioms only')
        retained=e.json('validator/native-receipt.json')
        old_names=[n for row in retained['proofs'] for n in row['names']]
        same(len(set(old_names+UNARY_PROOF_NAMES)),541,'541 distinct actual reports')
        results={mode:unary_church(e,'church-native-'+mode,'native',mode) for mode in ['baseline','stages']}
        receipt={'schema':'psc1-unary-native-v1','sourceSha':SHA,'runId':str(RUN),'runAttempt':str(ATTEMPT),
            'status':'pass','productionTree':EMPTY_PRODUCTION_TREE,'retainedProofs':532,'newProofs':9,
            'totalProofs':541,'proofModules':37,'names':UNARY_PROOF_NAMES,
            'newProofSource':digest(git_bytes('psc1/test/PsKernelUnarySpineProofs.lean')),
            'newProofLog':digest(e.raw('unary/proof.log')),
            'retainedReceipt':digest(e.raw('validator/native-receipt.json')),
            'sourceInventory':digest(e.raw('unary/source-inventory.json')),
            'church':results,'fuel':4096,'fullKernel':False,'performanceQualified':False}
        same(e.json('unary/native-receipt.json'),receipt,'entire independent native541 receipt')
        logged_json(e.terminal,'PSC1_UNARY_NATIVE541: PASS ',receipt)
        UNARY_NATIVE_COPY={n:e.raw('unary/'+n) for n in ['native-receipt.json','proof.log','input.ndjson','input-provenance.json']}
    else:
        require(UNARY_NATIVE_COPY is not None,'native evidence precedes route auditing')
        for n,raw in UNARY_NATIVE_COPY.items():
            members.add('unary/native-'+n)
            same(e.raw('unary/native-'+n),raw,'exact native/runtime evidence bytes '+n)
        for label in ['unary-controls','church-baseline','church-stages']:
            members|={'unary/'+label+s for s in ['.stdout','.stderr','.time','.status.json']}
        members.add('unary/route-receipt.json')
        labels=[line.split(' ',1)[1] for line in e.text('unary/unary-controls.stdout').splitlines() if line.startswith('PSC1_UNARY_SPINE_ASSERT ')]
        same(labels,UNARY_LABELS,'exact20 real executed helper controls')
        summary=one_json_line(e.text('unary/unary-controls.stdout'),'PSC1_UNARY_SPINE_JS: PASS ')
        same(summary,{'schema':'psc1-unary-spine-v1','assertions':20,'labels':UNARY_LABELS,
            'actualGeneratedConstructors':True,'helperOnly':True,'fullKernel':False,'performanceQualified':False},
            'complete independent20-control result')
        status=e.json('unary/unary-controls.status.json')
        require(status['timedOut'] is False and status['exitCode']==0 and status['seconds']<60,'bounded actual helper process')
        for n in ['pskernel-unary-spine-smoke.mjs','pskernel-arena-replay.mjs','pskernel-church-stages.mjs']:
            same(e.raw('detached/'+n),git_bytes('psc1/scripts/'+n),'exact executed generated harness '+n)
        driver=git_bytes('psc1/scripts/pskernel-arena-replay.mjs').decode()
        anchor="    const result=accepted(get('psKernelV1RunDag')(session,nil,S.safe,arena,list(commands)),'kernel-admission');"
        same(driver.count(anchor),1,'one original production admission boundary')
        transport="import {runChurchStages} from './pskernel-church-stages.mjs';\n"+driver.replace(anchor,
            "    return runChurchStages(kernel,{arena,commands,session,nil,safety:S.safe,list,array,request:order[3].request});")
        same(e.text('detached/church-diagnostic-transport.mjs'),transport,'exact diagnostic transport insertion')
        runner="import {readFileSync} from 'node:fs';\nimport * as kernel from './kernel.mjs';\nimport {replayText} from './church-diagnostic-transport.mjs';\nreplayText(kernel,readFileSync('church-input.ndjson','utf8'));\n"
        same(e.text('detached/church-staged-runner.mjs'),runner,'exact same-kernel staged entry')
        same(e.raw('detached/church-input.ndjson'),UNARY_NATIVE_COPY['input.ndjson'],'exact generated Church body')
        results={mode:unary_church(e,'church-'+mode,e.route,mode) for mode in ['baseline','stages']}
        receipt={'schema':'psc1-unary-route-v1','sourceSha':SHA,'runId':str(RUN),'runAttempt':str(ATTEMPT),
            'status':'pass','route':e.route,'productionTree':EMPTY_PRODUCTION_TREE,'nativeProofs':541,
            'newRuntimeControls':summary,'church':results,'kernel':digest(e.raw('detached/kernel.mjs')),
            'retainedReceipt':digest(e.raw('validator/route-receipt.json')),
            'nativeReceipt':digest(UNARY_NATIVE_COPY['native-receipt.json']),
            'sourceInventory':digest(e.raw('unary/source-inventory.json')),
            'fuel':4096,'processLimitSeconds':60,'oldSpaceMiB':2048,'emptyPATH':True,
            'fullKernel':False,'performanceQualified':False}
        same(e.json('unary/route-receipt.json'),receipt,'entire independently checked generated541 receipt')
        logged_json(e.terminal,'PSC1_UNARY_ROUTE541: PASS ',receipt)
    same({p for p in e.files if p.startswith('unary/')},members,'exact complete unary artifact member set')
    return {'status':'pass','nativeReports':541,'nativeModules':37,'originalChurchAccepted':True,
        'runtimeControls':0 if e.route=='native' else 20,'fuel':4096,'fullKernel':False,'performanceQualified':False}


def main():
    require(os.environ.get("RUNNER_OS") == "Linux","This audit runs on GitHub Linux only")
    require(os.environ.get("GITHUB_ACTIONS") == "true","GitHub Actions required")
    require(TOKEN,"Missing read-only GitHub token")
    require(CONFIG.get("unary") is True and VALIDATOR and EMPTY_CACHE,"Complete unary extension required")
    require(PROFILE in ("helpers","fields","analysis","loop","admission","deferred","retained","restored","layout","empty-cache"),"Unknown audit profile")
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
    if EMPTY_CACHE:
        REPORT["emptySemanticCacheSources"] = empty_cache_sources(expected_paths)
    if LAYOUT:
        require(LAYOUT_PROOF in expected_paths,"explicit layout proof source inventory member")
        same(git_blob_sha(git_bytes(LAYOUT_PROOF)),LAYOUT_PROOF_BLOB,"pinned five-report layout proof Git blob")
        same(digest(git_bytes(LAYOUT_PROOF)),LAYOUT_PROOF_DIGEST,"pinned five-report layout proof source")
        REPORT["layoutBoundarySource"]={"path":LAYOUT_PROOF,"gitBlobSha":LAYOUT_PROOF_BLOB,
            **LAYOUT_PROOF_DIGEST,"proofNames":LAYOUT_NAMES,"physicalLayoutOnly":True}
    if RETAINED:
        require(set(RETAINED_INPUTS) <= set(expected_paths),"ten explicit retained native proof inputs")
    if DEFERRED:
        require(set(DEFERRED_INPUTS) <= set(expected_paths),"five explicit deferred production/proof/harness inputs")
        if RESTORED:
            REPORT["baselineTransformSources"] = restored_production_sources()
        else:
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
    REPORT["unarySpineSources"] = unary_source_authentication()
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
            if EMPTY_CACHE:
                same(len(files),{"native":226,"generated":401,"canonical":404}[route],"exact complete unary qualification archive member count")
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
            if EMPTY_CACHE and route == "native":
                result["emptySemanticCacheSourceAuthentication"] = empty_cache_source_receipt(evidence)
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
                label = "baselineTransformQualification" if RESTORED else "deferredTransformQualification"
                result[label] = deferred_native_audit(evidence) if route == "native" else deferred_route_audit(evidence)
            if RETAINED and route == "native":
                result["retainedNativeQualification"] = retained_native_audit(evidence)
            if LAYOUT and route == "native":
                result["layoutBoundaryQualification"] = layout_boundary_native_audit(evidence)
            if EMPTY_CACHE:
                result["emptySemanticCacheQualification"] = empty_cache_native_audit(evidence) if route == "native" else empty_cache_route_audit(evidence)
            if VALIDATOR:
                result["validatorQualification"] = validator_audit(evidence)
            result["unarySpineQualification"] = unary_audit(evidence)
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
    REPORT["metadataCorrespondenceEstablished"] = True
    REPORT["decoderCorrespondenceEstablished"] = True
    REPORT["replayArenaModelBridgeEstablished"] = True
    REPORT["unarySpineLocalRefinementQualified"] = True
    REPORT["scope"] = {
        "constructorHelpersQualified":True,"fullT05AdmissionQualified":ADMISSION,
        "ordinaryAdmissionQualified":ADMISSION,"publicRoutingQualified":ADMISSION,"fullKernelQualified":False,
        "projectB":"OPEN","projectC":"FAIL","projectD":"OPEN",
        "nativeProofReports":541,"nativeProofModules":37,
        "nativeAssertions":{"params":284,"result":432,
            **({"fields":268} if FIELDS else {}),**({"analysis":93} if ANALYSIS else {}),
            **({"loop":69} if LOOP else {}),
            **({"elimination":116,"privateAdmission":143,"publicRouting":12} if ADMISSION else {})},
        "eachGeneratedRouteAssertions":{"header":1992,"cache":1884,"params":268,"result":432,
            **({"fields":268} if FIELDS else {}),**({"analysis":93} if ANALYSIS else {}),
            **({"loop":69} if LOOP else {}),
            **({"elimination":116,"privateAdmission":143,"publicRouting":12} if ADMISSION else {}),
            **({("rawTransform" if RESTORED else "deferredTransform"):23} if DEFERRED else {}),
            **({"emptySemanticCache":21} if EMPTY_CACHE else {})},
        "constructorFieldsQualified":FIELDS,"singleConstructorAnalysisQualified":ANALYSIS,
        "constructorLoopQualified":LOOP,"profile":PROFILE,
        "deferredTransformQualified":DEFERRED and not RESTORED,"retainedNativeProofsQualified":RETAINED,
        **({"baselineTransformConstructionRestored":True,"deferredTransformConstruction":False,
            "baselineTransformRestorationQualified":True} if RESTORED else {}),
        **({"layoutBoundaryQualified":True,**LAYOUT_SCOPE} if LAYOUT else {}),
        **({"emptySemanticCacheSemanticQualification":True,"emptySemanticCacheHelperOnly":True,
            "productionChanges":UNARY_FULL_DELTA,"optimizationAdopted":False,
            "emptySemanticCachePerformanceQualified":False} if EMPTY_CACHE else {}),
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
            "nativeReports":541 if REPORT["status"] == "pass" else None,
            "nativeModules":37 if REPORT["status"] == "pass" else None,
            "profile":PROFILE,
            **({"deferredTransformQualified":REPORT["status"] == "pass" and not RESTORED} if DEFERRED else {}),
            **({"baselineTransformConstructionRestored":REPORT["status"] == "pass",
                "baselineTransformRestorationQualified":REPORT["status"] == "pass"} if RESTORED else {}),
            **({"retainedNativeProofsQualified":REPORT["status"] == "pass"} if RETAINED else {}),
            **({"layoutBoundaryQualified":REPORT["status"] == "pass",
                "canonicalOutputLayoutEstablished":REPORT["status"] == "pass",
                "metadataCorrespondenceEstablished":REPORT["status"] == "pass","decoderCorrespondenceEstablished":REPORT["status"] == "pass",
                "replayArenaModelBridgeEstablished":REPORT["status"] == "pass"} if LAYOUT else {}),
            **({"emptySemanticCacheSemanticQualification":REPORT["status"] == "pass",
                "emptySemanticCacheHelperOnly":True,"productionChanges":UNARY_FULL_DELTA,
                "optimizationAdopted":False,"emptySemanticCachePerformanceQualified":False}
               if EMPTY_CACHE else {}),
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

