#!/usr/bin/env python3
"""Read-only audit of the frozen, incomplete v1 helper experiment."""
import hashlib, importlib.util, json, os, pathlib, re, stat, sys, zipfile

MEASURED = "d3c50dcb182960d8a78b3da53a7d04fde0ec809d"
PRODUCER = "80182d1b95894fc3daa5c7fbcfe8b1a7adb687d9"
BASE = "20224a295359abb201f56c72395690bf0bfac9fa"
CANDIDATE = "e503972553ae2d41d5ba7a26d7739fb32ee86b96"
MICRO = ".github/psc1-empty-semantic-cache/micro.py"
AUDITOR = ".github/psc1-empty-semantic-cache/micro-audit.py"
WORKFLOW = ".github/workflows/psc1-empty-semantic-cache-micro-audit.yml"
MICRO_SHA = "083bfb78be64c4b2742c5c1447446eda78f675b757e9c880f4bb8489496a306e"
SOURCE_PINS = {
 ".github/psc1-empty-semantic-cache/micro.py":
  ("7b2dfa04780cbaf77608c38d80037cdbea00abcf",42339,MICRO_SHA),
 ".github/workflows/psc1-empty-semantic-cache-micro.yml":
  ("4022f8e4ba4be927f3fe3a2d16aa107450485025",3533,
   "2f18a9fe32420815b3cfe4a028ffc874a649702a787a377b6a779fd2dfd651ca"),
 "psc1/scripts/pskernel-empty-semantic-cache-micro.mjs":
  ("2ac2d6ae0e1b3ac9fcc21402faf7cd41a08c9af2",14328,
   "1e13989ff42143b9b5d6bf8686d4e1405d64e5f1f626161afe0ac00a30551ffa"),
 "psc1/packages/pskernel-core/docs/T09_EMPTY_SEMANTIC_CACHE_MICROBENCH_PROTOCOL.md":
  ("285fcb439f3567f9697c3d0046e129c140b0cee5",8606,
   "3982b235c6c45c783ea5a1fa2eeedeea0f72bf07f1ea48e3bdf6651dd0b6be2e")}
SPEC = {"source":MEASURED,"run":40161243172,"attempt":1,"job":121073067656,
 "jobName":"micro","artifact":12585854601,
 "name":"psc1-empty-semantic-cache-micro-attempt-1","size":10629811,
 "sha256":"835a058052da746ee78aa9395514748373c29f1596bde9f3af4e8f0a1b672861",
 "workflow":".github/workflows/psc1-empty-semantic-cache-micro.yml"}
AUDIT_SHA = "53acda4ce2fe2069854241de0aec5846fa4869cbc60789bb82e9a1ed2860487f"
STEP_NAMES = [
 "Set up job","Check out exact timing implementation",
 "Check out exact qualified producer implementation",
 "Check out fixed baseline source for archive correspondence",
 "Check out fixed candidate source for archive correspondence",
 "Authenticate exact producer API metadata and raw archive digest",
 "Extract the exact paired leaf artifact with the official action",
 "Independently verify all136 raw and extracted members and complete receipt chains",
 "Run actions/setup-node@v4",
 "Recheck semantic controls and execute the frozen14-case56-process protocol",
 "Retain every observation, status, source pin and complete producer evidence",
 "Post Run actions/setup-node@v4",
 "Post Check out fixed candidate source for archive correspondence",
 "Post Check out fixed baseline source for archive correspondence",
 "Post Check out exact qualified producer implementation",
 "Post Check out exact timing implementation","Complete job"]
m = None
p = None

def require(value, message):
    if not value:
        raise RuntimeError(message)

def sha(raw):
    return hashlib.sha256(raw).hexdigest()

def load_utilities(measured, producer):
    global m,p
    raw = (measured/MICRO).read_bytes()
    require(len(raw) == 42339 and sha(raw) == MICRO_SHA,"pinned measured audit utility")
    spec = importlib.util.spec_from_file_location("frozen_micro",measured/MICRO)
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    p = m.load_producer(producer)
    m.p = p

def check_sources(audit_source,measured,producer,base,candidate):
    roots = [(audit_source,os.environ["GITHUB_SHA"]),(measured,MEASURED),
        (producer,PRODUCER),(base,BASE),(candidate,CANDIDATE)]
    for root,expected in roots:
        require(p.git(root,"rev-parse","HEAD").decode().strip() == expected,"exact checkout SHA")
        require(p.git(root,"status","--porcelain") == b"","clean source checkout")
    records = []
    for name,(blob,size,expected_sha) in SOURCE_PINS.items():
        record = p.checked_source(measured,name,blob)
        require(record["bytes"] == size and record["sha256"] == expected_sha,"measured source byte pin")
        records.append(record)
    p.source_manifest(base,"baseline")
    p.source_manifest(candidate,"candidate")
    require(p.git(base,"rev-parse","HEAD:"+p.SRC).decode().strip() ==
        "57b209c4b29f7a9dd67bdae37e728cde4a0ac1ff","baseline production tree")
    require(p.git(candidate,"rev-parse","HEAD:"+p.SRC).decode().strip() ==
        "e567685e5c441a5b0a78d8241f7bae151b48b5ca","candidate production tree")
    return records

def measured_identity(measured):
    return {"sourceSha":MEASURED,"runId":str(SPEC["run"]),"runAttempt":"1","job":"micro",
        "files":[p.checked_source(measured,name) for name in (m.WORKFLOW,m.DRIVER,m.WORKER,m.PROTOCOL)]}

def audit_identity(audit_source):
    return {"sourceSha":os.environ["GITHUB_SHA"],"runId":os.environ["GITHUB_RUN_ID"],
        "runAttempt":os.environ["GITHUB_RUN_ATTEMPT"],"job":os.environ["GITHUB_JOB"],
        "files":[p.checked_source(audit_source,name) for name in (WORKFLOW,AUDITOR)]}

def verify_metadata(meta):
    run,artifact,job = meta["run"],meta["artifact"],meta["job"]
    require(run["id"] == SPEC["run"] and run["run_attempt"] == 1
        and run["head_sha"] == MEASURED and run["path"] == SPEC["workflow"]
        and run["repository"]["full_name"] == "dwijayuda/pskernel"
        and run["status"] == "completed" and run["conclusion"] == "failure",
        "exact failed experiment run")
    require(artifact["id"] == SPEC["artifact"] and artifact["name"] == SPEC["name"]
        and artifact["size_in_bytes"] == SPEC["size"] and artifact["expired"] is False
        and artifact["digest"] == "sha256:"+SPEC["sha256"]
        and artifact["workflow_run"]["id"] == SPEC["run"]
        and artifact["workflow_run"]["head_sha"] == MEASURED,"exact partial artifact")
    require(job["id"] == SPEC["job"] and job["run_id"] == SPEC["run"]
        and job["run_attempt"] == 1 and job["head_sha"] == MEASURED and job["name"] == "micro"
        and job["status"] == "completed" and job["conclusion"] == "failure",
        "exact failed experiment job")
    require([s["name"] for s in job["steps"]] == STEP_NAMES,"exact measured step inventory")
    for index,step in enumerate(job["steps"]):
        expected = "failure" if index == 9 else "skipped" if index == 11 else "success"
        require(step["status"] == "completed" and step["conclusion"] == expected,
            "measured step conclusion")

def raw_members(archive,extracted):
    actual = p.files(extracted)
    require(len(actual) == 333,"exact partial333 extracted files")
    seen,total = set(),0
    with zipfile.ZipFile(archive) as zipped:
        require(len(zipped.infolist()) == 333,"exact partial333 ZIP members")
        for info in zipped.infolist():
            name = info.filename
            require(name and "\\" not in name and not pathlib.PurePosixPath(name).is_absolute()
                and all(x not in ("",".","..") for x in name.split("/")) and name not in seen,
                "safe unique archive member")
            seen.add(name)
            require(not info.is_dir() and not info.flag_bits & 1
                and stat.S_IFMT(info.external_attr >> 16) in (0,stat.S_IFREG),"regular unencrypted member")
            require(0 <= info.file_size <= 20_000_000,"bounded member")
            total += info.file_size
            require(total <= 100_000_000,"bounded expanded archive")
            with zipped.open(info) as stream:
                raw = stream.read(info.file_size+1)
            require(len(raw) == info.file_size and name in actual
                and p.exact(actual[name],p.digest(raw)),"ZIP CRC/content matches official extraction")
    require(seen == set(actual),"raw/extracted exact membership")
    return actual,{"files":333,"expandedBytes":total,"crcCheckedBy":"python-stdlib-zipfile",
        "customZipParserImplemented":False,"rawMembersMatchExtracted":True}

def prepare(audit_source,measured,producer,base,candidate,out):
    check_sources(audit_source,measured,producer,base,candidate)
    require(not out.exists(),"fresh audit output")
    out.mkdir(parents=True)
    meta = {"run":p.api("/actions/runs/"+str(SPEC["run"])+"/attempts/1"),
        "artifact":p.api("/actions/artifacts/"+str(SPEC["artifact"])),
        "job":p.api("/actions/jobs/"+str(SPEC["job"]))}
    verify_metadata(meta)
    p.write_json(out/"measurement-api-metadata.json",meta)
    (out/"measurement-artifact.zip").write_bytes(p.download_zip(SPEC))
    for name in (WORKFLOW,AUDITOR):
        p.copy(audit_source/name,out/"audit-sources"/name)
    p.write_json(out/"prepared.json",{"schema":"psc1-empty-cache-micro-partial-audit-prepared-v1",
        "audit":audit_identity(audit_source),"measurement":SPEC,
        "rawZip":p.digest((out/"measurement-artifact.zip").read_bytes())})
    print("PSC1_EMPTY_CACHE_MICRO_PARTIAL_AUDIT_PREPARED: PASS")

def verify_producer(extracted,measured,producer,base,candidate):
    old_audit = p.read_json(extracted/"artifact-audit.json")
    require((extracted/"artifact-audit.json").stat().st_size == 26579
        and sha((extracted/"artifact-audit.json").read_bytes()) == AUDIT_SHA,
        "actual completed producer audit receipt pin")
    require(p.exact(old_audit["experiment"],measured_identity(measured))
        and old_audit["producerSourceSha"] == PRODUCER
        and old_audit["producerMembers"] == 136
        and old_audit["nativeProofReportsVerified"] == 69
        and old_audit["leafAssertionsVerified"] == 3810
        and old_audit["wholeKernelBuilt"] is False
        and old_audit["performanceQualified"] is False,"producer audit identity/scope")
    origin = extracted/"producer"
    members = p.files(origin)
    require(len(members) == 136 and p.exact(members,old_audit["producerFiles"]),
        "all136 producer members match audited inventory")
    raw = (extracted/"producer-artifact.zip").read_bytes()
    require(len(raw) == m.SPEC["size"] and sha(raw) == m.SPEC["sha256"]
        and p.exact(p.digest(raw),old_audit["producerArtifactZip"]),"producer raw ZIP pin")
    m.zip_contents(extracted/"producer-artifact.zip",origin,members)
    p.validate_metadata(m.SPEC,p.read_json(extracted/"producer-api-metadata.json"))
    report = p.read_json(origin/"paired-leaf-report.json")
    require(sha((origin/"paired-leaf-report.json").read_bytes()) == m.REPORT_SHA,
        "paired report byte pin")
    producer_identity = {"sourceSha":PRODUCER,"runId":"40158333460","runAttempt":"1","job":"paired",
        "files":[p.checked_source(producer,name) for name in m.LEAF_FILES]}
    require(p.exact(report["experiment"],producer_identity)
        and report["baselineSourceSha"] == BASE and report["candidateSourceSha"] == CANDIDATE
        and report["compilerSourceSha"] == m.COMPILER
        and report["compilerSha256"] == p.COMPILER_HASH and report["totalAssertions"] == 3810,
        "paired source/runtime identity")
    for name in m.LEAF_FILES:
        require((origin/"experiment-sources"/name).read_bytes() == (producer/name).read_bytes(),
            "producer execution source correspondence")
    require(p.exact(p.read_json(origin/"prepared.json"),{
        "schema":"psc1-empty-cache-leaf-prepared-v1","experiment":producer_identity,
        "baselineSourceSha":BASE,"candidateSourceSha":CANDIDATE,"compilerSourceSha":m.COMPILER,
        "inputs":p.INPUTS,"rawZipSha256Verified":True,"independentZipParser":False}),
        "producer preparation receipt")
    input_receipt = p.read_json(origin/"input-receipt.json")
    require(p.exact(report["inputReceipt"],p.digest((origin/"input-receipt.json").read_bytes())),
        "producer input receipt chain")
    for name,spec in p.INPUTS.items():
        directory = origin/"inputs"/name
        p.validate_metadata(spec,p.read_json(directory/"api-metadata.json"))
        raw_input = (directory/"artifact.zip").read_bytes()
        require(len(raw_input) == spec["size"] and sha(raw_input) == spec["sha256"],
            "nested raw archive pin")
        listed = input_receipt["compilerFiles" if name == "compiler" else "nativeFiles"]
        require(len(listed) == (13 if name == "compiler" else 18)
            and p.exact(p.files(directory/"extracted"),listed),"nested member inventory")
        result = m.zip_contents(directory/"artifact.zip",directory/"extracted",listed)
        require(p.exact(result,old_audit["nestedInputs"][name]),"nested archive receipt")
    compiler = origin/"inputs/compiler/extracted"
    compiler_receipt = p.read_json(compiler/"compiler-receipt.json")
    require(sha((compiler/"compiler-receipt.json").read_bytes()) == p.COMPILER_RECEIPT
        and compiler_receipt["sourceSha"] == m.COMPILER
        and compiler_receipt["compilerSha256"] == p.COMPILER_HASH
        and sha((compiler/"psc1").read_bytes()) == p.COMPILER_HASH,"compiler binary/receipt")
    require(set(compiler_receipt["files"]) | {"compiler-receipt.json"} ==
        set(input_receipt["compilerFiles"]),"compiler file inventory")
    for name,expected in compiler_receipt["files"].items():
        require(sha((compiler/name).read_bytes()) == expected,"compiler file digest")
    require(p.exact(input_receipt["compilerReceipt"],p.digest(
        (compiler/"compiler-receipt.json").read_bytes())),"compiler parent receipt")
    m.verify_native(origin,candidate,input_receipt)
    for i,(root,role) in enumerate([(base,"baseline"),(candidate,"candidate")]):
        receipt = m.verify_variant(origin,root,role,producer)
        require(p.exact(receipt["experiment"],producer_identity),"leaf experiment identity")
        require(p.exact(report["variants"][i],{"variant":role,
            "kernelSourceSha":m.KERNELS[role]["source"],
            "receipt":p.digest((origin/role/"leaf-receipt.json").read_bytes()),
            "generatedKernel":receipt["generatedKernel"]}),"paired leaf receipt chain")
    tools = p.read_json(origin/"tools.json")
    require(p.exact(report["tools"],p.digest((origin/"tools.json").read_bytes()))
        and tools["nodeVersion"] == "v22.23.3" and tools["typescriptVersion"] == "7.0.2"
        and tools["compilerSourceSha"] == m.COMPILER and tools["compilerSha256"] == p.COMPILER_HASH
        and p.exact(tools["node"],old_audit["node"]),"producer tool chain")
    for key,name in [("typescriptPackage","typescript-package.json"),
                     ("typescriptLock","typescript-package-lock.json")]:
        require(p.exact(tools[key],p.digest((origin/"tool-sources"/name).read_bytes())),
            "producer TypeScript source")
    return members,tools

def check_status(directory,arguments,cwd,success=True):
    record = p.read_json(directory/"command-status.json")
    require(set(record) == {"arguments","cwd","timeoutSeconds","timedOut","exitCode",
        "runtimePathEmpty","nodeOptionsEmpty","stdout","stderr"},"exact process status fields")
    require(record["arguments"] == arguments and record["cwd"] == cwd
        and record["timeoutSeconds"] == 60 and record["runtimePathEmpty"] is True
        and record["nodeOptionsEmpty"] is True,"exact frozen command and environment")
    require(p.exact(record["stdout"],p.digest((directory/"stdout.log").read_bytes()))
        and p.exact(record["stderr"],p.digest((directory/"stderr.log").read_bytes())),
        "captured process stdout/stderr chain")
    if success:
        require(record["timedOut"] is False and type(record["exitCode"]) is int
            and record["exitCode"] == 0,"completed process status")
        require((directory/"stderr.log").read_bytes() == b"","completed process stderr")
    else:
        require(type(record["timedOut"]) is bool,"failed process timeout flag")
        if record["timedOut"]:
            require(record["exitCode"] is None,"timed-out process has no exit receipt")
        else:
            require(type(record["exitCode"]) is int and record["exitCode"] != 0,
                "failed non-timeout process exit")
    return record

def config_for(ordinal,tools):
    case_index,position = divmod(ordinal,4)
    case_id,calls = m.CASES[case_index]
    role = m.ABBA[position]
    return {"schema":"psc1-empty-cache-micro-case-v1","experimentSourceSha":MEASURED,
        "runId":str(SPEC["run"]),"runAttempt":"1","job":"micro",
        "sequenceOrdinal":ordinal,"caseIndex":case_index,"caseId":case_id,
        "variant":role,"abbaPosition":position,"kernelSourceSha":m.KERNELS[role]["source"],
        "kernelSha256":m.KERNELS[role]["sha256"],"nodeSha256":tools["node"]["sha256"],
        "warmupCalls":4096,"measuredCalls":calls}

def observation_name(config):
    return str(config["sequenceOrdinal"]).zfill(2)+"-"+config["caseId"].replace("/","-")+"-"+config["variant"]

def audit(audit_source,measured,producer,base,candidate,out):
    sources = check_sources(audit_source,measured,producer,base,candidate)
    identity = audit_identity(audit_source)
    prepared = p.read_json(out/"prepared.json")
    require(p.exact(prepared["audit"],identity) and p.exact(prepared["measurement"],SPEC),
        "audit preparation identity")
    verify_metadata(p.read_json(out/"measurement-api-metadata.json"))
    archive = out/"measurement-artifact.zip"
    require(archive.stat().st_size == SPEC["size"] and sha(archive.read_bytes()) == SPEC["sha256"]
        and p.exact(prepared["rawZip"],p.digest(archive.read_bytes())),"raw partial ZIP identity")
    extracted = out/"input"
    actual,zip_record = raw_members(archive,extracted)
    for name in SOURCE_PINS:
        require((extracted/"experiment-sources"/name).read_bytes() == (measured/name).read_bytes(),
            "archived measured implementation")
    expected_prepared = {"schema":"psc1-empty-cache-micro-prepared-v1",
        "experiment":measured_identity(measured),"producer":m.SPEC,
        "baselineSourceSha":BASE,"candidateSourceSha":CANDIDATE,"compilerSourceSha":m.COMPILER,
        "rawZip":p.digest((extracted/"producer-artifact.zip").read_bytes())}
    require(p.exact(p.read_json(extracted/"prepared.json"),expected_prepared),
        "measured preparation receipt")
    producer_members,tools = verify_producer(extracted,measured,producer,base,candidate)
    expected = {"producer/"+name for name in producer_members}
    expected |= {"producer-api-metadata.json","producer-artifact.zip","prepared.json",
        "artifact-audit.json","execution-tools.json","semantic-controls.json","incomplete.json"}
    expected |= {"experiment-sources/"+name for name in SOURCE_PINS}
    runtime = extracted/"runtime"
    worker_name = pathlib.Path(m.WORKER).name
    require((runtime/worker_name).read_bytes() == (measured/m.WORKER).read_bytes(),
        "actual executed worker bytes")
    expected.add("runtime/"+worker_name)
    require(p.exact(p.read_json(extracted/"execution-tools.json"),{
        "nodeVersion":"v22.23.3","node":tools["node"],
        "worker":p.digest((measured/m.WORKER).read_bytes()),
        "workerSource":p.checked_source(measured,m.WORKER),
        "runtimePathEmpty":True,"nodeOldSpaceMiB":2048,"hostTimeoutSeconds":60,
        "warmupCalls":4096,"explicitGcCallsOutsideTiming":2}),"execution tool/source receipt")
    syntax = p.read_json(extracted/"syntax/command-status.json")
    require(isinstance(syntax["cwd"],str) and pathlib.PurePosixPath(syntax["cwd"]).is_absolute()
        and pathlib.PurePosixPath(syntax["cwd"]).name == "runtime","detached runtime absolute path")
    original_runtime = pathlib.PurePosixPath(syntax["cwd"])
    original_root = original_runtime.parent
    require(original_root.name == "empty-semantic-cache-micro","measured runtime root")
    node = syntax["arguments"][0]
    require(isinstance(node,str) and pathlib.PurePosixPath(node).is_absolute()
        and pathlib.PurePosixPath(node).name == "node","one absolute Node executable")
    check_status(extracted/"syntax",[node,"--check",str(original_runtime/worker_name)],
        str(original_runtime))
    require((extracted/"syntax/stdout.log").read_bytes() == b"","syntax stdout")
    expected |= {"syntax/"+name for name in ("stdout.log","stderr.log","command-status.json")}
    controls = []
    for role in ("baseline","candidate"):
        kernel_name = role+".mjs"
        require((runtime/kernel_name).read_bytes() == (extracted/"producer"/role/"kernel.js").read_bytes(),
            "runtime generated kernel byte correspondence")
        expected.add("runtime/"+kernel_name)
        for label,name,marker,wanted in [
            ("retained",pathlib.Path(p.RETAINED).name,"PSC1_CLOSED_CACHE_ANALYSIS_JS: PASS ",p.RETAINED_RESULT),
            ("empty",pathlib.Path(p.NEW).name,"PSC1_EMPTY_SEMANTIC_CACHE_JS: PASS ",p.EMPTY_RESULT)]:
            script_name = role+"-"+name
            require((runtime/script_name).read_bytes() ==
                (extracted/"producer"/role/"runtime"/name).read_bytes(),"executed semantic harness bytes")
            expected.add("runtime/"+script_name)
            control_name = role+"-"+label
            directory = extracted/"controls"/control_name
            status = check_status(directory,[node,"--max-old-space-size=2048",
                str(original_runtime/script_name),str(original_runtime/kernel_name)],str(original_runtime))
            value = p.runtime_result(directory/"stdout.log",marker,wanted)
            if label == "empty":
                lines = (directory/"stdout.log").read_text().splitlines()
                labels = ["PSC1_EMPTY_SEMANTIC_CACHE_ASSERT harness/rejection",
                    "PSC1_EMPTY_SEMANTIC_CACHE_SECTION harness=1"]
                labels += ["PSC1_EMPTY_SEMANTIC_CACHE_ASSERT empty/"+str(i).zfill(2) for i in range(20)]
                labels += ["PSC1_EMPTY_SEMANTIC_CACHE_SECTION empty=20"]
                require(lines[:-1] == labels,"exact semantic21 labels")
            controls.append({"variant":role,"kind":label,"result":value,"status":status,
                "script":p.digest((runtime/script_name).read_bytes())})
            expected |= {"controls/"+control_name+"/"+name
                for name in ("stdout.log","stderr.log","command-status.json")}
    require(p.exact(p.read_json(extracted/"semantic-controls.json"),{
        "retainedPerVariant":1884,"emptyPerVariant":21,"totalAssertions":3810,
        "processes":4,"records":controls}),"all four untimed semantic control receipts")
    records = []
    statuses = []
    for ordinal in range(33):
        config = config_for(ordinal,tools)
        name = observation_name(config)
        directory = extracted/"observations"/name
        old_directory = original_root/"observations"/name
        require(p.exact(p.read_json(directory/"case-config.json"),config),"frozen per-case configuration")
        status = check_status(directory,[node,"--expose-gc","--max-old-space-size=2048",
            str(original_runtime/worker_name),str(original_runtime/(config["variant"]+".mjs")),
            str(old_directory/"case-config.json")],str(old_directory),success=ordinal < 32)
        statuses.append(status)
        expected |= {"observations/"+name+"/"+leaf for leaf in
            ("case-config.json","command-status.json","stdout.log","stderr.log")}
        if ordinal < 32:
            lines = (directory/"stdout.log").read_text().splitlines()
            require(len(lines) == 1 and lines[0].startswith(m.MARKER),"one completed observation stdout")
            observation = p.parse(lines[0][len(m.MARKER):])
            require(p.exact(observation,p.read_json(directory/"observation.json")),
                "observation JSON/actual stdout equality")
            m.validate_observation(observation,config,m.WORKER_SHA,"v22.23.3")
            records.append(observation)
            expected.add("observations/"+name+"/observation.json")
        else:
            require(not any(line.startswith(m.MARKER) for line in
                (directory/"stdout.log").read_text().splitlines()),"failed process has no success observation")
    require(len(records) == 32 and [r["config"]["sequenceOrdinal"] for r in records] == list(range(32)),
        "exact32 complete ordered observations")
    failed_name = observation_name(config_for(32,tools))
    failed = statuses[32]
    failed_directory = extracted/"observations"/failed_name
    error = "incomplete bounded process; inspect "+str(original_root/"observations"/failed_name)
    incomplete = p.read_json(extracted/"incomplete.json")
    require(p.exact(incomplete,{"schema":"psc1-empty-cache-micro-incomplete-v1",
        "status":"incomplete","phase":"measure","error":error,"sourceSha":MEASURED,
        "runId":str(SPEC["run"]),"runAttempt":"1","processStatusesRetained":33,
        "performanceQualified":False,"optimizationAdopted":False}),"actual incomplete receipt")
    require(len(expected) == 333 and set(actual) == expected,
        "exact333 members; no final56 report, inventory or fabricated later observations")
    reason = "host-timeout" if failed["timedOut"] else (
        "exit-signal" if failed["exitCode"] < 0 else "nonzero-exit")
    diagnosis = {"ordinal":32,"caseId":"indexed/hit","variant":"baseline",
        "warmupCalls":4096,"measuredCalls":1000000,"classification":reason,
        "timedOut":failed["timedOut"],"exitCode":failed["exitCode"],
        "timeoutSeconds":60,"status":failed,
        "stdout":(failed_directory/"stdout.log").read_text(),
        "stderr":(failed_directory/"stderr.log").read_text(),
        "candidateIndexedHitAttempted":False,"remainingObservationsUnattempted":23}
    require(len(diagnosis["stdout"]) <= 100000 and len(diagnosis["stderr"]) <= 100000,
        "bounded failure diagnostic")
    check_sources(audit_source,measured,producer,base,candidate)
    require(p.exact(actual,p.files(extracted)),"archive contents unchanged by read-only audit")
    report = {"schema":"psc1-empty-cache-micro-partial-audit-v1","status":"pass",
        "audit":identity,"measurementSourceSha":MEASURED,"measurementRunId":SPEC["run"],
        "measurementRunAttempt":1,"measurementStatus":"incomplete",
        "artifactId":SPEC["artifact"],"artifactZip":p.digest(archive.read_bytes()),
        "archive":zip_record,"members":actual,"measuredSources":sources,
        "nativeProofReportsVerified":69,"producerMembersVerified":136,
        "producerLeafAssertionsVerified":3810,"timingSemanticAssertionsVerified":3810,
        "completeObservations":32,"retainedProcessStatuses":33,"expectedObservations":56,
        "completeObservationRecords":records,"failure":diagnosis,
        "incompleteReceipt":incomplete,"completeExperiment":False,
        "measurementsRerun":False,"countsOrLimitsChanged":False,"customZipParserImplemented":False,
        "wholeKernelBuilt":False,"wholeKernelRegressionsChecked":False,
        "optimizationAdopted":False,"performanceQualified":False}
    p.write_json(out/"partial-audit-report.json",report)
    print("PSC1_EMPTY_CACHE_MICRO_PARTIAL_AUDIT: PASS "+json.dumps({
        "audit":identity,"measurementSourceSha":MEASURED,"measurementRunId":SPEC["run"],
        "measurementStatus":"incomplete","artifactId":SPEC["artifact"],
        "artifactZip":report["artifactZip"],"files":333,"producerFiles":136,
        "nativeReports":69,"completedObservations":32,"retainedProcessStatuses":33,
        "expectedObservations":56,"failure":diagnosis,
        "report":p.digest((out/"partial-audit-report.json").read_bytes()),
        "completeExperiment":False,"measurementsRerun":False,
        "optimizationAdopted":False,"performanceQualified":False},separators=(",",":")))

def main():
    require(len(sys.argv) == 8 and sys.argv[1] in {"prepare","audit"},
        "usage: micro-audit.py <prepare|audit> audit-source measured producer baseline candidate out")
    audit_source,measured,producer,base,candidate,out = [pathlib.Path(v).resolve() for v in sys.argv[2:]]
    require(os.environ.get("PYTHONDONTWRITEBYTECODE") == "1" and sys.dont_write_bytecode,
        "read-only imports require bytecode writing disabled")
    require(os.environ["GITHUB_REPOSITORY"] == "dwijayuda/pskernel","repository identity")
    load_utilities(measured,producer)
    {"prepare":prepare,"audit":audit}[sys.argv[1]](
        audit_source,measured,producer,base,candidate,out)

if __name__ == "__main__":
    main()
