import "./check-erasure-finish-application-sequencing-selfhost-source-syntax.mjs";
import "./check-erasure-finish-application-cons-selfhost-source-syntax.mjs";
import "./check-erasure-selected-arguments-index-selfhost-source-syntax.mjs";
import "./check-erasure-selected-arguments-cons-selfhost-source-syntax.mjs";
import "./check-erasure-primitive-application-sequencing-selfhost-source-syntax.mjs";
import "./check-erasure-primitive-application-equality-selfhost-source-syntax.mjs";
import "./check-erasure-primitive-application-disjunction-selfhost-source-syntax.mjs";
import "./check-erasure-primitive-application-conjunction-selfhost-source-syntax.mjs";
import "./check-erasure-expr-operators-selfhost-source-syntax.mjs";
import "./check-erasure-condition-sequencing-selfhost-source-syntax.mjs";
import "./check-erasure-ite-argument-index-selfhost-source-syntax.mjs";
import "./check-erasure-ite-equality-selfhost-source-syntax.mjs";
import "./check-erasure-runtime-aggregate-source-syntax.mjs";
import "./check-erasure-open-match-minor-fields-source-syntax.mjs";
import "./check-erasure-recursive-call-arguments-source-syntax.mjs";
import "./check-erasure-open-match-hypotheses-source-syntax.mjs";
import "./check-erasure-match-minor-sequencing-source-syntax.mjs";
import "./check-erasure-match-alternatives-source-syntax.mjs";
import "./check-erasure-runtime-recursor-source-syntax.mjs";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/erasure/src/Ps/Erasure/Expr.lean"),
  "utf8",
);

const match = source.match(
  /def psEraseApplicationArguments[\s\S]*?(?=\ndef psEraseFinishApplicationWithFuel)/,
);
if (match === null) {
  throw new Error(
    "PSC2_ERASURE_APPLICATION_ARGUMENTS_CONS_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
  );
}

const block = match[0];
const required = [
  /typeArgumentsRev :=\s*List\.cons erasedType state\.typeArgumentsRev/,
  /runtimeArgumentsRev :=\s*List\.cons erasedArgument state\.runtimeArgumentsRev/,
];
for (const pattern of required) {
  if (!pattern.test(block)) {
    throw new Error(
      `PSC2_ERASURE_APPLICATION_ARGUMENTS_CONS_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const forbidden = [
  /erasedType\s*::\s*state\.typeArgumentsRev/,
  /erasedArgument\s*::\s*state\.runtimeArgumentsRev/,
];
for (const pattern of forbidden) {
  if (pattern.test(block)) {
    throw new Error(
      `PSC2_ERASURE_APPLICATION_ARGUMENTS_CONS_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ERASURE_APPLICATION_ARGUMENTS_CONS_SELFHOST_SOURCE_SYNTAX: PASS (explicit List.cons for erased argument accumulation)\n",
);
