import { readFile } from "node:fs/promises";

const data=JSON.parse(await readFile(
  new URL("../profiles/assurance/INDEPENDENCE_VECTORS.json",import.meta.url),
  "utf8",
));
if(data.contract!=="psc-independence-vector/1") throw new Error("PSC_INDEPENDENCE_CONTRACT");
for(const selector of ["lean434-wasm","lean434","pskernel-core"]){
  const item=data.providers?.[selector];
  if(!item) throw new Error("PSC_INDEPENDENCE_PROVIDER: "+selector);
  for(const field of ["theoryOrigin","algorithmOrigin","sourceDerivation","implementationLanguage","compilerToolchain","runtime","memoryManager","parserOrDecoder","organization","proofFoundation"]){
    if(typeof item[field]!=="string"||item[field].length===0) throw new Error("PSC_INDEPENDENCE_FIELD: "+selector+":"+field);
  }
}
if(data.policy?.booleanIndependenceForbidden!==true) throw new Error("PSC_INDEPENDENCE_BOOLEAN_POLICY");
if(data.providers["lean434-wasm"].algorithmOrigin===data.providers["pskernel-core"].algorithmOrigin) throw new Error("PSC_INDEPENDENCE_ALGORITHM_DIVERSITY");
process.stdout.write("PSCV_INDEPENDENCE_VECTOR: PASS (shared and diverse axes explicit)\n");
