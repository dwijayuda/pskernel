import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/meta/src/Ps/Meta/SynthInstance.lean"),
  "utf8",
);

const required = [
  "def psPrepareInstanceWithFuelWorker\n    (remainingFuel : Nat) :",
  "psPrepareInstanceWithFuelWorker fuel;",
  "def psPrepareInstanceWithFuel\n    (environment : PsEnvironment)\n    (localContext : PsLocalContext)\n    (context : PsMetaContext)\n    (value : PsExpr)\n    (type : PsExpr)\n    (arguments : List PsPreparedInstanceArgument)\n    (fuel : Nat) : PsPreparedInstance :=\n  psPrepareInstanceWithFuelWorker",
  "let typeValue :=",
  "psWhnf environment context localContext type;",
  "let kind :=",
  "PsMetaVarKind.natural;",
  "let fresh := psMetaFresh context localContext domain kind;",
  "let nextValue := PsExpr.app value fresh.expr;",
  "let nextType := psExprInstantiate1 body fresh.expr;",
  "def psSolvePreparedInstanceArgumentsWorker\n    (arguments : List PsPreparedInstanceArgument) :",
  "psSolvePreparedInstanceArgumentsWorker rest;",
  "def psSolvePreparedInstanceArguments\n    (synthesize : PsMetaContext -> PsExpr -> PsSynthInstanceResult)\n    (arguments : List PsPreparedInstanceArgument)\n    (current : PsMetaContext) : PsSolveInstanceArgsResult :=\n  psSolvePreparedInstanceArgumentsWorker",
  "let targetType := psMetaInstantiate current argument.type;",
  "let synthesized := synthesize current targetType;",
  "let prepared :=",
  "psPrepareInstance environment localContext original entry;",
  "let targetResult :=",
  "prepared.resultType\n        target;",
  "let solved :=",
  "targetResult.context;",
  "let finalValue :=",
  "psMetaInstantiate solved.context prepared.value;",
  "def psTryInstanceCandidatesWorker\n    (entries : List PsInstanceEntry) :",
  "psTryInstanceCandidatesWorker rest;",
  "def psTryInstanceCandidates\n    (environment : PsEnvironment)\n    (localContext : PsLocalContext)\n    (original : PsMetaContext)\n    (target : PsExpr)\n    (synthesize : PsMetaContext -> PsExpr -> PsSynthInstanceResult)\n    (entries : List PsInstanceEntry) : PsSynthInstanceResult :=\n  psTryInstanceCandidatesWorker",
  "def psSynthInstanceWithFuelWorker\n    (remainingFuel : Nat) :",
  "psSynthInstanceWithFuelWorker fuel;",
  "fun (nextContext : PsMetaContext) =>",
  "fun (nextTarget : PsExpr) =>",
  "def psSynthInstanceWithFuel\n    (environment : PsEnvironment)\n    (localContext : PsLocalContext)\n    (index : PsInstanceIndex)\n    (context : PsMetaContext)\n    (fuel : Nat)\n    (target : PsExpr) : PsSynthInstanceResult :=\n  psSynthInstanceWithFuelWorker",
];

for (const marker of required) {
  if (!source.includes(marker)) {
    throw new Error(`PSC2_SYNTH_INSTANCE_SELFHOST_SOURCE_SYNTAX_MISSING: ${marker}`);
  }
}

const requiredPatterns = [
  /def psPreparedInstanceArgumentListReverseAux\s*\(remaining : List PsPreparedInstanceArgument\) :\s*List PsPreparedInstanceArgument -> List PsPreparedInstanceArgument :=\s*match remaining with/,
  /\| List\.nil =>\s*fun \(acc : List PsPreparedInstanceArgument\) => acc/,
  /\| List\.cons head tail =>\s*let smaller :\s*List PsPreparedInstanceArgument -> List PsPreparedInstanceArgument :=\s*psPreparedInstanceArgumentListReverseAux tail;/,
  /fun \(acc : List PsPreparedInstanceArgument\) =>\s*smaller \(List\.cons head acc\)/,
  /def psPreparedInstanceArgumentListReverse\s*\(values : List PsPreparedInstanceArgument\) :\s*List PsPreparedInstanceArgument :=\s*psPreparedInstanceArgumentListReverseAux values List\.nil/,
  /arguments := psPreparedInstanceArgumentListReverse arguments/,
];

for (const pattern of requiredPatterns) {
  if (!pattern.test(source)) {
    throw new Error(`PSC2_SYNTH_INSTANCE_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`);
  }
}

const forbidden = [
  ":\n    Nat -> PsPreparedInstance\n  | 0 =>",
  "let typeValue := psWhnf environment context localContext type\n      match typeValue with",
  "List PsPreparedInstanceArgument ->\n    PsMetaContext ->\n    PsSolveInstanceArgsResult\n  | [], current =>",
  "let targetType := psMetaInstantiate current argument.type\n                let synthesized :=",
  "if !prepared.success then",
  "if !targetResult.success then",
  "if !solved.success then",
  "List PsInstanceEntry -> PsSynthInstanceResult\n  | [] =>",
  ":\n    Nat -> PsExpr -> PsSynthInstanceResult\n  | 0, _ =>",
  "| fuel + 1, target =>",
  "fun nextContext nextTarget =>",
  ".reverse",
  "List.reverse",
];

for (const marker of forbidden) {
  if (source.includes(marker)) {
    throw new Error(`PSC2_SYNTH_INSTANCE_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${marker}`);
  }
}

process.stdout.write(
  "PSC2_SYNTH_INSTANCE_SELFHOST_SOURCE_SYNTAX: PASS (explicit sequencing, local List reverse, and invariant-safe instance recursion)\n",
);
