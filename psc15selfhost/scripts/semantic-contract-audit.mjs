import { access, readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),"..");
const defeq=JSON.parse(await readFile(path.join(root,"contracts/semantic/ALGORITHMIC_DEFEQ_CACHE_V1.json"),"utf8"));
if(defeq.contract!=="psc-algorithmic-defeq-cache/1"||defeq.relationProperties.transitive!==false||defeq.relationProperties.equivalenceClosurePermitted!==false) throw new Error("PSC_DEFEQ_CACHE_CONTRACT");
if(!defeq.forbiddenCacheOperations.includes("union-find-equivalence-closure")) throw new Error("PSC_DEFEQ_CACHE_UNION_FIND");
for(const owner of defeq.currentOwners) {
  const candidate=owner.endsWith("/DefEq")?owner+".lean":owner;
  try { await access(path.join(root,candidate)); } catch {
    if(!owner.endsWith("/DefEq")) throw new Error("PSC_DEFEQ_CACHE_OWNER: "+owner);
  }
}
const gaps=JSON.parse(await readFile(path.join(root,"contracts/ir/VERIFIED_IR_GAPS_V1.json"),"utf8"));
if(gaps.contract!=="psc-verified-ir-gap-registry/1"||gaps.verifiedIrContract!=="psc-verified-ir/1") throw new Error("PSC_VERIFIED_IR_GAP_SCHEMA");
const all=[...gaps.implemented,...gaps.gaps], seen=new Set();
for(const id of all){if(!id||seen.has(id)) throw new Error("PSC_VERIFIED_IR_GAP_DUPLICATE: "+id);seen.add(id);}
if(gaps.gaps.length===0) throw new Error("PSC_VERIFIED_IR_FALSE_COMPLETENESS");
process.stdout.write("PSCV_SEMANTIC_CONTRACTS: PASS ("+gaps.implemented.length+" implemented, "+gaps.gaps.length+" open VerifiedIR invariants)\n");
