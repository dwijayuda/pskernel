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
  /def psElabLambda([\s\S]*?)(?=\ndef psCloseElabForallBinders)/,
);
if (match === null) {
  throw new Error(
    "PSC2_ELAB_LAMBDA_SELFHOST_SOURCE_SYNTAX_MISSING: psElabLambda block",
  );
}
const lambda = match[0];

const required = [
  /let finalResult\s*:=\s*PsElabTermResult\.mk\s+outerContext\s*\(Prod\.fst closed\)\s*\(Prod\.snd closed\);/,
  /psElabFinalizeExpected\s+finalResult\s+expected/,
];
for (const pattern of required) {
  if (!pattern.test(lambda)) {
    throw new Error(
      `PSC2_ELAB_LAMBDA_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const forbidden = [
  /let finalResult\s*:\s*PsElabTermResult\s*:=\s*\{/,
];
for (const pattern of forbidden) {
  if (pattern.test(lambda)) {
    throw new Error(
      `PSC2_ELAB_LAMBDA_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ELAB_LAMBDA_SELFHOST_SOURCE_SYNTAX: PASS (constructor-normalized final term result)\n",
);
