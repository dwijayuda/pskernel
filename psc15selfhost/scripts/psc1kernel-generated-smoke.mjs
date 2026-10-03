import path from "node:path";
import { pathToFileURL } from "node:url";
import assert from "node:assert/strict";

if (process.argv.length < 3) {
  throw new Error(
    "usage: node scripts/psc1kernel-generated-smoke.mjs <generated-kernel.js>",
  );
}

const root = path.resolve(import.meta.dirname, "..");
const kernelPath = path.resolve(root, process.argv[2]);
const kernel = await import(pathToFileURL(kernelPath).href);

const required = [
  "List",
  "PsKernelName",
  "PsKernelLevel",
  "PsKernelLiteral",
  "PsKernelExpr",
  "psKernelNameEq",
  "psKernelLevelEquivalent",
  "psKernelExprEq",
  "psKernelExprInstantiate1",
  "psKernelNatGcd",
  "psKernelEnvironmentEmpty",
  "psKernelEnvironmentSize",
  "psKernelEnvironmentContains",
  "psKernelCheckerContextEmpty",
  "psKernelCheckerStateEmpty",
  "psKernelWhnfNoRecursor",
  "psKernelMkCheckerSession",
  "psKernelSessionIsDefEq",
  "psKernelSessionWhnf",
  "psKernelApplyArgs",
  "psKernelAddAxiom",
  "psKernelAddSimpleInductive",
  "psKernelSimpleRecName",
  "psKernelLeanNatMaxSizeDefault",
  "psKernelSelfHostSemanticRoot",
];

for (const name of required) {
  if (!(name in kernel)) {
    throw new Error(`PSC1KERNEL_GENERATED_EXPORT_MISSING: ${name}`);
  }
}

function sumTag(value) {
  if (value === null || typeof value !== "object") return undefined;
  for (const symbol of Object.getOwnPropertySymbols(value)) {
    const tag = value[symbol];
    if (typeof tag === "string") return tag;
  }
  return undefined;
}

function unwrapExcept(value, label) {
  const tag = sumTag(value);
  if (tag === "ok") return value.value;
  if (tag === "error") {
    throw new Error(
      `PSC1KERNEL_GENERATED_${label}_ERROR: ${String(value.error)}`,
    );
  }
  throw new Error(`PSC1KERNEL_GENERATED_${label}_RESULT_SHAPE`);
}

assert.equal(kernel.psKernelSelfHostSemanticRoot, true);

const anonymous = kernel.PsKernelName.anonymous;
const alpha = kernel.PsKernelName.str(anonymous, "Alpha");
assert.equal(kernel.psKernelNameEq(alpha, alpha), true);

const zero = kernel.PsKernelLevel.zero;
assert.equal(kernel.psKernelLevelEquivalent(zero, zero), true);

const sort0 = kernel.PsKernelExpr.sort(zero);
assert.equal(kernel.psKernelExprEq(sort0, sort0), true);

const seven = kernel.PsKernelExpr.lit(kernel.PsKernelLiteral.nat(7n));
const bvar0 = kernel.PsKernelExpr.bvar(0n);
const instantiated = kernel.psKernelExprInstantiate1(bvar0, seven);
assert.equal(kernel.psKernelExprEq(instantiated, seven), true);

assert.equal(kernel.psKernelNatGcd(48n, 18n), 6n);

const environment0 = kernel.psKernelEnvironmentEmpty;
assert.equal(kernel.psKernelEnvironmentSize(environment0), 0n);

const context = kernel.psKernelCheckerContextEmpty(environment0);
const state = kernel.psKernelCheckerStateEmpty;
const whnf = unwrapExcept(
  kernel.psKernelWhnfNoRecursor(256n, context, state, sort0),
  "WHNF",
);
assert.equal(kernel.psKernelExprEq(whnf.fst, sort0), true);

const defeqSession = kernel.psKernelMkCheckerSession(
  environment0,
  kernel.List.nil(),
  kernel.PsKernelDefinitionSafety.safe,
  0n,
  kernel.psKernelLeanNatMaxSizeDefault,
);
const xName = kernel.PsKernelName.str(anonymous, "x");
const betaLeft = kernel.PsKernelExpr.app(
  kernel.PsKernelExpr.lam(
    xName,
    sort0,
    kernel.PsKernelExpr.bvar(0n),
    kernel.PsKernelBinderInfo.default,
  ),
  seven,
);
const betaEqual = unwrapExcept(
  kernel.psKernelSessionIsDefEq(
    2048n,
    defeqSession,
    betaLeft,
    seven,
  ),
  "DEFEQ",
);
assert.equal(betaEqual.fst, true);

const base = {
  name: alpha,
  levelParams: kernel.List.nil(),
  type: sort0,
};
const axiom = {
  base,
  isUnsafe: false,
};
const environment1 = unwrapExcept(
  kernel.psKernelAddAxiom(
    2048n,
    environment0,
    axiom,
    0n,
    kernel.psKernelLeanNatMaxSizeDefault,
  ),
  "AXIOM",
);
assert.equal(kernel.psKernelEnvironmentSize(environment1), 1n);
assert.equal(kernel.psKernelEnvironmentContains(environment1, alpha), true);

const duplicate = kernel.psKernelAddAxiom(
  2048n,
  environment1,
  axiom,
  0n,
  kernel.psKernelLeanNatMaxSizeDefault,
);
assert.equal(sumTag(duplicate), "error");

const unitName = kernel.PsKernelName.str(anonymous, "SmokeUnit");
const unitCtorName = kernel.PsKernelName.str(unitName, "unit");
const unitRecName = kernel.psKernelSimpleRecName(unitName);
const unitType = kernel.PsKernelExpr.sort(zero);
const unitValueType = kernel.PsKernelExpr.const(
  unitName,
  kernel.List.nil(),
);
const unitCtor = {
  name: unitCtorName,
  type: unitValueType,
};
const unitDecl = {
  levelParams: kernel.List.nil(),
  name: unitName,
  type: unitType,
  ctors: kernel.List.cons(unitCtor, kernel.List.nil()),
  isUnsafe: false,
  numParams: 0n,
};
const environment2 = unwrapExcept(
  kernel.psKernelAddSimpleInductive(
    16384n,
    environment1,
    unitDecl,
    0n,
    kernel.psKernelLeanNatMaxSizeDefault,
  ),
  "INDUCTIVE",
);
assert.equal(kernel.psKernelEnvironmentContains(environment2, unitName), true);
assert.equal(kernel.psKernelEnvironmentContains(environment2, unitCtorName), true);
assert.equal(kernel.psKernelEnvironmentContains(environment2, unitRecName), true);

const unitCtorValue = kernel.PsKernelExpr.const(
  unitCtorName,
  kernel.List.nil(),
);
const motiveName = kernel.PsKernelName.str(anonymous, "motiveArg");
const unitMotive = kernel.PsKernelExpr.lam(
  motiveName,
  unitValueType,
  unitValueType,
  kernel.PsKernelBinderInfo.default,
);
const unitRecursorApp = kernel.psKernelApplyArgs(
  kernel.PsKernelExpr.const(unitRecName, kernel.List.nil()),
  kernel.List.cons(
    unitMotive,
    kernel.List.cons(
      unitCtorValue,
      kernel.List.cons(unitCtorValue, kernel.List.nil()),
    ),
  ),
);
const unitSession = kernel.psKernelMkCheckerSession(
  environment2,
  kernel.List.nil(),
  kernel.PsKernelDefinitionSafety.safe,
  0n,
  kernel.psKernelLeanNatMaxSizeDefault,
);
const unitReduced = unwrapExcept(
  kernel.psKernelSessionWhnf(
    16384n,
    unitSession,
    unitRecursorApp,
  ),
  "RECURSOR",
);
assert.equal(kernel.psKernelExprEq(unitReduced.fst, unitCtorValue), true);

const duplicateInductive = kernel.psKernelAddSimpleInductive(
  16384n,
  environment2,
  unitDecl,
  0n,
  kernel.psKernelLeanNatMaxSizeDefault,
);
assert.equal(sumTag(duplicateInductive), "error");

process.stdout.write(
  [
    "PSC1KERNEL_GENERATED_SMOKE: PASS",
    `kernel=${path.relative(root, kernelPath)}`,
    "checks=name,level,expr,subst,nat,whnf,defeq,axiom,inductive,recursor,duplicate-rejection",
  ].join("\n") + "\n",
);
