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
  /def psElabIf([\s\S]*?)(?=\nstructure PsExprAppView)/,
);
if (match === null) {
  throw new Error(
    "PSC2_ELAB_IF_SELFHOST_SOURCE_SYNTAX_MISSING: psElabIf block",
  );
}

const block = match[0];
const required = [
  /match elaborate context condition \(Option\.some boolType\) with/,
  /thenResult\.context\s+elseBranch\s+\(Option\.some resultType\) with/,
];
for (const pattern of required) {
  if (!pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_IF_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const forbidden = [
  /elaborate context condition \(some boolType\)/,
  /elseBranch\s+\(some resultType\) with/,
];
for (const pattern of forbidden) {
  if (pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_IF_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ELAB_IF_SELFHOST_SOURCE_SYNTAX: PASS (explicit Option.some condition and else expectations)\n",
);
