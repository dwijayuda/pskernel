import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/erasure/src/Ps/Erasure/Expr.lean"),
  "utf8",
);

const match = source.match(
  /def psEraseFinishApplicationWithFuel[\s\S]*?(?=\ndef psEraseFinishApplication)/,
);
if (match === null) {
  throw new Error(
    "PSC2_ERASURE_FINISH_APPLICATION_SEQUENCING_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
  );
}

const block = match[0];
const required = [
  /let pushed :=\s*psLocalPushBinding\s+scope\.localContext\s+name\s+domain\s+binder;/,
  /let nextScope : PsErasureScope := \{[\s\S]*?currentDefinition := scope\.currentDefinition\s*\};\s*psEraseFinishApplicationWithFuel/,
  /let parameterName :=\s*psErasureSafeIdentifier[\s\S]*?\("arg\$" \+\+ toString pushed\.id\);/,
  /let body :=\s*if runtimeArguments\.isEmpty then[\s\S]*?runtimeArguments;\s*match parametersRev\.reverse with/,
];
for (const pattern of required) {
  if (!pattern.test(block)) {
    throw new Error(
      `PSC2_ERASURE_FINISH_APPLICATION_SEQUENCING_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const pushedCount = (block.match(/psLocalPushBinding\s+scope\.localContext\s+name\s+domain\s+binder;/g) ?? []).length;
if (pushedCount !== 2) {
  throw new Error(
    `PSC2_ERASURE_FINISH_APPLICATION_SEQUENCING_SELFHOST_SOURCE_SYNTAX_MISSING: expected two sequenced pushed bindings, got ${pushedCount}`,
  );
}

process.stdout.write(
  "PSC2_ERASURE_FINISH_APPLICATION_SEQUENCING_SELFHOST_SOURCE_SYNTAX: PASS (explicit local let sequencing across proof/runtime/final application branches)\n",
);
