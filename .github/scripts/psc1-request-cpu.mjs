// Per-request CPU attribution on the exact qualified .7 compiler; no source optimization.
import fs from'node:fs';import path from'node:path';import os from'node:os';import assert from'node:assert/strict';import{spawnSync}from'node:child_process';
import{readQualifiedArtifact,sha256}from'../../psc1/scripts/kernel435-qualified-artifact.mjs';
const q=JSON.parse(fs.readFileSync('docs/PSC1_SEMANTIC_REUSE_QUALIFICATION_2026-10-29.json')),archive=await readQualifiedArtifact(q.qualification,'dist/cpu-qualified-input');
const tar=path.join(archive,'modular-toolchain/tarballs',q.package.tarball);assert.equal(sha256(fs.readFileSync(tar)),q.package.sha256);
const sources=[],seen=new Set(),active=new Set();
function visit(module){
 if(seen.has(module))return;assert.match(module,/^[A-Za-z_][A-Za-z0-9_.]*$/);assert.ok(!active.has(module));
 const relative=module.replaceAll('.','/')+'.lean',matches=['test/applications','stdlib'].map(root=>path.join(root,relative)).filter(fs.existsSync);assert.equal(matches.length,1,module);
 const text=fs.readFileSync(matches[0],'utf8');active.add(module);
 for(const m of text.matchAll(/^import\s+(.+)$/gm))for(const dependency of m[1].trim().split(/\s+/))visit(dependency);
 active.delete(module);seen.add(module);sources.push({module,kind:'lean',text});
}
visit('PracticalCli.Run');
const expected=JSON.parse(fs.readFileSync('docs/PSC1_APPLICATION_EXECUTION_CONTRACT.json')).cases.find(c=>c.id==='unicode-records');assert.ok(expected);

const directory=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-request-cpu-')),output=path.resolve('dist/request-cpu');fs.mkdirSync(output,{recursive:true});
const run=args=>{const r=spawnSync(process.execPath,args,{cwd:directory,encoding:'utf8',timeout:240000,maxBuffer:33554432});assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,r.stdout+r.stderr);return r.stdout;};
try{
 fs.writeFileSync(path.join(directory,'package.json'),'{"private":true,"type":"module"}');
 run([path.resolve(path.dirname(process.execPath),'../lib/node_modules/npm/bin/npm-cli.js'),'install','--offline','--ignore-scripts','--no-audit','--no-fund','--cache',path.join(directory,'cache'),'--registry','http://127.0.0.1:9',tar]);
 let driver=fs.readFileSync('../.github/scripts/psc1-persistent-profile-driver.mjs','utf8');
 driver=driver.replace("const outcomes=[];",`const inspector=await import('node:inspector'),session=new inspector.Session();session.connect();
 const post=(method,params={})=>new Promise((resolve,reject)=>session.post(method,params,(error,value)=>error?reject(error):resolve(value)));
 await post('Profiler.enable');await post('Profiler.setSamplingInterval',{interval:2000});
 const outcomes=[];`);
 const needle="text:source.text+(index===fixture.sources.length-1?";
 assert.ok(driver.includes(needle));
 driver=driver.replace(needle,"text:(index===fixture.sources.length-1&&i>0?source.text.replace('Result.ok success => success','Result.ok success => if success then true else false'):source.text)+(index===fixture.sources.length-1?");
 driver=driver.replace("const compileStarted=performance.now();","await post('Profiler.start');const compileStarted=performance.now();");
 driver=driver.replace("const compileWallMs=performance.now()-compileStarted;","const compileWallMs=performance.now()-compileStarted;const cpu=await post('Profiler.stop');fs.writeFileSync(path.join(process.argv[4],i+'.cpuprofile'),JSON.stringify(cpu.profile));");
 driver=driver.replace("mark('done');","session.disconnect();mark('done');");
 fs.writeFileSync(path.join(directory,'profile.mjs'),driver);
 const fixture=path.join(directory,'application.json');fs.writeFileSync(fixture,JSON.stringify({entryModule:'PracticalCli.Run',sources,expected}));
 const text=run([path.join(directory,'profile.mjs'),'warm-app',fixture,output]),line=text.split('\n').find(l=>l.startsWith('PSC1_PERSISTENT_PROFILE '));assert.ok(line,text);
 const result=JSON.parse(line.slice('PSC1_PERSISTENT_PROFILE '.length));assert.ok(result.outcomes.every(r=>r.admission==='accepted'&&r.application?.status==='passed'));
 assert.equal(result.outcomes[1].cache.semanticHit,false);assert.equal(result.outcomes[2].cache.semanticHit,true);
 const profiles=[];
 for(let i=0;i<3;i++){
  const data=JSON.parse(fs.readFileSync(path.join(output,i+'.cpuprofile'))),nodes=new Map(data.nodes.map(n=>[n.id,n])),parent=new Map(),self=new Map(),inclusive=new Map(),stacks=new Map();
  for(const n of data.nodes)for(const child of n.children??[])parent.set(child,n.id);
  for(let j=0;j<data.samples.length;j++){
   const id=data.samples[j],ms=(data.timeDeltas[j]??2000)/1000;self.set(id,(self.get(id)??0)+ms);
   let at=id,depth=0;const chain=[];
   while(at!==undefined&&depth++<256){inclusive.set(at,(inclusive.get(at)??0)+ms);const frame=nodes.get(at).callFrame;chain.push((frame.functionName||'<anonymous>')+'@'+frame.url.split('/').at(-1)+':'+(frame.lineNumber+1));at=parent.get(at);}
   if(/psTextInsert|psJson|__ps\$run/.test(nodes.get(id).callFrame.functionName)){const key=chain.slice(0,12).reverse().join(' > ');stacks.set(key,(stacks.get(key)??0)+ms);}
  }
  const rows=[...nodes].map(([id,n])=>({function:n.callFrame.functionName,file:n.callFrame.url.split('/').slice(-2).join('/'),line:n.callFrame.lineNumber+1,selfMs:self.get(id)??0,inclusiveMs:inclusive.get(id)??0}));
  const summary={request:i,kind:['first-request','semantic-body-edit','comment-after-body-edit'][i],topSelf:rows.sort((a,b)=>b.selfMs-a.selfMs).slice(0,24),topCompiler:rows.filter(r=>r.file.includes('Ps.')||/^ps/.test(r.function)).sort((a,b)=>b.inclusiveMs-a.inclusiveMs).slice(0,24),hotStacks:[...stacks].sort((a,b)=>b[1]-a[1]).slice(0,12).map(([stack,ms])=>({stack,ms}))};profiles.push(summary);
 }
 const report={schema:'psc1-request-cpu/1',commit:process.env.GITHUB_SHA,package:q.package,status:'passed',scope:'main-thread sampling2ms; first request, actual body edit, comment edit; exact qualified compiler; not timing qualification',result,profiles};fs.writeFileSync(path.join(output,'report.json'),JSON.stringify(report,null,2)+'\n');
 console.log('PSC1_REQUEST_CPU '+JSON.stringify({status:'passed',outcomes:result.outcomes,profiles}));
}finally{fs.rmSync(directory,{recursive:true,force:true});}
