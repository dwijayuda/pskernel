// Explicit generated execution path; the existing native CLI remains available.
import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';
import {createGeneratedJsCompilerSession} from '../host-tools/generated-compiler-session.mjs';
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const decode=bytes=>new TextDecoder('utf-8',{fatal:true,ignoreBOM:true}).decode(bytes);
const fail=code=>{throw Error('PSC1_GENERATED_CLI_'+code);};
export async function generatedMain(args,root){
 const meta=JSON.parse(fs.readFileSync(path.join(root,'SELFHOST_DISTRIBUTION.json'),'utf8'));
 if(meta.schema!=='psc1-installed-generated-engines/1')fail('DISTRIBUTION');
 const engines=Object.keys(meta.engines);
 if(args.length===1&&args[0]==='--identity'){console.log(JSON.stringify(meta));return;}
 if(args[0]!=='build')fail('USAGE: psc generated build Main.ps --engine ts --out dist/generated [--project sources.json]');
 const options={};let file;
 for(let i=1;i<args.length;i++){
  const key=args[i];
  if(key.startsWith('--')){if(!['--engine','--out','--project','--assurance','--target','--kernel'].includes(key)||options[key]!==undefined||!args[i+1]||args[i+1].startsWith('--'))fail('ARGUMENT');options[key]=args[++i];}
  else if(file)fail('ARGUMENT');else file=key;
 }
 if(!engines.includes(options['--engine'])||!options['--out']||((!!file)===(!!options['--project'])))fail('ARGUMENT');
 if(options['--target']&&options['--target']!=='js')fail('TARGET: generated package integration currently qualifies JS publication; use psc build for other native targets');
 const kernel=options['--kernel']||meta.defaultKernel||'native';if(!['wasm','native','both'].includes(kernel))fail('KERNEL');
 const engine=meta.engines[options['--engine']];
 const inside=relative=>{if(typeof relative!=='string'||path.isAbsolute(relative)||relative.split(/[\\/]/).some(x=>!x||x==='..'||x==='.' ))fail('PATH');return path.join(root,relative);};
 const pin=row=>{const p=inside(row.path),stat=fs.lstatSync(p);if(!stat.isFile()||stat.isSymbolicLink()||sha(fs.readFileSync(p))!==row.sha256)fail('IDENTITY_CHANGED');return {path:p,sha256:row.sha256};};
 const service=pin(engine.adapter),deps=[...engine.dependencies,...meta.nativeLibraries,...(meta.hostDependencies||[])].map(pin);
 let checker,checkerScript;
 const additionalCheckers=[];
 if(kernel==='native'){
  checker=pin(meta.checker);deps.push(...(meta.kernelCheckers?.native?.dependencies||[]).map(pin));
 }else{
  const descriptor=meta.kernelCheckers?.wasm;if(!descriptor)fail('WASM_KERNEL_UNAVAILABLE');
  checkerScript=pin(descriptor.script);checker={path:process.execPath,sha256:sha(fs.readFileSync(process.execPath))};deps.push(...descriptor.dependencies.map(pin));
 }
 if(kernel==='both'){
  const descriptor=meta.additionalCheckers?.native;if(!descriptor)fail('NATIVE_KERNEL_UNAVAILABLE');
  const script=pin(descriptor.script);deps.push(...descriptor.dependencies.map(pin));
  additionalCheckers.push({name:'native',scriptFile:script.path,scriptSha256:script.sha256});
 }
 const runner=pin(meta.runner);const sessionCode=pin(meta.session);
 // The session is loaded from this immutable installed package; verify its pin.
 if(sessionCode.path!==path.join(root,'host-tools/generated-compiler-session.mjs'))fail('SESSION');
 let project;
 if(options['--project']){const b=fs.readFileSync(path.resolve(options['--project']));if(b.length>128*1024*1024)fail('INPUT_LIMIT');project=JSON.parse(decode(b));}
 else{const p=path.resolve(file),kind=path.extname(p).slice(1),entryModule=path.basename(p,path.extname(p));
  if(!['lean','ps'].includes(kind)||!/^[A-Za-z_][A-Za-z_0-9]*$/.test(entryModule))fail('SOURCE');
  const b=fs.readFileSync(p);if(b.length>128*1024*1024)fail('INPUT_LIMIT');
  project={entryModule,sources:[{module:entryModule,kind,text:decode(b)}]};
 }
 const assurance=options['--assurance']||project.assurance||'checked';
 process.env.LD_LIBRARY_PATH=[path.join(root,'native/lib'),process.env.LD_LIBRARY_PATH].filter(Boolean).join(path.delimiter);
 const session=createGeneratedJsCompilerSession({requestId:'package-'+crypto.randomUUID(),
  sources:project.sources,entryModule:project.entryModule,assurance,
  serviceFile:service.path,serviceSha256:service.sha256,runnerFile:runner.path,runnerSha256:runner.sha256,
  checkerExecutable:checker.path,checkerSha256:checker.sha256,...(checkerScript?{checkerScriptFile:checkerScript.path,checkerScriptSha256:checkerScript.sha256}:{}),publicationRoot:path.resolve(options['--out']),
  serviceDependencies:[...deps,sessionCode],additionalCheckers});
 const result=session.execute(),published=session.publish();
 console.log(JSON.stringify({status:'accepted',engine:options['--engine'],engineSourceClosureDigest:engine.sourceClosureDigest,
  engineQualification:engine.qualification,compilerExecutionMs:session.events.find(e=>e.role==='generated-compiler').elapsedMs,target:'js',artifact:published.target,manifestSha256:published.manifestSha256,
  sourceClosureDigest:result.sourceClosureDigest,logicalAdmission:result.logicalAdmission,checkerCommit:meta.checkerCommit,
  kernelProviders:kernel==='both'?['wasm','native']:[kernel],...(result.additionalAdmissions?{additionalAdmissions:result.additionalAdmissions}:{}),
  performanceQualification:engine.performanceQualification,behaviorallyVerified:false,formalPreservation:'not-provided'}));
}
