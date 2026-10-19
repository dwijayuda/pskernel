import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

export function assertErasureExprOperators(source) {
  for (const [name, pattern] of [
    [
      "and",
      /def psErasureBoolAnd[\s\S]*?if left then right else false/,
    ],
    [
      "or",
      /def psErasureBoolOr[\s\S]*?if left then true else right/,
    ],
    [
      "not",
      /def psErasureBoolNot[\s\S]*?if value then false else true/,
    ],
  ]) {
    if (!pattern.test(source)) {
      throw new Error(
        `PSC2_ERASURE_EXPR_OPERATORS_SELFHOST_SOURCE_SYNTAX_MISSING: structural Bool ${name} helper`,
      );
    }
  }

  const required = [
    "psStringEq key name",
    "psStringEq value target",
    "psErasureBoolNot field.recursive",
    "psStringEq binding.field fieldName",
    "psErasureBoolOr",
    "(Nat.beq ctorInfo.numParams 0)",
    "Nat.beq field.projectionIndex index",
    "(psStringEq ownerName structureInfo.name)",
    "(psListLength structureInfo.typeParameters))",
  ];
  for (const text of required) {
    if (!source.includes(text)) {
      throw new Error(
        `PSC2_ERASURE_EXPR_OPERATORS_SELFHOST_SOURCE_SYNTAX_MISSING: ${text}`,
      );
    }
  }

  if (/==|&&|\|\|/.test(source)) {
    throw new Error(
      "PSC2_ERASURE_EXPR_OPERATORS_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: unsupported equality/boolean operator",
    );
  }
}

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/erasure/src/Ps/Erasure/Expr.lean"),
  "utf8",
);
assertErasureExprOperators(source);

for (const [from, to] of [
  ["psStringEq value target", "value == target"],
  [
    "psErasureBoolAnd\n                    (Nat.beq ctorInfo.numParams 0)\n                    (psListIsEmpty ctorInfo.fields)",
    "Nat.beq ctorInfo.numParams 0 && (psListIsEmpty ctorInfo.fields)",
  ],
  [
    "psErasureBoolOr\n                        (psErasureNatInList scope.erasedLocals id)",
    "psErasureNatInList scope.erasedLocals id ||",
  ],
]) {
  assert.ok(source.includes(from));
  const broken = source.replace(from, to);
  assert.throws(
    () => assertErasureExprOperators(broken),
    /ERASURE_EXPR_OPERATORS.*(?:MISSING|FORBIDDEN)/,
  );
}

process.stdout.write(
  "PSC2_ERASURE_EXPR_OPERATORS_SELFHOST_SOURCE_SYNTAX: PASS (structural Bool helpers; String/Nat equality; unsupported operator mutations rejected)\n",
);
