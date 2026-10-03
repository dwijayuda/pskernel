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
  "psKernelAddAxiom",
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

process.stdout.write(
  [
    "PSC1KERNEL_GENERATED_SMOKE: PASS",
    `kernel=${path.relative(root, kernelPath)}`,
    "checks=name,level,expr,subst,nat,whnf,axiom,duplicate-rejection",
  ].join("\n") + "\n",
);
