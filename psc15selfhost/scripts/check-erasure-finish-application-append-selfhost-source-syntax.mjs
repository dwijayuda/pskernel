import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

export function assertFinishApplicationAppend(source) {
  const block = source.match(/^def psEraseFinishApplicationWithFuelWorker\b[\s\S]*?(?=^def psEraseFinishApplication\b)/m)?.[0];
  if (!block) throw new Error("PSC2_ERASURE_FINISH_APPLICATION_APPEND_MISSING: declaration");
  if (block.includes("++")) throw new Error("PSC2_ERASURE_FINISH_APPLICATION_APPEND_FORBIDDEN: infix append");
  const required = [
    /String\.Internal\.append\s*\(String\.Internal\.append\s*\(psNameToString name\)\s*"\$"\)\s*\(psNatToString pushed\.id\)/,
    /String\.Internal\.append\s*"arg\$"\s*\(psNatToString pushed\.id\)/,
    /psErasureAppendRuntimeArgument\s+runtimeArguments\s*\(PsVerifiedIrExpr\.var parameterName\)/,
  ];
  for (const pattern of required) {
    if (!pattern.test(block)) throw new Error(`PSC2_ERASURE_FINISH_APPLICATION_APPEND_MISSING: ${pattern}`);
  }
  const helper = source.match(/^def psErasureAppendRuntimeArgument\b[\s\S]*?(?=^def |^structure )/m)?.[0];
  if (!helper || !/\(arguments : List PsVerifiedIrExpr\)/.test(helper) ||
      !/match arguments with/.test(helper) ||
      !/\| \[\] => fun \(argument : PsVerifiedIrExpr\) => List\.cons argument List\.nil/.test(helper) ||
      !/let smaller : PsVerifiedIrExpr -> List PsVerifiedIrExpr :=\s*psErasureAppendRuntimeArgument rest;\s*fun \(argument : PsVerifiedIrExpr\) => List\.cons head \(smaller argument\)/.test(helper)) {
    throw new Error("PSC2_ERASURE_FINISH_APPLICATION_APPEND_MISSING: order-preserving list-recursive helper");
  }
  if (/List\.append|\+\+/.test(helper)) throw new Error("PSC2_ERASURE_FINISH_APPLICATION_APPEND_FORBIDDEN: generic append helper");
}

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
assertFinishApplicationAppend(await readFile(path.join(root, "packages/erasure/src/Ps/Erasure/Expr.lean"), "utf8"));
console.log("PSC2_ERASURE_FINISH_APPLICATION_APPEND: PASS (explicit string append and ordered runtime argument helper)");
