import Ps.Bootstrap.SelfHost

def psMinimalSelfHostLeanSource : String :=
  "def answer : Nat := 42"

def psMinimalSelfHostListConstructionSource : String :=
  "def singleton : List Nat := List.cons 1 List.nil\n"

def psMinimalSelfHostListMatchSource : String :=
  "def headOrZero (xs : List Nat) : Nat :=\n" ++
  "  match xs with\n" ++
  "  | List.nil => 0\n" ++
  "  | List.cons head tail => head\n"

def psMinimalSelfHostListSource : String :=
  psMinimalSelfHostListConstructionSource ++
  psMinimalSelfHostListMatchSource

def psMinimalSelfHostOptionSource : String :=
  "def oneOption : Option Nat := Option.some 1\n" ++
  "def optionOrZero (value : Option Nat) : Nat :=\n" ++
  "  match value with\n" ++
  "  | Option.none => 0\n" ++
  "  | Option.some current => current\n"

def psMinimalSelfHostExceptSource : String :=
  "def okValue : Except String Nat := Except.ok 1\n" ++
  "def errorValue : Except String Nat := Except.error \"bad\"\n" ++
  "def exceptOrZero (value : Except String Nat) : Nat :=\n" ++
  "  match value with\n" ++
  "  | Except.error message => 0\n" ++
  "  | Except.ok current => current\n"

def psMinimalSelfHostProdSource : String :=
  "def pairValue : Prod Nat Nat := Prod.mk 1 2\n"

def psMinimalSelfHostProdMatchSource : String :=
  "def prodFirst (value : Prod Nat Nat) : Nat :=\n" ++
  "  match value with\n" ++
  "  | Prod.mk first second => first\n"

def psTestMinimalSelfHostPreparation : Bool :=
  match
      psCompilerPrepareSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostLeanSource with
  | Except.error _ => false
  | Except.ok prepared =>
      prepared.declarations.length > 0
        && (psCompilerAdmissionsFromPrepared prepared).isOk

def psTestMinimalSelfHostVerifiedIr : Bool :=
  match
      psCompilerPrepareSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostLeanSource with
  | Except.error _ => false
  | Except.ok prepared =>
      match psCompilerVerifiedIrFromPrepared prepared with
      | Except.error _ => false
      | Except.ok _ => true

def psTestInvalidAdmissionReadyRejected : Bool :=
  match
      psCompilerPrepareSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostLeanSource with
  | Except.error _ => false
  | Except.ok prepared =>
      let forged : PsCompilerAdmissionReadyModule :=
        { declarations := [PsDeclaration.definitionDecl (psRootName "bad") []
            (PsExpr.constE psNatName []) (PsExpr.mvar 0)] }
      match psCompilerVerifiedIrFromPrepared forged with
      | Except.error (PsCompilerError.admission _) => true
      | _ => false

def psTestMinimalSelfHostTypeScript : Bool :=
  match
      psCompilerTypeScriptSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostLeanSource with
  | Except.error _ => false
  | Except.ok output => output.contains "answer"

def psTestMinimalSelfHostListConstructionPreparation : Bool :=
  match
      psCompilerPrepareSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostListConstructionSource with
  | Except.error _ => false
  | Except.ok prepared =>
      prepared.declarations.length > 0
        && (psCompilerAdmissionsFromPrepared prepared).isOk

def psTestMinimalSelfHostListMatchPreparation : Bool :=
  match
      psCompilerPrepareSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostListMatchSource with
  | Except.error _ => false
  | Except.ok prepared =>
      prepared.declarations.length > 0
        && (psCompilerAdmissionsFromPrepared prepared).isOk

def psTestMinimalSelfHostListPreparation : Bool :=
  match
      psCompilerPrepareSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostListSource with
  | Except.error _ => false
  | Except.ok prepared =>
      prepared.declarations.length > 0
        && (psCompilerAdmissionsFromPrepared prepared).isOk

def psTestMinimalSelfHostListConstructionMissingRuntime : Bool :=
  match
      psCompilerPrepareSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostListConstructionSource with
  | Except.error _ => false
  | Except.ok prepared =>
      match psCompilerVerifiedIrFromPrepared prepared with
      | Except.error
          (PsCompilerError.erasure
            (PsErasureError.unknownConstant name)) =>
          psNameEq name psSelfHostListConsName
            || psNameEq name psSelfHostListNilName
      | _ => false

def psTestMinimalSelfHostListMatchMissingRuntime : Bool :=
  match
      psCompilerPrepareSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostListMatchSource with
  | Except.error _ => false
  | Except.ok prepared =>
      match psCompilerVerifiedIrFromPrepared prepared with
      | Except.error
          (PsCompilerError.erasure
            (PsErasureError.unknownConstant name)) =>
          psNameEq name psSelfHostListRecName
            || psNameEq name psSelfHostListConsName
            || psNameEq name psSelfHostListNilName
      | _ => false

def psTestMinimalSelfHostListVerifiedIr : Bool :=
  match
      psCompilerPrepareSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostListSource with
  | Except.error _ => false
  | Except.ok prepared =>
      match psCompilerVerifiedIrFromPrepared prepared with
      | Except.error _ => false
      | Except.ok _ => true

def psTestMinimalSelfHostListTypeScript : Bool :=
  match
      psCompilerTypeScriptSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostListSource with
  | Except.error _ => false
  | Except.ok _ => true

def psTestMinimalSelfHostOptionPreparation : Bool :=
  match
      psCompilerPrepareSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostOptionSource with
  | Except.error _ => false
  | Except.ok prepared =>
      prepared.declarations.length > 0
        && (psCompilerAdmissionsFromPrepared prepared).isOk

def psTestMinimalSelfHostOptionVerifiedIr : Bool :=
  match
      psCompilerPrepareSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostOptionSource with
  | Except.error _ => false
  | Except.ok prepared =>
      match psCompilerVerifiedIrFromPrepared prepared with
      | Except.error _ => false
      | Except.ok _ => true

def psTestMinimalSelfHostOptionTypeScript : Bool :=
  match
      psCompilerTypeScriptSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostOptionSource with
  | Except.error _ => false
  | Except.ok _ => true

def psTestMinimalSelfHostExceptPreparation : Bool :=
  match
      psCompilerPrepareSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostExceptSource with
  | Except.error _ => false
  | Except.ok prepared =>
      prepared.declarations.length > 0
        && (psCompilerAdmissionsFromPrepared prepared).isOk

def psTestMinimalSelfHostExceptVerifiedIr : Bool :=
  match
      psCompilerPrepareSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostExceptSource with
  | Except.error _ => false
  | Except.ok prepared =>
      match psCompilerVerifiedIrFromPrepared prepared with
      | Except.error _ => false
      | Except.ok _ => true

def psTestMinimalSelfHostExceptTypeScript : Bool :=
  match
      psCompilerTypeScriptSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostExceptSource with
  | Except.error _ => false
  | Except.ok _ => true

def psTestMinimalSelfHostProdPreparation : Bool :=
  match
      psCompilerPrepareSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostProdSource with
  | Except.error _ => false
  | Except.ok prepared =>
      prepared.declarations.length > 0
        && (psCompilerAdmissionsFromPrepared prepared).isOk

def psTestMinimalSelfHostProdVerifiedIr : Bool :=
  match
      psCompilerPrepareSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostProdSource with
  | Except.error _ => false
  | Except.ok prepared =>
      match psCompilerVerifiedIrFromPrepared prepared with
      | Except.error _ => false
      | Except.ok _ => true

def psTestMinimalSelfHostProdTypeScript : Bool :=
  match
      psCompilerTypeScriptSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostProdSource with
  | Except.error _ => false
  | Except.ok _ => true

def psTestMinimalSelfHostProdMatchPreparation : Bool :=
  match
      psCompilerPrepareSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostProdMatchSource with
  | Except.error _ => false
  | Except.ok prepared =>
      prepared.declarations.length > 0
        && (psCompilerAdmissionsFromPrepared prepared).isOk

def psTestInductiveConstructorTraversal : Bool :=
  let position := PsSourcePos.mk 0 1 1
  let span := PsSourceSpan.mk position position
  let context := psElabContextEmpty psEnvironmentEmpty
  let inductiveName := psRootName "Traversal"
  let firstSource :=
    PsSyntaxInductiveConstructor.mk (PsSyntaxName.mk ["first"] span) [] span
  let secondSource :=
    PsSyntaxInductiveConstructor.mk (PsSyntaxName.mk ["second"] span) [] span
  let invalidSource :=
    PsSyntaxInductiveConstructor.mk (PsSyntaxName.mk [] span) [] span
  let priorA :=
    PsDeclaration.axiomDecl (psRootName "priorA") [] (PsExpr.sortE PsLevel.zero)
  let priorB :=
    PsDeclaration.axiomDecl (psRootName "priorB") [] (PsExpr.sortE PsLevel.zero)
  let ordered :=
    match psElabInductiveConstructors context [] inductiveName 7
        [firstSource, secondSource] [priorB, priorA] with
    | Except.ok [a, b, .constructorDecl first, .constructorDecl second] =>
        psNameEq (psDeclarationName a) (psRootName "priorA")
          && psNameEq (psDeclarationName b) (psRootName "priorB")
          && psNameEq first.name (psNameAppendStr inductiveName "first")
          && psNameEq second.name (psNameAppendStr inductiveName "second")
          && first.constructorIndex == 7
          && second.constructorIndex == 8
          && first.numFields == 0 && second.numFields == 0
    | _ => false
  let empty :=
    match psElabInductiveConstructors context [] inductiveName 7 [] [priorB, priorA] with
    | Except.ok [a, b] =>
        psNameEq (psDeclarationName a) (psRootName "priorA")
          && psNameEq (psDeclarationName b) (psRootName "priorB")
    | _ => false
  let failed :=
    match psElabInductiveConstructors context [] inductiveName 7
        [firstSource, invalidSource, secondSource] [priorB, priorA] with
    | Except.error PsElabError.emptyName => true
    | _ => false
  ordered && empty && failed

def psTestErasureDeclarationNames : Bool :=
  let type := PsExpr.sortE PsLevel.zero
  let name := psRootName "item"
  let prior := psRootName "prior"
  let initial := PsErasureNameState.mk ["item"] [(prior, "item")]
  let sources :=
    [ PsDeclaration.definitionDecl name [] type type,
      PsDeclaration.axiomDecl (psRootName "skip") [] type,
      PsDeclaration.partialDecl name [] type type,
      PsDeclaration.theoremDecl name [] type type,
      PsDeclaration.inductiveDecl
        (PsInductiveInfo.mk (psRootName "Choice") [] type 0 0 [] false) ]
  let result := psBuildErasureDeclarationNames sources initial
  let names := result.entriesRev.map Prod.snd
  let ordered :=
    names == ["Choice", "item___", "item__", "item_", "item"]
      && result.used == names
  let preserved :=
    match result.entriesRev.reverse with
    | (first, _) :: _ => psNameEq first prior
    | _ => false
  let empty := psBuildErasureDeclarationNames [] initial
  let publicNames := (psErasureDeclarationNames sources).map Prod.snd
  ordered && preserved && empty.used == initial.used
    && empty.entriesRev.length == 1
    && publicNames == ["item", "item_", "item__", "Choice"]
    && (psErasureDeclarationNames []).isEmpty

def psTestOpenDefinitionBinderErasure : Bool :=
  let source :=
    "def keep (a : Type) (b : Type) (p : Prop) (h : p) (x : a) (y : b) : a := x\n" ++
    "def proofIdentity (p : Prop) (h : p) : p := h"
  match psCompilerVerifiedIrSource PsCompilerSourceKind.lean source with
  | Except.error _ => false
  | Except.ok ir =>
      ir.raw.declarations.length == 1 && ir.raw.declarations.any fun declaration =>
        declaration.name == "keep"
          && declaration.typeParameters.map (fun parameter => parameter.name) == ["T0", "T1"]
          && declaration.parameters.map (fun parameter => parameter.name) == ["x", "y"]
          && (match declaration.resultType, declaration.body with
              | .typeParameter "T0", .var "x" => true
              | _, _ => false)

def psTestOpenDefinitionFuelBoundary : Bool :=
  let natType := PsExpr.constE psNatName []
  let scope := psErasureScopeEmpty []
  let type := PsExpr.forallE (psRootName "x") natType natType .explicit
  let value := PsExpr.lam (psRootName "x") natType (PsExpr.bvar 0) .explicit
  let exhausted :=
    match psEraseOpenDefinitionWithFuel psBootstrapPreludeEnvironment 1
        scope type value 0 [] [] with
    | Except.error PsErasureError.fuelExhausted => true
    | _ => false
  let completed :=
    match psEraseOpenDefinitionWithFuel psBootstrapPreludeEnvironment 2
        scope type value 0 [] [] with
    | Except.ok opened =>
        opened.typeParameters.isEmpty
          && opened.parameters.map (fun parameter => parameter.name) == ["x"]
          && (match opened.body with | .var "x" => true | _ => false)
    | Except.error _ => false
  exhausted && completed

def psTestErasureDefinitionTraversal : Bool :=
  let environment := psBootstrapPreludeEnvironment
  let scope := psErasureScopeEmpty []
  let natType := PsExpr.constE psNatName []
  let first := PsDeclaration.definitionDecl (psRootName "first") [] natType (.lit (.natural 1))
  let second := PsDeclaration.partialDecl (psRootName "second") [] natType (.lit (.natural 2))
  let skipped := PsDeclaration.axiomDecl (psRootName "skipped") [] natType
  let bad := PsDeclaration.definitionDecl (psRootName "bad") [] natType (.fvar 999)
  let priorA := PsVerifiedIrDeclaration.mk "priorA" [] [] (.primitive .nat) (.literal (.natural 0))
  let priorB := PsVerifiedIrDeclaration.mk "priorB" [] [] (.primitive .nat) (.literal (.natural 0))
  let ordered :=
    match psEraseDefinitionsLoop environment scope [first, skipped, second] [priorB, priorA] with
    | Except.ok declarations =>
        declarations.map (fun declaration => declaration.name) == ["priorA", "priorB", "first", "second"]
    | Except.error _ => false
  let empty :=
    match psEraseDefinitionsLoop environment scope [] [priorB, priorA] with
    | Except.ok declarations =>
        declarations.map (fun declaration => declaration.name) == ["priorA", "priorB"]
    | Except.error _ => false
  let failed :=
    match psEraseDefinitionsLoop environment scope [first, bad, second] [] with
    | Except.error (.unknownLocal 999) => true
    | _ => false
  ordered && empty && failed

def main : IO Unit := do
  if psTestErasureDefinitionTraversal then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: erasure traversal order, partial definitions, skipped axioms, prefix and errors"
  else
    throw (IO.userError "PSC2_MINIMAL_SELFHOST_FAIL: erasure definition traversal")
  if psTestOpenDefinitionBinderErasure && psTestOpenDefinitionFuelBoundary then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: type/proof/runtime binder erasure, parameter order and fuel boundary"
  else
    throw (IO.userError "PSC2_MINIMAL_SELFHOST_FAIL: open-definition erasure contract")
  if psTestErasureDeclarationNames then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: erasure naming collisions, skipped axioms, order and existing state"
  else
    throw (IO.userError "PSC2_MINIMAL_SELFHOST_FAIL: erasure declaration naming")
  if psTestInductiveConstructorTraversal then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: constructor order, indices, accumulated prefix and errors"
  else
    throw (IO.userError "PSC2_MINIMAL_SELFHOST_FAIL: constructor traversal contract")
  if psTestMinimalSelfHostPreparation then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: admission-ready boundary"
  else
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: admission-ready boundary")
  if psTestMinimalSelfHostVerifiedIr then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: prepared core -> VerifiedIR"
  else
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: prepared core -> VerifiedIR")
  if psTestInvalidAdmissionReadyRejected then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: codec-invalid admission-ready declarations rejected"
  else
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: codec-invalid admission-ready declarations was accepted")
  if psTestMinimalSelfHostTypeScript then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: TypeScript bootstrap backend"
  else
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: TypeScript bootstrap backend")
  if psTestMinimalSelfHostListConstructionPreparation then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: foundational List construction preparation"
  else
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: foundational List construction preparation")
  if psTestMinimalSelfHostListMatchPreparation then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: foundational List match preparation"
  else
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: foundational List match preparation")
  if psTestMinimalSelfHostListPreparation then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: foundational List preparation"
  else
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: foundational List preparation")
  if psTestMinimalSelfHostListVerifiedIr then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: foundational List -> VerifiedIR"
  else if psTestMinimalSelfHostListConstructionMissingRuntime then
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: foundational List erasure missing constructor runtime")
  else if psTestMinimalSelfHostListMatchMissingRuntime then
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: foundational List erasure missing match runtime")
  else
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: foundational List -> VerifiedIR")
  if psTestMinimalSelfHostListTypeScript then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: foundational List -> TypeScript"
  else
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: foundational List -> TypeScript")
  if psTestMinimalSelfHostOptionPreparation then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: foundational Option preparation"
  else
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: foundational Option preparation")
  if psTestMinimalSelfHostOptionVerifiedIr then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: foundational Option -> VerifiedIR"
  else
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: foundational Option -> VerifiedIR")
  if psTestMinimalSelfHostOptionTypeScript then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: foundational Option -> TypeScript"
  else
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: foundational Option -> TypeScript")
  if psTestMinimalSelfHostExceptPreparation then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: foundational Except preparation"
  else
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: foundational Except preparation")
  if psTestMinimalSelfHostExceptVerifiedIr then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: foundational Except -> VerifiedIR"
  else
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: foundational Except -> VerifiedIR")
  if psTestMinimalSelfHostExceptTypeScript then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: foundational Except -> TypeScript"
  else
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: foundational Except -> TypeScript")
  if psTestMinimalSelfHostProdPreparation then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: foundational Prod preparation"
  else
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: foundational Prod preparation")
  if psTestMinimalSelfHostProdVerifiedIr then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: foundational Prod -> VerifiedIR"
  else
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: foundational Prod -> VerifiedIR")
  if psTestMinimalSelfHostProdTypeScript then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: foundational Prod -> TypeScript"
  else
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: foundational Prod -> TypeScript")
  if psTestMinimalSelfHostProdMatchPreparation then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: foundational Prod match preparation"
  else
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: foundational Prod match preparation")
