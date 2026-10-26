"""Authenticate unchanged retained harnesses; execute only inside GitHub Actions."""
from pathlib import Path
import os,json,subprocess,hashlib,sys

assert os.environ.get('GITHUB_ACTIONS')=='true','GitHub Actions execution only'
manifest=json.loads(Path(sys.argv[1]).read_text())
node=Path(sys.argv[2]).resolve();kernel=Path(sys.argv[3]).resolve();out=Path(sys.argv[4]).resolve()
out.mkdir(parents=True,exist_ok=True)
rows=[]
for spec in manifest['helpers']:
 path=spec['path'];data=Path(path).read_bytes()
 assert len(data)==spec['bytes'] and hashlib.sha256(data).hexdigest()==spec['sha256'],path
 assert data==subprocess.check_output(['git','show',manifest['source']+':'+path]),path
 target=out/Path(path).name;target.write_bytes(data)
 syntax=subprocess.run([str(node),'--check',str(target)],capture_output=True,text=True,timeout=30)
 assert syntax.returncode==0,(path,syntax.stderr)
 result=subprocess.run([str(node),'--max-old-space-size=2048',str(target),str(kernel)],env={'PATH':''},cwd=out,capture_output=True,text=True,timeout=300)
 text=result.stdout+result.stderr;log=out/(target.stem+'.log');log.write_text(text)
 print(text,end='',flush=True)
 assert result.returncode==0,(path,result.returncode)
 marker=spec['requiredFinalPassPrefix'];assert any(line.startswith(marker) for line in text.splitlines()),(path,marker)
 rows.append({'path':path,'sourceBytesAndDigestExact':True,'qualifiedBaselineBytesExact':True,'exitCode':0,'passMarker':marker,'logBytes':log.stat().st_size,'logSha256':hashlib.sha256(log.read_bytes()).hexdigest()})
assert len(rows)==21
record={'source':os.environ['GITHUB_SHA'],'baseline':manifest['source'],'all21QualifiedRetainedHarnessesUnchangedAndPassed':True,'kernel':{'bytes':kernel.stat().st_size,'sha256':hashlib.sha256(kernel.read_bytes()).hexdigest()},'harnesses':rows,'emptyPATH':True,'oldSpaceMiB':2048,'fullKernel':False,'performanceQualified':False}
(out/'receipt.json').write_text(json.dumps(record,indent=2)+'\n')
print('PSC1_MUTUAL_RETAINED_RUNTIME_ALL: PASS unchangedHarnesses=21')
