import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/erasure/src/Ps/Erasure/Definition.lean"),
  "utf8",
);

const match = source.match(
  /def psEraseCoreModuleWithRuntimePrelude[\s\S]*?(?=\ndef psEraseCoreModule)/,
);
if (match === null) {
  throw new Error(
    "PSC2_ERASURE_CORE_MODULE_SEQUENCING_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
  );
}

const block = match[0];
const required = [
  /let runtimeDeclarations :=\s*psErasureAppendDeclarations runtimePreludeDeclarations declarations;/,
  /let names := psErasureDeclarationNames runtimeDeclarations;/,
  /let baseScope := psErasureScopeEmpty names;/,
];
for (const pattern of required) {
  if (!pattern.test(block)) {
    throw new Error(
      `PSC2_ERASURE_CORE_MODULE_SEQUENCING_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ERASURE_CORE_MODULE_SEQUENCING_SELFHOST_SOURCE_SYNTAX: PASS (explicit let sequencing before runtime preparation)\n",
);
