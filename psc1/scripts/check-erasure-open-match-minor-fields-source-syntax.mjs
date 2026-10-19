import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

export function assertErasureOpenMatchMinorFieldsSourceSyntax(source) {
  const block = source.match(
    /^def psOpenMatchMinorFields\b[\s\S]*?(?=^def psErasureFindStringIndex\b)/m,
  )?.[0];
  if (!block) {
    throw new Error(
      "PSC2_ERASURE_OPEN_MATCH_MINOR_FIELDS_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
    );
  }
  const required = [
    /psErasureLocalName state\.scope[\s\S]*?field\.name state\.scope\.localContext\.nextId;/,
    /psLocalPushBinding[\s\S]*?binder;/,
    /let nextScope : PsErasureScope := \{[\s\S]*?currentDefinition := state\.scope\.currentDefinition\s*\};/,
    /runtimeLocals :=\s*List\.cons\s*\(Prod\.mk pushed\.id bindingName\)\s*state\.scope\.runtimeLocals/,
    /bindingsRev :=\s*List\.cons\s*\(PsVerifiedIrMatchBinding\.mk[\s\S]*?field\.type\)\)\s*state\.bindingsRev/,
  ];
  if (!required.every((pattern) => pattern.test(block))) {
    throw new Error(
      "PSC2_ERASURE_OPEN_MATCH_MINOR_FIELDS_SELFHOST_SOURCE_SYNTAX_MISSING: sequenced locals and explicit cons constructors",
    );
  }
  if (/\(pushed\.id, bindingName\)\s*::/.test(block) ||
      /\}\s*::\s*state\.bindingsRev/.test(block)) {
    throw new Error(
      "PSC2_ERASURE_OPEN_MATCH_MINOR_FIELDS_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: tuple or term-level cons",
    );
  }
  return block;
}

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/erasure/src/Ps/Erasure/Expr.lean"),
  "utf8",
);
const block = assertErasureOpenMatchMinorFieldsSourceSyntax(source);
const mutations = [
  ["field.name state.scope.localContext.nextId;", "field.name state.scope.localContext.nextId"],
  ["binder;", "binder"],
  ["currentDefinition := state.scope.currentDefinition\n              };",
   "currentDefinition := state.scope.currentDefinition\n              }"],
  ["List.cons\n                    (Prod.mk pushed.id bindingName)\n                    state.scope.runtimeLocals",
   "(pushed.id, bindingName) ::\n                    state.scope.runtimeLocals"],
  ["List.cons\n                      (PsVerifiedIrMatchBinding.mk",
   "{\n                    field := field.name"],
];
for (const [from, to] of mutations) {
  assert.ok(block.includes(from));
  const broken = block.replace(from, to);
  assert.throws(
    () => assertErasureOpenMatchMinorFieldsSourceSyntax(source.replace(block, broken)),
    /OPEN_MATCH_MINOR_FIELDS.*(?:MISSING|FORBIDDEN)/,
  );
}
process.stdout.write(
  "PSC2_ERASURE_OPEN_MATCH_MINOR_FIELDS_SELFHOST_SOURCE_SYNTAX: PASS (three sequenced locals, explicit runtime pair cons and match-binding cons)\n",
);
