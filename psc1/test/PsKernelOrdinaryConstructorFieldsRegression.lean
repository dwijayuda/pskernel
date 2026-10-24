import Ps.KernelCore.API.DagOrdinaryConstructorFields
import Ps.KernelCore.API.DagOrdinaryConstructorParams
import Ps.KernelCore.API.DagOrdinaryHeader
import Ps.KernelCore.Admission.Inductive.Ordinary.Constructor
import Ps.KernelCore.Core.ExprV2.Decode
import Ps.KernelCore.Research.ExprV2PagedImport

/- Private constructor-field and recursive-argument qualification.
   Provisional inductive metadata is built only from checked header fixtures,
   matching the existing V1 internal phase. No public admission or publication
   is asserted. The independent V1 Constructor module stays frozen. -/

private def require (counter : IO.Ref Nat) (label : String) (value : Bool) : IO Unit := do
  unless value do throw (IO.userError ("PSC1_CONSTRUCTOR_FIELDS_NATIVE_FAIL " ++ label))
  counter.modify (fun n => n + 1)
  IO.println ("PSC1_CONSTRUCTOR_FIELDS_ASSERT " ++ label)

private def expect {α : Type} : Except String α → IO α
  | .ok value => pure value
  | .error error => throw (IO.userError error)

private def direct {α : Type} : Option (Except String α) → IO α
  | some (.ok value) => pure value
  | some (.error error) => throw (IO.userError error)
  | none => throw (IO.userError "unexpected private constructor helper decline")

private def nm (text : String) := PsKernelName.str .anonymous text
private def one := PsKernelLevel.succ .zero
private def s0 := PsKernelExpr.sort .zero
private def s1 := PsKernelExpr.sort one
private def target := nm "CtorFieldsT"
private def t := PsKernelExpr.const target []
private def all (name : String) (domain body : PsKernelExpr)
    (info : PsKernelBinderInfo := .default) :=
  PsKernelExpr.forallE (nm name) domain body info
private def lam (name : String) (domain body : PsKernelExpr) :=
  PsKernelExpr.lam (nm name) domain body .default
private def ti (index : PsKernelExpr) := PsKernelExpr.app t index
private def ti2 (left right : PsKernelExpr) := PsKernelExpr.app (ti left) right
private def ih1 := all "i" s1 s1
private def ih2 := all "i" s1 (all "j" s1 s1)
private def ph := all "A" s1 s1 .implicit
private def fn1 := all "a" s0 t
private def fn2 := all "a" s0 (all "b" s0 t)
private def nestedError := "simple inductive admission does not yet support nested recursive occurrences"
private def negativeError := "recursive function argument contains a negative recursive occurrence"
private def indexError := "recursive argument index contains a recursive occurrence"

private structure FieldCase where
  label : String
  header : PsKernelExpr
  numParams : Nat
  ctor : PsKernelExpr
  expected : Except String (Nat × Nat)

private def fieldCases : List FieldCase :=
  [ ⟨"empty",s1,0,t,.ok (0,0)⟩,
    ⟨"prop-value",s1,0,all "p" s0 t,.ok (1,0)⟩,
    ⟨"two-fields",s1,0,all "p" s0 (all "q" s0 t),.ok (2,0)⟩,
    ⟨"direct-recursive",s1,0,all "t" t t,.ok (1,1)⟩,
    ⟨"function-one",s1,0,all "f" fn1 t,.ok (1,1)⟩,
    ⟨"function-two",s1,0,all "f" fn2 t,.ok (1,1)⟩,
    ⟨"scope-after-function",s1,0,all "f" fn2 (all "p" s0 (all "q" s0 t)),.ok (3,1)⟩,
    ⟨"metadata-domain",s1,0,all "t" (.mdata 217 t) t,.ok (1,1)⟩,
    ⟨"beta-domain",s1,0,all "t" (.app (lam "X" s1 (.bvar 0)) t) t,.ok (1,1)⟩,
    ⟨"erased-occurrence",s1,0,all "p" (.app (lam "X" s1 s0) t) t,.error nestedError⟩,
    ⟨"negative-function",s1,0,all "f" (all "x" t t) t,.error negativeError⟩,
    ⟨"universe-overflow",s1,0,all "A" s1 t,.error "simple inductive constructor field universe is too large"⟩,
    ⟨"whole-metadata",s1,0,.mdata 218 (all "t" t t),.ok (0,0)⟩,
    ⟨"whole-beta",s1,0,.app (lam "X" s1 (all "t" t t)) s0,.ok (0,0)⟩,
    ⟨"whole-let",s1,0,.letE (nm "X") s1 s0 (all "t" t t) false,.ok (0,0)⟩,
    ⟨"prop-exception",s0,0,all "A" s1 t,.ok (1,0)⟩,
    ⟨"indexed",ih1,0,all "t" (ti s0) (ti s0),.ok (1,1)⟩,
    ⟨"indexed-repeated",ih2,0,all "t" (ti2 s0 s0) (ti2 s0 s0),.ok (1,1)⟩,
    ⟨"recursive-index",ih1,0,all "t" (ti (ti s0)) (ti s0),.error indexError⟩,
    ⟨"parameterized",ph,1,all "X" s1 (all "t" (ti (.bvar 0)) (ti (.bvar 1))) .implicit,.ok (1,1)⟩,
    ⟨"wrong-field-parameter",ph,1,all "X" s1 (all "t" (ti s0) (ti (.bvar 1))) .implicit,.error nestedError⟩ ]

private structure Fixture where
  old : PsKernelCheckerSession
  oldType : PsKernelExpr
  oldParams : List PsKernelOpenBinder
  context : PsKernelExprV2CheckContext
  state : PsKernelExprV2CheckState
  params : List PsKernelExprV2OrdinaryOpenBinder
  numIndices : Nat
  resultLevel : PsKernelLevel
  root : Nat

private def prepare (row : FieldCase) : IO Fixture := do
  let initial := psKernelMkCheckerSession psKernelEnvironmentEmpty [] .safe 0 psKernelLeanNatMaxSizeDefault
  let checked ← expect (psKernelSessionCheck 4096 initial row.header)
  let sorted ← expect (psKernelSessionEnsureSort 4096 checked.snd checked.fst)
  let oldParams ← expect (psKernelOpenSimpleHeaderParams 4096 sorted.snd row.header row.numParams)
  let oldIndices ← expect (psKernelOpenSimpleHeaderIndices 4096 oldParams.session oldParams.result)
  let (arena,headerId) ← expect (psKernelExprV2PagedImportIntoChecked psKernelExprV2PagedEmpty row.header)
  let analysis ← direct (psKernelExprV2OrdinaryAnalyzeHeaderWithFuel 4096 psKernelEnvironmentEmpty
    0 psKernelLeanNatMaxSizeDefault arena [] [] row.numParams ⟨target,headerId,[]⟩ false)
  let numIndices := analysis.indices.binders.length
  unless numIndices == oldIndices.binders.length do throw (IO.userError "header index arity mismatch")
  let info := PsKernelInductiveInfo.mk ⟨target,[],row.header⟩ row.numParams numIndices [target] [] 0 false false false
  let work := psKernelEnvironmentAddUnchecked psKernelEnvironmentEmpty (.inductInfo info)
  let oldOwner := psKernelSessionWithEnvironment oldParams.session work
  let oldOpened ← expect (psKernelOpenSimpleConstructorParams 4096 oldOwner oldParams.binders row.ctor)
  let parent := psKernelExprV2OrdinaryConstructorState analysis
  let ctx := psKernelExprV2OrdinaryConstructorContext analysis
  let context := PsKernelExprV2CheckContext.mk (psKernelCheckerContextWithEnvironment ctx.scalar work) ctx.locals
  let (arena,root) ← expect (psKernelExprV2PagedImportIntoChecked parent.whnf.arena row.ctor)
  let reference := PsKernelExprV2DeclarationRef.mk target [] headerId none .inductiveDecl
  let state := psKernelExprV2CheckStateWithWhnf parent
    ⟨arena,parent.whnf.coreCache,parent.whnf.publicCache,reference :: parent.whnf.declarations⟩
  let opened ← direct (psKernelExprV2OrdinaryOpenConstructorParamsWithFuel 4096
    context state analysis.parameters.binders root)
  pure ⟨oldOpened.session,oldOpened.result,oldParams.binders,context,opened.fst,
    analysis.parameters.binders,numIndices,analysis.resultLevel,opened.snd⟩

private def sameList {α β : Type} (same : α → β → Bool) : List α → List β → Bool
  | [],[] => true
  | a :: rest,b :: tail => same a b && sameList same rest tail
  | _,_ => false

private def decodedEq (built : PsKernelExprV2Decoded) (left : PsKernelExpr) (right : Nat) : Bool :=
  match psKernelExprV2DecodedRequire built right with
  | .ok value => psKernelExprEqual left value
  | .error _ => false

private def binderEq (built : PsKernelExprV2Decoded)
    (left : PsKernelOpenBinder) (right : PsKernelExprV2OrdinaryOpenBinder) : Bool :=
  psKernelNameEq left.internalName right.internalName &&
    psKernelNameEq left.userName right.userName &&
    psKernelBinderInfoEq left.binderInfo right.binderInfo && decodedEq built left.type right.type

private def localsEq (built : PsKernelExprV2Decoded)
    (left : List PsKernelLocalDecl) (right : List PsKernelExprV2CheckLocal) : Bool :=
  sameList (fun old actual =>
    psKernelNameEq (psKernelLocalDeclName old) actual.name &&
    psKernelNameEq (psKernelLocalDeclUserName old) actual.userName &&
    psKernelBinderInfoEq (psKernelLocalDeclBinderInfo old) actual.binderInfo &&
    decodedEq built (psKernelLocalDeclType old) actual.type &&
    (psKernelLocalDeclValue old).isNone && actual.value.isNone) left right

private def referencesEq (left right : List PsKernelExprV2DeclarationRef) : Bool :=
  sameList (fun a b => psKernelNameEq a.name b.name &&
    psKernelNameListsEq a.levelParams b.levelParams && a.type == b.type &&
    a.deltaValue == b.deltaValue &&
    (match a.kind,b.kind with | .inductiveDecl,.inductiveDecl => true | _,_ => false))
    left right

private def sameNode : PsKernelExprV2Node → PsKernelExprV2Node → Bool
  | .bvar a,.bvar b => a == b
  | .fvar a,.fvar b => psKernelNameEq a b
  | .mvar a,.mvar b => psKernelNameEq a b
  | .sort a,.sort b => psKernelLevelEq a b
  | .const a us,.const b vs => psKernelNameEq a b && psKernelLevelListEq us vs
  | .app a b,.app c d => a == c && b == d
  | .lam a b c i,.lam d e f j =>
      psKernelNameEq a d && b == e && c == f && psKernelBinderInfoEq i j
  | .forallE a b c i,.forallE d e f j =>
      psKernelNameEq a d && b == e && c == f && psKernelBinderInfoEq i j
  | .letE a b c d n,.letE e f g h m =>
      psKernelNameEq a e && b == f && c == g && d == h && n == m
  | .lit a,.lit b => psKernelExprEqual (.lit a) (.lit b)
  | .mdata a b,.mdata c d => a == c && b == d
  | .proj a b c,.proj d e f => psKernelNameEq a d && b == e && c == f
  | _,_ => false

private def arenaPrefix (before after : PsKernelExprV2PagedArena) : Bool :=
  Nat.ble before.size after.size && before.pageLimit == after.pageLimit &&
    (List.range before.size).all (fun id =>
      match psKernelExprV2PagedFind before id,psKernelExprV2PagedFind after id with
      | some left,some right => sameNode left.node right.node &&
          psKernelExprV2PortableSameMetadata left right
      | _,_ => false)


private def fieldEq (fixture : Fixture)
    (old : Except String PsKernelOpenFieldsResult)
    (actual : Option (Except String PsKernelExprV2OrdinaryOpenFieldsResult)) : Bool :=
  match old,actual with
  | .error left,some (.error right) => left == right
  | .ok left,some (.ok right) =>
      match psKernelExprV2DecodeChecked right.state.whnf.arena with
      | .error _ => false
      | .ok built =>
          decodedEq built left.result right.result &&
          left.session.state.nextFresh == right.state.nextFresh &&
          sameList (binderEq built) left.fields right.fields &&
          sameList (fun a b => binderEq built a.field b.field &&
            sameList (binderEq built) a.arguments b.arguments &&
            sameList (decodedEq built) a.indices b.indices) left.recursiveFields right.recursiveFields &&
          localsEq built left.session.context.localContext.decls right.context.locals &&
          referencesEq right.state.whnf.declarations fixture.state.whnf.declarations &&
          arenaPrefix fixture.state.whnf.arena right.state.whnf.arena
  | _,_ => false

private def fieldsMatrix (counter : IO.Ref Nat) : IO Unit := do
  let before ← counter.get
  unless fieldCases.length == 21 do throw (IO.userError "field fixture inventory")
  for row in fieldCases do
    let fixture ← prepare row
    for fuel in [0,1,2,3,8,4096] do
      let old := psKernelOpenSimpleConstructorFields fuel fixture.old target [] fixture.oldParams
        fixture.numIndices fixture.resultLevel fixture.oldType
      let actual := psKernelExprV2OrdinaryOpenConstructorFieldsWithFuel fuel fixture.context fixture.state
        target [] fixture.params fixture.numIndices fixture.resultLevel fixture.root
      require counter ("fields/" ++ row.label ++ "/fuel=" ++ toString fuel) (fieldEq fixture old actual)
    let actual := psKernelExprV2OrdinaryOpenConstructorFieldsWithFuel 4096 fixture.context fixture.state
      target [] fixture.params fixture.numIndices fixture.resultLevel fixture.root
    let correct := match row.expected,actual with
      | .error expected,some (.error got) => expected == got
      | .ok dimensions,some (.ok got) =>
          got.fields.length == dimensions.fst && got.recursiveFields.length == dimensions.snd
      | _,_ => false
    require counter ("fields/" ++ row.label ++ "/required-outcome") correct
    if row.label == "scope-after-function" then
      let got ← direct actual
      match got.recursiveFields with
      | [recursive] =>
          unless recursive.arguments.length == 2 && got.context.locals.length == 3 &&
              !(got.context.locals.any (fun local =>
                recursive.arguments.any (fun arg => psKernelNameEq local.name arg.internalName))) do
            throw (IO.userError "temporary recursive arguments leaked into field context")
      | _ => throw (IO.userError "missing recursive field")
  unless (← counter.get) - before == 147 do throw (IO.userError "fields assertion inventory")
  IO.println "PSC1_CONSTRUCTOR_FIELDS_SECTION fields=147"

private structure RecursiveCase where
  label : String
  header : PsKernelExpr
  expr : PsKernelExpr
  expected : Except String (Option (Nat × Nat))

private def recursiveCases : List RecursiveCase :=
  [ ⟨"nonrecursive-sort",s1,s0,.ok none⟩,
    ⟨"direct",s1,t,.ok (some (0,0))⟩,
    ⟨"function-one",s1,fn1,.ok (some (1,0))⟩,
    ⟨"function-two",s1,fn2,.ok (some (2,0))⟩,
    ⟨"metadata",s1,.mdata 219 t,.ok (some (0,0))⟩,
    ⟨"beta",s1,.app (lam "X" s1 (.bvar 0)) t,.ok (some (0,0))⟩,
    ⟨"negative",s1,all "x" t t,.error negativeError⟩,
    ⟨"erased",s1,.app (lam "X" s1 s0) t,.error nestedError⟩,
    ⟨"surplus-argument",s1,ti s0,.error nestedError⟩,
    ⟨"indexed",ih1,ti s0,.ok (some (0,1))⟩,
    ⟨"indexed-repeated",ih2,ti2 s0 s0,.ok (some (0,2))⟩,
    ⟨"recursive-index",ih1,ti (ti s0),.error indexError⟩,
    ⟨"function-index",ih1,all "i" s1 (ti (.bvar 0)),.ok (some (1,1))⟩,
    ⟨"nonrecursive-function",s1,all "p" s0 s0,.ok none⟩,
    ⟨"lambda-occurrence",s1,lam "p" s0 t,.error nestedError⟩ ]

private def recursiveEq (fixture : Fixture)
    (old : Except String PsKernelRecursiveArgumentResult)
    (actual : Option (Except String PsKernelExprV2OrdinaryRecursiveArgumentResult)) : Bool :=
  match old,actual with
  | .error left,some (.error right) => left == right
  | .ok left,some (.ok right) =>
      match psKernelExprV2DecodeChecked right.state.whnf.arena with
      | .error _ => false
      | .ok built =>
          let info := match left.recursiveInfo,right.recursiveInfo with
            | none,none => true
            | some a,some b =>
                sameList (binderEq built) a.fst b.fst && sameList (decodedEq built) a.snd b.snd
            | _,_ => false
          info && left.session.state.nextFresh == right.state.nextFresh &&
            localsEq built left.session.context.localContext.decls right.context.locals &&
            referencesEq right.state.whnf.declarations fixture.state.whnf.declarations &&
            arenaPrefix fixture.state.whnf.arena right.state.whnf.arena
  | _,_ => false

private def recursiveMatrix (counter : IO.Ref Nat) : IO Unit := do
  let before ← counter.get
  unless recursiveCases.length == 15 do throw (IO.userError "recursive fixture inventory")
  for row in recursiveCases do
    let base ← prepare ⟨row.label,row.header,0,t,.ok (0,0)⟩
    let (arena,root) ← expect (psKernelExprV2PagedImportIntoChecked base.state.whnf.arena row.expr)
    let state := psKernelExprV2CheckStateWithArena base.state arena
    let fixture := { base with state := state }
    for fuel in [0,1,2,3,8,4096] do
      let old := psKernelAnalyzeSimpleRecursiveArgument fuel fixture.old target []
        fixture.oldParams fixture.numIndices row.expr
      let actual := psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWithFuel fuel fixture.context state
        target [] fixture.params fixture.numIndices root
      require counter ("recursive/" ++ row.label ++ "/fuel=" ++ toString fuel)
        (recursiveEq fixture old actual)
    let actual := psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWithFuel 4096 fixture.context state
      target [] fixture.params fixture.numIndices root
    let correct := match row.expected,actual with
      | .error expected,some (.error got) => expected == got
      | .ok none,some (.ok got) => got.recursiveInfo.isNone
      | .ok (some dimensions),some (.ok got) =>
          match got.recursiveInfo with
          | some info => info.fst.length == dimensions.fst && info.snd.length == dimensions.snd
          | none => false
      | _,_ => false
    require counter ("recursive/" ++ row.label ++ "/required-outcome") correct
  unless (← counter.get) - before == 105 do throw (IO.userError "recursive assertion inventory")
  IO.println "PSC1_CONSTRUCTOR_FIELDS_SECTION recursive=105"


private abbrev CheckCallback := Nat → PsKernelExprV2CheckContext → PsKernelExprV2CheckState → Nat →
  Option (Except String (PsKernelExprV2CheckState × Nat))

private def callbackDecline : CheckCallback := fun _ _ _ _ => none
private def callbackError (message : String) : CheckCallback := fun _ _ _ _ => some (.error message)
private def forbidden : CheckCallback := callbackError "UNEXPECTED_CALLBACK"

private def errorIs {α : Type} (message : String) : Option (Except String α) → Bool
  | some (.error got) => message == got
  | _ => false

private def boundaryMatrix (counter : IO.Ref Nat) : IO Unit := do
  let before ← counter.get
  let base ← prepare ⟨"boundaries",s1,0,t,.ok (0,0)⟩
  let (arena,terminal) ← expect (psKernelExprV2PagedImportIntoChecked base.state.whnf.arena s0)
  let (arena,forallId) ← expect (psKernelExprV2PagedImportIntoChecked arena (all "x" t t))
  let state := psKernelExprV2CheckStateWithArena base.state arena
  let analyze := fun (_fuel : Nat) (_ctx : PsKernelExprV2CheckContext) (_state : PsKernelExprV2CheckState)
    (_target : PsKernelName) (_levels : List PsKernelLevel)
    (_params : List PsKernelExprV2OrdinaryOpenBinder) (_count root : Nat) =>
      (some (.error ("UNEXPECTED_ANALYSIS/" ++ toString root)) :
        Option (Except String PsKernelExprV2OrdinaryRecursiveArgumentResult))
  let fields := fun fuel check whnf root =>
    psKernelExprV2OrdinaryOpenConstructorFieldsWorker fuel check whnf analyze base.context state
      target [] base.params base.numIndices base.resultLevel root [] []
  let recursive := fun fuel check whnf root =>
    psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWorker fuel check whnf base.context state
      target [] base.params base.numIndices root []
  require counter "boundaries/fields-zero-before-invalid-root"
    (errorIs "simple inductive field budget exhausted" (fields 0 forbidden forbidden 999999))
  require counter "boundaries/fields-positive-invalid-before-callbacks"
    (errorIs "PSKERNEL_V2_PAGED_INVALID_CHILD" (fields 1 forbidden forbidden 999999))
  let terminalResult ← direct (fields 1 forbidden forbidden terminal)
  require counter "boundaries/terminal-keeps-owner"
    (terminalResult.result == terminal && terminalResult.fields.isEmpty &&
      terminalResult.recursiveFields.isEmpty && terminalResult.context.locals.isEmpty &&
      terminalResult.state.nextFresh == state.nextFresh &&
      terminalResult.state.whnf.arena.size == state.whnf.arena.size &&
      arenaPrefix state.whnf.arena terminalResult.state.whnf.arena &&
      referencesEq terminalResult.state.whnf.declarations state.whnf.declarations)
  require counter "boundaries/field-check-decline"
    ((fields 1 callbackDecline forbidden forallId).isNone)
  require counter "boundaries/field-check-error"
    (errorIs "field-check-sentinel" (fields 1 (callbackError "field-check-sentinel") forbidden forallId))
  require counter "boundaries/recursive-zero-before-root-or-whnf"
    (errorIs "simple inductive recursive-argument budget exhausted" (recursive 0 forbidden forbidden 999999))
  require counter "boundaries/recursive-whnf-decline"
    ((recursive 1 forbidden callbackDecline 999999).isNone)
  require counter "boundaries/recursive-whnf-error"
    (errorIs "recursive-whnf-sentinel" (recursive 1 forbidden (callbackError "recursive-whnf-sentinel") 999999))
  unless (← counter.get) - before == 8 do throw (IO.userError "boundary assertion inventory")
  IO.println "PSC1_CONSTRUCTOR_FIELDS_SECTION boundaries=8"

private def boolResult (expected : Bool) : Except String Bool → Bool
  | .ok value => value == expected
  | .error _ => false

private def guardMatrix (counter : IO.Ref Nat) : IO Unit := do
  let before ← counter.get
  let base ← prepare ⟨"guard",s1,0,t,.ok (0,0)⟩
  let recName := nm "CtorFieldsGuardRec"
  let (arena,root) ← expect (psKernelExprV2PagedImportIntoChecked base.state.whnf.arena
    (.app (.const recName []) t))
  let (arena,erased) ← expect (psKernelExprV2PagedImportIntoChecked arena
    (.app (.const recName []) s0))
  let state := psKernelExprV2CheckStateWithArena base.state arena
  let recInfo := PsKernelRecursorInfo.mk ⟨recName,[],s1⟩ [target] 0 0 0 0 [] false false
  let withInfo := fun info =>
    PsKernelExprV2CheckContext.mk
      (psKernelCheckerContextWithEnvironment base.context.scalar
        (psKernelEnvironmentAddUnchecked base.context.scalar.environment info)) base.context.locals
  let recContext := withInfo (.recInfo recInfo)
  let axiomContext := withInfo (.axiomInfo ⟨recInfo.base,false⟩)
  let unsafeContext := { recContext with scalar := { recContext.scalar with safety := .unsafeDef } }
  let guard := fun context id => psKernelExprV2OrdinaryInvalidRecursorOccurrence context state target id
  -- Isolated guard-kind probes: synthetic metadata is never claimed admitted.
  require counter "recursorGuard/safe-live-recursor-target" (boolResult true (guard recContext root))
  require counter "recursorGuard/unsafe" (boolResult false (guard unsafeContext root))
  require counter "recursorGuard/missing-head" (boolResult false (guard base.context root))
  require counter "recursorGuard/axiom-not-recursor" (boolResult false (guard axiomContext root))
  require counter "recursorGuard/reduced-target-absent" (boolResult false (guard recContext erased))
  require counter "recursorGuard/unsafe-before-invalid-id" (boolResult false (guard unsafeContext 999999))
  require counter "recursorGuard/safe-invalid-id"
    (match guard recContext 999999 with | .error error => error == "PSKERNEL_V2_PAGED_INVALID_CHILD" | _ => false)
  unless (← counter.get) - before == 7 do throw (IO.userError "guard assertion inventory")
  IO.println "PSC1_CONSTRUCTOR_FIELDS_SECTION recursorGuard=7"

def main : IO Unit := do
  let counter ← IO.mkRef 0
  require counter "harness/constructor-tags"
    (errorIs "same" (some (.error "same") : Option (Except String String)) &&
      !errorIs "same" (some (.ok "same") : Option (Except String String)) &&
      !errorIs "same" (none : Option (Except String String)))
  IO.println "PSC1_CONSTRUCTOR_FIELDS_SECTION harness=1"
  fieldsMatrix counter
  recursiveMatrix counter
  boundaryMatrix counter
  guardMatrix counter
  unless (← counter.get) == 268 do throw (IO.userError "exact268 field and recursive assertions required")
  IO.println "PSC1_ORDINARY_CONSTRUCTOR_FIELDS_NATIVE: PASS assertions=268 fieldRows=21 recursiveRows=15 fuelValues=6 fullAdmission=false"
  IO.println "PSC1_ORDINARY_CONSTRUCTOR_FIELDS_NATIVE_SECTIONS: PASS harness=1 fields=147 recursive=105 boundaries=8 recursorGuard=7"
