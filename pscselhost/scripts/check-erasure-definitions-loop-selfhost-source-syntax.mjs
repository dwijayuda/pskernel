import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/erasure/src/Ps/Erasure/Definition.lean"), "utf8",
);
const match = source.match(/def psErasureReverseIrDeclarationsAcc[\s\S]*?(?=\ndef psEraseCoreModuleWithRuntimePrelude\n)/);
if (match === null) throw new Error("PSC2_ERASURE_DEFINITIONS_LOOP_MISSING: reverse helper and worker");
const block = match[0];
for (const pattern of [
  /\(declarations : List PsVerifiedIrDeclaration\) :\s*List PsVerifiedIrDeclaration -> List PsVerifiedIrDeclaration :=\s*match declarations with/,
  /psErasureReverseIrDeclarationsAcc rest;\s*fun \(acc : List PsVerifiedIrDeclaration\) =>\s*smaller \(List\.cons declaration acc\)/,
  /def psEraseDefinitionsLoopWorker\s*\(environment : PsEnvironment\)\s*\(scope : PsErasureScope\)\s*\(declarations : List PsDeclaration\) :\s*List PsVerifiedIrDeclaration ->\s*Except PsErasureError \(List PsVerifiedIrDeclaration\) :=\s*match declarations with/,
  /Except\.ok \(psErasureReverseIrDeclarationsAcc declarationsRev List\.nil\)/,
  /psEraseDefinitionsLoopWorker environment scope rest;/,
  /\| PsDeclaration\.definitionDecl name _ type value =>/,
  /\| PsDeclaration\.partialDecl name _ type value =>/,
  /\| _ => smaller declarationsRev/,
  /def psEraseDefinitionsLoop\s*\(environment : PsEnvironment\)\s*\(scope : PsErasureScope\)\s*\(declarations : List PsDeclaration\)\s*\(declarationsRev : List PsVerifiedIrDeclaration\)[\s\S]*?psEraseDefinitionsLoopWorker environment scope declarations declarationsRev/,
]) {
  if (!pattern.test(block)) throw new Error(`PSC2_ERASURE_DEFINITIONS_LOOP_MISSING: ${pattern}`);
}
for (const pattern of [
  /\| Except\.error error => Except\.error error/g,
  /\| Except\.ok result =>\s*match result with\s*\| Option\.none => smaller declarationsRev\s*\| Option\.some lowered =>\s*smaller \(List\.cons lowered declarationsRev\)/g,
]) {
  if ([...block.matchAll(pattern)].length !== 2) {
    throw new Error(`PSC2_ERASURE_DEFINITIONS_LOOP_MISSING: both definition branches: ${pattern}`);
  }
}
if (/\.reverse\b|\| \[\],|\| declaration :: rest,|\| Except\.ok \(|\| \.(?:definition|partial)Decl/.test(block)) {
  throw new Error("PSC2_ERASURE_DEFINITIONS_LOOP_FORBIDDEN: generic reverse, multi-argument or nested patterns");
}
process.stdout.write("PSC2_ERASURE_DEFINITIONS_LOOP: PASS (declaration-list recursion; ordered results; sequential Except/Option matches)\n");
