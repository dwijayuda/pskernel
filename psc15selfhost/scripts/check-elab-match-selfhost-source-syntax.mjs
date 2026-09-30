// Option constructor patterns stay ordinary match syntax, but Option values passed to helpers must be explicit in the PSC1 bootstrap profile.
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
  /def psElabMatch\n([\s\S]*?)(?=\ndef psBinderAcceptsExplicitArgument\n)/,
);
if (match === null) {
  throw new Error(
    "PSC2_ELAB_MATCH_SELFHOST_SOURCE_SYNTAX_MISSING: psElabMatch block",
  );
}

const block = match[0];
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
