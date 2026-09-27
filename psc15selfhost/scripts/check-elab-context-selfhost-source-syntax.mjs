import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Context.lean"),
  "utf8",
);

const required = [
  /structure PsElabContext where\s*environment : PsEnvironment\s*localContext : PsLocalContext\s*instances : PsInstanceIndex\s*metaContext : PsMetaContext\s*structuralRecursion : Option PsElabStructuralRecursion(?:\s|$)/,
  /def psElabContextEmpty[\s\S]*structuralRecursion := none/,
];

for (const pattern of required) {
  if (!pattern.test(source)) {
    throw new Error(`PSC2_ELAB_CONTEXT_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`);
  }
}

const forbidden = [
  /structuralRecursion : Option PsElabStructuralRecursion := none/,
];

for (const pattern of forbidden) {
  if (pattern.test(source)) {
    throw new Error(`PSC2_ELAB_CONTEXT_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`);
  }
}

process.stdout.write(
  "PSC2_ELAB_CONTEXT_SELFHOST_SOURCE_SYNTAX: PASS (explicit structure fields; no Lean field defaults)\n",
);
