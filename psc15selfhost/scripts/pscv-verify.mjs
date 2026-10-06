import { readFile } from "node:fs/promises";
import { verifySavefFile } from "./savef-object.mjs";
import { assertProviderSecurityRegistry } from "./provider-security.mjs";

export const pscvVerifierPrototype = Object.freeze({
  id:"pscv-verify/0-prototype",
  offline:true,
  fullCompilerRequired:false,
});

export async function verifyOfflinePrototype() {
  assertProviderSecurityRegistry();
  const architecture=JSON.parse(await readFile(new URL("../contracts/registry/ARCHITECTURE_REGISTRY.json",import.meta.url),"utf8"));
  const trust=JSON.parse(await readFile(new URL("../TRUST_MANIFEST.json",import.meta.url),"utf8"));
  if(architecture.masterPlan!=="THE_PSCV_COMPILER_REFERENCE_VERSION_3.md") throw new Error("PSCV_VERIFY_ARCHITECTURE");
  if(trust.contract!=="psc-trust-manifest/1") throw new Error("PSCV_VERIFY_TRUST");
  const schemaUrl=new URL("../savef/schemas/KNOWLEDGE_OBJECT_V1.json",import.meta.url);
  const objectUrls=[
    new URL("../savef/objects/psc-specialization-pass.json",import.meta.url),
    new URL("../savef/objects/psc-theory-exact-defeq-reflexive.json",import.meta.url),
    new URL("../savef/objects/psc-module-interface-validation.json",import.meta.url),
    new URL("../savef/objects/psc-erasure-proof-omission.json",import.meta.url),
    new URL("../savef/objects/psc-specialization-literal-proof.json",import.meta.url),
  ];
  const savefObjects=[];
  for(const objectUrl of objectUrls){
    const verified=await verifySavefFile(objectUrl,schemaUrl);
    savefObjects.push(verified.objectId);
  }
  return Object.freeze({
    verifier:pscvVerifierPrototype.id,
    architecture:"pscv-architecture/v3",
    trust:trust.contract,
    savefObjects:Object.freeze(savefObjects),
  });
}

if(process.argv[1]&&new URL("file:"+process.argv[1]).pathname===new URL(import.meta.url).pathname){
  verifyOfflinePrototype().then(result=>process.stdout.write("PSCV_VERIFY_OFFLINE: PASS "+JSON.stringify(result)+"\n"));
}
