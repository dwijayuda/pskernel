import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

export function assertErasureInductiveParametersSource(source) {
  const block = source.match(
    /^def psPrepareInductiveParametersWithFuel\b[\s\S]*?(?=^def psPrepareInductiveParameters\b)/m,
  )?.[0];
  if (!block) {
    throw new Error(
      "PSC2_ERASURE_INDUCTIVE_PARAMETERS_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
    );
  }
  const required = [
    "                  binder;",
    'String.Internal.append "T" (psNatToString index);',
    "let value := PsExpr.fvar pushed.id;",
    "List.cons (Prod.mk pushed.id parameterName) scope.typeLocals",
    "List.cons pushed.id scope.erasedLocals",
    "List.cons value valuesRev",
    "PsVerifiedIrTypeParameter.mk parameterName",
    "currentDefinition := scope.currentDefinition\n                  };",
  ];
  for (const text of required) {
    if (!block.includes(text)) {
      throw new Error(
        `PSC2_ERASURE_INDUCTIVE_PARAMETERS_SELFHOST_SOURCE_SYNTAX_MISSING: ${text}`,
      );
    }
  }
  if (/\+\+|::|\(pushed\.id,\s*parameterName\)|\{\s*name := parameterName\s*\}/.test(block)) {
    throw new Error(
      "PSC2_ERASURE_INDUCTIVE_PARAMETERS_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: bootstrap-incompatible term syntax",
    );
  }
  return block;
}

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/erasure/src/Ps/Erasure/Inductive.lean"),
  "utf8",
);
const block = assertErasureInductiveParametersSource(source);
const terminators = [
  "                  binder;",
  'let parameterName := String.Internal.append "T" (psNatToString index);',
  "let value := PsExpr.fvar pushed.id;",
  "currentDefinition := scope.currentDefinition\n                  };",
];
for (const current of terminators) {
  assert.ok(block.includes(current));
  const broken = block.replace(current, current.replace(";", ""));
  assert.throws(
    () => assertErasureInductiveParametersSource(source.replace(block, broken)),
    /INDUCTIVE_PARAMETERS.*MISSING/,
  );
}
process.stdout.write(
  "PSC2_ERASURE_INDUCTIVE_PARAMETERS_SELFHOST_SOURCE_SYNTAX: PASS (sequenced locals; explicit append, Prod/IR constructors and List.cons)\n",
);
