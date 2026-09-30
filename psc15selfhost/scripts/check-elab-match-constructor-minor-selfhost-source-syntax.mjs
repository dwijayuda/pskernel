// Regression gate: PSC1 self-host match elaboration needs an explicit result type here.
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Term.lean"),
  "utf8",
);

const blockMatch = source.match(
  /def psElabMatchConstructorMinor([\s\S]*?)(?=\ndef psElabMatchMinor\n)/,
);

if (blockMatch === null) {
  throw new Error(
    "PSC2_ELAB_MATCH_CONSTRUCTOR_MINOR_SELFHOST_SOURCE_SYNTAX_MISSING: constructor minor declaration",
  );
}

const block = blockMatch[0];

if (!/let binders\s*:\s*List PsSyntaxName\s*:=\s*match sourceBinders with/.test(block)) {
  throw new Error(
    "PSC2_ELAB_MATCH_CONSTRUCTOR_MINOR_SELFHOST_SOURCE_SYNTAX_MISSING: explicit List PsSyntaxName expected type for source-binder match",
  );
}

if (/let binders\s*:=\s*match sourceBinders with/.test(block)) {
  throw new Error(
    "PSC2_ELAB_MATCH_CONSTRUCTOR_MINOR_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: untyped source-binder match reaches match elaboration with no expected type",
  );
}

process.stdout.write(
  "PSC2_ELAB_MATCH_CONSTRUCTOR_MINOR_SELFHOST_SOURCE_SYNTAX: PASS (typed source-binder match)\n",
);
