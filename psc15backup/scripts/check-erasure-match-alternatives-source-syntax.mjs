import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

export function assertErasureMatchAlternativesSourceSyntax(source) {
  const block = source.match(
    /^def psEraseMatchAlternativesWorker\b[\s\S]*?(?=^def psEraseRuntimeRecursorApplication\b)/m,
  )?.[0];
  if (!block) {
    throw new Error(
      "PSC2_ERASURE_MATCH_ALTERNATIVES_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
    );
  }
  if (
    !block.includes("match psErasureExprListAt arguments (Nat.add minorStart index) with") ||
    !/List\.cons\s*\(Prod\.mk\s*alternative\.constructorName\s*\(Prod\.mk\s*alternative\.bindings\s*alternative\.body\)\)\s*alternativesRev/.test(block)
  ) {
    throw new Error(
      "PSC2_ERASURE_MATCH_ALTERNATIVES_SELFHOST_SOURCE_SYNTAX_MISSING: structural minor lookup and nested Prod cons",
    );
  }
  if (/arguments\s*\[\s*minorStart \+ index\s*\]\?/.test(block) ||
      /\(\(alternative\.constructorName,[\s\S]*?\)\s*::\s*alternativesRev\)/.test(block)) {
    throw new Error(
      "PSC2_ERASURE_MATCH_ALTERNATIVES_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: optional index or tuple-cons syntax",
    );
  }
  return block;
}

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/erasure/src/Ps/Erasure/Expr.lean"),
  "utf8",
);
const block = assertErasureMatchAlternativesSourceSyntax(source);
const mutations = [
  [
    "match psErasureExprListAt arguments (Nat.add minorStart index) with",
    "match arguments[minorStart + index]? with",
  ],
  [
    "List.cons\n                  (Prod.mk",
    "((alternative.constructorName,",
  ],
];
for (const [from, to] of mutations) {
  assert.ok(block.includes(from));
  const broken = block.replace(from, to);
  assert.throws(
    () => assertErasureMatchAlternativesSourceSyntax(source.replace(block, broken)),
    /MATCH_ALTERNATIVES.*(?:MISSING|FORBIDDEN)/,
  );
}
process.stdout.write(
  "PSC2_ERASURE_MATCH_ALTERNATIVES_SELFHOST_SOURCE_SYNTAX: PASS (structural minor lookup and nested Prod alternative cons)\n",
);
