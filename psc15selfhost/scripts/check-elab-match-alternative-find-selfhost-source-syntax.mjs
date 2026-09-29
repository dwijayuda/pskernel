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
  /def psElabMatchAlternativeFind([\s\S]*?)(?=\ndef psElabMatchAlternativeCovered)/,
);
if (match === null) {
  throw new Error(
    "PSC2_ELAB_MATCH_ALTERNATIVE_FIND_SELFHOST_SOURCE_SYNTAX_MISSING: psElabMatchAlternativeFind block",
  );
}

const block = match[0];
const required = [
  /\(alternatives : List PsElabMatchAlternative\)\s*:\s*Option PsElabMatchAlternative\s*:=\s*match alternatives with/,
  /\| \[\] =>\s*Option\.none/,
  /then\s+Option\.some alternative/,
  /psElabMatchAlternativeFind name rest/,
];
for (const pattern of required) {
  if (!pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_MATCH_ALTERNATIVE_FIND_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const forbidden = [
  /List PsElabMatchAlternative -> Option PsElabMatchAlternative\s*\n\s*\|/,
  /\| \[\] =>\s*none\b/,
  /then\s+some alternative\b/,
];
for (const pattern of forbidden) {
  if (pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_MATCH_ALTERNATIVE_FIND_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ELAB_MATCH_ALTERNATIVE_FIND_SELFHOST_SOURCE_SYNTAX: PASS (explicit recursive list parameter, top-level match, and explicit Option constructors)\n",
);
