// Independent provider orchestration only. Packages cannot grant compiler/host authority.
import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import {pathToFileURL} from 'node:url';
const expectedCommit='eb6cafb7290e8bd5f2937522d8d804f58f02bafc',sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const fail=message=>{throw new Error('PSC1_KERNEL_PACKAGE: '+message);};
export function loadKernelDistribution(root){
 const file=path.join(root,'KERNEL_DISTRIBUTION.json'),st=fs.lstatSync(file);if(!st.isFile()||st.isSymbolicLink()||st.size>1024*1024)fail('distribution file kind/size');
 const d=JSON.parse(fs.readFileSync(file,'utf8'));if(d.schema!=='psc1-installed-independent-kernels/1'||d.leanVersion!=='4.35.0'||d.leanCommit!==expectedCommit||d.canonicalAdmissionsVersion!==2||d.defaultProvider!=='wasm')fail('distribution identity');
 if(!Array.isArray(d.hostFiles)||d.hostFiles.length===0)fail('host pin set missing');
 if(!d.providers||Object.keys(d.providers).sort().join(',')!=='native,wasm')fail('closed provider set');
 return d;
}
function pinned(root,record){
 if(!record||typeof record.path!=='string'||!/^[A-Za-z0-9_@./-]+$/.test(record.path)||!/^[0-9a-f]{64}$/.test(record.sha256||''))fail('invalid pin');
 const file=path.resolve(root,record.path),rel=path.relative(root,file);if(!rel||rel.startsWith('..')||path.isAbsolute(rel))fail('pin escapes package');
 for(let p=file;p!==root;p=path.dirname(p)){if(fs.lstatSync(p).isSymbolicLink())fail('symlink in pinned path');}
 const st=fs.lstatSync(file);if(!st.isFile()||st.size<=0||st.size>128*1024*1024||st.size!==record.bytes)fail('pinned file kind/size');
 if(sha(fs.readFileSync(file))!==record.sha256)fail('pinned file checksum '+record.path);
 return file;
}
export async function createIndependentKernelToolchain({root,provider='wasm'}){
 root=path.resolve(root);if(!['native','wasm','both'].includes(provider))fail('unknown provider');
 const distribution=loadKernelDistribution(root),selected=provider==='both'?['native','wasm']:[provider],verify=()=>{
  const current=loadKernelDistribution(root);if(JSON.stringify(current)!==JSON.stringify(distribution))fail('distribution changed');
  for(const record of distribution.hostFiles||[])pinned(root,record);
  for(const key of selected){const p=distribution.providers[key];if(!p||p.version!=='4.35.0'||!Array.isArray(p.files)||p.files.length===0)fail('provider descriptor');for(const r of p.files)pinned(root,r);}
 };
 verify();const handles={};
 for(const key of selected){
  const p=distribution.providers[key];if(!p.files.some(r=>r.path===p.entry))fail('entry is not pinned');
  const module=await import(pathToFileURL(path.resolve(root,p.entry)).href),env={...process.env};delete env.PSC_LEAN_KERNEL_PROVIDER_BIN;
  const handle=await module.createKernel(key==='native'?{env,allowSourceCheckoutFallback:false,timeoutMs:120000,maxBuffer:32*1024*1024}:{timeoutMs:120000,maxBuffer:32*1024*1024});
  if(handle.metadata.leanVersion!=='4.35.0'||handle.metadata.leanCommit!==expectedCommit||handle.metadata.profile!=='lean4.35-core')fail('runtime identity');
  handles[key]=handle;
 }
 verify();
 return Object.freeze({metadata:Object.freeze({schema:'psc1-independent-kernel-toolchain/1',provider,leanVersion:'4.35.0',leanCommit:expectedCommit,canonicalAdmissionsVersion:2,wasmMemoryModel:'linear'}),
  async checkCanonicalAdmissions(source){
   if(typeof source!=='string'||Buffer.byteLength(source)>128*1024*1024)fail('request must be a bounded string');verify();
   const results={};for(const key of selected)results[key]=await handles[key].checkCanonicalAdmissions(source);verify();
   const accepted=selected.every(k=>results[k].accepted===true),agreement=selected.every(k=>results[k].accepted===results[selected[0]].accepted);
   return Object.freeze({schema:'psc1-independent-kernel-toolchain-result/1',provider,accepted,agreement,admissionsSha256:sha(source),leanVersion:'4.35.0',leanCommit:expectedCommit,results,scope:'independent canonical admission only; not compiler semantic preservation'});
  }
 });
}
