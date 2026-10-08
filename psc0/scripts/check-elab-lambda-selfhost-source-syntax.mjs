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

const requiredSource = [
  /def psElabTypedBinderListReverseAux\s+\(remaining : List PsElabTypedBinder\)[\s\S]*?match remaining with[\s\S]*?\| List\.nil =>[\s\S]*?fun \(acc : List PsElabTypedBinder\) => acc[\s\S]*?\| List\.cons head tail =>[\s\S]*?psElabTypedBinderListReverseAux tail[\s\S]*?smaller \(List\.cons head acc\)/,
  /def psElabTypedBinderListReverse\s+\(values : List PsElabTypedBinder\)[\s\S]*?psElabTypedBinderListReverseAux values List\.nil/,
];
for (const pattern of requiredSource) {
  if (!pattern.test(source)) {
    throw new Error(
      `PSC2_ELAB_LAMBDA_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const required = [
  /psElabLambdaBodyExpected\s+binderResult\.context\s+\(psElabTypedBinderListReverse binderResult\.bindersRev\)\s+expected/,
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
  /List\.reverse\s+binderResult\.bindersRev/,
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
  "PSC2_ELAB_LAMBDA_SELFHOST_SOURCE_SYNTAX: PASS (PSC1-safe typed-binder reversal and constructor-normalized final term result)\n",
);
