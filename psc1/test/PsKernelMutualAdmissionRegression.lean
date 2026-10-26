import Ps.KernelCore.API.DagMutualAdmission
import Ps.KernelCore.Admission.Inductive.Mutual.Admission
import Ps.KernelCore.Core.ExprV2.Decode
import Ps.KernelCore.Research.ExprV2PagedImport
import Lean

/- The frozen prefix below uses only retained V1 operations and stops before
   provisional metadata. Native differential evidence for a private stage is
   not complete mutual admission. No public fallback supplies direct success. -/
private def expect {α : Type} : Except String α → IO α
  | .ok value => pure value
  | .error error => throw (IO.userError error)
private def require (label : String) (ok : Bool) : IO Unit := do
  unless ok do throw (IO.userError ("PSC1_MUTUAL_ADMISSION_FAIL " ++ label))
  IO.println ("PSC1_MUTUAL_ADMISSION_ASSERT " ++ label)
private def nm (s : String) := PsKernelName.str .anonymous s
private def s1 := PsKernelExpr.sort (.succ .zero)
private def s2 := PsKernelExpr.sort (.succ (.succ .zero))
private def all (n : String) (domain body : PsKernelExpr) :=
  PsKernelExpr.forallE (nm n) domain body .default
private def a := nm "T06MutualA"
private def b := nm "T06MutualB"
private def c := nm "T06MutualC"
private def u := nm "u"
private def v := nm "v"

private def build (value : PsKernelSimpleMutualInductiveDecl) :
    IO (PsKernelExprV2PagedArena × PsKernelDagInductiveGroup) := do
  let mut arena := psKernelExprV2PagedEmpty
  let mut types := []
  for declaration in value.types do
    let (next,root) ← expect (psKernelExprV2PagedImportIntoChecked arena declaration.type)
    arena := next
    let mut ctors := []
    for ctor in declaration.ctors do
      let (next,root) ← expect (psKernelExprV2PagedImportIntoChecked arena ctor.type)
      arena := next
      ctors := ctors ++ [PsKernelDagConstructor.mk ctor.name root]
    types := types ++ [PsKernelDagInductive.mk declaration.name root ctors]
  pure (arena,⟨value.levelParams,value.numParams,types,value.isUnsafe⟩)

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
private def validationEq (left : Except String Unit)
    (right : Option (Except String PsKernelExprV2OrdinaryAdmissionResult)) : Bool :=
  match left,right with
  | .ok _,some (.ok _) => true
  | .error a,some (.error b) => a == b
  | _,_ => false

private def group (ta tb : PsKernelExpr) (params : Nat := 0)
    (levels : List PsKernelName := []) : PsKernelSimpleMutualInductiveDecl :=
  ⟨levels,params,[⟨a,ta,[]⟩,⟨b,tb,[]⟩],false⟩

private def headerNegatives : List (String × PsKernelSimpleMutualInductiveDecl) :=
  [ ("duplicate-level-before-count",⟨[u,u],0,[],false⟩),
    ("minimum-count-before-mvar",⟨[],0,[⟨a,.mvar a,[]⟩],false⟩),
    ("type-name-duplicate-before-mvar",⟨[],0,[⟨a,.mvar a,[]⟩,⟨a,s1,[]⟩],false⟩),
    ("recursor-name-collision",⟨[],0,[⟨a,s1,[]⟩,⟨psKernelSimpleRecName a,s1,[]⟩],false⟩),
    ("constructor-name-collision",⟨[],0,[⟨a,s1,[⟨b,.mvar a⟩]⟩,⟨b,s1,[]⟩],false⟩),
    ("uniform-before-first-static",⟨[],1,[⟨a,.mvar a,[⟨nm "bad",.const b []⟩]⟩,
      ⟨b,s1,[]⟩],false⟩),
    ("first-mvar",group (.mvar a) s1),
    ("later-mvar",group s1 (.mvar b)),
    ("later-fvar-before-level",group s1 (.app (.fvar a) (.sort (.param u)))),
    ("later-undeclared-level",group s1 (.sort (.param u))),
    ("later-illtyped",group s1 (.app s1 s1)),
    ("later-result-universe-mismatch",group s1 s2),
    ("later-parameter-type-mismatch",group (all "A" s1 s1) (all "B" s2 s1) 1),
    ("later-too-few-parameters",group (all "A" s1 s1) s1 1),
    ("later-not-sort-result",group s1 (all "A" s1 (.bvar 0))),
    ("first-not-sort-result",group (all "A" s1 (.bvar 0)) s1) ]

private def ownerLive (environment : PsKernelEnvironment) (owner : PsKernelDagGeneratedState) : Bool :=
  owner.built.size == owner.arena.size && environment.constants.all (fun info =>
    match psKernelExprV2DeclarationRefFind owner.declarations (psKernelConstantInfoName info) with
    | none => false
    | some reference =>
        psKernelNameListsEq reference.levelParams (psKernelConstantInfoBase info).levelParams &&
        decodedEq owner.built (psKernelConstantInfoBase info).type reference.type &&
        psKernelExprV2DeclarationRefKindMatches reference.kind info &&
        (match info,reference.kind with
         | .recInfo recursor,.recursorDecl rules => sameList (fun x y => psKernelNameEq x.ctor y.ctor &&
             x.nFields == y.nFields && decodedEq owner.built x.rhs y.rhs) recursor.rules rules
         | .recInfo _,_ => false
         | _,_ => true))
private def makeOwner (value : PsKernelSimpleMutualInductiveDecl) :
    IO (PsKernelExprV2Decoded × PsKernelDagGeneratedState × PsKernelDagInductiveGroup) := do
  let (arena,dag) ← build value
  let input ← expect (psKernelExprV2DecodeChecked arena)
  pure (input,⟨arena,input,[]⟩,dag)
private def compareWhole (label : String) (fuel depth : Nat) (value : PsKernelSimpleMutualInductiveDecl)
    (positive : Bool) : IO Unit := do
  let (input,owner,dag) ← makeOwner value
  let left := psKernelAddSimpleMutualInductive fuel psKernelEnvironmentEmpty value depth psKernelLeanNatMaxSizeDefault
  let right := psKernelExprV2MutualAdmitWithFuel fuel psKernelEnvironmentEmpty depth psKernelLeanNatMaxSizeDefault input owner dag
  require (label ++ "-actual-original-result")
    (match left,right with
     | .error a,some (.error b) => a == b
     | .ok a,some (.ok b) => fullEnvironmentEq a b.environment
     | _,_ => false)
  if positive && fuel == 256 && depth == 0 then
    let result ← match right with
      | some (.ok result) => pure result
      | some (.error error) => throw (IO.userError ("expected direct full mutual success " ++ label ++ ": " ++ error))
      | none => throw (IO.userError ("unexpected full mutual decline " ++ label))
    require (label ++ "-direct-no-original-restart") true
    require (label ++ "-all-live-type-constructor-rule-metadata-owners") (ownerLive result.environment result.owner)
    require (label ++ "-original-input-namespace-and-session-retained")
      (input.size == owner.built.size && owner.declarations.isEmpty && psKernelEnvironmentEmpty.constants.isEmpty &&
        result.owner.arena.size >= owner.arena.size)

private def positives : List (String × PsKernelSimpleMutualInductiveDecl) := Id.run do
  let ap := fun n => psKernelApplyArgs (.const a []) [.bvar n]
  let bp := fun n => psKernelApplyArgs (.const b []) [.bvar n,.bvar n]
  let cp := fun n => psKernelApplyArgs (.const c []) [.bvar n,.bvar n,.bvar n]
  let close := fun body => all "P" s1 body
  let rows := [[[],[],[]],[[close (ap 0)],[close (bp 0)],[close (cp 0)]],
    [[close (ap 0),close (all "f" (ap 0) (ap 1))],[close (bp 0)],[]],
    [[close (all "f" (bp 0) (ap 1))],[close (all "f" (cp 0) (bp 1))],[close (all "f" (ap 0) (cp 1))]],
    [[close (all "f" (all "x" (.bvar 0) (ap 1)) (ap 1))],[],[close (cp 0)]]]
  let mut cases := []
  for (kind,resultLevel) in [("prop",PsKernelLevel.zero),("type",PsKernelLevel.succ .zero)] do
    for unsafeFlag in [false,true] do
      let typeRows := [(a,all "P" s1 (.sort resultLevel)),(b,all "P" s1 (all "i" s1 (.sort resultLevel))),
        (c,all "P" s1 (all "i" s1 (all "j" s1 (.sort resultLevel))))]
      for (row,i) in rows.zipIdx do
        let label := kind ++ (if unsafeFlag then "-unsafe-" else "-safe-") ++ toString i
        let types := ((typeRows.zip row).zipIdx).map (fun (((name,type),ctors),j) =>
          PsKernelSimpleMutualTypeDecl.mk name type ((ctors.zipIdx).map (fun (body,n) =>
            PsKernelSimpleConstructorDecl.mk (nm (label ++ "-family" ++ toString j ++ "-ctor" ++ toString n)) body)))
        cases := cases ++ [(label,PsKernelSimpleMutualInductiveDecl.mk [] 1 types unsafeFlag)]
  for (label,levelName) in [("polymorphic",u),("polymorphic-elim-name-collision",psKernelSimpleFreshElimName [])] do
    let level := PsKernelLevel.param levelName
    let binder := PsKernelExpr.sort level
    let ta := all "P" binder binder
    let resultA := PsKernelExpr.app (.const a [level]) (.bvar 0)
    let resultB := PsKernelExpr.app (.const b [level]) (.bvar 0)
    cases := cases ++ [(label,⟨[levelName],1,[⟨a,ta,[⟨nm (label ++ "-a"),all "P" binder resultA⟩]⟩,
      ⟨b,ta,[⟨nm (label ++ "-b"),all "P" binder (all "f" resultA
        (PsKernelExpr.app (.const b [level]) (.bvar 1)))⟩]⟩],false⟩)]
  return cases

private def constructorNegatives : List (String × PsKernelSimpleMutualInductiveDecl) := Id.run do
  let ap := fun n => PsKernelExpr.app (.const a []) (.bvar n)
  let close := fun body => all "P" s1 body
  let values := [("ctor-mvar",PsKernelExpr.mvar a),
    ("ctor-wrong-family",close (PsKernelExpr.app (.const b []) (.bvar 0))),
    ("ctor-nonpositive",close (all "f" (all "x" (ap 0) (.bvar 1)) (ap 1))),
    ("ctor-nonuniform-nested",close (all "f" (PsKernelExpr.app (.const a []) (ap 0)) (ap 1))),
    ("ctor-parameter-domain-mismatch",all "P" s2 s1),
    ("ctor-too-few-parameters",s1),("ctor-invalid-result",close s1),
    ("ctor-universe-too-large",close (all "f" s2 (ap 1)))]
  return values.map (fun (label,type) => (label,⟨[],1,[⟨a,all "P" s1 s1,[⟨nm label,type⟩]⟩,
    ⟨b,all "P" s1 s1,[]⟩],false⟩))

private def protocols : IO Unit := do
  let value := PsKernelSimpleMutualInductiveDecl.mk [] 0 [⟨a,s1,[]⟩,⟨b,s1,[]⟩] false
  let (input,owner,dag) ← makeOwner value
  let poison := fun (_fuel : Nat) (_context : PsKernelExprV2CheckContext)
      (_state : PsKernelExprV2CheckState) (_root : Nat) => some (Except.error "CHECK_CALLED")
  let noneCheck := fun (_fuel : Nat) (_context : PsKernelExprV2CheckContext)
      (_state : PsKernelExprV2CheckState) (_root : Nat) => none
  let neverEq := fun (_fuel : Nat) (_context : PsKernelExprV2CheckContext)
      (_state : PsKernelExprV2CheckState) (_left _right : Nat) => none
  require "protocol-unsynchronized-owner-before-all-callbacks"
    (match psKernelExprV2MutualAdmitWith poison poison neverEq 256 psKernelEnvironmentEmpty 0
        psKernelLeanNatMaxSizeDefault input {owner with built := psKernelExprV2DecodedEmpty} dag with
     | some (.error error) => error == "PSKERNEL_V2_GENERATED_OWNER_MISMATCH" | _ => false)
  require "protocol-oversized-original-prefix-before-all-callbacks"
    (match psKernelExprV2MutualAdmitWith poison poison neverEq 256 psKernelEnvironmentEmpty 0
        psKernelLeanNatMaxSizeDefault {input with size := owner.built.size+1} owner dag with
     | some (.error error) => error == "PSKERNEL_V2_GENERATED_OWNER_MISMATCH" | _ => false)
  require "protocol-early-check-error-preserved"
    (match psKernelExprV2MutualAdmitWith poison poison neverEq 256 psKernelEnvironmentEmpty 0
        psKernelLeanNatMaxSizeDefault input owner dag with
     | some (.error error) => error == "CHECK_CALLED" | _ => false)
  require "protocol-early-decline-returns-no-private-result"
    ((psKernelExprV2MutualAdmitWith noneCheck poison neverEq 256 psKernelEnvironmentEmpty 0
      psKernelLeanNatMaxSizeDefault input owner dag).isNone)
  let lateNone := fun (nextFuel : Nat) (context : PsKernelExprV2CheckContext)
      (state : PsKernelExprV2CheckState) (root : Nat) =>
    if psKernelEnvironmentContains context.scalar.environment (psKernelSimpleRecName a) then none
    else psKernelExprV2TryCheckStateWithFuel nextFuel context state root
  let lateError := fun (nextFuel : Nat) (context : PsKernelExprV2CheckContext)
      (state : PsKernelExprV2CheckState) (root : Nat) =>
    if psKernelEnvironmentContains context.scalar.environment (psKernelSimpleRecName a) then
      some (Except.error "LATE_RECURSOR_CHECK_ERROR")
    else psKernelExprV2TryCheckStateWithFuel nextFuel context state root
  require "protocol-late-recursor-decline-returns-no-private-result"
    ((psKernelExprV2MutualAdmitWith lateNone psKernelExprV2TryWhnfCheckStateWithFuel psKernelExprV2TryDefEqStateWithFuel
      256 psKernelEnvironmentEmpty 0 psKernelLeanNatMaxSizeDefault input owner dag).isNone)
  require "protocol-late-recursor-error-preserved-without-publication"
    (match psKernelExprV2MutualAdmitWith lateError psKernelExprV2TryWhnfCheckStateWithFuel psKernelExprV2TryDefEqStateWithFuel
        256 psKernelEnvironmentEmpty 0 psKernelLeanNatMaxSizeDefault input owner dag with
     | some (.error error) => error == "LATE_RECURSOR_CHECK_ERROR" && owner.declarations.isEmpty &&
         psKernelEnvironmentEmpty.constants.isEmpty | _ => false)

def main : IO Unit := do
  unless positives.length == 22 && headerNegatives.length == 16 && constructorNegatives.length == 8 do
    throw (IO.userError "full mutual case inventory changed")
  for (label,value) in positives do
    for fuel in [0,1,8,256] do compareWhole (label ++ "-fuel-" ++ toString fuel) fuel 0 value true
  let negatives := headerNegatives ++ constructorNegatives ++
    [("no-types",⟨[],0,[],false⟩),("one-type",⟨[],0,[⟨a,s1,[]⟩],false⟩)]
  for (label,value) in negatives do
    for fuel in [0,8,256] do compareWhole (label ++ "-fuel-" ++ toString fuel) fuel 0 value false
  let depthCase ← match positives[5]? with | some value => pure value.snd | none => throw (IO.userError "missing depth case")
  for depth in [1,4] do compareWhole ("max-depth-" ++ toString depth) 256 depth depthCase false
  protocols
  IO.println "PSC1_MUTUAL_ADMISSION_NATIVE: PASS assertions=240 positiveGroups=22 negativeGroups=26 completeComparisons=168 positiveOwnerControls=66 resource=2 protocols=6"
