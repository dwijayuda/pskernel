// Option constructor patterns stay ordinary match syntax, but Option values passed to helpers must be explicit in the PSC1 bootstrap profile.
// This guard also serves as the clean-branch verification trigger after the production qualification lands.
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Term.lean"),
  "utf8",
);

const startMatch = /^def psElabMatch\r?$/m.exec(source);
if (startMatch === null) {
  throw new Error(
    "PSC2_ELAB_MATCH_SELFHOST_SOURCE_SYNTAX_MISSING: psElabMatch start",
  );
}
const afterStart = source.slice(startMatch.index + startMatch[0].length);
const endMatch = /^def psBinderAcceptsExplicitArgument\b/m.exec(afterStart);
if (endMatch === null) {
  throw new Error(
    "PSC2_ELAB_MATCH_SELFHOST_SOURCE_SYNTAX_MISSING: psElabMatch end",
  );
}
const block = source.slice(
  startMatch.index,
  startMatch.index + startMatch[0].length + endMatch.index,
);

const required = [
  /match elaborate context scrutineeSyntax Option\.none with/,
  /\(Option\.some instantiatedExpected\)/,
];
for (const pattern of required) {
  if (!pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_MATCH_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const forbidden = [
  /match elaborate context scrutineeSyntax none with/,
  /\(some instantiatedExpected\)/,
];
for (const pattern of forbidden) {
  if (pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_MATCH_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ELAB_MATCH_SELFHOST_SOURCE_SYNTAX: PASS (explicit Option.none scrutinee expectation; explicit Option.some resolved expectation)\n",
);
