import Ps.KernelCore.API.Dag
import Ps.KernelCore.Research.ExprV2PagedImport
import Lean

/- The String cases below inspect raw reduction and the official Init kernel.
No portable String/ByteArray declaration closure is fabricated or admitted.
The separately checked ordinary structure exercises the shared field selection. -/
private def require (label : String) (condition : Bool) : IO Unit := do
  unless condition do throw (IO.userError ("PSC1_V2_STRING_PROJECTION_FAIL " ++ label))

private def expect {α : Type} : Except String α → IO α
  | .ok result => pure result
  | .error error => throw (IO.userError error)

private def expectPublic {α : Type} (label : String) : Except PsKernelError α → IO α
  | .ok result => pure result
  | .error (.rejectedInvalid message) => throw (IO.userError (label ++ ": rejectedInvalid " ++ message))
  | .error (.declinedUnsupported message) => throw (IO.userError (label ++ ": declinedUnsupported " ++ message))
  | .error (.resourceExhausted _ message) => throw (IO.userError (label ++ ": resourceExhausted " ++ message))
  | .error (.internalError message) => throw (IO.userError (label ++ ": internalError " ++ message))

private def nm (value : String) := PsKernelName.str .anonymous value
private def one := PsKernelLevel.succ PsKernelLevel.zero
private def s1 := PsKernelExpr.sort one
private def nat := PsKernelExpr.const psKernelNatName []
private def lit (value : Nat) := PsKernelExpr.lit (.nat value)
private def boxName := nm "StringProjectionBox"
private def boxCtor := PsKernelName.str boxName "mk"
private def box := PsKernelExpr.const boxName []
private def forallE (name : String) (type body : PsKernelExpr) :=
  PsKernelExpr.forallE (nm name) type body .default
private def strings := ["","a","é","é","🙂","a" ++ String.singleton (Char.ofNat 0) ++ "β"]

private def decode (arena : PsKernelExprV2PagedArena) (root : Nat) : IO PsKernelExpr := do
  let graph ← expect (psKernelExprV2DecodeChecked arena)
  expect (psKernelExprV2DecodedRequire graph root)

private def compare (label : String)
    (original : Except String (PsKernelExpr × PsKernelCheckerState))
    (actual : Option (Except String (PsKernelExprV2CheckState × Nat))) : IO Unit := do
  match original,actual with
  | .error a,some (.error b) => require (label ++ "-exact-error") (a == b)
  | .ok a,some (.ok b) =>
      require (label ++ "-expression") (psKernelExprEqual a.fst (← decode b.fst.whnf.arena b.snd))
      require (label ++ "-fresh-counter") (a.snd.nextFresh == b.fst.nextFresh)
  | _,none => throw (IO.userError ("unexpected String projection fallback: " ++ label))
  | _,_ => throw (IO.userError ("String projection result mismatch: " ++ label))

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
  | none => throw (IO.userError "official recursor conversion")

private structure Prepared where
  session : PsKernelKernelSession
  arena : PsKernelExprV2PagedArena
  commands : List PsKernelDagCommand
  declarations : List PsKernelExprV2DeclarationRef

private def prepareInductive (label : String) (prior : Prepared) (decl : PsKernelSimpleInductiveDecl) :
    IO Prepared := do
  let admitted ← expectPublic ("admit-" ++ label)
    (psKernelV1AdmitDeclaration prior.session (.ordinaryInductive decl))
  let (a,type) ← expect (psKernelExprV2PagedImportIntoChecked prior.arena decl.type)
  let mut arena := a
  let mut ctors := []
  for ctor in decl.ctors do
    let (a,root) ← expect (psKernelExprV2PagedImportIntoChecked arena ctor.type)
    arena := a
    ctors := ctors ++ [PsKernelDagConstructor.mk ctor.name root]
  let request := PsKernelDagDeclarationRequest.ordinaryInductive decl.levelParams decl.numParams
    (PsKernelDagInductive.mk decl.name type ctors) decl.isUnsafe
  pure (Prepared.mk admitted.session arena (prior.commands ++ [.admit request])
    (psKernelDagDeclarationsAfterAdmission request prior.declarations))

private def officialInductive (environment : Lean.Environment)
    (decl : PsKernelSimpleInductiveDecl) : IO Lean.Environment := do
  let type ← officialExpr decl.type
  let mut constructors : List Lean.Constructor := []
  for ctor in decl.ctors do
    constructors := constructors ++ [{ name := inferOfficialName ctor.name, type := ← officialExpr ctor.type }]
  match environment.addDeclCore 0 0 (.inductDecl
      (decl.levelParams.map inferOfficialName) decl.numParams
      [{ name := inferOfficialName decl.name, type := type, ctors := constructors }] decl.isUnsafe)
      none true with
  | .ok next => pure next
  | .error _ => throw (IO.userError "official checked inductive fixture failed")

private def resourceMatrix (prepared : Prepared) : IO Unit := do
  let scalar := (psKernelKernelSessionChecker prepared.session [] .safe).context
  let oldNoRec := fun (_ : PsKernelCheckerContext) (state : PsKernelCheckerState)
      (_ : PsKernelExpr) (_ _ : Bool) =>
    (Except.ok (none,state) : Except String (Option PsKernelExpr × PsKernelCheckerState))
  let newNoRec := fun (_ : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
      (_ : Nat) (_ _ : Bool) =>
    (some (.ok (state,none)) : Option (Except String (PsKernelExprV2CheckState × Option Nat)))
  let mut publics := 0
  let mut cores := 0
  let mut fixed := 0
  for value in strings do
    let term := PsKernelExpr.proj psKernelStringName 0 (.lit (.str value))
    let (arena,root) ← expect (psKernelExprV2PagedImportIntoChecked prepared.arena term)
    let initial := psKernelExprV2CheckStateFromWhnf
      (psKernelExprV2WhnfStateForDeclarations arena prepared.declarations)
    for fuel in [0,1,2,3,8,32,64] do
      for (limit,depth) in [(0,0),(1,15),(1,16)] do
        let oldContext := { scalar with maxRecDepth := limit,recDepth := depth }
        let context := psKernelExprV2CheckContextEmpty oldContext
        compare "String-projection-public"
          (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel)
            oldContext psKernelCheckerStateEmpty term)
          (psKernelExprV2TryWhnfCheckStateWithFuel fuel context initial root)
        publics := publics + 1
        for cheapRec in [false,true] do
          for cheapProj in [false,true] do
            compare "String-projection-core"
              (psKernelWhnfCoreWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel)
                oldContext psKernelCheckerStateEmpty term cheapRec cheapProj)
              (psKernelExprV2TryWhnfCoreOwnedWithLocalValuesFuel fuel
                (psKernelExprV2TryDefEqStateWithFuel fuel) psKernelExprV2CheckLocalValue
                context initial root cheapRec cheapProj)
            cores := cores + 1
    for structuralFuel in [0,1,2,4,16] do
      for callbackFuel in [0,1,2,8] do
        let oldPublic := psKernelWhnfWithRecursorFuel callbackFuel (psKernelIsDefEqWithFuel callbackFuel)
        let newPublic := psKernelExprV2TryWhnfCheckStateWithFuel callbackFuel
        for cheapRec in [false,true] do
          for cheapProj in [false,true] do
            compare "String-projection-fixed-public-owner"
              (psKernelWhnfCoreWithFuel structuralFuel oldPublic oldNoRec
                scalar psKernelCheckerStateEmpty term cheapRec cheapProj)
              (psKernelExprV2TryWhnfCoreOwnedModeWithReducerFuel structuralFuel
                cheapRec cheapProj psKernelExprV2CheckLocalValue newPublic newNoRec
                (psKernelExprV2CheckContextEmpty scalar) initial root)
            fixed := fixed + 1
  require "String-projection-matrix-counts" (publics == 126 && cores == 504 && fixed == 480)
  IO.println "PSC1_V2_DAG_STRING_PROJECTION_MATRIX: PASS public=126 core=504 fixed=480"

private def cacheTag (cache : PsKernelExprV2WhnfCache) (tag : Nat) : Bool :=
  match psKernelExprV2WhnfCacheEntries cache with
  | [row] => row.hash == psKernelCacheHashModulus + tag
  | _ => false

private def pairTag (rows : List PsKernelExprV2DefEqPair) (tag : Nat) : Bool :=
  match rows with
  | [row] => row.hash == psKernelCacheHashModulus + tag
  | _ => false

private def arenaTag (state : PsKernelExprV2CheckState) (tag : Nat) : Bool :=
  match psKernelExprV2WhnfCacheEntries state.checkedInfer with
  | [row] =>
      match psKernelExprV2PagedRequire state.whnf.arena row.result with
      | .ok entry =>
          match entry.node with
          | .lit (.nat value) => value == 14000 + tag
          | _ => false
      | .error _ => false
  | _ => false

private def tagged (state : PsKernelExprV2CheckState) (tag : Nat) : Bool :=
  state.nextFresh == tag && cacheTag state.checkedInfer tag &&
    pairTag state.success tag && cacheTag state.inferOnly tag &&
    cacheTag state.unfold tag && pairTag state.failure tag && arenaTag state tag

private def stamp (key : Nat) (state : PsKernelExprV2CheckState) (tag : Nat) :
    Except String PsKernelExprV2CheckState := do
  let (arena,marker) ← psKernelExprV2PagedMkLit state.whnf.arena (.nat (14000 + tag))
  let cache := PsKernelExprV2WhnfCacheEntry.mk key marker (psKernelCacheHashModulus + tag)
  let pair := PsKernelExprV2DefEqPair.mk key key (psKernelCacheHashModulus + tag)
  let whnf := PsKernelExprV2WhnfState.mk arena (psKernelExprV2WhnfCacheInsert state.whnf.coreCache cache)
    (psKernelExprV2WhnfCacheInsert state.whnf.publicCache cache) state.whnf.declarations
  let entries := psKernelExprV2WhnfCacheFromList [cache]
  pure (PsKernelExprV2CheckState.mk whnf tag entries [pair] entries entries [pair])

private def markStep (failAt : Nat) (decline : Bool)
    (state : PsKernelExprV2CheckState) (key result tag : Nat) :
    Option (Except String (PsKernelExprV2CheckState × Nat)) :=
  if !tagged state tag then some (.error "STRING_PROJECTION_STALE_STATE")
  else if failAt == tag + 1 - 20 then
    if decline then none else some (.error "STRING_PROJECTION_INJECTED")
  else some ((stamp key state (tag + 1)).map (fun next => (next,result)))

private def stateMatrix (prepared : Prepared) : IO Unit := do
  let scalar := (psKernelKernelSessionChecker prepared.session [] .safe).context
  let context := psKernelExprV2CheckContextEmpty scalar
  let mut probes := 0
  let mut propagated := 0
  for value in strings do
    let (arena,left) ← expect (psKernelExprV2PagedMkLit prepared.arena (.nat 7))
    let (arena,right) ← expect (psKernelExprV2PagedMkLit arena (.nat 11))
    let (arena,ctor) ← expect (psKernelExprV2PagedMkConst arena boxCtor [])
    let (arena,part) ← expect (psKernelExprV2PagedMkApp arena ctor left)
    let (arena,constructed) ← expect (psKernelExprV2PagedMkApp arena part right)
    let (arena,literal) ← expect (psKernelExprV2PagedMkLit arena (.str value))
    let (arena,expectedExpansion) ← expect (psKernelExprV2StringLitToConstructorOnCanonical arena value)
    require "String-projection-exact-constructor"
      (psKernelExprEqual (psKernelStringLitToConstructor value) (← decode arena expectedExpansion))
    for index in [0,1,2,psKernelLeanUInt32Max + 1] do
      let (arena,root) ← expect (psKernelExprV2PagedMkProj arena boxName index literal)
      let initial := psKernelExprV2CheckStateFromWhnf
        (psKernelExprV2WhnfStateForDeclarations arena prepared.declarations)
      let seeded ← expect (stamp literal initial 20)
      require "String-projection-arena-loss-marker"
        (!tagged (psKernelExprV2CheckStateWithArena seeded arena) 20)
      let selected := if index == 0 then left else right
      let hasField : Bool := decide (index < 2)
      for cheapProj in [false,true] do
        let run := fun (failAt : Nat) (decline : Bool) =>
          let recurse := fun (_ : PsKernelExprV2CheckContext)
              (state : PsKernelExprV2CheckState) (nextRoot : Nat) =>
            if state.nextFresh == 20 && cheapProj && nextRoot == literal then
              markStep failAt decline state literal literal 20
            else if state.nextFresh == 22 && hasField && nextRoot == selected then
              markStep failAt decline state selected selected 22
            else some (.error "STRING_PROJECTION_RECURSE_ORDER")
          let publicWhnf := fun (_ : PsKernelExprV2CheckContext)
              (state : PsKernelExprV2CheckState) (nextRoot : Nat) =>
            if state.nextFresh == 20 && !cheapProj && nextRoot == literal then
              markStep failAt decline state literal literal 20
            else if state.nextFresh == 21 then
              match psKernelExprV2PagedEqOnCanonical state.whnf.arena nextRoot expectedExpansion with
              | .error error => some (.error error)
              | .ok equal =>
                  if equal then markStep failAt decline state nextRoot constructed 21
                  else some (.error "STRING_PROJECTION_CONSTRUCTOR_INPUT")
            else some (.error "STRING_PROJECTION_PUBLIC_ORDER")
          psKernelExprV2TryWhnfProjectionOwnedWith recurse publicWhnf context seeded
            root boxName index literal cheapProj
        let some (.ok result) := run 0 false
          | throw (IO.userError "String projection state probe failed")
        let finalTag := if hasField then 23 else 22
        let finalRoot := if hasField then selected else root
        require "String-projection-all-fields-and-arena" (tagged result.fst finalTag)
        require "String-projection-exact-selected-or-original-root" (result.snd == finalRoot)
        require "String-projection-core-marker-retained"
          ((psKernelExprV2WhnfCacheEntries result.fst.whnf.coreCache).any (fun row => row.hash == psKernelCacheHashModulus + finalTag))
        require "String-projection-public-marker-retained"
          ((psKernelExprV2WhnfCacheEntries result.fst.whnf.publicCache).any (fun row => row.hash == psKernelCacheHashModulus + finalTag))
        let originalEntry ← expect (psKernelExprV2PagedRequire result.fst.whnf.arena root)
        let cached ← expect (psKernelExprV2WhnfCacheFind result.fst.whnf root originalEntry)
        require "String-projection-original-root-publication"
          (if cheapProj then cached.isNone else cached == some finalRoot)
        let _ ← expect (psKernelExprV2PagedValidate result.fst.whnf.arena)
        probes := probes + 1
        let stops := if hasField then [1,2,3] else [1,2]
        for failAt in stops do
          for decline in [false,true] do
            require "String-projection-ordered-failure"
              (match run failAt decline with
               | none => decline
               | some (.error error) => !decline && error == "STRING_PROJECTION_INJECTED"
               | _ => false)
            propagated := propagated + 1
  require "String-projection-state-counts" (probes == 48 && propagated == 240)
  IO.println "PSC1_V2_DAG_STRING_PROJECTION_STATE: PASS cases=48 propagated=240"

private def checkedControls (prepared : Prepared) (official : Lean.Environment) : IO Unit := do
  let empty ← expectPublic "empty-controls"
    (psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault)
  let ctorValue := psKernelApplyArgs (.const boxCtor []) [lit 7,lit 11]
  let beta := PsKernelExpr.app (.lam (nm "box") box (.bvar 0) .default) ctorValue
  let zeta := PsKernelExpr.letE (nm "box") box ctorValue (.bvar 0) false
  let fixtures := [
    (PsKernelExpr.proj boxName 0 ctorValue,lit 7),
    (PsKernelExpr.proj boxName 1 ctorValue,lit 11),
    (PsKernelExpr.proj boxName 0 beta,lit 7),
    (PsKernelExpr.proj boxName 1 beta,lit 11),
    (PsKernelExpr.proj boxName 0 zeta,lit 7),
    (PsKernelExpr.proj boxName 1 zeta,lit 11)]
  let scalar := (psKernelKernelSessionChecker prepared.session [] .safe).context
  let mut valid := 0
  for (term,expected) in fixtures do
    let (arena,root) ← expect (psKernelExprV2PagedImportIntoChecked prepared.arena term)
    let reference ← expectPublic "checked-projection-reference"
      (psKernelV1Whnf prepared.session [] .safe term)
    let result ← expectPublic "checked-projection-batch"
      (psKernelV1RunDag empty [] .safe arena (prepared.commands ++ [.whnf root]))
    require "checked-projection-protocol"
      (match result.replies.reverse with
       | .normalized actual :: _ => psKernelExprEqual actual expected
       | _ => false)
    require "checked-projection-V1" (psKernelExprEqual reference expected)
    let initial := psKernelExprV2CheckStateFromWhnf
      (psKernelExprV2WhnfStateForDeclarations arena prepared.declarations)
    let some (.ok actual) := psKernelExprV2TryWhnfCheckStateWithFuel 4096
        (psKernelExprV2CheckContextEmpty scalar) initial root
      | throw (IO.userError "checked ordinary projection declined")
    require "checked-projection-direct-V2"
      (psKernelExprEqual (← decode actual.fst.whnf.arena actual.snd) expected)
    require "checked-projection-official-type"
      (match Lean.Kernel.check official {} (← officialExpr term) with | .ok _ => true | _ => false)
    require "checked-projection-official-result"
      (match Lean.Kernel.isDefEq official {} (← officialExpr term) (← officialExpr expected) with
       | .ok true => true | _ => false)
    valid := valid + 1
  let negative := [
    PsKernelExpr.proj boxName 2 ctorValue,
    PsKernelExpr.proj psKernelStringName 0 ctorValue,
    PsKernelExpr.proj boxName 0 (.const boxCtor [])]
  let mut invalid := 0
  for term in negative do
    let (arena,root) ← expect (psKernelExprV2PagedImportIntoChecked prepared.arena term)
    require "checked-projection-invalid-exact"
      (match psKernelV1Whnf prepared.session [] .safe term,
          psKernelV1RunDag empty [] .safe arena (prepared.commands ++ [.whnf root]) with
       | .error (.rejectedInvalid a),.error (.rejectedInvalid b) => a == b
       | _,_ => false)
    require "checked-projection-official-reject"
      (match Lean.Kernel.check official {} (← officialExpr term) with | .error _ => true | _ => false)
    invalid := invalid + 1
  require "checked-projection-counts" (valid == 6 && invalid == 3)
  IO.println "PSC1_V2_DAG_STRING_PROJECTION_CHECKED: PASS valid=6 invalid=3"

private def officialStringScope (prepared : Prepared) : IO Unit := do
  Lean.initSearchPath (← Lean.findSysroot)
  let official ← Lean.importModules #[{ module := `Init }] {}
  let empty ← expectPublic "empty-String-scope"
    (psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault)
  let mut acceptedOfficial := 0
  let mut rejectedOfficial := 0
  let mut missingEnvironment := 0
  for value in strings do
    for index in [0,1,2] do
      let term := PsKernelExpr.proj psKernelStringName index (.lit (.str value))
      let checked := Lean.Kernel.check official {} (← officialExpr term)
      if index < 2 then
        require "official-real-String-projection-check"
          (match checked with | .ok _ => true | _ => false)
        acceptedOfficial := acceptedOfficial + 1
      else
        require "official-real-String-projection-invalid-field"
          (match checked with | .error _ => true | _ => false)
        rejectedOfficial := rejectedOfficial + 1
      -- This provider intentionally has no String/ByteArray declaration closure.
      -- It must reject a checked projection instead of accepting raw reduction.
      let (arena,root) ← expect (psKernelExprV2PagedImportIntoChecked prepared.arena term)
      require "String-missing-environment-explicit-checked-rejection"
        (match psKernelV1CheckExpression prepared.session [] .safe term,
            psKernelV1RunDag empty [] .safe arena (prepared.commands ++ [.check root]) with
         | .error (.rejectedInvalid a),.error (.rejectedInvalid b) => a == b
         | _,_ => false)
      missingEnvironment := missingEnvironment + 1
  require "official-String-scope-counts"
    (acceptedOfficial == 12 && rejectedOfficial == 6 && missingEnvironment == 18)
  IO.println "PSC1_V2_DAG_STRING_PROJECTION_OFFICIAL: PASS valid=12 invalid=6 missingEnvironment=18"

private def regression : IO Unit := do
  let empty ← expectPublic "empty"
    (psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault)
  let natDecl := PsKernelSimpleInductiveDecl.mk [] psKernelNatName s1 [
    PsKernelSimpleConstructorDecl.mk psKernelNatZeroName nat,
    PsKernelSimpleConstructorDecl.mk psKernelNatSuccName (forallE "n" nat nat)] false 0
  let boxDecl := PsKernelSimpleInductiveDecl.mk [] boxName s1 [
    PsKernelSimpleConstructorDecl.mk boxCtor (forallE "left" nat (forallE "right" nat box))] false 0
  let withNat ← prepareInductive "Nat" (Prepared.mk empty psKernelExprV2PagedEmpty [] []) natDecl
  let prepared ← prepareInductive "Box" withNat boxDecl
  let baseOfficial ← Lean.mkEmptyEnvironment
  let natOfficial ← officialInductive baseOfficial natDecl
  let boxOfficial ← officialInductive natOfficial boxDecl
  resourceMatrix prepared
  stateMatrix prepared
  checkedControls prepared boxOfficial
  officialStringScope prepared

def main : IO Unit := regression
