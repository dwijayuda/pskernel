import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const quick = await readFile(
  path.join(root, "packages/pskernel-core/src/Ps/KernelCore/Checker/DefEq/Quick.lean"),
  "utf8",
);
const cache = await readFile(
  path.join(root, "packages/pskernel-core/src/Ps/KernelCore/Runtime/Acceleration/Cache.lean"),
  "utf8",
);
const finalRules = await readFile(
  path.join(root, "packages/pskernel-core/src/Ps/KernelCore/Checker/DefEq/FinalRules.lean"),
  "utf8",
);

if (!quick.includes("psKernelExprPairSetContains") || !quick.includes("state.success")) {
  throw new Error("PSC_DEFEQ_CACHE_SUCCESS_LOOKUP");
}
if (
  !cache.includes("structure PsKernelExprPairSet") ||
  !cache.includes("psKernelExprPairSetContainsIn") ||
  !cache.includes("psKernelExprPairSetInsert")
) {
  throw new Error("PSC_DEFEQ_CACHE_PAIR_SET");
}
for (const forbidden of ["UnionFind", "EquivManager", "unionFind", "equivalenceClosure"]) {
  if (quick.includes(forbidden) || cache.includes(forbidden)) {
    throw new Error("PSC_DEFEQ_CACHE_FORBIDDEN_CLOSURE: " + forbidden);
  }
}
if (
  !finalRules.includes("algorithmic definitional equality is intentionally incomplete") ||
  !finalRules.includes("non-transitive")
) {
  throw new Error("PSC_DEFEQ_RELATION_POLICY");
}
process.stdout.write(
  "PSCV_DEFEQ_CACHE_SOURCE: PASS (pair-local memoization; no equivalence closure)\n",
);
