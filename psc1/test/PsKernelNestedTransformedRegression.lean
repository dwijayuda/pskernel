import Ps.KernelCore.API.DagNestedTransformed
import Ps.KernelCore.API.Kernel
import Ps.KernelCore.Core.ExprV2.Decode
import Ps.KernelCore.Research.ExprV2PagedImport
import Lean

private def expect {α : Type} : Except String α → IO α
  | .ok x => pure x
  | .error e => throw (IO.userError e)
private def acceptPublic {α : Type} : Except PsKernelError α → IO α
  | .ok x => pure x
  | .error _ => throw (IO.userError "fixture public admission failed")
private def require (label : String) (value : Bool) : IO Unit := do
  unless value do throw (IO.userError ("PSC1_NESTED_TRANSFORMED_FAIL " ++ label))
  IO.println ("PSC1_NESTED_TRANSFORMED_ASSERT " ++ label)
private def nm (s : String) := PsKernelName.str .anonymous s
private def s1 := PsKernelExpr.sort (.succ .zero)
private def all (n : String) (domain body : PsKernelExpr) := PsKernelExpr.forallE (nm n) domain body .default
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

private def inductiveEq (left right : PsKernelInductiveInfo) : Bool :=
  psKernelNameEq left.base.name right.base.name &&
    psKernelNameListsEq left.base.levelParams right.base.levelParams &&
    psKernelExprEqual left.base.type right.base.type &&
    left.numParams == right.numParams && left.numIndices == right.numIndices &&
    psKernelNameListsEq left.all right.all && psKernelNameListsEq left.ctors right.ctors &&
    left.numNested == right.numNested && left.isRec == right.isRec &&
    left.isReflexive == right.isReflexive && left.isUnsafe == right.isUnsafe

private def constantEq (left right : PsKernelConstantInfo) : Bool :=
  match left,right with
  | .inductInfo a,.inductInfo b => inductiveEq a b
  | .ctorInfo a,.ctorInfo b =>
      psKernelNameEq a.base.name b.base.name &&
      psKernelNameListsEq a.base.levelParams b.base.levelParams &&
      psKernelExprEqual a.base.type b.base.type &&
      psKernelNameEq a.induct b.induct && a.cidx == b.cidx &&
      a.numParams == b.numParams && a.numFields == b.numFields && a.isUnsafe == b.isUnsafe
  | _,_ => false

private def environmentEq (left right : PsKernelEnvironment) : Bool :=
  left.quotInitialized == right.quotInitialized &&
    left.runtime.nativeEvaluator.isNone && right.runtime.nativeEvaluator.isNone &&
    sameList constantEq left.constants right.constants &&
    left.constants.all (fun original =>
      match psKernelEnvironmentFind left (psKernelConstantInfoName original),
          psKernelEnvironmentFind right (psKernelConstantInfoName original) with
      | some a,some b => constantEq original a && constantEq original b
      | _,_ => false)

private def legacyBinderEq (left right : PsKernelOpenBinder) : Bool :=
  psKernelNameEq left.internalName right.internalName && psKernelNameEq left.userName right.userName &&
    psKernelExprEqual left.type right.type && psKernelBinderInfoEq left.binderInfo right.binderInfo
private def legacyCtorEq (left right : PsKernelSimpleConstructorDecl) : Bool :=
  psKernelNameEq left.name right.name && psKernelExprEqual left.type right.type
private def legacyTypeEq (left right : PsKernelSimpleMutualTypeShape) : Bool :=
  psKernelNameEq left.decl.name right.decl.name && psKernelExprEqual left.decl.type right.decl.type &&
    sameList legacyCtorEq left.decl.ctors right.decl.ctors && sameList legacyBinderEq left.indices right.indices
private def legacyShapeEq (left right : PsKernelSimpleMutualConstructorShape) : Bool :=
  left.owner == right.owner && legacyCtorEq left.ctor right.ctor && sameList legacyBinderEq left.fields right.fields &&
    sameList (fun x y => legacyBinderEq x.field y.field && x.target == y.target &&
      sameList legacyBinderEq x.args y.args && sameList psKernelExprEqual x.indices y.indices)
      left.recursiveFields right.recursiveFields && sameList psKernelExprEqual left.resultIndices right.resultIndices
private def recursorEq (left right : PsKernelRecursorInfo) : Bool :=
  psKernelNameEq left.base.name right.base.name && psKernelNameListsEq left.base.levelParams right.base.levelParams &&
    psKernelExprEqual left.base.type right.base.type && psKernelNameListsEq left.all right.all &&
    left.numParams == right.numParams && left.numIndices == right.numIndices &&
    left.numMotives == right.numMotives && left.numMinors == right.numMinors && left.k == right.k &&
    left.isUnsafe == right.isUnsafe && sameList (fun x y => psKernelNameEq x.ctor y.ctor &&
      x.nFields == y.nFields && psKernelExprEqual x.rhs y.rhs) left.rules right.rules

private def fullConstantEq (left right : PsKernelConstantInfo) : Bool :=
  match left,right with
  | .recInfo x,.recInfo y => recursorEq x y
  | _,_ => constantEq left right
private def fullEnvironmentEq (left right : PsKernelEnvironment) : Bool :=
  left.quotInitialized == right.quotInitialized && left.runtime.nativeEvaluator.isNone &&
    right.runtime.nativeEvaluator.isNone && sameList fullConstantEq left.constants right.constants &&
    left.constants.all (fun original =>
      match psKernelEnvironmentFind left (psKernelConstantInfoName original),
          psKernelEnvironmentFind right (psKernelConstantInfoName original) with
      | some x,some y => fullConstantEq original x && fullConstantEq original y
      | _,_ => false)

private def sameExprs (a b : List PsKernelExpr) : Bool :=
  a.length == b.length && (a.zip b).all (fun p => psKernelExprEqual p.1 p.2)
private def sameTypes (a b : List PsKernelSimpleMutualTypeDecl) : Bool :=
  a.length == b.length && (a.zip b).all (fun p =>
    psKernelNameEq p.1.name p.2.name && psKernelExprEqual p.1.type p.2.type &&
    p.1.ctors.length == p.2.ctors.length && (p.1.ctors.zip p.2.ctors).all (fun c =>
      psKernelNameEq c.1.name c.2.name && psKernelExprEqual c.1.type c.2.type))
private def sameFamilies (a b : List PsKernelSimpleNestedAuxFamily) : Bool :=
  a.length == b.length && (a.zip b).all (fun p =>
    psKernelNameEq p.1.auxName p.2.auxName && psKernelNameEq p.1.outerName p.2.outerName &&
    p.1.outerLevels.length == p.2.outerLevels.length &&
    (p.1.outerLevels.zip p.2.outerLevels).all (fun l => psKernelLevelEq l.1 l.2) &&
    sameExprs p.1.fixedParams p.2.fixedParams && psKernelExprEqual p.1.nestedTemplate p.2.nestedTemplate &&
    p.1.ctorMap.length == p.2.ctorMap.length && (p.1.ctorMap.zip p.2.ctorMap).all (fun c =>
      psKernelNameEq c.1.auxCtor c.2.auxCtor && psKernelNameEq c.1.outerCtor c.2.outerCtor))
private def sameProcessed (a b : PsKernelSimpleNestedProcessQueueResult) : Bool :=
  sameTypes a.types b.types && sameFamilies a.state.aux b.state.aux &&
  a.state.fresh == b.state.fresh && sameTypes a.state.created b.state.created
private def build (decl : PsKernelSimpleMutualInductiveDecl) :
    IO (PsKernelExprV2PagedArena × PsKernelDagInductiveGroup) := do
  let mut arena := psKernelExprV2PagedEmpty
  let mut types := []
  for t in decl.types do
    let (next,root) ← expect (psKernelExprV2PagedImportIntoChecked arena t.type)
    arena := next
    let mut ctors := []
    for c in t.ctors do
      let (next,root) ← expect (psKernelExprV2PagedImportIntoChecked arena c.type)
      arena := next
      ctors := ctors ++ [PsKernelDagConstructor.mk c.name root]
    types := types ++ [PsKernelDagInductive.mk t.name root ctors]
  pure (arena,⟨decl.levelParams,decl.numParams,types,decl.isUnsafe⟩)
private def originalPrefix (fuel : Nat) (environment : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl) : Except String PsKernelOpenBindersResult := do
  psKernelSimpleNestedCheckReserved decl
  psKernelSimpleCheckUniformOccurrences (psKernelSimpleMutualNames decl.types)
    decl.levelParams decl.numParams (psKernelSimpleMutualCtorTypes decl.types)
  match decl.types with
  | [] => throw "empty nested inductive declaration"
  | first :: _ =>
      let safety := if decl.isUnsafe then PsKernelDefinitionSafety.unsafeDef else .safe
      let initial := psKernelMkCheckerSession environment decl.levelParams safety 0 psKernelLeanNatMaxSizeDefault
      let checked ← psKernelSessionCheck fuel initial first.type
      let sorted ← psKernelSessionEnsureSort fuel checked.snd checked.fst
      psKernelOpenSimpleHeaderParams fuel sorted.snd first.type decl.numParams
private def compare (label : String) (session : PsKernelKernelSession)
    (decl : PsKernelSimpleMutualInductiveDecl) (expectAux : Bool) : IO Unit := do
  let (arena,value) ← build decl
  let input ← expect (psKernelExprV2DecodeChecked arena)
  let owner ← expect (psKernelDagGeneratedFromSession session arena input)
  let params ← expect (originalPrefix 256 session.environment decl)
  let original ← expect (psKernelSimpleNestedProcessQueue 256 session.environment decl.levelParams
    (psKernelSimpleMutualNames decl.types) params.binders decl.numParams decl.types [] ⟨[],1,[]⟩)
  let some attempted := psKernelExprV2NestedPreprocessWithFuel 256 session.environment 0
    psKernelLeanNatMaxSizeDefault input owner value | throw (IO.userError "private preprocessing declined")
  let actual ← expect attempted
  require (label ++ "-whole-plan-parity") (sameProcessed original actual.processed)
  require (label ++ "-exact-auxiliary-presence") (actual.processed.state.aux.isEmpty == !expectAux)
  require (label ++ "-synchronized-append-only-owner")
    (owner.arena.size ≤ actual.owner.arena.size && actual.owner.built.size == actual.owner.arena.size)
  for root in List.range input.size do
    let old ← expect (psKernelExprV2DecodedRequire input root)
    let new ← expect (psKernelExprV2DecodedRequire actual.owner.built root)
    unless psKernelExprEqual old new do throw (IO.userError "original input prefix changed")
  require (label ++ "-all-original-input-roots-retained") true
  let prepared ← expect (psKernelExprV2NestedPrepareTransformed value actual)
  let decodedGroup ← expect (psKernelDagDecodeGroup prepared.owner.built prepared.value)
  require (label ++ "-prepared-targets-exact-original-pure-plan") (sameTypes decodedGroup.types original.types)
  let mut sameHeaders := true
  for typ in value.types do
    let some imported := psKernelExprV2NestedOriginType typ.name prepared.value.types
      | throw (IO.userError "original family missing from transformed group")
    sameHeaders := sameHeaders && imported.type == typ.type
  require (label ++ "-all-original-header-ids-reused") sameHeaders
  let mut intact := true
  for id in List.range input.size do
    let beforeEntry ← expect (psKernelExprV2PagedRequire owner.arena id)
    let afterEntry ← expect (psKernelExprV2PagedRequire prepared.owner.arena id)
    let beforeExpr ← expect (psKernelExprV2DecodedRequire input id)
    let afterExpr ← expect (psKernelExprV2DecodedRequire prepared.owner.built id)
    intact := intact && psKernelExprV2NestedOverlayNodeSame beforeEntry.node afterEntry.node &&
      beforeEntry.hash == afterEntry.hash && beforeEntry.looseRange == afterEntry.looseRange &&
      beforeEntry.hasFVar == afterEntry.hasFVar && beforeEntry.hasExprMVar == afterEntry.hasExprMVar &&
      beforeEntry.depth == afterEntry.depth && psKernelExprEqual beforeExpr afterExpr
  require (label ++ "-all-original-ids-and-metadata-preserved") intact
  let reference ← expect (if expectAux then
    psKernelAddSimpleMutualInductive 256 session.environment
      ⟨decl.levelParams,decl.numParams,original.types,decl.isUnsafe⟩ 0 psKernelLeanNatMaxSizeDefault
    else psKernelSimpleNestedAddWithoutAux 256 session.environment decl original.types 0 psKernelLeanNatMaxSizeDefault)
  let some checked := psKernelExprV2NestedTransformedWithFuel 256 session.environment 0 psKernelLeanNatMaxSizeDefault input owner value
    | throw (IO.userError "private transformed admission declined")
  let checked ← expect checked
  require (label ++ "-whole-transformed-environment-exact-actual-original") (fullEnvironmentEq reference checked.admitted.environment)
  require (label ++ "-final-owner-synchronized-and-original-input-intact")
    (checked.admitted.owner.arena.size == checked.admitted.owner.built.size && owner.arena.size ≤ checked.admitted.owner.arena.size)
  let mut recursors := true
  for typ in original.types do
    let recName := psKernelSimpleRecName typ.name
    match psKernelEnvironmentFind checked.admitted.environment recName,
        psKernelExprV2DeclarationRefFind checked.admitted.owner.declarations recName with
    | some (.recInfo info),some owned =>
        recursors := recursors && decodedEq checked.admitted.owner.built info.base.type owned.type
        match owned.kind with
        | .recursorDecl rules =>
            recursors := recursors && sameList (fun a b => psKernelNameEq a.ctor b.ctor && a.nFields == b.nFields &&
              decodedEq checked.admitted.owner.built a.rhs b.rhs) info.rules rules
        | _ => recursors := false
    | _,_ => recursors := false
  require (label ++ "-all-checked-recursor-owner-types-and-rules-exact") recursors
  let oldCount := psKernelEnvironmentSize session.environment
  discard (acceptPublic (psKernelV1AdmitDeclaration session (.nestedInductive decl)))
  require (label ++ "-actual-original-complete-admission-accepts")
    (psKernelEnvironmentSize session.environment == oldCount)

def main : IO Unit := do
  let mut failed := false
  try require "forced-failure" false catch _ => failed := true
  require "harness-rejection-active" failed
  let empty ← acceptPublic (psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault)
  let enumName := nm "NestedPlanEnum"
  compare "no-aux-enum" empty ⟨[],0,[⟨enumName,s1,[⟨PsKernelName.str enumName "mk",.const enumName []⟩]⟩],false⟩ false
  let boxName := nm "NestedPlanBox"
  let box : PsKernelSimpleInductiveDecl := ⟨[],boxName,all "A" s1 s1,
    [⟨PsKernelName.str boxName "mk",all "A" s1
      (all "value" (.bvar 0) (.app (.const boxName []) (.bvar 1)))⟩],false,1⟩
  let boxed ← acceptPublic (psKernelV1AdmitDeclaration empty (.ordinaryInductive box))
  let name := nm "NestedPlanOwner"
  let self := PsKernelExpr.const name []
  let nested := PsKernelExpr.app (.const boxName []) self
  let single : PsKernelSimpleMutualInductiveDecl := ⟨[],0,[⟨name,s1,
    [⟨PsKernelName.str name "mk",all "child" nested self⟩]⟩],false⟩
  compare "genuine-nested-box" boxed.session single true
  let repeated : PsKernelSimpleMutualInductiveDecl := {single with types := [⟨name,s1,
    [⟨PsKernelName.str name "left",all "child" nested self⟩,
     ⟨PsKernelName.str name "right",all "child" nested self⟩]⟩]}
  compare "repeated-template-reuses-family" boxed.session repeated true
  let deep := PsKernelExpr.app (.const boxName []) nested
  let twice : PsKernelSimpleMutualInductiveDecl := {single with types := [⟨name,s1,
    [⟨PsKernelName.str name "mk",all "child" deep self⟩]⟩]}
  compare "nested-discovery-queue" boxed.session twice true
  let paramName := nm "NestedPlanParameterized"
  let applied := PsKernelExpr.app (.const paramName []) (.bvar 0)
  let paramNested := PsKernelExpr.app (.const boxName []) applied
  let parameterized : PsKernelSimpleMutualInductiveDecl := ⟨[],1,
    [⟨paramName,all "A" s1 s1,[⟨PsKernelName.str paramName "mk",
      all "A" s1 (all "child" paramNested (.app (.const paramName []) (.bvar 1)))⟩]⟩],false⟩
  compare "shared-parameter-rebasing" boxed.session parameterized true
  let a := nm "NestedNoAuxA"
  let b := nm "NestedNoAuxB"
  compare "no-aux-mutual-dispatch" empty ⟨[],0,
    [⟨a,s1,[⟨PsKernelName.str a "mk",.const a []⟩]⟩,
     ⟨b,s1,[⟨PsKernelName.str b "mk",.const b []⟩]⟩],false⟩ false
  let u := nm "u"
  let level := PsKernelLevel.param u
  let sortU := PsKernelExpr.sort (.succ level)
  let boxUName := nm "NestedUniverseBox"
  let boxU : PsKernelSimpleInductiveDecl := ⟨[u],boxUName,all "A" sortU sortU,
    [⟨PsKernelName.str boxUName "mk",all "A" sortU
      (all "value" (.bvar 0) (.app (.const boxUName [level]) (.bvar 1)))⟩],false,1⟩
  let boxedU ← acceptPublic (psKernelV1AdmitDeclaration empty (.ordinaryInductive boxU))
  let nestedUName := nm "NestedUniverseOwner"
  let selfU := PsKernelExpr.const nestedUName [level]
  compare "universe-polymorphic-transformed-family" boxedU.session ⟨[u],0,
    [⟨nestedUName,sortU,[⟨PsKernelName.str nestedUName "mk",
      all "child" (.app (.const boxUName [level]) selfU) selfU⟩]⟩],false⟩ true
  let ordinary := fun (_fuel : Nat) (_env : PsKernelEnvironment) (_depth _nat : Nat)
      (_input : PsKernelExprV2Decoded) (_owner : PsKernelDagGeneratedState) (_levels : List PsKernelName)
      (_params : Nat) (_type : PsKernelDagInductive) (_unsafe : Bool) =>
        (some (.error "ordinary") : Option (Except String PsKernelExprV2OrdinaryAdmissionResult))
  let admitMutual := fun (_fuel : Nat) (_env : PsKernelEnvironment) (_depth _nat : Nat)
      (_input : PsKernelExprV2Decoded) (_owner : PsKernelDagGeneratedState) (_value : PsKernelDagInductiveGroup) =>
        (some (.error "mutual") : Option (Except String PsKernelExprV2OrdinaryAdmissionResult))
  let owner := PsKernelDagGeneratedState.mk psKernelExprV2PagedEmpty psKernelExprV2DecodedEmpty []
  let group : PsKernelDagInductiveGroup := ⟨[],0,[],false⟩
  let errorIs := fun (result : Option (Except String PsKernelExprV2OrdinaryAdmissionResult)) (expected : String) =>
    match result with | some (.error error) => error == expected | _ => false
  let run := fun (aux : Bool) (value : PsKernelDagInductiveGroup) =>
    psKernelExprV2NestedAdmitModeWith ordinary admitMutual aux 256 empty.environment 0 psKernelLeanNatMaxSizeDefault owner value
  require "mode-empty-original-error-first" (errorIs (run false group) "empty nested inductive declaration")
  let first : PsKernelDagInductive := ⟨a,0,[]⟩
  require "mode-no-aux-single-ordinary" (errorIs (run false {group with types := [first]}) "ordinary")
  require "mode-no-aux-multiple-mutual" (errorIs (run false {group with types := [first,⟨b,0,[]⟩]}) "mutual")
  require "mode-aux-always-mutual-with-exact-prefix" (errorIs (run true {group with types := [first]}) "nested transformed admission: mutual")
  require "prefix-aux-decline-retained" ((psKernelExprV2NestedTransformedPrefix true none).isNone)
  require "prefix-no-aux-decline-retained" ((psKernelExprV2NestedTransformedPrefix false none).isNone)
  require "prefix-no-aux-hard-error-retained" (errorIs (psKernelExprV2NestedTransformedPrefix false (some (.error "marker"))) "marker")
  IO.println "PSC1_NESTED_TRANSFORMED_NATIVE: PASS controls=85 actualOriginalTransformedEnvironments=7 noAuxOrdinary=true noAuxMutual=true auxMutual=true privateOnly=true publicRouteChanged=false restorationValidated=false"

