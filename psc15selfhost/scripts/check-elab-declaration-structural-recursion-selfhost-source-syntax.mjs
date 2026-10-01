import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Declaration.lean"),
  "utf8",
);

const helperStart = source.indexOf("def psElabReverseTypedBindersAcc\n");
const helperEnd = source.indexOf("\ndef psElabStructuralRecursionFromSource\n", helperStart + 1);
if (helperStart < 0 || helperEnd < 0) {
  throw new Error(
    "PSC2_ELAB_DECL_STRUCTURAL_RECURSION_SELFHOST_SOURCE_SYNTAX_MISSING: typed-binder reverse helper",
  );
}

const helper = source.slice(helperStart, helperEnd);
const helperRequired = [
  /\(binders\s*:\s*List PsElabTypedBinder\)\s*:\s*\n\s*List PsElabTypedBinder\s*->\s*List PsElabTypedBinder\s*:=/,
  /match\s+binders\s+with/,
  /\| List\.nil =>\s*fun \(acc\s*:\s*List PsElabTypedBinder\) => acc/,
  /psElabReverseTypedBindersAcc\s+rest\s*;/,
  /smaller \(List\.cons binder acc\)/,
  /def psElabReverseTypedBinders\s*\n\s*\(binders\s*:\s*List PsElabTypedBinder\)\s*:\s*List PsElabTypedBinder\s*:=\s*\n\s*psElabReverseTypedBindersAcc binders List\.nil/,
];
for (const pattern of helperRequired) {
  if (!pattern.test(helper)) {
    throw new Error(
      `PSC2_ELAB_DECL_STRUCTURAL_RECURSION_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const start = source.indexOf("def psElabStructuralRecursionFromSource\n");
const end = source.indexOf("\ndef psElabDeclarationTermCallback\n", start + 1);
if (start < 0 || end < 0) {
  throw new Error(
    "PSC2_ELAB_DECL_STRUCTURAL_RECURSION_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
  );
}
const block = source.slice(start, end);
if (!/psElabExplicitParameterIds\s*\n\s*\(psElabReverseTypedBinders bindersRev\)/.test(block)) {
  throw new Error(
    "PSC2_ELAB_DECL_STRUCTURAL_RECURSION_SELFHOST_SOURCE_SYNTAX_MISSING: local typed-binder reverse call",
  );
}
if (/bindersRev\.reverse/.test(block) || /List\.reverse/.test(block)) {
  throw new Error(
    "PSC2_ELAB_DECL_STRUCTURAL_RECURSION_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: generic List reverse",
  );
}

process.stdout.write(
  "PSC2_ELAB_DECL_STRUCTURAL_RECURSION_SELFHOST_SOURCE_SYNTAX: PASS (project-owned typed-binder reverse; generic List.reverse excluded)\n",
);
