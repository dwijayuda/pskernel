import bisect,collections,hashlib,json,pathlib,re
reports=list(pathlib.Path("baseline").rglob("qualification.json"));assert len(reports)==1
r=json.loads(reports[0].read_text());assert r["testedCommit"]=="1174300d0efc2a10cf6887e598a1a4057f36c7cc"
module=reports[0].parent/"G1-service/module.php";source=module.read_bytes();assert hashlib.sha256(source).hexdigest()==r["generations"][0]["sourceSha256"]
files=list(pathlib.Path("sample").rglob("all-samples.json"));assert len(files)==1;samples=json.loads(files[0].read_text())
lines=source.decode().splitlines();markers=[]
for i,line in enumerate(lines,1):
 match=re.match(r'^\s*// declaration (.*)$',line)
 if match:markers.append((i,match.group(1)[1:-1]))
positions=[row[0] for row in markers];methods=[]
for i,line in enumerate(lines[:positions[0]-1]):
 match=re.search(r'public function (offsetGet|offsetExists|offsetSet|offsetUnset|__destruct)\(',line)
 if not match:continue
 depth=0
 for j in range(i,len(lines)):
  depth+=lines[j].count("{")-lines[j].count("}")
  if depth==0:methods.append((i+1,j+1,match.group(1)));break
def owner(line):
 for a,b,name in methods:
  if a<=line<=b:return "nodes."+name
 index=bisect.bisect_right(positions,line)-1
 return markers[index][1] if index>=0 else "<runtime-other>"
counts=collections.Counter();rows=[]
for sample in samples:
 frame=next((f for f in sample["frames"] if f.get("file","").endswith("/G1-service/module.php")),None)
 assert frame is not None
 line=frame["line"];label=owner(line);counts[label]+=1;rows.append({"seconds":sample["seconds"],"line":line,"owner":label})
result={"schema":"psc1-exact-php-sample-label-recovery/1","qualified":False,"sourceSha256":hashlib.sha256(source).hexdigest(),"samples":len(samples),"sampledInterruptedOwners":counts.most_common(),"scope":"read-only recovery of existing async interrupted-callsite samples; not CPU attribution or compiler execution"}
out=pathlib.Path("diagnostics/php-current-labels");out.mkdir(parents=True,exist_ok=True);(out/"receipt.json").write_text(json.dumps(result,indent=2)+"\n");(out/"labeled-samples.json").write_text(json.dumps(rows,indent=2)+"\n")
print("PSC1_PHP_CURRENT_LABELS: "+json.dumps(result))
