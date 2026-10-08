import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

export function assertErasureRuntimeRecursorSourceSyntax(source) {
  const block = source.match(
    /^def psEraseRuntimeRecursorApplication\b[\s\S]*?(?=^def psEraseRuntimeExprWithFuelWorker\b)/m,
  )?.[0];
  if (!block) {
    throw new Error(
      "PSC2_ERASURE_RUNTIME_RECURSOR_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
    );
  }
  const required = [
    /Nat\.add\s*\(Nat\.add \(Nat\.add inductiveInfo\.numParams 1\)\s*\(psListLength inductiveInfo\.constructors\)\)\s*1;\s*if psErasureBoolNot \(Nat\.beq \(psListLength view\.args\) expectedArity\) then/,
    /fun \(entry : PsVerifiedIrTypeParameter × PsVerifiedIrType\) =>\s*match entry with\s*\| Prod\.mk parameter value => Prod\.mk parameter\.name value;/,
    /let minorStart := Nat\.add inductiveInfo\.numParams 1;/,
    /let majorIndex := Nat\.sub expectedArity 1;/,
    /match psErasureExprListAt view\.args majorIndex with/,
    /match scope\.currentDefinition with\s*\| Option\.none => Option\.none\s*\| Option\.some current =>\s*match scrutinee with/,
    /\| _ => Option\.none;\s*match\s+psEraseMatchAlternatives/,
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
  ["1;\n          if psErasureBoolNot", "1\n          if psErasureBoolNot"],
  ["fun (entry : PsVerifiedIrTypeParameter × PsVerifiedIrType) =>",
   "fun entry =>"],
  ["Prod.mk parameter.name value", "(parameter.name, value)"],
  ["let minorStart := Nat.add inductiveInfo.numParams 1;", "let minorStart := Nat.add inductiveInfo.numParams 1"],
  ["let majorIndex := Nat.sub expectedArity 1;", "let majorIndex := Nat.sub expectedArity 1"],
  ["match psErasureExprListAt view.args majorIndex with", "match view.args[majorIndex]? with"],
  ["| _ => Option.none;", "| _ => Option.none"],
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
