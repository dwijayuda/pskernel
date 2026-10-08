import { readFile } from "node:fs/promises";

const contract=JSON.parse(await readFile(
  new URL("../contracts/resource/COMPILATION_RESOURCE_V1.json",import.meta.url),
  "utf8",
));
if(contract.contract!=="psc-compilation-resource/1") throw new Error("PSC_RESOURCE_CONTRACT_ID");
for(const required of ["accepted","rejectedInvalid","declinedUnsupported","resourceExhausted","internalError","infrastructureUnavailable"]){
  if(!contract.outcomes.includes(required)) throw new Error("PSC_RESOURCE_OUTCOME: "+required);
}
if(contract.monotonicity.status!=="target-unproved") throw new Error("PSC_RESOURCE_MONOTONICITY_OVERCLAIM");
const test=await readFile(
  new URL("../test/KernelCore/Foundation/KernelContract.lean",import.meta.url),
  "utf8",
);
if(!test.includes("psKernelContractResourceMonotonicityTests")) throw new Error("PSC_RESOURCE_MONOTONICITY_REGRESSION");
const outcome=await readFile(
  new URL("../packages/pskernel-core/src/Ps/KernelCore/API/Outcome.lean",import.meta.url),
  "utf8",
);
if(!outcome.includes("| resourceExhausted")) throw new Error("PSC_RESOURCE_TYPED_OUTCOME");
process.stdout.write("PSCV_RESOURCE_CONTRACT: PASS (typed exhaustion + monotonicity regression slice)\n");
