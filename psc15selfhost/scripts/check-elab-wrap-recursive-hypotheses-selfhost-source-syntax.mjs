import "./check-elab-recursor-minor-binders-selfhost-source-syntax.mjs";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(path.join(root, "packages/elab/src/Ps/Elab/Declaration.lean"), "utf8");
const start = source.indexOf("def psWrapRecursiveHypotheses\n");
const end = source.indexOf("\ndef psBuildInductiveMinorType\n", start + 1);
if (start < 0 || end < 0) {
  throw new Error("PSC2_ELAB_WRAP_RECURSIVE_HYPOTHESES_MISSING: declaration block");
}
const block = source.slice(start, end);
const required = [
  /\(fieldArgs : List PsExpr\)\s*\(indices : List Nat\)\s*\(body : PsExpr\)\s*:\s*Except PsElabError PsExpr :=\s*match indices with/,
  /\| List\.nil => Except\.ok body/,
  /\| List\.cons fieldIndex rest =>/,
  /psWrapRecursiveHypotheses\s+motiveId\s+fieldArgs\s+rest\s+body with/,
];
for (const pattern of required) {
  if (!pattern.test(block)) {
    throw new Error(`PSC2_ELAB_WRAP_RECURSIVE_HYPOTHESES_MISSING: ${pattern}`);
  }
}
if (/\|\s*\[\]\s*,|\|\s*fieldIndex\s*::\s*rest\s*,/.test(block)) {
  throw new Error("PSC2_ELAB_WRAP_RECURSIVE_HYPOTHESES_FORBIDDEN: multi-argument equations");
}
process.stdout.write("PSC2_ELAB_WRAP_RECURSIVE_HYPOTHESES: PASS (explicit index-list recursion with invariant body)\n");
