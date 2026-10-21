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
if(process.argv[1]&&import.meta.url===pathToFileURL(path.resolve(process.argv[1])).href){
 const event=JSON.parse(fs.readFileSync(process.env.GITHUB_EVENT_PATH,'utf8'));
 const pull=event.pull_request;
 const sha=process.env.GITHUB_SHA;
 const full=event.inputs?.full===true||event.inputs?.full==='true';
 let paths=[],uncertain=false;
 // synchronize uses only the new commit interval, never the cumulative PR path filter.
 const before=event.action==='synchronize'?event.before:pull?.base?.sha;
 const head=pull?.head?.sha;
 if(!before||!head||!/^[a-f0-9]{40}$/.test(before)||!/^[a-f0-9]{40}$/.test(head))uncertain=true;
 else {
  const diff=spawnSync('git',['diff','--name-only','--no-renames','-z',before,head],{encoding:'utf8'});
  if(diff.error||diff.status!==0)uncertain=true;
  else paths=diff.stdout.split('\0').filter(Boolean);
 }
 const result={schema:'psc1-ci-selection/1',testedCommit:sha,headCommit:head||sha,beforeCommit:before||null,
  ...selectPsc1Tests(paths,{full,uncertain})};
 fs.mkdirSync('psc1/dist/development',{recursive:true});
 fs.writeFileSync('psc1/dist/development/ci-selection.json',JSON.stringify(result,null,2)+'\n');
 for(const name of ['static','focused','integration','release','benchmark'])
  fs.appendFileSync(process.env.GITHUB_OUTPUT,name+'='+result[name]+'\n');
 fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY,
  'PSC1 incremental CI selection\n\n```json\n'+JSON.stringify(result,null,2)+'\n```\n');
 console.log(JSON.stringify(result));
}
