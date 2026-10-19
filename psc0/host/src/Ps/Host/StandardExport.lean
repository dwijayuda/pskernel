/-
Native-only authoring of a reviewed, closed Standard Core asset.
Reference: Lean 4.35.0 Declaration.lean, Expr.lean, Structure.lean and
Init/Prelude.lean, commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Generated upstream bodies retain their Apache-2.0 attribution.
This tool is not imported by the portable compiler.
-/
import Ps.Host.StandardClosure
import Ps.Meta.Reduce
import Ps.Host.StandardSource
import Ps.Host.StandardManifest
import Ps.Environment.StandardWellFounded
import Ps.Environment.StandardPartialFixpoint
import Ps.Host.FloatConstructive
import Ps.Host.FloatCanonicalContracts

namespace PsV7Native

open StandardSource

private def exportName : Lean.Name → PsName
  | .anonymous => .anonymous
  | .str parent value => .str (exportName parent) value
  | .num parent value => .num (exportName parent) value

private def exportLevel : Lean.Level → Except String PsLevel
  | .zero => pure .zero
  | .succ value => return .succ (← exportLevel value)
  | .max a b => return .max (← exportLevel a) (← exportLevel b)
  | .imax a b => return .imax (← exportLevel a) (← exportLevel b)
  | .param name => pure (.param (exportName name))
  | .mvar _ => throw "universe metavariable in Standard asset"

private def exportBinder : Lean.BinderInfo → PsBinderInfo
  | .default => .explicit
  | .implicit => .implicit
  | .strictImplicit => .strictImplicit
  | .instImplicit => .instanceImplicit

private def exportExpr : Lean.Expr → Except String PsExpr
  | .bvar index => pure (.bvar index)
  | .fvar _ => throw "free variable in Standard asset"
  | .mvar _ => throw "metavariable in Standard asset"
  | .sort level => return .sortE (← exportLevel level)
  | .const name levels => return .constE (exportName name) (← levels.mapM exportLevel)
  | .app fn arg => return .app (← exportExpr fn) (← exportExpr arg)
  | .lam name type body binder =>
    return .lam (exportName name) (← exportExpr type) (← exportExpr body) (exportBinder binder)
  | .forallE name type body binder =>
    return .forallE (exportName name) (← exportExpr type) (← exportExpr body) (exportBinder binder)
  | .letE name type value body _ =>
    return .letE (exportName name) (← exportExpr type) (← exportExpr value) (← exportExpr body)
  | .lit (.natVal value) => pure (.lit (.natural value))
  | .lit (.strVal value) => pure (.lit (.string value))
  | .mdata _ value => exportExpr value
  | .proj name index value => return .proj (exportName name) index (← exportExpr value)

private def exportCoreExpr (eraseAutoParams : Bool) (expression : Lean.Expr) :
    Except String PsExpr :=
  exportExpr (if eraseAutoParams then standardEraseAutoParam expression else expression)

-- Single-family recursor fields follow kernel/inductive.cpp is_rec_argument:
-- peel a dependent Pi telescope, then require the family at its result head.
-- Nested occurrences remain refused; official replay checks positivity.
private def recursiveFields (family : Lean.Name) (parameters fields : Nat)
    (type : Lean.Expr) : Except String (List Nat) := do
  let rec skip : Nat → Lean.Expr → Except String Lean.Expr
    | 0, value => pure value
    | n + 1, .forallE _ _ body _ => skip n body
    | _, _ => throw "constructor parameter telescope mismatch"
  let rec collect : Nat → Nat → Lean.Expr → Except String (List Nat)
    | 0, _, _ => pure []
    | n + 1, index, .forallE _ domain body _ => do
      let rest ← collect n (index + 1) body
      if domain.getForallBody.getAppFn.isConstOf family then return index :: rest
      if domain.getUsedConstants.contains family then
        throw "nested recursive field is outside Standard asset policy"
      return rest
    | _, _, _ => throw "constructor field telescope mismatch"
  collect fields 0 (← skip parameters type)

private def exportDeclaration (native : Lean.Environment) (allowedAssumptions : List Lean.Name)
    (info : Lean.ConstantInfo) (eraseAutoParams : Bool := false) :
    Except String PsDeclaration := do
  if info.isUnsafe || info.isPartial then throw "unsafe or partial Standard declaration"
  let name := exportName info.name
  let levels := info.levelParams.map exportName
  let type ← exportCoreExpr eraseAutoParams info.type
  match info with
  | .defnInfo value => return .definitionDecl name levels type (← exportCoreExpr eraseAutoParams value.value)
  | .thmInfo value => return .theoremDecl name levels type (← exportCoreExpr eraseAutoParams value.value)
  | .opaqueInfo value => return .opaqueDecl name levels type (← exportCoreExpr eraseAutoParams value.value)
  | .inductInfo value =>
    let logical := match value.type.getForallBody with
      | .sort .zero => true
      | _ => false
    unless value.all == [value.name] && value.numNested == 0 &&
        (!value.isReflexive || logical) do
      throw "mutual, nested or computational reflexive inductive is outside Standard asset policy"
    return .inductiveDecl {
      name, levelParams := levels, type, numParams := value.numParams,
      numIndices := value.numIndices, constructors := value.ctors.map exportName,
      isStructure := Lean.isStructure native value.name }
  | .ctorInfo value =>
    return .constructorDecl {
      name, levelParams := levels, type, inductiveName := exportName value.induct,
      constructorIndex := value.cidx, numParams := value.numParams, numFields := value.numFields,
      recursiveFields := ← recursiveFields value.induct value.numParams value.numFields
         (if eraseAutoParams then standardEraseAutoParam value.type else value.type) }
  | .recInfo value =>
    unless value.all.length == 1 && value.numMotives == 1 do
      throw "mutual recursor is outside Standard asset policy"
    return .recursorDecl {
      name, levelParams := levels, type, inductiveNames := value.all.map exportName,
      numParams := value.numParams, numIndices := value.numIndices,
      numMotives := value.numMotives, numMinors := value.numMinors }
  | .axiomInfo _ =>
    if allowedAssumptions.contains info.name then return .axiomDecl name levels type
    else throw "unapproved imported assumption in Standard asset"
  | .quotInfo value =>
    let kind := match value.kind with
      | .type => PsQuotientKind.type | .ctor => .ctor
      | .lift => .lift | .ind => .ind
    unless psNameEq name (psQuotientKindName kind) do
      throw "invalid native quotient identity"
    return .quotientDecl name levels type kind

private def sourceStatus (native : Lean.Environment) (name : Lean.Name) : String :=
  match Lean.getReducibilityStatusCore native name with
  | .reducible => ".reducible"
  | .semireducible => ".semireducible"
  | .irreducible => ".irreducible"
  | .instanceReducible => ".instanceReducible"
  | .implicitReducible => ".implicitReducible"

-- Always check the converted portable candidate, not just the original native
-- entries. No axiom replacement for failed proofs, no unchecked addDecl path.
private def checkCandidate (declarations candidates : List PsDeclaration) : IO Unit := do
  let empty := (← Lean.mkEmptyEnvironment 0).toKernelEnv
  -- Authoring diagnostics collect independent root failures in one pass.
  -- Each independent admission owns the unchanged kernel budget, as source
  -- admission does. Previous declarations must not consume this one's fuel.
  -- A rejected declaration is never inserted; its dependents stay blocked.
  -- This temporary environment is discarded on any error and cannot publish.
  let mut checked := empty
  let mut pending := declarations.reverse
  let mut failures : List String := []
  let mut progress := true
  while progress && !pending.isEmpty do
    progress := false
    let mut deferred := []
    for declaration in pending do
      let attempt ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
        PsKernelLean.tryPreludeDeclaration declarations checked declaration
      match attempt with
      | .ok (.admitted next) => checked := next; progress := true
      | .ok .deferred => deferred := declaration :: deferred
      | .error error => failures := error.message :: failures; progress := true
    pending := deferred.reverse
  unless failures.isEmpty && pending.isEmpty do
    IO.println (Lean.Json.mkObj [
      ("schema", Lean.toJson ("pscv0-standard-replay-failures/1" : String)),
      ("failures", Lean.toJson failures.reverse),
      ("blocked", Lean.toJson (pending.map (fun d => psNameToString (psDeclarationName d))))]).compress
    throw (IO.userError "native Standard replay refused; see complete root-failure inventory")
  -- Constructors and recursors are generated by the kernel; check that the
  -- supplied portable signatures agree with what was actually generated.
  for declaration in candidates do
    match declaration with
    | .constructorDecl _ | .recursorDecl _ | .quotientDecl .. =>
      let name := PsKernelLean.toLeanName (psDeclarationName declaration)
      let some info := checked.find? name
        | throw (IO.userError ("missing regenerated metadata: " ++ toString name))
      let .ok type := PsKernelLean.toLeanExpr (psDeclarationType declaration)
        | throw (IO.userError "metadata type conversion failed")
      unless info.type == type do
        throw (IO.userError ("regenerated metadata signature differs: " ++ toString name))
    | _ => pure ()

-- Differentially compare each exported one-step iota rule against the actual
-- pinned kernel-generated rule. Symbolic typed locals keep this independent of
-- concrete examples and cover every recursive field telescope in the asset.
private def checkRecursorRules (native : Lean.Environment)
    (declarations candidates : List PsDeclaration)
    (eraseAutoParams : Bool := false) : IO Nat := do
  let environment := declarations.foldl psEnvironmentInsert psEnvironmentEmpty
  let mut count := 0
  for declaration in candidates do
    let .recursorDecl info := declaration | continue
    let some (.recInfo original) := native.find? (PsKernelLean.toLeanName info.name)
      | throw (IO.userError "missing native recursor rule reference")
    for rule in original.rules do
      let some constructor := psEnvironmentFindConstructor environment (exportName rule.ctor)
        | throw (IO.userError "missing exported rule constructor")
      let mut expected ← match exportCoreExpr eraseAutoParams rule.rhs with
        | .ok expr => pure expr
        | .error error => throw (IO.userError error)
      let fixedCount := info.numParams + info.numMotives + info.numMinors
      let mut locals := psLocalEmpty
      let mut arguments : List PsExpr := []
      for _ in [:fixedCount + rule.nfields] do
        let .lam name domain body binder := expected
          | throw (IO.userError "native rule lambda telescope mismatch")
        let pushed := psLocalPushBinding locals name domain binder
        locals := pushed.context
        let value := PsExpr.fvar pushed.id
        arguments := arguments ++ [value]
        expected := psExprInstantiate1 body value
      let reduce := psWhnf environment psMetaEmpty locals
      let ctorArguments := arguments.take info.numParams ++ arguments.drop fixedCount
      let some resultType := psReduceApplyType reduce constructor.type ctorArguments
        | throw (IO.userError "cannot instantiate exported constructor result")
      let indices := (psReduceAppView resultType).args.drop info.numParams
      unless indices.length == info.numIndices do
        throw (IO.userError "exported recursor index count differs")
      let major := psReduceApply
        (.constE constructor.name (constructor.levelParams.map PsLevel.param)) ctorArguments
      let redex := psReduceApply (.constE info.name (info.levelParams.map PsLevel.param))
        (arguments.take fixedCount ++ indices ++ [major])
      let some actual := psReduceIota reduce environment redex
        | throw (IO.userError ("portable iota stuck: " ++ toString original.name))
      unless psExprAlphaEq actual expected do
        throw (IO.userError ("portable/native iota rule differs: " ++ toString rule.ctor))
      count := count + 1
  return count

-- Validate the kernel mechanism independently of any additional assumptions.
-- The temporary environment contains only the existing checked prelude plus
-- four kernel-generated descriptors. It is discarded, never used by compiling.
def checkQuotientFoundation : IO Unit := do
  Lean.initSearchPath (← Lean.findSysroot)
  let native ← Lean.importModules #[{ module := `Init }] {}
  let candidates ← [`Quot, `Quot.mk, `Quot.lift, `Quot.ind].mapM fun name => do
    let some info := native.find? name | throw (IO.userError "missing native quotient primitive")
    match exportDeclaration native [] info with
    | .ok value => pure value
    | .error reason => throw (IO.userError reason)
  let base := psSelfHostProdHashPreludeEnvironment.declarations
  let declarations := candidates ++ base
  checkCandidate declarations candidates
  let environment := declarations.foldl psEnvironmentInsert psEnvironmentEmpty
  let level := PsLevel.succ .zero
  let nat := PsExpr.constE psNatName []
  let prop := PsExpr.constE (psRootName "True") []
  let intro := PsExpr.constE (psDecisionName "True.intro") []
  let eq := fun type a b => psReduceApply (.constE (psRootName "Eq") [level]) [type, a, b]
  let refl := fun type value => psReduceApply (.constE (psDecisionName "Eq.refl") [level]) [type, value]
  let relation := PsExpr.app (.constE (psRootName "Eq") [level]) nat
  let quotient := psReduceApply (.constE (psRootName "Quot") [level]) [nat, relation]
  let major := psReduceApply (.constE (psDecisionName "Quot.mk") [level])
    [nat, relation, .lit (.natural 41)]
  let identity := PsExpr.lam (psRootName "n") nat (.bvar 0) .explicit
  let functionType := PsExpr.forallE (psRootName "n") nat nat .explicit
  let function := PsExpr.lam (psRootName "a") nat identity .explicit
  let respects := PsExpr.lam (psRootName "a") nat
    (.lam (psRootName "b") nat
      (.lam (psRootName "h") (eq nat (.bvar 1) (.bvar 0))
        (refl functionType identity) .explicit) .explicit) .explicit
  let lift := psReduceApply (.constE (psDecisionName "Quot.lift") [level, level])
    [nat, relation, functionType, function, respects, major, .lit (.natural 7)]
  let ind := psReduceApply (.constE (psDecisionName "Quot.ind") [level])
    [nat, relation, .lam (psRootName "q") quotient prop .explicit,
      .lam (psRootName "a") nat intro .explicit, major]
  let reduce := psWhnf environment psMetaEmpty psLocalEmpty
  unless psExprAlphaEq (reduce lift) (.lit (.natural 7)) &&
      psExprAlphaEq (reduce ind) intro do
    throw (IO.userError "portable quotient computation differs from kernel rules")
  let probes := [
    PsDeclaration.theoremDecl (psRootName "_psQuotientLiftProbe") []
      (eq nat lift (.lit (.natural 7))) (refl nat (.lit (.natural 7))),
    PsDeclaration.theoremDecl (psRootName "_psQuotientIndProbe") [] prop ind]
  -- The official kernel independently validates both computations.
  checkCandidate (probes ++ declarations) probes
  unless (psReduceQuotientIota (fun value => value)
      psSelfHostProdHashPreludeEnvironment lift).isNone do
    throw (IO.userError "unregistered quotient spelling activated reduction")
  let empty := (← Lean.mkEmptyEnvironment 0).toKernelEnv
  let .ok checked := PsKernelLean.replayPreludeDeclarations base base.reverse empty
    | throw (IO.userError "quotient test prelude failed")
  -- Replaying supplied descriptors must validate an already generated group
  -- without publishing the same names to Lean's AsyncConsts again.
  let .ok registered := PsKernelLean.replayPreludeDeclarations declarations
      (candidates ++ candidates.reverse) checked
    | throw (IO.userError "repeated quotient descriptor validation failed")
  let wrong := PsDeclaration.quotientDecl (psDecisionName "Quot.lift") [] nat .lift
  let existingSignature ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
    PsKernelLean.tryPreludeDeclaration declarations registered wrong
  if existingSignature.isOk then
    throw (IO.userError "forged existing quotient signature accepted")
  let newSignature ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
    PsKernelLean.tryPreludeDeclaration declarations checked wrong
  if newSignature.isOk then
    throw (IO.userError "forged quotient signature accepted")
  -- Mirror pinned kernelQuotNameCollision in an isolated discarded environment.
  let collisionResult ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
    checked.addDeclCore 2000000 20000
      (.axiomDecl { name := `Quot.lift, levelParams := [], type := .const `False [], isUnsafe := false }) none
  let .ok collision := collisionResult
    | throw (IO.userError "cannot construct isolated quotient collision probe")
  let some candidate := candidates.head?
    | throw (IO.userError "quotient candidate group is empty")
  let collisionCandidate ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
    PsKernelLean.tryPreludeDeclaration declarations collision candidate
  if collisionCandidate.isOk then
    throw (IO.userError "provider accepted a quotient name collision")
  let registration ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
    collision.addDeclCore 2000000 20000 .quotDecl none
  if registration.isOk then
    throw (IO.userError "kernel quotient registration overwrote an existing name")
  IO.println "PSCV0_QUOTIENT_FOUNDATION: PASS kernel regeneration, lift/ind computation, signature/collision refusal; no added assumptions"

structure StandardExportSpec where
  roots : List Lean.Name
  boundary : List PsName
  baseDeclarations : List PsDeclaration
  publicPrefix : String
  privatePrefix : String
  provenance : String
  allowedAssumptions : List Lean.Name := []
  -- Candidate authoring may replace reached legacy assumptions with their
  -- actual native definitions. Frozen assets record the resulting exact cut.
  replaceDefinitionAxioms : Bool := false
  -- F0: replacing a legacy primitive type *axiom* by its pinned Lean
  -- structure is an explicit, independently checked identity migration.
  -- Do not apply to ordinary type names or unchecked/custom structures.
  replaceInductiveAxioms : List Lean.Name := []
  -- Export Core by removing only fully applied *elaboration tactic* annotations.
  -- The pinned official kernel checks each changed signature in its native
  -- environment; exported declarations are also re-admitted independently.
  eraseAutoParams : Bool := false
  shareSource : Bool := false
  -- Host-only, opt-in. All established pinned assets continue importing Init.
  nativeModules : Array Lean.Import := #[{ module := `Init }]
  -- Source theorem → original theorem name; native type equality and portable
  -- proof replay are compulsory. Never replace computational definitions.
  checkedTheoremRenames : List (Lean.Name × Lean.Name) := []

-- Every changed *native signature* must be definitionally equivalent to the
-- original in the OFFICIAL pinned kernel. A fresh checked alias proves the
-- native constant can inhabit the annotation-free type; the returned
-- environment is discarded, and the alias is never exported. This is not
-- unchecked insertion, axiom admission or string-based dependency exclusion.
private def checkAutoParamSignature (native : Lean.Environment)
    (info : Lean.ConstantInfo) : IO Unit := do
  let normalized := standardEraseAutoParam info.type
  if normalized != info.type then
    let witness : Lean.Declaration := .defnDecl {
      name := `_pscv0AutoParamDefeqWitness
      levelParams := info.levelParams
      type := normalized
      value := .const info.name (info.levelParams.map Lean.Level.param)
      hints := .opaque
      safety := .safe
    }
    let attempt ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
      native.checked.get.addDeclCore 2000000 20000 witness none
    match attempt with
    | .ok _ => pure ()
    | .error error =>
      throw (IO.userError (toString info.name ++
        ": official native kernel refused autoParam definitional equivalence: " ++
        PsKernelLean.kernelExceptionSummary error))
  -- Do not silently rewrite proof terms or executable definitions: doing so
  -- would require a separate kernel-checked value-convertibility certificate.
  if let some value := info.value? true then
    if standardEraseAutoParam value != value then
      throw (IO.userError (toString info.name ++
        ": autoParam in a declaration body requires independent value-equivalence proof"))


-- A dedicated negative conformance gate: the boundary is definitional
-- equivalence, NOT a textual rewrite license. If Lean changes the generated
-- constructor's annotations, this probe refuses silently altered semantics.
private def checkFloatAnnotationPolicy (native : Lean.Environment) : IO Unit := do
  let some constructor := native.find? `Float.Model.Format.mk
    | throw (IO.userError "pinned Float format constructor is missing")
  let before := constructor.type
  let after := standardEraseAutoParam before
  unless after != before do
    throw (IO.userError "expected pinned Format.mk autoParam signature change is absent")
  if after.getUsedConstants.contains `autoParam ||
      after.getUsedConstants.contains `Lean.Syntax then
    throw (IO.userError "elaboration-only annotation escaped F0 normalization")
  let syntaxExpr := Lean.Expr.const `Lean.Syntax []
  unless standardEraseAutoParam syntaxExpr == syntaxExpr do
    throw (IO.userError "ordinary Lean.Syntax dependency was silently excluded")
  let partialAnnotation := Lean.Expr.app (.const `autoParam [.zero]) (.const `Nat [])
  unless standardEraseAutoParam partialAnnotation == partialAnnotation do
    throw (IO.userError "partially applied autoParam was unsoundly normalized")
  let optional := Lean.Expr.app
    (Lean.Expr.app (.const `optParam [.zero]) (.const `Nat [])) (.lit (.natVal 0))
  unless standardEraseAutoParam optional == optional do
    throw (IO.userError "optParam semantics were silently changed")
  let bogus : Lean.Declaration := .defnDecl {
    name := `_pscv0FloatFormatForgedSignature
    levelParams := constructor.levelParams
    type := .const `Nat []
    value := .const constructor.name (constructor.levelParams.map Lean.Level.param)
    hints := .opaque
    safety := .safe
  }
  let attempt ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
    native.checked.get.addDeclCore 2000000 20000 bogus none
  if attempt.isOk then
    throw (IO.userError "official Lean kernel accepted a forged Format.mk signature")
  IO.println "PSCV0_FLOAT_ANNOTATION_POLICY: PASS true annotation removal, ordinary Syntax and optParam preservation, partial-application preservation, and official kernel forged-type refusal"

-- One conversion, admission and source-rendering pipeline for reviewed library
-- slices. Profiles choose roots and a boundary; they cannot bypass checking.
private def exportStandardCore (spec : StandardExportSpec)
    (output : System.FilePath) : IO Unit := do
  Lean.initSearchPath (← Lean.findSysroot)
  let native ← Lean.importModules spec.nativeModules {}
  unless Lean.githash == "eb6cafb7290e8bd5f2937522d8d804f58f02bafc" do
    throw (IO.userError "Standard export requires the pinned Lean 4.35.0 commit")
  if spec.eraseAutoParams then checkFloatAnnotationPolicy native
  let originalBoundary := spec.boundary.foldl
    (fun (names : Lean.NameSet) name => names.insert (PsKernelLean.toLeanName name)) {}
  let originalBase := spec.baseDeclarations.filter
    (fun d => originalBoundary.contains (PsKernelLean.toLeanName (psDeclarationName d)))
  unless originalBase.length == spec.boundary.length do
    throw (IO.userError "frozen Standard export boundary has missing or duplicate declarations")
  -- A portable axiom cannot cut a native definition whose computation a proof
  -- uses. Follow these definitions in the same closure traversal, then replace
  -- only the reached declarations. Unrelated primitives stay in the base.
  let boundary := originalBase.foldl (fun (names : Lean.NameSet) declaration =>
    let name := PsKernelLean.toLeanName (psDeclarationName declaration)
    let replace := match declaration, native.find? name with
      | .axiomDecl .., some (.defnInfo _) => spec.replaceDefinitionAxioms
      | .axiomDecl .., some (.thmInfo _) => spec.replaceDefinitionAxioms
      | .axiomDecl .., some (.inductInfo _) => spec.replaceInductiveAxioms.contains name
      | _, _ => false
    if replace then names else names.insert name) {}
  -- A replacement theorem closes the dependency graph *at the original
  -- theorem name* while the independently checked constructive proof enters
  -- as a separately listed root. Without this cut the collector would still
  -- descend into the upstream proof body and reintroduce Classical.choice.
  -- This cannot hide a selected Standard declaration or another root.
  let cutNames := spec.checkedTheoremRenames.map (·.snd)
  if cutNames.any (fun name => originalBoundary.contains name ||
      spec.roots.contains name) then
    throw (IO.userError "theorem-only cut collides with selected Standard or root")
  let boundary := cutNames.foldl (fun (names : Lean.NameSet) name =>
    names.insert name) boundary
  let mut seen : Lean.NameSet := {}
  let mut entries : Array Lean.ConstantInfo := #[]
  for root in spec.roots do
    if boundary.contains root then
      throw (IO.userError ("export root was incorrectly cut at boundary: " ++ toString root))
    for info in ← standardDependencyClosure native root boundary spec.eraseAutoParams do
      if !boundary.contains info.name && !seen.contains info.name then
        seen := seen.insert info.name
        entries := entries.push info
  entries := entries.qsort (fun a b => Lean.Name.lt a.name b.name)
  let base := originalBase.filter
    (fun d => !seen.contains (PsKernelLean.toLeanName (psDeclarationName d)))
  let replaced := originalBase.filter
    (fun d => seen.contains (PsKernelLean.toLeanName (psDeclarationName d)))
  IO.println (Lean.Json.mkObj [
    ("schema", Lean.toJson ("pscv0-standard-candidate-policy/1" : String)),
    ("declarations", Lean.toJson entries.size),
    ("replacedDefinitionAxioms", Lean.toJson (replaced.map (fun d => psNameToString (psDeclarationName d)))),
    ("axioms", Lean.toJson ((entries.filter Lean.ConstantInfo.isAxiom).map (fun info => toString info.name))),
    ("quotientPrimitives", Lean.toJson (entries.filterMap fun info =>
      match info with | .quotInfo _ => some (toString info.name) | _ => none))]).compress
  if (spec.checkedTheoremRenames.map (·.snd)).eraseDups.length !=
      spec.checkedTheoremRenames.length ||
      (spec.checkedTheoremRenames.map (·.fst)).eraseDups.length !=
        spec.checkedTheoremRenames.length ||
      !spec.checkedTheoremRenames.all (fun pair => spec.roots.contains pair.fst) then
    throw (IO.userError "theorem-only proof substitutions are duplicate or unrooted")
  let declarations ← entries.toList.mapM fun info => do
    if spec.eraseAutoParams then checkAutoParamSignature native info
    let exported ← match exportDeclaration native spec.allowedAssumptions info spec.eraseAutoParams with
      | .ok value => pure value
      | .error reason =>
        let path := standardDependencyPath native spec.roots info.name boundary spec.eraseAutoParams
        throw (IO.userError
          (toString info.name ++ ": " ++ reason ++
            " | upstream dependency path: " ++
            String.intercalate " -> " (path.map toString)))
    match spec.checkedTheoremRenames.find? (fun pair => pair.fst == info.name) with
    | none => pure exported
    | some (_, target) => do
      if originalBoundary.contains target || seen.contains target then
        throw (IO.userError "theorem-only proof cut would collide with active Standard")
      let some (.thmInfo upstream) := native.find? target
        | throw (IO.userError ("proof-cut destination not an upstream theorem: " ++
            toString target))
      let .thmInfo _ := info
        | throw (IO.userError "proof-cut source is not an upstream theorem")
      let witness : Lean.Declaration := .defnDecl {
        name := `_pscv0ConstructiveTheoremTypeWitness
        levelParams := info.levelParams
        type := upstream.type
        value := .const info.name (info.levelParams.map Lean.Level.param)
        hints := .opaque
        safety := .safe }
      let attempt ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
        native.checked.get.addDeclCore 2000000 20000 witness none
      match attempt with
      | .error error =>
        throw (IO.userError ("official kernel refused proof-cut type: " ++
          PsKernelLean.kernelExceptionSummary error))
      | .ok _ => pure ()
      match exported with
      | .theoremDecl _ levels type value =>
        pure (.theoremDecl (exportName target) levels type value)
      | _ => throw (IO.userError "proof cut changed theorem declaration kind")
  -- The cut names are frozen, but current implementations of cut declarations
  -- may acquire new checked helper dependencies. Replay the complete declared
  -- pre-admission stage, excluding every replacement. Keep its extra helpers
  -- out of the frozen cut so earlier assets still regenerate byte-for-byte.
  let replayBase := spec.baseDeclarations.filter
    (fun d => !seen.contains (PsKernelLean.toLeanName (psDeclarationName d)))
  checkCandidate (declarations ++ replayBase) declarations
  let recursorRules ← checkRecursorRules native (declarations ++ replayBase) declarations spec.eraseAutoParams
  let boundaryNames := (base.map psDeclarationName).mergeSort
    (fun a b => Lean.Name.lt (PsKernelLean.toLeanName a) (PsKernelLean.toLeanName b))
  let mut pool : StandardSource.Pool := {
    enabled := spec.shareSource, namePrefix := spec.privatePrefix ++ "Node" }
  let mut definitions := []
  let mut identifiers := []
  let mut statuses := []
  for (declaration, index) in declarations.zipIdx do
    let identifier := spec.privatePrefix ++ toString index
    let (body, nextPool) := (StandardSource.renderDeclaration declaration).run pool
    pool := nextPool
    definitions := ("-- " ++ psNameToString (psDeclarationName declaration) ++
      "\nprivate def " ++ identifier ++ " : PsDeclaration :=\n  " ++ body ++ "\n") :: definitions
    identifiers := identifier :: identifiers
    if (psDeclarationValue declaration).isSome then
      let name := psDeclarationName declaration
      statuses := ("(" ++ sourceName name ++ ", " ++ sourceStatus native (PsKernelLean.toLeanName name) ++ ")") :: statuses
  let header := spec.provenance ++ (if spec.allowedAssumptions.isEmpty then "" else
    "-- Explicitly approved pinned Lean assumptions: " ++
      String.intercalate ", " (spec.allowedAssumptions.map toString) ++ ".\n\n")
  let shared := String.join pool.definitions.toList
  let source := header ++ (if shared.isEmpty then "" else shared ++ "\n") ++ "def " ++ spec.publicPrefix ++ "Boundary : List PsName :=\n  " ++
    sourceList (boundaryNames.map sourceName) ++ "\n\n" ++ String.intercalate "\n" definitions.reverse ++
    "\ndef " ++ spec.publicPrefix ++ "Declarations : List PsDeclaration :=\n  " ++ sourceList identifiers.reverse ++
    "\n\ndef " ++ spec.publicPrefix ++ "Reducibility : List (PsName × PsReducibility) :=\n  " ++
    sourceList statuses.reverse ++ "\n"
  IO.FS.writeFile output source
  IO.println (Lean.Json.mkObj [
    ("schema", Lean.toJson ("pscv0-standard-core-export/1" : String)),
    ("roots", Lean.toJson (spec.roots.map toString)), ("declarations", Lean.toJson declarations.length),
    ("sourceBytes", Lean.toJson source.utf8ByteSize),
    ("sharedSourceNodes", Lean.toJson pool.definitions.size),
    ("kernelChecked", Lean.toJson true), ("recursorRulesCompared", Lean.toJson recursorRules),
    ("importedAssumptions", Lean.toJson (spec.allowedAssumptions.map toString)),
    ("leanCommit", Lean.toJson Lean.githash)]).compress
  -- Review transport uses bounded, JSON-escaped lines; the file is also uploaded
  -- as an Actions artifact. This does not introduce a runtime wire format.
  let mut chunk := ""
  let mut count := 0
  for char in source.toList do
    chunk := chunk.push char
    count := count + 1
    if count == 2048 then
      IO.println ("PSCV0_STANDARD_SOURCE " ++ (Lean.toJson chunk).compress)
      chunk := ""
      count := 0
  unless chunk.isEmpty do
    IO.println ("PSCV0_STANDARD_SOURCE " ++ (Lean.toJson chunk).compress)

-- The original frozen boundary is used even after Standard grows.
def exportScalarArithmetic (output : System.FilePath) : IO Unit :=
  exportStandardCore {
    roots := [`Nat.mod_lt]
    boundary := psStandardScalarArithmeticBoundary
    baseDeclarations := psSelfHostProdCorePreludeEnvironment.declarations
    publicPrefix := "psStandardScalarArithmetic"
    privatePrefix := "scalarArithmeticDecl"
    provenance := "/-\nCopyright (c) 2020 Microsoft Corporation. All rights reserved.\nReleased under Apache 2.0 license; see THIRD_PARTY_NOTICES.md.\nUpstream Init/Prelude.lean authors: Leonardo de Moura, Mario Carneiro.\nGenerated by Ps.Host.StandardExport from Lean 4.35.0\neb6cafb7290e8bd5f2937522d8d804f58f02bafc. Modified: closed Core\nconversion removes metadata only; dependency cut is recorded below.\nLogical library data, not a native elaborator import or runtime implementation.\n-/\nimport Ps.Environment.Basic\n\nset_option maxRecDepth 20000\n\n" } output

-- Reviewed logical UInt/BitVec construction and conversions.
-- Regenerate against the original frozen boundary after admission.
-- Native typeclass registrations and runtime intrinsic selection are separate.
def exportUnsignedFoundation (output : System.FilePath) : IO Unit :=
  let owners := ["UInt8", "UInt16", "UInt32", "UInt64"]
  let roots := [`BitVec.ofNat, `BitVec.toNat, `BitVec.toFin, `BitVec.ofNatLT] ++
    owners.flatMap (fun owner =>
      ["ofNat", "ofNatLT", "toNat", "toFin", "toBitVec", "size", "instOfNat"].map
        (fun method => Lean.Name.str (Lean.Name.str .anonymous owner) method))
  let boundary := psStandardUnsignedFoundationBoundary
  exportStandardCore {
    roots, boundary
    baseDeclarations := psSelfHostProdScalarPreludeEnvironment.declarations
    publicPrefix := "psStandardUnsignedFoundation"
    privatePrefix := "unsignedFoundationDecl"
    provenance := "/-\nCopyright (c) 2018, 2020 Microsoft Corporation. All rights reserved.\nReleased under Apache 2.0 license; see THIRD_PARTY_NOTICES.md.\nUpstream Init/Prelude.lean and Init/Data/UInt/BasicAux.lean;\nauthors Leonardo de Moura and Mario Carneiro.\nGenerated by Ps.Host.StandardExport from Lean 4.35.0\neb6cafb7290e8bd5f2937522d8d804f58f02bafc. Modified: closed Core\nconversion removes metadata only; dependency cut is recorded below.\nLogical library data, not a native elaborator import or runtime implementation.\n-/\nimport Ps.Environment.Basic\n\nset_option maxRecDepth 20000\n\n" } output

-- Candidate: the native opaque hashing boundary and universe-correct class.
-- Runtime hash algorithms are audited and qualified independently.
def exportHashFoundation (output : System.FilePath) : IO Unit :=
  exportStandardCore {
    roots := [`Hashable.hash, `mixHash, `String.hash]
    boundary := psStandardHashFoundationBoundary
    baseDeclarations := psSelfHostProdUnsignedPreludeEnvironment.declarations
    publicPrefix := "psStandardHashFoundation"
    privatePrefix := "hashFoundationDecl"
    provenance := "/-\nCopyright (c) 2020 Microsoft Corporation. All rights reserved.\nReleased under Apache 2.0 license; see THIRD_PARTY_NOTICES.md.\nUpstream Init/Prelude.lean authors: Leonardo de Moura, Mario Carneiro.\nGenerated by Ps.Host.StandardExport from Lean 4.35.0\neb6cafb7290e8bd5f2937522d8d804f58f02bafc. Modified: closed Core\nconversion removes metadata only; dependency cut is recorded below.\nOpaque runtime primitives remain opaque in the logical library.\n-/\nimport Ps.Environment.Basic\n\nset_option maxRecDepth 20000\n\n" } output

-- Reviewed unsigned arithmetic/bitwise/shift proof slice. Its frozen cut and
-- pre-admission stage are independent of later Standard expansion. Native
-- replay, symbolic iota comparison and exact source regeneration remain gates.
def exportUnsignedOperationsCandidate (output : System.FilePath) : IO Unit :=
  let owners := ["UInt8", "UInt16", "UInt32", "UInt64"]
  let methods := ["add", "sub", "mul", "div", "mod", "neg", "complement",
    "land", "lor", "xor", "shiftLeft", "shiftRight"]
  let roots := [`Nat.div] ++ owners.flatMap (fun owner =>
    methods.map (fun method => Lean.Name.str (Lean.Name.str .anonymous owner) method))
  let declarations := psSelfHostProdHashPreludeEnvironment.declarations
  let boundary := psStandardUnsignedOperationsBoundary
  exportStandardCore {
    roots, boundary, baseDeclarations := declarations
    shareSource := true
    allowedAssumptions := [`propext, `Quot.sound]
    publicPrefix := "psStandardUnsignedOperations"
    privatePrefix := "unsignedOperationDecl"
    provenance := "/-\nCopyright (c) 2016, 2018 Microsoft Corporation; 2024 Lean FRO, LLC.\nReleased under Apache 2.0 license; see THIRD_PARTY_NOTICES.md.\nUpstream Init/Prelude, Init/Data/UInt, BitVec and Nat dependency closure.\nGenerated by Ps.Host.StandardExport from Lean 4.35.0\neb6cafb7290e8bd5f2937522d8d804f58f02bafc. Modified: closed Core\nconversion removes metadata only; dependency cut is recorded below.\nLogical library data, not a native elaborator import or runtime implementation.\n-/\nimport Ps.Environment.Basic\n\nset_option maxRecDepth 20000\n\n" } output

-- F0 checked identity candidate, not a published source Float feature.
-- Original boundary is the entire /61 selected Standard. Exactly the legacy
-- Float and Float32 axioms are replaced with the true pinned inductive
-- structures; every newly reachable constructor, recursor, theorem and model
-- dependency must pass the original kernel replay and signature audits.
-- This deliberately omits ofBits/BEq/scientific: the read-only upstream
-- closure shows those require an unapproved Classical.choice dependency.
-- No proof replacement, unsafe insertion, or expanded assumption allowlist.
def exportFloatIdentityCandidate (output : System.FilePath) : IO Unit := do
  let existing := psSelfHostProdPreFloatPreludeEnvironment.declarations
  exportStandardCore {
    roots := [`Float, `Float32]
    boundary := existing.map psDeclarationName
    baseDeclarations := existing
    allowedAssumptions := [`propext, `Quot.sound]
    replaceInductiveAxioms := [`Float, `Float32]
    eraseAutoParams := true
    shareSource := true
    publicPrefix := "psStandardFloatIdentity"
    privatePrefix := "floatIdentityDecl"
    provenance := "/-\nCopyright (c) 2016 Microsoft Corporation and 2024 Lean FRO, LLC.\nApache-2.0; see THIRD_PARTY_NOTICES.md.\nUpstream Init/Data/Float/{Float,Float32,Model/Float,Model/Float32}.lean.\nPinned Lean 4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc.\nModified: selected Core conversion, closure/cut and independent kernel audit.\nEXPERIMENTAL F0 LOGICAL CANDIDATE, NOT RUNTIME FLOAT SUPPORT.\n-/\nimport Ps.Environment.Basic\n\nset_option maxRecDepth 20000\n\n"
  } output

-- Reproducible pinned Int arithmetic asset. Keep the original boundary
-- separate from its selected output, and replay real native proof bodies.
-- Checked logical definitions and existing fast runtime intrinsics have
-- distinct responsibilities; neither is evidence for the other.
def exportIntArithmeticModelCandidate (output : System.FilePath) : IO Unit := do
  let base := psSelfHostProdPreIntArithmeticPreludeEnvironment.declarations
  if !base.any (fun d =>
      psNameToString (psDeclarationName d) == "Int.add") then
    throw (IO.userError "pinned Int.add is absent from selected Standard boundary")
  exportStandardCore {
    roots := [`Int.add, `Int.neg, `Int.sub, `Int.mul,
      `Int.add_zero, `Int.neg_neg, `Int.add_neg_eq_sub,
      `Int.natCast_add, `Int.natCast_mul]
    boundary := psStandardIntArithmeticModelBoundary ++
      [psIntAddName, psIntNegName, psIntSubName, psIntMulName]
    baseDeclarations := base
    allowedAssumptions := [`propext, `Quot.sound]
    replaceDefinitionAxioms := true
    eraseAutoParams := true
    shareSource := true
    publicPrefix := "psStandardIntArithmeticModel"
    privatePrefix := "intArithmeticModelDecl"
    provenance := "/-\nCopyright (c) 2016 Jeremy Avigad and Lean FRO, LLC contributors.\nApache-2.0; see THIRD_PARTY_NOTICES.md.\nPinned Lean 4.35.0 Init/Data/Int/Basic.lean: native checked Int arithmetic definitions and laws research only.\nNOT SELECTED, NOT EXECUTABLE.\n-/\nimport Ps.Environment.Basic\n\nset_option maxRecDepth 20000\n\n"
  } output

-- Research-only constructive theorem authoring cut. This never changes
-- the selected Standard, its strict fingerprints, or the Float runtime.
def exportFloatConstructivePowCandidate (output : System.FilePath) : IO Unit := do
  let base := psSelfHostProdPreludeEnvironment.declarations
  if base.any (fun d => psNameToString (psDeclarationName d) == "Nat.pow_eq_zero") then
    throw (IO.userError "proof-cut destination collides with selected Standard")
  exportStandardCore {
    roots := [`PsV7Native.FloatConstructive.powEqZero]
    boundary := base.map psDeclarationName
    baseDeclarations := base
    nativeModules := #[{ module := `Init }, { module := `Ps.Host.FloatConstructive }]
    checkedTheoremRenames := [(`PsV7Native.FloatConstructive.powEqZero, `Nat.pow_eq_zero)]
    allowedAssumptions := [`propext, `Quot.sound]
    shareSource := true
    publicPrefix := "psStandardFloatConstructivePow"
    privatePrefix := "floatConstructivePowDecl"
    provenance := "/-\nCopyright (c) 2026 Lean FRO, LLC and contributors.\nApache-2.0; see THIRD_PARTY_NOTICES.md.\nConstructive Nat.pow_eq_zero: proof-only, unselected F1 research.\nNative kernel type witness and portable proof replay required.\n-/\nimport Ps.Environment.Basic\n\nset_option maxRecDepth 20000\n\n"
  } output

-- F1 authoring candidate: exact pinned Float and Float32 bit constructors,
-- projections and classifications. A rejected dependency is a hard error,
-- NEVER an occasion to add Classical.choice or to turn proofs into axioms.
-- Existing /F0 Standard is the immutable input cut and is not mutated.
def exportFloatBitsCandidate (output : System.FilePath) : IO Unit := do
  let existing := psSelfHostProdPreFloatConstructorsPreludeEnvironment.declarations
  exportStandardCore {
    roots := [`Float.ofBits, `Float.toBits, `Float.isNaN, `Float.isFinite,
              `Float32.ofBits, `Float32.toBits, `Float32.isNaN, `Float32.isFinite]
    boundary := existing.map psDeclarationName
    baseDeclarations := existing
    allowedAssumptions := [`propext, `Quot.sound]
    eraseAutoParams := true
    shareSource := true
    publicPrefix := "psStandardFloatBits"
    privatePrefix := "floatBitsDecl"
    provenance := "/-\nCopyright (c) 2016 Microsoft Corporation and Lean FRO, LLC.\nApache-2.0; see THIRD_PARTY_NOTICES.md.\nPinned Float logical bits and classification at Lean 4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc.\nExperimental kernel-checked F1 candidate, not yet selected or runtime-qualified.\n-/\nimport Ps.Environment.Basic\n\nset_option maxRecDepth 20000\n\n"
  } output

-- Second-stage F1 research: close only the original pinned
-- Nat.pow_eq_zero *theorem* using the already-kernel-checked constructive
-- alternative, then attempt the entire checked ofBits/toBits/classification
-- dependency closure. This is not selected Standard or executable Float.
-- Never change the allowed assumption list to make a candidate pass.
def exportFloatBitsConstructiveCandidate (output : System.FilePath) : IO Unit := do
  let existing := psSelfHostProdPreFloatConstructorsPreludeEnvironment.declarations
  -- These two checked F1a projection declarations are already in the exact
  -- frozen Standard. Require their presence; do not duplicate source roots
  -- or pretend the candidate separately requalifies their definitions.
  let frozenNames := existing.map (fun d =>
    PsKernelLean.toLeanName (psDeclarationName d))
  unless frozenNames.contains `Float.toBits &&
      frozenNames.contains `Float32.toBits do
    throw (IO.userError "F1a checked toBits projection missing from frozen Standard")
  exportStandardCore {
    roots := [`Float.ofBits, `Float.isNaN, `Float.isFinite,
              `Float32.ofBits, `Float32.isNaN, `Float32.isFinite,
              `PsV7Native.FloatConstructive.powEqZero]
    boundary := existing.map psDeclarationName
    baseDeclarations := existing
    allowedAssumptions := [`propext, `Quot.sound]
    nativeModules := #[{ module := `Init }, { module := `Ps.Host.FloatConstructive }]
    checkedTheoremRenames :=
      [(`PsV7Native.FloatConstructive.powEqZero, `Nat.pow_eq_zero)]
    eraseAutoParams := true
    shareSource := true
    publicPrefix := "psStandardFloatBitsConstructive"
    privatePrefix := "floatBitsConstructiveDecl"
    provenance := "/-\nCopyright (c) 2016 Microsoft Corporation and Lean FRO, LLC.\nApache-2.0; see THIRD_PARTY_NOTICES.md.\nPinned Lean 4.35.0 Float model and verified constructive Nat.pow_eq_zero proof cut.\nKernel replay and approved propext/Quot.sound assumptions only.\nF1 research-only; not selected Standard or executable Float.\n-/\nimport Ps.Environment.Basic\n\nset_option maxRecDepth 20000\n\n"
  } output

-- Full constructive F1 representation audit. Replay all reached declarations
-- against the frozen pre-constructor Standard, independent of selected exports;
-- refuse any incompatible dependencies, unapproved axioms or opaque casts.
def exportFloatCanonicalModelCandidate (output : System.FilePath) : IO Unit := do
  let selected := psSelfHostProdPreFloatConstructorsPreludeEnvironment.declarations
  exportStandardCore {
    roots := FloatCanonical.contractRoots ++
      [`PsV7Native.FloatConstructive.getLsbDOfGe]
    boundary := selected.map psDeclarationName
    baseDeclarations := selected
    nativeModules := #[{ module := `Init }, { module := `Ps.Host.FloatCanonicalContracts },
      { module := `Ps.Host.FloatConstructive }]
    checkedTheoremRenames :=
      [(`PsV7Native.FloatConstructive.getLsbDOfGe, `BitVec.getLsbD_of_ge)]
    allowedAssumptions := [`propext, `Quot.sound]
    shareSource := true
    publicPrefix := "psStandardFloatCanonicalModel"
    privatePrefix := "floatCanonicalModelDecl"
    provenance := "/-\nCopyright (c) 2026 Lean FRO, LLC and contributors.\nApache-2.0; see THIRD_PARTY_NOTICES.md.\nNative kernel-checked Float canonical-model research, not executable Float.\n-/\nimport Ps.Environment.Basic\n\nset_option maxRecDepth 20000\n\n"
  } output

-- F1 constructors need their validity proof, not every representation theorem.
-- The larger contract roster remains independently checked by the audit entry.
-- Regenerate against the frozen pre-constructor stage, never its own exports.
def exportFloatConstructorsCandidate (output : System.FilePath) : IO Unit := do
  let selected := psSelfHostProdPreFloatConstructorsPreludeEnvironment.declarations
  exportStandardCore {
    roots := [`PsV7Native.FloatCanonical.fromBits64,
      `PsV7Native.FloatCanonical.fromBits32]
    boundary := psStandardFloatConstructorsBoundary
    baseDeclarations := selected
    nativeModules := #[{ module := `Init }, { module := `Ps.Host.FloatCanonical }]
    allowedAssumptions := [`propext, `Quot.sound]
    shareSource := true
    publicPrefix := "psStandardFloatConstructors"
    privatePrefix := "floatConstructorsDecl"
    provenance := "/-\nCopyright (c) 2026 Lean FRO, LLC and contributors.\nApache-2.0; see THIRD_PARTY_NOTICES.md.\nPinned Lean 4.35.0 compact Float constructors with checked Format.Valid evidence.\nIndependent constructor candidate; runtime enablement is separate.\n-/\nimport Ps.Environment.Basic\n\nset_option maxRecDepth 20000\n\n"
  } output

-- F2 dependency gate: genuine pinned arithmetic, IEEE comparisons and
-- classification, before enabling runtime operators. Reuse only the two
-- already checked constructive theorem proofs, and only outside the selected
-- cut. A new assumption or incompatible proof dependency remains a hard error.
def exportFloatOperationsCandidate (output : System.FilePath) : IO Unit := do
  let selected := psSelfHostProdPreFloatOperationsPreludeEnvironment.declarations
  let names := selected.map (fun d => PsKernelLean.toLeanName (psDeclarationName d))
  let owners := ["Float", "Float32"]
  let methods := ["add", "sub", "mul", "div", "neg", "abs", "beq", "lt", "le",
    "isNaN", "isInf", "isFinite", "nan", "inf"]
  let operations := owners.flatMap fun owner =>
    methods.map (fun method => Lean.Name.str (Lean.Name.str .anonymous owner) method)
  let cuts := [(`PsV7Native.FloatConstructive.powEqZero, `Nat.pow_eq_zero),
    (`PsV7Native.FloatConstructive.getLsbDOfGe, `BitVec.getLsbD_of_ge)]
  let cuts := cuts.filter (fun pair => !names.contains pair.snd)
  exportStandardCore {
    roots := operations ++ [`Float.decLt, `Float.decLe, `instDecidableEqFloat,
      `Float32.decLt, `Float32.decLe, `instDecidableEqFloat32] ++ cuts.map (·.fst)
    boundary := psStandardFloatOperationsBoundary
    baseDeclarations := selected
    nativeModules := #[{ module := `Init }, { module := `Ps.Host.FloatConstructive }]
    checkedTheoremRenames := cuts
    allowedAssumptions := [`propext, `Quot.sound]
    eraseAutoParams := true
    shareSource := true
    publicPrefix := "psStandardFloatOperations"
    privatePrefix := "floatOperationsDecl"
    provenance := "/-\nCopyright (c) 2016 Microsoft Corporation and 2026 Lean FRO, LLC.\nApache-2.0; see THIRD_PARTY_NOTICES.md.\nPinned Lean 4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc.\nInit/Data/Float/Model/Unpacked Operations and Round; authors include Julia M. Himmel.\nClosed Core conversion and existing checked constructive theorem cuts.\nF2 research candidate only: not selected Standard or executable arithmetic.\n-/\nimport Ps.Environment.Basic\n\nset_option maxRecDepth 20000\n\n"
  } output

-- F3 dependency gate: native scientific literals and fixed-width numeric
-- conversions are one logical family. Platform words and opaque cross-float
-- conversions have separate contracts and are deliberately not roots here.
def exportFloatConversionsCandidate (output : System.FilePath) : IO Unit := do
  let selected := psSelfHostProdPreFloatConversionsPreludeEnvironment.declarations
  let owners := ["Float", "Float32"]
  let words := ["UInt8", "UInt16", "UInt32", "UInt64", "Int8", "Int16", "Int32", "Int64"]
  let sourceMethods := owners.flatMap fun owner =>
    (["ofScientific", "ofNat", "ofInt"] ++ words.map ("to" ++ ·)).map
      (fun method => Lean.Name.str (Lean.Name.str .anonymous owner) method)
  let destinationMethods := (words ++ ["Nat", "Int"]).flatMap fun owner =>
    ["toFloat", "toFloat32"].map
      (fun method => Lean.Name.str (Lean.Name.str .anonymous owner) method)
  exportStandardCore {
    roots := sourceMethods ++ destinationMethods
    boundary := selected.map psDeclarationName
    baseDeclarations := selected
    allowedAssumptions := [`propext, `Quot.sound]
    eraseAutoParams := true
    shareSource := true
    publicPrefix := "psStandardFloatConversions"
    privatePrefix := "floatConversionsDecl"
    provenance := "/-\nCopyright (c) Microsoft Corporation and Lean FRO, LLC.\nApache-2.0; see THIRD_PARTY_NOTICES.md.\nPinned Lean 4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc.\nInit/Data/OfScientific, Float/Model/Unpacked/Operations/{OfNat,ToNat,OfScientific}, SInt/Float{,32}.\nAuthors include Julia M. Himmel and Henrik Boeving.\nF3 logical dependency candidate; runtime and source enablement remain separate gates.\n-/\nimport Ps.Environment.Basic\n\nset_option maxRecDepth 20000\n\n"
  } output

-- Pinned Lean 4.35.0 SInt/Basic: each signed type is a checked
-- wrapper around an unsigned two's-complement carrier. This is a
-- native-only authoring candidate, NOT executable signed arithmetic.
def exportSignedIdentityCandidate (output : System.FilePath) : IO Unit := do
  let existing := psSelfHostProdPreSignedPreludeEnvironment.declarations
  exportStandardCore {
    roots := [`Int8, `Int16, `Int32, `Int64, `ISize]
    boundary := existing.map psDeclarationName
    baseDeclarations := existing
    allowedAssumptions := [`propext, `Quot.sound]
    replaceInductiveAxioms := [`Int8, `Int16, `Int32, `Int64, `ISize]
    shareSource := true
    publicPrefix := "psStandardSignedIdentity"
    privatePrefix := "signedIdentityDecl"
    provenance := "/-\nCopyright (c) 2024 Lean FRO, LLC.\nApache-2.0; see THIRD_PARTY_NOTICES.md.\nPinned src/Init/Data/SInt/Basic.lean (Henrik Böving), Lean 4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc.\nExperimental checked signed wrappers, not runtime-qualified.\n-/\nimport Ps.Environment.Basic\n\nset_option maxRecDepth 20000\n\n"
  } output

-- F1a native logical read-only bit projections. The genuine pinned Lean
-- definitions use model-carrying structure projections. This does not
-- authorize construction, arithmetic or a Float runtime ABI.
def exportFloatToBitsCandidate (output : System.FilePath) : IO Unit := do
  let existing := psSelfHostProdPreM2AMethodPreludeEnvironment.declarations
  exportStandardCore {
    roots := [`Float.toBits, `Float32.toBits]
    boundary := existing.map psDeclarationName
    baseDeclarations := existing
    allowedAssumptions := [`propext, `Quot.sound]
    eraseAutoParams := true
    shareSource := true
    publicPrefix := "psStandardFloatToBits"
    privatePrefix := "floatToBitsDecl"
    provenance := "/-\nCopyright (c) Microsoft Corporation and Lean FRO, LLC.\nApache-2.0; see THIRD_PARTY_NOTICES.md.\nPinned Lean 4.35.0 Float/Float32.toBits, eb6cafb7290e8bd5f2937522d8d804f58f02bafc.\nNative-only checked F1 read projection candidate.\n-/\nimport Ps.Environment.Basic\n\nset_option maxRecDepth 20000\n\n"
  } output

-- Four portable signed widths share one checked 20-method logical family.
-- ISize's platform-dependent runtime representation is deliberately separate.
-- Methods and typeclass dictionaries do not become executable merely because
-- Lean's kernel checked their original logical Core definitions.
def exportSignedOperationsCandidate (output : System.FilePath) : IO Unit := do
  let owners := ["Int8", "Int16", "Int32", "Int64"]
  -- Faithful logical dependency cut: native Int.toInt/ofInt and signed
  -- shifts/comparisons reach Int lemma proofs whose source representations
  -- differ from the currently checked PSCV0 Int arithmetic model. These
  -- cannot be replayed by mere signature matching. Select whole pure BitVec
  -- operation families first; re-enable the other roots after aligning the
  -- underlying Int and proof dependencies, not via axiom substitution.
  let methods := ["ofNat", "toBitVec", "ofBitVec",
                  "add", "sub", "mul", "div", "mod", "neg", "complement",
                  "land", "lor", "xor"]
  let roots := owners.flatMap fun owner =>
    methods.map (fun method => Lean.Name.str (Lean.Name.str .anonymous owner) method)
  let existing := psSelfHostProdPreM2AMethodPreludeEnvironment.declarations
  exportStandardCore {
    roots, boundary := existing.map psDeclarationName
    baseDeclarations := existing
    allowedAssumptions := [`propext, `Quot.sound]
    shareSource := true
    publicPrefix := "psStandardSignedOperations"
    privatePrefix := "signedOperationsDecl"
    provenance := "/-\nCopyright (c) 2024 Lean FRO, LLC.\nApache-2.0; see THIRD_PARTY_NOTICES.md.\nPinned src/Init/Data/SInt/Basic.lean, Henrik Böving, Lean 4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc.\nNative-only checked signed operation candidate, not runtime-qualified.\n-/\nimport Ps.Environment.Basic\n\nset_option maxRecDepth 20000\n\n"
  } output

-- F4: native opaque signatures/inhabitants, display dictionaries and exact
-- cross-width contracts. Runtime implementations are qualified separately.
def exportFloatDisplayCandidate (output : System.FilePath) : IO Unit := do
  let selected := psSelfHostProdPreFloatDisplayPreludeEnvironment.declarations
  exportStandardCore {
    roots := [`Float.toString, `Float32.toString, `Float.repr, `Float32.repr,
      `instToStringFloat, `instToStringFloat32, `instReprFloat, `instReprFloat32,
      `instReprAtomFloat, `instReprAtomFloat32, `Float.toFloat32, `Float32.toFloat]
    boundary := selected.map psDeclarationName
    baseDeclarations := selected
    allowedAssumptions := [`propext, `Quot.sound]
    shareSource := true
    publicPrefix := "psStandardFloatDisplay"
    privatePrefix := "floatDisplayDecl"
    provenance := "/-\nCopyright (c) Microsoft Corporation and Lean FRO, LLC.\nApache-2.0; see THIRD_PARTY_NOTICES.md.\nPinned Lean 4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc.\nInit/Data/Float/Float{,32}.lean, Init/Data/Repr.lean and runtime/object.cpp.\nNative checked opaque inhabitants and display dictionaries; runtime parity is a separate gate.\n-/\nimport Ps.Environment.Basic\n\nset_option maxRecDepth 20000\n\n"
  } output

-- ISize/ofUSize/rec are already selected by StandardSignedIdentityData and
-- stay at the frozen boundary; do not duplicate their checked native family.
-- Target-word dependency review. Logical width stays abstract, including the
-- native opaque getNumBits inhabitant; selecting an executable 32/64 profile
-- is an erasure concern and must never change this checking environment.
def exportPlatformWordsCandidate (output : System.FilePath) : IO Unit := do
  let selected := psSelfHostProdPrePlatformWordsPreludeEnvironment.declarations
  exportStandardCore {
    roots := [`System.Platform.getNumBits,
      `System.Platform.numBits,
      `USize,
      `USize.ofNat,
      `USize.ofNatLT,
      `USize.ofNatClamp,
      `USize.ofInt,
      `USize.toNat,
      `USize.toFin,
      `USize.toBitVec,
      `USize.ofBitVec,
      `USize.size,
      `USize.decEq,
      `USize.decLt,
      `USize.decLe,
      `USize.lt,
      `USize.le,
      `USize.add,
      `USize.sub,
      `USize.mul,
      `USize.div,
      `USize.mod,
      `USize.pow,
      `USize.neg,
      `USize.complement,
      `USize.land,
      `USize.lor,
      `USize.xor,
      `USize.shiftLeft,
      `USize.shiftRight,
      `ISize.ofNat,
      `ISize.ofInt,
      `ISize.toInt,
      `ISize.toNatClampNeg,
      `ISize.ofIntClamp,
      `ISize.toBitVec,
      `ISize.ofBitVec,
      `ISize.toUSize,
      `ISize.size,
      `ISize.minValue,
      `ISize.maxValue,
      `ISize.decEq,
      `ISize.decLt,
      `ISize.decLe,
      `ISize.lt,
      `ISize.le,
      `ISize.add,
      `ISize.sub,
      `ISize.mul,
      `ISize.div,
      `ISize.mod,
      `ISize.pow,
      `ISize.neg,
      `ISize.complement,
      `ISize.abs,
      `ISize.land,
      `ISize.lor,
      `ISize.xor,
      `ISize.shiftLeft,
      `ISize.shiftRight,
      `USize.instOfNat,
      `ISize.instOfNat,
      `USize.ofFin,
      `Nat.toUSize,
      `Nat.toISize,
      `Int.toISize,
      `UInt8.toUSize,
      `USize.toUInt8,
      `UInt16.toUSize,
      `USize.toUInt16,
      `UInt32.toUSize,
      `USize.toUInt32,
      `UInt64.toUSize,
      `USize.toUInt64,
      `Int8.toISize,
      `ISize.toInt8,
      `Int16.toISize,
      `ISize.toInt16,
      `Int32.toISize,
      `ISize.toInt32,
      `Int64.toISize,
      `ISize.toInt64,
      `Float.toUSize,
      `USize.toFloat,
      `Float.toISize,
      `ISize.toFloat,
      `Float32.toUSize,
      `USize.toFloat32,
      `Float32.toISize,
      `ISize.toFloat32,
      `USize.toISize]
    boundary := selected.map psDeclarationName
    baseDeclarations := selected
    replaceInductiveAxioms := [`USize]
    allowedAssumptions := [`propext, `Quot.sound]
    eraseAutoParams := true
    shareSource := true
    publicPrefix := "psStandardPlatformWords"
    privatePrefix := "platformWordsDecl"
    provenance := "/-\nCopyright (c) Microsoft Corporation and Lean FRO, LLC.\nApache-2.0; see THIRD_PARTY_NOTICES.md.\nPinned Lean 4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc.\nInit/Prelude, UInt/Basic{,Aux}, SInt/Basic and SInt/Float{,32}.\nNative abstract-width Core; runtime target profiles require separate qualification.\n-/\nimport Ps.Environment.Basic\n\nset_option maxRecDepth 20000\n\n"
  } output

-- M3 authoring profile for the actual pinned relation dictionaries and
-- generic fixedpoint equation. The input is the complete frozen prior stage:
-- an already selected declaration remains an exact replay boundary, and every
-- missing root uses the existing checked closure/recursor/source pipeline.
-- This command does not publish declarations or enable executable recursion.
def exportWellFoundedCandidate (output : System.FilePath) : IO Unit := do
  let selected := psSelfHostProdPreWellFoundedPreludeEnvironment.declarations
  let candidates := [`WellFoundedRelation, `WellFounded.fix, `WellFounded.fix_eq,
    `invImage, `SizeOf, `SizeOf.sizeOf, `instSizeOfNat, `instSizeOfDefault,
    `sizeOfWFRel, `Nat.lt_wfRel, `Prod.instWellFoundedRelation,
    `Prod.Lex.left, `Prod.Lex.right, `emptyWf,
    `Nat.lt_succ_self, `Nat.succ_lt_succ, `Nat.lt_succ_of_le, `Nat.sub_le]
  let alreadySelected := fun (name : Lean.Name) =>
    selected.any (fun declaration => psNameEq (psDeclarationName declaration) (exportName name))
  let roots := candidates.filter (fun name => !alreadySelected name)
  IO.println (Lean.Json.mkObj [
    ("schema", Lean.toJson ("pscv0-well-founded-foundation-selection/1" : String)),
    ("alreadySelected", Lean.toJson ((candidates.filter alreadySelected).map toString)),
    ("missingRoots", Lean.toJson (roots.map toString))]).compress
  exportStandardCore {
    roots
    boundary := selected.map psDeclarationName
    baseDeclarations := selected
    allowedAssumptions := [`propext, `Quot.sound]
    shareSource := true
    publicPrefix := "psStandardWellFounded"
    privatePrefix := "wellFoundedDecl"
    provenance := "/-\nCopyright (c) Microsoft Corporation and Lean FRO, LLC.\nApache-2.0; see THIRD_PARTY_NOTICES.md.\nPinned Lean 4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc.\nInit/WF.lean, Init/SizeOf.lean and actual transitive dependency closure.\nGenerated by Ps.Host.StandardExport; closed Core conversion removes metadata only.\nLogical library data; runtime relation use requires separate typed qualification.\n-/\nimport Ps.Environment.Basic\n\nset_option maxRecDepth 20000\n\n"
  } output


-- Native-only authoring probe for the P1 logical order foundation.
-- This adds no declarations to the selected portable Standard. The emitted
-- candidate must survive the existing complete closure conversion, trust-zero
-- kernel replay and recursor-rule comparison before any source is written.
-- Monadic instances and executable P1 lowering remain separate work.
-- PSum has a standalone kernel closure: neither a growing Standard boundary
-- nor a logical assumption is needed to reify the mutual WF domain family.
def exportMutualWellFoundedCandidate (output : System.FilePath) : IO Unit := do
  exportStandardCore {
    roots := [`PSum, `PSum.inl, `PSum.inr, `PSum.rec, `PSum.casesOn]
    boundary := []
    baseDeclarations := []
    publicPrefix := "psStandardPSum"
    privatePrefix := "pSumDecl"
    provenance := "/-\nCopyright (c) 2014 Microsoft Corporation. All rights reserved.\nApache-2.0; see THIRD_PARTY_NOTICES.md. Author: Leonardo de Moura.\nPinned Lean 4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc.\nInit/Core.lean PSum and kernel-generated constructor/recursor declarations.\nGenerated by Ps.Host.StandardExport; metadata-only removal, no assumptions.\nStandalone checked Core asset; activation and compiler qualification are separate.\n-/\nimport Ps.Environment.Basic\n\n"
  } output

def exportPartialFixpointCandidate (output : System.FilePath) : IO Unit := do
  let selected := psSelfHostProdPrePartialFixpointPreludeEnvironment.declarations
  let candidates : List Lean.Name := [
    `Classical.ofNonempty,
    `Lean.Order.PartialOrder, `Lean.Order.CCPO, `Lean.Order.CCPO.csup,
    `Lean.Order.CCPO.toPartialOrder,
    `Lean.Order.monotone, `Lean.Order.fix, `Lean.Order.fix_eq,
    `Lean.Order.fix_induct,
    `Lean.Order.instOrderPi, `Lean.Order.instCCPOPi,
    `Lean.Order.FlatOrder, `Lean.Order.FlatOrder.instOrder,
    `Lean.Order.FlatOrder.instCCPO, `Lean.Order.instCCPOUnit,
    `Lean.Order.instPartialOrderOption, `Lean.Order.instCCPOOption,
    `Lean.Order.instCCPOPProd,
    `Lean.Order.monotone_const, `Lean.Order.monotone_id,
    `Lean.Order.monotone_compose, `Lean.Order.monotone_of_monotone_apply,
    `Lean.Order.monotone_apply, `Lean.Order.monotone_ite,
    `Lean.Order.monotone_dite, `Lean.Order.PProd.monotone_mk,
    `Lean.Order.PProd.monotone_fst, `Lean.Order.PProd.monotone_snd]
  let alreadySelected := fun (name : Lean.Name) =>
    selected.any (fun declaration => psNameEq (psDeclarationName declaration) (exportName name))
  let roots := candidates.filter (fun name => !alreadySelected name)
  IO.println (Lean.Json.mkObj [
    ("schema", Lean.toJson ("pscv0-partial-fixpoint-foundation-selection/1" : String)),
    ("leanCommit", Lean.toJson Lean.githash),
    ("alreadySelected", Lean.toJson ((candidates.filter alreadySelected).map toString)),
    ("missingRoots", Lean.toJson (roots.map toString)),
    ("runtimeQualified", Lean.toJson false)]).compress
  exportStandardCore {
    roots
    boundary := selected.map psDeclarationName
    baseDeclarations := selected
    allowedAssumptions := [`propext, `Quot.sound, `Classical.choice]
    shareSource := true
    nativeModules := #[{ module := `Init.Internal.Order.Basic }]
    publicPrefix := "psStandardPartialFixpointCandidate"
    privatePrefix := "partialFixpointCandidateDecl"
    provenance := "/-\nCopyright (c) Microsoft Corporation and Lean FRO, LLC.\nApache-2.0; see THIRD_PARTY_NOTICES.md.\nPinned Lean 4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc.\nInit/Internal/Order/Basic.lean and actual transitive dependency closure.\nGenerated by Ps.Host.StandardExport; closed Core conversion removes metadata only.\nCandidate logical library data; no portable selection, class/instance registration,\nsource partial_fixpoint elaboration or executable lowering is qualified here.\n-/\nimport Ps.Environment.Basic\n\nset_option maxRecDepth 20000\n\n"
  } output

-- Audit the proposed logical stage while the active compiler keeps its exact
-- qualified Standard. These are authoring observations, not self-updating pins.
-- The real imported asset is compared with the pinned native declarations and
-- replayed through the same trust-zero admission and recursor-rule owners.
def checkWellFoundedFoundation : IO Unit := do
  Lean.initSearchPath (← Lean.findSysroot)
  -- Class and instance metadata live in persistent environment extensions.
  -- A declaration-only import leaves those extensions at their initial state.
  unsafe Lean.enableInitializersExecution
  let native ← Lean.importModules #[{ module := `Init }] {} (loadExts := true)
  unless Lean.githash == "eb6cafb7290e8bd5f2937522d8d804f58f02bafc" do
    throw (IO.userError "WF foundation audit requires the pinned Lean commit")
  let base := psSelfHostProdPreWellFoundedPreludeEnvironment
  let candidates := psStandardWellFoundedDeclarations
  let names := candidates.map psDeclarationName
  unless candidates.length == 34 && (names.map psNameToString).eraseDups.length == 34 do
    throw (IO.userError "WF foundation declaration inventory differs")
  unless psStandardWellFoundedBoundary.length == base.declarations.length &&
      psStandardWellFoundedBoundary.all (psEnvironmentContains base) do
    throw (IO.userError "WF foundation frozen boundary differs")
  if names.any (psEnvironmentContains base) then
    throw (IO.userError "WF foundation authoring stage contains its own candidate")
  let activeNames := names.filter (psEnvironmentContains psSelfHostProdPreludeEnvironment)
  unless activeNames.isEmpty || activeNames.length == candidates.length do
    throw (IO.userError "WF foundation is only partially present in the active Standard")
  let proposed := psStandardWellFoundedExtend base
  unless proposed.declarations.length == base.declarations.length + candidates.length do
    throw (IO.userError "WF foundation extension replaced a prior declaration")
  for declaration in candidates do
    let name := psDeclarationName declaration
    match declaration with
    | .axiomDecl .. | .quotientDecl .. | .partialDecl .. =>
      throw (IO.userError ("WF foundation contains a prohibited declaration: " ++ psNameToString name))
    | _ => pure ()
    let some upstream := native.find? (PsKernelLean.toLeanName name)
      | throw (IO.userError ("WF foundation native reference missing: " ++ psNameToString name))
    let reference ← match exportDeclaration native [] upstream with
      | .ok reference => pure reference
      | .error message => throw (IO.userError message)
    unless psStandardSnapshotDeclaration declaration == psStandardSnapshotDeclaration reference do
      throw (IO.userError ("WF foundation stored Core differs from native: " ++ psNameToString name))
    let some selected := psEnvironmentFind proposed name
      | throw (IO.userError ("WF foundation declaration not selected: " ++ psNameToString name))
    unless psStandardSnapshotDeclaration selected == psStandardSnapshotDeclaration declaration do
      throw (IO.userError ("WF foundation extension altered a declaration: " ++ psNameToString name))
    if (psDeclarationValue declaration).isSome then
      unless psReducibilityName (psEnvironmentReducibility proposed name) ==
          (Lean.getReducibilityStatusCore native (PsKernelLean.toLeanName name)).toAttrString do
        throw (IO.userError ("WF foundation reducibility differs: " ++ psNameToString name))
  for name in [`SizeOf, `WellFoundedRelation] do
    let portable := exportName name
    let some (_, parameters) := proposed.classParameters.find? (fun entry => psNameEq entry.1 portable)
      | throw (IO.userError ("WF foundation class metadata missing: " ++ toString name))
    unless Lean.isClass native name && proposed.classes.any (psNameEq portable) &&
        (Lean.getOutParamPositions? native name).map Array.toList == some parameters.outputs &&
        (Lean.getOutLevelParamPositions? native name).map Array.toList == some parameters.outputLevels do
      throw (IO.userError ("WF foundation class metadata differs: " ++ toString name))
  let isNamed := fun (name : PsName) (entry : PsInstanceEntry) =>
    match entry.value with
    | .constE actual _ => psNameEq actual name
    | _ => false
  let registrations : List (Lean.Name × Lean.Name) := [
    (`instSizeOfDefault, `SizeOf), (`instSizeOfNat, `SizeOf),
    (`sizeOfWFRel, `WellFoundedRelation), (`Prod.instWellFoundedRelation, `WellFoundedRelation)]
  for (name, className) in registrations do
    let some upstream := (Lean.Meta.instanceExtension.getState native).instanceNames.find? name
      | throw (IO.userError ("WF foundation native instance missing: " ++ toString name))
    let [selected] := proposed.instances.entries.filter (isNamed (exportName name))
      | throw (IO.userError ("WF foundation instance missing or duplicated: " ++ toString name))
    unless selected.priority == upstream.priority &&
        selected.className.any (psNameEq (exportName className)) do
      throw (IO.userError ("WF foundation instance priority/class differs: " ++ toString name))
    if proposed.instances.defaults.any (isNamed (exportName name)) then
      throw (IO.userError ("WF foundation ordinary instance entered default_instance: " ++ toString name))
  for name in [`Nat.lt_wfRel, `emptyWf] do
    if Lean.Meta.isInstanceCore native name ||
        (proposed.instances.entries ++ proposed.instances.defaults).any (isNamed (exportName name)) then
      throw (IO.userError ("WF foundation named dictionary became an instance: " ++ toString name))
  unless proposed.exportedAliases.any (fun (alias, target) =>
      psNameEq alias (psRootName "sizeOf") && psNameEq target (psDecisionName "SizeOf.sizeOf")) do
    throw (IO.userError "WF foundation sizeOf export alias missing")
  match selectedProofClosureAudit proposed with
  | .ok () => pure ()
  | .error message => throw (IO.userError message)
  match standardInstanceIndexAudit proposed with
  | .ok () => pure ()
  | .error message => throw (IO.userError message)
  -- Exercise the actual search order as well as the imported metadata.
  -- These goals distinguish the Nat method and product lexicographic instance
  -- from the lower-priority fallback without enabling runtime relation code.
  let nat := PsExpr.constE psNatName []
  let product := psExprApplyMany (.constE psProdName [.zero, .zero]) [nat, nat]
  let goals : List (String × PsExpr × PsName) := [
    ("SizeOf Nat", .app (.constE (psRootName "SizeOf") [.succ .zero]) nat,
      psRootName "instSizeOfNat"),
    ("WellFoundedRelation Nat", .app (.constE (psRootName "WellFoundedRelation") [.succ .zero]) nat,
      psRootName "sizeOfWFRel"),
    ("WellFoundedRelation (Nat × Nat)", .app (.constE (psRootName "WellFoundedRelation") [.succ .zero]) product,
      psDecisionName "Prod.instWellFoundedRelation")]
  for (label, target, expected) in goals do
    let found := psSynthInstanceWithTable proposed psLocalEmpty proposed.instances psMetaEmpty 64 target
    let some value := found.result.value
      | throw (IO.userError ("WF foundation synthesis failed: " ++ label))
    let .constE actual _ := (psInferAppView (psMetaInstantiate found.result.context value)).head
      | throw (IO.userError ("WF foundation synthesis has no dictionary head: " ++ label))
    unless psNameEq actual expected && !found.table.resourceExceeded do
      throw (IO.userError ("WF foundation selected the wrong dictionary: " ++ label))
  checkCandidate (candidates ++ base.declarations) candidates
  let compared ← checkRecursorRules native (candidates ++ base.declarations) candidates
  unless compared == 3 do
    throw (IO.userError "WF foundation recursor-rule inventory differs")
  IO.println (Lean.Json.mkObj [
    ("schema", Lean.toJson ("pscv0-well-founded-foundation-audit/1" : String)),
    ("leanCommit", Lean.toJson Lean.githash),
    ("candidateDeclarations", Lean.toJson candidates.length),
    ("candidateAxioms", Lean.toJson ([] : List String)),
    ("kernelChecked", Lean.toJson true),
    ("recursorRulesCompared", Lean.toJson compared),
    ("proposedStandardFNV", Lean.toJson (psStandardSnapshotFingerprint proposed)),
    ("proposedStandardSHA256", Lean.toJson (psStandardSnapshotSHA256Fingerprint proposed)),
    ("proposedSurfaceSHA256", Lean.toJson (standardSurfaceManifestSHA256 proposed)),
    ("proposedDeclarations", Lean.toJson proposed.declarations.length),
    ("proposedClasses", Lean.toJson proposed.classes.length),
    ("proposedInstances", Lean.toJson proposed.instances.entries.length),
    ("activeFoundationDeclarations", Lean.toJson activeNames.length),
    ("runtimeQualified", Lean.toJson false)]).compress

-- Audit the retained Order asset against the frozen pre-Order boundary.
-- Every Core declaration, reducibility choice and selected class/instance
-- record is compared with pinned native Lean before any selected-stage pin
-- can change. This audit also emits proposed identities for explicit review.
def checkPartialFixpointFoundation : IO Unit := do
  Lean.initSearchPath (← Lean.findSysroot)
  -- Class and instance metadata live in persistent environment extensions.
  -- A declaration-only import leaves those extensions at their initial state.
  unsafe Lean.enableInitializersExecution
  let native ← Lean.importModules #[{ module := `Init.Internal.Order.Basic }] {} (loadExts := true)
  unless Lean.githash == "eb6cafb7290e8bd5f2937522d8d804f58f02bafc" do
    throw (IO.userError "P1 foundation audit requires the pinned Lean commit")
  let base := psSelfHostProdPrePartialFixpointPreludeEnvironment
  let candidates := psStandardPartialFixpointCandidateDeclarations
  let names := candidates.map psDeclarationName
  unless candidates.length == 117 && (names.map psNameToString).eraseDups.length == 117 do
    throw (IO.userError "P1 foundation declaration inventory differs")
  unless psStandardPartialFixpointCandidateBoundary.length == base.declarations.length &&
      psStandardPartialFixpointCandidateBoundary.all (psEnvironmentContains base) do
    throw (IO.userError "P1 foundation frozen boundary differs")
  if names.any (psEnvironmentContains base) then
    throw (IO.userError "P1 foundation authoring stage contains its own candidate")
  let activeNames := names.filter (psEnvironmentContains psSelfHostProdPreludeEnvironment)
  unless activeNames.isEmpty || activeNames.length == candidates.length do
    throw (IO.userError "P1 foundation is only partially present in the active Standard")
  let proposed := psStandardPartialFixpointExtend base
  unless proposed.declarations.length == base.declarations.length + candidates.length do
    throw (IO.userError "P1 foundation extension replaced a prior declaration")
  for declaration in candidates do
    let name := psDeclarationName declaration
    match declaration with
    | .axiomDecl .. | .quotientDecl .. | .partialDecl .. =>
      throw (IO.userError ("P1 foundation contains a prohibited declaration: " ++ psNameToString name))
    | _ => pure ()
    let some upstream := native.find? (PsKernelLean.toLeanName name)
      | throw (IO.userError ("P1 foundation native reference missing: " ++ psNameToString name))
    let reference ← match exportDeclaration native [] upstream with
      | .ok reference => pure reference
      | .error message => throw (IO.userError message)
    unless psStandardSnapshotDeclaration declaration == psStandardSnapshotDeclaration reference do
      throw (IO.userError ("P1 foundation stored Core differs from native: " ++ psNameToString name))
    let some selected := psEnvironmentFind proposed name
      | throw (IO.userError ("P1 foundation declaration not selected: " ++ psNameToString name))
    unless psStandardSnapshotDeclaration selected == psStandardSnapshotDeclaration declaration do
      throw (IO.userError ("P1 foundation extension altered a declaration: " ++ psNameToString name))
    if (psDeclarationValue declaration).isSome then
      unless psReducibilityName (psEnvironmentReducibility proposed name) ==
          (Lean.getReducibilityStatusCore native (PsKernelLean.toLeanName name)).toAttrString do
        throw (IO.userError ("P1 foundation reducibility differs: " ++ psNameToString name))
  for name in [`Lean.Order.PartialOrder, `Lean.Order.CCPO] do
    let portable := exportName name
    let some (_, parameters) := proposed.classParameters.find? (fun entry => psNameEq entry.1 portable)
      | throw (IO.userError ("P1 foundation class metadata missing: " ++ toString name))
    unless Lean.isClass native name && proposed.classes.any (psNameEq portable) &&
        (Lean.getOutParamPositions? native name).map Array.toList == some parameters.outputs &&
        (Lean.getOutLevelParamPositions? native name).map Array.toList == some parameters.outputLevels do
      throw (IO.userError ("P1 foundation class metadata differs: " ++ toString name))
  let isNamed := fun (name : PsName) (entry : PsInstanceEntry) =>
    match entry.value with
    | .constE actual _ => psNameEq actual name
    | _ => false
  let registrations : List (Lean.Name × Lean.Name) := [
    (`Lean.Order.CCPO.toPartialOrder, `Lean.Order.PartialOrder),
    (`Lean.Order.instOrderPi, `Lean.Order.PartialOrder),
    (`Lean.Order.instCCPOPi, `Lean.Order.CCPO),
    (`Lean.Order.instPartialOrderPProd, `Lean.Order.PartialOrder),
    (`Lean.Order.instCCPOPProd, `Lean.Order.CCPO),
    (`Lean.Order.instPartialOrderOption, `Lean.Order.PartialOrder),
    (`Lean.Order.instCCPOOption, `Lean.Order.CCPO),
    (`Lean.Order.instPartialOrderUnit, `Lean.Order.PartialOrder),
    (`Lean.Order.instCCPOUnit, `Lean.Order.CCPO),
    (`Lean.Order.FlatOrder.instOrder, `Lean.Order.PartialOrder),
    (`Lean.Order.FlatOrder.instCCPO, `Lean.Order.CCPO)]
  for (name, className) in registrations do
    let some upstream := (Lean.Meta.instanceExtension.getState native).instanceNames.find? name
      | throw (IO.userError ("P1 foundation native instance missing: " ++ toString name))
    let [selected] := proposed.instances.entries.filter (isNamed (exportName name))
      | throw (IO.userError ("P1 foundation instance missing or duplicated: " ++ toString name))
    unless selected.priority == upstream.priority &&
        selected.className.any (psNameEq (exportName className)) do
      throw (IO.userError ("P1 foundation instance priority/class differs: " ++ toString name))
    if proposed.instances.defaults.any (isNamed (exportName name)) then
      throw (IO.userError ("P1 foundation ordinary instance entered default_instance: " ++ toString name))
  -- Logical dependency import does not silently turn classical decisions or
  -- proof helpers into globally selected dictionary/runtime mechanisms.
  let registeredNames := registrations.map (fun entry => exportName entry.1)
  for declaration in candidates do
    let name := psDeclarationName declaration
    if !(registeredNames.any (psNameEq name)) &&
        (proposed.instances.entries ++ proposed.instances.defaults).any (isNamed name) then
      throw (IO.userError ("P1 foundation imported an unselected instance: " ++ psNameToString name))
  unless proposed.classes.length == base.classes.length + 2 &&
      proposed.instances.entries.length == base.instances.entries.length + registrations.length &&
      proposed.instances.defaults.length == base.instances.defaults.length do
    throw (IO.userError "P1 foundation changed the exact class/ordinary/default inventory")
  match selectedProofClosureAudit proposed with
  | .ok () => pure ()
  | .error message => throw (IO.userError message)
  match standardInstanceIndexAudit proposed with
  | .ok () => pure ()
  | .error message => throw (IO.userError message)
  -- Actual dictionary search must use the selected native Option/Pi/PProd
  -- instances, as well as retain their exact registration metadata.
  -- This native control is elaborated independently of the portable terms.
  let _ : Lean.Order.CCPO ((n : Nat) → Option (Fin (n + 1))) := inferInstance
  let nat := PsExpr.constE psNatName []
  let option := psExprApplyMany (.constE (psRootName "Option") [.zero]) [nat]
  let functionType := PsExpr.forallE .anonymous nat option .explicit
  let indexedOption := psExprApplyMany (.constE (psRootName "Option") [.zero])
    [.app (.constE (psRootName "Fin") [])
      (.app (.constE (psNameAppendStr psNatName "succ") []) (.bvar 0))]
  let dependentFunctionType := PsExpr.forallE .anonymous nat indexedOption .explicit
  let product := psExprApplyMany (.constE (psRootName "PProd") [.succ .zero, .succ .zero])
    [option, option]
  let ccpo := fun type => PsExpr.app
    (.constE (psDecisionName "Lean.Order.CCPO") [.succ .zero]) type
  let goals : List (String × PsExpr × PsName) := [
    ("CCPO (Option Nat)", ccpo option, psDecisionName "Lean.Order.instCCPOOption"),
    ("CCPO (Nat → Option Nat)", ccpo functionType, psDecisionName "Lean.Order.instCCPOPi"),
    ("CCPO ((n : Nat) → Option (Fin (n + 1)))", ccpo dependentFunctionType,
      psDecisionName "Lean.Order.instCCPOPi"),
    ("CCPO (PProd (Option Nat) (Option Nat))", ccpo product,
      psDecisionName "Lean.Order.instCCPOPProd")]
  let mut witnessDeclarations : List PsDeclaration := []
  for ((label, target, expected), index) in goals.zipIdx do
    let found := psSynthInstanceWithTable proposed psLocalEmpty proposed.instances psMetaEmpty 64 target
    let some value := found.result.value
      | throw (IO.userError ("P1 foundation synthesis failed: " ++ label))
    let value := psMetaInstantiate found.result.context value
    let .constE actual _ := (psInferAppView value).head
      | throw (IO.userError ("P1 foundation synthesis has no dictionary head: " ++ label))
    unless psNameEq actual expected && !found.table.resourceExceeded &&
        !psExprHasUnresolvedMeta value && psExprFVarsInContext psLocalEmpty value do
      throw (IO.userError ("P1 foundation selected the wrong or open dictionary: " ++ label))
    witnessDeclarations := .definitionDecl
      (.num (psRootName "$psc0P1FoundationWitness") index) [] target value :: witnessDeclarations
  checkCandidate (witnessDeclarations ++ candidates ++ base.declarations)
    (witnessDeclarations ++ candidates)
  let compared ← checkRecursorRules native (candidates ++ base.declarations) candidates
  unless compared == 6 do
    throw (IO.userError "P1 foundation recursor-rule inventory differs")
  IO.println (Lean.Json.mkObj [
    ("schema", Lean.toJson ("pscv0-partial-fixpoint-foundation-audit/1" : String)),
    ("leanCommit", Lean.toJson Lean.githash),
    ("synthesizedDictionaries", Lean.toJson witnessDeclarations.length),
    ("synthesisGoals", Lean.toJson (goals.map (fun entry => entry.1))),
    ("candidateDeclarations", Lean.toJson candidates.length),
    ("candidateAxioms", Lean.toJson ([] : List String)),
    ("kernelChecked", Lean.toJson true),
    ("recursorRulesCompared", Lean.toJson compared),
    ("proposedStandardFNV", Lean.toJson (psStandardSnapshotFingerprint proposed)),
    ("proposedStandardSHA256", Lean.toJson (psStandardSnapshotSHA256Fingerprint proposed)),
    ("proposedSurfaceSHA256", Lean.toJson (standardSurfaceManifestSHA256 proposed)),
    ("proposedDeclarations", Lean.toJson proposed.declarations.length),
    ("proposedClasses", Lean.toJson proposed.classes.length),
    ("proposedInstances", Lean.toJson proposed.instances.entries.length),
    ("activeFoundationDeclarations", Lean.toJson activeNames.length),
    ("runtimeQualified", Lean.toJson false)]).compress

-- Independent Core-first authoring profiles. These never consume the Full
-- portable prelude or a legacy bootstrap axiom boundary.
def coreBootstrapCandidateRoots : List Lean.Name :=
  [`Nat, `Bool, `PUnit, `Unit, `Empty, `PEmpty,
   `True, `False, `Eq, `HEq, `And, `Or, `Exists, `Nonempty,
   `Prod, `PProd, `Sum, `Option, `List, `Except, `Decidable,
   `id, `ite, `dite, `optParam, `outParam]

def coreByteWordCandidateRoots : List Lean.Name :=
  [`UInt8.ofNat, `UInt8.toUInt32, `UInt8.toUInt64,
   `UInt32.ofNat, `UInt32.toNat, `UInt32.add, `UInt32.sub,
   `UInt32.land, `UInt32.lor, `UInt32.xor, `UInt32.complement,
   `UInt32.shiftLeft, `UInt32.shiftRight,
   `UInt64.ofNat, `UInt64.toNat, `UInt64.toUInt8,
   `UInt64.mul, `UInt64.xor, `UInt64.shiftRight,
   `ByteArray, `ByteArray.mk, `ByteArray.size, `ByteArray.push,
   `ByteArray.foldl, `String.toUTF8]

def exportCoreBootstrapCandidate (output : System.FilePath) : IO Unit :=
  exportStandardCore {
    roots := coreBootstrapCandidateRoots
    boundary := []
    baseDeclarations := []
    shareSource := true
    publicPrefix := "psCoreBootstrapCandidate"
    privatePrefix := "coreBootstrapCandidateDecl"
    provenance := "/-\nCopyright (c) Microsoft Corporation and Lean FRO, LLC.\nApache-2.0; see THIRD_PARTY_NOTICES.md.\nPinned Lean 4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc.\nIndependent Core-first bootstrap candidate from an empty kernel environment.\nActual native declarations; no Full boundary or legacy primitive assumptions.\n-/\nimport Ps.Environment.Basic\n\nset_option maxRecDepth 20000\n\n"
  } output

def exportCoreByteWordCandidate (output : System.FilePath) : IO Unit :=
  exportStandardCore {
    roots := coreBootstrapCandidateRoots ++ coreByteWordCandidateRoots
    boundary := []
    baseDeclarations := []
    allowedAssumptions := [`propext, `Quot.sound]
    eraseAutoParams := true
    shareSource := true
    publicPrefix := "psCoreByteWordCandidate"
    privatePrefix := "coreByteWordCandidateDecl"
    provenance := "/-\nCopyright (c) Microsoft Corporation and Lean FRO, LLC.\nApache-2.0; see THIRD_PARTY_NOTICES.md.\nPinned Lean 4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc.\nNative closure for the measured compiler byte/word workload.\nStandalone candidate; source compiler closure and runtime qualification remain separate.\n-/\nimport Ps.Environment.Basic\n\nset_option maxRecDepth 20000\n\n"
  } output

def exportCoreCompilerCandidate (output : System.FilePath) : IO Unit := do
  let measured ← collectCoreNativeClosure
  IO.FS.writeFile (System.FilePath.mk (output.toString ++ ".native-closure.json"))
    (measured.report.compress ++ "\n")
  let allowed : List Lean.Name := [`propext, `Quot.sound]
  let refused := measured.entries.filter fun info =>
    info.isUnsafe || info.isPartial ||
      (info.isAxiom && !allowed.contains info.name)
  unless refused.isEmpty do
    IO.println (Lean.Json.mkObj [
      ("schema", Lean.toJson ("pscv0-core-candidate-refusal/1" : String)),
      ("declarations", Lean.toJson (refused.map (fun info => toString info.name))),
      ("policy", Lean.toJson
        ("No source-root trimming, unsafe or partial declarations, or new assumptions." : String))]).compress
    throw (IO.userError
      "measured native Core closure exceeds the independently approved authoring policy")
  exportStandardCore {
    roots := coreBootstrapCandidateRoots ++ measured.roots
    boundary := []
    baseDeclarations := []
    allowedAssumptions := allowed
    eraseAutoParams := true
    shareSource := true
    nativeModules := coreNativeCompilerImports
    publicPrefix := "psCoreCompilerCandidate"
    privatePrefix := "coreCompilerCandidateDecl"
    provenance := "/-\nCopyright (c) Microsoft Corporation and Lean FRO, LLC.\nApache-2.0; see THIRD_PARTY_NOTICES.md.\nPinned Lean 4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc.\nEmpty-boundary native closure of measured compiler dependencies plus explicit bootstrap seeds.\nCandidate authoring only; no selected Core/Full inclusion or runtime qualification is asserted.\n-/\nimport Ps.Environment.Basic\n\nset_option maxRecDepth 20000\n\n"
  } output

private def coreProbeSubmission (declarations : List PsDeclaration)
    (declaration : PsDeclaration) : IO Lean.Declaration := do
  match PsKernelLean.toLeanPreludeDeclaration declarations declaration with
  | .ok (some value) => pure value
  | .ok none => throw (IO.userError "Core probe expected a kernel submission")
  | .error error => throw (IO.userError error.message)

-- The expected failure is precise. Resource failures, unrelated conversion
-- failures and other IO errors never satisfy a negative authoring control.
private def coreExpectAuthoringFailure (expected : String)
    (action : IO Unit) : IO Unit := do
  let failure ← try
    action
    pure none
  catch error =>
    pure (some error)
  match failure with
  | some (.userError reason) => do
      unless reason == expected do
        throw (IO.userError ("Core control failed at the wrong rule: " ++ reason))
  | some error => throw error
  | none => throw (IO.userError "Core control unexpectedly accepted the mutation")

def checkCoreExportControls : IO Unit := do
  Lean.initSearchPath (← Lean.findSysroot)
  unless Lean.githash == "eb6cafb7290e8bd5f2937522d8d804f58f02bafc" do
    throw (IO.userError "Core controls require pinned Lean 4.35.0")
  let native ← Lean.importModules #[{ module := `Init }] {}
  let mut seen : Lean.NameSet := {}
  let mut entries : Array Lean.ConstantInfo := #[]
  for root in [`Nat, `Bool, `Eq] do
    for info in ← standardDependencyClosure native root do
      unless seen.contains info.name do
        seen := seen.insert info.name
        entries := entries.push info
  let declarations ← entries.toList.mapM fun info => do
    match exportDeclaration native [] info with
    | .ok value => pure value
    | .error error => throw (IO.userError error)
  checkCandidate declarations declarations
  let compared ← checkRecursorRules native declarations declarations
  unless compared > 0 do
    throw (IO.userError "Core controls did not exercise a native recursor rule")
  let empty := (← Lean.mkEmptyEnvironment 0).toKernelEnv
  let replay ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
    PsKernelLean.replayPreludeDeclarations declarations declarations.reverse empty
  let checked ← match replay with
    | .ok value => pure value
    | .error error => throw (IO.userError error.message)
  let nat := PsExpr.constE (exportName `Nat) []
  let zero := PsExpr.lit (.natural 0)
  let one := PsExpr.lit (.natural 1)
  let natural : PsDeclaration := .definitionDecl
    (exportName `_pscv0CoreNaturalProbe) [] nat zero
  let naturalSubmission ← coreProbeSubmission declarations natural
  let absent ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
    empty.addDeclCore 2000000 20000 naturalSubmission none
  match absent with
  | .error (.unknownConstant _ name) => do
      unless name == `Nat do
        throw (IO.userError "Core empty-environment control missed a different dependency")
  | .error error =>
      throw (IO.userError ("Core missing-dependency control failed at the wrong rule: " ++
        PsKernelLean.kernelExceptionSummary error))
  | .ok _ => throw (IO.userError "empty kernel unexpectedly supplied Nat")
  let present ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
    checked.addDeclCore 2000000 20000 naturalSubmission none
  match present with
  | .ok _ => pure ()
  | .error error => throw (IO.userError (PsKernelLean.kernelExceptionSummary error))
  let equality := fun (left right : PsExpr) =>
    PsExpr.app (.app (.app (.constE (exportName `Eq) [.succ .zero]) nat) left) right
  let reflexivity := PsExpr.app
    (.app (.constE (exportName `Eq.refl) [.succ .zero]) nat) zero
  let good : PsDeclaration := .theoremDecl
    (exportName `_pscv0CoreTrueEquation) [] (equality zero zero) reflexivity
  checkCandidate (good :: declarations) [good]
  let bad : PsDeclaration := .theoremDecl
    (exportName `_pscv0CoreFalseEquation) [] (equality zero one) reflexivity
  let badSubmission ← coreProbeSubmission declarations bad
  let falseProof ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
    checked.addDeclCore 2000000 20000 badSubmission none
  match falseProof with
  | .error (.declTypeMismatch ..) => pure ()
  | .error error =>
      throw (IO.userError ("Core false-proof control failed at the wrong rule: " ++
        PsKernelLean.kernelExceptionSummary error))
  | .ok _ => throw (IO.userError "Core candidate kernel accepted false reflexivity")
  let forged := declarations.map fun declaration =>
    match declaration with
    | .recursorDecl info =>
        if psNameEq info.name (exportName `Nat.rec) then
          PsDeclaration.recursorDecl { info with type := nat }
        else declaration
    | _ => declaration
  coreExpectAuthoringFailure "regenerated metadata signature differs: Nat.rec"
    (checkCandidate forged forged)
  for name in [`propext, `Quot.sound, `Classical.choice] do
    let some (.axiomInfo info) := native.checked.get.find? name
      | throw (IO.userError ("missing native assumption control: " ++ toString name))
    match exportDeclaration native [] (.axiomInfo info) with
    | .error reason => do
        unless reason == "unapproved imported assumption in Standard asset" do
          throw (IO.userError ("assumption control failed at the wrong rule: " ++ reason))
    | .ok _ => throw (IO.userError "empty Core assumption policy accepted an axiom")
    if name != `Classical.choice then
      match exportDeclaration native [`propext, `Quot.sound] (.axiomInfo info) with
      | .ok (.axiomDecl ..) => pure ()
      | .ok _ => throw (IO.userError "approved native axiom changed declaration kind")
      | .error error => throw (IO.userError error)
    else
      match exportDeclaration native [`propext, `Quot.sound] (.axiomInfo info) with
      | .error reason => do
          unless reason == "unapproved imported assumption in Standard asset" do
            throw (IO.userError ("Classical control failed at the wrong rule: " ++ reason))
      | .ok _ => throw (IO.userError "byte-word assumption policy accepted Classical.choice")
  IO.println
    "PSCV0_CORE_EXPORT_CONTROLS: PASS empty kernel, checked positive proof, typed false-proof refusal, regenerated-signature refusal, exact assumption policy"

end PsV7Native
