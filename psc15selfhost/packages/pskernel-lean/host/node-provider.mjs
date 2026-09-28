import {spawnSync} from 'node:child_process';
import {join} from 'node:path';
import {fileURLToPath} from 'node:url';

export const leanKernelProviderProtocol='pskernel-lean/1';
export const leanKernelProviderName='lean4-cpp';
export const leanKernelProviderVersion='4.34.0';

const workspaceRoot=fileURLToPath(new URL('../../../',import.meta.url));

export function defaultLeanKernelProviderBinary({
  platform=process.platform,
  env=process.env,
}={}){
  if(env.PSC_LEAN_KERNEL_PROVIDER_BIN){
    return env.PSC_LEAN_KERNEL_PROVIDER_BIN;
  }
  const executable=platform==='win32'
    ? 'psc2_lean_kernel_provider.exe'
    : 'psc2_lean_kernel_provider';
  return join(workspaceRoot,'.lake','build','bin',executable);
}

export function checkCanonicalAdmissions(
  source,
  {
    binaryPath=defaultLeanKernelProviderBinary(),
    maxBuffer=16*1024*1024,
  }={},
){
  if(typeof source!=='string'){
    throw new TypeError('Lean kernel provider input must be a string');
  }

  const run=spawnSync(binaryPath,['--check'],{
    input:source,
    encoding:'utf8',
    maxBuffer,
    windowsHide:true,
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
  if(typeof result?.accepted!=='boolean'){
    throw new Error('Lean kernel provider result is missing boolean accepted');
  }

  return result;
}
