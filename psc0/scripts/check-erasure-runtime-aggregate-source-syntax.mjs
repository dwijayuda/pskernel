import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

function block(source, start, end) {
  return source.match(new RegExp(
    `^def ${start}\\b[\\s\\S]*?(?=^def ${end}\\b)`,
    "m",
  ))?.[0];
}

export function assertErasureRuntimeAggregateSourceSyntax(source) {
  const structureFields = block(
    source,
    "psEraseRuntimeStructureFields",
    "psEraseRuntimeStructureApplication",
  );
  const structureApp = block(
    source,
    "psEraseRuntimeStructureApplication",
    "psEraseRuntimeConstructorFields",
  );
  const constructorFields = block(
    source,
    "psEraseRuntimeConstructorFields",
    "psEraseRuntimeConstructorApplication",
  );
  const constructorApp = block(
    source,
    "psEraseRuntimeConstructorApplication",
    "psOpenMatchMinorFields",
  );
  if (!structureFields || !structureApp || !constructorFields || !constructorApp) {
    throw new Error(
      "PSC2_ERASURE_RUNTIME_AGGREGATE_SELFHOST_SOURCE_SYNTAX_MISSING: declaration blocks",
    );
  }

  for (const fields of [structureFields, constructorFields]) {
    if (
      !fields.includes("match psErasureExprListAt arguments field.sourceIndex with") ||
      !fields.includes("(List.cons (Prod.mk field.name value) fieldsRev)")
    ) {
      throw new Error(
        "PSC2_ERASURE_RUNTIME_AGGREGATE_SELFHOST_SOURCE_SYNTAX_MISSING: structural field lookup and pair cons",
      );
    }
    if (/arguments\s*\[\s*field\.sourceIndex\s*\]\?/.test(fields) ||
        /\(\(field\.name, value\)\s*::\s*fieldsRev\)/.test(fields)) {
      throw new Error(
        "PSC2_ERASURE_RUNTIME_AGGREGATE_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: optional index or tuple-cons syntax",
      );
    }
  }

  if (
    !/Nat\.add structureInfo\.numParams \(psListLength structureInfo\.fields\);\s*if psErasureBoolNot \(Nat\.beq \(psListLength view\.args\) expectedArity\) then/.test(structureApp) ||
    !/Nat\.add ctorInfo\.numParams \(psListLength ctorInfo\.fields\);\s*if psErasureBoolNot \(Nat\.beq \(psListLength view\.args\) expectedArity\) then/.test(constructorApp)
  ) {
    throw new Error(
      "PSC2_ERASURE_RUNTIME_AGGREGATE_SELFHOST_SOURCE_SYNTAX_MISSING: sequenced expected arity",
    );
  }

  return { structureFields, structureApp, constructorFields, constructorApp };
}

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/erasure/src/Ps/Erasure/Expr.lean"),
  "utf8",
);
const blocks = assertErasureRuntimeAggregateSourceSyntax(source);

const mutations = [
  [
    blocks.structureFields,
    "match psErasureExprListAt arguments field.sourceIndex with",
    "match arguments[field.sourceIndex]? with",
  ],
  [
    blocks.constructorFields,
    "(List.cons (Prod.mk field.name value) fieldsRev)",
    "((field.name, value) :: fieldsRev)",
  ],
  [
    blocks.structureApp,
    "Nat.add structureInfo.numParams (psListLength structureInfo.fields);",
    "Nat.add structureInfo.numParams (psListLength structureInfo.fields)",
  ],
  [
    blocks.constructorApp,
    "Nat.add ctorInfo.numParams (psListLength ctorInfo.fields);",
    "Nat.add ctorInfo.numParams (psListLength ctorInfo.fields)",
  ],
];
for (const [currentBlock, from, to] of mutations) {
  assert.ok(currentBlock.includes(from));
  const broken = currentBlock.replace(from, to);
  assert.throws(
    () => assertErasureRuntimeAggregateSourceSyntax(source.replace(currentBlock, broken)),
    /RUNTIME_AGGREGATE.*(?:MISSING|FORBIDDEN)/,
  );
}
process.stdout.write(
  "PSC2_ERASURE_RUNTIME_AGGREGATE_SELFHOST_SOURCE_SYNTAX: PASS (structure/constructor field lookup, pair cons and expected-arity sequencing)\n",
);
