import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

export function assertErasurePrimitiveApplicationDisjunction(source) {
  const block = source.match(
    /^def psErasePrimitiveApplication\b[\s\S]*?(?=^def psEraseCondition\b)/m,
  )?.[0];
  if (!block) {
    throw new Error(
      "PSC2_ERASURE_PRIMITIVE_APPLICATION_DISJUNCTION_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
    );
  }
  const mk = 'else if psStringEq text "String.Pos.Raw.mk" then';
  const byteIdx = 'else if psStringEq text "String.Pos.Raw.byteIdx" then';
  if (!block.includes(mk) || !block.includes(byteIdx)) {
    throw new Error(
      "PSC2_ERASURE_PRIMITIVE_APPLICATION_DISJUNCTION_SELFHOST_SOURCE_SYNTAX_MISSING: split String.Pos.Raw branches",
    );
  }
  if (/\|\|/.test(block)) {
    throw new Error(
      "PSC2_ERASURE_PRIMITIVE_APPLICATION_DISJUNCTION_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: boolean disjunction operator",
    );
  }
  return block;
}

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/erasure/src/Ps/Erasure/Expr.lean"),
  "utf8",
);
const block = assertErasurePrimitiveApplicationDisjunction(source);
const split = 'else if psStringEq text "String.Pos.Raw.byteIdx" then';
assert.ok(block.includes(split));
const broken = block.replace(
  split,
  '|| psStringEq text "String.Pos.Raw.byteIdx" then',
);
assert.throws(
  () => assertErasurePrimitiveApplicationDisjunction(source.replace(block, broken)),
  /PRIMITIVE_APPLICATION_DISJUNCTION.*(?:MISSING|FORBIDDEN)/,
);
process.stdout.write(
  "PSC2_ERASURE_PRIMITIVE_APPLICATION_DISJUNCTION_SELFHOST_SOURCE_SYNTAX: PASS (String.Pos.Raw cases split; disjunction mutation rejected)\n",
);
