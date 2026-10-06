import { readFile } from "node:fs/promises";
import { kernelContractV1 } from "./kernel-contract.mjs";

const lock=JSON.parse(await readFile(
  new URL("../psc.semantic-lock.json",import.meta.url),
  "utf8",
));
const language=JSON.parse(await readFile(
  new URL("../language-authority.json",import.meta.url),
  "utf8",
));
const runtime=JSON.parse(await readFile(
  new URL("../packages/compiler-ir/package.json",import.meta.url),
  "utf8",
));

if(lock.contract!=="psc-semantic-lock/0") throw new Error("PSC_SEMANTIC_LOCK_CONTRACT");
if(lock.architecture!=="pscv-architecture/v3") throw new Error("PSC_SEMANTIC_LOCK_ARCH");
if(lock.lean.version!==language.leanVersion||lock.lean.commit!==language.leanCommit) throw new Error("PSC_SEMANTIC_LOCK_LEAN");
if(lock.kernelContract.id!==kernelContractV1.id||lock.kernelContract.sha256!==kernelContractV1.sha256) throw new Error("PSC_SEMANTIC_LOCK_KERNEL");
const declared=runtime.proofscript?.runtimeSemantics;
if(lock.runtimeSemantics.id!==declared?.id||lock.runtimeSemantics.sha256!==declared?.sha256) throw new Error("PSC_SEMANTIC_LOCK_RUNTIME");
if(lock.verifiedIr!=="psc-verified-ir/1"||lock.providerSecurity!=="psc-provider-security/1"||lock.trustManifest!=="psc-trust-manifest/1") throw new Error("PSC_SEMANTIC_LOCK_REQUIRED");
process.stdout.write("PSCV_SEMANTIC_LOCK: PASS\n");
