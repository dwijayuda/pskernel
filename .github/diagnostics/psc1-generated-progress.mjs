import fs from 'node:fs';
import crypto from 'node:crypto';
import path from 'node:path';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
const root='retained/generated-compiler/';
const receipt=JSON.parse(fs.readFileSync(root+'selfhost-failure-cpu-profile/receipt.json','utf8'));
const sha=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
assert.equal(receipt.testedCommit,'573bf48533cb196450a8d1df4f454de20c47b08f');
assert.equal(receipt.requestSha256,'e60717a16128dffcafc84499939aa58c5f58f22103be7a3233166cb81ff52f36');
assert.equal(process.version,'v22.23.3');
const original=fs.readFileSync(root+'G1.mjs'),input=fs.readFileSync(root+'selfhost-failure-cpu-profile/request.json');
assert.equal(sha(original),receipt.serviceSha256);assert.equal(sha(input),receipt.requestSha256);
const runner='psc1/scripts/generated-compiler-runner.mjs';
assert.equal(sha(fs.readFileSync(runner)),receipt.runnerSha256);
const wire=JSON.parse(input.toString('utf8'));
assert.equal(wire[0],'psc1-compiler-service/1');
const inventory=wire[6].map(([name,text],index)=>[sha(text),{name,index,bytes:Buffer.byteLength(text)}]);
const wanted=new Set(['psJsonParse','psCompilerParseSource','psCompilerPreparationStepParsedWithOrigins',
 'psElabDeclarationBatchWithOrigins','psCompilerPrepareOrdinary','psCompilerOrdinaryIr',
 'psFuseClosedWorkers','psJsLowerValidatedModuleWithTargetProfile','psJsPrintDeclarationsWith']);
const instrumented=[];
assert.ok(!original.toString('utf8').includes('__psc1DiagnosticTrace'));
const lines=original.toString('utf8').split('\n').map(line=>{
 const found=/^function\* __ps\$impl\$(\w+)\(([^)]*)\) \{(.*)\}$/.exec(line);
 if(!found||!wanted.has(found[1]))return line;
 instrumented.push(found[1]);
 return 'function* __ps$impl$'+found[1]+'('+found[2]+') { __psc1DiagnosticTrace('+JSON.stringify(found[1])+',['+found[2]+']);'+found[3]+'}';
});
assert.ok(instrumented.includes('psCompilerParseSource'));
assert.ok(instrumented.includes('psCompilerPreparationStepParsedWithOrigins'));
assert.ok(instrumented.includes('psElabDeclarationBatchWithOrigins'));
const header="import {createHash as __psc1DiagnosticHash} from 'node:crypto';\n"+
 "const __psc1DiagnosticStart=Date.now(),__psc1DiagnosticSources=new Map("+JSON.stringify(inventory)+");\n"+
 "let __psc1DiagnosticModule=null,__psc1DiagnosticCount=0;\n"+
 "function __psc1DiagnosticTrace(phase,args){"+
 "if(phase==='psCompilerParseSource'&&typeof args[1]==='string')__psc1DiagnosticModule=__psc1DiagnosticSources.get(__psc1DiagnosticHash('sha256').update(args[1]).digest('hex'))||null;"+
 "const declaration=phase==='psElabDeclarationBatchWithOrigins'?String(args[1]):null;"+
 "console.error('PSC1_DIAGNOSTIC_PROGRESS: '+JSON.stringify({count:++__psc1DiagnosticCount,elapsedMs:Date.now()-__psc1DiagnosticStart,phase,module:__psc1DiagnosticModule,declaration,rssKiB:Math.ceil(process.memoryUsage().rss/1024)}));}\n";
fs.mkdirSync('diagnostic-progress',{recursive:true});
const service=path.resolve('diagnostic-progress/instrumented-service.mjs'),request=path.resolve('diagnostic-progress/request.json');
fs.writeFileSync(service,header+lines.join('\n'));fs.writeFileSync(request,input);
const hash=sha(fs.readFileSync(service));
const syntax=spawnSync(process.execPath,['--check',service],{encoding:'utf8',timeout:30000,maxBuffer:32*1024*1024});
assert.equal(syntax.status,0,syntax.stderr);
const started=performance.now();
const run=spawnSync(process.execPath,[path.resolve(runner),service,hash,request,path.resolve('diagnostic-progress/not-adopted-response.json')],
 {encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024});
fs.writeFileSync('diagnostic-progress/stdout.txt',run.stdout||'');
fs.writeFileSync('diagnostic-progress/stderr.txt',run.stderr||'');
assert.equal(sha(fs.readFileSync(root+'G1.mjs')),receipt.serviceSha256);
assert.equal(sha(fs.readFileSync(root+'selfhost-failure-cpu-profile/request.json')),receipt.requestSha256);
assert.equal(sha(fs.readFileSync(service)),hash);assert.equal(sha(fs.readFileSync(request)),receipt.requestSha256);
const progress=(run.stderr||'').split('\n').filter(line=>line.startsWith('PSC1_DIAGNOSTIC_PROGRESS: ')).map(line=>JSON.parse(line.slice('PSC1_DIAGNOSTIC_PROGRESS: '.length)));
const report={schema:'psc1-instrumented-progress-diagnostic/1',qualificationRun:39864113546,originalServiceSha256:receipt.serviceSha256,
 requestSha256:receipt.requestSha256,instrumentedServiceSha256:hash,instrumentedFunctions:instrumented,
 elapsedMs:Math.round(performance.now()-started),timeoutMs:240000,status:run.status,signal:run.signal,error:run.error?.message||null,
 enteredSources:progress.filter(p=>p.phase==='psCompilerParseSource').map(p=>p.module),
 lastProgress:progress.slice(-30),nativeCompilerDelegation:false,admission:'not-run',publication:'not-run',qualification:false,
 scope:'Instrumented copy only. Function-entry counters do not prove completion; timing includes logging overhead. No response is adopted and original failed qualification stays failed.'};
fs.writeFileSync('diagnostic-progress/receipt.json',JSON.stringify(report,null,2)+'\n');
console.log('PSC1_PROGRESS_DIAGNOSTIC: '+JSON.stringify(report));
