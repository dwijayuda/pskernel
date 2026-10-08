import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Declaration.lean"),
  "utf8",
);
const start = source.indexOf("def psElabStructuralRecursionFromSource\n");
const end = source.indexOf("\ndef psElabDeclarationTermCallback\n", start + 1);
if (start < 0 || end < 0) {
  throw new Error("PSC2_ELAB_STRUCTURAL_RECURSION_SOURCE_MISSING: declaration block");
}

const block = source.slice(start, end);
// Parameter IDs must stay in source order. The generic .reverse projection is
// outside the bootstrap language; use the existing monomorphic binder helper.
if (!/psElabExplicitParameterIds\s*\(psElabTypedBinderListReverse\s+bindersRev\)/.test(block)) {
  throw new Error(
    "PSC2_ELAB_STRUCTURAL_RECURSION_SOURCE_MISSING: explicit parameter IDs in source order via typed binder reverse",
  );
}
if (/\bbindersRev\s*\.\s*reverse\b|\bList\.reverse\b/.test(block)) {
  throw new Error("PSC2_ELAB_STRUCTURAL_RECURSION_SOURCE_FORBIDDEN: generic reverse");
}

process.stdout.write(
  "PSC2_ELAB_STRUCTURAL_RECURSION_SOURCE: PASS (source-order parameter IDs through typed binder reverse)\n",
);
