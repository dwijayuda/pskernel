import bisect,hashlib,json,pathlib,re
reports=list(pathlib.Path("baseline").rglob("qualification.json"));assert len(reports)==1
report=json.loads(reports[0].read_text());assert report["testedCommit"]=="75f04cfdcafc1fbeea08f66f595f40ff6b777d04"
module=reports[0].parent/"G1-service/module.php";source=module.read_bytes()
assert hashlib.sha256(source).hexdigest()==report["generations"][0]["sourceSha256"]
samples=list(pathlib.Path("sample").rglob("samples.json"));assert len(samples)==1
data=json.loads(samples[0].read_text())
# Diagnostic injected driver precedes every declaration; account for added lines.
driver='            [$fn, $arguments] = $task->current();'
text=source.decode();assert text.count(driver)==1
init="$pending = [$root];";assert text.count(init)==1
added=5+17
# Derive exact shift from the committed diagnostic generator, without executing it.
diagnostic=pathlib.Path(".github/diagnostics/psc1-php-node-phase.py").read_text()
initText=diagnostic.split('source=source.replace(init,init+"""',1)[1].split('""")',1)[0]
injection=diagnostic.split('injection="""',1)[1].split('"""',1)[0]
added=initText.count("\n")+injection.count("\n")
markers=[]
for line,content in enumerate(text.splitlines(),1):
 match=re.match(r'^\s*// declaration ("(?:[^"\\]|\\.)*")$',content)
 if match:markers.append((line+added,json.loads(match.group(1))))
assert markers and added>0
positions=[line for line,name in markers]
rows=[]
for position,count in data["sampledGeneratorStarts"].items():
 index=bisect.bisect_right(positions,int(position))-1
 rows.append({"diagnosticStartLine":int(position),"originalStartLine":int(position)-added,"owner":markers[index][1] if index>=0 else "<runtime>","samples":count})
rows.sort(key=lambda row:-row["samples"])
result={"schema":"psc1-php-existing-phase-owner-recovery/1","qualified":False,"sourceSha256":hashlib.sha256(source).hexdigest(),"diagnosticLineShift":added,"existingSampleElapsedSeconds":data["elapsedSeconds"],"sampleRows":rows[:50],"scope":"read-only mapping of existing yield-boundary samples; no compiler execution and no CPU attribution"}
out=pathlib.Path("diagnostics/php-owner-recovery");out.mkdir(parents=True,exist_ok=True);(out/"receipt.json").write_text(json.dumps(result,indent=2)+"\n")
print("PSC1_PHP_OWNER_RECOVERY: "+json.dumps(result))
