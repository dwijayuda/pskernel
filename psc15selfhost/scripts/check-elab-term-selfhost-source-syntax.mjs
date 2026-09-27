import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Term.lean"),
  "utf8",
);

const required = [
  /def psSyntaxNameAppendSegments\s*\(segments : List String\)\s*:\s*PsName -> PsName :=\s*match segments with/,
  /\| \[\] =>\s*fun \(name : PsName\) =>\s*name/,
  /let smaller : PsName -> PsName :=\s*psSyntaxNameAppendSegments rest;/,
  /fun \(name : PsName\) =>\s*smaller \(psNameAppendStr name segment\)/,
  /psSyntaxNameAppendSegments\s+rest\s*\(psNameAppendStr PsName\.anonymous first\)/,
];

for (const pattern of required) {
  if (!pattern.test(source)) {
    throw new Error(`PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`);
  }
}

const forbidden = [
  /def psSyntaxNameAppendSegments\s*\(name : PsName\)\s*\(segments : List String\)/,
  /psSyntaxNameAppendSegments\s*\(psNameAppendStr name segment\)\s*rest/,
];

for (const pattern of forbidden) {
  if (pattern.test(source)) {
    throw new Error(`PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`);
  }
}

process.stdout.write(
  "PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX: PASS (invariant-safe syntax-name segment recursion)\n",
);
