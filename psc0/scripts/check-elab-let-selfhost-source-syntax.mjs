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
  /def psElabLet([\s\S]*?)(?=\ndef psExprApplyMany)/,
);
if (match === null) {
  throw new Error(
    "PSC2_ELAB_LET_SELFHOST_SOURCE_SYNTAX_MISSING: psElabLet block",
  );
}

const block = match[0];
const required = [
  /match elaborate context value Option\.none with/,
  /match elaborate context sourceType Option\.none with/,
  /match elaborate\s+typeResult\.context\s+value\s+\(Option\.some typeResult\.term\) with/,
];
for (const pattern of required) {
  if (!pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_LET_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const forbidden = [
  /match elaborate context value none with/,
  /match elaborate context sourceType none with/,
  /match elaborate\s+typeResult\.context\s+value\s+\(some typeResult\.term\) with/,
];
for (const pattern of forbidden) {
  if (pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_LET_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ELAB_LET_SELFHOST_SOURCE_SYNTAX: PASS (explicit Option.none value/type expectations; explicit Option.some declared-type expectation)\n",
);
