import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

export function assertErasurePrimitiveApplicationSequencing(source) {
  const block = source.match(
    /^def psErasePrimitiveApplication\b[\s\S]*?(?=^def psEraseCondition\b)/m,
  )?.[0];
  if (!block) {
    throw new Error(
      "PSC2_ERASURE_PRIMITIVE_APPLICATION_SEQUENCING_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
    );
  }
  if (
    !/let text := psNameToString name;\s*let binary : PsVerifiedIrIntrinsic -> Except PsErasureError \(Option PsVerifiedIrExpr\) :=/.test(block) ||
    !/let binary : PsVerifiedIrIntrinsic -> Except PsErasureError \(Option PsVerifiedIrExpr\) :=\s*fun \(operation : PsVerifiedIrIntrinsic\) =>[\s\S]*?Except\.error PsErasureError\.unsupportedApplication;\s*let productProjection : Nat -> Except PsErasureError \(Option PsVerifiedIrExpr\) :=/.test(block) ||
    !/let productProjection : Nat -> Except PsErasureError \(Option PsVerifiedIrExpr\) :=\s*fun \(index : Nat\) =>[\s\S]*?Except\.error PsErasureError\.unsupportedApplication;\s*if psStringEq text "Prod\.fst" then/.test(block)
  ) {
    throw new Error(
      "PSC2_ERASURE_PRIMITIVE_APPLICATION_SEQUENCING_SELFHOST_SOURCE_SYNTAX_MISSING: three sequenced locals",
    );
  }
  return block;
}

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/erasure/src/Ps/Erasure/Expr.lean"),
  "utf8",
);
const block = assertErasurePrimitiveApplicationSequencing(source);
assert.ok(!/fun operation =>/.test(block));
const lambdaBroken = block.replace("fun (operation : PsVerifiedIrIntrinsic) =>", "fun operation =>");
assert.throws(
  () => assertErasurePrimitiveApplicationSequencing(source.replace(block, lambdaBroken)),
  /SEQUENCING.*MISSING/,
);
const protectedTerminators = [
  "let text := psNameToString name;",
  "Except.error PsErasureError.unsupportedApplication;\n      let productProjection",
  "Except.error PsErasureError.unsupportedApplication;\n      if psStringEq text \"Prod.fst\" then",
];
for (const protectedText of protectedTerminators) {
  assert.ok(block.includes(protectedText));
  const broken = block.replace(protectedText, protectedText.replace(";", ""));
  assert.throws(
    () => assertErasurePrimitiveApplicationSequencing(source.replace(block, broken)),
    /SEQUENCING.*MISSING/,
  );
}
process.stdout.write(
  "PSC2_ERASURE_PRIMITIVE_APPLICATION_SEQUENCING_SELFHOST_SOURCE_SYNTAX: PASS (three sequenced locals; three missing-terminator mutation checks)\n",
);
