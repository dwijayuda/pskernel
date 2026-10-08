import { readFile } from "node:fs/promises";
import { verifySavefFile } from "./savef-object.mjs";
import { assertProviderSecurityRegistry } from "./provider-security.mjs";
import { pathToFileURL } from 'node:url';
export { verifyOfflineCapsule } from './offline-capsule.mjs';

export const pscvVerifierPrototype = Object.freeze({
  id:"pscv-verify/0-prototype",
  offline:true,
  fullCompilerRequired:false,
});

export async function verifyOfflinePrototype() {
  assertProviderSecurityRegistry();
  const architecture=JSON.parse(await readFile(new URL("../contracts/registry/ARCHITECTURE_REGISTRY.json",import.meta.url),"utf8"));
  const trust=JSON.parse(await readFile(new URL("../TRUST_MANIFEST.json",import.meta.url),"utf8"));
  const semanticLock=JSON.parse(await readFile(new URL("../psc.semantic-lock.json",import.meta.url),"utf8"));
  const archiveProfile=JSON.parse(await readFile(new URL("../contracts/archive/ARCHIVE_PROFILE_V0.json",import.meta.url),"utf8"));
  const independence=JSON.parse(await readFile(new URL("../profiles/assurance/INDEPENDENCE_VECTORS.json",import.meta.url),"utf8"));
  if(architecture.masterPlan!=="THE_PSCV_COMPILER_REFERENCE_VERSION_5.1.md") throw new Error("PSCV_VERIFY_ARCHITECTURE");
  if(trust.contract!=="psc-trust-manifest/1") throw new Error("PSCV_VERIFY_TRUST");
  if(semanticLock.contract!=="psc-semantic-lock/0") throw new Error("PSCV_VERIFY_SEMANTIC_LOCK");
  if(archiveProfile.contract!=="psc-archive-profile/0"||archiveProfile.offlineVerificationRequired!==true) throw new Error("PSCV_VERIFY_ARCHIVE");
  if(independence.contract!=="psc-independence-vector/1") throw new Error("PSCV_VERIFY_INDEPENDENCE");
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
    architecture:"pscv-architecture/v3", // Historical evidence origin, not current target conformance.
    targetArchitecture:"pscv-architecture/v5.1",
    targetConformance:false,
    trust:trust.contract,
    semanticLock:semanticLock.contract,
    archiveProfile:archiveProfile.contract,
    independence:independence.contract,
    savefObjects:Object.freeze(savefObjects),
  });
}

if(process.argv[1] && pathToFileURL(process.argv[1]).href === import.meta.url){
  const args = process.argv.slice(2);
  const run = async () => {
    if (!args.length) return { prototype: await verifyOfflinePrototype() };
    if (args.length === 3 && args[0] === '--diff-locks') {
      const { compareSemanticLockFiles } = await import('./offline-verifier-cli.mjs');
      return compareSemanticLockFiles(args[1], args[2]);
    }
    if (args.length !== 4 || !['--capsule', '--build-archive'].includes(args[0]) || args[2] !== '--policy') {
      throw new Error('Usage: pscv-verify --capsule FILE --policy TRUSTED_LOCAL_POLICY | --build-archive FILE --policy TRUSTED_LOCAL_POLICY | --diff-locks LEFT RIGHT');
    }
    const api = await import('./offline-verifier-cli.mjs');
    return args[0] === '--build-archive' ? api.verifyBuildArchiveCommand(args[1], args[3]) : api.verifyCapsuleCommand(args[1], args[3]);
  };
  run().then(result => {
    process.stdout.write(JSON.stringify(result) + '\n');
    if (result.kind && result.kind !== 'accepted') process.exitCode = 1;
  }).catch(error => { process.stderr.write(error.message + '\n'); process.exitCode = 1; });
}
