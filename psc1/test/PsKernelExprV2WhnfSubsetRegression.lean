import Ps.KernelCore.Checker.Session
import Ps.KernelCore.Research.ExprV2Validation
import Ps.KernelCore.Research.ExprV2PagedImport
import Ps.KernelCore.Research.ExprV2PagedWhnfSubset

/-
Research-only V2 paged application-function WHNF subset oracle.

All positive terms are fully checked through the original independent
production PSKernel-Core SessionCheck, SessionWhnf and SessionIsDefEq.
Only then is V2's bounded restricted result compared structurally.

This test does NOT authorize V2 for proof checking or claim full Lean WHNF
semantics / matching checker fuel. Invalid applications must be rejected
by the existing full checker.
-/

private def whnfSort0 : PsKernelExpr :=
  PsKernelExpr.sort PsKernelLevel.zero

private def whnfSort1 : PsKernelExpr :=
  PsKernelExpr.sort (PsKernelLevel.succ PsKernelLevel.zero)

private def whnfSession : PsKernelCheckerSession :=
  psKernelMkCheckerSession
    psKernelEnvironmentEmpty
    List.nil
    PsKernelDefinitionSafety.safe
    4096
    psKernelLeanNatMaxSizeDefault

private def whnfExpect {α : Type}
    (value : Except String α) : IO α := do
  match value with
  | Except.ok result => return result
  | Except.error error =>
      throw (IO.userError ("PSC1_V2_WHNF_UNEXPECTED_ERROR " ++ error))

private def whnfRequire (label : String) (ok : Bool) : IO Unit := do
  unless ok do
    throw (IO.userError ("PSC1_V2_WHNF_FAILED " ++ label))

private def whnfDecodePaged
    (arena : PsKernelExprV2PagedArena)
    (root : Nat) : IO PsKernelExpr := do
  let verified ← whnfExpect (psKernelExprV2PagedValidate arena)
  let mut flat := psKernelExprV2Empty
  for id in [:verified.size] do
    let entry ← whnfExpect (psKernelExprV2PagedRequire verified id)
    flat := (psKernelExprV2Push flat entry).fst
  whnfExpect (psKernelExprV2Decode flat root)

private def whnfPositive
    (label : String) (source : PsKernelExpr)
    (expectedType expectedWhnf : PsKernelExpr) : IO Unit := do
  let typeChecked ← whnfExpect (psKernelSessionCheck 4096 whnfSession source)
  whnfRequire (label ++ "-typed")
    (psKernelExprEq (Prod.fst typeChecked) expectedType)
  let oldWhnf ← whnfExpect (psKernelSessionWhnf 4096 whnfSession source)
  whnfRequire (label ++ "-whnf")
    (psKernelExprEq (Prod.fst oldWhnf) expectedWhnf)
  let oldDefEq ← whnfExpect
    (psKernelSessionIsDefEq 4096 whnfSession source expectedWhnf)
  whnfRequire (label ++ "-defeq") (Prod.fst oldDefEq)
  let (input,root) ← whnfExpect (psKernelExprV2PagedImportChecked source)
  let (reduced,id) ← whnfExpect
    (psKernelExprV2PagedWhnfSubsetChecked 24 input root)
  let actual ← whnfDecodePaged reduced id
  whnfRequire (label ++ "-strict-shape")
    (psKernelExprEqual actual expectedWhnf)
  whnfRequire (label ++ "-semantic-shape")
    (psKernelExprEq actual (Prod.fst oldWhnf))
  IO.println ("PSC1_V2_WHNF_CASE PASS " ++ label)

private def testWhnfFunctionReduction : IO Unit := do
  let name := PsKernelName.str PsKernelName.anonymous "beta-whnf"
  let identity : PsKernelExpr :=
    PsKernelExpr.lam name whnfSort1 (PsKernelExpr.bvar 0)
      PsKernelBinderInfo.default
  let functionType : PsKernelExpr :=
    PsKernelExpr.forallE name whnfSort1 whnfSort1
      PsKernelBinderInfo.default
  let letFunction : PsKernelExpr :=
    PsKernelExpr.letE name functionType identity
      (PsKernelExpr.bvar 0) false
  let beta := PsKernelExpr.app identity whnfSort0
  let letHeadBeta := PsKernelExpr.app letFunction whnfSort0
  let metadataHeadBeta := PsKernelExpr.app
    (PsKernelExpr.mdata 9 identity) whnfSort0
  let nestedFunction := PsKernelExpr.app
    (PsKernelExpr.mdata 11 letFunction) whnfSort0
  let zeta : PsKernelExpr :=
    PsKernelExpr.letE name whnfSort1 whnfSort0
      (PsKernelExpr.bvar 0) false

  whnfPositive "direct-beta" beta whnfSort1 whnfSort0
  whnfPositive "let-function-beta" letHeadBeta whnfSort1 whnfSort0
  whnfPositive "metadata-function-beta" metadataHeadBeta whnfSort1 whnfSort0
  whnfPositive "metadata-let-function-beta"
    nestedFunction whnfSort1 whnfSort0
  whnfPositive "direct-zeta" zeta whnfSort1 whnfSort0

  let malformed := PsKernelExpr.app whnfSort0 whnfSort0
  whnfRequire "full-checker-invalid-app-rejected"
    (match psKernelSessionCheck 4096 whnfSession malformed with
      | Except.error _ => true
      | Except.ok _ => false)
  let (neutralArena,neutralRoot) ←
    whnfExpect (psKernelExprV2PagedImportChecked malformed)
  let (unchanged,root) ← whnfExpect
    (psKernelExprV2PagedWhnfSubsetChecked
      8 neutralArena neutralRoot)
  whnfRequire "subset-stuck-neutral-is-not-proof-acceptance"
    (root == neutralRoot && unchanged.size == neutralArena.size)
  whnfRequire "zero-fuel-rejected"
    (match psKernelExprV2PagedWhnfSubsetChecked
        0 neutralArena neutralRoot with
      | Except.error _ => true
      | Except.ok _ => false)
  whnfRequire "invalid-root-rejected"
    (match psKernelExprV2PagedWhnfSubsetChecked
        8 neutralArena 9999 with
      | Except.error _ => true
      | Except.ok _ => false)
  let (valid,leaf) ← whnfExpect
    (psKernelExprV2PagedMkBVar psKernelExprV2PagedEmpty 0)
  let item ← whnfExpect (psKernelExprV2PagedRequire valid leaf)
  let forged : PsKernelExprV2Entry := {
    item with hasFVar := true
  }
  let (bad,badId) := psKernelExprV2PagedPush psKernelExprV2PagedEmpty forged
  whnfRequire "forged-metadata-rejected"
    (match psKernelExprV2PagedWhnfSubsetChecked 8 bad badId with
      | Except.error _ => true
      | Except.ok _ => false)
  IO.println "PSC1_V2_WHNF_SUBSET: PASS cases=5"

def main : IO Unit := do
  testWhnfFunctionReduction
