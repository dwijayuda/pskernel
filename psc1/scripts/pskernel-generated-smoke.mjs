import { pathToFileURL } from "node:url";
import path from "node:path";

if (process.argv.length !== 3) {
  throw new Error("PSKERNEL_GENERATED_SMOKE_USAGE: node scripts/pskernel-generated-smoke.mjs <generated-kernel.js>");
}

const url = pathToFileURL(path.resolve(process.argv[2])).href;
const kernel = await import(url);

function requireExport(name) {
  if (!(name in kernel)) {
    throw new Error(`PSKERNEL_GENERATED_EXPORT_MISSING: ${name}`);
  }
  return kernel[name];
}

function expect(name, condition) {
  if (!condition) throw new Error(`PSKERNEL_GENERATED_SMOKE_FAILED: ${name}`);
  console.log(`PSKERNEL_GENERATED_SMOKE PASS: ${name}`);
}

const semanticRoot = requireExport("psKernelCoreSemanticRoot");
expect("semantic root exports true", semanticRoot === true);

const max = requireExport("psKernelStateNatMax");
expect("freshness maximum larger right", max(3n, 14n) === 14n);
expect("freshness maximum larger left", max(19n, 7n) === 19n);
expect("freshness maximum equality", max(7n, 7n) === 7n);

const stringEq = requireExport("psKernelStringEq");
expect("UTF8 byte iteration equal", stringEq("hé", "hé") === true);
expect("UTF8 byte iteration distinct", stringEq("hé", "he") === false);
expect("empty strings equal", stringEq("", "") === true);
expect("length mismatch rejected", stringEq("x", "") === false);

const natLt = requireExport("psKernelNatLt");
expect("strict nat ordering", natLt(2n, 3n) === true && natLt(3n, 2n) === false);

const cacheEligible = requireExport("psKernelSemanticCacheEligible");
const names = requireExport("PsKernelName");
const expr = requireExport("PsKernelExpr");
const levels = requireExport("PsKernelLevel");
if (!names || !expr || !levels || typeof expr.fvar !== "function") {
  throw new Error("PSKERNEL_GENERATED_CONSTRUCTOR_EXPORTS_MISSING");
}
expect("closed sort eligible", cacheEligible(expr.sort(levels.zero)) === true);
expect("free variable never cached", cacheEligible(expr.fvar(names.anonymous)) === false);

const inst1 = requireExport("psKernelExprInstantiate1");
const eq = requireExport("psKernelExprEq");
const sort0 = expr.sort(levels.zero);
expect("C0 one-variable beta substitution", eq(inst1(expr.bvar(0n), sort0), sort0));
expect("C0 outer de Bruijn decrement", eq(inst1(expr.bvar(2n), sort0), expr.bvar(1n)));
const openApp = expr.app(expr.bvar(0n), expr.bvar(2n));
const expectedApp = expr.app(sort0, expr.bvar(1n));
expect("C0 app substitution in generated JS",
  eq(inst1(openApp, sort0), expectedApp));
expect("C0 closed app retained",
  eq(inst1(expr.app(sort0, sort0), sort0), expr.app(sort0, sort0)));

const multi = requireExport("psKernelExprInstantiateAtChanged");
const psList = requireExport("List");
const nil = typeof psList.nil === "function" ? psList.nil() : psList.nil;
const subs = psList.cons(expr.bvar(3n), psList.cons(sort0, nil));
const multiResult = multi(expr.app(expr.bvar(0n), expr.bvar(2n)), 0n, subs, 0n);
expect("C0 multi substitution generated JS",
  eq(multiResult.fst, expr.app(expr.bvar(3n), expr.bvar(0n))));
const lift = requireExport("psKernelExprLiftLooseBVarsChanged");
const lifted = lift(expr.app(expr.bvar(0n), expr.bvar(2n)), 0n, 3n);
expect("C0 binder-aware lifting in generated JS",
  eq(lifted.fst, expr.app(expr.bvar(3n), expr.bvar(5n))));
const unchanged = lift(expr.bvar(0n), 1n, 2n);
expect("C0 lifting preserves bound variable below cutoff",
  eq(unchanged.fst, expr.bvar(0n)));
const zeroLift = lift(openApp, 0n, 0n);
expect("C0 lifting zero amount remains identity", eq(zeroLift.fst, openApp));

console.log("PSKERNEL_GENERATED_SMOKE: PASS");
