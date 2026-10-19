import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Declaration.lean"),
  "utf8",
);

const match = source.match(
  /def psElabDeclarationBatch[\s\S]*?(?=\ndef psPrependBatchReverse)/,
);
if (match === null) {
  throw new Error(
    "PSC2_ELAB_DECLARATION_BATCH_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
  );
}

const block = match[0];
const required = [
  /\| Except\.ok result =>\s*Except\.ok\s*\(PsElabDeclarationBatchResult\.mk\s*\(List\.cons result\.declaration List\.nil\)\)/,
];
for (const pattern of required) {
  if (!pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_DECLARATION_BATCH_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const forbidden = [
  /Except\.ok\s*\{\s*declarations :=/,
  /\[result\.declaration\]/,
];
for (const pattern of forbidden) {
  if (pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_DECLARATION_BATCH_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ELAB_DECLARATION_BATCH_SELFHOST_SOURCE_SYNTAX: PASS (explicit batch-result constructor and singleton List.cons)\n",
);
