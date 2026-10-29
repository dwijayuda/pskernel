// Diagnostic only: intercept reads/spawns without changing compiler decisions.
import fs from 'node:fs';
import cp from 'node:child_process';
import path from 'node:path';
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
 const warm=await import(pathToFileURL(file));await warm.prepareWarmCompiler('js');
}
const outcomes=[];
for(let i=0;i<(mode.startsWith('warm')?3:1);i++){
 mark('request-'+i);
 const options={entryModule:'Main',sources:[{module:'Main',kind:'ps',text:'def answer : Nat := '+(42+i)+'\n'}]};
 const r=mode.includes('check')?api.check(options):api.build({...options,target:'js',out:path.resolve('profile-out-'+mode+'-'+i)});
 outcomes.push({status:r.status,admission:r.logicalAdmission,timings:r.timings,cache:r.cache});
}
mark('done');
const values=[...rows.values()],total=values.reduce((a,r)=>({reads:a.reads+r.reads,bytes:a.bytes+r.bytes,readMs:a.readMs+r.readMs}),{reads:0,bytes:0,readMs:0});
console.log('PSC1_PERSISTENT_PROFILE '+JSON.stringify({mode,wallMs:performance.now()-started,total,phases,outcomes,children,byPhase:Object.fromEntries([...new Set(values.map(r=>r.phase))].map(p=>[p,values.filter(r=>r.phase===p).reduce((a,r)=>({reads:a.reads+r.reads,bytes:a.bytes+r.bytes,readMs:a.readMs+r.readMs}),{reads:0,bytes:0,readMs:0})])),largest:values.sort((a,b)=>b.bytes-a.bytes).slice(0,24)}));
