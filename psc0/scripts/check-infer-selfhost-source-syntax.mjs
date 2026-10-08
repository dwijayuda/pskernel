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
  'def psInferExprListLength\n    (values : List PsExpr) : Nat :=\n  match values with',
  'def psInferNameListLength\n    (values : List PsName) : Nat :=\n  match values with',
  'def psInferLevelListLength\n    (values : List PsLevel) : Nat :=\n  match values with',
  '| [] => 0',
  '| _ :: rest =>\n      Nat.succ (psInferExprListLength rest)',
  'def psInferAppViewAcc\n    (expr : PsExpr) : List PsExpr -> PsInferAppView :=\n  match expr with',
  '| .app fn arg =>\n      let smaller : List PsExpr -> PsInferAppView :=\n        psInferAppViewAcc fn;\n      fun (args : List PsExpr) =>\n        smaller (List.cons arg args)',
  '| _ =>\n      fun (args : List PsExpr) =>\n        PsInferAppView.mk expr args',
  'def psInferApplyStructureParametersWorker\n    (arguments : List PsExpr) :',
  'psInferApplyStructureParametersWorker rest;',
  'psInferApplyStructureParametersWorker\n    arguments\n    environment\n    metaContext\n    localContext\n    cursor',
  'def psInferStructureProjectionFieldWorker\n    (remainingFuel : Nat) :',
  'psInferStructureProjectionFieldWorker fuel;',
  'psInferStructureProjectionFieldWorker\n    remainingFuel\n    environment\n    metaContext\n    localContext\n    typeName\n    target\n    requestedIndex\n    fieldIndex\n    cursor',
  '(psInferNatNe (psInferExprListLength view.args) info.numParams)',
  'def psInferTypeWithFuelWorker\n    (remainingFuel : Nat) :',
  'let smaller :\n          PsEnvironment ->\n          PsMetaContext ->\n          PsLocalContext ->\n          PsExpr ->\n          Except PsInferError PsExpr :=\n        psInferTypeWithFuelWorker fuel;',
  'def psInferTypeWithFuel\n    (environment : PsEnvironment)\n    (metaContext : PsMetaContext)\n    (localContext : PsLocalContext)\n    (fuel : Nat)\n    (expr : PsExpr) : Except PsInferError PsExpr :=\n  psInferTypeWithFuelWorker\n    fuel\n    environment\n    metaContext\n    localContext\n    expr',
  '(psInferNameListLength parameters)',
  '(psInferLevelListLength levels)',
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
  'psInferStructureProjectionField\n              environment\n              metaContext\n              localContext\n              typeName\n              target\n              fuel\n              requestedIndex\n              (Nat.succ fieldIndex)',
  'view.args.length',
  'List.length view.args',
  'parameters.length',
  'levels.length',
  ': Nat -> PsExpr -> Except PsInferError PsExpr\n  | 0, _ =>',
  '| fuel + 1, expr =>',
  '| head =>',
  'head := head',
];
for (const marker of forbidden) {
  if (infer.includes(marker)) {
    throw new Error(`PSC2_INFER_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${marker}`);
  }
}

process.stdout.write(
  "PSC2_INFER_SELFHOST_SOURCE_SYNTAX: PASS (local list ops and invariant-safe Infer recursion)\n",
);
