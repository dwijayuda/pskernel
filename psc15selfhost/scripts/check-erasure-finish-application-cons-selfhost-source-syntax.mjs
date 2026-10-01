import "./check-erasure-finish-application-append-selfhost-source-syntax.mjs";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/erasure/src/Ps/Erasure/Expr.lean"),
  "utf8",
);

// Replay at 0601ca9 failed at Expr.lean:118:43 on term-level ::.
// Keep the regression scoped to the three cons terms in this declaration;
// cons patterns in other declarations are still valid PSC1 source.
const match = source.match(
  /^def psEraseFinishApplicationWithFuel\b[\s\S]*?(?=^def psEraseFinishApplication\b)/m,
);
if (match === null) {
  throw new Error(
    "PSC2_ERASURE_FINISH_APPLICATION_CONS_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
  );
}

const block = match[0];
const required = [
  /erasedLocals :=\s*List\.cons\s+pushed\.id\s+scope\.erasedLocals/,
  /runtimeLocals :=\s*List\.cons\s*\(pushed\.id,\s*parameterName\)\s+scope\.runtimeLocals/,
  /\(List\.cons\s*\{\s*name := parameterName\s+type := parameterType\s*\}\s+parametersRev\)/,
];
for (const pattern of required) {
  if (!pattern.test(block)) {
    throw new Error(
      `PSC2_ERASURE_FINISH_APPLICATION_CONS_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const forbidden = [
  /pushed\.id\s*::\s*scope\.erasedLocals/,
  /\(pushed\.id,\s*parameterName\)\s*::\s*scope\.runtimeLocals/,
  /\}\s*::\s*parametersRev/,
];
for (const pattern of forbidden) {
  if (pattern.test(block)) {
    throw new Error(
      `PSC2_ERASURE_FINISH_APPLICATION_CONS_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ERASURE_FINISH_APPLICATION_CONS_SELFHOST_SOURCE_SYNTAX: PASS (explicit List.cons for proof/runtime locals and parameter accumulation)\n",
);
