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
  for (const branch of [mk, byteIdx]) {
    const start = block.indexOf(branch);
    const end = block.indexOf("\n      else if", start + branch.length);
    const body = block.slice(start + branch.length, end);
    if (!/^\s*match view\.args with\s*\| List\.cons value rest =>\s*match rest with\s*\| List\.nil =>\s*match erase value with\s*\| Except\.error error => Except\.error error\s*\| Except\.ok result => Except\.ok \(Option\.some result\)\s*\| List\.cons _ _ =>\s*Except\.error PsErasureError\.unsupportedApplication\s*\| _ =>\s*Except\.error PsErasureError\.unsupportedApplication\s*$/.test(body)) {
      throw new Error(
        `PSC2_ERASURE_PRIMITIVE_APPLICATION_DISJUNCTION_SELFHOST_SOURCE_SYNTAX_MISSING: flat singleton matches and arity rejection for ${branch}`,
      );
    }
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
for (const name of ["String.Pos.Raw.mk", "String.Pos.Raw.byteIdx"]) {
  const start = block.indexOf(`else if psStringEq text "${name}" then`);
  const end = block.indexOf("\n      else if", start + 1);
  const branch = block.slice(start, end);
  for (const [from, to] of [
    ["List.cons value rest", "value :: []"],
    ["List.cons value rest", "[value]"],
    ["List.nil =>", "_ =>"],
    ["Except.error error => Except.error error", "Except.error error => Except.ok none"],
    ["| List.cons _ _ =>\n                Except.error PsErasureError.unsupportedApplication",
     "| List.cons _ _ =>\n                Except.ok none"],
    ["| _ =>\n            Except.error PsErasureError.unsupportedApplication",
     "| _ =>\n            Except.ok none"],
  ]) {
    assert.ok(branch.includes(from));
    const mutated = block.replace(branch, branch.replace(from, to));
    assert.throws(
      () => assertErasurePrimitiveApplicationDisjunction(source.replace(block, mutated)),
      /PRIMITIVE_APPLICATION_DISJUNCTION.*MISSING/,
    );
  }
}
process.stdout.write(
  "PSC2_ERASURE_PRIMITIVE_APPLICATION_DISJUNCTION_SELFHOST_SOURCE_SYNTAX: PASS (String.Pos.Raw cases split; flat singleton matches; syntax, arity and error-propagation mutations rejected)\n",
);
