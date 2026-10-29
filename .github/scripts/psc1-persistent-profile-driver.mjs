// Diagnostic only: intercept reads/spawns without changing compiler decisions.
import fs from 'node:fs';
import cp from 'node:child_process';
import path from 'node:path';
import assert from 'node:assert/strict';
import {syncBuiltinESMExports} from 'node:module';
import {pathToFileURL} from 'node:url';
const mode=process.argv[2],rows=new Map(),children=[],phases=[];
let phase='module-import',phaseStart=performance.now();
const read=fs.readFileSync,spawn=cp.spawnSync;
fs.readFileSync=function(...args){
 const start=performance.now(),value=read.apply(this,args),bytes=typeof value==='string'?Buffer.byteLength(value):value.byteLength;
 const file=typeof args[0]==='number'?'fd:'+args[0]:String(args[0]),key=phase+'|'+file;
 let row=rows.get(key);if(!row){row={phase,file,reads:0,bytes:0,readMs:0,caller:new Error().stack.split('\n').slice(2,5).join(' | ')};rows.set(key,row);}
 row.reads++;row.bytes+=bytes;row.readMs+=performance.now()-start;return value;
};
cp.spawnSync=function(exe,args,options){const start=performance.now(),r=spawn.call(this,exe,args,options);children.push({phase,exe:path.basename(exe),args:args.slice(0,2),wallMs:performance.now()-start,status:r.status});return r;};
syncBuiltinESMExports();
function mark(next){phases.push({phase,wallMs:performance.now()-phaseStart});phase=next;phaseStart=performance.now();}
const started=performance.now(),api=await import('proofscript');
mark('prepare-warm');
if(mode.startsWith('warm')){
 const root=path.dirname(new URL(import.meta.resolve('proofscript/package.json')).pathname);
 const file=path.join(root,'node_modules/@proofscript/compiler/dist/host/host-tools/warm-compiler.mjs');
 const warm=await import(pathToFileURL(file));await warm.prepareWarmCompiler('js');if(warm.prepareWarmKernel)await warm.prepareWarmKernel();
}
const fixture=process.argv[3]?JSON.parse(fs.readFileSync(process.argv[3],'utf8')):undefined;
const outcomes=[];
for(let i=0;i<(mode.startsWith('warm')?3:1);i++){
 mark('request-'+i);
 const options=mode==='warm-app'
 ? {entryModule:fixture.entryModule,assurance:'ordinary-checked',outputAbi:'io-dispatcher',sources:fixture.sources.map((source,index)=>({...source,text:source.text+(index===fixture.sources.length-1?'\n-- profile edit '+i+'\n':'')}))}
 : {entryModule:'Main',sources:[{module:'Main',kind:'ps',text:'def answer : Nat := '+(42+i)+'\n'}]};
 const compileStarted=performance.now();
 const r=mode.includes('check')?api.check(options):api.build({...options,target:'js',out:path.resolve('profile-out-'+mode+'-'+i)});
 const compileWallMs=performance.now()-compileStarted;
 let application;
 if(mode==='warm-app'){
  const folder=path.resolve('application-'+i);fs.mkdirSync(folder);
  fs.writeFileSync(path.join(folder,'input.json'),'[{"text":"A","count":2},{"text":"\\uD83D\\uDE00","count":-4}]');
  const logFile=path.join(folder,'stdout.txt'),fd=fs.openSync(logFile,'w');
  const {createTypedIo}=await import('proofscript/io');
  const io=createTypedIo({abi:'psc1-node-linux-string-io/1',capabilities:['readUtf8','writeUtf8','writeLine'],required:['readUtf8','writeUtf8','writeLine'],root:folder,maxFileBytes:512,maxLineBytes:128,inputFd:0,outputFd:fd});
  let accepted;try{const guest=await import(pathToFileURL(r.runtimeArtifact));accepted=guest.run(JSON.stringify(['transform','input.json','output.json']),request=>io.execute(request));}
  finally{io.close();try{fs.closeSync(fd);}catch(error){if(error.code!=='EBADF')throw error;}}
  assert.equal(accepted,true);
  assert.equal(fs.readFileSync(path.join(folder,'output.json'),'utf8'),fixture.expected.output);
  assert.equal(fs.readFileSync(logFile,'utf8'),fixture.expected.stdout);
  application={case:'unicode-records',status:'passed',sources:fixture.sources.length};
 }
 outcomes.push({status:r.status,admission:r.logicalAdmission,compileWallMs,timings:r.timings,cache:r.cache??r.receipt?.cache,...(application?{application}:{})});
}
mark('done');
const values=[...rows.values()],total=values.reduce((a,r)=>({reads:a.reads+r.reads,bytes:a.bytes+r.bytes,readMs:a.readMs+r.readMs}),{reads:0,bytes:0,readMs:0});
console.log('PSC1_PERSISTENT_PROFILE '+JSON.stringify({mode,wallMs:performance.now()-started,total,phases,outcomes,children,byPhase:Object.fromEntries([...new Set(values.map(r=>r.phase))].map(p=>[p,values.filter(r=>r.phase===p).reduce((a,r)=>({reads:a.reads+r.reads,bytes:a.bytes+r.bytes,readMs:a.readMs+r.readMs}),{reads:0,bytes:0,readMs:0})])),maxRssKiB:process.resourceUsage().maxRSS,maxRssScope:'parent process including worker threads; subprocess memory excluded',largest:values.sort((a,b)=>b.bytes-a.bytes).slice(0,24)}));
