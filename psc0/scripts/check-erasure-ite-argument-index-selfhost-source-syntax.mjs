import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

export function assertErasureIteArgumentIndex(source) {
  const block = source.match(
    /^def psEraseIteApplication\b[\s\S]*?(?=^def psErasureLookupTypeSubstitution\b)/m,
  )?.[0];
  if (!block) {
    throw new Error(
      "PSC2_ERASURE_ITE_ARGUMENT_INDEX_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
    );
  }
  for (const index of [1, 3, 4]) {
    if (!block.includes(`psErasureExprListAt view.args ${index}`)) {
      throw new Error(
        "PSC2_ERASURE_ITE_ARGUMENT_INDEX_SELFHOST_SOURCE_SYNTAX_MISSING: structural argument lookup",
      );
    }
  }
  if (/view\.args\s*\[\s*(?:1|3|4)\s*\]\?/.test(block)) {
    throw new Error(
      "PSC2_ERASURE_ITE_ARGUMENT_INDEX_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: optional indexing syntax",
    );
  }
  return block;
}

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/erasure/src/Ps/Erasure/Expr.lean"),
  "utf8",
);
const block = assertErasureIteArgumentIndex(source);
for (const index of [1, 3, 4]) {
  const current = `psErasureExprListAt view.args ${index}`;
  const broken = block.replace(current, `view.args[${index}]?`);
  assert.throws(
    () => assertErasureIteArgumentIndex(source.replace(block, broken)),
    /ARGUMENT_INDEX.*(?:MISSING|FORBIDDEN)/,
  );
}
process.stdout.write(
  "PSC2_ERASURE_ITE_ARGUMENT_INDEX_SELFHOST_SOURCE_SYNTAX: PASS (three structural argument lookups; optional-index mutation checks)\n",
);
