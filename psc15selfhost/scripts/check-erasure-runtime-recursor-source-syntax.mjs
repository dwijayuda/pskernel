import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

export function assertErasureRuntimeRecursorSourceSyntax(source) {
  const block = source.match(
    /^def psEraseRuntimeRecursorApplication\b[\s\S]*?(?=^def psEraseRuntimeExprWithFuel\b)/m,
  )?.[0];
  if (!block) {
    throw new Error(
      "PSC2_ERASURE_RUNTIME_RECURSOR_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
    );
  }
  const required = [
    /inductiveInfo\.constructors\.length \+\s*1;\s*if view\.args\.length != expectedArity then/,
    /fun \(entry :\s*PsVerifiedIrTypeParameter × PsVerifiedIrType\) =>\s*Prod\.mk entry\.1\.name entry\.2/,
    /let minorStart := inductiveInfo\.numParams \+ 1;/,
    /let majorIndex := expectedArity - 1;/,
    /match psErasureExprListAt view\.args majorIndex with/,
    /\| _, _ => none;\s*match\s+psEraseMatchAlternatives/,
  ];
  if (!required.every((pattern) => pattern.test(block))) {
    throw new Error(
      "PSC2_ERASURE_RUNTIME_RECURSOR_SELFHOST_SOURCE_SYNTAX_MISSING: PSC1-safe recursor locals",
    );
  }
  if (/fun entry =>/.test(block) ||
      /\(entry\.1\.name, entry\.2\)/.test(block) ||
      /view\.args\s*\[\s*majorIndex\s*\]\?/.test(block)) {
    throw new Error(
      "PSC2_ERASURE_RUNTIME_RECURSOR_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: untyped lambda, tuple constructor or optional index",
    );
  }
  return block;
}

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/erasure/src/Ps/Erasure/Expr.lean"),
  "utf8",
);
const block = assertErasureRuntimeRecursorSourceSyntax(source);
const mutations = [
  ["1;\n          if view.args.length", "1\n          if view.args.length"],
  ["fun (entry :\n                            PsVerifiedIrTypeParameter × PsVerifiedIrType) =>",
   "fun entry =>"],
  ["Prod.mk entry.1.name entry.2", "(entry.1.name, entry.2)"],
  ["let minorStart := inductiveInfo.numParams + 1;", "let minorStart := inductiveInfo.numParams + 1"],
  ["let majorIndex := expectedArity - 1;", "let majorIndex := expectedArity - 1"],
  ["match psErasureExprListAt view.args majorIndex with", "match view.args[majorIndex]? with"],
  ["| _, _ => none;", "| _, _ => none"],
];
for (const [from, to] of mutations) {
  assert.ok(block.includes(from));
  const broken = block.replace(from, to);
  assert.throws(
    () => assertErasureRuntimeRecursorSourceSyntax(source.replace(block, broken)),
    /RUNTIME_RECURSOR.*(?:MISSING|FORBIDDEN)/,
  );
}
process.stdout.write(
  "PSC2_ERASURE_RUNTIME_RECURSOR_SELFHOST_SOURCE_SYNTAX: PASS (sequenced locals, typed substitution lambda, explicit Prod and structural major lookup)\n",
);
