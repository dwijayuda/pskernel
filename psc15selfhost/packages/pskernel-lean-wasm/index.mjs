export async function createKernel(){
  throw new Error('@proofscript/pskernel-lean-wasm build artifact is not initialized');
}

export async function checkCanonicalAdmissions(source,options={}){
  const kernel=await createKernel(options);
  return kernel.checkCanonicalAdmissions(source);
}
