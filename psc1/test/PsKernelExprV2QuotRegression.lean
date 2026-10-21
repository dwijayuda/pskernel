import Ps.KernelCore.API.Dag
import Ps.KernelCore.Research.ExprV2PagedImport
import Lean

private def require (label : String) (condition : Bool) : IO Unit := do
  unless condition do throw (IO.userError ("PSC1_V2_QUOT_FAIL " ++ label))

private def expect {α : Type} : Except String α → IO α
  | .ok result => pure result
  | .error error => throw (IO.userError error)

private def expectPublic {α : Type} : Except PsKernelError α → IO α
  | .ok result => pure result
  | .error _ => throw (IO.userError "quotient fixture admission failed")

private def nm (value : String) := PsKernelName.str .anonymous value
private def nat := PsKernelExpr.const psKernelNatName []
private def one := PsKernelLevel.succ PsKernelLevel.zero
private def s1 := PsKernelExpr.sort one
private def lit (value : Nat) := PsKernelExpr.lit (.nat value)
private def lam (name : String) (type body : PsKernelExpr) :=
  PsKernelExpr.lam (nm name) type body .default
private def forallE (name : String) (type body : PsKernelExpr) :=
  PsKernelExpr.forallE (nm name) type body .default
private def apply (fn : PsKernelExpr) (args : List PsKernelExpr) := psKernelApplyArgs fn args
private def refl (type value : PsKernelExpr) :=
  apply (.const (PsKernelName.str psKernelEqName "refl") [one]) [type,value]
private def relation := PsKernelExpr.app (.const psKernelEqName [one]) nat
private def equality (left right : PsKernelExpr) := apply relation [left,right]
private def quotient := apply (.const psKernelQuotName [one]) [nat,relation]
private def major (representative : PsKernelExpr) :=
  apply (.const psKernelQuotMkName [one]) [nat,relation,representative]
private def identity := lam "x" nat (.bvar 0)
private def respectIdentity := lam "a" nat (lam "b" nat
  (lam "h" (apply relation [.bvar 1,.bvar 0]) (.bvar 0)))
private def respectConstant (type value : PsKernelExpr) := lam "a" nat (lam "b" nat
  (lam "h" (apply relation [.bvar 1,.bvar 0]) (refl type value)))
private def lift (type fn respect value : PsKernelExpr) :=
  apply (.const psKernelQuotLiftName [one,one]) [nat,relation,type,fn,respect,value]
private def liftIdentity (value : PsKernelExpr) := lift nat identity respectIdentity value
private def induction (motive minor value : PsKernelExpr) :=
  apply (.const psKernelQuotIndName [one]) [nat,relation,motive,minor,value]

private def decode (arena : PsKernelExprV2PagedArena) (root : Nat) : IO PsKernelExpr := do
  let graph ← expect (psKernelExprV2DecodeChecked arena)
  expect (psKernelExprV2DecodedRequire graph root)

private def compareWhnf (label : String)
    (original : Except String (PsKernelExpr × PsKernelCheckerState))
    (actual : Option (Except String (PsKernelExprV2WhnfState × Nat))) : IO Unit := do
  match original,actual with
  | .error a,some (.error b) => require (label ++ "-exact-error") (a == b)
  | .ok a,some (.ok b) =>
      require (label ++ "-expression") (psKernelExprEqual a.fst (← decode b.fst.arena b.snd))
  | _,none => throw (IO.userError ("unexpected quotient fallback: " ++ label))
  | _,_ => throw (IO.userError ("quotient result mismatch: " ++ label))

private def compareReduction (label : String)
    (original : Except String (Option PsKernelExpr × PsKernelCheckerState))
    (actual : Option (Except String (PsKernelExprV2WhnfState × Option Nat))) : IO Unit := do
  match original,actual with
  | .error a,some (.error b) => require (label ++ "-exact-error") (a == b)
  | .ok a,some (.ok b) =>
      match a.fst,b.snd with
      | none,none => pure ()
      | some left,some right =>
          require (label ++ "-expression") (psKernelExprEqual left (← decode b.fst.arena right))
      | _,_ => throw (IO.userError ("quotient optional result mismatch: " ++ label))
  | _,none => throw (IO.userError ("unexpected quotient reduction fallback: " ++ label))
  | _,_ => throw (IO.userError ("quotient reduction error mismatch: " ++ label))

private def inferOfficialName : PsKernelName → Lean.Name
  | .anonymous => .anonymous
  | .str parent value => .str (inferOfficialName parent) value
  | .num parent value => .num (inferOfficialName parent) value

private def inferOfficialLevel : PsKernelLevel → Option Lean.Level
  | .zero => some .zero
  | .succ value => (inferOfficialLevel value).map Lean.Level.succ
  | .max left right => do
      return .max (← inferOfficialLevel left) (← inferOfficialLevel right)
  | .imax left right => do
      return .imax (← inferOfficialLevel left) (← inferOfficialLevel right)
  | .param name => some (.param (inferOfficialName name))
  | .mvar _ => none

private def inferOfficialBinder : PsKernelBinderInfo → Lean.BinderInfo
  | .default => .default
  | .implicit => .implicit
  | .strictImplicit => .strictImplicit
  | .instImplicit => .instImplicit

private def inferOfficialExpr : PsKernelExpr → Option Lean.Expr
  | .bvar index => some (.bvar index)
  | .sort level => (inferOfficialLevel level).map Lean.Expr.sort
  | .const name levels => do
      return .const (inferOfficialName name) (← levels.mapM inferOfficialLevel)
  | .app fn arg => do
      return .app (← inferOfficialExpr fn) (← inferOfficialExpr arg)
  | .lam name domain body binderInfo => do
      return .lam (inferOfficialName name) (← inferOfficialExpr domain)
        (← inferOfficialExpr body) (inferOfficialBinder binderInfo)
  | .forallE name domain body binderInfo => do
      return .forallE (inferOfficialName name) (← inferOfficialExpr domain)
        (← inferOfficialExpr body) (inferOfficialBinder binderInfo)
  | .letE name type value body nondep => do
      return .letE (inferOfficialName name) (← inferOfficialExpr type)
        (← inferOfficialExpr value) (← inferOfficialExpr body) nondep
  | .lit (.nat value) => some (.lit (.natVal value))
  | .lit (.str value) => some (.lit (.strVal value))
  | .mdata _ body => (inferOfficialExpr body).map (Lean.Expr.mdata {})
  | .proj name index body => do
      return .proj (inferOfficialName name) index (← inferOfficialExpr body)
  | _ => none

private def officialExpr (value : PsKernelExpr) : IO Lean.Expr :=
  match inferOfficialExpr value with
  | some result => pure result
  | none => throw (IO.userError "official quotient conversion")

private def regression : IO Unit := do
  let empty ← expectPublic (psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault)
  require "quot-requires-validated-Eq"
    (match psKernelV1AdmitDeclaration empty .quot with | .error (.rejectedInvalid _) => true | _ => false)
  let natDeclaration := PsKernelSimpleInductiveDecl.mk [] psKernelNatName s1
    [PsKernelSimpleConstructorDecl.mk psKernelNatZeroName nat,
     PsKernelSimpleConstructorDecl.mk psKernelNatSuccName (forallE "n" nat nat)] false 0
  let withNat ← expectPublic (psKernelV1AdmitDeclaration empty (.ordinaryInductive natDeclaration))
  let universeName := nm "u"
  let eqDeclaration := PsKernelSimpleInductiveDecl.mk [universeName] psKernelEqName
    (psKernelExpectedEqType universeName)
    [PsKernelSimpleConstructorDecl.mk (PsKernelName.str psKernelEqName "refl")
      (psKernelExpectedEqReflType universeName)] false 2
  let withEq ← expectPublic (psKernelV1AdmitDeclaration withNat.session (.ordinaryInductive eqDeclaration))
  let admitted ← expectPublic (psKernelV1AdmitDeclaration withEq.session .quot)
  let session := admitted.session
  require "quot-admitted-from-checked-Eq" session.environment.quotInitialized
  let checker := psKernelKernelSessionChecker session [] .safe
  let major7 := major (lit 7)
  let result7 := refl nat (lit 7)
  let motive := lam "q" quotient (equality (lit 7) (lit 7))
  let minor := lam "a" nat result7
  let nestedMajor := lift quotient (lam "a" nat major7) (respectConstant quotient major7) major7
  let fnType := forallE "x" nat nat
  let constantFn := lam "a" nat identity
  let liftFn := lift fnType constantFn (respectConstant fnType identity) major7
  let motiveFn := lam "q" quotient (forallE "x" nat (equality (lit 7) (lit 7)))
  let minorFn := lam "a" nat (lam "x" nat result7)
  let partialLift := apply (.const psKernelQuotLiftName [one,one]) [nat,relation,nat,identity]
  let partialInd := apply (.const psKernelQuotIndName [one]) [nat,relation,motive]
  let fixtures : List (String × PsKernelExpr × PsKernelExpr) := [
    ("lift",liftIdentity major7,lit 7),
    ("ind",induction motive minor major7,result7),
    ("major-beta",liftIdentity (.app (lam "q" quotient (.bvar 0)) major7),lit 7),
    ("major-zeta",liftIdentity (.letE (nm "q") quotient major7 (.bvar 0) false),lit 7),
    ("major-metadata",liftIdentity (.mdata 31 major7),lit 7),
    ("major-nested-quot",liftIdentity nestedMajor,lit 7),
    ("ind-trailing",.app (induction motiveFn minorFn major7) (lit 9),result7),
    ("lift-trailing",.app liftFn (lit 9),lit 9),
    ("unsaturated-lift",partialLift,partialLift),
    ("unsaturated-ind",partialInd,partialInd)]
  Lean.initSearchPath (← Lean.findSysroot)
  let official ← Lean.importModules #[{ module := `Init }] {}
  let mut publicComparisons := 0
  let mut coreComparisons := 0
  let mut ownerComparisons := 0
  let mut reducerComparisons := 0
  for (label,expr,expected) in fixtures do
    let (arena,root) ← expect (psKernelExprV2PagedImportChecked expr)
    for fuel in [0,1,2,3,4,6,8,32] do
      for (limit,depth) in [(0,0),(1,15),(1,16)] do
        let context := { checker.context with maxRecDepth := limit,recDepth := depth }
        let oldDefEq := psKernelIsDefEqWithFuel fuel
        compareWhnf (label ++ "-public")
          (psKernelWhnfWithRecursorFuel fuel oldDefEq context psKernelCheckerStateEmpty expr)
          (psKernelExprV2TryWhnfStateWithFuel fuel context (psKernelExprV2WhnfStateEmpty arena) root)
        publicComparisons := publicComparisons + 1
        for cheapProj in [false,true] do
          compareWhnf (label ++ "-core")
            (psKernelWhnfCoreWithRecursorFuel fuel oldDefEq context psKernelCheckerStateEmpty
              expr false cheapProj)
            (psKernelExprV2CheckWhnfCoreWithFuel fuel (psKernelExprV2CheckContextEmpty context)
              (psKernelExprV2WhnfStateEmpty arena) root cheapProj)
          coreComparisons := coreComparisons + 1
    for structuralFuel in [0,1,2,3,6,16] do
      for recursorFuel in [0,1,2,8] do
        for (limit,depth) in [(0,0),(1,15),(1,16)] do
          let context := { checker.context with maxRecDepth := limit,recDepth := depth }
          let oldReducer := psKernelReduceRecursorBoundedWithFuel recursorFuel
            (psKernelIsDefEqWithFuel 64)
          let reducer := psKernelExprV2TryReduceRecursorWithLocalValuesFuel recursorFuel
            psKernelExprV2NoLocalValue
          compareWhnf (label ++ "-fixed-recursor-owner")
            (psKernelWhnfWithFuel structuralFuel oldReducer context psKernelCheckerStateEmpty expr)
            (psKernelExprV2TryWhnfStateWithReducerFuel structuralFuel reducer
              psKernelExprV2NoLocalValue context (psKernelExprV2WhnfStateEmpty arena) root)
          ownerComparisons := ownerComparisons + 1
    for fuel in [0,1,2,3,8,32] do
      compareReduction (label ++ "-bounded-reducer")
        (psKernelReduceRecursorBoundedWithFuel fuel (psKernelIsDefEqWithFuel 64)
          checker.context psKernelCheckerStateEmpty expr false false)
        (psKernelExprV2TryReduceRecursorWithLocalValuesFuel fuel psKernelExprV2NoLocalValue
          checker.context (psKernelExprV2WhnfStateEmpty arena) root false)
      reducerComparisons := reducerComparisons + 1
    let publicResult ← expectPublic (psKernelV1Whnf session [] .safe expr)
    require (label ++ "-checked-V1") (psKernelExprEq publicResult expected)
    let batch ← expectPublic (psKernelV1RunDag session [] .safe arena [.whnf root])
    require (label ++ "-checked-DAG-provider")
      (match batch.replies with | [.normalized value] => psKernelExprEq value expected | _ => false)
    let officialInput ← officialExpr expr
    let officialExpected ← officialExpr expected
    require (label ++ "-official-input-checked")
      (match Lean.Kernel.check official {} officialInput with | .ok _ => true | _ => false)
    require (label ++ "-official-equal")
      (match Lean.Kernel.isDefEq official {} officialInput officialExpected with | .ok true => true | _ => false)
  require "complete-resource-matrix"
    (publicComparisons == 240 && coreComparisons == 480 && ownerComparisons == 720 && reducerComparisons == 60)

  let invalids : List PsKernelExpr := [
    liftIdentity (apply (.const psKernelQuotMkName [one]) [nat,relation]),
    liftIdentity (apply (.const psKernelQuotMkName [one]) [nat,relation,lit 7,lit 8]),
    liftIdentity (lit 7),
    lift nat s1 respectIdentity major7,
    apply (.const psKernelQuotLiftName []) [nat,relation,nat,identity,respectIdentity,major7]]
  for expr in invalids do
    let (arena,root) ← expect (psKernelExprV2PagedImportChecked expr)
    require "public-invalid-never-normalized"
      (match psKernelV1RunDag session [] .safe arena [.whnf root] with
       | .error (.rejectedInvalid _) => true | _ => false)
    require "V1-rejects-invalid-quotient"
      (match psKernelV1Whnf session [] .safe expr with | .error (.rejectedInvalid _) => true | _ => false)
    require "official-rejects-invalid-quotient"
      (match Lean.Kernel.check official {} (← officialExpr expr) with | .error _ => true | _ => false)
    compareReduction "raw-illtyped-hook-is-not-public-admission"
      (psKernelReduceQuotWith (fun _ s value => .ok (value,s))
        checker.context psKernelCheckerStateEmpty expr)
      (psKernelExprV2TryReduceQuotWith (fun _ s value => some (.ok (s,value)))
        checker.context (psKernelExprV2WhnfStateEmpty arena) root)

  let (arena,root) ← expect (psKernelExprV2PagedImportChecked (liftIdentity major7))
  let state := psKernelExprV2WhnfStateEmpty arena
  require "public-zero-before-root"
    (match psKernelExprV2TryWhnfStateWithFuel 0 checker.context state (arena.size + 1) with
     | some (.error error) => error == "kernel reduction budget exhausted" | _ => false)
  require "recursor-zero-before-root"
    (match psKernelExprV2TryReduceRecursorWithLocalValuesFuel 0 psKernelExprV2NoLocalValue
        checker.context state (arena.size + 1) false with
     | some (.error error) => error == "kernel recursor budget exhausted" | _ => false)
  let badWhnf := fun (_ : PsKernelCheckerContext) (_ : PsKernelExprV2WhnfState) (_ : Nat) =>
    (some (.error "QUOT_MAJOR_CALLBACK") : Option (Except String (PsKernelExprV2WhnfState × Nat)))
  require "major-error-propagates"
    (match psKernelExprV2TryReduceQuotWith badWhnf checker.context state root with
     | some (.error error) => error == "QUOT_MAJOR_CALLBACK" | _ => false)
  let missingWhnf := fun (_ : PsKernelCheckerContext) (_ : PsKernelExprV2WhnfState) (_ : Nat) =>
    (none : Option (Except String (PsKernelExprV2WhnfState × Nat)))
  require "major-unsupported-propagates"
    (psKernelExprV2TryReduceQuotWith missingWhnf checker.context state root).isNone
  let coldChecker := psKernelKernelSessionChecker withEq.session [] .safe
  require "quot-disabled-before-root-or-callback"
    (match psKernelExprV2TryReduceQuotWith badWhnf coldChecker.context state (arena.size + 1) with
     | some (.ok result) => result.snd.isNone && result.fst.arena.size == arena.size | _ => false)
  let (shortArena,shortRoot) ← expect (psKernelExprV2PagedImportChecked partialLift)
  require "unsaturated-before-callback"
    (match psKernelExprV2TryReduceQuotWith badWhnf checker.context
        (psKernelExprV2WhnfStateEmpty shortArena) shortRoot with
     | some (.ok result) => result.snd.isNone | _ => false)
  let warm ← match psKernelExprV2TryWhnfStateWithFuel 32 checker.context state root with
    | some result => expect result
    | none => throw (IO.userError "warm quotient fallback")
  require "public-cache-is-operation-owned" (!(psKernelExprV2WhnfCacheEntries warm.fst.publicCache).isEmpty)
  require "warm-zero-still-rejects"
    (match psKernelExprV2TryWhnfStateWithFuel 0 checker.context warm.fst root with
     | some (.error error) => error == "kernel reduction budget exhausted" | _ => false)
  let noRecursor := PsKernelExpr.app (.const psKernelNatZeroName []) (lit 0)
  let (inertArena,inertRoot) ← expect (psKernelExprV2PagedImportChecked noRecursor)
  compareReduction "zero-recursion-owner-precedes-inert-head"
    (psKernelReduceRecursorBoundedWithFuel 0 (psKernelIsDefEqWithFuel 32)
      checker.context psKernelCheckerStateEmpty noRecursor false false)
    (psKernelExprV2TryReduceRecursorWithLocalValuesFuel 0 psKernelExprV2NoLocalValue
      checker.context (psKernelExprV2WhnfStateEmpty inertArena) inertRoot false)
  IO.println "PSC1_V2_DAG_QUOT: PASS public=240 core=480 owners=720 reducer=60"
  IO.println "PSC1_V2_DAG_OFFICIAL_QUOT: PASS valid=10 invalid=5"

def main : IO Unit := regression
