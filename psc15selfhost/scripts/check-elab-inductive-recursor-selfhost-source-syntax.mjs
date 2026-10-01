import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Declaration.lean"),
  "utf8",
);

const start = source.indexOf("def psBuildInductiveRecursor\n");
const end = source.indexOf("\ndef psElabInductiveDeclaration\n", start + 1);
if (start < 0 || end < 0) {
  throw new Error(
    "PSC2_ELAB_INDUCTIVE_RECURSOR_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
  );
}

const block = source.slice(start, end);
const required = [
  /PsRecursorInfo\.mk/,
  /\(psElabListLength\s+parameterArgs\)/,
  /\(psElabListLength\s+constructors\)/,
];
for (const pattern of required) {
  if (!pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_INDUCTIVE_RECURSOR_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const forbidden = [
  /parameterArgs\.length\b/,
  /constructors\.length\b/,
];
for (const pattern of forbidden) {
  if (pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_INDUCTIVE_RECURSOR_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ELAB_INDUCTIVE_RECURSOR_SELFHOST_SOURCE_SYNTAX: PASS (project-owned list counts in recursor metadata)\n",
);
