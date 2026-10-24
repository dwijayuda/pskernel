import hashlib,json,pathlib,sys,subprocess,time
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

request=base/"G2-self.request.json"
wire=request.read_bytes()
print("PSC1_PHP_G2_INPUT_SIZE: "+json.dumps({"bytes":len(wire),"unicodeScalars":len(wire.decode("utf-8"))}),flush=True)
needle="            [$fn, $arguments] = $task->current();"
assert data.decode("utf-8").count(needle)==1
sample="""            static $__psc_next_trace = 0;
            if (memory_get_usage(true) >= $__psc_next_trace) {
                $__psc_reflection = new \\ReflectionGenerator($task);
                fwrite(STDERR, 'PSC1_PHP_HEAP_SAMPLE: '.json_encode([
                    'heapBytes'=>memory_get_usage(true),
                    'pendingGenerators'=>count($pending),
                    'executingLine'=>$__psc_reflection->getExecutingLine()
                ],JSON_THROW_ON_ERROR)."\\n");
                unset($__psc_reflection);
                $__psc_next_trace = memory_get_usage(true) + 67108864;
            }
"""
instrumented=source.with_name("diagnostic-heap-module.php")
instrumented.write_text(data.decode("utf-8").replace(needle,sample+needle))
consumer=source.with_name("diagnostic-heap-run.php")
consumer.write_text("<?php $api=require $argv[1]; $wire=file_get_contents($argv[2]); $response=$api['psCompilerPhpServiceCandidate']($wire); if(strlen($response)>134217728)throw new RuntimeException('RESPONSE_LIMIT');")
began=time.monotonic()
p=subprocess.run(["php","-d","memory_limit=1G",str(consumer),str(instrumented),str(request)],capture_output=True,text=True,timeout=150)
trace={"schema":"psc1-php-G2-diagnostic-heap-trace/1","qualified":False,"status":p.returncode,"elapsedSeconds":time.monotonic()-began,"sourceSha256":hashlib.sha256(data).hexdigest(),"requestSha256":hashlib.sha256(wire).hexdigest(),"memoryLimit":"1G","mutation":"diagnostic copy adds only driver memory/pending/line samples; retained source untouched","stderr":p.stderr[-15000:]}
(dst/"php-g2-heap-trace.json").write_text(json.dumps(trace,indent=2)+"\n")
print("PSC1_PHP_G2_HEAP_TRACE: "+json.dumps(trace),flush=True)
