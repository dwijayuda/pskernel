import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

export function assertErasureMatchMinorSequencing(source) {
  const block = source.match(
    /^def psEraseMatchMinor\b[\s\S]*?(?=^def psEraseMatchAlternativesWorker\b)/m,
  )?.[0];
  if (
    !block ||
    !/let bindings := \(psListReverse opened\.bindingsRev\);\s*match\s+psOpenMatchMinorHypotheses/.test(block)
  ) {
    throw new Error(
      "PSC2_ERASURE_MATCH_MINOR_SEQUENCING_SELFHOST_SOURCE_SYNTAX_MISSING: sequenced bindings",
    );
  }
  return block;
}

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/erasure/src/Ps/Erasure/Expr.lean"),
  "utf8",
);
const block = assertErasureMatchMinorSequencing(source);
const protectedText = "let bindings := (psListReverse opened.bindingsRev);";
assert.ok(block.includes(protectedText));
const broken = block.replace(protectedText, protectedText.replace(";", ""));
assert.throws(
  () => assertErasureMatchMinorSequencing(source.replace(block, broken)),
  /MATCH_MINOR_SEQUENCING.*MISSING/,
);
process.stdout.write(
  "PSC2_ERASURE_MATCH_MINOR_SEQUENCING_SELFHOST_SOURCE_SYNTAX: PASS (sequenced bindings; missing-terminator mutation check)\n",
);
