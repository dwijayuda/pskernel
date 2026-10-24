import Ps.KernelCore.API.DagOrdinaryAdmission
import Ps.KernelCore.API.DagGenerated
import Ps.KernelCore.Admission.Inductive.Ordinary.Admission
import Ps.KernelCore.Core.ExprV2.Decode
import Ps.KernelCore.Research.ExprV2PagedImport
import Lean

/- End-to-end private ordinary admission qualification. The frozen reference
   is the complete V1 psKernelAddSimpleInductive, including generated recursor
   type checking and rule RHS type preservation. No public fallback supplies
   direct success. Public routing remains separately gated. -/

private def require (counter : IO.Ref Nat) (label : String) (value : Bool) : IO Unit := do
  unless value do throw (IO.userError ("PSC1_ORDINARY_ADMISSION_NATIVE_FAIL " ++ label))
  counter.modify (fun n => n + 1)
  IO.println ("PSC1_ORDINARY_ADMISSION_ASSERT " ++ label)

private def expect {α : Type} : Except String α → IO α
  | .ok value => pure value
  | .error error => throw (IO.userError error)

private def nm (text : String) := PsKernelName.str .anonymous text
private def one := PsKernelLevel.succ .zero
private def s0 := PsKernelExpr.sort .zero
private def s1 := PsKernelExpr.sort one
private def s2 := PsKernelExpr.sort (.succ one)
private def target := nm "AdmissionT"
private def ctorName (index : Nat) := nm ("AdmissionT.c" ++ toString index)
private def priorName := nm "AdmissionPrior"
private def unsafeName := nm "AdmissionUnsafe"
private def u := nm "AdmissionU"
private def t := PsKernelExpr.const target []
private def all (name : String) (domain body : PsKernelExpr)
    (info : PsKernelBinderInfo := .default) :=
  PsKernelExpr.forallE (nm name) domain body info
private def apps := psKernelApplyArgs
private def ti (index : PsKernelExpr) := PsKernelExpr.app t index

private structure AdmissionSummary where
  indices : Nat
  fields : List Nat
  recursive : Bool
  reflexive : Bool
  k : Bool
  propOnly : Bool

private structure AdmissionCase where
  label : String
  header : PsKernelExpr
  numParams : Nat
  levels : List PsKernelName
  isUnsafe : Bool
  ctors : List PsKernelExpr
  expected : Except String AdmissionSummary

private def good (fields : List Nat) (indices : Nat := 0)
    (recursive : Bool := false) (reflexive : Bool := false)
    (k : Bool := false) (propOnly : Bool := false) : Except String AdmissionSummary :=
  .ok ⟨indices,fields,recursive,reflexive,k,propOnly⟩

private def row (label : String) (header : PsKernelExpr) (ctors : List PsKernelExpr)
    (expected : Except String AdmissionSummary) (params : Nat := 0)
    (levels : List PsKernelName := []) (isUnsafe : Bool := false) : AdmissionCase :=
  ⟨label,header,params,levels,isUnsafe,ctors,expected⟩

private def admissionCases : List AdmissionCase :=
  [ row "type-empty" s1 [] (good []),
    row "enum-two" s1 [t,t] (good [0,0]),
    row "direct-recursive" s1 [t,all "previous" t t] (good [0,1] 0 true),
    row "reflexive" s1 [all "branch" (all "p" s0 t) t] (good [1] 0 true true),
    row "parameterized" (all "A" s1 s1 .implicit)
      [all "A" s1 (all "value" (.bvar 0) (ti (.bvar 1))) .implicit]
      (good [1]) 1,
    row "dependent-index" (all "A" s1 (all "a" (.bvar 0) s1) .implicit)
      [all "A" s1 (all "a" (.bvar 0) (apps t [.bvar 1,.bvar 0])) .implicit]
      (good [1] 1) 1,
    row "universe" (all "A" (.sort (.param u)) (.sort (.param u)) .implicit)
      [all "A" (.sort (.param u))
        (all "value" (.bvar 0) (apps (.const target [.param u]) [.bvar 1])) .implicit]
      (good [1] 0 false false false true) 1 [u],
    row "prop-empty" s0 [] (good []),
    row "prop-unit" s0 [t] (good [0] 0 false false true),
    row "prop-proof-field" (all "P" s0 s0 .implicit)
      [all "P" s0 (all "proof" (.bvar 0) (ti (.bvar 1))) .implicit]
      (good [1]) 1,
    row "prop-data-field" s0 [all "A" s1 t] (good [1] 0 false false false true),
    row "prop-two" s0 [t,t] (good [0,0] 0 false false false true),
    row "unsafe-reference" s1 [all "x" (.const unsafeName []) t] (good [1]) 0 [] true,
    row "safe-prior-reference" s1 [all "x" (.const priorName []) t] (good [1]),
    row "duplicate-level-before-mvar" (.mvar (nm "AdmissionM")) []
      (.error "duplicate universe parameter") 0 [u,u],
    row "late-wrong-result" s1 [t,s0]
      (.error "simple inductive constructor must return the declared datatype with matching parameters and index arity"),
    row "negative-function" s1 [all "f" (all "x" t t) t]
      (.error "recursive function argument contains a negative recursive occurrence"),
    row "safe-unsafe-reference" s1 [all "x" (.const unsafeName []) t]
      (.error "safe declaration uses unsafe constant") ]

private def priorEnvironment : IO PsKernelEnvironment := do
  let first ← expect (psKernelAddAxiom 4096 psKernelEnvironmentEmpty
    ⟨⟨priorName,[],s1⟩,false⟩ 0 psKernelLeanNatMaxSizeDefault)
  expect (psKernelAddAxiom 4096 first
    ⟨⟨unsafeName,[],s1⟩,true⟩ 0 psKernelLeanNatMaxSizeDefault)

private structure Fixture where
  decl : PsKernelSimpleInductiveDecl
  environment : PsKernelEnvironment
  input : PsKernelExprV2Decoded
  sourceArena : PsKernelExprV2PagedArena
  owner : PsKernelDagGeneratedState
  value : PsKernelDagInductive

private def prepare (environment : PsKernelEnvironment) (test : AdmissionCase) : IO Fixture := do
  let (initial,_) ← expect (psKernelDagGeneratedImport s2
    ⟨psKernelExprV2PagedEmpty,psKernelExprV2DecodedEmpty,[]⟩)
  let (header,headerId) ← expect (psKernelDagGeneratedImport test.header initial)
  let mut owner := header
  let mut oldCtors := []
  let mut dagCtors := []
  for (type,index) in test.ctors.zipIdx do
    let (next,root) ← expect (psKernelDagGeneratedImport type owner)
    owner := next
    oldCtors := oldCtors ++ [PsKernelSimpleConstructorDecl.mk (ctorName index) type]
    dagCtors := dagCtors ++ [PsKernelDagConstructor.mk (ctorName index) root]
  let sourceArena := owner.arena
  let input := owner.built
  let installed ← expect (psKernelDagGeneratedDemandRange environment 0 owner)
  pure ⟨⟨test.levels,target,test.header,oldCtors,test.isUnsafe,test.numParams⟩,
    environment,input,sourceArena,installed,⟨target,headerId,dagCtors⟩⟩

private def sameList {α β : Type} (same : α → β → Bool) : List α → List β → Bool
  | [],[] => true
  | a :: rest,b :: tail => same a b && sameList same rest tail
  | _,_ => false

private def baseEq (a b : PsKernelConstantBase) : Bool :=
  psKernelNameEq a.name b.name && psKernelNameListsEq a.levelParams b.levelParams &&
    psKernelExprEqual a.type b.type

private def ruleEq (a b : PsKernelRecursorRule) : Bool :=
  psKernelNameEq a.ctor b.ctor && a.nFields == b.nFields && psKernelExprEqual a.rhs b.rhs

private def recursorEq (a b : PsKernelRecursorInfo) : Bool :=
  baseEq a.base b.base && psKernelNameListsEq a.all b.all &&
    a.numParams == b.numParams && a.numIndices == b.numIndices &&
    a.numMotives == b.numMotives && a.numMinors == b.numMinors &&
    sameList ruleEq a.rules b.rules && a.k == b.k && a.isUnsafe == b.isUnsafe

/- Other constant kinds are rejected, never ignored. The checked baseline and
   these fixtures contain exactly axioms, inductives, constructors, recursors. -/
private def constantEq (a b : PsKernelConstantInfo) : Bool :=
  match a,b with
  | .axiomInfo x,.axiomInfo y => baseEq x.base y.base && x.isUnsafe == y.isUnsafe
  | .inductInfo x,.inductInfo y =>
      baseEq x.base y.base && x.numParams == y.numParams && x.numIndices == y.numIndices &&
        psKernelNameListsEq x.all y.all && psKernelNameListsEq x.ctors y.ctors &&
        x.numNested == y.numNested && x.isRec == y.isRec &&
        x.isReflexive == y.isReflexive && x.isUnsafe == y.isUnsafe
  | .ctorInfo x,.ctorInfo y =>
      baseEq x.base y.base && psKernelNameEq x.induct y.induct &&
        x.cidx == y.cidx && x.numParams == y.numParams && x.numFields == y.numFields &&
        x.isUnsafe == y.isUnsafe
  | .recInfo x,.recInfo y => recursorEq x y
  | _,_ => false

private def environmentEq (a b : PsKernelEnvironment) : Bool :=
  a.quotInitialized == b.quotInitialized &&
    a.runtime.nativeEvaluator.isNone && b.runtime.nativeEvaluator.isNone &&
    sameList constantEq a.constants b.constants &&
    a.constants.all (fun info =>
      match psKernelEnvironmentFind a (psKernelConstantInfoName info),
          psKernelEnvironmentFind b (psKernelConstantInfoName info) with
      | some x,some y => constantEq info x && constantEq info y
      | _,_ => false)

private def decodedEq (built : PsKernelExprV2Decoded) (old : PsKernelExpr) (root : Nat) : Bool :=
  match psKernelExprV2DecodedRequire built root with
  | .ok value => psKernelExprEqual old value
  | .error _ => false

private def builtPrefix (a b : PsKernelExprV2Decoded) : Bool :=
  Nat.ble a.size b.size && (List.range a.size).all (fun root =>
    match psKernelExprV2DecodedRequire a root,psKernelExprV2DecodedRequire b root with
    | .ok x,.ok y => psKernelExprEqual x y
    | _,_ => false)

private def referenceKindEq (a b : PsKernelExprV2DeclarationRefKind) : Bool :=
  match a,b with
  | .axiomDecl,.axiomDecl | .definitionDecl,.definitionDecl | .theoremDecl,.theoremDecl |
    .opaqueDecl,.opaqueDecl | .inductiveDecl,.inductiveDecl | .constructorDecl,.constructorDecl => true
  | .recursorDecl xs,.recursorDecl ys =>
      sameList (fun x y => psKernelNameEq x.ctor y.ctor && x.nFields == y.nFields && x.rhs == y.rhs) xs ys
  | .quotDecl x,.quotDecl y => psKernelExprV2QuotKindEq x y
  | _,_ => false

private def referenceEq (a b : PsKernelExprV2DeclarationRef) : Bool :=
  psKernelNameEq a.name b.name && psKernelNameListsEq a.levelParams b.levelParams &&
    a.type == b.type && a.deltaValue == b.deltaValue && referenceKindEq a.kind b.kind

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

private def ownerEq (a b : PsKernelDagGeneratedState) : Bool :=
  a.arena.size == b.arena.size && arenaPrefix a.arena b.arena &&
    a.built.size == b.built.size && builtPrefix a.built b.built &&
    sameList referenceEq a.declarations b.declarations

private def ownerSuccess (fixture : Fixture) (actual : PsKernelExprV2OrdinaryAdmissionResult) : Bool :=
  let next := actual.owner
  let newNames := target :: psKernelSimpleRecName target :: fixture.decl.ctors.map (fun c => c.name)
  next.arena.size == next.built.size &&
    arenaPrefix fixture.owner.arena next.arena && arenaPrefix fixture.sourceArena next.arena &&
    builtPrefix fixture.input next.built &&
    (match psKernelExprV2DecodeChecked next.arena with
    | .ok decoded => decoded.size == next.built.size && builtPrefix decoded next.built
    | .error _ => false) &&
    next.declarations.length == fixture.owner.declarations.length + newNames.length &&
    psKernelSimpleNameListUnique (next.declarations.map (fun ref => ref.name)) &&
    fixture.owner.declarations.all (fun old =>
      match psKernelExprV2DeclarationRefFind next.declarations old.name with
      | some ref => referenceEq old ref | none => false) &&
    next.declarations.all (fun ref =>
      match psKernelEnvironmentFind actual.environment ref.name with
      | some info =>
          psKernelExprV2DeclarationRefMatches ref info && ref.deltaValue.isNone &&
            decodedEq next.built (psKernelConstantInfoType info) ref.type
      | none => false) &&
    (match psKernelExprV2DeclarationRefFind next.declarations target with
    | some ref => ref.type == fixture.value.type && ref.type < fixture.input.size
    | none => false) &&
    fixture.value.ctors.all (fun ctor =>
      match psKernelExprV2DeclarationRefFind next.declarations ctor.name with
      | some ref => ref.type == ctor.type && ref.type < fixture.input.size
      | none => false) &&
    (match psKernelEnvironmentFind actual.environment (psKernelSimpleRecName target),
        psKernelExprV2DeclarationRefFind next.declarations (psKernelSimpleRecName target) with
    | some (.recInfo info),some ref =>
        ref.type >= fixture.input.size &&
        (match ref.kind with
        | .recursorDecl rules =>
            sameList (fun old owned =>
              psKernelNameEq old.ctor owned.ctor && old.nFields == owned.nFields &&
                owned.rhs >= fixture.input.size && decodedEq next.built old.rhs owned.rhs)
              info.rules rules
        | _ => false)
    | _,_ => false)

private def resultEq (fixture : Fixture) (old : Except String PsKernelEnvironment)
    (actual : Option (Except String PsKernelExprV2OrdinaryAdmissionResult)) : Bool :=
  match old,actual with
  | .error a,some (.error b) => a == b
  | .ok a,some (.ok b) => environmentEq a b.environment && ownerSuccess fixture b
  | _,_ => false

private def run (fixture : Fixture) (fuel : Nat) :=
  psKernelExprV2OrdinaryAdmitWithFuel fuel fixture.environment 0 psKernelLeanNatMaxSizeDefault
    fixture.input fixture.owner fixture.decl.levelParams fixture.decl.numParams
    fixture.value fixture.decl.isUnsafe

private def summaryOk (fixture : Fixture) (expected : AdmissionSummary)
    (actual : PsKernelExprV2OrdinaryAdmissionResult) : Bool :=
  match psKernelEnvironmentFind actual.environment target,
      psKernelEnvironmentFind actual.environment (psKernelSimpleRecName target) with
  | some (.inductInfo induct),some (.recInfo recursor) =>
      actual.environment.constants.length == fixture.environment.constants.length +
        fixture.decl.ctors.length + 2 &&
      induct.numParams == fixture.decl.numParams && induct.numIndices == expected.indices &&
      induct.numNested == 0 && induct.isRec == expected.recursive &&
      induct.isReflexive == expected.reflexive && induct.isUnsafe == fixture.decl.isUnsafe &&
      recursor.numParams == fixture.decl.numParams && recursor.numIndices == expected.indices &&
      recursor.numMotives == 1 && recursor.numMinors == fixture.decl.ctors.length &&
      recursor.rules.length == fixture.decl.ctors.length && recursor.k == expected.k &&
      recursor.isUnsafe == fixture.decl.isUnsafe &&
      recursor.base.levelParams.length == fixture.decl.levelParams.length +
        (if expected.propOnly then 0 else 1) &&
      expected.fields.length == fixture.decl.ctors.length &&
      (expected.fields.zipIdx).all (fun (fields,index) =>
        match psKernelEnvironmentFind actual.environment (ctorName index) with
        | some (.ctorInfo ctor) =>
            ctor.cidx == index && ctor.numFields == fields &&
              ctor.numParams == fixture.decl.numParams && ctor.isUnsafe == fixture.decl.isUnsafe
        | _ => false)
  | _,_ => false

private def matrix (counter : IO.Ref Nat) (environment : PsKernelEnvironment) : IO Unit := do
  let before ← counter.get
  unless admissionCases.length == 18 &&
      (admissionCases.filter (fun row => match row.expected with | .ok _ => true | _ => false)).length == 14 do
    throw (IO.userError "admission fixture inventory requires eighteen rows, fourteen positive")
  for row in admissionCases do
    let fixture ← prepare environment row
    for fuel in [0,1,2,3,8,4096] do
      let old := psKernelAddSimpleInductive fuel environment fixture.decl 0 psKernelLeanNatMaxSizeDefault
      require counter ("matrix/" ++ row.label ++ "/fuel=" ++ toString fuel)
        (resultEq fixture old (run fixture fuel))
    let actual := run fixture 4096
    require counter ("matrix/" ++ row.label ++ "/required-outcome")
      (match row.expected,actual with
      | .error expected,some (.error got) => expected == got
      | .ok expected,some (.ok got) => summaryOk fixture expected got
      | _,_ => false)
  unless (← counter.get) - before == 126 do throw (IO.userError "admission matrix assertion inventory")
  IO.println "PSC1_ORDINARY_ADMISSION_SECTION matrix=126"

private abbrev CheckCallback := Nat → PsKernelExprV2CheckContext → PsKernelExprV2CheckState → Nat →
  Option (Except String (PsKernelExprV2CheckState × Nat))
private abbrev DefEqCallback := Nat → PsKernelExprV2CheckContext → PsKernelExprV2CheckState → Nat → Nat →
  Option (Except String (PsKernelExprV2CheckState × Bool))

private def errorIs {α : Type} (message : String) : Option (Except String α) → Bool
  | some (.error got) => message == got
  | _ => false

private def emptySemanticState (state : PsKernelExprV2CheckState) : Bool :=
  state.nextFresh == 0 && state.whnf.coreCache.isEmpty && state.whnf.publicCache.isEmpty &&
    state.checkedInfer.isEmpty && state.success.isEmpty && state.inferOnly.isEmpty &&
    state.unfold.isEmpty && state.failure.isEmpty

private def contextEq (a b : PsKernelExprV2CheckContext) : Bool :=
  a.locals.isEmpty && b.locals.isEmpty &&
    a.scalar.localContext.decls.isEmpty && b.scalar.localContext.decls.isEmpty &&
    a.scalar.localContext.nextIndex == b.scalar.localContext.nextIndex &&
    psKernelNameListsEq a.scalar.levelParams b.scalar.levelParams &&
    psKernelSafetyEq a.scalar.safety b.scalar.safety &&
    a.scalar.eagerReduce == b.scalar.eagerReduce &&
    a.scalar.nativeEvaluator.isNone && b.scalar.nativeEvaluator.isNone &&
    a.scalar.maxRecDepth == b.scalar.maxRecDepth && a.scalar.maxNatSize == b.scalar.maxNatSize &&
    a.scalar.recDepth == b.scalar.recDepth && environmentEq a.scalar.environment b.scalar.environment

private def rootIs (state : PsKernelExprV2CheckState) (root : Nat) (expected : PsKernelExpr) : Bool :=
  match psKernelExprV2DecodeChecked state.whnf.arena with
  | .ok decoded => decodedEq decoded expected root
  | .error _ => false

private def liveReferences (fixture : Fixture) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) : Bool :=
  let refs := state.whnf.declarations
  let environment := context.scalar.environment
  let newNames := environment.constants.filter (fun info =>
    !psKernelEnvironmentContains fixture.environment (psKernelConstantInfoName info))
  match psKernelExprV2DecodeChecked state.whnf.arena with
  | .error _ => false
  | .ok built =>
      refs.length == fixture.owner.declarations.length + newNames.length &&
      psKernelSimpleNameListUnique (refs.map (fun ref => ref.name)) &&
      fixture.owner.declarations.all (fun old =>
        match psKernelExprV2DeclarationRefFind refs old.name with
        | some actual => referenceEq old actual | none => false) &&
      newNames.all (fun info => (psKernelExprV2DeclarationRefFind refs (psKernelConstantInfoName info)).isSome) &&
      refs.all (fun ref =>
        match psKernelEnvironmentFind environment ref.name with
        | some info =>
            psKernelExprV2DeclarationRefMatches ref info && ref.deltaValue.isNone &&
              decodedEq built (psKernelConstantInfoType info) ref.type &&
              (match info,ref.kind with
              | .recInfo recursor,.recursorDecl rules =>
                  sameList (fun rule owned => psKernelNameEq rule.ctor owned.ctor &&
                    rule.nFields == owned.nFields && decodedEq built rule.rhs owned.rhs)
                    recursor.rules rules
              | .recInfo _,_ => false
              | _,_ => true)
        | none => false) &&
      (match psKernelExprV2DeclarationRefFind refs target with
      | some ref => ref.type == fixture.value.type | none => false) &&
      fixture.value.ctors.all (fun ctor =>
        match psKernelExprV2DeclarationRefFind refs ctor.name with
        | some ref => ref.type == ctor.type | none => false) &&
      arenaPrefix fixture.owner.arena state.whnf.arena

/- Stamp only after a successful real first-rule DefEq. The second check
   returns a sentinel before calling a real checker, so synthetic caches
   cannot authorize admission or enter any real checker invocation. -/
private def stampRuleOwner (state : PsKernelExprV2CheckState) : PsKernelExprV2CheckState :=
  ⟨⟨state.whnf.arena,[⟨1,2,101⟩],[⟨1,2,102⟩],[]⟩,
    37,[⟨1,2,103⟩],[⟨1,2,104⟩],[⟨1,2,105⟩],[⟨1,2,106⟩],[⟨1,2,107⟩]⟩

private def cacheStamp (cache : List PsKernelExprV2WhnfCacheEntry) (hash : Nat) : Bool :=
  match cache with
  | [entry] => entry.source == 1 && entry.result == 2 && entry.hash == hash
  | _ => false

private def pairStamp (pairs : List PsKernelExprV2DefEqPair) (hash : Nat) : Bool :=
  match pairs with
  | [entry] => entry.left == 1 && entry.right == 2 && entry.hash == hash
  | _ => false

private def stampedOwner (state : PsKernelExprV2CheckState) : Bool :=
  state.nextFresh == 37 && state.whnf.declarations.isEmpty &&
    cacheStamp state.whnf.coreCache 101 && cacheStamp state.whnf.publicCache 102 &&
    cacheStamp state.checkedInfer 103 && pairStamp state.success 104 &&
    cacheStamp state.inferOnly 105 && cacheStamp state.unfold 106 && pairStamp state.failure 107

private def protocol (counter : IO.Ref Nat) (environment : PsKernelEnvironment) : IO Unit := do
  let before ← counter.get
  let fixture ← prepare environment (row "protocol-enum" s1 [t,t] (good [0,0]))
  let old ← expect (psKernelAddSimpleInductive 4096 environment fixture.decl 0 psKernelLeanNatMaxSizeDefault)
  let recursor ← match psKernelEnvironmentFind old (psKernelSimpleRecName target) with
    | some (.recInfo recursor) => pure recursor
    | _ => throw (IO.userError "missing frozen V1 protocol recursor")
  let firstRule ← match recursor.rules.head? with
    | some rule => pure rule.rhs
    | none => throw (IO.userError "missing first frozen V1 rule")
  let secondRule ← match recursor.rules.drop 1 with
    | rule :: _ => pure rule.rhs
    | _ => throw (IO.userError "missing second frozen V1 rule")
  let firstCtor ← match fixture.value.ctors.head? with
    | some ctor => pure ctor
    | none => throw (IO.userError "missing protocol constructor")
  -- Rebuild the preceding checked work environment without stale index entries.
  let withoutRec := old.constants.reverse.foldl (fun current info =>
    let name := psKernelConstantInfoName info
    if psKernelEnvironmentContains environment name ||
        psKernelNameEq name recursor.base.name then current
    else psKernelEnvironmentAddUnchecked current info) environment
  let safety := if fixture.decl.isUnsafe then PsKernelDefinitionSafety.unsafeDef else .safe
  let typeContext := psKernelExprV2CheckContextEmpty
    (psKernelMkCheckerSession withoutRec recursor.base.levelParams safety 0 psKernelLeanNatMaxSizeDefault).context
  let ruleContext := psKernelExprV2CheckContextEmpty
    (psKernelMkCheckerSession old recursor.base.levelParams safety 0 psKernelLeanNatMaxSizeDefault).context
  let hasRec := fun (context : PsKernelExprV2CheckContext) =>
    psKernelEnvironmentContains context.scalar.environment recursor.base.name
  let atType := fun (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState) (root : Nat) =>
    !hasRec context && rootIs state root recursor.base.type
  let atRule := fun (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
      (root : Nat) (rhs : PsKernelExpr) =>
    hasRec context && rootIs state root rhs
  let realCheck : CheckCallback := psKernelExprV2TryCheckStateWithFuel
  let realWhnf : CheckCallback := psKernelExprV2TryWhnfCheckStateWithFuel
  let realDefEq : DefEqCallback := psKernelExprV2TryDefEqStateWithFuel
  let runWith := fun (owner : PsKernelDagGeneratedState) (value : PsKernelDagInductive)
      (check : CheckCallback) (defeq : DefEqCallback) =>
    psKernelExprV2OrdinaryAdmitWith check realWhnf defeq 4096 environment 0 psKernelLeanNatMaxSizeDefault
      fixture.input owner fixture.decl.levelParams fixture.decl.numParams value fixture.decl.isUnsafe
  let checkFor := fun (mode : Nat) =>
    fun fuel context state root =>
      if atType context state root then
        if mode == 0 then some (.error "REC_TYPE_ERROR")
        else if mode == 1 then none
        else if mode == 2 then some (.ok (state,firstCtor.type))
        else if mode == 3 then
          some (.error (if fuel == 4096 && contextEq context typeContext &&
              emptySemanticState state && liveReferences fixture context state
            then "REC_TYPE_FRESH_OK" else "REC_TYPE_FRESH_BAD"))
        else realCheck fuel context state root
      else if atRule context state root firstRule then
        if mode == 4 then some (.error "FIRST_RULE_ERROR")
        else if mode == 5 then none
        else if mode == 11 then
          some (.error (if fuel == 4096 && contextEq context ruleContext &&
              emptySemanticState state && liveReferences fixture context state
            then "FIRST_RULE_FRESH_OK" else "FIRST_RULE_FRESH_BAD"))
        else realCheck fuel context state root
      else if atRule context state root secondRule && (mode == 6 || mode == 7) then
        if fuel == 4096 && contextEq context ruleContext && stampedOwner state then
          if mode == 6 then some (.error "SECOND_RULE_ERROR") else none
        else some (.error "SECOND_RULE_OWNER_BAD")
      else realCheck fuel context state root
  let defeqFor := fun (mode : Nat) =>
    fun fuel context state left right =>
      if hasRec context then
        if mode == 8 then some (.error "RULE_DEFEQ_ERROR")
        else if mode == 9 then none
        else if mode == 10 then some (.ok (state,false))
        else if mode == 6 || mode == 7 then
          match realDefEq fuel context state left right with
          | some (.ok (next,true)) => some (.ok (stampRuleOwner next,true))
          | other => other
        else realDefEq fuel context state left right
      else realDefEq fuel context state left right
  let baselineOwner := fixture.owner
  let baselineEnvironment := environment
  let intact := fun (_ : Unit) =>
    ownerEq baselineOwner fixture.owner && environmentEq baselineEnvironment environment &&
      builtPrefix fixture.input fixture.owner.built &&
      !psKernelEnvironmentContains environment target &&
      !psKernelEnvironmentContains environment recursor.base.name &&
      fixture.decl.ctors.all (fun ctor => !psKernelEnvironmentContains environment ctor.name)
  let checks : List (String × Nat × Option String) :=
    [("rec-type-error",0,some "REC_TYPE_ERROR"),
     ("rec-type-decline",1,none),
     ("rec-type-nonsort",2,some "expected sort"),
     ("rec-type-fresh-context",3,some "REC_TYPE_FRESH_OK"),
     ("first-rule-error",4,some "FIRST_RULE_ERROR"),
     ("first-rule-decline",5,none),
     ("second-rule-error",6,some "SECOND_RULE_ERROR"),
     ("second-rule-decline",7,none),
     ("rule-defeq-error",8,some "RULE_DEFEQ_ERROR"),
     ("rule-defeq-decline",9,none),
     ("rule-defeq-false",10,some "generated simple recursor rule is not type preserving"),
     ("first-rule-fresh-context",11,some "FIRST_RULE_FRESH_OK")]
  for (label,mode,expected) in checks do
    let result := runWith fixture.owner fixture.value (checkFor mode) (defeqFor mode)
    require counter ("protocol/" ++ label)
      ((match expected with | some message => errorIs message result | none => result.isNone) && intact ())
  require counter "protocol/real-callbacks-match-wrapper"
    (resultEq fixture (.ok old) (runWith fixture.owner fixture.value realCheck realDefEq) &&
      resultEq fixture (.ok old) (run fixture 4096) && intact ())
  let (extended,privateRoot) ← expect (psKernelDagGeneratedImport s1 fixture.owner)
  let invalid := "PSKERNEL_V2_DECODE_INVALID_REFERENCE"
  let forbidden : CheckCallback := fun _ _ _ _ => some (.error "UNEXPECTED_CHECK")
  let forbiddenDefEq : DefEqCallback := fun _ _ _ _ _ => some (.error "UNEXPECTED_DEFEQ")
  require counter "protocol/private-header-id-not-input"
    (privateRoot >= fixture.input.size &&
      errorIs invalid (runWith extended { fixture.value with type := privateRoot } forbidden forbiddenDefEq) &&
      intact ())
  let privateCtors := { firstCtor with type := privateRoot } :: fixture.value.ctors.drop 1
  require counter "protocol/private-ctor-id-not-input"
    (errorIs invalid (runWith extended { fixture.value with ctors := privateCtors } forbidden forbiddenDefEq) &&
      intact ())
  let lateFailure := runWith fixture.owner fixture.value (checkFor 6) (defeqFor 6)
  require counter "protocol/retry-after-late-failure"
    (errorIs "SECOND_RULE_ERROR" lateFailure && intact () &&
      resultEq fixture (.ok old) (run fixture 4096) && intact ())
  unless (← counter.get) - before == 16 do throw (IO.userError "admission protocol assertion inventory")
  IO.println "PSC1_ORDINARY_ADMISSION_SECTION protocol=16"

private def officialName : PsKernelName → Lean.Name
  | .anonymous => .anonymous
  | .str parent text => .str (officialName parent) text
  | .num parent value => .num (officialName parent) value

private def officialLevel : PsKernelLevel → Lean.Level
  | .zero => .zero
  | .succ value => .succ (officialLevel value)
  | .max left right => .max (officialLevel left) (officialLevel right)
  | .imax left right => .imax (officialLevel left) (officialLevel right)
  | .param name => .param (officialName name)
  | .mvar name => .mvar ⟨officialName name⟩

private def officialBinder : PsKernelBinderInfo → Lean.BinderInfo
  | .default => .default
  | .implicit => .implicit
  | .strictImplicit => .strictImplicit
  | .instImplicit => .instImplicit

private def officialExpr : PsKernelExpr → Lean.Expr
  | .bvar index => .bvar index
  | .fvar name => .fvar ⟨officialName name⟩
  | .mvar name => .mvar ⟨officialName name⟩
  | .sort level => .sort (officialLevel level)
  | .const name levels => .const (officialName name) (levels.map officialLevel)
  | .app fn arg => .app (officialExpr fn) (officialExpr arg)
  | .lam name domain body binder =>
      .lam (officialName name) (officialExpr domain) (officialExpr body) (officialBinder binder)
  | .forallE name domain body binder =>
      .forallE (officialName name) (officialExpr domain) (officialExpr body) (officialBinder binder)
  | .letE name type value body nondep =>
      .letE (officialName name) (officialExpr type) (officialExpr value) (officialExpr body) nondep
  | .lit (.nat value) => .lit (.natVal value)
  | .lit (.str value) => .lit (.strVal value)
  | .mdata _ body => .mdata {} (officialExpr body)
  | .proj name index body => .proj (officialName name) index (officialExpr body)

private def officialDeclaration (decl : PsKernelSimpleInductiveDecl) : Lean.Declaration :=
  .inductDecl (decl.levelParams.map officialName) decl.numParams
    [{ name := officialName decl.name, type := officialExpr decl.type,
       ctors := decl.ctors.map (fun ctor =>
         { name := officialName ctor.name, type := officialExpr ctor.type }) }]
    decl.isUnsafe

/- For safe positives, the pinned Lean kernel checks the generated recursor
   type and every RHS against its frozen V1 inferred type. Unsafe admission is
   an explicit contract control, not a claim that Lean checks unsafe bodies. -/
private def officialGenerated (official : Lean.Environment) (fixture : Fixture) : IO Bool := do
  if fixture.decl.isUnsafe then return true
  let old ← expect (psKernelAddSimpleInductive 4096 fixture.environment fixture.decl
    0 psKernelLeanNatMaxSizeDefault)
  let recursor ← match psKernelEnvironmentFind old (psKernelSimpleRecName target) with
    | some (.recInfo value) => pure value
    | _ => throw (IO.userError "official control missing V1 recursor")
  let checkedType := official.addDeclCore 0 0 (.axiomDecl {
    name := officialName (nm "AdmissionOracleRecType")
    levelParams := recursor.base.levelParams.map officialName
    type := officialExpr recursor.base.type
    isUnsafe := false }) none true
  match checkedType with
  | .error _ => return false
  | .ok _ => pure ()
  let session := psKernelMkCheckerSession old recursor.base.levelParams .safe
    0 psKernelLeanNatMaxSizeDefault
  for (rule,index) in recursor.rules.zipIdx do
    let inferred ← expect (psKernelSessionCheck 4096 session rule.rhs)
    let checkedRule := official.addDeclCore 0 0 (.defnDecl {
      name := officialName (.num (nm "AdmissionOracleRule") index)
      levelParams := recursor.base.levelParams.map officialName
      type := officialExpr inferred.fst
      value := officialExpr rule.rhs
      hints := .abbrev
      safety := .safe }) none true
    match checkedRule with
    | .ok _ => pure ()
    | .error _ => return false
  pure true

private def officialControls (environment : PsKernelEnvironment) : IO Unit := do
  Lean.initSearchPath (← Lean.findSysroot)
  let imported ← Lean.importModules #[{ module := `Init }] {}
  let mut baseline := imported
  for (name,isUnsafe) in [(priorName,false),(unsafeName,true)] do
    match baseline.addDeclCore 0 0 (.axiomDecl {
      name := officialName name, levelParams := [], type := officialExpr s1, isUnsafe }) none true with
    | .ok next => baseline := next
    | .error _ => throw (IO.userError "official prior axiom admission")
  let mut accepted := 0
  let mut rejected := 0
  for row in admissionCases do
    let fixture ← prepare environment row
    let result := baseline.addDeclCore 0 0 (officialDeclaration fixture.decl) none true
    let valid ← match row.expected,result with
      | .ok _,.ok next => do
          accepted := accepted + 1
          officialGenerated next fixture
      | .error _,.error _ => do
          rejected := rejected + 1
          pure true
      | _,_ => pure false
    unless valid do throw (IO.userError ("PSC1_ORDINARY_ADMISSION_ORACLE_FAIL " ++ row.label))
    IO.println ("PSC1_ORDINARY_ADMISSION_ORACLE_ASSERT " ++ row.label)
  unless accepted == 14 && rejected == 4 do throw (IO.userError "official admission inventory")
  IO.println "PSC1_ORDINARY_ADMISSION_ORACLE: PASS controls=18 accepted=14 rejected=4 safeGenerated=13 unsafeContract=1"

def main : IO Unit := do
  let counter ← IO.mkRef 0
  require counter "harness/constructor-tags"
    (errorIs "same" (some (.error "same") : Option (Except String String)) &&
      !errorIs "same" (some (.ok "same") : Option (Except String String)) &&
      !errorIs "same" (none : Option (Except String String)))
  IO.println "PSC1_ORDINARY_ADMISSION_SECTION harness=1"
  let environment ← priorEnvironment
  matrix counter environment
  protocol counter environment
  unless (← counter.get) == 143 do throw (IO.userError "exact143 ordinary admission assertions required")
  officialControls environment
  IO.println "PSC1_ORDINARY_ADMISSION_PRIVATE_NATIVE: PASS assertions=143 rows=18 fuelValues=6 privateAdmission=true fullAdmission=false"
