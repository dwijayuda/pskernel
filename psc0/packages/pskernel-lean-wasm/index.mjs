import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {readFileSync, mkdtempSync, writeFileSync, openSync, closeSync, rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

export const leanKernelProviderProtocol='pskernel-lean-wasm/2';
export const leanKernelProviderName='lean4-cpp';
export const leanKernelProviderVersion='4.35.0';
export const leanKernelProviderCommit='eb6cafb7290e8bd5f2937522d8d804f58f02bafc';
export const leanKernelProviderProfile='pscv0-v7.2';
const root=path.dirname(fileURLToPath(import.meta.url));
const launcher=path.join(root,'wasm/pskernel-lean.cjs');
const expectedFiles=['wasm/pskernel-lean.cjs','wasm/pskernel-lean.wasm'];

export class KernelNotReadyError extends Error {
  constructor(message='Lean 4.35.0 linear-memory kernel build is not qualified') {
    super('PSC0-LEAN-WASM-KERNEL-NOT-READY: '+message);
    this.name='KernelNotReadyError';
    this.code='PSC0-LEAN-WASM-KERNEL-NOT-READY';
  }
}
export function kernelStatus() {
  let manifest;
  try { manifest=readManifest(); } catch { return Object.freeze({checkerReady:false,assurance:'unavailable'}); }
  return Object.freeze({checkerReady:manifest.qualified===true,assurance:manifest.qualified?'native-wasm-parity-qualified':'unavailable'});
}
function sha256(file) {return createHash('sha256').update(readFileSync(file)).digest('hex');}
function readManifest(){
  let manifest;
  try {manifest=JSON.parse(readFileSync(path.join(root,'PREBUILT_WASM_MANIFEST.json'),'utf8'));}
  catch {throw new KernelNotReadyError('prebuilt manifest missing');}
  if(manifest.schemaVersion!==1 || manifest.packageName!=='@proofscript/pskernel-lean-wasm' ||
     manifest.leanVersion!==leanKernelProviderVersion ||
     manifest.leanCommit!==leanKernelProviderCommit ||
     manifest.profile!==leanKernelProviderProfile ||
     manifest.protocol!==leanKernelProviderProtocol ||
     manifest.provider!==leanKernelProviderName ||
     manifest.memoryModel!=='linear' ||
     manifest.qualified!==true){
    throw new KernelNotReadyError('prebuilt is not qualified for the exact pinned kernel');
  }
  for(const key of expectedFiles){
    const record=manifest.assets?.[key];
    if(record?.path!==key || !Number.isSafeInteger(record.bytes) || record.bytes<=0 ||
       typeof record.sha256!=='string') throw new KernelNotReadyError('invalid prebuilt manifest entry');
    try{
      const file=path.join(root,key);
      if(readFileSync(file).length!==record.bytes || sha256(file)!==record.sha256)
        throw new Error('size or digest mismatch');
    }catch{throw new KernelNotReadyError('missing or corrupt prebuilt '+key);}
  }
  return manifest;
}
function identity(result){
  if(result?.protocol!==leanKernelProviderProtocol ||
     result?.provider!==leanKernelProviderName ||
     result?.leanVersion!==leanKernelProviderVersion ||
     result?.leanCommit!==leanKernelProviderCommit ||
     result?.profile!==leanKernelProviderProfile)
    throw new KernelNotReadyError('provider identity mismatch');
  return result;
}
function options(input={}){
  const resolved={
    launcherPath:launcher,nodePath:process.execPath,maxBuffer:16*1024*1024,timeoutMs:60000,...input,
  };
  if(!Number.isSafeInteger(resolved.timeoutMs)||resolved.timeoutMs<=0 ||
     !Number.isSafeInteger(resolved.maxBuffer)||resolved.maxBuffer<=0)
    throw new TypeError('invalid resource limits');
  // No unverified external launcher overrides in the production API.
  if(resolved.launcherPath!==launcher) throw new KernelNotReadyError('unverified launcher override');
  return resolved;
}
function invoke(command,configuration,source){
  readManifest(); // Integrity is checked for every call, not only on construction.
  let directory,fd;
  try {
    if(source!==undefined){
      directory=mkdtempSync(path.join(tmpdir(),'psc0-kernel-wasm-'));
      const inputPath=path.join(directory,'admissions.json');
      writeFileSync(inputPath,source,{encoding:'utf8',mode:0o600});
      fd=openSync(inputPath,'r');
    }
    const result=spawnSync(configuration.nodePath,[configuration.launcherPath,command],{
      stdio:[fd??'ignore','pipe','pipe'],encoding:'utf8',
      timeout:configuration.timeoutMs,maxBuffer:configuration.maxBuffer,
      killSignal:'SIGKILL',windowsHide:true,
    });
    if(result.error||result.status!==0||result.signal)
      throw new KernelNotReadyError('provider execution failure: '+
        (result.error?.message??result.stderr?.slice(0,300)??String(result.status)));
    let response;
    try {response=JSON.parse(result.stdout.trim());}
    catch{throw new KernelNotReadyError('invalid provider JSON');}
    return identity(response);
  }finally{
    if(fd!==undefined) closeSync(fd);
    if(directory!==undefined) rmSync(directory,{recursive:true,force:true});
  }
}
export async function createKernel(input={}){
  const config=options(input);
  const health=invoke('--health',config);
  if(health.status!=='ok') throw new KernelNotReadyError('health check failed');
  return Object.freeze({metadata:Object.freeze(health),
    checkCanonicalAdmissions(source){return checkWithOptions(source,config);}});
}
function checkWithOptions(source,config){
  if(typeof source!=='string') throw new TypeError('canonical admissions must be a string');
  const response=invoke('--check',config,source);
  if(typeof response.accepted!=='boolean') throw new KernelNotReadyError('missing acceptance bit');
  if(response.accepted===false && typeof response.errorKind!=='string')
    throw new KernelNotReadyError('missing rejection category');
  return response;
}
export async function checkCanonicalAdmissions(source,input={}){
  return checkWithOptions(source,options(input));
}
