import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

export function assertErasureIteEquality(source) {
  const block = source.match(
    /^def psEraseIteApplication\b[\s\S]*?(?=^def psErasureLookupTypeSubstitution\b)/m,
  )?.[0];
  if (!block) {
    throw new Error(
      "PSC2_ERASURE_ITE_EQUALITY_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
    );
  }
  if (!/psErasureBoolAnd \(psNameEq name psIteName\) \(Nat\.beq \(psListLength view\.args\) 5\)/.test(block)) {
    throw new Error(
      "PSC2_ERASURE_ITE_EQUALITY_SELFHOST_SOURCE_SYNTAX_MISSING: structural conjunction with explicit Nat equality",
    );
  }
  if (/==|&&/.test(block)) {
    throw new Error(
      "PSC2_ERASURE_ITE_EQUALITY_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: equality/conjunction operator",
    );
  }
  return block;
}

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/erasure/src/Ps/Erasure/Expr.lean"),
  "utf8",
);
const block = assertErasureIteEquality(source);
const current = "psErasureBoolAnd (psNameEq name psIteName) (Nat.beq (psListLength view.args) 5)";
assert.ok(block.includes(current));
const broken = block.replace(current, "psNameEq name psIteName && (psListLength view.args) == 5");
assert.throws(
  () => assertErasureIteEquality(source.replace(block, broken)),
  /ITE_EQUALITY.*(?:MISSING|FORBIDDEN)/,
);
process.stdout.write(
  "PSC2_ERASURE_ITE_EQUALITY_SELFHOST_SOURCE_SYNTAX: PASS (structural conjunction with Nat.beq length check; operator mutation rejected)\n",
);
