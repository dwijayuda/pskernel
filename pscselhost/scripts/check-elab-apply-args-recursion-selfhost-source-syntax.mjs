import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Term.lean"),
  "utf8",
);

const workerStart = source.indexOf("def psElabApplyArgsWithFuelWorker\n");
const wrapperStart = source.indexOf("\ndef psElabApplyArgsWithFuel\n");
const wrapperEnd = source.indexOf("\ndef psElabApplyArgs\n", wrapperStart + 1);

if (workerStart < 0 || wrapperStart < 0 || wrapperEnd < 0 || workerStart >= wrapperStart) {
  throw new Error(
    "PSC2_ELAB_APPLY_ARGS_RECURSION_SELFHOST_SOURCE_SYNTAX_MISSING: invariant-fuel worker/wrapper layout",
  );
}

const workerBlock = source.slice(workerStart, wrapperStart);
const wrapperBlock = source.slice(wrapperStart, wrapperEnd);
// The callback elaborates one term; only the application worker adds pending
// instances. A transport edit once changed only the wrapper callback's result.
const elaborateCallback = /\(elaborate\s*:\s*PsElabContext\s*->\s*PsSyntaxTerm\s*->\s*Option PsExpr\s*->\s*Except PsElabError PsElabTermResult\s*\)/;
for (const [label, block] of [["worker", workerBlock], ["wrapper", wrapperBlock]]) {
  if (!elaborateCallback.test(block)) {
    throw new Error(
      `PSC2_ELAB_APPLY_ARGS_CALLBACK_TYPE_MISMATCH: ${label} elaborate callback must return PsElabTermResult`,
    );
  }
}

const required = [
  /\(remainingFuel : Nat\)\s*:\s*\n\s*PsElabTermResult ->\s*\n\s*List PsSyntaxTerm ->\s*\n\s*List Nat ->\s*\n\s*Except PsElabError PsElabApplicationResult :=\s*\n\s*match remainingFuel with/,
  /let smaller\s*:\s*\n\s*PsElabTermResult ->\s*\n\s*List PsSyntaxTerm ->\s*\n\s*List Nat ->\s*\n\s*Except PsElabError PsElabApplicationResult :=\s*\n\s*psElabApplyArgsWithFuelWorker elaborate fuel;/,
  /smaller\s*\n\s*nextResult\s*\n\s*rest\s*\n\s*pendingInstancesRev/,
  /smaller\s*\n\s*nextResult\s*\n\s*arguments\s*\n\s*nextPending/,
];
for (const pattern of required) {
  if (!pattern.test(workerBlock)) {
    throw new Error(
      `PSC2_ELAB_APPLY_ARGS_RECURSION_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

if (/psElabApplyArgsWithFuel\s*\n\s*elaborate\s*\n\s*fuel/.test(workerBlock)) {
  throw new Error(
    "PSC2_ELAB_APPLY_ARGS_RECURSION_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: direct recursive wrapper call remains",
  );
}

if (!/psElabApplyArgsWithFuelWorker\s*\n\s*elaborate\s*\n\s*remainingFuel\s*\n\s*current\s*\n\s*arguments\s*\n\s*pendingInstancesRev/.test(wrapperBlock)) {
  throw new Error(
    "PSC2_ELAB_APPLY_ARGS_RECURSION_SELFHOST_SOURCE_SYNTAX_MISSING: thin public wrapper",
  );
}

process.stdout.write(
  "PSC2_ELAB_APPLY_ARGS_RECURSION_SELFHOST_SOURCE_SYNTAX: PASS (fuel-recursive worker; current/arguments/pending state applied post-recursion)\n",
);
