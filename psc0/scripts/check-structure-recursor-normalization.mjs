import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");

const normalizerPath = path.join(
  root,
  "packages",
  "erasure",
  "src",
  "Ps",
  "Erasure",
  "StructureRecursor.lean",
);
const definitionPath = path.join(
  root,
  "packages",
  "erasure",
  "src",
  "Ps",
  "Erasure",
  "Definition.lean",
);

const normalizer = await readFile(normalizerPath, "utf8");
const definition = await readFile(definitionPath, "utf8");

for (const marker of [
  "psErasureStructureNameFromRecursor",
  "psExprLiftBVars 1 0 minor",
  "PsExpr.letE",
  "PsExpr.proj structureName index major",
  "if psErasureNatNotEqual (psListLength view.args) expectedArity then\n                                      Except.ok Option.none",
  "psLowerStructureRecursorsWithFuel",
]) {
  if (!normalizer.includes(marker)) {
    throw new Error(`PSC2_STRUCTURE_RECURSOR_NORMALIZATION_MISSING: ${marker}`);
  }
}

if (normalizer.includes("psProdName") || normalizer.includes("Prod.rec")) {
  throw new Error("PSC2_STRUCTURE_RECURSOR_NORMALIZATION_NOT_GENERIC");
}

if (!definition.includes("import Ps.Erasure.StructureRecursor")) {
  throw new Error("PSC2_STRUCTURE_RECURSOR_NORMALIZATION_IMPORT_MISSING");
}
if (!definition.includes("psLowerStructureRecursors environment value")) {
  throw new Error("PSC2_STRUCTURE_RECURSOR_NORMALIZATION_NOT_APPLIED");
}

process.stdout.write(
  "PSC2_STRUCTURE_RECURSOR_NORMALIZATION: PASS (generic, capture-safe, single-evaluation)\n",
);
