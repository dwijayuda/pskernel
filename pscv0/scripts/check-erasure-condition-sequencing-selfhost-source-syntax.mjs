import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

export function assertErasureConditionSequencing(source) {
  const block = source.match(
    /^def psEraseCondition\b[\s\S]*?(?=^def psEraseIteApplication\b)/m,
  )?.[0];
  if (
    !block ||
    !/let view := psErasureAppView proposition;\s*match view\.head with/.test(block)
  ) {
    throw new Error(
      "PSC2_ERASURE_CONDITION_SEQUENCING_SELFHOST_SOURCE_SYNTAX_MISSING: sequenced app view",
    );
  }
  return block;
}

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/erasure/src/Ps/Erasure/Expr.lean"),
  "utf8",
);
const block = assertErasureConditionSequencing(source);
const protectedText = "let view := psErasureAppView proposition;";
assert.ok(block.includes(protectedText));
const broken = block.replace(protectedText, protectedText.replace(";", ""));
assert.throws(
  () => assertErasureConditionSequencing(source.replace(block, broken)),
  /SEQUENCING.*MISSING/,
);
process.stdout.write(
  "PSC2_ERASURE_CONDITION_SEQUENCING_SELFHOST_SOURCE_SYNTAX: PASS (sequenced app view; missing-terminator mutation check)\n",
);
