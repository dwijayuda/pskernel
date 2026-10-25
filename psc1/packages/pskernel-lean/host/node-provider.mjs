import {spawnSync} from 'node:child_process';
import {resolveLeanKernelProviderBinary,verifyLeanKernelPrebuiltBinary} from './prebuilt.mjs';

export const leanKernelProviderProtocol='pskernel-lean/1';
export const leanKernelProviderName='lean4-cpp';
export const leanKernelProviderVersion='4.35.0';
export const leanKernelProviderCommit='eb6cafb7290e8bd5f2937522d8d804f58f02bafc';
export const leanKernelProviderProfile='lean4.35-core';

function command(command,input,options={}){
 const {binaryPath:explicitBinaryPath,maxBuffer=16*1024*1024,timeoutMs=60000,...resolverOptions}=options;
 if(!Number.isSafeInteger(timeoutMs)||timeoutMs<=0)throw new TypeError('timeoutMs must be a positive integer');
 if(!Number.isSafeInteger(maxBuffer)||maxBuffer<=0)throw new TypeError('maxBuffer must be a positive integer');
 const resolved=explicitBinaryPath?{binaryPath:explicitBinaryPath,source:'explicit'}:resolveLeanKernelProviderBinary(resolverOptions);
 if(resolved.source==='bundled')verifyLeanKernelPrebuiltBinary({binaryPath:resolved.binaryPath,target:resolved.target,manifest:resolved.manifest,packageRoot:resolverOptions.packageRoot});
 const run=spawnSync(resolved.binaryPath,[command],{input,encoding:'utf8',maxBuffer,env:resolverOptions.env??process.env,windowsHide:true,timeout:timeoutMs,killSignal:'SIGKILL'});
 if(resolved.source==='bundled')verifyLeanKernelPrebuiltBinary({binaryPath:resolved.binaryPath,target:resolved.target,manifest:resolved.manifest,packageRoot:resolverOptions.packageRoot});
 if(run.error)throw new Error('failed to start Lean kernel provider: '+run.error.message,{cause:run.error});
 if(run.status!==0)throw new Error('Lean kernel provider exited '+run.status+': '+(run.stderr||'').trim());
 let result;try{result=JSON.parse((run.stdout||'').trim());}catch(cause){throw new Error('Lean kernel provider returned invalid JSON',{cause});}
 for(const [key,value]of Object.entries({protocol:leanKernelProviderProtocol,provider:leanKernelProviderName,leanVersion:leanKernelProviderVersion,leanCommit:leanKernelProviderCommit,profile:leanKernelProviderProfile})){
  if(result?.[key]!==value)throw new Error('Lean kernel provider '+key+' mismatch: '+String(result?.[key]));
 }
 if(command==='--health'){if(result.status!=='ok')throw new Error('Lean kernel provider health mismatch');}
 else if(typeof result.accepted!=='boolean')throw new Error('Lean kernel provider result is missing boolean accepted');
 return result;
}
export function defaultLeanKernelProviderBinary(options={}){return resolveLeanKernelProviderBinary(options).binaryPath;}
export function checkCanonicalAdmissions(source,options={}){if(typeof source!=='string')throw new TypeError('Lean kernel provider input must be a string');return command('--check',source,options);}
export async function createKernel(options={}){
 const metadata=command('--health',undefined,options);
 return Object.freeze({metadata:Object.freeze({...metadata}),async checkCanonicalAdmissions(source){return checkCanonicalAdmissions(source,options);}});
}
