#!/usr/bin/env python3
"""Read-only verification of archived four-case ABBA evidence; executes no kernel."""
import ast,hashlib,io,json,math,os,pathlib,re,stat,statistics,subprocess,sys,tarfile,urllib.parse,urllib.request,zipfile
CFG=json.loads(pathlib.Path(sys.argv[1]).read_text())
REPO=CFG["repository"];SHA=CFG["sourceSha"];BASE=CFG["baselineSha"]
RUN=int(CFG["runId"]);ATTEMPT=int(CFG["runAttempt"])
CHECKOUT=pathlib.Path(sys.argv[2]).resolve();OUT=pathlib.Path(sys.argv[3]).resolve()
OUT.mkdir(parents=True,exist_ok=True)
REPORT={"schema":"psc1-empty-cache-abba-artifact-audit-v1","sourceSha":SHA,"baselineSha":BASE,
        "runId":str(RUN),"runAttempt":str(ATTEMPT),"status":"running","errors":[],
        "workloadsExecuted":False,"fullKernelQualified":False,"performanceQualified":False}
def require(ok,message):
    if not ok:raise RuntimeError(message)
def equal(a,b):
    if type(a) is not type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys() and all(equal(a[k],b[k]) for k in a)
    if isinstance(a,(list,tuple)):return len(a)==len(b) and all(equal(x,y) for x,y in zip(a,b))
    return a==b
def same(a,b,message):
    require(equal(a,b),message)
def sha(raw):return hashlib.sha256(raw).hexdigest()
def dg(raw):return {"bytes":len(raw),"sha256":sha(raw)}
def git(*args):return subprocess.check_output(["git","-C",str(CHECKOUT),*args])
def source(path,ref=SHA):return git("show",ref+":"+path)
def oid(raw):return hashlib.sha1(b"blob "+str(len(raw)).encode()+b"\0"+raw).hexdigest()
class Redirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self,req,fp,code,msg,headers,newurl):
        target=urllib.parse.urlparse(newurl)
        require(target.scheme=="https" and target.hostname and target.username is None
                and target.password is None and target.port in (None,443),"safe HTTPS redirect")
        result=super().redirect_request(req,fp,code,msg,headers,newurl)
        if result and urllib.parse.urlparse(req.full_url).netloc!=urllib.parse.urlparse(newurl).netloc:
            result.remove_header("Authorization")
        return result
HTTP=urllib.request.build_opener(Redirect())
def get(path):
    url="https://api.github.com/repos/"+REPO+path
    req=urllib.request.Request(url,headers={"Authorization":"Bearer "+os.environ["GH_TOKEN"],
        "Accept":"application/vnd.github+json","X-GitHub-Api-Version":"2022-11-28","User-Agent":"psc1-artifact-audit"})
    with HTTP.open(req,timeout=90) as response:return response.read()
def api(path):return json.loads(get(path))
def logged(text,prefix,expected):
    values=[json.loads(line[len(prefix):]) for line in text.splitlines() if line.startswith(prefix)]
    same(values,[expected],"exact terminal JSON: "+prefix)
def marker(text,value):require(text.splitlines().count(value)==1,"exact terminal marker: "+value)
def clean(raw):
    return "\n".join(re.sub(r"^\d{4}-\d\d-\d\dT\S+\s","",line.lstrip("\ufeff"))
                     for line in raw.decode("utf-8-sig").splitlines())
class Archive:
    def __init__(self,meta,terminal):
        self.meta=meta;raw=get("/actions/artifacts/"+str(meta["id"])+"/zip")
        require(len(raw)==meta["size_in_bytes"] and "sha256:"+sha(raw)==meta["digest"],"API archive bytes/digest")
        require(("Artifact ID "+str(meta["id"])) in terminal or
                ("Artifact ID is "+str(meta["id"])) in terminal,"actual upload artifact identity")
        require("SHA256 digest of uploaded artifact zip is "+sha(raw) in terminal,"actual upload ZIP digest")
        self.z=zipfile.ZipFile(io.BytesIO(raw));infos=self.z.infolist()
        require(len(infos)<=4096 and sum(x.file_size for x in infos)<=1024**3,"bounded archive expansion")
        names=set()
        for info in infos:
            name=info.filename;parts=pathlib.PurePosixPath(name).parts
            require(name and not name.startswith("/") and "\\" not in name and "\0" not in name
                    and ".." not in parts and name not in names,"unique safe ZIP member")
            names.add(name);kind=stat.S_IFMT(info.external_attr>>16)
            require(kind in (0,stat.S_IFREG,stat.S_IFDIR) and not (info.flag_bits&1),"ordinary unencrypted ZIP members")
        require(self.z.testzip() is None,"every ZIP CRC")
        self.files={x.filename:x for x in infos if not x.is_dir()}
        count=re.findall(r"With the provided path, there will be (\d+) files? uploaded",terminal)
        same(count,[str(len(self.files))],"actual upload file count")
        self.receipt={"artifactId":meta["id"],"name":meta["name"],"archive":dg(raw),
                      "files":len(self.files),"apiDigestMatches":True,"crcChecked":True,"uniqueSafePaths":True}
    def raw(self,name):require(name in self.files,"missing archive member: "+name);return self.z.read(name)
    def text(self,name):return self.raw(name).decode("utf-8")
    def json(self,name):return json.loads(self.raw(name))
    def manifest(self):return {name:dg(self.raw(name)) for name in sorted(self.files)}
def identity(obj):
    for key,val in {"sourceSha":SHA,"baselineSha":BASE,"runId":str(RUN),"runAttempt":str(ATTEMPT)}.items():
        same(obj.get(key),val,"source-bound "+key)
def literal(tree,name):
    hits=[n.value for n in tree.body if isinstance(n,ast.Assign)
          and any(isinstance(t,ast.Name) and t.id==name for t in n.targets)]
    require(len(hits)==1,"one data constant: "+name)
    return ast.literal_eval(hits[0])
def proof_reports(text,expected):
    rows=re.findall(r"(?m)^'([^']+)' (?:depends on axioms:\s*\[([^\]]*)\]|does not depend on any axioms)",text)
    same([n for n,_ in rows],expected,"actual ordered native proof reports")
    allowed={"propext","Classical.choice","Quot.sound"}
    require(all({a.strip() for a in used.split(",") if a.strip()}<=allowed for _,used in rows),"standard axioms")
    require(not any(x in text for x in ("sorryAx","Lean.ofReduceBool","Lean.trustCompiler")),"no forbidden dependencies")
def main():
    require(REPO=="dwijayuda/pskernel" and SHA=="054edfce56eda28a166624ddc92dfac5af8499c0"
            and BASE=="20224a295359abb201f56c72395690bf0bfac9fa"
            and RUN==40163474950 and ATTEMPT==1,"reviewed exact experiment target")
    same(git("rev-parse","HEAD").decode().strip(),SHA,"exact audit checkout")
    run=api("/actions/runs/"+str(RUN))
    for key,val in {"head_sha":SHA,"run_attempt":ATTEMPT,"status":"completed","conclusion":"success",
                    "path":".github/workflows/psc1-pskernel-empty-semantic-cache-abba.yml"}.items():
        same(run.get(key),val,"completed exact ABBA run "+key)
    jobs=api("/actions/runs/"+str(RUN)+"/attempts/"+str(ATTEMPT)+"/jobs?per_page=100")["jobs"]
    require(len(jobs)==5,"exact five attempt jobs")
    byname={j["name"]:j for j in jobs}
    roles={"native":"native","compiler":"compiler","baseline":"generated (baseline)",
           "candidate":"generated (candidate)","results":"abba"}
    same(set(byname),set(roles.values()),"exact five ABBA jobs")
    logs={}
    for role,name in roles.items():
        j=byname[name];same(j["status"],"completed","terminal job");same(j["conclusion"],"success","successful job")
        for key,value in {"run_id":RUN,"run_attempt":ATTEMPT,"head_sha":SHA}.items():
            same(j.get(key),value,"exact attempt/source job "+key)
        logs[role]=clean(get("/actions/jobs/"+str(j["id"])+"/logs"))
        (OUT/(role+"-job.log")).write_text(logs[role])
    REPORT["jobs"]={role:{"id":byname[name]["id"],"name":name,"runId":RUN,
        "runAttempt":ATTEMPT,"headSha":SHA,"conclusion":"success"} for role,name in roles.items()}
    arts=api("/actions/runs/"+str(RUN)+"/artifacts?per_page=100")["artifacts"]
    names={"native":"psc1-empty-cache-abba-native-preflight-attempt-1",
           "compiler":"psc1-empty-cache-abba-compiler-attempt-1",
           "baseline":"psc1-empty-cache-abba-baseline-attempt-1",
           "candidate":"psc1-empty-cache-abba-candidate-attempt-1",
           "results":"psc1-empty-cache-abba-results-attempt-1"}
    same({a["name"] for a in arts},set(names.values()),"exact five artifact roles")
    require(len(arts)==5,"unique artifact names")
    archives={}
    for role,name in names.items():
        meta=next(a for a in arts if a["name"]==name)
        require(not meta["expired"] and meta["workflow_run"]["id"]==RUN
                and meta["workflow_run"]["head_sha"]==SHA,"artifact source/run binding")
        if CFG.get("artifactIds"):same(meta["id"],CFG["artifactIds"][role],"pinned artifact ID")
        archives[role]=Archive(meta,logs[role])
    REPORT["artifacts"]={role:a.receipt for role,a in archives.items()}
    native,shared=archives["native"],archives["compiler"]
    same(set(native.files),{"source-audit.json","native-build.log","proofs.log","native-receipt.json"},"native files")
    aud=native.json("source-audit.json");nr=native.json("native-receipt.json")
    identity(aud);identity(nr)
    same(aud["schema"],"psc1-empty-cache-abba-source-v1","source audit schema")
    root="psc1/packages/pskernel-core/src";prod=root+"/Ps/KernelCore/Runtime/Acceleration/CacheAnalysis.lean"
    trees={BASE:"57b209c4b29f7a9dd67bdae37e728cde4a0ac1ff",SHA:"e567685e5c441a5b0a78d8241f7bae151b48b5ca"}
    for ref,tree in trees.items():same(git("rev-parse",ref+":"+root).decode().strip(),tree,"full production tree")
    same(git("diff","--name-only",BASE,SHA,"--",root).decode().splitlines(),[prod],"one production delta")
    same(aud["baselineProductionTree"],trees[BASE],"source baseline tree")
    same(aud["candidateProductionTree"],trees[SHA],"source candidate tree")
    same(aud["productionChanges"],[prod],"truthful production delta")
    for flag in ("frozenBodiesMatch","baselineTransformConstructionRestored","exactLookupGuardAndCommentOnly",
                 "frozenCacheLookupByteExact","retainedProofStatementAndOtherBodiesUnchanged"):
        same(aud.get(flag),True,"source guard "+flag)
    for flag in ("exactBindingMovesOnly","deferredTransformConstruction","fullQualification","performanceQualified"):
        same(aud.get(flag),False,"source scope "+flag)
    before=source(prod,BASE);after=source(prod)
    same(oid(before),"4d5ca3d8e2a6136d5fcb35dec131e5c28e6b743b","complete predecessor blob")
    same(oid(after),"d8f8fd5731d0473370a0028d4f484bcb845d9e57","complete candidate blob")
    def helper(raw):return raw.decode().split("def psKernelSemanticExprMapGet\n",1)[1].split("\n/- None means",1)[0]
    old=("def psKernelSemanticExprMapGet\n"+helper(before)).encode()
    new=("def psKernelSemanticExprMapGet\n"+helper(after)).encode()
    same(len(old),546,"frozen helper size");same(len(new),648,"candidate helper size")
    same(aud["predecessorLookup"],dg(old),"predecessor helper digest")
    same(aud["candidateLookup"],dg(new),"candidate helper digest")
    same(aud["baselineCacheProduction"],{"path":prod,**dg(before),"gitBlobSha":oid(before)},"predecessor full source")
    pins={"psc1/test/PsKernelEmptySemanticCacheProofs.lean":"57a6e6f2a339fdfddb077baa28e344309812cfc5",
          "psc1/test/PsKernelClosedCacheAnalysisRegression.lean":"0e137de5672d6b63dd8a157cfadc398ca1691d59"}
    for path,pin in pins.items():same(oid(source(path)),pin,"exact reviewed proof source")
    retained="psc1/test/PsKernelClosedCacheAnalysisRegression.lean"
    prior=source(retained,BASE).decode();current=source(retained).decode()
    def theorem(text):return text[text.index("theorem semantic_map_get_eq\n"):text.index("\ntheorem semantic_map_insert_eq\n")]
    old_theorem,new_theorem=theorem(prior),theorem(current)
    same(old_theorem.split(":= by",1)[0],new_theorem.split(":= by",1)[0],"retained universal statement unchanged")
    same(current.replace(new_theorem,old_theorem,1),prior,"all other retained proof text unchanged")
    cp=source("psc1/test/PsKernelEmptySemanticCacheProofs.lean").decode()
    same(cp.split("namespace Frozen\n\n",1)[1].split("\nend Frozen",1)[0].encode(),old,"frozen helper bytes")
    prefix=root+"/Ps/KernelCore/Core/ExprV2/"
    transforms={"Transform.lean":"8f50a74edf1d00288efee9c559a05a75b755acbf",
                "TransformSupport.lean":"7957a3aaf87f440b6fb09c2ee98eb574aeab6c72",
                "Lift.lean":"50a63d2729088039a3b01f75eda5c6e83f91e036"}
    same(aud["baselineBlobs"],{prefix+p:b for p,b in transforms.items()},"restored transform blob inventory")
    for path,pin in aud["baselineBlobs"].items():
        same(source(path),source(path,BASE),"complete restored transform bytes");same(oid(source(path)),pin,"restored blob")
    deferred="psc1/test/PsKernelDeferredTransformProofs.lean"
    same(source(deferred),source(deferred,BASE),"unchanged three-report proof source")
    frozen=source(deferred).decode().split("namespace Frozen\n",1)[1].split("\nend Frozen",1)[0]
    def worker(text,name):
        found=re.search(r"(?ms)^def "+re.escape(name)+r"\n.*?(?=^def |\Z)",text)
        require(found is not None,"actual worker body "+name);return found.group(0).rstrip()
    for short,name in zip(transforms,("psKernelExprV2TransformWithFuel",
                          "psKernelExprV2TransformCountWithFuel","psKernelExprV2PagedLiftWithFuel")):
        same(worker(source(prefix+short).decode(),name),worker(frozen,name),"exact frozen transform worker")
    expected=["PsKernelDeferredTransformProofs."+n for n in
              ("transform_with_fuel_eq","count_with_fuel_eq","lift_with_fuel_eq")]+[
              "PsKernelEmptySemanticCacheProofs.semantic_map_get_eq_before",
              "PsKernelEmptySemanticCacheProofs.empty_lookup_ignores_expression"]
    same(aud["proofNames"],expected,"five source names");same(aud["proofs"],5,"source proof count")
    expected_paths=set(aud["baselineBlobs"])|{deferred,prod,*pins,
        "psc1/scripts/pskernel-expr-v2-transform-delay-smoke.mjs",
        ".github/workflows/psc1-pskernel-empty-semantic-cache-abba.yml",
        "psc1/scripts/pskernel-empty-semantic-cache-abba.py"}
    same(set(aud["sourceFiles"]),expected_paths,"exact ten source inputs")
    for path,digest in aud["sourceFiles"].items():same(sha(source(path)),digest,"actual Git source hash "+path)
    proof_reports(native.text("proofs.log"),expected);proof_reports(logs["native"],expected)
    same(nr,{"schema":"psc1-empty-cache-abba-native-v1","sourceSha":SHA,"baselineSha":BASE,
             "runId":str(RUN),"runAttempt":str(ATTEMPT),"proofs":5,"retainedTransformProofs":3,
             "emptyCacheProofs":2,"names":expected,"proofLogSha256":sha(native.raw("proofs.log")),
             "sourceAuditSha256":sha(native.raw("source-audit.json")),
             "baselineTransformConstructionRestored":True,"deferredTransformConstruction":False,
             "fullQualification":False,"performanceQualified":False},"exact native receipt")
    logged(logs["native"],"PSC1_EMPTY_CACHE_ABBA_SOURCE: PASS ",aud)
    logged(logs["native"],"PSC1_EMPTY_CACHE_ABBA_NATIVE: PASS ",nr)
    for name in native.files:same(shared.raw(name),native.raw(name),"shared native evidence "+name)
    compiler=shared.json("compiler-receipt.json");identity(compiler)
    same(compiler["schema"],"psc1-empty-cache-abba-compiler-v1","shared compiler schema")
    same(compiler["leanGitHash"],"eb6cafb7290e8bd5f2937522d8d804f58f02bafc","pinned compiler Lean")
    for flag in ("fullQualification","performanceQualified"):same(compiler[flag],False,"compiler scope")
    same(compiler["compilerSha256"],sha(shared.raw("psc1")),"actual shared compiler binary")
    same(compiler["nativeReceiptSha256"],sha(native.raw("native-receipt.json")),"native/compiler chain")
    runtime_names={"pskernel-expr-v2-transform-delay-smoke.mjs","pskernel-expr-v2-dag-smoke.mjs",
                   "pskernel-expr-v2-generated-smoke.mjs","pskernel-arena-replay-controls.mjs","pskernel-arena-replay.mjs"}
    expected_shared=set(native.files)|{"psc1","compiler-build.log","portable-leaf.log"}|{"runtime/"+n for n in runtime_names}
    same(set(compiler["files"]),expected_shared,"exact twelve shared compiler payloads")
    same(set(shared.files),expected_shared|{"compiler-receipt.json"},"exact thirteen-file shared archive")
    for path,digest in compiler["files"].items():same(sha(shared.raw(path)),digest,"shared file "+path)
    for flag in ("portableLeafChecked","retainedArenaHarnessUnchanged"):same(compiler[flag],True,"retained compiler gate")
    for path in compiler["files"]:
        if path.startswith("runtime/"):same(shared.raw(path),source("psc1/scripts/"+path[8:]),"actual shared harness")
    logged(logs["compiler"],"PSC1_EMPTY_CACHE_ABBA_COMPILER: PASS ",compiler)
    driver=source("psc1/scripts/pskernel-empty-semantic-cache-abba.py")
    parsed=ast.parse(driver);cases=literal(parsed,"CASES");keys=literal(parsed,"SEMANTIC_KEYS")
    required=literal(parsed,"REQUIRED_FILES");same(len(cases),4,"four frozen cases");same(len(required),20,"twenty producer files")
    entry="packages/pskernel-core/src/Ps/KernelCore/SelfHost.lean"
    def closure(ref):
        layout=source("psc1/scripts/workspace-layout.mjs",ref).decode()
        packages=dict(re.findall(r'\["([A-Za-z0-9]+)", "([a-z0-9-]+)"\]',layout))
        same(packages.get("KernelCore"),"pskernel-core","package mapping")
        seen=set()
        def visit(path):
            if path in seen:return
            seen.add(path)
            for module in re.findall(r"^\s*import\s+([A-Za-z0-9_.]+)\s*;?\s*$",source("psc1/"+path,ref).decode(),re.M):
                parts=module.split(".")
                if parts[0]=="ProofScript":child="stdlib/"+"/".join(parts)+".lean"
                else:
                    require(parts[0]=="Ps" and len(parts)>1 and parts[1] in packages,"known import")
                    child="packages/"+packages[parts[1]]+"/src/"+"/".join(parts)+".lean"
                visit(child)
        visit(entry);return sorted(seen)
    closures={ref:closure(ref) for ref in (BASE,SHA)}
    same(closures[BASE],closures[SHA],"same actual import closure paths")
    producers={}
    for variant in ("baseline","candidate"):
        a=archives[variant];pr=a.json("receipt.json");identity(pr)
        same(pr["schema"],"psc1-empty-cache-abba-producer-v1","producer schema")
        same(pr["leanGitHash"],compiler["leanGitHash"],"same pinned Lean producer")
        same(pr["variant"],variant,"producer variant")
        same(pr["kernelSourceSha"],BASE if variant=="baseline" else SHA,"exact kernel source")
        same(pr["compilerSourceSha"],SHA,"same compiler source")
        same(pr["compilerSha256"],compiler["compilerSha256"],"same actual compiler binary")
        same(set(pr["files"]),required,"producer advertised inventory");same(set(a.files),required|{"receipt.json"},"producer ZIP inventory")
        for path,digest in pr["files"].items():same(sha(a.raw(path)),digest,"producer bytes "+variant+"/"+path)
        for old,new_name in (("native-receipt.json","native-receipt.json"),("source-audit.json","native-source-audit.json"),
                             ("proofs.log","native-proofs.log"),("compiler-receipt.json","compiler-receipt.json")):
            same(a.raw(new_name),shared.raw(old),"producer shared evidence "+new_name)
        tools=a.json("producer-tools.json");same(pr["tools"],tools,"exact producer tools")
        same(tools["kernelSourceTree"],trees[pr["kernelSourceSha"]],"actual variant production tree")
        for key,value in {"kernelSourceSha":pr["kernelSourceSha"],"compilerSourceSha":SHA,
            "experimentSourceSha":SHA,"workflowPath":".github/workflows/psc1-pskernel-empty-semantic-cache-abba.yml",
            "nativeSourceAuditSha256":sha(native.raw("source-audit.json")),"leanGitHash":compiler["leanGitHash"],
            "typescriptVersion":"Version 7.0.2"}.items():same(tools[key],value,"producer tool identity "+key)
        require(re.fullmatch(r"v22\.\d+\.\d+",tools["nodeVersion"]) is not None,"producer Node22")
        for path,key in ((".github/workflows/psc1-pskernel-empty-semantic-cache-abba.yml","workflowSha256"),
                         ("psc1/scripts/pskernel-empty-semantic-cache-abba.py","driverSha256")):
            same(tools[key],sha(source(path)),"producer experiment source")
        bootstrap=tools["bootstrap"]
        same(bootstrap["translatorSha256"],compiler["compilerSha256"],"shared canonical translator")
        same(bootstrap["translatorSourceSha"],SHA,"translator source")
        same(bootstrap["replacementCount"],4,"retained adapter substitutions")
        same(bootstrap["adapterSha256"],sha(a.raw("bootstrap-shared.mjs")),"actual canonical adapter")
        same(bootstrap["sourceGitBlob"],oid(source("psc1/scripts/bootstrap-project.mjs")),"original bootstrap source")
        same(bootstrap["sourceSha256"],sha(source("psc1/scripts/bootstrap-project.mjs")),"bootstrap source hash")
        adapter=a.text("bootstrap-shared.mjs");original_bootstrap=source("psc1/scripts/bootstrap-project.mjs").decode()
        root_match=re.findall(r'^const selfhostRoot = ("(?:\\.|[^"\\])*");$',adapter,re.M)
        require(len(root_match)==1,"one shared adapter workspace")
        workspace=json.loads(root_match[0]);require(workspace.startswith("/") and workspace.endswith("/psc1"),"absolute source workspace")
        translator_match=re.findall(r'(?m)^    ("(?:\\.|[^"\\])*"),\n    \[\n',adapter)
        require(len(translator_match)==1,"one shared executable substitution")
        translator=json.loads(translator_match[0])
        require(translator.startswith("/") and translator.endswith("/transform-delay-shared/psc1"),"shared executable path")
        replacements=[
            ('from "./workspace-layout.mjs";','from '+json.dumps(pathlib.PurePosixPath(workspace+"/scripts/workspace-layout.mjs").as_uri())+';'),
            ('from "./bootstrap-manifest.mjs";','from '+json.dumps(pathlib.PurePosixPath(workspace+"/scripts/bootstrap-manifest.mjs").as_uri())+';'),
            ('const selfhostRoot = path.resolve(scriptDir, "..");','const selfhostRoot = '+json.dumps(workspace)+';'),
            ('    "lake",\n    [\n      "exe",\n      "psc1",\n','    '+json.dumps(translator)+',\n    [\n')]
        for old_text,new_text in replacements:
            require(original_bootstrap.count(old_text)==1,"unique reviewed adapter edit")
            original_bootstrap=original_bootstrap.replace(old_text,new_text,1)
        same(adapter,original_bootstrap,"only four shared-compiler adapter substitutions")
        research=tools["research"]
        same(research["sourceSha"],pr["kernelSourceSha"],"separate research source")
        same(research["compilerSha256"],compiler["compilerSha256"],"same research compiler")
        for field,path in (("kernelSha256","research-kernel.mjs"),("buildLogSha256","research-build.log"),
                           ("smokeLogSha256","paged-smoke.log")):same(research[field],sha(a.raw(path)),"research byte binding")
        same(research["harnessSha256"],sha(shared.raw("runtime/pskernel-expr-v2-generated-smoke.mjs")),"retained research harness")
        research_entry="packages/pskernel-core/src/Ps/KernelCore/Research/ExprV2ResearchAll.lean"
        same(research["entry"],research_entry,"retained research entry")
        same(research["entryGitBlob"],oid(source("psc1/"+research_entry,pr["kernelSourceSha"])),"actual research source blob")
        same(research["entrySha256"],sha(source("psc1/"+research_entry,pr["kernelSourceSha"])),"actual research source bytes")
        same(research["kernelFile"],"research-kernel.mjs","research kernel file")
        same(research["compilerSourceSha"],SHA,"research compiler source")
        same(research["validatesSelfHost"],False,"truthful research scope")
        for path,mark in {
            "raw-abi.log":"PSC1_TRANSFORM_DELAY_RAW_JS: PASS assertions=23 exports=3 stagedArrows=11",
            "dag-smoke.log":"PSC1_V2_TRANSFORM_JS: PASS","paged-smoke.log":"PSC1_EXPR_V2_JS_SMOKE: PASS",
            "arena-controls.log":"PSC1_ARENA_REPLAY_CONTROLS: PASS count=138"}.items():marker(a.text(path),mark)
        marker(a.text("dag-smoke.log"),"PSC1_V2_DAG_JS: PASS")
        require(len([l for l in a.text("raw-abi.log").splitlines() if l.startswith("PSC1_TRANSFORM_DELAY_ASSERT ")])==23,"all raw23 controls")
        same(a.json("kernel.js.map")["version"],3,"generated source map")
        manifest=a.json("bootstrap-manifest.json")
        same(manifest["schemaVersion"],2,"canonical manifest schema");same(manifest["generation"],"bootstrap","canonical generation")
        same(manifest["entry"],"packages/pskernel-core/src/Ps/KernelCore/SelfHost.ps","complete canonical entry")
        same(manifest["sourceCount"],157,"retained complete canonical module count")
        same(manifest["generated"],[p[:-5]+".ps" for p in closures[pr["kernelSourceSha"]]],"actual complete closure membership")
        require(re.fullmatch(r"[0-9a-f]{64}",manifest["closureSha256"]) is not None,"recorded canonical body digest")
        marker(logs[variant],"PSC1_EMPTY_CACHE_ABBA_CANONICAL_CLOSURE modules=157")
        for flag in ("fullQualification","performanceQualified"):same(pr[flag],False,"producer scope")
        logged(logs[variant],"PSC1_EMPTY_CACHE_ABBA_PRODUCER: PASS ",pr)
        producers[variant]=pr
    pair=archives["results"];report=pair.json("results/report.json");identity(report)
    same(report["schema"],"psc1-empty-cache-abba-v1","ABBA report schema")
    same(report["producerReceipts"],producers,"exact producer receipts in report")
    for variant in producers:
        for name in archives[variant].files:
            same(pair.raw(variant+"/"+name),archives[variant].raw(name),"result archive producer copy")
    manifest=pair.json("results/sha256.json")
    require(isinstance(manifest,list),"result member manifest")
    listed=[row["path"] for row in manifest]
    same(listed,sorted(set(listed)),"sorted unique result manifest")
    actual={name[8:] for name in pair.files if name.startswith("results/")}
    same(set(listed)|{"sha256.json"},actual,"complete result-manifest membership")
    for row in manifest:
        same(set(row),{"path","sha256"},"manifest record schema")
        same(sha(pair.raw("results/"+row["path"])),row["sha256"],"actual result member hash")
    same(set(pair.files),{"abba.log"}|{"results/"+p for p in actual}|
         {v+"/"+p for v in producers for p in archives[v].files},"complete final ZIP membership")
    oracle_source=source("psc1/scripts/pskernel-arena435-oracle.py")
    oracle_ast=ast.parse(oracle_source);target=literal(oracle_ast,"TARGET")
    archive_hash=literal(oracle_ast,"ARCHIVE_SHA256")
    same(archive_hash,"98a69742b538296c5f413d0527dfeef8c4d1815fe64b12c8623cd33de63bee0d","pinned original corpus")
    req=urllib.request.Request("https://github.com/leanprover/lean-kernel-arena/releases/download/"
        "round-2026-09/lean-arena-round-2026-09-tests.tar.gz",headers={"User-Agent":"psc1-artifact-audit"})
    with HTTP.open(req,timeout=90) as response:corpus_zip=response.read()
    require(len(corpus_zip)==3497743 and sha(corpus_zip)==archive_hash,"original corpus archive bytes")
    corpus={}
    with tarfile.open(fileobj=io.BytesIO(corpus_zip),mode="r:gz") as tar:
        for member in tar:
            require(member.isfile() or member.isdir(),"ordinary corpus member")
            parts=pathlib.PurePosixPath(member.name).parts
            require(not member.name.startswith("/") and ".." not in parts,"safe corpus name")
            if not member.isfile() or not member.name.endswith(".ndjson"):continue
            labels=[p for p in parts if p in ("good","bad")]
            require(len(labels)==1 and member.size<=10*1024**2,"pinned corpus case bounds")
            label=labels[0];name="/".join(parts[parts.index(label)+1:])
            require((label,name) not in corpus,"unique original corpus case")
            corpus[label,name]=tar.extractfile(member).read()
    same(len(corpus),193,"complete original corpus inventory")
    require(sum(map(len,corpus.values()))<=60*1024**2,"bounded original corpus expansion")
    def official(record,path):
        text=pair.text("results/"+path)
        same(record["output_sha256"],sha(text.encode()),"official log hash")
        same(record["log"],path,"official archived log identity")
        status=record["returncode"];accepts=text.count("Lean default kernel accepts the solution")
        rejects=text.count("Lean default kernel rejects the solution")
        quotient=text.count("Quotient post-check rejects the solution")
        verdict,reason=None,None
        if accepts==1 and rejects==quotient==0 and status==0:verdict,reason="accepted","official_kernel_verdict"
        elif accepts==0 and rejects==1 and quotient==0 and status!=0:verdict,reason="rejected","official_kernel_verdict"
        elif accepts==1 and rejects==0 and quotient==1 and status!=0:verdict,reason="rejected","official_quotient_postcheck_rejection"
        else:
            lines=[l.strip() for l in text.splitlines() if l.strip()]
            if status!=0 and accepts==rejects==0 and len(lines)==1 and re.fullmatch(r"uncaught exception: Duplicate declaration: \S+",lines[0]):
                verdict,reason="rejected","official_kernel_duplicate_declaration"
        require(verdict is not None,"unambiguous archived official verdict")
        same(record["verdict"],verdict,"official verdict");same(record["reason"],reason,"official reason")
        require(type(record["elapsed_seconds"]) in (int,float) and math.isfinite(record["elapsed_seconds"])
                and record["elapsed_seconds"]>=0,"official elapsed measurement")
    controls=report["controls"];same(len(controls),2,"two independent official controls")
    for accepted,record in zip((True,False),controls):
        verdict="accepted" if accepted else "rejected"
        same(record["expected"],verdict,"official control polarity");same(record["verdict"],verdict,"official control result")
        rows=[{"meta":{"exporter":{"name":"pskernel-oracle-control","version":"3.1.0"},
                       "format":{"version":"3.1.0"},"lean":target}},
              {"in":1,"str":{"pre":0,"str":"PsKernelArenaOracleControl"}},
              {"il":1,"succ":0},{"ie":0,"sort":0},{"ie":1,"sort":1},
              {"def":{"all":[1],"hints":"abbrev","levelParams":[],"name":1,"safety":"safe",
                      "type":1 if accepted else 0,"value":0}}]
        data=("\n".join(json.dumps(r,separators=(",",":")) for r in rows)+"\n").encode()
        same(pair.raw("results/official-control-"+verdict+".ndjson"),data,"actual official control bytes")
        official(record,verdict+".official.txt")
    prepared=[]
    for index,(label,name,body_hash) in enumerate(cases):
        raw=corpus[label,name];header,newline,body=raw.partition(b"\n")
        require(newline==b"\n" and body,"complete original case")
        same(sha(body),body_hash,"pinned original body")
        meta=json.loads(header);old_lean=meta["meta"]["lean"];meta["meta"]["lean"]=target
        adapted=json.dumps(meta,ensure_ascii=False,separators=(",",":")).encode()+b"\n"+body
        same(pair.raw("results/input-"+str(index)+".ndjson"),adapted,"exact header-only adapted input")
        adaptation={"method":"header_only_compatibility_NOT_native_435_reexport","original_lean":old_lean,
                    "target_lean":target,"original_sha256":sha(raw),"adapted_sha256":sha(adapted),
                    "original_body_sha256":body_hash,"adapted_body_sha256":body_hash,"body_bytes_identical":True}
        prepared.append((adapted,adaptation))
    stages={"source-decode","module-load","transport","declaration-ordering",
            "kernel-admission","metadata-decode","metadata-compare"}
    def progress(text,input_hash):
        last=None;count=invalid=0;elapsed=-1.0
        for line in text.splitlines():
            if not line.startswith("PSC1_ARENA_PROGRESS "):continue
            try:
                value=json.loads(line[len("PSC1_ARENA_PROGRESS "):])
                require(isinstance(value,dict) and value.get("format")=="psc1-arena-progress-v2"
                    and value.get("sourceSha256")==input_hash and value.get("stage") in stages
                    and value.get("fuel")=="4096" and type(value.get("coreInvoked")) is bool,"progress envelope")
                timer=value.get("elapsedMilliseconds")
                require(type(timer) in (int,float) and 0<=timer<=9007199254740991 and timer>=elapsed,"progress time")
                for field in ("records","exportedDeclarations","admissionCommands"):
                    if field in value:require(type(value[field]) is int and 0<=value[field]<=9007199254740991,"progress count")
                if "arenaNodes" in value:require(isinstance(value["arenaNodes"],str)
                    and re.fullmatch(r"0|[1-9][0-9]{0,30}",value["arenaNodes"]) is not None,"arena size")
                last={k:value[k] for k in ("stage","coreInvoked","records","exportedDeclarations",
                      "admissionCommands","arenaNodes","fuel","sourceSha256","elapsedMilliseconds") if k in value}
                elapsed=timer;count+=1
            except (ValueError,TypeError,RuntimeError):invalid+=1
        return {"progress_snapshots":count,"invalid_progress_snapshots":invalid,"last_progress":last}
    def classify(ref,obs):
        official,current=ref["verdict"],obs["verdict"]
        if current not in ("accepted","rejected","malformed"):return "pskernel_"+current
        if current=="accepted" and official=="rejected":return "false_accept"
        if current in ("rejected","malformed") and official=="accepted":return "false_reject"
        if obs.get("containsUnsafeOrPartial") is True:return "agreement_with_unsafe_or_partial_contract_difference"
        if current=="accepted":return "matched_acceptance"
        if current=="malformed":return "matched_transport_rejection"
        return "matched_metadata_rejection" if obs.get("stage")=="metadata" else "matched_kernel_rejection"
    records=report["records"];same(len(records),16,"all sixteen observations")
    observation_lines=[];errors=[];expected_files={"report.json","sha256.json",
        "official-control-accepted.ndjson","official-control-rejected.ndjson",
        "accepted.official.txt","rejected.official.txt"}|{
        "input-"+str(i)+".ndjson" for i in range(4)}|{"case-"+str(i)+".official.txt" for i in range(4)}
    for ordinal,record in enumerate(records):
        round_index,index=divmod(ordinal,4);variant=("baseline","candidate","candidate","baseline")[round_index]
        label,name,body_hash=cases[index];data,adaptation=prepared[index]
        for key,val in {"round":round_index,"variant":variant,"index":index,"label":label,
                        "name":name,"bodySha256":body_hash,"adaptation":adaptation}.items():same(record[key],val,"ordered observation "+key)
        folder="round-"+str(round_index)+"/case-"+str(index)+"/"
        same(pair.json("results/"+folder+"record.json"),record,"actual individual observation record")
        expected_files.add(folder+"record.json")
        ref,obs=record["reference"],record["observed"];official(ref,"case-"+str(index)+".official.txt")
        same(ref["verdict"],"accepted" if label=="good" else "rejected","original official outcome")
        suffix="case-"+str(index).zfill(3)
        for field,tail in (("stdout","-stdout.txt"),("stderr","-stderr.txt"),("time_log","-time.txt")):
            same(obs[field],suffix+tail,"observation log identity")
        stdout=pair.text("results/"+folder+obs["stdout"]);stderr=pair.text("results/"+folder+obs["stderr"])
        expected_files.update((folder+obs["stdout"],folder+obs["stderr"]))
        measurement={key:obs[key] for key in ("elapsed_seconds","returncode","stdout","stderr","time_log")}
        require(type(obs["elapsed_seconds"]) in (int,float) and math.isfinite(obs["elapsed_seconds"])
                and obs["elapsed_seconds"]>=0 and type(obs["returncode"]) is int,"actual observation measurements")
        measurement.update(progress(stderr,sha(data)))
        timing=folder+obs["time_log"]
        if timing in actual:
            expected_files.add(timing);text=pair.text("results/"+timing)
            peak=re.search(r"Maximum resident set size \(kbytes\):\s*(\d+)",text)
            if peak:measurement["peak_rss_kib"]=int(peak[1])
        if obs["verdict"]=="timeout":
            require(obs["elapsed_seconds"]>=60,"actual sixty-second timeout boundary")
            expected_obs={**measurement,"verdict":"timeout","stage":"host-wall-time","timeout_seconds":60}
        else:
            lines=[l[len("PSC1_ARENA_REPLAY "):] for l in stdout.splitlines() if l.startswith("PSC1_ARENA_REPLAY ")]
            if len(lines)!=1 and re.search(r"FATAL ERROR:.*JavaScript heap out of memory",stderr):
                expected_obs={**measurement,"verdict":"resource_exhausted","stage":"host-heap",
                              "reason":"Node reported JavaScript heap exhaustion","host_heap_mib":2048}
            else:
                require(len(lines)==1,"one actual generated-kernel verdict")
                verdict=json.loads(lines[0])
                require(verdict.get("verdict") in {"accepted","rejected","malformed","unsupported","resource_exhausted","internal_error"}
                        and verdict.get("format")=="psc1-arena-replay-v1" and verdict.get("fuel")=="4096"
                        and verdict.get("sourceSha256")==sha(data) and obs["returncode"]==0,"valid generated envelope")
                if verdict["verdict"]=="accepted":
                    require(verdict.get("metadataValidated") is True and verdict.get("coreInvoked") is True,"independent acceptance checks")
                expected_obs={**verdict,**measurement}
        same(obs,expected_obs,"actual raw logs reconstruct complete observation")
        classification=classify(ref,obs);same(record["classification"],classification,"recomputed classification")
        if obs["verdict"]=="driver_error" or classification in ("false_accept","false_reject"):
            errors.append(variant+":"+name+":"+classification)
        if name=="perf/church-numerals.ndjson" and (obs["verdict"]!="resource_exhausted"
            or obs.get("stage")!="kernel-admission" or "kernel reduction budget exhausted" not in obs.get("reason","")):
            errors.append("original Church fuel error changed: "+variant)
        if name in ("perf/repeated-subproblem.ndjson","bugs/proj-of-stuck-prop.ndjson") and obs["verdict"]!=ref["verdict"]:
            errors.append("retained complete control regressed: "+variant+":"+name)
        observation_lines.append({"round":round_index,"variant":variant,"name":name,"verdict":obs["verdict"],
            "elapsedSeconds":obs.get("elapsed_seconds"),"peakRssKiB":obs.get("peak_rss_kib"),"lastProgress":obs.get("last_progress")})
    same(actual,expected_files,"exact result file inventory including timeout logs")
    summaries=[]
    for _,name,_ in cases:
        groups={v:[r["observed"] for r in records if r["name"]==name and r["variant"]==v] for v in producers}
        complete={v:[o for o in rows if o["verdict"]!="timeout"
                      and o.get("stage") not in ("host-heap","host-stack-or-allocation")] for v,rows in groups.items()}
        for left in complete["baseline"]:
            for right in complete["candidate"]:
                if {k:left.get(k) for k in keys}!={k:right.get(k) for k in keys}:errors.append("complete result mismatch: "+name)
        if len(complete["baseline"])==2 and len(complete["candidate"])<2:errors.append("new candidate host resource failure: "+name)
        if any(o.get("stage")=="host-heap" for o in groups["candidate"]) and not any(o.get("stage")=="host-heap" for o in groups["baseline"]):
            errors.append("new candidate heap exhaustion: "+name)
        bounded=all(len(rows)==2 for rows in complete.values())
        med={v:statistics.median(o["elapsed_seconds"] for o in rows) for v,rows in groups.items()}
        rss={v:[o["peak_rss_kib"] for o in rows if "peak_rss_kib" in o] for v,rows in groups.items()}
        ratio=med["candidate"]/med["baseline"] if bounded else None
        rss_ratio=statistics.median(rss["candidate"])/statistics.median(rss["baseline"]) if bounded and all(len(x)==2 for x in rss.values()) else None
        summaries.append({"name":name,"verdicts":{v:[o["verdict"] for o in rows] for v,rows in groups.items()},
            "elapsedSeconds":{v:[o["elapsed_seconds"] for o in rows] for v,rows in groups.items()},
            "peakRssKiB":rss,"uncensoredPair":bounded,"candidateMedianTimeRatio":ratio,"candidateMedianRssRatio":rss_ratio,
            "timeRegressionOver10Percent":ratio is not None and ratio>1.10,
            "rssRegressionOver15Percent":rss_ratio is not None and rss_ratio>1.15})
    same(report["summaries"],summaries,"independently recomputed medians/censoring/regression flags")
    same(report["errors"],sorted(set(errors)),"recomputed semantic error list");same(errors,[],"semantic diagnostics pass")
    same(report["diagnosticsComplete"],True,"complete16 diagnostic")
    for key,val in {"archiveSha256":archive_hash,"targetLean":target,"sequence":["A","B","B","A"],
        "freshProcessEachCase":True,"kernelFuel":4096,"hostWallSeconds":60,"nodeOldSpaceMiB":2048,
        "runtimePathEmpty":True,"fullArenaQualification":False,"performanceQualified":False}.items():same(report[key],val,"retained protocol "+key)
    for key,path in {"driverSha256":"pskernel-empty-semantic-cache-abba.py","comparisonDriverSha256":"pskernel-arena435-compare.py",
                     "oracleSha256":"pskernel-arena435-oracle.py","replaySha256":"pskernel-arena-replay.mjs"}.items():
        same(report[key],sha(source("psc1/scripts/"+path)),"actual protocol source hash")
    require(re.fullmatch(r"v22\.\d+\.\d+",report["nodeVersion"]) is not None
            and re.fullmatch(r"[0-9a-f]{64}",report["nodeSha256"]) is not None,"recorded Node identity")
    obs_prefix="PSC1_EMPTY_CACHE_ABBA_OBSERVATION "
    for text in (pair.text("abba.log"),logs["results"]):
        values=[json.loads(l[len(obs_prefix):]) for l in text.splitlines() if l.startswith(obs_prefix)]
        same(values,observation_lines,"actual sixteen terminal observation receipts")
        marker(text,"PSC1_EMPTY_CACHE_ABBA: PASS observations=16 cases=4 kernelFuel=4096 fullArena=false performanceQualified=false")
    logged(logs["results"],"PSC1_EMPTY_CACHE_ABBA_REPORT ",report)
    REPORT.update(status="pass",nativeReports=5,sourceInputs=10,compilerBinaryVerified=True,
        producerFileInventory=20,observations=16,cases=4,originalBodyBytesVerified=True,
        officialVerdictsFromActualLogs=True,actualRuntimeLogsReconstructed=True,semanticDiagnosticsPassed=True,
        summaries=summaries,experimentReport=dg(pair.raw("results/report.json")),
        rawRuntimeKernels={v:dg(archives[v].raw("kernel.js")) for v in producers},
        canonicalManifestStructuralOnly=True,canonicalSourceBodiesArchived=False,nodeBinaryArchived=False,
        performanceFlagsAreDiagnostic=True,globalPerformanceQualified=False,
        artifactMembers={role:a.manifest() for role,a in archives.items()})
try:
    main()
except Exception as error:
    REPORT["status"]="fail";REPORT["errors"].append(type(error).__name__+": "+str(error))
finally:
    raw=(json.dumps(REPORT,indent=2,ensure_ascii=False,allow_nan=False)+"\n").encode()
    (OUT/"audit.json").write_bytes(raw)
    summary={"status":REPORT["status"],"sourceSha":SHA,"baselineSha":BASE,"runId":str(RUN),
             "runAttempt":str(ATTEMPT),"report":dg(raw),"errors":REPORT["errors"],
             "workloadsExecuted":False,"performanceQualified":False}
    (OUT/"summary.json").write_text(json.dumps(summary,indent=2)+"\n")
    print("PSC1_EMPTY_CACHE_ABBA_ARTIFACT_AUDIT: "+REPORT["status"].upper()+" "+json.dumps(summary,separators=(",",":")))
sys.exit(0 if REPORT["status"]=="pass" else 1)
