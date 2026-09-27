import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const infer = await readFile(
  path.join(root, "packages/meta/src/Ps/Meta/Infer.lean"),
  "utf8",
);

const required = [
  'def psInferAppViewAcc\n    (expr : PsExpr) : List PsExpr -> PsInferAppView :=\n  match expr with',
  '| .app fn arg =>\n      let smaller : List PsExpr -> PsInferAppView :=\n        psInferAppViewAcc fn;\n      fun (args : List PsExpr) =>\n        smaller (List.cons arg args)',
  '| _ =>\n      fun (args : List PsExpr) =>\n        PsInferAppView.mk expr args',
  'def psInferApplyStructureParametersWorker\n    (arguments : List PsExpr) :',
  'psInferApplyStructureParametersWorker rest;',
  'psInferApplyStructureParametersWorker\n    arguments\n    environment\n    metaContext\n    localContext\n    cursor',
];
for (const marker of required) {
  if (!infer.includes(marker)) {
    throw new Error(`PSC2_INFER_SELFHOST_SOURCE_SYNTAX_MISSING: ${marker}`);
  }
}

const forbidden = [
  'def psInferAppViewAcc\n    (expr : PsExpr)\n    (args : List PsExpr) : PsInferAppView :=',
  'psInferAppViewAcc fn (List.cons arg args)',
  'psInferApplyStructureParameters\n            environment\n            metaContext\n            localContext\n            (psExprInstantiate1 body argument)\n            rest',
  '| head =>',
  'head := head',
];
for (const marker of forbidden) {
  if (infer.includes(marker)) {
    throw new Error(`PSC2_INFER_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${marker}`);
  }
}

process.stdout.write(
  "PSC2_INFER_SELFHOST_SOURCE_SYNTAX: PASS (explicit arity-safe app-view and invariant-safe structure-parameter recursion)\n",
);
