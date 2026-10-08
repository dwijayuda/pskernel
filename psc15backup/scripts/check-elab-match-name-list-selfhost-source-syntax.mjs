import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Term.lean"),
  "utf8",
);

const match = source.match(
  /def psMatchNameListContains([\s\S]*?)(?=\nstructure PsElabMatchAlternative)/,
);
if (match === null) {
  throw new Error(
    "PSC2_ELAB_MATCH_NAME_LIST_SELFHOST_SOURCE_SYNTAX_MISSING: psMatchNameListContains block",
  );
}

const block = match[0];
const required = [
  /def psMatchNameListContains\s*\(names : List PsName\)\s*\(target : PsName\) : Bool :=\s*match names with/,
  /psMatchNameListContains\s+rest\s+target/,
];
for (const pattern of required) {
  if (!pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_MATCH_NAME_LIST_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const forbidden = [
  /\bList\.any\b/,
];
for (const pattern of forbidden) {
  if (pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_MATCH_NAME_LIST_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ELAB_MATCH_NAME_LIST_SELFHOST_SOURCE_SYNTAX: PASS (explicit structural name-list recursion; no unavailable List.any dependency)\n",
);
