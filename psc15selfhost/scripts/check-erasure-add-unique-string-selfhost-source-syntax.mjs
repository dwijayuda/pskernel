import "./check-erasure-core-module-sequencing-selfhost-source-syntax.mjs";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/erasure/src/Ps/Erasure/Definition.lean"),
  "utf8",
);

const match = source.match(
  /def psErasureAddUniqueString[\s\S]*?(?=\nstructure PsErasureNameState)/,
);
if (match === null) {
  throw new Error(
    "PSC2_ERASURE_ADD_UNIQUE_STRING_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
  );
}

const block = match[0];
const required = [
  /\| 0 => String\.Internal\.append base "_overflow"/,
  /String\.Internal\.append base "_"/,
];
for (const pattern of required) {
  if (!pattern.test(block)) {
    throw new Error(
      `PSC2_ERASURE_ADD_UNIQUE_STRING_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

if (/\+\+/.test(block)) {
  throw new Error(
    "PSC2_ERASURE_ADD_UNIQUE_STRING_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ++",
  );
}

process.stdout.write(
  "PSC2_ERASURE_ADD_UNIQUE_STRING_SELFHOST_SOURCE_SYNTAX: PASS (direct String.Internal.append; ++ syntax excluded)\n",
);
