import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

export function assertFinishApplicationSequencing(source) {
  const block = source.match(/^def psEraseFinishApplicationWithFuelWorker\b[\s\S]*?(?=^def psEraseFinishApplication\b)/m)?.[0];
  if (!block) throw new Error("PSC2_ERASURE_FINISH_APPLICATION_SEQUENCING_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block");
  const pushed = /psLocalPushBinding\s+scope\.localContext\s+name\s+domain\s+binder;/g;
  const scopes = /let nextScope : PsErasureScope := \{[^;]*?currentDefinition := scope\.currentDefinition\s*\};\s*smaller nextScope/g;
  const name = /let parameterBase :=\s*psErasureSafeIdentifier[^;]*?;\s*let parameterName :=\s*psErasureLocalName scope parameterBase "arg" pushed\.id;\s*if psErasureLocalNameUsed scope parameterName then\s*Except\.error PsErasureError\.fuelExhausted\s*else\s*let nextScope : PsErasureScope :=/;
  const body = /let body :=\s*if \(psListIsEmpty runtimeArguments\) then[^;]*?runtimeArguments;\s*match \(psListReverse parametersRev\) with/;
  if ((block.match(pushed) ?? []).length !== 2 || (block.match(scopes) ?? []).length !== 2 ||
      !name.test(block) || !body.test(block) ||
      !/psEraseFinishApplicationWithFuelWorker environment fn typeArguments remaining;\s*fun/.test(block) ||
      !/let parameters := List\.cons parameter rest;\s*match/.test(block)) {
    throw new Error("PSC2_ERASURE_FINISH_APPLICATION_SEQUENCING_SELFHOST_SOURCE_SYNTAX_MISSING: nine sequenced locals");
  }
  return block;
}

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(path.join(root, "packages/erasure/src/Ps/Erasure/Expr.lean"), "utf8");
const block = assertFinishApplicationSequencing(source);
// Each original terminator must remain independently protected. The guard does
// not require the obsolete infix spelling of the parameter-name expression.
const terminators = [...block.matchAll(/;/g)].map((match) => match.index);
assert.equal(terminators.length, 9);
for (const index of terminators) {
  const broken = block.slice(0, index) + block.slice(index + 1);
  assert.throws(() => assertFinishApplicationSequencing(source.replace(block, broken)), /SEQUENCING.*MISSING/);
}
process.stdout.write("PSC2_ERASURE_FINISH_APPLICATION_SEQUENCING_SELFHOST_SOURCE_SYNTAX: PASS (nine sequenced locals; nine missing-terminator mutation checks)\n");
