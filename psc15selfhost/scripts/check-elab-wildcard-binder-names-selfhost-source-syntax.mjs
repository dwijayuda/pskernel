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
  /def psElabWildcardBinderNames([\s\S]*?)(?=\ndef psElabMatchConstructorMinor)/,
);

if (blockMatch === null) {
  throw new Error(
    "PSC2_ELAB_WILDCARD_BINDER_NAMES_SELFHOST_SOURCE_SYNTAX_MISSING: psElabWildcardBinderNames",
  );
}

const block = blockMatch[0];

if (/\btoString\b/.test(block)) {
  throw new Error(
    "PSC2_ELAB_WILDCARD_BINDER_NAMES_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: generic toString is outside the PSC1 selfhost surface",
  );
}

if (!/psNatToString\s+index/.test(block)) {
  throw new Error(
    "PSC2_ELAB_WILDCARD_BINDER_NAMES_SELFHOST_SOURCE_SYNTAX_MISSING: project-owned psNatToString index rendering",
  );
}

process.stdout.write(
  "PSC2_ELAB_WILDCARD_BINDER_NAMES_SELFHOST_SOURCE_SYNTAX: PASS (project-owned Nat-to-String rendering; no generic ToString dependency)\n",
);
