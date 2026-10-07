import { readFile } from "node:fs/promises";
import { createHash } from "node:crypto";
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
// Current implementation and normative language target are separate identities.
// Neither target documentation nor this lock upgrades bootstrap conformance.
if(language.schemaVersion!==2 || !language.bootstrapLean ||
  lock.lean.version!==language.bootstrapLean.version ||
  lock.lean.commit!==language.bootstrapLean.commit) throw new Error("PSC_SEMANTIC_LOCK_BOOTSTRAP_LEAN");
const toolchain=(await readFile(new URL("../lean-toolchain",import.meta.url),"utf8")).trim();
if(toolchain!=="leanprover/lean4:v"+lock.lean.version ||
  !/^[a-f0-9]{40}$/.test(lock.lean.commit)) throw new Error("PSC_SEMANTIC_LOCK_BOOTSTRAP_TOOLCHAIN");
const target=lock.targetLanguage;
if(!target || target.document!==language.document || target.sha256!==language.sha256 ||
  target.profile!==language.verificationProfile ||
  target.verificationSemantics!==language.verificationSemantics ||
  target.certificatePolicy!==language.certificatePolicy ||
  target.lean?.version!==language.normativeLeanVersion ||
  target.lean?.commit!==language.normativeLeanCommit ||
  target.conformance!=="not-established") throw new Error("PSC_SEMANTIC_LOCK_TARGET_LANGUAGE");
const reference=await readFile(new URL("../"+target.document,import.meta.url));
if(createHash("sha256").update(reference).digest("hex")!==target.sha256) throw new Error("PSC_SEMANTIC_LOCK_TARGET_BYTES");
if(lock.kernelContract.id!==kernelContractV1.id||lock.kernelContract.sha256!==kernelContractV1.sha256) throw new Error("PSC_SEMANTIC_LOCK_KERNEL");
const declared=runtime.proofscript?.runtimeSemantics;
if(lock.runtimeSemantics.id!==declared?.id||lock.runtimeSemantics.sha256!==declared?.sha256) throw new Error("PSC_SEMANTIC_LOCK_RUNTIME");
if(lock.verifiedIr!=="psc-verified-ir/1"||lock.providerSecurity!=="psc-provider-security/1"||lock.trustManifest!=="psc-trust-manifest/1") throw new Error("PSC_SEMANTIC_LOCK_REQUIRED");
process.stdout.write("PSCV_SEMANTIC_LOCK: PASS\n");
