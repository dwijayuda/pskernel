"""Artifact-only diagnostic. This does not qualify a source revision."""
import hashlib,io,json,os,pathlib,re,stat,subprocess,sys,urllib.error,urllib.request,zipfile
S="a298be9d9d770dffcfdbffd7f8414e8d76f9641a"
RUN=40115285221
ART=12569921711
HASH="25caa820b1d27f19170544afcfe0702c891ff4fb49c8ba9974700cee050d3b09"
ROOT=pathlib.Path(os.environ["SOURCE_ROOT"])
OUT=pathlib.Path(os.environ["PREFLIGHT_OUT"])
API="https://api.github.com/repos/dwijayuda/pskernel/"
TOKEN=os.environ["GH_TOKEN"]
R={"schema":"psc1-t05-artifact-preflight-v1","diagnosticOnly":True,"qualified":False,
 "sourceSha":S,"runId":RUN,"attempt":1,"artifactId":ART,"results":{}}
def need(ok,msg):
  if not ok: raise RuntimeError(msg)
def dig(b):return {"bytes":len(b),"sha256":hashlib.sha256(b).hexdigest()}
class NoRedirect(urllib.request.HTTPRedirectHandler):
  def redirect_request(self,*args):return None
def get(path):
  req=urllib.request.Request(API+path,headers={"Authorization":"Bearer "+TOKEN,
    "Accept":"application/vnd.github+json","X-GitHub-Api-Version":"2022-11-28"})
  try:
    response=urllib.request.build_opener(NoRedirect).open(req,timeout=120)
  except urllib.error.HTTPError as e:
    need(e.code==302,"GitHub download/read failed: "+str(e.code))
    url=e.headers["Location"];need(url.startswith("https://"),"Non-HTTPS redirect")
    response=urllib.request.urlopen(url,timeout=180)
  with response:
    b=response.read(64*1024*1024+1)
  need(len(b)<=64*1024*1024,"Unexpected artifact size")
  return b
cache={}
def blob(p):
  need(p and not p.startswith("/") and "\\" not in p and
    all(x not in ("",".","..") for x in p.split("/")),"Unsafe source path")
  if p not in cache:
    cache[p]=subprocess.check_output(["git","-C",str(ROOT),"cat-file","blob",S+":"+p])
  return cache[p]
def main():
  need(os.environ.get("GITHUB_ACTIONS")=="true" and os.environ.get("RUNNER_OS")=="Linux","Actions Linux only")
  need(subprocess.check_output(["git","-C",str(ROOT),"rev-parse","HEAD"],text=True).strip()==S,"Wrong checkout")
  meta=json.loads(get("actions/artifacts/"+str(ART)))
  need(meta["workflow_run"]["id"]==RUN and meta["workflow_run"]["head_sha"]==S and
    meta["name"]=="psc1-t05-header-generated-attempt-1" and not meta["expired"],"Artifact identity")
  raw=get("actions/artifacts/"+str(ART)+"/zip")
  need(dig(raw)["sha256"]==HASH and meta["digest"]=="sha256:"+HASH and len(raw)==meta["size_in_bytes"],"Archive digest")
  files={}
  with zipfile.ZipFile(io.BytesIO(raw)) as z:
    seen=set()
    for f in z.infolist():
      p=f.filename.rstrip("/") if f.is_dir() else f.filename
      need(p and p not in seen and not p.startswith("/") and "\\" not in p and
        all(x not in ("",".","..") for x in p.split("/")),"Unsafe/duplicate ZIP path")
      seen.add(p)
      need(stat.S_IFMT(f.external_attr>>16) in (0,stat.S_IFREG,stat.S_IFDIR),"ZIP special file")
      need(f.file_size<128*1024*1024,"Unexpected member size")
      if not f.is_dir():files[p]=z.read(f)
    need(z.testzip() is None,"ZIP CRC")
  def j(p):return json.loads(files[p])
  inv=j("source-inventory.json");prov=j("provenance.json");manifest=j("lean-source-manifest.json")
  for v in (inv,prov,manifest):
    need(v["sourceSha"]==S and v["runId"]==str(RUN) and v["runAttempt"]=="1" and
      v["route"]=="generated","Evidence source/run/attempt identity")
  need(inv["job"]==prov["job"]=="generated-header","Evidence job identity")
  need(prov["leanCommit"]=="eb6cafb7290e8bd5f2937522d8d804f58f02bafc" and
    prov["fuel"]==4096 and prov["oldSpaceMiB"]==2048 and prov["emptyPATH"] is True and
    prov["fullAdmission"] is False,"Retained provenance limits")
  for name,key in [("source-inventory.json","sourceInventory"),("lean-source-manifest.json","leanSourceManifest"),
          ("detached/kernel.mjs","kernel")]:
    need(dig(files[name])==prov[key],"Provenance digest "+name)
  need(files["detached/kernel.mjs"]==files["production/kernel.js"],"Production kernel mismatch")
  packages=dict(re.findall(r'\["(\w+)", "([\w-]+)"\]',blob("psc1/scripts/workspace-layout.mjs").decode()))
  closure=set()
  def visit(p):
    if p in closure:return
    closure.add(p)
    for mod in re.findall(r"^\s*import\s+([A-Za-z0-9_.]+)\s*;?\s*$",blob("psc1/"+p).decode(),re.M):
      parts=mod.split(".")
      if parts[0]=="ProofScript":child="stdlib/"+"/".join(parts)+".lean"
      else:
        need(parts[0]=="Ps" and parts[1] in packages,"Unknown closure import")
        child="packages/"+packages[parts[1]]+"/src/"+"/".join(parts)+".lean"
      visit(child)
  entry="packages/pskernel-core/src/Ps/KernelCore/SelfHost.lean";visit(entry)
  need(manifest["entry"]==entry and manifest["sourceCount"]==len(closure)==148,"Actual148 closure")
  need([r["path"] for r in manifest["files"]]==sorted(closure),"Closure membership")
  for row in manifest["files"]:
    b=blob("psc1/"+row["path"])
    need(row=={"path":row["path"],**dig(b)} and files["lean-source/"+row["path"]]==b,"Closure Git bytes")
  kernel=OUT/"kernel.mjs";kernel.write_bytes(files["detached/kernel.mjs"])
  R.update({"archive":dig(raw),"crcVerified":True,"leanGitModules":148,
       "provenance":prov,"kernel":dig(kernel.read_bytes()),"harnesses":{}})
  names={"params":"pskernel-ordinary-constructor-params-smoke.mjs",
     "result":"pskernel-ordinary-constructor-result-smoke.mjs"}
  for kind,name in names.items():
    b=files["detached/"+name]
    need(dig(b)==prov["scripts"][name] and b==blob("psc1/scripts/"+name),"Original harness authentication")
    before=dig(b)
    if kind=="params":
      old=b"ok({fst:single.state,snd:999999n})"
      new=b'ok(get("Prod").mk(single.state,999999n))'
      need(b.count(old)==2,"Exactly two expected-value replacements")
      b=b.replace(old,new)
    R["harnesses"][kind]={"before":before,"after":dig(b),"replacements":2 if kind=="params" else 0}
    (OUT/name).write_bytes(b)
  need(R["harnesses"]["result"]["before"]==R["harnesses"]["result"]["after"],"Result harness must remain unchanged")
  node=os.environ["NODE_BIN"]
  need(subprocess.check_output([node,"--version"],text=True).startswith("v22."),"Node22 required")
  child_env={k:v for k,v in os.environ.items() if k not in ("GH_TOKEN","GITHUB_TOKEN","ACTIONS_RUNTIME_TOKEN")}
  child_env["PATH"]="";child_env["NODE_OPTIONS"]=""
  for kind,name in names.items():
    start=__import__("time").monotonic()
    with (OUT/(kind+".log")).open("wb") as output:
      try:
        cp=subprocess.run([node,"--max-old-space-size=2048",str(OUT/name),str(kernel)],
                 cwd=OUT,env=child_env,stdout=output,stderr=subprocess.STDOUT,timeout=1500)
        code=cp.returncode
      except subprocess.TimeoutExpired:code=124
    text=(OUT/(kind+".log")).read_text()
    print("PSC1_T05_DIAGNOSTIC_LOG "+kind+"\n"+text,flush=True)
    expected=268 if kind=="params" else 432
    marker="PSC1_ORDINARY_CONSTRUCTOR_"+kind.upper()+"_JS: PASS assertions="+str(expected)+" fullAdmission=false"
    passed=code==0 and text.splitlines().count(marker)==1
    R["results"][kind]={"exitCode":code,"pass":passed,"assertionsExpected":expected,
      "wallSeconds":__import__("time").monotonic()-start,"log":dig((OUT/(kind+".log")).read_bytes())}
    print("PSC1_T05_DIAGNOSTIC_ROUTE "+json.dumps({"kind":kind,**R["results"][kind]}),flush=True)
  need(all(v["pass"] for v in R["results"].values()),"At least one independent harness failed")
OUT.mkdir(parents=True,exist_ok=True)
code=0
try:main()
except Exception as e:R["error"]=str(e);code=1
R["status"]="pass" if code==0 else "fail"
(OUT/"preflight.json").write_text(json.dumps(R,indent=2)+"\n")
print("PSC1_T05_ARTIFACT_PREFLIGHT: "+R["status"].upper()+" "+json.dumps(R,separators=(",",":")),flush=True)
sys.exit(code)
