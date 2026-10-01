import "./check-elab-declaration-structural-recursion-selfhost-source-syntax.mjs";
import "./check-elab-try-structural-self-call-selfhost-source-syntax.mjs";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Term.lean"),
  "utf8",
);

const workerStart = source.indexOf("def psElabValidateStructuralCallWorker\n");
const wrapperStart = source.indexOf(
  "\ndef psElabValidateStructuralCall\n",
  workerStart + 1,
);
const end = source.indexOf(
  "\ndef psTryElabStructuralSelfCall\n",
  wrapperStart + 1,
);
if (workerStart < 0 || wrapperStart < 0 || end < 0) {
  throw new Error(
    "PSC2_ELAB_VALIDATE_STRUCTURAL_CALL_SELFHOST_SOURCE_SYNTAX_MISSING: worker/wrapper declaration block",
  );
}

const worker = source.slice(workerStart, wrapperStart);
const wrapper = source.slice(wrapperStart, end);
const block = source.slice(workerStart, end);

const workerRequired = [
  /\(arguments\s*:\s*List PsSyntaxTerm\)\s*:\s*\n\s*PsElabContext\s*->\s*\n\s*PsElabStructuralRecursion\s*->\s*\n\s*Nat\s*->\s*\n\s*Option Nat\s*->\s*\n\s*Except PsElabError Nat\s*:=/,
  /match\s+arguments\s+with/,
  /psElabValidateStructuralCallWorker\s+rest\s*;/,
  /fun \(context\s*:\s*PsElabContext\) =>/,
  /fun \(recursion\s*:\s*PsElabStructuralRecursion\) =>/,
  /fun \(index\s*:\s*Nat\) =>/,
  /fun \(hypothesisId\s*:\s*Option Nat\) =>/,
  /smaller\s+context\s+recursion\s+\(Nat\.succ index\)\s+\(Option\.some nextHypothesisId\)/,
  /smaller\s+context\s+recursion\s+\(Nat\.succ index\)\s+hypothesisId/,
  /\| Option\.some resolvedHypothesisId =>/,
  /\| Option\.none =>/,
];
for (const pattern of workerRequired) {
  if (!pattern.test(worker)) {
    throw new Error(
      `PSC2_ELAB_VALIDATE_STRUCTURAL_CALL_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

if (!/psElabValidateStructuralCallWorker\s+arguments\s+context\s+recursion\s+index\s+hypothesisId/.test(wrapper)) {
  throw new Error(
    "PSC2_ELAB_VALIDATE_STRUCTURAL_CALL_SELFHOST_SOURCE_SYNTAX_MISSING: thin wrapper delegates to worker",
  );
}

const forbidden = [
  /psElabValidateStructuralCall\s+context\s+recursion\s+\(Nat\.succ index\)\s+rest/,
  /\|\s*none\s*=>/,
  /\|\s*some\s+/,
  /\(some\s+nextHypothesisId\)/,
];
for (const pattern of forbidden) {
  if (pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_VALIDATE_STRUCTURAL_CALL_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ELAB_VALIDATE_STRUCTURAL_CALL_SELFHOST_SOURCE_SYNTAX: PASS (arguments-recursive worker; index/hypothesis state applied post-recursion; explicit Option constructors)\n",
);