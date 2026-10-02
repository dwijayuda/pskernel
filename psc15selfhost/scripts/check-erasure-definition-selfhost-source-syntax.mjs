import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/erasure/src/Ps/Erasure/Definition.lean"),
  "utf8",
);
const match = source.match(/def psEraseDefinition\n[\s\S]*?(?=\ndef psErasureReverseIrDeclarationsAcc\n|\ndef psEraseDefinitionsLoop\n)/);
if (match === null) throw new Error("PSC2_ERASURE_DEFINITION_MISSING: declaration");
const block = match[0];
for (const pattern of [
  /if psErasureIsProp environment psLocalEmpty type then\s*Except\.ok Option\.none/,
  /let outputName : String :=\s*match psErasureLookupName/,
  /\| Option\.some known => known/,
  /\| Option\.none =>[\s\S]*?"decl";/,
  /let definitionScope : PsErasureScope :=\s*PsErasureScope\.mk\s+scope\.localContext\s+scope\.runtimeLocals\s+scope\.typeLocals\s+scope\.erasedLocals\s+scope\.declarationNames\s+scope\.runtimeConstructors\s+scope\.runtimeRecursors\s+scope\.runtimeStructures\s+scope\.runtimeStructureConstructors\s+scope\.runtimeExpressions\s*\(Option\.some\s*\(PsErasureCurrentDefinition\.mk outputName List\.nil\)\);/,
  /match psLowerStructureRecursors environment value with\s*\| Except\.error error => Except\.error error/,
  /psEraseOpenDefinition\s+environment\s+definitionScope\s+type\s+normalizedValue with/,
  /match psErasureEtaFunction opened\.parameters opened\.resultType opened\.body with/,
  /PsVerifiedIrExpr\.lambda parameters resultType body =>\s*Except\.ok\s*\(Option\.some\s*\(PsVerifiedIrDeclaration\.mk\s+outputName\s+opened\.typeParameters\s+parameters\s+resultType\s+body\)\)/,
]) {
  if (!pattern.test(block)) throw new Error(`PSC2_ERASURE_DEFINITION_MISSING: ${pattern}`);
}
if (/(?<![\w.])(?:some|none)\b|:=\s*\{|\bscope with\b/.test(block)) {
  throw new Error("PSC2_ERASURE_DEFINITION_FORBIDDEN: implicit Option or record construction");
}
process.stdout.write("PSC2_ERASURE_DEFINITION: PASS (typed output-name match; explicit scope, Option and IR declaration constructors)\n");
