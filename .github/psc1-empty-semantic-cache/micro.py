#!/usr/bin/env python3
"""Authenticate existing leaf artifacts, then run the fixed helper-only protocol."""
import hashlib, importlib.util, json, os, pathlib, re, shutil, stat, statistics
import subprocess, sys, zipfile

REPO = "dwijayuda/pskernel"
BASE = "20224a295359abb201f56c72395690bf0bfac9fa"
CANDIDATE = "e503972553ae2d41d5ba7a26d7739fb32ee86b96"
PRODUCER = "80182d1b95894fc3daa5c7fbcfe8b1a7adb687d9"
COMPILER = "80005bb250a7324772db76d51684d23fbf0fe6ed"
WORKFLOW = ".github/workflows/psc1-empty-semantic-cache-micro.yml"
DRIVER = ".github/psc1-empty-semantic-cache/micro.py"
WORKER = "psc1/scripts/pskernel-empty-semantic-cache-micro.mjs"
WORKER_SHA = "1e13989ff42143b9b5d6bf8686d4e1405d64e5f1f626161afe0ac00a30551ffa"
PROTOCOL = "psc1/packages/pskernel-core/docs/T09_EMPTY_SEMANTIC_CACHE_MICROBENCH_PROTOCOL.md"
PROTOCOL_BLOB = "285fcb439f3567f9697c3d0046e129c140b0cee5"
PROTOCOL_SHA = "3982b235c6c45c783ea5a1fa2eeedeea0f72bf07f1ea48e3bdf6651dd0b6be2e"
LEAF_FILES = {
 ".github/workflows/psc1-empty-semantic-cache-leaf.yml":
  ("3157ec79aaae99df7c324723d3987ab369010ed4",
   "df5843fcad4cf6c9346e45b329551531e63c2890e34f2a344a30308f70eba2bf"),
 ".github/psc1-empty-semantic-cache/leaf.py":
  ("7556f7d827f9c96fbb517ad9073e8752b9f1142c",
   "abf7848400b9ad6b2feb8109ec8474e7eccbe35be4c5d706d32464ab140c48e5"),
 "psc1/scripts/pskernel-empty-semantic-cache-smoke.mjs":
  ("8791063bc6850dec0af726afad8563f78cb63d7e",
   "0cce9ce96ace90dcd6ac9cfe1c7a5352d4aca3f05a842fa76e89112961277721")}
SPEC = {
 "source":PRODUCER, "run":40158333460, "attempt":1, "job":121064387870,
 "jobName":"paired", "artifact":12585423993,
 "name":"psc1-empty-semantic-cache-paired-leaf-attempt-1", "size":5226483,
 "sha256":"adf655c16ab115565e3bbeb8204cc2d1d25c8fa98b495d0bd8849926986e4d63",
 "workflow":".github/workflows/psc1-empty-semantic-cache-leaf.yml"}
REPORT_SHA = "cb15be03900075c4124965d2262e5dadaad1fa9fe13ce4f9fea72543c21cc612"
KERNELS = {
 "baseline": {"source":BASE, "bytes":360259,
  "sha256":"47c320361a197b3bfe4eeb16c7a95375ceed26869375d1fd941ed7c2cb34021e",
  "receipt":"776e4c512466b16d497d74aa9dc04365d2f841b5f0a1e6c6fbc4ba0076eddcc7"},
 "candidate": {"source":CANDIDATE, "bytes":360611,
  "sha256":"067b7c540f340ccfc12b730156f5fdee0fa288ec4b784640f788a8e1eec0d554",
  "receipt":"5d30641c6b59039c62e6eaf2b80e73435201eb59a15ca2a1f9ce833a8074e866"}}
CASES = [
 ("empty/shallow",1000000), ("empty/deep",10000),
 ("empty/early-open",1000000), ("empty/late-open",10000),
 ("small/hit",1000000), ("small/deep-miss",10000),
 ("small/early-open",1000000), ("small/late-open",10000),
 ("indexed/hit",1000000), ("indexed/deep-miss",10000),
 ("indexed/early-open",1000000), ("indexed/late-open",10000),
 ("small/shallow-miss",1000000), ("indexed/shallow-miss",1000000)]
ABBA = ["baseline","candidate","candidate","baseline"]
MARKER = "PSC1_EMPTY_CACHE_MICRO_OBSERVATION: PASS "
p = None

def require(value, message):
    if not value:
        raise RuntimeError(message)

def sha(raw):
    return hashlib.sha256(raw).hexdigest()

def digest(raw):
    return {"bytes":len(raw), "sha256":sha(raw)}

def git(root, *args):
    return subprocess.check_output(["git","-C",str(root),*args])

def load_producer(root):
    require(git(root,"rev-parse","HEAD").decode().strip() == PRODUCER, "producer source SHA")
    for name, (expected_blob, expected_sha) in LEAF_FILES.items():
        raw = (root / name).read_bytes()
        require(raw == git(root,"show","HEAD:" + name) and sha(raw) == expected_sha,
                "producer source bytes: " + name)
        require(hashlib.sha1(b"blob " + str(len(raw)).encode() + b"\0" + raw).hexdigest()
                == expected_blob, "producer Git blob: " + name)
    path = root / ".github/psc1-empty-semantic-cache/leaf.py"
    spec = importlib.util.spec_from_file_location("authenticated_leaf_producer",path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

def check_checkouts(base, candidate, producer, experiment):
    for role, root, expected in [
        ("baseline",base,BASE), ("candidate",candidate,CANDIDATE),
        ("producer",producer,PRODUCER), ("experiment",experiment,os.environ["GITHUB_SHA"])]:
        require(git(root,"rev-parse","HEAD").decode().strip() == expected, role + " source SHA")
        require(not git(root,"status","--porcelain"), role + " checkout must remain clean")
    require(os.environ["GITHUB_REPOSITORY"] == REPO, "repository mismatch")
    for root, role in [(base,"baseline"),(candidate,"candidate")]:
        require(git(root,"rev-parse","HEAD:" + p.SRC).decode().strip() == p.TREES[role],
                role + " production tree")
    require(p.checked_source(experiment,PROTOCOL,PROTOCOL_BLOB)["sha256"] == PROTOCOL_SHA,
            "frozen protocol bytes")
    for name in (WORKFLOW,DRIVER,WORKER):
        p.checked_source(experiment,name)
    require(sha((experiment/WORKER).read_bytes()) == WORKER_SHA,"frozen worker bytes")

def experiment_identity(root):
    return {"sourceSha":os.environ["GITHUB_SHA"], "runId":os.environ["GITHUB_RUN_ID"],
        "runAttempt":os.environ["GITHUB_RUN_ATTEMPT"], "job":os.environ["GITHUB_JOB"],
        "files":[p.checked_source(root,name) for name in (WORKFLOW,DRIVER,WORKER,PROTOCOL)]}

def zip_contents(archive, extracted, expected_names=None):
    actual = p.files(extracted)
    total = 0
    seen = set()
    with zipfile.ZipFile(archive) as zipped:
        infos = zipped.infolist()
        require(len(infos) <= 200, "bounded artifact member inventory")
        for info in infos:
            name = info.filename
            path = pathlib.PurePosixPath(name)
            require(name and "\\" not in name and not path.is_absolute()
                and all(x not in ("",".","..") for x in name.split("/"))
                and name not in seen, "unsafe or duplicate ZIP path")
            seen.add(name)
            require(not info.is_dir() and not info.flag_bits & 1, "regular unencrypted ZIP files only")
            mode = info.external_attr >> 16
            require(stat.S_IFMT(mode) in (0,stat.S_IFREG), "nonregular ZIP entry")
            require(0 <= info.file_size <= 20_000_000, "bounded ZIP member size")
            total += info.file_size
            require(total <= 100_000_000, "bounded expanded artifact size")
            # zipfile checks CRC while independently reading the raw archive member.
            with zipped.open(info) as stream:
                raw = stream.read(info.file_size + 1)
            require(len(raw) == info.file_size, "ZIP member size mismatch")
            require(name in actual and p.exact(actual[name],digest(raw)),
                    "official extraction differs from raw ZIP member: " + name)
    require(seen == set(actual), "raw ZIP/extracted membership mismatch")
    if expected_names is not None:
        require(seen == set(expected_names), "exact expected artifact inventory")
    return {"files":len(actual), "expandedBytes":total, "rawMembersMatchExtracted":True,
        "crcCheckedBy":"python-stdlib-zipfile", "customZipParserImplemented":False}

def prepare(base, candidate, producer, experiment, out):
    check_checkouts(base,candidate,producer,experiment)
    require(not out.exists(), "fresh microbenchmark output required")
    out.mkdir(parents=True)
    meta = {"run":p.api("/actions/runs/" + str(SPEC["run"]) + "/attempts/1"),
        "artifact":p.api("/actions/artifacts/" + str(SPEC["artifact"])),
        "job":p.api("/actions/jobs/" + str(SPEC["job"]))}
    p.validate_metadata(SPEC,meta)
    p.write_json(out / "producer-api-metadata.json",meta)
    (out / "producer-artifact.zip").write_bytes(p.download_zip(SPEC))
    for name in (WORKFLOW,DRIVER,WORKER,PROTOCOL):
        p.copy(experiment / name,out / "experiment-sources" / name)
    p.write_json(out / "prepared.json",{"schema":"psc1-empty-cache-micro-prepared-v1",
        "experiment":experiment_identity(experiment), "producer":SPEC,
        "baselineSourceSha":BASE, "candidateSourceSha":CANDIDATE,
        "compilerSourceSha":COMPILER, "rawZip":digest((out / "producer-artifact.zip").read_bytes())})
    print("PSC1_EMPTY_CACHE_MICRO_PREPARED: PASS")

def verify_native(extracted, candidate, input_receipt):
    native = extracted / "inputs/native/extracted"
    receipt_path = native / "native-receipt.json"
    require(sha(receipt_path.read_bytes()) ==
        "57c2beac55dd1ab5184df29176ca9cc6189032fbddbc9e2cdd40fe6cef635a74",
        "native69 receipt pin")
    receipt = p.read_json(receipt_path)
    inventory_path = native / "source-inventory.json"
    inventory = p.read_json(inventory_path)
    require(sha(inventory_path.read_bytes()) ==
        "8b0874cf6be298d6312b457072ef60a3d4a7089e36433fc0abd78ae9af0395cb",
        "native69 source inventory pin")
    require(inventory["sourceSha"] == CANDIDATE and inventory["branchBaseSha"] == BASE
        and inventory["productionChanges"] == [p.ENTRY] and len(inventory["files"]) == 11,
        "native69 source identity")
    for row in inventory["files"]:
        require(p.exact(row,p.checked_source(candidate,row["path"]))
            and (native / "sources" / row["path"]).read_bytes() == (candidate / row["path"]).read_bytes(),
            "native69 source bytes")
    all_names, records, statuses = [], [], []
    pattern = r"'([^']+)' (?:depends on axioms:\s*\[([^\]]*)\]|does not depend on any axioms)"
    for module, count, log_name in p.MODULES:
        source = native / "sources" / ("psc1/test/" + module + ".lean")
        names = re.findall(r"(?m)^#print axioms (\S+)\s*$",source.read_text())
        names = [n if "." in n else module + "." + n for n in names]
        text = (native / log_name).read_text()
        reports = re.findall(pattern,text)
        require(len(names) == count and [n for n,_ in reports] == names, "native ordered reports")
        require(not any(w in text for w in ("sorryAx","Lean.ofReduceBool","Lean.trustCompiler"))
            and not re.search(r"\.lean:\d+:\d+: error:",text)
            and all({a.strip() for a in used.split(",") if a.strip()} <=
                {"propext","Classical.choice","Quot.sound"} for _,used in reports),
            "native standard-axiom inventory")
        all_names.extend(names)
        records.append({"module":module,"proofs":count,"names":names,
            "source":digest(source.read_bytes()),"log":digest((native / log_name).read_bytes())})
        statuses.append("PSC1_EMPTY_SEMANTIC_CACHE_PROOF_STATUS module=" + module +
            " count=" + str(count) + " countStatus=0 leanStatus=0")
    require(len(all_names) == 69 and len(set(all_names)) == 69, "69 unique native reports")
    require(p.exact(receipt["proofs"],records) and receipt["sourceSha"] == CANDIDATE
        and receipt["totalProofs"] == 69 and receipt["proofModules"] == 3,
        "native69 receipt correspondence")
    require((native / "proof-status.log").read_text() == "\n".join(statuses) + "\n",
        "native69 exact statuses")
    for key,value in p.NATIVE_SCOPE.items():
        require(receipt[key] is value,"native scope flag")
    require(p.exact(input_receipt["candidateNativeReceipt"],digest(receipt_path.read_bytes())),
        "native receipt chain")

def verify_commands_and_adapter(dest, source, receipt, role):
    commands = p.read_json(dest / "command-statuses.json")
    names = {"adapterSyntax","authenticSource","translation","canonicalManifest",
        "canonicalSource","generatedBuild","generatedSyntax","retained","empty"}
    require(set(commands) == names,"nine exact producer commands")
    old_work = commands["authenticSource"]["cwd"]
    old_dest = commands["generatedSyntax"]["cwd"]
    old_compiler = commands["authenticSource"]["arguments"][0]
    old_node = commands["adapterSyntax"]["arguments"][0]
    require(old_work.endswith("/" + role + "-source/psc1")
        and old_dest.endswith("/empty-semantic-cache-leaf/" + role)
        and old_compiler.endswith("/empty-semantic-cache-leaf/inputs/compiler/extracted/psc1")
        and all(pathlib.PurePosixPath(x).is_absolute() for x in
                (old_work,old_dest,old_compiler,old_node)), "producer detached path identity")
    entry = p.ENTRY.removeprefix("psc1/")
    workspace = "dist/empty-semantic-cache-leaf/workspace"
    canonical = workspace + "/" + entry.removesuffix(".lean") + ".ps"
    expected = {
      "adapterSyntax":([old_node,"--check",old_dest+"/bootstrap-shared.mjs"],old_work,60,"adapter-syntax.log"),
      "authenticSource":([old_compiler,"check",entry],old_work,600,"authentic-source.log"),
      "translation":([old_node,old_dest+"/bootstrap-shared.mjs",entry,workspace],old_work,600,"bootstrap.log"),
      "canonicalManifest":([old_node,old_dest+"/check-manifest.mjs"],old_work,60,"canonical-manifest.log"),
      "canonicalSource":([old_compiler,"check",canonical],old_work,600,"canonical-source.log"),
      "generatedBuild":([old_compiler,"build",canonical,"--out","dist/empty-semantic-cache-leaf/kernel.js"],
        old_work,600,"generated-build.log"),
      "generatedSyntax":([old_node,"--check",old_dest+"/runtime/kernel.mjs"],old_dest,60,"generated-syntax.log"),
      "retained":([old_node,"--max-old-space-size=2048",old_dest+"/runtime/"+pathlib.Path(p.RETAINED).name,
        old_dest+"/runtime/kernel.mjs"],old_dest+"/runtime",60,"retained-runtime.log"),
      "empty":([old_node,"--max-old-space-size=2048",old_dest+"/runtime/"+pathlib.Path(p.NEW).name,
        old_dest+"/runtime/kernel.mjs"],old_dest+"/runtime",60,"empty-runtime.log")}
    for name,(args,cwd,timeout,log_name) in expected.items():
        require(p.exact(commands[name],{"arguments":args,"cwd":cwd,"exitCode":0,
            "timeoutSeconds":timeout,"log":digest((dest/log_name).read_bytes())}),
            "producer command/log correspondence: " + name)
    for name in ("authentic-source.log","canonical-source.log"):
        require((dest/name).read_text() == "PSC2_CHECK: PASS (207 declarations)\n",
                "actual207 declaration check")
    bootstrap = dest / "sources/psc1/scripts/bootstrap-project.mjs"
    text = bootstrap.read_text()
    old_root = pathlib.PurePosixPath(old_work)
    substitutions = [
      ('from "./workspace-layout.mjs";','from '+json.dumps((old_root/"scripts/workspace-layout.mjs").as_uri())+';'),
      ('from "./bootstrap-manifest.mjs";','from '+json.dumps((old_root/"scripts/bootstrap-manifest.mjs").as_uri())+';'),
      ('const selfhostRoot = path.resolve(scriptDir, "..");','const selfhostRoot = '+json.dumps(old_work)+';'),
      ('    "lake",\n    [\n      "exe",\n      "psc1",\n','    '+json.dumps(old_compiler)+',\n    [\n')]
    for before,after in substitutions:
        require(text.count(before) == 1,"four exact original bootstrap substitutions")
        text = text.replace(before,after,1)
    require((dest/"bootstrap-shared.mjs").read_text() == text,"archived bootstrap adapter bytes")
    source_row = next(row for row in source["tools"] if row["path"] == "psc1/scripts/bootstrap-project.mjs")
    expected_tools = {"source":source_row,"adapter":digest(text.encode()),"replacementCount":4,
        "translatorSourceSha":COMPILER,"translatorSha256":p.COMPILER_HASH,
        "kernelSourceSha":source["kernelSourceSha"]}
    require(p.exact(p.read_json(dest/"bootstrap-tools.json"),expected_tools),
            "bootstrap tool/source/translator correspondence")
    require(p.exact(receipt["bootstrapTools"],digest((dest/"bootstrap-tools.json").read_bytes()))
        and p.exact(receipt["commandStatuses"],digest((dest/"command-statuses.json").read_bytes())),
        "producer command and bootstrap receipt chains")

def verify_variant(extracted, root, role, producer):
    dest = extracted / role
    receipt_path = dest / "leaf-receipt.json"
    require(sha(receipt_path.read_bytes()) == KERNELS[role]["receipt"],"pinned leaf receipt")
    receipt = p.read_json(receipt_path)
    source = p.source_manifest(root,role)
    require(p.exact(p.read_json(dest/"source-manifest.json"),source),"exact Git leaf source manifest")
    for row in source["sources"] + source["tools"]:
        require((dest/"sources"/row["path"]).read_bytes() == (root/row["path"]).read_bytes(),
                "archived leaf source or tool")
    expected_paths = {r["path"].removeprefix("psc1/").removesuffix(".lean")+".ps"
        for r in source["sources"]}
    canonical = dest/"canonical"
    manifest = p.read_json(canonical/".proofscript-bootstrap.json")
    entry = p.ENTRY.removeprefix("psc1/").removesuffix(".lean")+".ps"
    h = hashlib.sha256(b"proofscript-bootstrap-closure-v2\0"+entry.encode()+b"\0")
    for name in sorted(expected_paths):
        raw = (canonical/name).read_bytes()
        raw.decode("utf-8")
        h.update(name.encode()+b"\0"+raw+b"\0")
    expected_manifest = {"schemaVersion":2,"generation":"bootstrap","entry":entry,
        "sourceCount":8,"generated":sorted(expected_paths),"closureSha256":h.hexdigest()}
    require(p.exact(manifest,expected_manifest),"canonical eight-source closure")
    logs = {"adapter-syntax.log","authentic-source.log","bootstrap.log","canonical-manifest.log",
        "canonical-source.log","generated-build.log","generated-syntax.log",
        "retained-runtime.log","empty-runtime.log"}
    expected = {"sources/"+row["path"] for row in source["sources"]+source["tools"]}
    expected |= {"canonical/"+name for name in expected_paths}
    expected |= {"canonical/.proofscript-bootstrap.json", "source-manifest.json",
        "bootstrap-shared.mjs","bootstrap-tools.json","check-manifest.mjs","command-statuses.json",
        "runtime/kernel.mjs","runtime/"+pathlib.Path(p.NEW).name,"runtime/"+pathlib.Path(p.RETAINED).name,
        "kernel.js","kernel.ts","kernel.d.ts","kernel.js.map"} | logs
    require(len(expected) == 45 and set(receipt["files"]) == expected,"45 producer variant members")
    actual = p.files(dest)
    require(set(actual) == expected | {"leaf-receipt.json"},"46 exact producer variant members")
    for name,record in receipt["files"].items():
        require(p.exact(record,actual[name]),"variant member hash: " + name)
    expected_kernel = {"bytes":KERNELS[role]["bytes"],"sha256":KERNELS[role]["sha256"]}
    require(p.exact(actual["kernel.js"],expected_kernel)
        and p.exact(actual["runtime/kernel.mjs"],expected_kernel)
        and p.exact(receipt["generatedKernel"],expected_kernel),"generated/executed kernel bytes")
    require((dest/"runtime"/pathlib.Path(p.RETAINED).name).read_bytes() == (root/p.RETAINED).read_bytes()
        and (dest/"runtime"/pathlib.Path(p.NEW).name).read_bytes() == (producer/p.NEW).read_bytes(),
        "byte-exact runtime harnesses")
    retained = p.runtime_result(dest/"retained-runtime.log","PSC1_CLOSED_CACHE_ANALYSIS_JS: PASS ",p.RETAINED_RESULT)
    empty = p.runtime_result(dest/"empty-runtime.log","PSC1_EMPTY_SEMANTIC_CACHE_JS: PASS ",p.EMPTY_RESULT)
    lines = (dest/"empty-runtime.log").read_text().splitlines()
    expected_lines = ["PSC1_EMPTY_SEMANTIC_CACHE_ASSERT harness/rejection",
        "PSC1_EMPTY_SEMANTIC_CACHE_SECTION harness=1"]
    expected_lines += ["PSC1_EMPTY_SEMANTIC_CACHE_ASSERT empty/"+str(i).zfill(2) for i in range(20)]
    expected_lines += ["PSC1_EMPTY_SEMANTIC_CACHE_SECTION empty=20"]
    require(lines[:-1] == expected_lines,"exact21 producer labels and sections")
    require(receipt["kernelSourceSha"] == KERNELS[role]["source"]
        and receipt["compilerSourceSha"] == COMPILER and receipt["compilerSha256"] == p.COMPILER_HASH
        and receipt["sourceCount"] == 8 and receipt["assertions"] == 1905
        and p.exact(receipt["runtime"],{"retained":retained,"empty":empty})
        and receipt["canonicalClosureSha256"] == h.hexdigest()
        and p.exact(receipt["sourceManifest"],actual["source-manifest.json"]),
        "producer variant receipt/source/runtime chain")
    for flag in ("heldKernelProductionImported","nativeProofsRerun","fuelPolicyChanged",
                 "fullKernelGenerated","fullQualification","fullKernel",
                 "churchAcceptanceFixed","performanceMeasured","performanceQualified"):
        require(receipt[flag] is False,"truthful producer scope")
    verify_commands_and_adapter(dest,source,receipt,role)
    return receipt

def audit(base,candidate,producer,experiment,out):
    check_checkouts(base,candidate,producer,experiment)
    prepared = p.read_json(out/"prepared.json")
    require(p.exact(prepared["experiment"],experiment_identity(experiment))
        and p.exact(prepared["producer"],SPEC),"micro experiment preparation identity")
    for name in (WORKFLOW,DRIVER,WORKER,PROTOCOL):
        require((out/"experiment-sources"/name).read_bytes() == (experiment/name).read_bytes(),
                "archived micro execution source")
    raw = (out/"producer-artifact.zip").read_bytes()
    require(len(raw) == SPEC["size"] and sha(raw) == SPEC["sha256"]
        and p.exact(prepared["rawZip"],digest(raw)),"producer raw ZIP pin")
    p.validate_metadata(SPEC,p.read_json(out/"producer-api-metadata.json"))
    extracted = out/"producer"
    zip_record = zip_contents(out/"producer-artifact.zip",extracted)
    require(zip_record["files"] == 136,"136 producer members")
    report_path = extracted/"paired-leaf-report.json"
    require(sha(report_path.read_bytes()) == REPORT_SHA,"paired producer report pin")
    report = p.read_json(report_path)
    producer_identity = {"sourceSha":PRODUCER,"runId":"40158333460","runAttempt":"1","job":"paired",
        "files":[p.checked_source(producer,name) for name in LEAF_FILES]}
    require(p.exact(report["experiment"],producer_identity)
        and report["baselineSourceSha"] == BASE and report["candidateSourceSha"] == CANDIDATE
        and report["compilerSourceSha"] == COMPILER and report["compilerSha256"] == p.COMPILER_HASH
        and report["leafSourceChanges"] == [p.ENTRY] and report["totalAssertions"] == 3810,
        "paired producer source/runtime identity")
    for name in LEAF_FILES:
        require((extracted/"experiment-sources"/name).read_bytes() == (producer/name).read_bytes(),
                "producer execution source bytes")
    require(p.exact(p.read_json(extracted/"prepared.json"),{
        "schema":"psc1-empty-cache-leaf-prepared-v1","experiment":producer_identity,
        "baselineSourceSha":BASE,"candidateSourceSha":CANDIDATE,"compilerSourceSha":COMPILER,
        "inputs":p.INPUTS,"rawZipSha256Verified":True,"independentZipParser":False}),
        "original producer preparation chain")
    input_path = extracted/"input-receipt.json"
    require(p.exact(report["inputReceipt"],digest(input_path.read_bytes())),"input receipt chain")
    input_receipt = p.read_json(input_path)
    expected_members = {"paired-leaf-report.json","prepared.json","input-receipt.json","tools.json",
        "tool-sources/typescript-package-lock.json","tool-sources/typescript-package.json"}
    expected_members |= {"experiment-sources/"+name for name in LEAF_FILES}
    nested = {}
    for name,spec in p.INPUTS.items():
        directory = extracted/"inputs"/name
        p.validate_metadata(spec,p.read_json(directory/"api-metadata.json"))
        archive = (directory/"artifact.zip").read_bytes()
        require(len(archive) == spec["size"] and sha(archive) == spec["sha256"],"nested input ZIP pin")
        listed = input_receipt["compilerFiles" if name == "compiler" else "nativeFiles"]
        require(len(listed) == (13 if name == "compiler" else 18)
            and p.exact(p.files(directory/"extracted"),listed),"nested extracted member hashes")
        nested[name] = zip_contents(directory/"artifact.zip",directory/"extracted",listed)
        expected_members |= {"inputs/"+name+"/api-metadata.json","inputs/"+name+"/artifact.zip"}
        expected_members |= {"inputs/"+name+"/extracted/"+member for member in listed}
    compiler_root = extracted/"inputs/compiler/extracted"
    compiler_receipt = p.read_json(compiler_root/"compiler-receipt.json")
    require(sha((compiler_root/"compiler-receipt.json").read_bytes()) == p.COMPILER_RECEIPT
        and compiler_receipt["sourceSha"] == COMPILER
        and compiler_receipt["compilerSha256"] == p.COMPILER_HASH
        and sha((compiler_root/"psc1").read_bytes()) == p.COMPILER_HASH,"compiler binary/receipt chain")
    require(set(compiler_receipt["files"]) | {"compiler-receipt.json"} ==
        set(input_receipt["compilerFiles"]),"compiler member inventory")
    for name,expected_hash in compiler_receipt["files"].items():
        require(sha((compiler_root/name).read_bytes()) == expected_hash,"compiler content digest")
    require(p.exact(input_receipt["compilerReceipt"],digest((compiler_root/"compiler-receipt.json").read_bytes())),
            "compiler receipt parent digest")
    verify_native(extracted,candidate,input_receipt)
    variants = [verify_variant(extracted,root,role,producer)
        for root,role in [(base,"baseline"),(candidate,"candidate")]]
    for i,receipt in enumerate(variants):
        role = receipt["variant"]
        require(p.exact(receipt["experiment"],producer_identity),"variant experiment identity")
        expected = {"variant":role,"kernelSourceSha":KERNELS[role]["source"],
            "receipt":digest((extracted/role/"leaf-receipt.json").read_bytes()),
            "generatedKernel":receipt["generatedKernel"]}
        require(p.exact(report["variants"][i],expected),"paired-to-variant receipt chain")
        expected_members |= {role+"/"+name for name in p.files(extracted/role)}
    require(p.exact(variants[0]["runtime"],variants[1]["runtime"]),"paired semantic receipts")
    differences = [name for name in variants[0]["files"]
        if name.startswith("sources/"+p.SRC+"/") and not p.exact(
            variants[0]["files"][name],variants[1]["files"][name])]
    require(differences == ["sources/"+p.ENTRY],"exact one-file paired production change")
    require(len(expected_members) == 136 and set(p.files(extracted)) == expected_members,
            "complete exact136 artifact membership")
    tools_path = extracted/"tools.json"
    require(p.exact(report["tools"],digest(tools_path.read_bytes())),"producer tool receipt chain")
    tool_record = p.read_json(tools_path)
    require(tool_record["nodeVersion"] == "v22.23.3" and tool_record["typescriptVersion"] == "7.0.2"
        and tool_record["compilerSourceSha"] == COMPILER and tool_record["compilerSha256"] == p.COMPILER_HASH,
        "producer tool identity")
    require(p.exact(tool_record["typescriptPackage"],
            digest((extracted/"tool-sources/typescript-package.json").read_bytes()))
        and p.exact(tool_record["typescriptLock"],
            digest((extracted/"tool-sources/typescript-package-lock.json").read_bytes())),
        "TypeScript tool archive correspondence")
    result = {"schema":"psc1-empty-cache-micro-artifact-audit-v1","status":"pass",
        "experiment":experiment_identity(experiment),"producerSourceSha":PRODUCER,
        "producerRunId":SPEC["run"],"producerRunAttempt":1,"producerArtifactId":SPEC["artifact"],
        "producerArtifactZip":digest(raw),"producerReport":digest(report_path.read_bytes()),
        "producerMembers":136,"nestedInputs":nested,"rawArchive":zip_record,
        "nativeProofReportsVerified":69,"leafAssertionsVerified":3810,
        "producerFiles":p.files(extracted),"node":tool_record["node"],
        "nodeVersion":tool_record["nodeVersion"],"sourceClosuresMatchExactGit":True,
        "receiptChainsVerified":True,"bootstrapAdaptationsVerified":True,
        "customZipParserImplemented":False,"wholeKernelBuilt":False,"performanceQualified":False}
    p.write_json(out/"artifact-audit.json",result)
    print("PSC1_EMPTY_CACHE_MICRO_ARTIFACT_AUDIT: PASS "+json.dumps({
        "producerArtifactId":SPEC["artifact"],"files":136,"nativeReports":69,
        "leafAssertions":3810,"report":digest((out/"artifact-audit.json").read_bytes()),
        "customZipParserImplemented":False},separators=(",",":")))
    return tool_record

def execute(command,cwd,directory,timeout=60):
    directory.mkdir(parents=True,exist_ok=True)
    env = os.environ.copy()
    env.pop("GH_TOKEN",None)
    env["PATH"] = ""
    env["NODE_OPTIONS"] = ""
    timed_out = False
    code = None
    with (directory/"stdout.log").open("wb") as stdout, (directory/"stderr.log").open("wb") as stderr:
        try:
            process = subprocess.run([str(v) for v in command],cwd=cwd,env=env,
                stdout=stdout,stderr=stderr,timeout=timeout,check=False)
            code = process.returncode
        except subprocess.TimeoutExpired:
            timed_out = True
    record = {"arguments":[str(v) for v in command],"cwd":str(cwd),
        "timeoutSeconds":timeout,"timedOut":timed_out,"exitCode":code,
        "runtimePathEmpty":True,"nodeOptionsEmpty":True,
        "stdout":digest((directory/"stdout.log").read_bytes()),
        "stderr":digest((directory/"stderr.log").read_bytes())}
    p.write_json(directory/"command-status.json",record)
    if timed_out or code != 0:
        print((directory/"stdout.log").read_text(),end="")
        print((directory/"stderr.log").read_text(),end="")
    require(not timed_out and code == 0,"incomplete bounded process; inspect "+str(directory))
    return record

def validate_observation(observation,config,worker_sha,node_version):
    fields = {"schema","status","config","workerSha256","kernelSha256","nodeVersion","nodeSha256",
        "mapShape","queryShape","expectedResult","expectedCode","warmupChecksum","checksum",
        "invalidResults","elapsedNanoseconds","cpuUserMicroseconds","cpuSystemMicroseconds",
        "memoryBefore","memoryAfter","maxRssKiB","maxRssScope","gcCalls","controlsPassed",
        "ringValidated","inputsUnchanged","optionShapeValidated","loopIncludesResultConsumption",
        "fullKernel","performanceQualified"}
    require(set(observation) == fields and observation["schema"] == "psc1-empty-cache-micro-observation-v1"
        and observation["status"] == "pass" and p.exact(observation["config"],config),
        "exact observation schema/config")
    case = config["caseId"]
    expected_code = 2 if case in {"small/hit","indexed/hit"} else 1
    query = "deep" if "deep" in case else "early" if "early" in case else \
        "late" if "late" in case else "miss" if "shallow-miss" in case else "hit"
    require(observation["workerSha256"] == worker_sha
        and observation["kernelSha256"] == config["kernelSha256"]
        and observation["nodeSha256"] == config["nodeSha256"] and observation["nodeVersion"] == node_version
        and observation["mapShape"] == case.split("/")[0] and observation["queryShape"] == query
        and observation["expectedResult"] == ("some(value)" if expected_code == 2 else "none")
        and observation["expectedCode"] == expected_code
        and observation["warmupChecksum"] == 4096*expected_code
        and observation["checksum"] == config["measuredCalls"]*expected_code
        and observation["invalidResults"] == 0 and observation["gcCalls"] == 2,
        "observed output consumption/identity")
    for flag in ("controlsPassed","ringValidated","inputsUnchanged","optionShapeValidated",
                 "loopIncludesResultConsumption"):
        require(observation[flag] is True,"observation control failed")
    require(observation["fullKernel"] is False and observation["performanceQualified"] is False,
            "helper-only observation scope")
    elapsed = observation["elapsedNanoseconds"]
    require(isinstance(elapsed,str) and re.fullmatch(r"[1-9][0-9]*",elapsed)
        and int(elapsed) < 60_000_000_000,"bounded measured interval")
    for name in ("cpuUserMicroseconds","cpuSystemMicroseconds","maxRssKiB"):
        require(type(observation[name]) is int and observation[name] >= 0,"integer observation metric")
    require(observation["maxRssKiB"] > 0
        and observation["maxRssScope"] == "whole-process-including-import-and-setup",
        "whole-process maxRSS scope")
    for name in ("memoryBefore","memoryAfter"):
        require(set(observation[name]) == {"heapUsed","rss"}
            and all(type(x) is int and x >= 0 for x in observation[name].values()),"memory metrics")

def summary_metrics(rows,field):
    values = {role:[field(row) for row in rows if row["config"]["variant"] == role]
        for role in ("baseline","candidate")}
    require(all(len(v) == 2 for v in values.values()),"two observations per variant")
    result = {role:{"raw":v,"median":statistics.median(v),"min":min(v),"max":max(v)}
        for role,v in values.items()}
    before,after = result["baseline"]["median"],result["candidate"]["median"]
    result["candidateOverBaseline"] = after/before if before > 0 else None
    return result

def measure(base,candidate,producer,experiment,out):
    check_checkouts(base,candidate,producer,experiment)
    audit_record = p.read_json(out/"artifact-audit.json")
    require(p.exact(audit_record["experiment"],experiment_identity(experiment))
        and audit_record["producerSourceSha"] == PRODUCER and audit_record["producerMembers"] == 136
        and p.exact(audit_record["producerFiles"],p.files(out/"producer")),
        "audited producer bytes changed before timing")
    require(p.exact(audit_record["producerArtifactZip"],
        digest((out/"producer-artifact.zip").read_bytes())),"audited raw archive changed")
    node_name = shutil.which("node")
    require(node_name is not None,"Node executable missing")
    node = pathlib.Path(node_name).resolve(strict=True)
    node_record = digest(node.read_bytes())
    node_version = subprocess.check_output([str(node),"--version"],text=True).strip()
    require(node_version == "v22.23.3" and node_version == audit_record["nodeVersion"]
        and p.exact(node_record,audit_record["node"]),"exact semantic Node binary required")
    runtime = out/"runtime"
    require(not runtime.exists(),"fresh detached runtime required")
    runtime.mkdir()
    worker = runtime/pathlib.Path(WORKER).name
    p.copy(experiment/WORKER,worker)
    worker_sha = sha(worker.read_bytes())
    p.write_json(out/"execution-tools.json",{"nodeVersion":node_version,"node":node_record,
        "worker":digest(worker.read_bytes()),"workerSource":p.checked_source(experiment,WORKER),
        "runtimePathEmpty":True,"nodeOldSpaceMiB":2048,"hostTimeoutSeconds":60,
        "warmupCalls":4096,"explicitGcCallsOutsideTiming":2})
    execute([node,"--check",worker],runtime,out/"syntax",60)
    kernels = {}
    controls = []
    for role in ("baseline","candidate"):
        origin = out/"producer"/role
        kernel = runtime/(role+".mjs")
        p.copy(origin/"kernel.js",kernel)
        require(digest(kernel.read_bytes()) == {"bytes":KERNELS[role]["bytes"],
            "sha256":KERNELS[role]["sha256"]},"detached runtime kernel identity")
        kernels[role] = kernel
        for label,name,marker,expected in [
            ("retained",pathlib.Path(p.RETAINED).name,"PSC1_CLOSED_CACHE_ANALYSIS_JS: PASS ",p.RETAINED_RESULT),
            ("empty",pathlib.Path(p.NEW).name,"PSC1_EMPTY_SEMANTIC_CACHE_JS: PASS ",p.EMPTY_RESULT)]:
            script = runtime/(role+"-"+name)
            p.copy(origin/"runtime"/name,script)
            directory = out/"controls"/(role+"-"+label)
            status = execute([node,"--max-old-space-size=2048",script,kernel],runtime,directory,60)
            value = p.runtime_result(directory/"stdout.log",marker,expected)
            controls.append({"variant":role,"kind":label,"result":value,"status":status,
                "script":digest(script.read_bytes())})
    p.write_json(out/"semantic-controls.json",{"retainedPerVariant":1884,"emptyPerVariant":21,
        "totalAssertions":3810,"processes":4,"records":controls})
    observations = []
    statuses = []
    for case_index,(case_id,calls) in enumerate(CASES):
        for abba_position,role in enumerate(ABBA):
            ordinal = case_index*4+abba_position
            directory = out/"observations"/(str(ordinal).zfill(2)+"-"+case_id.replace("/","-")+"-"+role)
            require(not directory.exists(),"fresh observation directory")
            directory.mkdir(parents=True)
            config = {"schema":"psc1-empty-cache-micro-case-v1",
                "experimentSourceSha":os.environ["GITHUB_SHA"],
                "runId":os.environ["GITHUB_RUN_ID"],"runAttempt":os.environ["GITHUB_RUN_ATTEMPT"],
                "job":os.environ["GITHUB_JOB"],"sequenceOrdinal":ordinal,
                "caseIndex":case_index,"caseId":case_id,"variant":role,"abbaPosition":abba_position,
                "kernelSourceSha":KERNELS[role]["source"],"kernelSha256":KERNELS[role]["sha256"],
                "nodeSha256":node_record["sha256"],"warmupCalls":4096,"measuredCalls":calls}
            p.write_json(directory/"case-config.json",config)
            status = execute([node,"--expose-gc","--max-old-space-size=2048",
                worker,kernels[role],directory/"case-config.json"],directory,directory,60)
            lines = (directory/"stdout.log").read_text().splitlines()
            require(len(lines) == 1 and lines[0].startswith(MARKER),"one exact observation output")
            observation = p.parse(lines[0][len(MARKER):])
            validate_observation(observation,config,worker_sha,node_version)
            require(p.exact(p.read_json(directory/"case-config.json"),config),"case config mutation")
            p.write_json(directory/"observation.json",observation)
            observations.append(observation)
            statuses.append({"sequenceOrdinal":ordinal,"directory":directory.relative_to(out).as_posix(),
                "status":status,"config":digest((directory/"case-config.json").read_bytes()),
                "observation":digest((directory/"observation.json").read_bytes())})
            print(lines[0])
    require(len(observations) == 56 and [r["config"]["sequenceOrdinal"] for r in observations] == list(range(56)),
        "56 ordered observations")
    require(sha(worker.read_bytes()) == worker_sha and worker.read_bytes() == (experiment/WORKER).read_bytes(),
        "worker source changed during timing")
    require(p.exact(node_record,digest(node.read_bytes())),"Node binary changed during timing")
    for role,path in kernels.items():
        require(sha(path.read_bytes()) == KERNELS[role]["sha256"],"runtime kernel changed")
    require(p.exact(audit_record["producerFiles"],p.files(out/"producer")),"producer archive contents changed")
    check_checkouts(base,candidate,producer,experiment)
    summaries = []
    for index,(case_id,calls) in enumerate(CASES):
        rows = observations[index*4:index*4+4]
        summaries.append({"caseId":case_id,"measuredCalls":calls,"observations":4,
            "elapsedNanoseconds":summary_metrics(rows,lambda r:int(r["elapsedNanoseconds"])),
            "cpuMicroseconds":summary_metrics(rows,lambda r:r["cpuUserMicroseconds"]+r["cpuSystemMicroseconds"]),
            "wholeProcessMaxRssKiB":summary_metrics(rows,lambda r:r["maxRssKiB"])})
    p.write_json(out/"observation-statuses.json",statuses)
    report = {"schema":"psc1-empty-cache-micro-report-v1","status":"complete",
        "experiment":experiment_identity(experiment),"producerSourceSha":PRODUCER,
        "baselineSourceSha":BASE,"candidateSourceSha":CANDIDATE,"compilerSourceSha":COMPILER,
        "producerArtifactId":SPEC["artifact"],"producerArtifactZip":audit_record["producerArtifactZip"],
        "producerArtifactAudit":digest((out/"artifact-audit.json").read_bytes()),
        "protocol":p.checked_source(experiment,PROTOCOL),
        "executionTools":p.read_json(out/"execution-tools.json"),
        "semanticControls":digest((out/"semantic-controls.json").read_bytes()),
        "caseCount":14,"sequence":ABBA,"observations":56,"freshProcessPerObservation":True,
        "runtimePathEmpty":True,"nodeOldSpaceMiB":2048,"hostTimeoutSeconds":60,
        "observationStatuses":digest((out/"observation-statuses.json").read_bytes()),
        "records":observations,"summaries":summaries,"measuredLoopIncludesConsumption":True,
        "maxRssScope":"whole-process-including-import-and-setup",
        "adaptiveIterations":False,"sampleRetries":False,"outliersRemoved":False,
        "helperOnly":True,"wholeKernelBuilt":False,"wholeKernelRegressionsChecked":False,
        "optimizationAdopted":False,"churchAcceptanceFixed":False,"performanceQualified":False}
    p.write_json(out/"micro-report.json",report)
    files_before_inventory = p.files(out)
    p.write_json(out/"output-inventory.json",{"schema":"psc1-empty-cache-micro-output-v1",
        "files":files_before_inventory,"inventoryExcludesItself":True})
    print("PSC1_EMPTY_CACHE_MICRO: PASS "+json.dumps({
        "experiment":report["experiment"],"producerSourceSha":PRODUCER,
        "baselineSourceSha":BASE,"candidateSourceSha":CANDIDATE,"compilerSourceSha":COMPILER,
        "caseCount":14,"observations":56,"report":digest((out/"micro-report.json").read_bytes()),
        "outputInventory":digest((out/"output-inventory.json").read_bytes()),
        "archiveFiles":len(files_before_inventory)+1,"summaries":summaries,
        "helperOnly":True,"wholeKernelRegressionsChecked":False,
        "optimizationAdopted":False,"performanceQualified":False},separators=(",",":")))

def main():
    global p
    require(len(sys.argv) == 7 and sys.argv[1] in {"prepare","audit","measure"},
        "usage: micro.py <prepare|audit|measure> baseline candidate producer experiment out")
    base,candidate,producer,experiment,out = [pathlib.Path(x).resolve() for x in sys.argv[2:]]
    p = load_producer(producer)
    try:
        {"prepare":prepare,"audit":audit,"measure":measure}[sys.argv[1]](
            base,candidate,producer,experiment,out)
    except Exception as error:
        if out.exists():
            p.write_json(out/"incomplete.json",{"schema":"psc1-empty-cache-micro-incomplete-v1",
                "status":"incomplete","phase":sys.argv[1],"error":str(error),
                "sourceSha":os.environ["GITHUB_SHA"],"runId":os.environ["GITHUB_RUN_ID"],
                "runAttempt":os.environ["GITHUB_RUN_ATTEMPT"],
                "processStatusesRetained":len(list((out/"observations").glob("*/command-status.json"))),
                "performanceQualified":False,"optimizationAdopted":False})
        raise

if __name__ == "__main__":
    main()
