import "./check-elab-binder-arguments-selfhost-source-syntax.mjs";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Declaration.lean"),
  "utf8",
);

const start = source.indexOf("def psElabStructuralRecursionFromSource\n");
const end = source.indexOf("\ndef psElabDeclarationTermCallback\n", start + 1);
if (start < 0 || end < 0) {
  throw new Error(
    "PSC2_ELAB_DECL_STRUCTURAL_RECURSION_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
  );
}

const block = source.slice(start, end);
const required = [
  /psElabExplicitParameterIds\s*\n\s*\(psElabTypedBinderListReverse bindersRev\)/,
];
for (const pattern of required) {
  if (!pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_DECL_STRUCTURAL_RECURSION_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const forbidden = [
  /bindersRev\.reverse/,
  /List\.reverse/,
];
for (const pattern of forbidden) {
  if (pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_DECL_STRUCTURAL_RECURSION_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ELAB_DECL_STRUCTURAL_RECURSION_SELFHOST_SOURCE_SYNTAX: PASS (existing PSC1-safe typed-binder reverse reused; generic List.reverse excluded)\n",
);