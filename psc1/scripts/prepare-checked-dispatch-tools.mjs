// CI-only assembly: exact shared emitters, isolated target runtimes and pinned tools.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {spawnSync,spawn} from 'node:child_process';import {createHash} from 'node:crypto';
const version='0.1.0-psc1.7',out=path.resolve('dist/dispatch-tools');fs.mkdirSync(out,{recursive:true});
const sha=b=>createHash('sha256').update(b).digest('hex');
const run=(exe,args)=>{const r=spawnSync(exe,args,{encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024});assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,r.stdout+r.stderr);return r.stdout.trim();};
function copy(from,to){fs.mkdirSync(path.dirname(to),{recursive:true});fs.cpSync(fs.realpathSync(from),to,{recursive:true,dereference:true,filter:src=>!/(^|\/)(__pycache__|site-packages|test|tests)(\/|$)/.test(src)&&!src.endsWith('.pyc')});}
function inventory(root,prefix=''){return fs.readdirSync(path.join(root,prefix)).sort().flatMap(name=>{const p=prefix?prefix+'/'+name:name,file=path.join(root,p),st=fs.lstatSync(file);assert.ok(!st.isSymbolicLink());if(st.isDirectory())return inventory(root,p);const b=fs.readFileSync(file);return [{path:p,bytes:b.length,sha256:sha(b)}];});}
function libraries(binary,destination){
 const text=run('ldd',[binary]);assert.doesNotMatch(text,/not found/);
 for(const line of text.split('\n')){const file=line.match(/=>\s+(\/\S+)/)?.[1]||line.trim().match(/^(\/\S+)/)?.[1];if(file)copy(file,path.join(destination,path.basename(file)));}
}
async function auditSymbols(binary,target){
 const forbidden=/initialize_Ps_Compiler_Api|initialize_Ps_Elab_Term|initialize_PsKernelLean_|initialize_Ps_Host_DirectBackend/;
 const other=target==='python'?/initialize_Ps_BackendPhp/:/initialize_Ps_BackendPython/;
 await new Promise((resolve,reject)=>{
   const child=spawn('nm',['--defined-only','--extern-only','-j',binary],{stdio:['ignore','pipe','pipe']});
   let pending='',stderr='',failure=null,owned=0,count=0;
   const inspect=line=>{count++;if(line.includes('initialize_Ps_Backend'))owned++;if(forbidden.test(line)||other.test(line))failure='PSC1_PROVIDER_FORBIDDEN_SYMBOL';};
   const timer=setTimeout(()=>{failure='PSC1_PROVIDER_SYMBOL_AUDIT_DEADLINE';child.kill('SIGKILL');},240000);
   child.stdout.on('data',bytes=>{pending+=bytes.toString('utf8');let index;while((index=pending.indexOf('\n'))!==-1){inspect(pending.slice(0,index));pending=pending.slice(index+1);}if(pending.length>1048576){failure='PSC1_PROVIDER_SYMBOL_LINE_LIMIT';child.kill('SIGKILL');}});
   child.stderr.on('data',bytes=>{stderr=(stderr+bytes.toString('utf8')).slice(-8192);});
   child.once('error',error=>{failure=error.message;});
   child.once('close',status=>{clearTimeout(timer);if(pending)inspect(pending);if(status!==0||failure||!owned)reject(Error(failure||stderr||'PSC1_PROVIDER_SYMBOL_AUDIT_EMPTY'));else{console.log('PSC1_PROVIDER_SYMBOL_AUDIT '+JSON.stringify({target,count,owned,streamed:true,frontendCheckerPublisherAbsent:true}));resolve();}});
 });
}
const descriptors={};
for(const target of ['python','php','wasm-component']){
 const packageName=target==='wasm-component'?'@proofscript/wasm-component-tools-linux-x64':'@proofscript/backend-'+target;
 const stage=path.join(out,target);fs.rmSync(stage,{recursive:true,force:true});fs.mkdirSync(stage);
 const launcher=path.join(stage,'tool');run('cc',['-O2','-Wall','-Wextra','-Werror','scripts/optional-tool-launcher.c','-o',launcher]);fs.chmodSync(launcher,0o755);
 if(target==='wasm-component'){
   copy(process.env.PSC1_WASM_TOOLS,path.join(stage,'wasm-tools'));
   assert.match(run(process.env.PSC1_WASM_TOOLS,['--version']),/^wasm-tools 1\.254\.0/);
   libraries(process.env.PSC1_WASM_TOOLS,path.join(stage,'lib'));
 }else{
   const worker=path.resolve('.lake/build/bin/psc1_backend_'+target);copy(worker,path.join(stage,'worker'));libraries(worker,path.join(stage,'lib'));
   await auditSymbols(worker,target);
   run('strip',['--strip-debug',path.join(stage,'worker')]);
   const resources=target==='python'?['typed_io.py','generated-python-transport.py']:['typed-io.php','generated-php-transport.php'];
   for(const resource of resources)copy('host-tools/'+resource,path.join(stage,'resources',resource));
   if(target==='python'){
     const exe=process.env.PSC1_PYTHON_314;assert.ok(exe);assert.equal(run(exe,['--version']),'Python 3.14.8');
     const info=JSON.parse(run(exe,['-I','-S','-c','import json,sysconfig;print(json.dumps({k:sysconfig.get_config_var(k) for k in ["LIBDIR","LDLIBRARY"]}|{"stdlib":sysconfig.get_path("stdlib")}))']));
     copy(exe,path.join(stage,'runtime/bin/python3'));libraries(exe,path.join(stage,'runtime/lib'));
     copy(info.stdlib,path.join(stage,'runtime/lib/python3.14'));
     copy(path.join(info.LIBDIR,info.LDLIBRARY),path.join(stage,'runtime/lib',info.LDLIBRARY));
     copy('scripts/optional-provider-validate.py',path.join(stage,'validate.py'));
   }else{
     const exe=process.env.PSC1_PHP;assert.ok(exe);assert.equal(run(exe,['-r','echo PHP_VERSION;']),'8.5.11');
     copy(exe,path.join(stage,'runtime/bin/php'));libraries(exe,path.join(stage,'runtime/lib'));
     const gmp=run(exe,['-r','echo ini_get("extension_dir")."/gmp.so";']);copy(gmp,path.join(stage,'runtime/gmp.so'));libraries(gmp,path.join(stage,'runtime/lib'));
     copy('scripts/optional-provider-validate.php',path.join(stage,'validate.php'));
   }
 }
 fs.writeFileSync(path.join(stage,'index.mjs'),'export const target='+JSON.stringify(target)+';\n');
 fs.writeFileSync(path.join(stage,'package.json'),JSON.stringify({name:packageName,version,type:'module',private:true,os:['linux'],cpu:['x64'],main:'index.mjs',exports:{'.':'./index.mjs','./package.json':'./package.json'},peerDependencies:{proofscript:version},peerDependenciesMeta:{proofscript:{optional:true}},proofscript:{schema:'psc1-checked-dispatch-package/1',target,sourceCommit:process.env.GITHUB_SHA,authority:'candidate-only',compilerFrontend:false,admissionAuthority:false,publicationAuthority:false}},null,2)+'\n');
 descriptors[target]={package:packageName,version,entry:'tool',target,sourceCommit:process.env.GITHUB_SHA,files:inventory(stage),platform:'linux-x64',limits:{timeoutMs:240000,addressSpaceBytes:4294967296,stackBytes:8388608,responseBytes:33554432}};
}
fs.writeFileSync(path.join(out,'descriptors.json'),JSON.stringify(descriptors,null,2)+'\n');
console.log('PSC1_DISPATCH_TOOLS: '+JSON.stringify(Object.fromEntries(Object.entries(descriptors).map(([t,d])=>[t,{files:d.files.length,bytes:d.files.reduce((n,f)=>n+f.bytes,0)}]))));
