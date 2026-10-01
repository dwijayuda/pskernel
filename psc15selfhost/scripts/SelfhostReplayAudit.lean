import Ps.Bootstrap.SelfHost
import Ps.Host.ProjectCompiler

-- Native-host regression and diagnostics only; not in the portable source closure.
theorem psAuditAppendRuntimeArgumentPreservesOrder
    (arguments : List PsVerifiedIrExpr) (argument : PsVerifiedIrExpr) :
    psErasureAppendRuntimeArgument arguments argument = arguments ++ [argument] := by
  induction arguments with
  | nil => rfl
  | cons head rest ih =>
      change List.cons head (psErasureAppendRuntimeArgument rest argument) =
        List.cons head (rest ++ [argument])
      exact congrArg (List.cons head) ih

def psAuditRuntimeNames (values : List PsVerifiedIrExpr) : List String :=
  values.map fun value => match value with
    | .var name => name
    | _ => "<not-var>"

def psAuditFinish (fuel : Nat) (type : PsExpr) (arguments : List PsVerifiedIrExpr) :=
  psEraseFinishApplicationWithFuel psBootstrapPreludeEnvironment
    (psErasureScopeEmpty []) (.var "f") [] fuel type [] arguments

def psAuditNat : PsExpr := PsExpr.constE psNatName []

def psAuditRuntimeBinders : Bool :=
  let type := PsExpr.forallE (psRootName "x") psAuditNat
    (PsExpr.forallE (psRootName "y") psAuditNat psAuditNat .explicit) .explicit
  match psAuditFinish 4 type [.var "existing"] with
  | Except.ok (.lambda parameters (.primitive .nat) (.call (.var "f") [] arguments)) =>
      parameters.map (fun parameter => parameter.name) == ["x$0", "y$1"] &&
        psAuditRuntimeNames arguments == ["existing", "x$0", "y$1"]
  | _ => false

def psAuditProofBinders : Bool :=
  let type := PsExpr.forallE (psRootName "p") (.sortE .zero)
    (PsExpr.forallE (psRootName "h") (.bvar 0)
      (PsExpr.forallE (psRootName "x") psAuditNat psAuditNat .explicit) .explicit) .explicit
  match psAuditFinish 5 type [] with
  | Except.ok (.lambda parameters (.primitive .nat) (.call (.var "f") [] arguments)) =>
      parameters.map (fun parameter => parameter.name) == ["x$2"] &&
        psAuditRuntimeNames arguments == ["x$2"]
  | _ => false

def psAuditName : Bool :=
  let type := PsExpr.forallE (psRootName "bad-name") psAuditNat psAuditNat .explicit
  match psAuditFinish 2 type [] with
  | Except.ok (.lambda parameters _ _) =>
      parameters.map (fun parameter => parameter.name) == ["bad_name$0"]
  | _ => false

def psAuditBaseCases : Bool :=
  let empty := match psAuditFinish 1 psAuditNat [] with
    | Except.ok (.var "f") => true
    | _ => false
  let ordered := match psAuditFinish 1 psAuditNat [.var "a", .var "b"] with
    | Except.ok (.call (.var "f") [] arguments) => psAuditRuntimeNames arguments == ["a", "b"]
    | _ => false
  let exhausted := match psAuditFinish 0 psAuditNat [] with
    | Except.error .fuelExhausted => true
    | _ => false
  let typeBinder := PsExpr.forallE (psRootName "T") (.sortE (.succ .zero)) psAuditNat .explicit
  let rejected := match psAuditFinish 2 typeBinder [] with
    | Except.error .unsupportedApplication => true
    | _ => false
  empty && ordered && exhausted && rejected

def main (arguments : List String) : IO UInt32 := do
  if arguments == ["--behavior"] then
    for (label, passed) in [("runtime argument and parameter order", psAuditRuntimeBinders),
        ("proof erasure and local IDs", psAuditProofBinders),
        ("sanitized parameter names", psAuditName),
        ("base cases, fuel and unsupported type binder", psAuditBaseCases)] do
      if passed then IO.println ("PSC2_FIXED_POINT_ERASURE_CASE: PASS " ++ label)
      else throw (IO.userError ("PSC2_FIXED_POINT_ERASURE_CASE: FAIL " ++ label))
    IO.println "PSC2_FIXED_POINT_ERASURE_FINISH_APPLICATION: PASS (native behavior and append-order theorem)"
    return 0
  let mut failures := 0
  for file in arguments do
    try
      let source ← IO.FS.readFile file
      let _ ← psHostParseSource file source
      IO.println ("PSC2_FIXED_POINT_PARSE_FILE: PASS " ++ file)
    catch error =>
      failures := failures + 1
      IO.println ("PSC2_FIXED_POINT_PARSE_FILE: FAIL " ++ file ++ " | " ++ error.toString)
  IO.println ("PSC2_FIXED_POINT_PARSE_SUMMARY: files=" ++ toString arguments.length ++
    " failures=" ++ toString failures)
  return if failures == 0 then 0 else 1
