import PsKernelLean.Prelude

namespace PsV7Native

-- This is a signature audit, not a proof that foreign runtime bodies implement
-- Lean definitions. Prelude axioms and checked-model runtime overrides are
-- separate trust categories: replacing an axiom must not hide its backend.
private def renameLevel (parameters : List Lean.Name) : Lean.Level → Lean.Level
  | .param name => .param (.num (.str .anonymous "u") (parameters.idxOf name))
  | .succ value => .succ (renameLevel parameters value)
  | .max a b => .max (renameLevel parameters a) (renameLevel parameters b)
  | .imax a b => .imax (renameLevel parameters a) (renameLevel parameters b)
  | value => value

-- Normalize universe arithmetic after alpha-renaming parameters, using the
-- pinned Lean Level.normalize/isEquiv algorithm. succ(max u v) and
-- max(succ u)(succ v) denote the same sort; structural Expr equality alone
-- must not turn that representation choice into a signature mismatch.
private def normalizeLevel (parameters : List Lean.Name) (level : Lean.Level) : Lean.Level :=
  (renameLevel parameters level).normalize

private def normalizeType (parameters : List Lean.Name) : Lean.Expr → Lean.Expr
  | .sort level => .sort (normalizeLevel parameters level)
  | .const name levels => .const name (levels.map (normalizeLevel parameters))
  | .app fn arg => .app (normalizeType parameters fn) (normalizeType parameters arg)
  | .lam name type body binder => .lam name (normalizeType parameters type) (normalizeType parameters body) binder
  | .forallE name type body binder =>
      .forallE name (normalizeType parameters type) (normalizeType parameters body) binder
  | .letE name type value body nondep =>
      .letE name (normalizeType parameters type) (normalizeType parameters value) (normalizeType parameters body) nondep
  | .mdata _ value => normalizeType parameters value
  | .proj name index value => .proj name index (normalizeType parameters value)
  | value => value

-- Exact reviewed signatures at the pinned native toolchain. These exceptions
-- encode the explicit fold bounds / position representation policies.
-- New mismatches fail qualification instead of expanding trust implicitly.
private def modeledSignatures : List (String × String × String) := [
  ("Array.foldl", "forall {α : Type.{u}} {b : Type.{v}}, (b -> α -> b) -> b -> (Array.{u} α) -> Nat -> Nat -> b", "forall {α : Type.{u}} {β : Type.{v}}, (β -> α -> β) -> β -> (forall (as : Array.{u} α), (optParam.{1} Nat (OfNat.ofNat.{0} Nat 0 (instOfNatNat 0))) -> (optParam.{1} Nat (Array.size.{u} α as)) -> β)"),
  ("String.Pos.Raw.byteIdx", "Nat -> Nat", "String.Pos.Raw -> Nat"),
  ("String.Pos.Raw.mk", "Nat -> Nat", "Nat -> String.Pos.Raw"),
  ("String.Internal.extract", "String -> Nat -> Nat -> String", "([mdata borrowed:1 String]) -> ([mdata borrowed:1 String.Pos.Raw]) -> ([mdata borrowed:1 String.Pos.Raw]) -> String"),
  ("String.Internal.atEnd", "String -> Nat -> Bool", "([mdata borrowed:1 String]) -> ([mdata borrowed:1 String.Pos.Raw]) -> Bool"),
  ("String.Internal.get", "String -> Nat -> Char", "([mdata borrowed:1 String]) -> ([mdata borrowed:1 String.Pos.Raw]) -> Char"),
  ("String.Internal.next", "String -> Nat -> Nat", "([mdata borrowed:1 String]) -> ([mdata borrowed:1 String.Pos.Raw]) -> String.Pos.Raw")]

def primitiveAudit : IO Lean.Json := do
  Lean.initSearchPath (← Lean.findSysroot)
  let native ← Lean.importModules #[{ module := `Init }] {}
  let mut entries := []
  for declaration in psSelfHostProdPreludeEnvironment.declarations do
    let name := psDeclarationName declaration
    let parameters := psDeclarationLevelParams declaration
    let type := psDeclarationType declaration
    let assumption := match declaration with | .axiomDecl .. => true | _ => false
    let reviewed := modeledSignatures.any (fun entry => entry.1 == psNameToString name)
    let opaquePrimitive := ["mixHash", "String.hash"].contains (psNameToString name)
    let logicalAssumption := ["propext", "Quot.sound"].contains (psNameToString name)
    let kernelQuotient := match declaration with | .quotientDecl .. => true | _ => false
    let checkedFoundation := ["Prod", "Prod.mk", "Prod.rec", "Prod.fst", "Prod.snd",
      "List.foldl", "List.reverse", "List.reverseAux"].contains
      (psNameToString name)
    let checkedArray := ["Array", "Array.map", "Array.setIfInBounds", "Array.getD",
      "Array.push", "Array.size", "Array.emptyWithCapacity"].contains (psNameToString name)
    let checkedOperator := psStandardHomogeneousNativeNames.any (psNameEq name)
    if assumption || reviewed || opaquePrimitive || kernelQuotient || checkedFoundation || checkedArray || checkedOperator then
      let nativeName := PsKernelLean.toLeanName name
      let portable ← match PsKernelLean.toLeanExpr type with
        | .ok value => pure value
        | .error _ => throw (IO.userError "primitive signature conversion failed")
      let original := native.find? nativeName
      let matched := match original with
        | none => false
        | some info => info.levelParams.length == parameters.length &&
            normalizeType (PsKernelLean.toLeanNames parameters) portable ==
              normalizeType info.levelParams info.type
      if !matched then
        let found := modeledSignatures.any fun (name, expected, nativeType) =>
          name == toString nativeName && expected == portable.dbgToString &&
            some nativeType == original.map (fun info => info.type.dbgToString)
        if !found then throw (IO.userError ("unreviewed primitive signature mismatch: " ++ toString nativeName ++
          "; portable=" ++ portable.dbgToString ++ "; native=" ++
          (original.map (fun info => info.type.dbgToString)).getD "<missing>"))
      entries := Lean.Json.mkObj [
        ("name", Lean.toJson (toString nativeName)),
        ("signature", Lean.toJson (if matched then "native-level-normalized-alpha-match" else "portable-model")),
        ("portableType", Lean.toJson portable.dbgToString),
        ("nativeType", Lean.toJson (original.map (fun info => info.type.dbgToString))),
        ("bodyTrust", Lean.toJson (if logicalAssumption then "approved-pinned-Lean-logical-assumption"
          else if kernelQuotient then "kernel-generated-quotient-primitive"
          else if assumption then "assumption/runtime-primitive"
          else if checkedFoundation || checkedOperator then "checked-native-signature-foundation"
          else if opaquePrimitive then "checked-opaque-inhabitant/runtime-primitive"
          else "checked-logical-model/runtime-override"))] :: entries
  -- Newly exposed representation conversions and proof-taking operations have
  -- checked portable models. Record both signatures without claiming alpha
  -- equality: selected proof-taking operations use explicit bounds instead of native LT/optParam.
  -- The exact portable bodies remain protected by the Standard snapshot and
  -- separately admitted by the kernel; the source oracle checks observations.
  let unsignedModels := ["UInt8", "UInt16", "UInt32", "UInt64"].flatMap fun owner =>
    ["ofNat", "ofNatLT", "ofBitVec", "toNat", "toBitVec", "toFin",
      "add", "sub", "mul", "div", "mod", "neg", "complement", "land", "lor", "xor", "shiftLeft", "shiftRight"].map (fun method => owner ++ "." ++ method)
  let floatModels := ["Float", "Float32"].flatMap fun owner =>
    let operations := ["add", "sub", "mul", "div", "neg", "abs", "beq",
      "lt", "le", "nan", "inf", "isNaN", "isInf", "isFinite"]
    (["ofBits", "toBits", "ofModel", "toModel", "decLt", "decLe"] ++ operations).map
      (fun method => owner ++ "." ++ method) ++
    operations.map (fun method => owner ++ ".Model." ++ method) ++
    [owner ++ ".instDecidableEqModel", owner ++ ".instDecidableEqModel.decEq",
      "instDecidableEq" ++ owner, "instDecidableEq" ++ owner ++ ".decEq"]
  let modelNames := floatModels ++ unsignedModels ++ ["BitVec.ofNat", "BitVec.ofNatLT", "Nat.pow", "ite", "Nat.mod", "Nat.add", "Nat.sub", "Nat.mul", "Nat.beq", "Int.toNat", "Int.add", "Int.neg", "Int.sub", "Int.mul", "Array.mk", "Array.toList", "Array.getInternal", "Array.set",
    "Nat.ble", "outOfBounds"]
  let mut models := []
  for name in modelNames do
    let some declaration := psSelfHostProdPreludeEnvironment.declarations.find?
      (fun d => psNameToString (psDeclarationName d) == name)
      | throw (IO.userError ("missing checked runtime model: " ++ name))
    match declaration with
    | .axiomDecl .. | .partialDecl .. =>
        throw (IO.userError ("unchecked runtime model: " ++ name))
    | _ => pure ()
    let nativeName := PsKernelLean.toLeanName (psDeclarationName declaration)
    let some original := native.find? nativeName
      | throw (IO.userError ("missing pinned runtime-model reference: " ++ name))
    let portable ← match PsKernelLean.toLeanExpr (psDeclarationType declaration) with
      | .ok value => pure value
      | .error _ => throw (IO.userError ("runtime-model type conversion failed: " ++ name))
    models := Lean.Json.mkObj [
      ("name", Lean.toJson name),
      ("portableType", Lean.toJson portable.dbgToString),
      ("nativeType", Lean.toJson original.type.dbgToString),
      ("signature", Lean.toJson ("recorded-selected-model; no alpha-equivalence claim" : String)),
      ("bodyTrust", Lean.toJson ("kernel-checked-logical-model/runtime-override" : String))] :: models
  -- Reference reducibility is a separate semantic input to instance search.
  -- Record every selected definition's pinned status, including deliberate
  -- portable helper identities absent from the native environment.
  let mut reduction := []
  let mut statusMismatches : List String := []
  for declaration in psSelfHostProdPreludeEnvironment.declarations do
    if (psDeclarationValue declaration).isSome then
      let name := PsKernelLean.toLeanName (psDeclarationName declaration)
      let status := if (native.find? name).isSome then
        some ((Lean.getReducibilityStatusCore native name).toAttrString)
        else none
      let portableStatus := psReducibilityName
        (psEnvironmentReducibility psSelfHostProdPreludeEnvironment (psDeclarationName declaration))
      if let some status := status then
        unless status == portableStatus do
          statusMismatches := (toString name ++ "; native " ++ status ++
            "; portable " ++ portableStatus) :: statusMismatches
      reduction := Lean.Json.mkObj [
        ("name", Lean.toJson (toString name)),
        ("nativeStatus", Lean.toJson status),
        ("portableStatus", Lean.toJson portableStatus)] :: reduction
  unless statusMismatches.isEmpty do
    throw (IO.userError ("reducibility mismatches:\n" ++ String.intercalate "\n" statusMismatches.reverse))
  return Lean.Json.mkObj [
    ("reducibilityReference", Lean.toJson reduction.reverse),
    ("schema", Lean.toJson ("pscv0-primitive-signature-audit/2" : String)),
    ("leanCommit", Lean.toJson Lean.githash),
    ("limitation", Lean.toJson ("Signature comparison for entries; checkedRuntimeModels record deliberate model boundaries without asserting native type equivalence. Kernel admission and runtime equivalence are separate obligations; no runtime equivalence theorem." : String)),
    ("entries", Lean.toJson entries.reverse),
    ("checkedRuntimeModels", Lean.toJson models.reverse)]

end PsV7Native
