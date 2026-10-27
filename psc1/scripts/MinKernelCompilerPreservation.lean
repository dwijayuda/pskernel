import Ps.Erasure.Expr
import Ps.BackendTs.Sh1
import Ps.Host.ProjectCompiler
import Ps.Bridge.Json

-- Host-only Linux oracle and artifact producer. Not a runtime kernel import.
def r5NatType : PsVerifiedIrType := .primitive .nat
def r5BoolType : PsVerifiedIrType := .primitive .bool
def r5Nat (n : Nat) : PsVerifiedIrExpr := .literal (.natural n)
def r5Bool (b : Bool) : PsVerifiedIrExpr := .literal (.bool b)
def r5Binary (op : PsVerifiedIrIntrinsic) (a b : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  .intrinsic op [] [a, b]

def r5Emit (expr : PsVerifiedIrExpr) : IO String :=
  match psTsEmitExpr [] [] expr with
  | .ok text => pure text
  | .error _ => throw (IO.userError "R5_EXPR_EMISSION_REFUSED")

def r5Source : String :=
  "def psR5Add (a : Nat) (b : Nat) : Nat := Nat.add a b\n" ++
  "def psR5Sub (a : Nat) (b : Nat) : Nat := Nat.sub a b\n" ++
  "def psR5Choose (flag : Bool) (a : Nat) (b : Nat) : Nat :=\n  if flag then Nat.add a b else Nat.sub a b\n" ++
  "def psR5Three (a : Nat) (b : Nat) (c : Nat) : Nat := Nat.add a (Nat.add b c)\n" ++
  "def psR5Capture (a : Nat) (b : Nat) (c : Nat) : Nat :=\n  let pending : Nat -> Nat := psR5Three (Nat.add a 1) (Nat.add b 2)\n  pending c\n" ++
  "def psR5UseClosure (seed : Nat) (value : Nat) : Nat :=\n  let captured := Nat.add seed 1\n  let fn : Nat -> Nat := fun (arg : Nat) => Nat.add captured arg\n  fn value\n"

def main : IO Unit := do
  let dir := "dist/pskernel-min/compiler-preservation"
  IO.FS.createDirAll dir
  let values : List Nat := [0, 1, 2, 9007199254740991, 9007199254740992,
    9007199254740993, 2 ^ 256 + 12345]
  let operations : List (String × PsVerifiedIrIntrinsic × (Nat → Nat → String) × String) := [
    ("add", .natAdd, fun a b => toString (a + b), "bigint"),
    ("sub", .natSub, fun a b => toString (a - b), "bigint"),
    ("mul", .natMul, fun a b => toString (a * b), "bigint"),
    ("div", .natDiv, fun a b => toString (a / b), "bigint"),
    ("mod", .natMod, fun a b => toString (a % b), "bigint"),
    ("eq", .natEq, fun a b => if a == b then "true" else "false", "boolean"),
    ("le", .natLe, fun a b => if a ≤ b then "true" else "false", "boolean"),
    ("lt", .natLt, fun a b => if a < b then "true" else "false", "boolean")]
  let mut functions : List String := []
  let mut expected : List String := []
  for (name, op, oracle, kind) in operations do
    for a in values do
      for b in values do
        let text ← r5Emit (r5Binary op (r5Nat a) (r5Nat b))
        functions := functions ++ ["() => (" ++ text ++ ")"]
        expected := expected ++ [psJsonObject [("operation", psJsonQuote name),
          ("left", psJsonQuote (toString a)), ("right", psJsonQuote (toString b)),
          ("type", psJsonQuote kind), ("value", psJsonQuote (oracle a b))]]
  for a in [false, true] do
    for b in [false, true] do
      for op in [PsVerifiedIrIntrinsic.boolAnd, .boolOr] do
        let text ← r5Emit (r5Binary op (r5Bool a) (r5Bool b))
        let result := match op with | .boolAnd => a && b | _ => a || b
        functions := functions ++ ["() => (" ++ text ++ ")"]
        expected := expected ++ [psJsonObject [("operation", psJsonQuote "bool"),
          ("type", psJsonQuote "boolean"), ("value", psJsonQuote (toString result))]]
  let first := (PsVerifiedIrParameter.mk "capturedA" r5NatType, r5Nat 5)
  let second := (PsVerifiedIrParameter.mk "capturedB" r5NatType,
    r5Binary .natAdd (.var "capturedA") (r5Nat 2))
  let capture ← r5Emit (psErasureWrapApplicationCaptures [second, first]
    (r5Binary .natSub (.var "capturedB") (.var "capturedA")))
  let params := [PsVerifiedIrParameter.mk "x" r5NatType,
    PsVerifiedIrParameter.mk "y" r5NatType, PsVerifiedIrParameter.mk "flag" r5BoolType]
  let body : PsVerifiedIrExpr := .ifE (.var "flag")
    (r5Binary .natAdd (.var "x") (.var "y"))
    (r5Binary .natSub (.var "x") (.var "y"))
  let curry ← r5Emit (psErasureCurryParameters params r5NatType body).2
  let shadow ← r5Emit (psErasureCurryParameters
    [PsVerifiedIrParameter.mk "same" r5NatType, PsVerifiedIrParameter.mk "same" r5NatType]
    r5NatType (.var "same")).2
  let mut traced : List String := []
  for (_, op, _, _) in operations do
    match psTsEmitIntrinsicFromPrinted op ["left()", "right()"] with
    | .error _ => throw (IO.userError "R5_TEMPLATE_REFUSED")
    | .ok text => traced := traced ++ ["() => {const log: string[]=[]; const left=()=>{log.push('L');return 17n}; const right=()=>{log.push('R');return 3n}; const value=(" ++ text ++ "); return {value,trace:log.join('')}}"]
  for op in [PsVerifiedIrIntrinsic.boolAnd, .boolOr] do
    for left in [false, true] do
      match psTsEmitIntrinsicFromPrinted op ["left()", "right()"] with
      | .error _ => throw (IO.userError "R5_BOOL_TEMPLATE_REFUSED")
      | .ok text => traced := traced ++ ["() => {const log: string[]=[]; const left=()=>{log.push('L');return " ++ (if left then "true" else "false") ++ "}; const right=()=>{log.push('R');return true}; const value=(" ++ text ++ "); return {value,trace:log.join('')}}"]
  let mut arityRefusals := 0
  for (_, op, _, _) in operations do
    for args in [[], ["a"], ["a","b","c"]] do
      match psTsEmitIntrinsicFromPrinted op args with
      | .error .intrinsicArity => arityRefusals := arityRefusals + 1
      | _ => throw (IO.userError "R5_ARITY_GUARD_CHANGED")
  for op in [PsVerifiedIrIntrinsic.boolAnd, .boolOr] do
    for args in [[], ["a"], ["a","b","c"]] do
      match psTsEmitIntrinsicFromPrinted op args with
      | .error .intrinsicArity => arityRefusals := arityRefusals + 1
      | _ => throw (IO.userError "R5_BOOL_ARITY_GUARD_CHANGED")
  let invalid : List PsVerifiedIrExpr := [
    r5Binary .natAdd (r5Bool true) (r5Nat 1),
    .ifE (r5Nat 1) (r5Nat 2) (r5Nat 3),
    .ifE (r5Bool true) (r5Nat 2) (r5Bool false),
    .var "missing"]
  let mut strictRefusals := 0
  for body in invalid do
    let module := PsVerifiedIrModule.mk [] [] []
      [PsVerifiedIrDeclaration.mk "invalid" [] [] r5NatType body]
    match psTsEmitCheckedModule psIrCheckDefaultOptions module with
    | .error (.check _) => strictRefusals := strictRefusals + 1
    | _ => throw (IO.userError "R5_CHECKED_EMISSION_ACCEPTED_INVALID_IR")
  IO.FS.writeFile (dir ++ "/direct.ts")
    ("export const probes = [" ++ String.intercalate ",\n" functions ++ "];\n" ++
      "export const traced = [" ++ String.intercalate ",\n" traced ++ "];\n" ++
      "export const captureProbe = () => (" ++ capture ++ ");\n" ++
      "export const curryProbe = (" ++ curry ++ ");\n" ++
      "export const shadowProbe = (" ++ shadow ++ ");\n")
  IO.FS.writeFile (dir ++ "/native.json")
    (psJsonObject [("schema", psJsonQuote "psc1-r5-native-oracle/1"),
      ("probes", psJsonArray expected), ("arityRefusals", toString arityRefusals),
      ("strictIrRefusals", toString strictRefusals)] ++ "\n")
  IO.FS.writeFile (dir ++ "/source.lean") r5Source
  let inputs := [psSh1SourceInput ["R5", "Scalar"] r5Source]
  match psCompilerSh1TypeScriptSources psSh1DefaultSourceOptions psIrCheckDefaultOptions
      PsCompilerSourceKind.lean inputs with
  | .error _ => throw (IO.userError "R5_ACTUAL_SOURCE_COMPILATION_REFUSED")
  | .ok result =>
      if !result.sourcePolicy.accepted || !result.targetPolicy.accepted ||
          !result.checkReport.accepted || !result.checkReport.traversalComplete then
        throw (IO.userError "R5_SOURCE_OR_IR_GUARD_REFUSED")
      IO.FS.writeFile (dir ++ "/whole.ts") result.typeScript
      IO.FS.writeFile (dir ++ "/whole.admissions.json") result.admissions
      IO.FS.writeFile (dir ++ "/source-policy.json")
        (psJsonObject [("sourceAccepted", "true"), ("targetAccepted", "true"),
          ("originalIrAccepted", "true"), ("providerChecked", toString result.providerChecked),
          ("strictSh1Qualified", toString result.strictSh1Qualified),
          ("semanticContractQualified", toString result.semanticContractQualified),
          ("moduleCount", toString result.sourcePolicy.moduleCount),
          ("originModuleCount", toString result.origins.length)] ++ "\n")
  IO.println "PSC1_R5_NATIVE_ORACLE_AND_ACTUAL_SOURCE_PASS"
