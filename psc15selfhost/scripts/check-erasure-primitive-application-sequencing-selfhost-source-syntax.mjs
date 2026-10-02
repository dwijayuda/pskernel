import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

export function assertErasurePrimitiveApplicationSequencing(source) {
  const block = source.match(
    /^def psErasePrimitiveApplication\b[\s\S]*?(?=^def |\s*$)/m,
  )?.[0];
  if (!block) {
    throw new Error(
      "PSC2_ERASURE_PRIMITIVE_APPLICATION_SEQUENCING_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
    );
  }
  if (
    !/let text := psNameToString name;\s*let binary :=/.test(block) ||
    !/let binary :=[\s\S]*?Except\.error PsErasureError\.unsupportedApplication;\s*if text == "Int\.ofNat" then/.test(block)
  ) {
    throw new Error(
      "PSC2_ERASURE_PRIMITIVE_APPLICATION_SEQUENCING_SELFHOST_SOURCE_SYNTAX_MISSING: two sequenced locals",
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
const protectedTerminators = [
  "let text := psNameToString name;",
  "Except.error PsErasureError.unsupportedApplication;\n      if text == \"Int.ofNat\" then",
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
  "PSC2_ERASURE_PRIMITIVE_APPLICATION_SEQUENCING_SELFHOST_SOURCE_SYNTAX: PASS (two sequenced locals; two missing-terminator mutation checks)\n",
);
