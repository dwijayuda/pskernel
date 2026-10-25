"""Read-only V8 profile of the authenticated original Prelude public operation."""
import hashlib
import importlib.util
import json
import os
import pathlib
import subprocess
ROOT=pathlib.Path(__file__).resolve().parents[1]
def load(name,path):
 spec=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
def digest(raw):return {'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()}
def main():
 assert os.environ.get('GITHUB_ACTIONS')=='true' and os.environ.get('RUNNER_OS')=='Linux'
 out=pathlib.Path(os.environ['RUNNER_TEMP'])/'prelude-ingress'
 ingress=load('authenticated_ingress',ROOT/'scripts/pskernel-prelude-ingress-ci.py')
 ingress.prepare(out,pathlib.Path(os.environ['RUNNER_TEMP'])/'lean-arena-round-2026-09-tests.tar.gz')
 profile=load('unchanged_profiler',ROOT/'scripts/pskernel-arena435-profile.py')
 detached=out/'detached';directory=out/'profile';directory.mkdir()
 os.environ['NODE_OPTIONS']=''
 result=profile.profile_case(pathlib.Path(os.environ['PSC1_PRELUDE_NODE']),detached/'pskernel-arena-replay.mjs',
  detached/'kernel.mjs',detached/'prelude.ndjson',directory)
 ingress.require(result['profile_collection_complete'],'Actual complete streaming tick profile')
 observed=result['observation'];progress=observed.get('last_progress',{})
 ingress.require(observed['verdict']=='timeout' and observed['timed_out'] and observed['returncode']==-9,
  'Actual unchanged bounded original Prelude outcome')
 ingress.require(progress.get('sourceSha256')==ingress.CASES['prelude'][1] and progress.get('stage')=='kernel-admission'
  and progress.get('coreInvoked') is True and progress.get('fuel')=='4096'
  and progress.get('records')==63723 and progress.get('admissionCommands')==1774
  and progress.get('arenaNodes')=='54535','Actual original input and admission boundary')
 paths=['psc1/scripts/pskernel-prelude-profile-ci.py','psc1/scripts/pskernel-arena435-profile.py',
  'psc1/scripts/pskernel-arena435-compare.py','.github/workflows/psc1-pskernel-prelude-profile.yml']
 snapshots=[]
 for path in paths:
  raw=(ROOT.parent/path).read_bytes();target=out/'sources'/path
  target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(raw);snapshots.append({'path':path,**digest(raw)})
 record={'schema':'psc1-prelude-original-profile-v1','workflowSourceSha':os.environ['GITHUB_SHA'],
  'runId':os.environ['GITHUB_RUN_ID'],'attempt':os.environ['GITHUB_RUN_ATTEMPT'],'kernelSourceSha':ingress.SOURCE,
  'kernel':digest((detached/'kernel.mjs').read_bytes()),'input':digest((detached/'prelude.ndjson').read_bytes()),
  'fuel':4096,'wallSeconds':60,'oldSpaceMiB':2048,'emptyPATH':True,'originalKernelUnmodified':True,
  'diagnosticOnly':True,'productionChanged':False,'performanceComparison':False,'nativeProfile':False,
  'sourceSnapshots':snapshots,'profile':result}
 ingress.write(out/'profile-report.json',record)
 print('PSC1_PRELUDE_ORIGINAL_PROFILE: PASS '+json.dumps(record,separators=(',',':')))
if __name__=='__main__':main()
