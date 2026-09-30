const providerSpecs=Object.freeze({
  lean434:Object.freeze({
    packageName:'@proofscript/pskernel-lean',
    localEntry:'../packages/pskernel-lean/index.mjs',
    overrideKey:'binaryPath',
  }),
  'lean434-wasm':Object.freeze({
    packageName:'@proofscript/pskernel-lean-wasm',
    localEntry:'../packages/pskernel-lean-wasm/index.mjs',
    overrideKey:'launcherPath',
  }),
});

export function kernelProviderSpec(kernel){
  const spec=providerSpecs[kernel];
  if(spec===undefined){
    throw new Error(`PSC2_KERNEL_PROVIDER: expected lean434 or lean434-wasm, got ${kernel}`);
  }
  return spec;
}

export function kernelProviderOptions(kernel,options={}){
  const spec=kernelProviderSpec(kernel);
  const override=options[spec.overrideKey];
  return override===undefined?{}:{[spec.overrideKey]:override};
}

export async function loadKernelProvider(kernel){
  const spec=kernelProviderSpec(kernel);
  try{
    return await import(spec.packageName);
  }catch(error){
    const missingInstalledPackage=
      error?.code==='ERR_MODULE_NOT_FOUND'&&
      String(error?.message??'').includes(spec.packageName);
    if(!missingInstalledPackage)throw error;
    return import(new URL(spec.localEntry,import.meta.url));
  }
}

export async function checkWithKernelProvider(kernel,source,options={}){
  const provider=options.providerModule??await loadKernelProvider(kernel);
  if(typeof provider?.checkCanonicalAdmissions!=='function'){
    throw new Error(`PSC2_KERNEL_PROVIDER_EXPORT_MISSING: ${kernel}: checkCanonicalAdmissions`);
  }
  return await provider.checkCanonicalAdmissions(
    source,
    kernelProviderOptions(kernel,options),
  );
}
