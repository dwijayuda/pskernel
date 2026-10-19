import {spawnSync} from 'node:child_process';
import {
  resolveLeanKernelProviderBinary,
  verifyLeanKernelPrebuiltBinary,
} from './prebuilt.mjs';

export const leanKernelProviderProtocol='pskernel-lean/1';
export const leanKernelProviderName='lean4-cpp';
export const leanKernelProviderVersion='4.34.0';
export const leanKernelProviderCommit='293d5d0c0c3f3dded4688b3ccd6a33939ac5102b';

export function defaultLeanKernelProviderBinary(options={}){
  return resolveLeanKernelProviderBinary(options).binaryPath;
}

export function checkCanonicalAdmissions(
  source,
  options={},
){
  if(typeof source!=='string'){
    throw new TypeError('Lean kernel provider input must be a string');
  }

  const {
    binaryPath:explicitBinaryPath,
    maxBuffer=16*1024*1024,
    timeoutMs=60000,
    ...resolverOptions
  }=options;
  if(!Number.isSafeInteger(timeoutMs)||timeoutMs<=0)throw new TypeError('timeoutMs must be a positive integer');
  const resolved=explicitBinaryPath
    ? {binaryPath:explicitBinaryPath,source:'explicit'}
    : resolveLeanKernelProviderBinary(resolverOptions);

  if(resolved.source==='bundled'){
    verifyLeanKernelPrebuiltBinary({
      binaryPath:resolved.binaryPath,
      target:resolved.target,
      manifest:resolved.manifest,
      packageRoot:resolverOptions.packageRoot,
    });
  }

  const run=spawnSync(resolved.binaryPath,['--check'],{
    input:source,
    encoding:'utf8',
    maxBuffer,
    windowsHide:true,
    timeout:timeoutMs,
    killSignal:'SIGKILL',
  });

  if(run.error){
    throw new Error(
      `failed to start Lean kernel provider: ${run.error.message}`,
      {cause:run.error},
    );
  }
  if(run.status!==0){
    const stderr=(run.stderr??'').trim();
    throw new Error(
      `Lean kernel provider exited ${run.status}${stderr?`: ${stderr}`:''}`,
    );
  }

  const output=(run.stdout??'').trim();
  let result;
  try{
    result=JSON.parse(output);
  }catch(cause){
    throw new Error(
      `Lean kernel provider returned invalid JSON: ${output.slice(0,500)}`,
      {cause},
    );
  }

  if(result?.protocol!==leanKernelProviderProtocol){
    throw new Error(
      `Lean kernel provider protocol mismatch: ${String(result?.protocol)}`,
    );
  }
  if(result?.provider!==leanKernelProviderName){
    throw new Error(
      `Lean kernel provider identity mismatch: ${String(result?.provider)}`,
    );
  }
  if(result?.leanVersion!==leanKernelProviderVersion){
    throw new Error(
      `Lean kernel provider version mismatch: ${String(result?.leanVersion)}`,
    );
  }
  if(result?.leanCommit!==leanKernelProviderCommit){
    throw new Error(
      `Lean kernel provider commit mismatch: ${String(result?.leanCommit)}`,
    );
  }
  if(result?.profile!=='lean4.34-core'){
    throw new Error('Lean kernel provider profile mismatch');
  }
  if(typeof result?.accepted!=='boolean'){
    throw new Error('Lean kernel provider result is missing boolean accepted');
  }

  return result;
}
