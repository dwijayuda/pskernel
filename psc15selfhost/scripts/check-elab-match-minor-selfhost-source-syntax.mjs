// Match patterns may use constructor syntax, but Option values passed to elaboration/helpers must be explicit in the PSC1 bootstrap profile.
// Keep this guard source-only: it exists to prevent unqualified Option value constructors from re-entering the self-host closure.
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
  /def psElabMatchMinor([\s\S]*?)(?=\nstructure PsElabMatchMinorsResult)/,
);
if (match === null) {
  throw new Error(
    "PSC2_ELAB_MATCH_MINOR_SELFHOST_SOURCE_SYNTAX_MISSING: psElabMatchMinor block",
  );
}

const block = match[0];
const required = [
  /match elaborate context alternative\.body \(Option\.some expectedType\) with/,
  /\n\s+Option\.none\n\s+\| \.constructor/,
  /\(Option\.some binders\)/,
];
for (const pattern of required) {
  if (!pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_MATCH_MINOR_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const forbidden = [
  /match elaborate context alternative\.body \(some expectedType\) with/,
  /\n\s+none\n\s+\| \.constructor/,
  /\(some binders\)/,
];
for (const pattern of forbidden) {
  if (pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_MATCH_MINOR_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ELAB_MATCH_MINOR_SELFHOST_SOURCE_SYNTAX: PASS (explicit Option.some body expectation; explicit Option.none wildcard binders; explicit Option.some constructor binders)\n",
);
