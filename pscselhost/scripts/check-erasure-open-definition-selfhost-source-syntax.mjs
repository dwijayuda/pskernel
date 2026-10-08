import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/erasure/src/Ps/Erasure/Definition.lean"),
  "utf8",
);
const match = source.match(
  /def psEraseOpenDefinitionWithFuel[\s\S]*?(?=\ndef psEraseOpenDefinition\n)/,
);
if (match === null) throw new Error("PSC2_ERASURE_OPEN_DEFINITION_MISSING: declaration");
const block = match[0];
for (const pattern of [
  /\(environment : PsEnvironment\)\s*\(fuel : Nat\) :[\s\S]*?Except PsErasureError PsOpenedErasedDefinition :=\s*match fuel with/,
  /\| Nat\.zero =>[\s\S]*?Except\.error PsErasureError\.fuelExhausted/,
  /\| Nat\.succ remaining =>\s*let smaller :[\s\S]*?psEraseOpenDefinitionWithFuel environment remaining;/,
  /\| PsExpr\.forallE typeName domain typeBody binder =>/,
  /\| PsExpr\.lam valueName _ valueBody _ =>/,
  /String\.Internal\.append "T" \(psNatToString typeIndex\);/,
  /\| PsErasedBinderKind\.type =>/,
  /\| PsErasedBinderKind\.proof =>/,
  /\| PsErasedBinderKind\.runtime =>/,
  /let nextCurrentDefinition : Option PsErasureCurrentDefinition :=/,
  /psErasureAppendRuntimeParameter current\.runtimeParameters parameterName/,
  /\(PsVerifiedIrTypeParameter\.mk parameterName\)/,
  /\(PsVerifiedIrParameter\.mk parameterName parameterType\)/,
  /\(Nat\.succ typeIndex\)/,
  /PsOpenedErasedDefinition\.mk\s*\(psErasureReverseTypeParametersAcc typeParametersRev List\.nil\)\s*\(psErasureReverseParametersAcc parametersRev List\.nil\)\s+resultType\s+body/,
]) {
  if (!pattern.test(block)) throw new Error(`PSC2_ERASURE_OPEN_DEFINITION_MISSING: ${pattern}`);
}
if ((block.match(/PsErasureScope\.mk/g) ?? []).length !== 3 ||
    (block.match(/\bsmaller\s+nextScope/g) ?? []).length !== 3) {
  throw new Error("PSC2_ERASURE_OPEN_DEFINITION_MISSING: three scope transitions and post-recursion calls");
}
if (/\+\+|\btoString\b|\.reverse\b|\| 0,|\| fuel \+ 1,|:=\s*\{|Except\.ok\s*\{|\| \.(?:forallE|lam|type|proof|runtime)\b/.test(block)) {
  throw new Error("PSC2_ERASURE_OPEN_DEFINITION_FORBIDDEN: unsupported syntax or generic list operations");
}
for (const [suffix, type] of [
  ["TypeParameters", "PsVerifiedIrTypeParameter"],
  ["Parameters", "PsVerifiedIrParameter"],
]) {
  const helper = source.match(new RegExp(`def psErasureReverse${suffix}Acc[\\s\\S]*?(?=\\ndef )`));
  if (helper === null || !helper[0].includes(`(parameters : List ${type})`) ||
      !helper[0].includes("match parameters with") ||
      !helper[0].includes(`fun (acc : List ${type}) => acc`) ||
      !helper[0].includes(`psErasureReverse${suffix}Acc rest;`) ||
      !helper[0].includes("smaller (List.cons parameter acc)")) {
    throw new Error(`PSC2_ERASURE_OPEN_DEFINITION_MISSING: structural ${suffix} reverse`);
  }
}
if (!/def psErasureAppendRuntimeParameter[\s\S]*?match parameters with\s*\| List\.nil => List\.cons name List\.nil\s*\| List\.cons parameter rest =>\s*List\.cons parameter \(psErasureAppendRuntimeParameter rest name\)/.test(source)) {
  throw new Error("PSC2_ERASURE_OPEN_DEFINITION_MISSING: ordered runtime-parameter append");
}
process.stdout.write(
  "PSC2_ERASURE_OPEN_DEFINITION: PASS (fuel recursion; scope/parameters applied afterward; explicit constructors and local list operations)\n",
);
