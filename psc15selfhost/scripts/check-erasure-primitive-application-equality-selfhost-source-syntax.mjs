import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

export function assertErasurePrimitiveApplicationEquality(source) {
  const block = source.match(
    /^def psErasePrimitiveApplication\b[\s\S]*?(?=^def psEraseCondition\b)/m,
  )?.[0];
  if (!block) {
    throw new Error(
      "PSC2_ERASURE_PRIMITIVE_APPLICATION_EQUALITY_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
    );
  }
  const natChecks = block.match(/Nat\.beq \(psListLength view\.args\)/g) ?? [];
  const stringChecks = block.match(/psStringEq text/g) ?? [];
  if (natChecks.length !== 22 || stringChecks.length !== 43) {
    throw new Error(
      "PSC2_ERASURE_PRIMITIVE_APPLICATION_EQUALITY_SELFHOST_SOURCE_SYNTAX_MISSING: explicit Nat/String equality checks",
    );
  }
  if (/==/.test(block)) {
    throw new Error(
      "PSC2_ERASURE_PRIMITIVE_APPLICATION_EQUALITY_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: equality operator",
    );
  }
  return block;
}

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/erasure/src/Ps/Erasure/Expr.lean"),
  "utf8",
);
const block = assertErasurePrimitiveApplicationEquality(source);

for (const [from, to] of [
  ["Nat.beq (psListLength view.args) 2", "(psListLength view.args) == 2"],
  ["psStringEq text \"Int.ofNat\"", "text == \"Int.ofNat\""],
]) {
  assert.ok(block.includes(from));
  const broken = block.replace(from, to);
  assert.throws(
    () => assertErasurePrimitiveApplicationEquality(source.replace(block, broken)),
    /PRIMITIVE_APPLICATION_EQUALITY.*(?:MISSING|FORBIDDEN)/,
  );
}

process.stdout.write(
  "PSC2_ERASURE_PRIMITIVE_APPLICATION_EQUALITY_SELFHOST_SOURCE_SYNTAX: PASS (22 Nat.beq length checks, 43 psStringEq name checks; equality-operator mutations rejected)\n",
);
