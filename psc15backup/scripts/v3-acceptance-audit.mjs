import { access, readFile } from "node:fs/promises";

const root=new URL("../",import.meta.url);
const read=relative=>readFile(new URL(relative,root),"utf8");
const json=async relative=>JSON.parse(await read(relative));

const checks=[];

async function check(id,run){
  try{
    await run();
    checks.push({id,accepted:true});
  }catch(error){
    checks.push({id,accepted:false,error:error instanceof Error?error.message:String(error)});
  }
}

await check("A1-production-build-checked",async()=>{
  const cli=await read("packages/cli/bin/psc.mjs");
  const start=cli.indexOf('} else if (command === "build")');
  const stop=cli.indexOf('} else if (command === "build-unchecked")');
  if(start<0||stop<=start) throw new Error("build command boundary");
  const block=cli.slice(start,stop);
  if(!block.includes("scripts/checked-build.mjs")||block.includes("compile-with-generated.mjs")) throw new Error("unchecked production build");
});

await check("A2-checked-capability",async()=>{
  const session=await read("scripts/kernel-checked-session.mjs");
  if(!session.includes("psc-checked-core-capability/1")||!session.includes("new WeakMap")) throw new Error("capability boundary missing");
});

await check("A3-provider-security-identity",async()=>{
  const security=await json("profiles/provider-security/PROVIDER_SECURITY_PROFILES.json");
  if(security.contract!=="psc-provider-security/1"||!security.providers?.["lean434-wasm"]?.securityRevision) throw new Error("provider security identity missing");
});

await check("A4-no-provider-fallback",async()=>{
  const provider=await read("scripts/checked-kernel-provider.mjs");
  const session=await read("scripts/kernel-checked-session.mjs");
  if(provider.includes("automatic-fallback")||!session.includes("provider failure")&&!session.includes("checkAdmissions")) {
    throw new Error("fail-closed provider evidence missing");
  }
  const tests=await read("scripts/kernel-checked-session.test.mjs");
  if(!tests.includes("provider failure does not fall back")) throw new Error("no fallback regression missing");
});

await check("A5-trust-manifest",async()=>{
  const trust=await json("TRUST_MANIFEST.json");
  if(trust.contract!=="psc-trust-manifest/1"||trust.legacyImplementationReference!=="THE_PSCV_COMPILER_REFERENCE_VERSION_3.md"||trust.masterPlan!=="THE_PSCV_COMPILER_REFERENCE_VERSION_5.1.md") throw new Error("trust manifest drift");
  await access(new URL(trust.semanticBootstrapRoot,root));
});

await check("A6-defeq-cache-contract",async()=>{
  const contract=await json("contracts/semantic/ALGORITHMIC_DEFEQ_CACHE_V1.json");
  if(contract.relationProperties?.transitive!==false||contract.relationProperties?.equivalenceClosurePermitted!==false) throw new Error("defeq relation overclaimed");
  const source=await read("packages/pskernel-core/src/Ps/KernelCore/Runtime/Acceleration/Cache.lean");
  if(!source.includes("PsKernelExprPairSet")||source.includes("UnionFind")||source.includes("EquivManager")) throw new Error("cache source violates pair-local policy");
});

await check("A7-verified-ir-gap-registry",async()=>{
  const gaps=await json("contracts/ir/VERIFIED_IR_GAPS_V1.json");
  if(gaps.verifiedIrContract!=="psc-verified-ir/1"||!Array.isArray(gaps.gaps)||gaps.gaps.length===0) throw new Error("VerifiedIR gaps not explicit");
});

await check("A8-specialized-ir-capability",async()=>{
  const source=await read("packages/compiler-ir/src/Ps/CompilerIr/Specialize.lean");
  if(!source.includes("structure PsSpecializedIrModule")||!source.includes("psIrSpecializeValidatedModule")) throw new Error("SpecializedIR capability missing");
});

await check("A9-pass-execution-evidence",async()=>{
  const pass=await read("packages/compiler-ir/src/Ps/CompilerIr/Pass.lean");
  const specialize=await read("packages/compiler-ir/src/Ps/CompilerIr/Specialize.lean");
  if(!pass.includes("structure PsPassDefinition")||!pass.includes("structure PsPassExecution")||!specialize.includes("PsSpecializedIrExecutionResult")) throw new Error("pass evidence missing");
});

await check("A10-module-interface-query-reuse",async()=>{
  const graph=await read("packages/project/src/Ps/Project/QueryGraph.lean");
  if(!graph.includes("interfaceFingerprint")||!graph.includes("psModuleInterfaceFingerprintEq")) throw new Error("typed module interface not driving query reuse");
});

await check("A11-comparator-prototype",async()=>{
  const comparator=await read("scripts/comparator-v1.mjs");
  if(!comparator.includes("psc-comparator/1")||!comparator.includes("sourceClosureSha256")||!comparator.includes("dualCheck")) throw new Error("comparator prototype incomplete");
});

await check("A12-formal-theory-slice",async()=>{
  const theory=await read("packages/pscv-theory/proof/Ps/Theory/Refinement.lean");
  const manifest=await json("theory/core/DECLARATIVE_CORE_SEED_V1.json");
  if(!theory.includes("PsDeclarativeConversion.refl")||!manifest.provedSlices?.some(item=>item.id==="psc-kernel-exact-defeq-sound/1"&&item.status==="proved-lean")) throw new Error("formal proof slice missing");
});

await check("A13-wasm-translation-validator",async()=>{
  const contract=await json("contracts/target/WASM_TRANSLATION_VALIDATOR_V0.json");
  const validator=await read("packages/backend-wasm/src/Ps/BackendWasm/Validate.lean");
  if(contract.assurance!=="translation-validation-closed-slice"||!validator.includes("psWasmValidateSpecializedLiteralModule")) throw new Error("Wasm validation slice missing");
});

await check("A14-savef-evidence-types",async()=>{
  const objects=[
    await json("savef/objects/psc-specialization-pass.json"),
    await json("savef/objects/psc-theory-exact-defeq-reflexive.json"),
    await json("savef/objects/psc-module-interface-validation.json"),
  ];
  const kinds=new Set(objects.map(item=>item.authorityClass));
  for(const required of ["formal-evidence","validation-authority"]){
    if(!kinds.has(required)) throw new Error("SAVEF evidence class missing: "+required);
  }
  if(!objects.some(item=>item.kind==="CompilerPassContract")) throw new Error("SAVEF pass object missing");
});

await check("A15-factorybench-holdout-frozen",async()=>{
  const holdout=await json("factory/bench/FACTORYBENCH_V4_HOLDOUT.json");
  if(holdout.searchableByFactory!==false||!String(holdout.status).startsWith("policy-frozen")) throw new Error("holdout exposure policy invalid");
});

await check("A16-erasure-formal-slice",async()=>{
  const contract=await json("contracts/ir/ERASURE_PRESERVATION_V0.json");
  const theory=await read("packages/pscv-theory/proof/Ps/Theory/Refinement.lean");
  if(!contract.provedSlices?.some(item=>item.id==="psc-erasure-proof-declaration-omission/1"&&item.status==="proved-lean")) throw new Error("erasure proof slice not registered");
  if(!theory.includes("psErasureProofDeclarationOmitted")) throw new Error("erasure proof term missing");
});

await check("A17-specialization-formal-slice",async()=>{
  const contract=await json("contracts/ir/SPECIALIZATION_PASS_V1.json");
  const theory=await read("packages/pscv-theory/proof/Ps/Theory/Refinement.lean");
  if(!contract.provedSlices?.some(item=>item.id==="psc-specialization-literal-preservation/1"&&item.status==="proved-lean")) throw new Error("specialization proof slice not registered");
  if(!theory.includes("psSpecializationLiteralModulePreserves")) throw new Error("specialization proof term missing");
});

const failed=checks.filter(item=>!item.accepted);
if(failed.length){
  for(const item of failed) process.stderr.write("PSCV_V3_ACCEPTANCE_FAIL: "+item.id+": "+item.error+"\n");
  process.exit(1);
}
process.stdout.write("PSCV_V3_ACCEPTANCE: PASS ("+checks.length+"/"+checks.length+" milestone criteria)\n");
