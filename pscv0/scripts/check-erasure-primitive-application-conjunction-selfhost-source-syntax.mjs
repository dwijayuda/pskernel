import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

export function assertErasurePrimitiveApplicationConjunction(source) {
  const helper = source.match(
    /^def psErasureBoolAnd\b[\s\S]*?(?=^def psErasePrimitiveApplication\b)/m,
  )?.[0];
  const block = source.match(
    /^def psErasePrimitiveApplication\b[\s\S]*?(?=^def psEraseCondition\b)/m,
  )?.[0];
  if (
    !helper ||
    !/\(left : Bool\)\s*\(right : Bool\) : Bool :=\s*if left then right else false/.test(helper)
  ) {
    throw new Error(
      "PSC2_ERASURE_PRIMITIVE_APPLICATION_CONJUNCTION_SELFHOST_SOURCE_SYNTAX_MISSING: structural Bool conjunction helper",
    );
  }
  if (!block) {
    throw new Error(
      "PSC2_ERASURE_PRIMITIVE_APPLICATION_CONJUNCTION_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
    );
  }
  const uses = block.match(/psErasureBoolAnd \(psStringEq text "Array\.[^"]+"\) \(Nat\.beq \(psListLength view\.args\) [0-9]+\)/g) ?? [];
  if (uses.length !== 9) {
    throw new Error(
      "PSC2_ERASURE_PRIMITIVE_APPLICATION_CONJUNCTION_SELFHOST_SOURCE_SYNTAX_MISSING: nine explicit array conjunctions",
    );
  }
  if (/&&/.test(block)) {
    throw new Error(
      "PSC2_ERASURE_PRIMITIVE_APPLICATION_CONJUNCTION_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: conjunction operator",
    );
  }
  return { helper, block };
}

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/erasure/src/Ps/Erasure/Expr.lean"),
  "utf8",
);
const { block } = assertErasurePrimitiveApplicationConjunction(source);
const current =
  'psErasureBoolAnd (psStringEq text "Array.emptyWithCapacity") (Nat.beq (psListLength view.args) 2)';
assert.ok(block.includes(current));
const broken = block.replace(
  current,
  'psStringEq text "Array.emptyWithCapacity" && Nat.beq (psListLength view.args) 2',
);
assert.throws(
  () => assertErasurePrimitiveApplicationConjunction(source.replace(block, broken)),
  /PRIMITIVE_APPLICATION_CONJUNCTION.*(?:MISSING|FORBIDDEN)/,
);
process.stdout.write(
  "PSC2_ERASURE_PRIMITIVE_APPLICATION_CONJUNCTION_SELFHOST_SOURCE_SYNTAX: PASS (structural Bool helper; nine array conjunctions; operator mutation rejected)\n",
);
