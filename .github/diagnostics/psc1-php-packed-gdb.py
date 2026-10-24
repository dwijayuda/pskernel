import hashlib,json,os,pathlib,signal,subprocess,time
root=pathlib.Path("baseline");reports=list(root.rglob("qualification.json"));assert len(reports)==1
report=json.loads(reports[0].read_text());base=reports[0].parent
assert report["testedCommit"]=="c3f53a7bf6f092e118a21a3d37f0b5ab4385c0c7" and report["target"]=="php"
assert report["status"]=="failed" and [g["generation"] for g in report["generations"]]==[1]
digest=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
service=base/"G1-service";module=service/"module.php";request=base/"G2-self.request.json"
assert digest(module)==report["generations"][0]["sourceSha256"]
event=next(e for e in report["events"] if e.get("id")=="G2-self")
assert digest(request)==event["requestSha256"]
manifest=json.loads((service/"artifact.json").read_text())
for entry in manifest["files"]:
 p=service/entry["path"];assert p.is_file() and p.stat().st_size==entry["bytes"] and digest(p)==entry["sha256"]
assert subprocess.check_output(["php","-r","echo PHP_VERSION;"],text=True)=="8.5.12"
command=["gdb","--batch","-ex","set pagination off","-ex","set disable-randomization off","-ex","run","-ex","bt 32","--args","php","-d","memory_limit=1G",str(service/"generated-php-transport.php"),str(module),"execute",'["psCompilerPhpServiceCandidate"]',str(request),str(base/"diagnostic-G2.candidate.json")]
began=time.monotonic();p=subprocess.Popen(command,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,start_new_session=True)
try:output=p.communicate(timeout=180)[0]
except subprocess.TimeoutExpired:
 os.killpg(p.pid,signal.SIGKILL);output=p.communicate()[0]
out=pathlib.Path("diagnostics/php-packed-gdb");out.mkdir(parents=True,exist_ok=True)
(out/"gdb.txt").write_text(output)
receipt={"schema":"psc1-php-packed-G2-gdb/1","qualified":False,"sourceSha256":digest(module),"requestSha256":digest(request),"status":p.returncode,"elapsedSeconds":time.monotonic()-began,"memoryLimit":"1G","stackLimit":"unchanged","compiler":"exact archived admitted G1; no source instrumentation or native compiler","scope":"diagnostic debugger replay; no admission or fixed-point qualification"}
(out/"receipt.json").write_text(json.dumps(receipt,indent=2)+"\n")
print("PSC1_PHP_PACKED_G2_GDB: "+json.dumps(receipt),flush=True)
print(output[-50000:],flush=True)
