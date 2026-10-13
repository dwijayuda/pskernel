/-
Native-only authoring of a reviewed, closed Standard Core asset.
Reference: Lean 4.35.0 Declaration.lean, Expr.lean, Structure.lean and
Init/Prelude.lean, commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Generated upstream bodies retain their Apache-2.0 attribution.
This tool is not imported by the portable compiler.
-/
import Ps.Host.StandardClosure

namespace PsV7Native

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

-- Portable recursor metadata currently represents direct recursive fields.
-- Reject nested/reflexive families instead of silently inventing that metadata.
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
      if domain.getAppFn.isConstOf family then return index :: rest
      if domain.getUsedConstants.contains family then
        throw "nested or reflexive recursive field is outside Standard asset policy"
      return rest
    | _, _, _ => throw "constructor field telescope mismatch"
  collect fields 0 (← skip parameters type)

private def exportDeclaration (native : Lean.Environment) (info : Lean.ConstantInfo) :
    Except String PsDeclaration := do
  if info.isUnsafe || info.isPartial then throw "unsafe or partial Standard declaration"
  let name := exportName info.name
  let levels := info.levelParams.map exportName
  let type ← exportExpr info.type
  match info with
  | .defnInfo value => return .definitionDecl name levels type (← exportExpr value.value)
  | .thmInfo value => return .theoremDecl name levels type (← exportExpr value.value)
  | .opaqueInfo value => return .opaqueDecl name levels type (← exportExpr value.value)
  | .inductInfo value =>
    unless value.all == [value.name] && value.numNested == 0 && !value.isReflexive do
      throw "mutual, nested or reflexive inductive is outside Standard asset policy"
    return .inductiveDecl {
      name, levelParams := levels, type, numParams := value.numParams,
      numIndices := value.numIndices, constructors := value.ctors.map exportName,
      isStructure := Lean.isStructure native value.name }
  | .ctorInfo value =>
    return .constructorDecl {
      name, levelParams := levels, type, inductiveName := exportName value.induct,
      constructorIndex := value.cidx, numParams := value.numParams, numFields := value.numFields,
      recursiveFields := ← recursiveFields value.induct value.numParams value.numFields value.type }
  | .recInfo value =>
    unless value.all.length == 1 && value.numMotives == 1 do
      throw "mutual recursor is outside Standard asset policy"
    return .recursorDecl {
      name, levelParams := levels, type, inductiveNames := value.all.map exportName,
      numParams := value.numParams, numIndices := value.numIndices,
      numMotives := value.numMotives, numMinors := value.numMinors }
  | .axiomInfo _ => throw "new axiom prohibited in Standard asset"
  | .quotInfo _ => throw "new quotient primitive prohibited in Standard asset"

private def sourceList (items : List String) : String :=
  "[" ++ String.intercalate ", " items ++ "]"

private def sourceName : PsName → String
  | .anonymous => ".anonymous"
  | .str parent value => "(.str " ++ sourceName parent ++ " " ++ reprStr value ++ ")"
  | .num parent value => "(.num " ++ sourceName parent ++ " " ++ toString value ++ ")"

private def sourceLevel : PsLevel → String
  | .zero => ".zero"
  | .succ value => "(.succ " ++ sourceLevel value ++ ")"
  | .max a b => "(.max " ++ sourceLevel a ++ " " ++ sourceLevel b ++ ")"
  | .imax a b => "(.imax " ++ sourceLevel a ++ " " ++ sourceLevel b ++ ")"
  | .param name => "(.param " ++ sourceName name ++ ")"
  | .mvar index => "(.mvar " ++ toString index ++ ")"

private def sourceBinder : PsBinderInfo → String
  | .explicit => ".explicit"
  | .implicit => ".implicit"
  | .strictImplicit => ".strictImplicit"
  | .instanceImplicit => ".instanceImplicit"

private def sourceExpr : PsExpr → String
  | .bvar index => "(.bvar " ++ toString index ++ ")"
  | .fvar index => "(.fvar " ++ toString index ++ ")"
  | .mvar index => "(.mvar " ++ toString index ++ ")"
  | .sortE level => "(.sortE " ++ sourceLevel level ++ ")"
  | .constE name levels => "(.constE " ++ sourceName name ++ " " ++ sourceList (levels.map sourceLevel) ++ ")"
  | .app fn arg => "(.app " ++ sourceExpr fn ++ " " ++ sourceExpr arg ++ ")"
  | .lam name type body binder =>
    "(.lam " ++ sourceName name ++ " " ++ sourceExpr type ++ " " ++ sourceExpr body ++ " " ++ sourceBinder binder ++ ")"
  | .forallE name type body binder =>
    "(.forallE " ++ sourceName name ++ " " ++ sourceExpr type ++ " " ++ sourceExpr body ++ " " ++ sourceBinder binder ++ ")"
  | .letE name type value body =>
    "(.letE " ++ sourceName name ++ " " ++ sourceExpr type ++ " " ++ sourceExpr value ++ " " ++ sourceExpr body ++ ")"
  | .lit (.natural value) => "(.lit (.natural " ++ toString value ++ "))"
  | .lit (.string value) => "(.lit (.string " ++ reprStr value ++ "))"
  | .proj name index value => "(.proj " ++ sourceName name ++ " " ++ toString index ++ " " ++ sourceExpr value ++ ")"

private def sourceDeclaration (declaration : PsDeclaration) : String :=
  let common := sourceName (psDeclarationName declaration) ++ " " ++
    sourceList ((psDeclarationLevelParams declaration).map sourceName) ++ " " ++
    sourceExpr (psDeclarationType declaration)
  match declaration with
  | .definitionDecl _ _ _ value => ".definitionDecl " ++ common ++ "\n    " ++ sourceExpr value
  | .theoremDecl _ _ _ value => ".theoremDecl " ++ common ++ "\n    " ++ sourceExpr value
  | .opaqueDecl _ _ _ value => ".opaqueDecl " ++ common ++ "\n    " ++ sourceExpr value
  | .inductiveDecl value => ".inductiveDecl (PsInductiveInfo.mk " ++ common ++ " " ++
      toString value.numParams ++ " " ++ toString value.numIndices ++ " " ++
      sourceList (value.constructors.map sourceName) ++ " " ++ toString value.isStructure ++ ")"
  | .constructorDecl value => ".constructorDecl (PsConstructorInfo.mk " ++ common ++ " " ++
      sourceName value.inductiveName ++ " " ++ toString value.constructorIndex ++ " " ++
      toString value.numParams ++ " " ++ toString value.numFields ++ " " ++
      sourceList (value.recursiveFields.map toString) ++ ")"
  | .recursorDecl value => ".recursorDecl (PsRecursorInfo.mk " ++ common ++ " " ++
      sourceList (value.inductiveNames.map sourceName) ++ " " ++ toString value.numParams ++ " " ++
      toString value.numIndices ++ " " ++ toString value.numMotives ++ " " ++ toString value.numMinors ++ ")"
  | .axiomDecl .. | .partialDecl .. => "" -- Refused before rendering.

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
  let empty ← Lean.mkEmptyEnvironment 0
  let checked ← match PsKernelLean.replayPreludeDeclarations declarations declarations.reverse empty with
    | .ok environment => pure environment
    | .error error => throw (IO.userError error.message)
  -- Constructors and recursors are generated by the kernel; check that the
  -- supplied portable signatures agree with what was actually generated.
  for declaration in candidates do
    match declaration with
    | .constructorDecl _ | .recursorDecl _ =>
      let name := PsKernelLean.toLeanName (psDeclarationName declaration)
      let some info := checked.checked.get.find? name
        | throw (IO.userError ("missing regenerated metadata: " ++ toString name))
      let .ok type := PsKernelLean.toLeanExpr (psDeclarationType declaration)
        | throw (IO.userError "metadata type conversion failed")
      unless info.type == type do
        throw (IO.userError ("regenerated metadata signature differs: " ++ toString name))
    | _ => pure ()

structure StandardExportSpec where
  roots : List Lean.Name
  boundary : List PsName
  baseDeclarations : List PsDeclaration
  publicPrefix : String
  privatePrefix : String
  provenance : String

-- One conversion, admission and source-rendering pipeline for reviewed library
-- slices. Profiles choose roots and a boundary; they cannot bypass checking.
private def exportStandardCore (spec : StandardExportSpec)
    (output : System.FilePath) : IO Unit := do
  Lean.initSearchPath (← Lean.findSysroot)
  let native ← Lean.importModules #[{ module := `Init }] {}
  unless Lean.githash == "eb6cafb7290e8bd5f2937522d8d804f58f02bafc" do
    throw (IO.userError "Standard export requires the pinned Lean 4.35.0 commit")
  let boundary := spec.boundary.foldl
    (fun (names : Lean.NameSet) name => names.insert (PsKernelLean.toLeanName name)) {}
  let base := spec.baseDeclarations.filter
    (fun d => boundary.contains (PsKernelLean.toLeanName (psDeclarationName d)))
  unless base.length == spec.boundary.length do
    throw (IO.userError "frozen Standard export boundary has missing or duplicate declarations")
  let mut seen : Lean.NameSet := {}
  let mut entries : Array Lean.ConstantInfo := #[]
  for root in spec.roots do
    if boundary.contains root then
      throw (IO.userError ("export root was incorrectly cut at boundary: " ++ toString root))
    for info in ← standardDependencyClosure native root boundary do
      if !boundary.contains info.name && !seen.contains info.name then
        seen := seen.insert info.name
        entries := entries.push info
  entries := entries.qsort (fun a b => Lean.Name.lt a.name b.name)
  let declarations ← entries.toList.mapM fun info => do
    match exportDeclaration native info with
    | .ok value => pure value
    | .error reason => throw (IO.userError (toString info.name ++ ": " ++ reason))
  checkCandidate (declarations ++ base) declarations
  let boundaryNames := (base.map psDeclarationName).mergeSort
    (fun a b => Lean.Name.lt (PsKernelLean.toLeanName a) (PsKernelLean.toLeanName b))
  let mut definitions := []
  let mut identifiers := []
  let mut statuses := []
  for (declaration, index) in declarations.zipIdx do
    let identifier := spec.privatePrefix ++ toString index
    definitions := ("-- " ++ psNameToString (psDeclarationName declaration) ++
      "\nprivate def " ++ identifier ++ " : PsDeclaration :=\n  " ++ sourceDeclaration declaration ++ "\n") :: definitions
    identifiers := identifier :: identifiers
    if (psDeclarationValue declaration).isSome then
      let name := psDeclarationName declaration
      statuses := ("(" ++ sourceName name ++ ", " ++ sourceStatus native (PsKernelLean.toLeanName name) ++ ")") :: statuses
  let header := spec.provenance
  let source := header ++ "def " ++ spec.publicPrefix ++ "Boundary : List PsName :=\n  " ++
    sourceList (boundaryNames.map sourceName) ++ "\n\n" ++ String.intercalate "\n" definitions.reverse ++
    "\ndef " ++ spec.publicPrefix ++ "Declarations : List PsDeclaration :=\n  " ++ sourceList identifiers.reverse ++
    "\n\ndef " ++ spec.publicPrefix ++ "Reducibility : List (PsName × PsReducibility) :=\n  " ++
    sourceList statuses.reverse ++ "\n"
  IO.FS.writeFile output source
  IO.println (Lean.Json.mkObj [
    ("schema", Lean.toJson ("pscv0-standard-core-export/1" : String)),
    ("roots", Lean.toJson (spec.roots.map toString)), ("declarations", Lean.toJson declarations.length),
    ("sourceBytes", Lean.toJson source.utf8ByteSize),
    ("kernelChecked", Lean.toJson true), ("leanCommit", Lean.toJson Lean.githash)]).compress
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
// Runtime hash algorithms are audited and qualified independently.
def exportHashFoundation (output : System.FilePath) : IO Unit :=
  exportStandardCore {
    roots := [`Hashable.hash, `mixHash, `String.hash]
    boundary := psSelfHostProdPreludeEnvironment.declarations.map psDeclarationName
    baseDeclarations := psSelfHostProdPreludeEnvironment.declarations
    publicPrefix := "psStandardHashFoundation"
    privatePrefix := "hashFoundationDecl"
    provenance := "/-\nCopyright (c) 2020 Microsoft Corporation. All rights reserved.\nReleased under Apache 2.0 license; see THIRD_PARTY_NOTICES.md.\nUpstream Init/Prelude.lean authors: Leonardo de Moura, Mario Carneiro.\nGenerated by Ps.Host.StandardExport from Lean 4.35.0\neb6cafb7290e8bd5f2937522d8d804f58f02bafc. Modified: closed Core\nconversion removes metadata only; dependency cut is recorded below.\nOpaque runtime primitives remain opaque in the logical library.\n-/\nimport Ps.Environment.Basic\n\nset_option maxRecDepth 20000\n\n" } output

end PsV7Native
