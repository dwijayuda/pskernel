import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

export function assertErasureRecursiveCallArgumentsSourceSyntax(source) {
  const block = source.match(
    /^def psErasureRecursiveCallArguments\b[\s\S]*?(?=^structure PsOpenMatchHypotheses\b)/m,
  )?.[0];
  if (!block) {
    throw new Error(
      "PSC2_ERASURE_RECURSIVE_CALL_ARGUMENTS_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
    );
  }
  if (
    (block.match(/List\.cons \(/g) ?? []).length !== 2 ||
    !block.includes("(psErasureRuntimeVariables rest)")
  ) {
    throw new Error(
      "PSC2_ERASURE_RECURSIVE_CALL_ARGUMENTS_SELFHOST_SOURCE_SYNTAX_MISSING: explicit cons and structural variable mapping",
    );
  }
  if (/PsVerifiedIrExpr\.var (?:recursiveName|name)\s*::/.test(block) ||
      /fun name =>/.test(block)) {
    throw new Error(
      "PSC2_ERASURE_RECURSIVE_CALL_ARGUMENTS_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: term-level cons or untyped lambda",
    );
  }
  return block;
}

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/erasure/src/Ps/Erasure/Expr.lean"),
  "utf8",
);
const block = assertErasureRecursiveCallArgumentsSourceSyntax(source);
const mutations = [
  ["List.cons (PsVerifiedIrExpr.var recursiveName)",
   "PsVerifiedIrExpr.var recursiveName ::"],
  ["List.cons (PsVerifiedIrExpr.var name)",
   "PsVerifiedIrExpr.var name ::"],
  ["(psErasureRuntimeVariables rest)", "(rest.map PsVerifiedIrExpr.var)"],
];
for (const [from, to] of mutations) {
  assert.ok(block.includes(from));
  const broken = block.replace(from, to);
  assert.throws(
    () => assertErasureRecursiveCallArgumentsSourceSyntax(source.replace(block, broken)),
    /RECURSIVE_CALL_ARGUMENTS.*(?:MISSING|FORBIDDEN)/,
  );
}
process.stdout.write(
  "PSC2_ERASURE_RECURSIVE_CALL_ARGUMENTS_SELFHOST_SOURCE_SYNTAX: PASS (two explicit cons sites and structural variable mapping)\n",
);
