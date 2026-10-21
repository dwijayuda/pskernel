// Dependency selection changes scheduling only. Full qualification retains every test.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {spawnSync} from 'node:child_process';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
export function selectPsc1Tests(paths,{full=false,uncertain=false}={}){
 const selected={static:true,focused:false,integration:false,release:false,benchmark:false};
 const reasons=[];
 const all=reason=>{selected.focused=true;selected.integration=true;selected.release=true;reasons.push(reason);};
 if(full||uncertain)all(full?'explicit-full-qualification':'missing-or-unreadable-diff');
 for(const file of paths){
  assert.equal(typeof file,'string');
  if(file.startsWith('.github/actions/') || /^\.github\/workflows\/psc1-.*\.ya?ml$/.test(file) || /^psc1\/(lean-toolchain|lakefile\.lean|lake-manifest\.json)$/.test(file)){
   all('build-or-ci-policy:'+file);continue;
  }
  if(!file.startsWith('psc1/'))continue; // PSKernel research is a separate workstream.
  if(/\.(md|txt)$/.test(file))continue;
  if(file.startsWith('psc1/docs/')){
   if(/^psc1\/docs\/PSC1_[A-Z0-9_]*(QUALIFICATION|FAILURE|RUNTIME|FIRST_ATTEMPT)_[0-9-]+\.json$/.test(file))continue;
   all('machine-readable-policy:'+file);continue;
  }
  if(file.startsWith('psc1/legacy/'))continue; // archived research; no current compiler import.
  if(file.includes('SpecializeQueueBenchmark')||file.includes('specialize-queue-comparison')){
   selected.benchmark=true;selected.focused=true;reasons.push('queue-benchmark:'+file);continue;
  }
  if(file.startsWith('psc1/test/')){selected.focused=true;reasons.push('authored-regression:'+file);continue;}
  if(/Backend(Python|Php|Wasm)|WasmComponent|wasm-|script-backend|runtime-conformance|seven-backend|npm-native/.test(file)){
   all('target-or-final-qualification:'+file);continue;
  }
  if(file.startsWith('psc1/packages/')||file.startsWith('psc1/host/')||file.startsWith('psc1/stdlib/')){
   selected.focused=true;selected.integration=true;reasons.push('compiler-source-or-library:'+file);continue;
  }
  if(file.startsWith('psc1/host-tools/')){all('host-authority-or-publication:'+file);continue;}
  if(/CONTRACT\.json$/.test(file)){all('finite-acceptance-contract:'+file);continue;}
  // These pure scheduling helpers are checked by static API/dependency regressions.
  // They do not change compiler, admission, IR, runtime or release assertions.
  if(['psc1/scripts/select-development-tests.mjs','psc1/scripts/development-selection-tests.mjs'].includes(file)){
   reasons.push('static-scheduling-regression:'+file);continue;
  }
  if(file.startsWith('psc1/scripts/')){
   selected.focused=true;
   // Most scripts enforce cross-target or authority boundaries. Keep unknown ones conservative.
   if(/compiler-m-conformance|language-backend-parity/.test(file))selected.release=true;
   else all('test-or-qualification-controller:'+file);
   reasons.push('test-controller:'+file);continue;
  }
  all('unknown-compiler-dependency:'+file);
 }
 return {...selected,paths:[...paths].sort(),reasons:[...new Set(reasons)]};
}
export function successfulBaseline(runs,{workflowPath,branch,prNumber,baseCommit,isAncestor}){
 for(const run of runs){
  if(run.path?.split('@')[0]!==workflowPath||run.head_branch!==branch||run.event!=='pull_request'||
      run.status!=='completed'||run.conclusion!=='success')continue;
  const pull=run.pull_requests?.find(p=>p.number===prNumber);
  // pull_requests.base is live API metadata; run-name captures the immutable dispatch base.
  if(!pull||run.display_title!=='PSC1 gates base '+baseCommit||!/^[a-f0-9]{40}$/.test(run.head_sha||''))continue;
  if(isAncestor(run.head_sha))return {commit:run.head_sha,runId:run.id};
 }
 return null;
}
if(process.argv[1]&&import.meta.url===pathToFileURL(path.resolve(process.argv[1])).href){
 const event=JSON.parse(fs.readFileSync(process.env.GITHUB_EVENT_PATH,'utf8'));
 const pull=event.pull_request;
 const sha=process.env.GITHUB_SHA;
 const full=event.inputs?.full===true||event.inputs?.full==='true';
 let paths=[],uncertain=false;
 // Carry all failed/cancelled update debt forward to the last successful gate.
 // Using event.before alone can silently lose a test dependency when its run is cancelled.
 const head=pull?.head?.sha;
 let baseline=null,baselineError=null;
 if(pull&&process.env.GITHUB_TOKEN){
  try{
   const response=await fetch(process.env.GITHUB_API_URL+'/repos/'+process.env.GITHUB_REPOSITORY+
    '/actions/runs?status=success&event=pull_request&per_page=100&branch='+encodeURIComponent(pull.head.ref),
    {headers:{Authorization:'Bearer '+process.env.GITHUB_TOKEN,Accept:'application/vnd.github+json'},redirect:'error'});
   assert.equal(response.status,200,'cannot read previous gate conclusions');
   const data=await response.json();
   baseline=successfulBaseline(data.workflow_runs,{
    workflowPath:process.env.GITHUB_WORKFLOW_REF?.slice((process.env.GITHUB_REPOSITORY+'/').length).split('@')[0],branch:pull.head.ref,prNumber:pull.number,baseCommit:pull.base.sha,
    isAncestor:commit=>spawnSync('git',['merge-base','--is-ancestor',commit,head]).status===0});
  }catch(error){uncertain=true;baselineError=String(error.message||error);}
 }
 const before=baseline?.commit;
 if(!baseline)uncertain=true;
 if(!before||!head||!/^[a-f0-9]{40}$/.test(before)||!/^[a-f0-9]{40}$/.test(head))uncertain=true;
 else {
  const diff=spawnSync('git',['diff','--name-only','--no-renames','-z',before,head],{encoding:'utf8'});
  if(diff.error||diff.status!==0)uncertain=true;
  else paths=diff.stdout.split('\0').filter(Boolean);
 }
 const result={schema:'psc1-ci-selection/1',testedCommit:sha,headCommit:head||sha,beforeCommit:before||null,eventBeforeCommit:event.before||null,baselineRunId:baseline?.runId||null,baselineError,
  ...selectPsc1Tests(paths,{full,uncertain})};
 fs.mkdirSync('psc1/dist/development',{recursive:true});
 fs.writeFileSync('psc1/dist/development/ci-selection.json',JSON.stringify(result,null,2)+'\n');
 for(const name of ['static','focused','integration','release','benchmark'])
  fs.appendFileSync(process.env.GITHUB_OUTPUT,name+'='+result[name]+'\n');
 fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY,
  'PSC1 incremental CI selection\n\n```json\n'+JSON.stringify(result,null,2)+'\n```\n');
 console.log(JSON.stringify(result));
}
