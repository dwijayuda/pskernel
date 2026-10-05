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

  const lengthUses =
    block.match(/psListLength view\.args/g) ?? [];
  const natChecks =
    block.match(/Nat\.beq\s*\(psListLength view\.args\)/g) ?? [];
  if (lengthUses.length === 0 || natChecks.length !== lengthUses.length) {
    throw new Error(
      "PSC2_ERASURE_PRIMITIVE_APPLICATION_EQUALITY_SELFHOST_SOURCE_SYNTAX_MISSING: explicit Nat.beq argument-length checks",
    );
  }

  const withoutTextBinding = block.replace(
    /let text := psNameToString name;/g,
    "",
  );
  const withoutExplicitStringChecks =
    withoutTextBinding.replace(/psStringEq text/g, "");
  if (
    !/psStringEq text/g.test(block) ||
    /\btext\b/.test(withoutExplicitStringChecks)
  ) {
    throw new Error(
      "PSC2_ERASURE_PRIMITIVE_APPLICATION_EQUALITY_SELFHOST_SOURCE_SYNTAX_MISSING: explicit psStringEq name checks",
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
  ["psStringEq text \"UInt8.ofNat\"", "text == \"UInt8.ofNat\""],
]) {
  assert.ok(block.includes(from));
  const broken = block.replace(from, to);
  assert.throws(
    () => assertErasurePrimitiveApplicationEquality(source.replace(block, broken)),
    /PRIMITIVE_APPLICATION_EQUALITY.*(?:MISSING|FORBIDDEN)/,
  );
}

process.stdout.write(
  "PSC2_ERASURE_PRIMITIVE_APPLICATION_EQUALITY_SELFHOST_SOURCE_SYNTAX: PASS (all argument-length checks use Nat.beq; all primitive-name checks use psStringEq; equality-operator mutations rejected)\n",
);
