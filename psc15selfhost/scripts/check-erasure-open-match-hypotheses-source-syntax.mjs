import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

export function assertErasureOpenMatchHypothesesSourceSyntax(source) {
  const block = source.match(
    /^def psOpenMatchMinorHypotheses\b[\s\S]*?(?=^def psEraseMatchMinor\b)/m,
  )?.[0];
  if (!block) {
    throw new Error(
      "PSC2_ERASURE_OPEN_MATCH_HYPOTHESES_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
    );
  }
  const required = [
    /if psErasureBoolNot field\.recursive then/,
    /match psErasureFindMatchBinding field\.name bindings with/,
    /psLocalPushBinding[\s\S]*?binder;/,
    /let baseScope : PsErasureScope := \{[\s\S]*?currentDefinition := state\.scope\.currentDefinition\s*\};/,
    /erasedLocals :=\s*List\.cons pushed\.id state\.scope\.erasedLocals/,
    /runtimeExpressions :=\s*List\.cons\s*\(Prod\.mk\s*pushed\.id[\s\S]*?binding\.name\)\)\)\s*baseScope\.runtimeExpressions/,
    /currentDefinition := baseScope\.currentDefinition[\s\S]*?\};\s*smaller/,
  ];
  if (!required.every((pattern) => pattern.test(block))) {
    throw new Error(
      "PSC2_ERASURE_OPEN_MATCH_HYPOTHESES_SELFHOST_SOURCE_SYNTAX_MISSING: PSC1-safe recursive-hypothesis path",
    );
  }
  if (/!field\.recursive|==|state\.scope\.currentDefinition,/.test(block) ||
      /fun binding =>/.test(block) ||
      /pushed\.id\s*::\s*state\.scope\.erasedLocals/.test(block) ||
      /\(pushed\.id,[\s\S]*?\)\s*::\s*baseScope\.runtimeExpressions/.test(block)) {
    throw new Error(
      "PSC2_ERASURE_OPEN_MATCH_HYPOTHESES_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: unsupported prefix/lambda/cons syntax",
    );
  }
  return block;
}

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/erasure/src/Ps/Erasure/Expr.lean"),
  "utf8",
);
const block = assertErasureOpenMatchHypothesesSourceSyntax(source);
const mutations = [
  ["if psErasureBoolNot field.recursive then", "if !field.recursive then"],
  ["if psErasureBoolNot field.recursive then", "if field.recursive == false then"],
  ["match psErasureFindMatchBinding field.name bindings with", "match bindings.find? (fun binding => binding.field == field.name) with"],
  ["match recursiveParameterIndex with", "match state.scope.currentDefinition, recursiveParameterIndex with"],
  ["binder;", "binder"],
  ["currentDefinition := state.scope.currentDefinition\n                };",
   "currentDefinition := state.scope.currentDefinition\n                }"],
  ["List.cons pushed.id state.scope.erasedLocals",
   "pushed.id :: state.scope.erasedLocals"],
  ["List.cons\n                                (Prod.mk",
   "(pushed.id,"],
  ["baseScope.runtimeExpressions\n                          };", "baseScope.runtimeExpressions\n                          }"],
];
for (const [from, to] of mutations) {
  assert.ok(block.includes(from));
  const broken = block.replace(from, to);
  assert.throws(
    () => assertErasureOpenMatchHypothesesSourceSyntax(source.replace(block, broken)),
    /OPEN_MATCH_HYPOTHESES.*(?:MISSING|FORBIDDEN)/,
  );
}
process.stdout.write(
  "PSC2_ERASURE_OPEN_MATCH_HYPOTHESES_SELFHOST_SOURCE_SYNTAX: PASS (Bool test, structural lookup, unary matches, sequenced locals and explicit cons constructors)\n",
);
