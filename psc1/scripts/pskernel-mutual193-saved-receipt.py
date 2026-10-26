"""Read/record the authentic completed193 result; never replays or executes a kernel."""
from pathlib import Path
import os,json,hashlib,zipfile,io,importlib.util
assert os.environ.get('GITHUB_ACTIONS')=='true' and os.environ.get('RUNNER_OS')=='Linux'
repo=Path(os.environ['GITHUB_WORKSPACE'])
spec=importlib.util.spec_from_file_location('download',repo/'psc1/scripts/pskernel-church-stage-ci.py')
C=importlib.util.module_from_spec(spec);spec.loader.exec_module(C)
source='97039e8d7b3554a770272418301d7f30532897ad';run=40248908829;artifact=12619303958
sha='6712fb97ddda6d99bd5f06f65ad003b5c479dc25047c8b82e783dfd6b27b1c55'
a=json.loads(C.github('/actions/artifacts/'+str(artifact)))
assert a['workflow_run']['head_sha']==source and a['workflow_run']['id']==run and not a['expired']
assert a['size_in_bytes']==13913110 and a['digest']=='sha256:'+sha
raw=C.github('/actions/artifacts/'+str(artifact)+'/zip');assert len(raw)==13913110 and hashlib.sha256(raw).hexdigest()==sha
z=zipfile.ZipFile(io.BytesIO(raw));assert z.testzip() is None and len(z.namelist())==len(set(z.namelist()))==589
prefix='_temp/arena435-independent/'
report=json.loads(z.read(prefix+'report.json'));origin=json.loads(z.read(prefix+'kernel-provenance.json'))
assert report['total']==len(report['tests'])==193 and report['excluded_cases']==[]
assert report['kernel_fuel']==4096 and report['host_timeout_seconds_per_case']==60 and report['node_heap_limit_mib']==2048 and report['host_workers']==2
assert report['runtime_path_empty'] and report['official_controls_valid'] and report['all_cases_recorded']
assert origin['kernelSourceSha']=='2708d07d5827b8aca72497a1ea3de989700b6996' and origin['nativeReports']==738 and origin['proofModules']==51
assert origin['kernel']['sha256']==report['kernel_module_sha256']=='9e81e1323aefacb71f3db71eb8698922e747160b051eff8ef82e1daa61679e9d'
assert origin['bothFullRoutesPass'] and origin['matchingIndependentNative738Pass']
assert report['actual_matched_cases']==174 and report['counts']['pskernel_timeout']==17 and report['counts']['agreement_with_unsafe_or_partial_contract_difference']==2
assert not report['arena_comparison_complete'] and not report['full_expression_v2_replacement_established']
completed=0
for case in report['tests']:
 assert case['adaptation']['body_bytes_identical'] and case['adaptation']['original_body_sha256']==case['adaptation']['adapted_body_sha256']
 observation=case['pskernel'];b=z.read(prefix+'case-logs/'+observation['stdout'])
 if observation['verdict']!='timeout':
  rows=[json.loads(line.removeprefix('PSC1_ARENA_REPLAY ')) for line in b.decode().splitlines() if line.startswith('PSC1_ARENA_REPLAY ')]
  assert len(rows)==1 and rows[0]['verdict']==observation['verdict'];completed+=1
 print('ARENA_SAVED_COMPLETE_CASE '+json.dumps(case,sort_keys=True))
assert completed==176
out=Path(os.environ['RUNNER_TEMP'])/'mutual193-saved-receipt';out.mkdir()
record={'collectionStatus':'pass','strictKernelStatus':'FAIL','source':source,'run':run,'artifact':artifact,'archiveSha256':sha,'kernelSource':origin['kernelSourceSha'],'productionTree':origin['productionTree'],'cases':193,'unchangedBodies':193,'completedEnvelopesRead':176,'strictMatches':174,'timeouts':17,'separateSafetyAgreements':2,'kernelFuel':4096,'hostTimeoutSeconds':60,'oldSpaceMiB':2048,'workers':2,'replayedCases':0,'postReplayRecorderCorrection':'Proof-module assertion changed narrowly to51;fuel assertion remains4096. Original comparison had actually runat4096.','originalStrictFailurePreserved':True,'fullKernel':False,'performanceQualified':False}
(out/'receipt.json').write_text(json.dumps(record,indent=2)+'\n');(out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
print('PSC1_MUTUAL193_SAVED_RECEIPT: PASS collectionOnly=true strictKernelStatus=FAIL cases=193 strictMatches=174 timeouts=17 safetyAgreements=2 replayedCases=0 fuel=4096')
