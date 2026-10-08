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
  "psKernelAddSimpleMutualInductive",
  "psKernelAddSimpleNestedInductive",
  "psKernelSimpleRecName",
  "psKernelNameAppendIndexAfter",
  "psKernelNatName",
  "psKernelLeanNatMaxSizeDefault",
  "psKernelCoreSemanticRoot",
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

assert.equal(kernel.psKernelCoreSemanticRoot, true);

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
  kernel.PsKernelExpr.const(
    unitRecName,
    kernel.List.cons(zero, kernel.List.nil()),
  ),
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

const type1 = kernel.PsKernelExpr.sort(
  kernel.PsKernelLevel.succ(zero),
);
const natBase = {
  name: kernel.psKernelNatName,
  levelParams: kernel.List.nil(),
  type: type1,
};
const natAxiom = {
  base: natBase,
  isUnsafe: false,
};
const environment3 = unwrapExcept(
  kernel.psKernelAddAxiom(
    4096n,
    environment2,
    natAxiom,
    0n,
    kernel.psKernelLeanNatMaxSizeDefault,
  ),
  "NAT_AXIOM",
);

const evenName = kernel.PsKernelName.str(anonymous, "SmokeEven");
const evenZeroName = kernel.PsKernelName.str(evenName, "zero");
const evenSuccName = kernel.PsKernelName.str(evenName, "succ");
const evenRecName = kernel.psKernelSimpleRecName(evenName);
const oddName = kernel.PsKernelName.str(anonymous, "SmokeOdd");
const oddSuccName = kernel.PsKernelName.str(oddName, "succ");
const oddRecName = kernel.psKernelSimpleRecName(oddName);
const evenType = kernel.PsKernelExpr.const(evenName, kernel.List.nil());
const oddType = kernel.PsKernelExpr.const(oddName, kernel.List.nil());
const evenSuccType = kernel.PsKernelExpr.forallE(
  kernel.PsKernelName.str(anonymous, "odd"),
  oddType,
  evenType,
  kernel.PsKernelBinderInfo.default,
);
const oddSuccType = kernel.PsKernelExpr.forallE(
  kernel.PsKernelName.str(anonymous, "even"),
  evenType,
  oddType,
  kernel.PsKernelBinderInfo.default,
);
const mutualDecl = {
  levelParams: kernel.List.nil(),
  numParams: 0n,
  types: kernel.List.cons(
    {
      name: evenName,
      type: type1,
      ctors: kernel.List.cons(
        { name: evenZeroName, type: evenType },
        kernel.List.cons(
          { name: evenSuccName, type: evenSuccType },
          kernel.List.nil(),
        ),
      ),
    },
    kernel.List.cons(
      {
        name: oddName,
        type: type1,
        ctors: kernel.List.cons(
          { name: oddSuccName, type: oddSuccType },
          kernel.List.nil(),
        ),
      },
      kernel.List.nil(),
    ),
  ),
  isUnsafe: false,
};
const environment4 = unwrapExcept(
  kernel.psKernelAddSimpleMutualInductive(
    32768n,
    environment3,
    mutualDecl,
    0n,
    kernel.psKernelLeanNatMaxSizeDefault,
  ),
  "MUTUAL",
);
for (const name of [
  evenName,
  evenZeroName,
  evenSuccName,
  evenRecName,
  oddName,
  oddSuccName,
  oddRecName,
]) {
  assert.equal(kernel.psKernelEnvironmentContains(environment4, name), true);
}

const natType = kernel.PsKernelExpr.const(kernel.psKernelNatName, kernel.List.nil());
const evenMotive = kernel.PsKernelExpr.lam(
  kernel.PsKernelName.str(anonymous, "even"),
  evenType,
  natType,
  kernel.PsKernelBinderInfo.default,
);
const oddMotive = kernel.PsKernelExpr.lam(
  kernel.PsKernelName.str(anonymous, "odd"),
  oddType,
  natType,
  kernel.PsKernelBinderInfo.default,
);
const evenZeroMinor = kernel.PsKernelExpr.lit(kernel.PsKernelLiteral.nat(61n));
const evenSuccMinor = kernel.PsKernelExpr.lam(
  kernel.PsKernelName.str(anonymous, "odd"),
  oddType,
  kernel.PsKernelExpr.lam(
    kernel.PsKernelName.str(anonymous, "odd_ih"),
    natType,
    kernel.PsKernelExpr.bvar(0n),
    kernel.PsKernelBinderInfo.default,
  ),
  kernel.PsKernelBinderInfo.default,
);
const oddSuccMinor = kernel.PsKernelExpr.lam(
  kernel.PsKernelName.str(anonymous, "even"),
  evenType,
  kernel.PsKernelExpr.lam(
    kernel.PsKernelName.str(anonymous, "even_ih"),
    natType,
    kernel.PsKernelExpr.bvar(0n),
    kernel.PsKernelBinderInfo.default,
  ),
  kernel.PsKernelBinderInfo.default,
);
const mutualMajor = kernel.PsKernelExpr.app(
  kernel.PsKernelExpr.const(evenSuccName, kernel.List.nil()),
  kernel.PsKernelExpr.app(
    kernel.PsKernelExpr.const(oddSuccName, kernel.List.nil()),
    kernel.PsKernelExpr.const(evenZeroName, kernel.List.nil()),
  ),
);
const mutualRecApp = kernel.psKernelApplyArgs(
  kernel.PsKernelExpr.const(
    evenRecName,
    kernel.List.cons(kernel.PsKernelLevel.succ(zero), kernel.List.nil()),
  ),
  kernel.List.cons(
    evenMotive,
    kernel.List.cons(
      oddMotive,
      kernel.List.cons(
        evenZeroMinor,
        kernel.List.cons(
          evenSuccMinor,
          kernel.List.cons(
            oddSuccMinor,
            kernel.List.cons(mutualMajor, kernel.List.nil()),
          ),
        ),
      ),
    ),
  ),
);
const mutualSession = kernel.psKernelMkCheckerSession(
  environment4,
  kernel.List.nil(),
  kernel.PsKernelDefinitionSafety.safe,
  0n,
  kernel.psKernelLeanNatMaxSizeDefault,
);
const mutualReduced = unwrapExcept(
  kernel.psKernelSessionWhnf(65536n, mutualSession, mutualRecApp),
  "MUTUAL_RECURSOR",
);
assert.equal(
  kernel.psKernelExprEq(
    mutualReduced.fst,
    kernel.PsKernelExpr.lit(kernel.PsKernelLiteral.nat(61n)),
  ),
  true,
);

const boxName = kernel.PsKernelName.str(anonymous, "SmokeNestedBox");
const boxMkName = kernel.PsKernelName.str(boxName, "mk");
const alphaName = kernel.PsKernelName.str(anonymous, "alpha");
const valueName = kernel.PsKernelName.str(anonymous, "value");
const boxType = kernel.PsKernelExpr.forallE(
  alphaName,
  type1,
  type1,
  kernel.PsKernelBinderInfo.default,
);
const boxCtorType = kernel.PsKernelExpr.forallE(
  alphaName,
  type1,
  kernel.PsKernelExpr.forallE(
    valueName,
    kernel.PsKernelExpr.bvar(0n),
    kernel.PsKernelExpr.app(
      kernel.PsKernelExpr.const(boxName, kernel.List.nil()),
      kernel.PsKernelExpr.bvar(1n),
    ),
    kernel.PsKernelBinderInfo.default,
  ),
  kernel.PsKernelBinderInfo.default,
);
const boxDecl = {
  levelParams: kernel.List.nil(),
  name: boxName,
  type: boxType,
  ctors: kernel.List.cons(
    { name: boxMkName, type: boxCtorType },
    kernel.List.nil(),
  ),
  isUnsafe: false,
  numParams: 1n,
};
const environment5 = unwrapExcept(
  kernel.psKernelAddSimpleInductive(
    32768n,
    environment4,
    boxDecl,
    0n,
    kernel.psKernelLeanNatMaxSizeDefault,
  ),
  "NESTED_OUTER",
);

const treeName = kernel.PsKernelName.str(anonymous, "SmokeNestedTree");
const leafName = kernel.PsKernelName.str(treeName, "leaf");
const nodeName = kernel.PsKernelName.str(treeName, "node");
const treeRecName = kernel.psKernelSimpleRecName(treeName);
const treeRecAuxName = kernel.psKernelNameAppendIndexAfter(treeRecName, 1n);
const treeType = kernel.PsKernelExpr.const(treeName, kernel.List.nil());
const boxTreeType = kernel.PsKernelExpr.app(
  kernel.PsKernelExpr.const(boxName, kernel.List.nil()),
  treeType,
);
const nodeType = kernel.PsKernelExpr.forallE(
  kernel.PsKernelName.str(anonymous, "children"),
  boxTreeType,
  treeType,
  kernel.PsKernelBinderInfo.default,
);
const nestedDecl = {
  levelParams: kernel.List.nil(),
  numParams: 0n,
  types: kernel.List.cons(
    {
      name: treeName,
      type: type1,
      ctors: kernel.List.cons(
        { name: leafName, type: treeType },
        kernel.List.cons(
          { name: nodeName, type: nodeType },
          kernel.List.nil(),
        ),
      ),
    },
    kernel.List.nil(),
  ),
  isUnsafe: false,
};
const environment6 = unwrapExcept(
  kernel.psKernelAddSimpleNestedInductive(
    65536n,
    environment5,
    nestedDecl,
    0n,
    kernel.psKernelLeanNatMaxSizeDefault,
  ),
  "NESTED",
);
for (const name of [
  treeName,
  leafName,
  nodeName,
  treeRecName,
  treeRecAuxName,
]) {
  assert.equal(kernel.psKernelEnvironmentContains(environment6, name), true);
}

process.stdout.write(
  [
    "PSC1KERNEL_GENERATED_SMOKE: PASS",
    `kernel=${path.relative(root, kernelPath)}`,
    "checks=name,level,expr,subst,nat,whnf,defeq,axiom,inductive,recursor,mutual,nested,duplicate-rejection",
  ].join("\n") + "\n",
);
