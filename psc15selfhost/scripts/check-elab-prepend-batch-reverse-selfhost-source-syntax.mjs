import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Declaration.lean"),
  "utf8",
);

const match = source.match(
  /def psPrependBatchReverse[\s\S]*?(?=\ndef psElabDeclarations)/,
);
if (match === null) {
  throw new Error(
    "PSC2_ELAB_PREPEND_BATCH_REVERSE_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
  );
}

const block = match[0];
const required = [
  /psElabAppendDeclarations\s+\(psElabReverseDeclarations declarations\)\s+declarationsRev/,
];
for (const pattern of required) {
  if (!pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_PREPEND_BATCH_REVERSE_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const forbidden = [
  /declarations\.reverse\b/,
  /List\.reverse\b/,
];
for (const pattern of forbidden) {
  if (pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_PREPEND_BATCH_REVERSE_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ELAB_PREPEND_BATCH_REVERSE_SELFHOST_SOURCE_SYNTAX: PASS (project-owned declaration reversal; generic reverse excluded)\n",
);

await import("./check-elab-declarations-selfhost-source-syntax.mjs");
