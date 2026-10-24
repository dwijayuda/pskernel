import hashlib,json,pathlib,sys
root=pathlib.Path(sys.argv[1])
reports=list(root.rglob("qualification.json"));assert len(reports)==1
report=json.loads(reports[0].read_text());base=reports[0].parent
assert report["testedCommit"]=="59ef3544cb97e03ffb9e0289e61685b654349cf2"
assert report["target"]=="php"
assert report["status"]=="failed"
assert [g["generation"] for g in report["generations"]]==[1]
out={"schema":"psc1-php-G2-memory-inspection/1","qualified":False,"scope":"read-only exact failed artifact inspection; no compiler executed","sourceModules":report["sourceModules"],"sourceClosureDigest":report["sourceClosureDigest"],"bootstrap":report["bootstrap"],"generation1":report["generations"][0],"events":report["events"],"attempts":report["attempts"]}
source=base/"G1-service"/"module.php"
data=source.read_bytes()
out["source"]={"bytes":len(data),"sha256":hashlib.sha256(data).hexdigest()}
assert out["source"]["sha256"]==report["generations"][0]["sourceSha256"]
candidate=base/"G1-bootstrap.candidate.json"
out["candidateBytes"]=candidate.stat().st_size
lines=data.decode("utf-8").splitlines()
site=200434
out["failureSite"]=[{"line":i+1,"text":lines[i][:1000]} for i in range(site-20,min(site+20,len(lines)))]
headers=[(i+1,line[:1200]) for i,line in enumerate(lines[:site]) if "= static function" in line or "= function" in line]
out["precedingFunctionHeaders"]=headers[-8:]
out["runtimePrefix"]=[{"line":i+1,"text":line[:1000]} for i,line in enumerate(lines[:160])]
dst=pathlib.Path("diagnostics");dst.mkdir(exist_ok=True)
(dst/"php-g2-memory-inspection.json").write_text(json.dumps(out,indent=2)+"\n")
print("PSC1_PHP_G2_MEMORY_INSPECTION: "+json.dumps(out))
