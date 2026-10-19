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

console.log("PSKERNEL_GENERATED_SMOKE: PASS");
