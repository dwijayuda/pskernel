import hashlib,json,os,pathlib,re,signal,subprocess,sys,time
mode=sys.argv[1];assert mode in ("sample","slice")
reports=list(pathlib.Path("baseline").rglob("qualification.json"));assert len(reports)==1
report=json.loads(reports[0].read_text());base=reports[0].parent
assert report["testedCommit"]=="75f04cfdcafc1fbeea08f66f595f40ff6b777d04"
assert report["target"]=="php" and [g["generation"] for g in report["generations"]]==[1]
service=base/"G1-service";module=service/"module.php";request=base/"G2-self.request.json"
digest=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
assert digest(module)==report["generations"][0]["sourceSha256"]
event=next(e for e in report["events"] if e.get("id")=="G2-self")
assert digest(request)==event["requestSha256"]
out=pathlib.Path("diagnostics/php-node-"+mode);out.mkdir(parents=True,exist_ok=True)
source=module.read_text();target=module
if mode=="sample":
 needle="            [$fn, $arguments] = $task->current();"
 assert source.count(needle)==1
 init="$pending = [$root];"
 assert source.count(init)==1
 source=source.replace(init,init+"""
        $__psc_ticks = 0;
        $__psc_begin = hrtime(true);
        $__psc_next = 0;
        $__psc_rows = [];
""")
 injection="""            if (((++$__psc_ticks) & 4095) === 0) {
                $__psc_now = hrtime(true);
                $__psc_reflection = new \\ReflectionGenerator($task);
                $__psc_line = $__psc_reflection->getFunction()->getStartLine();
                $__psc_rows[$__psc_line] = ($__psc_rows[$__psc_line] ?? 0) + 1;
                unset($__psc_reflection);
                if ($__psc_now >= $__psc_next) {
                    file_put_contents(getenv('PSC1_PHP_SAMPLE_FILE'), json_encode([
                        'elapsedSeconds'=>($__psc_now - $__psc_begin)/1000000000,
                        'ticks'=>$__psc_ticks, 'pendingGenerators'=>count($pending),
                        'heapBytes'=>memory_get_usage(true), 'sampledGeneratorStarts'=>$__psc_rows
                    ],JSON_THROW_ON_ERROR));
                    $__psc_next = $__psc_now + 10000000000;
                }
                if ($__psc_now - $__psc_begin >= 120000000000) {
                    throw new \\RuntimeException('PSC1_DIAGNOSTIC_120S_BUDGET');
                }
            }
"""
 source=source.replace(needle,injection+needle)
 target=module.with_name("diagnostic-sampled-module.php");target.write_text(source)
 runner=module.with_name("diagnostic-sample-run.php")
 runner.write_text("<?php $api=require $argv[1]; try{$result=$api['psCompilerPhpServiceCandidate'](file_get_contents($argv[2])); echo json_encode(['status'=>'finished','responseBytes'=>strlen($result)]);}catch(RuntimeException $e){if($e->getMessage()!=='PSC1_DIAGNOSTIC_120S_BUDGET')throw $e;echo json_encode(['status'=>'diagnostic-120s-budget-ended']);}")
 args=[str(runner),str(target),str(request)]
else:
 runner=module.with_name("diagnostic-runtime-slice.php")
 runner.write_text("""<?php
$api=require $argv[1];
$wrapped=(new ReflectionFunction($api['psCompilerPhpServiceCandidate']))->getStaticVariables();
$implementation=$wrapped['implementation'];
$helpers=(new ReflectionFunction($implementation))->getStaticVariables();
$slice=$helpers['__ps_stringExtract'];
$source=file_get_contents($argv[1]);
echo "PSC1_PHP_COMPILER_SLICE_BEGIN: ".json_encode(['sourceBytes'=>strlen($source),'start'=>0,'stop'=>32])."\\n";
$result=$slice($source,gmp_init(0),gmp_init(32));
if($result!==substr($source,0,32))throw new RuntimeException('RUNTIME_SLICE_MISMATCH');
echo "PSC1_PHP_COMPILER_SLICE_RESULT: ".json_encode(['passed'=>true,'bytes'=>strlen($result)])."\\n";
""")
 args=[str(runner),str(module)]
env=dict(os.environ);env["PSC1_PHP_SAMPLE_FILE"]=str(out/"samples.json")
command=["/usr/bin/time","-v","php","-d","memory_limit=1G",*args]
began=time.monotonic();p=subprocess.Popen(command,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True,start_new_session=True,env=env)
try:stdout,stderr=p.communicate(timeout=150)
except subprocess.TimeoutExpired:
 os.killpg(p.pid,signal.SIGKILL);stdout,stderr=p.communicate()
receipt={"schema":"psc1-php-node-actual-workload-diagnostic/1","mode":mode,"qualified":False,"status":p.returncode,"elapsedSeconds":time.monotonic()-began,"sourceSha256":digest(module),"requestSha256":digest(request),"sourceBytes":module.stat().st_size,"memoryLimit":"1G","stackLimit":"unchanged","scope":"sampled generated G1/G2 phase or exact compiler-source String.extract runtime probe; no native compiler/admission/fixed-point qualification","stdout":stdout[-3000:],"stderr":stderr[-8000:]}
samples=out/"samples.json"
if samples.exists():
 data=json.loads(samples.read_text())
 markers=[(i+1,line.strip()) for i,line in enumerate(module.read_text().splitlines()) if re.match(r"^\\s*// declaration ",line)]
 def owner(position):
  previous=[name for line,name in markers if line<=position]
  return previous[-1] if previous else "runtime"
 data["sampledOwners"]=sorted([{"startLine":int(line),"owner":owner(int(line)),"samples":count} for line,count in data["sampledGeneratorStarts"].items()],key=lambda x:-x["samples"])[:40]
 data["measurement"]="yield-boundary generator phase samples, not a CPU attribution"
 receipt["samples"]=data
(out/"receipt.json").write_text(json.dumps(receipt,indent=2)+"\n")
print("PSC1_PHP_NODE_DIAGNOSTIC: "+json.dumps(receipt),flush=True)
