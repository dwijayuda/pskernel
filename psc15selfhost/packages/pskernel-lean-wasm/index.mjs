import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {verifyWasmPrebuiltManifest} from './host/prebuilt.mjs';

export const leanKernelProviderProtocol='pskernel-lean/1';
export const leanKernelProviderName='lean4-cpp';
export const leanKernelProviderVersion='4.34.0';
export const leanKernelProviderCommit='293d5d0c0c3f3dded4688b3ccd6a33939ac5102b';

const bundledLauncherPath=fileURLToPath(
  new URL('./wasm/pskernel-lean.cjs',import.meta.url),
);

function providerOptions(options={}){
  const hasLauncherOverride=Object.prototype.hasOwnProperty.call(options,'launcherPath');
  const {
    launcherPath=bundledLauncherPath,
    nodePath=process.execPath,
    maxBuffer=16*1024*1024,
  }=options;
  return {
    launcherPath,
    nodePath,
    maxBuffer,
    verifyBundledPrebuilt:!hasLauncherOverride,
  };
}

function runProviderCommand(command,options,input){
  if(options.verifyBundledPrebuilt){
    verifyWasmPrebuiltManifest();
  }

  const run=spawnSync(options.nodePath,[options.launcherPath,command],{
    input,
    encoding:'utf8',
    maxBuffer:options.maxBuffer,
    windowsHide:true,
  });

  if(run.error){
    throw new Error(
      `failed to start Lean WASM kernel provider: ${run.error.message}`,
      {cause:run.error},
    );
  }
  if(run.status!==0){
    const stderr=(run.stderr??'').trim();
    throw new Error(
      `Lean WASM kernel provider exited ${String(run.status)}`+
      `${stderr?`: ${stderr}`:''}`,
    );
  }

  const output=(run.stdout??'').trim();
  try{
    return JSON.parse(output);
  }catch(cause){
    throw new Error(
      `Lean WASM kernel provider returned invalid JSON: ${output.slice(0,500)}`,
      {cause},
    );
  }
}

function verifyProviderIdentity(result){
  if(result?.protocol!==leanKernelProviderProtocol){
    throw new Error(
      `Lean WASM kernel provider protocol mismatch: ${String(result?.protocol)}`,
    );
  }
  if(result?.provider!==leanKernelProviderName){
    throw new Error(
      `Lean WASM kernel provider identity mismatch: ${String(result?.provider)}`,
    );
  }
  if(result?.leanVersion!==leanKernelProviderVersion){
    throw new Error(
      `Lean WASM kernel provider version mismatch: ${String(result?.leanVersion)}`,
    );
  }
  if(result?.leanCommit!==leanKernelProviderCommit){
    throw new Error(
      `Lean WASM kernel provider commit mismatch: ${String(result?.leanCommit)}`,
    );
  }
  return result;
}

async function checkWithOptions(source,options){
  if(typeof source!=='string'){
    throw new TypeError('Lean WASM kernel provider input must be a string');
  }

  const result=verifyProviderIdentity(
    runProviderCommand('--check',options,source),
  );
  if(typeof result?.accepted!=='boolean'){
    throw new Error(
      'Lean WASM kernel provider result is missing boolean accepted',
    );
  }
  return result;
}

export async function createKernel(options={}){
  const resolved=providerOptions(options);
  const metadata=verifyProviderIdentity(
    runProviderCommand('--health',resolved),
  );
  if(metadata?.status!=='ok'){
    throw new Error(
      `Lean WASM kernel provider health mismatch: ${String(metadata?.status)}`,
    );
  }

  return Object.freeze({
    metadata:Object.freeze({...metadata}),
    checkCanonicalAdmissions(source){
      return checkWithOptions(source,resolved);
    },
  });
}

export async function checkCanonicalAdmissions(source,options={}){
  return checkWithOptions(source,providerOptions(options));
}
