import Ps.Foundation.Name
import Ps.Syntax.Lexer
import Ps.Syntax.ParseLean
import Ps.Syntax.ParseProofScript
import Ps.Core.Abstract
import Ps.Core.Builtin
import Ps.Core.Equality
import Ps.Core.Expr
import Ps.Environment.Basic
import Ps.Environment.LocalContext
import Ps.Environment.Instances
import Ps.Meta.Context
import Ps.Meta.Infer
import Ps.Meta.LevelContext
import Ps.Meta.Reduce
import Ps.Meta.Unify
import Ps.Meta.SynthInstance
import Ps.Project.ModuleGraph
import Ps.Elab.Declaration

def psTestNatEnvironment : PsEnvironment :=
  let declaration :=
    PsDeclaration.axiomDecl
      psNatName
      []
      (PsExpr.sortE (PsLevel.succ PsLevel.zero))
  match psEnvironmentAdd psEnvironmentEmpty declaration with
  | some environment => environment
  | none => psEnvironmentEmpty

def psTestName (value : String) : PsName :=
  psRootName value

def psNameListEq : List PsName -> List PsName -> Bool
  | [], [] => true
  | left :: leftRest, right :: rightRest =>
      psNameEq left right && psNameListEq leftRest rightRest
  | _, _ => false

def psTestModuleGraph : Bool :=
  let a := psTestName "A"
  let b := psTestName "B"
  let nodes := [
    { name := b, imports := [a] : PsModuleNode },
    { name := a, imports := [] : PsModuleNode }
  ]
  match psCreateBuildPlan nodes with
  | Except.error _ => false
  | Except.ok plan => psNameListEq plan.order [a, b]

def psTestScopedMetaAssignment : Bool :=
  let natType := PsExpr.constE psNatName []
  let pushed :=
    psLocalPushBinding
      psLocalEmpty
      (psTestName "x")
      natType
      PsBinderInfo.explicit
  let fresh :=
    psMetaFresh
      psMetaEmpty
      pushed.context
      natType
      PsMetaVarKind.natural
  match fresh.expr with
  | .mvar id =>
      match psMetaAssign fresh.context id (PsExpr.fvar pushed.id) with
      | none => false
      | some _ => true
  | _ => false

def psTestRejectOutOfScopeMetaAssignment : Bool :=
  let natType := PsExpr.constE psNatName []
  let fresh :=
    psMetaFresh
      psMetaEmpty
      psLocalEmpty
      natType
      PsMetaVarKind.natural
  match fresh.expr with
  | .mvar id =>
      match psMetaAssign fresh.context id (PsExpr.fvar 99) with
      | none => true
      | some _ => false
  | _ => false

def psTestBetaWhnf : Bool :=
  let natType := PsExpr.constE psNatName []
  let identity :=
    PsExpr.lam
      (psTestName "x")
      natType
      (PsExpr.bvar 0)
      PsBinderInfo.explicit
  let value := PsExpr.lit (PsLiteral.natural 7)
  let reduced :=
    psWhnf
      psEnvironmentEmpty
      psMetaEmpty
      psLocalEmpty
      (PsExpr.app identity value)
  psExprAlphaEq reduced value

def psTestInferIdentity : Bool :=
  let natType := PsExpr.constE psNatName []
  let name := psTestName "x"
  let identity :=
    PsExpr.lam
      name
      natType
      (PsExpr.bvar 0)
      PsBinderInfo.explicit
  let expected :=
    PsExpr.forallE
      name
      natType
      natType
      PsBinderInfo.explicit
  match psInferType
      psTestNatEnvironment
      psMetaEmpty
      psLocalEmpty
      identity with
  | Except.error _ => false
  | Except.ok actual => psExprAlphaEq actual expected


def psTestLevelMetaUnify : Bool :=
  let fresh := psLevelMetaFresh psLevelMetaEmpty
  let target := PsLevel.succ PsLevel.zero
  let unified := psLevelUnify fresh.context fresh.level target
  if unified.success then
    psLevelStructuralEq
      (psLevelInstantiate unified.context fresh.level)
      target
  else
    false


def psTestTransactionalUnify : Bool :=
  let natTerm := PsExpr.constE psNatName []
  let boolTerm := PsExpr.constE psBoolName []
  let fresh :=
    psMetaFresh
      psMetaEmpty
      psLocalEmpty
      (PsExpr.sortE (PsLevel.succ PsLevel.zero))
      PsMetaVarKind.natural
  match fresh.expr with
  | .mvar id =>
      let left := PsExpr.app fresh.expr natTerm
      let right := PsExpr.app (PsExpr.constE (psTestName "F") []) boolTerm
      let result :=
        psUnify
          psEnvironmentEmpty
          psLocalEmpty
          fresh.context
          left
          right
      !result.success && result.context.assignments.length == fresh.context.assignments.length
  | _ => false

def psTestBinderInfoIgnoredByUnify : Bool :=
  let natType := PsExpr.constE psNatName []
  let left :=
    PsExpr.forallE
      (psTestName "x")
      natType
      natType
      PsBinderInfo.explicit
  let right :=
    PsExpr.forallE
      (psTestName "y")
      natType
      natType
      PsBinderInfo.implicit
  let result :=
    psUnify
      psEnvironmentEmpty
      psLocalEmpty
      psMetaEmpty
      left
      right
  result.success


def psTestClassC : PsName :=
  psTestName "C"

def psTestClassD : PsName :=
  psTestName "D"

def psTestClassApp (className : PsName) (argument : PsExpr) : PsExpr :=
  PsExpr.app (PsExpr.constE className []) argument

def psTestGlobalInstanceSynthesis : Bool :=
  let natType := PsExpr.constE psNatName []
  let target := psTestClassApp psTestClassC natType
  let instanceValue := PsExpr.constE (psTestName "instCNat") []
  let index :=
    psInstanceIndexAdd
      psInstanceIndexEmpty
      { value := instanceValue, type := target }
  let result :=
    psSynthInstance
      psEnvironmentEmpty
      psLocalEmpty
      index
      psMetaEmpty
      target
  match result.value with
  | some value => psExprAlphaEq value instanceValue
  | none => false

def psTestGenericInstanceSynthesis : Bool :=
  let natType := PsExpr.constE psNatName []
  let alphaName := psTestName "alpha"
  let target := psTestClassApp psTestClassC natType
  let instanceHead := PsExpr.constE (psTestName "instC") []
  let instanceType :=
    PsExpr.forallE
      alphaName
      (PsExpr.sortE (PsLevel.succ PsLevel.zero))
      (psTestClassApp psTestClassC (PsExpr.bvar 0))
      PsBinderInfo.implicit
  let index :=
    psInstanceIndexAdd
      psInstanceIndexEmpty
      { value := instanceHead, type := instanceType }
  let result :=
    psSynthInstance
      psEnvironmentEmpty
      psLocalEmpty
      index
      psMetaEmpty
      target
  let expected := PsExpr.app instanceHead natType
  match result.value with
  | some value => psExprAlphaEq value expected
  | none => false

def psTestDependentInstanceSynthesis : Bool :=
  let natType := PsExpr.constE psNatName []
  let alphaName := psTestName "alpha"
  let instanceName := psTestName "instD"
  let dNatValue := PsExpr.constE (psTestName "dNat") []
  let cFromDHead := PsExpr.constE (psTestName "cFromD") []
  let dNatType := psTestClassApp psTestClassD natType
  let cNatType := psTestClassApp psTestClassC natType
  let genericType :=
    PsExpr.forallE
      alphaName
      (PsExpr.sortE (PsLevel.succ PsLevel.zero))
      (PsExpr.forallE
        instanceName
        (psTestClassApp psTestClassD (PsExpr.bvar 0))
        (psTestClassApp psTestClassC (PsExpr.bvar 1))
        PsBinderInfo.instanceImplicit)
      PsBinderInfo.implicit
  let index0 :=
    psInstanceIndexAdd
      psInstanceIndexEmpty
      { value := dNatValue, type := dNatType }
  let index :=
    psInstanceIndexAdd
      index0
      { value := cFromDHead, type := genericType }
  let result :=
    psSynthInstance
      psEnvironmentEmpty
      psLocalEmpty
      index
      psMetaEmpty
      cNatType
  let expected :=
    PsExpr.app
      (PsExpr.app cFromDHead natType)
      dNatValue
  match result.value with
  | some value => psExprAlphaEq value expected
  | none => false

def psTestLocalInstanceSynthesis : Bool :=
  let natType := PsExpr.constE psNatName []
  let target := psTestClassApp psTestClassC natType
  let pushed :=
    psLocalPushBinding
      psLocalEmpty
      (psTestName "localC")
      target
      PsBinderInfo.instanceImplicit
  let result :=
    psSynthInstance
      psEnvironmentEmpty
      pushed.context
      psInstanceIndexEmpty
      psMetaEmpty
      target
  match result.value with
  | some value => psExprAlphaEq value (PsExpr.fvar pushed.id)
  | none => false


def psTestLexerUtf8Offset : Bool :=
  match psLex "𝒫x" with
  | Except.error _ => false
  | Except.ok tokens =>
      match tokens with
      | token :: eofToken :: [] =>
          psTokenKindEq token.kind PsTokenKind.identifier
            && token.text == "𝒫x"
            && token.span.start.byteOffset == 0
            && token.span.stop.byteOffset == 5
            && psTokenKindEq eofToken.kind PsTokenKind.endOfInput
            && eofToken.span.start.byteOffset == 5
      | _ => false

def psTestLexerNestedTrivia : Bool :=
  match psLex "a /- x /- y -/ z -/ b" with
  | Except.error _ => false
  | Except.ok tokens =>
      match tokens with
      | first :: second :: eofToken :: [] =>
          first.text == "a"
            && second.text == "b"
            && psTokenKindEq eofToken.kind PsTokenKind.endOfInput
      | _ => false

def psTestSyntaxNameSingle (name : PsSyntaxName) (expected : String) : Bool :=
  match name.segments with
  | [segment] => segment == expected
  | _ => false

def psTestParsedModuleShape (module : PsSyntaxModule) : Bool :=
  match module.imports, module.declarations with
  | [importDecl], [PsSyntaxDeclaration.definition name [] type value _] =>
      psTestSyntaxNameSingle importDecl.moduleName "A"
        && psTestSyntaxNameSingle name "x"
        && match type, value with
           | PsSyntaxTerm.reference typeName, PsSyntaxTerm.natural text _ =>
               psTestSyntaxNameSingle typeName "Nat" && text == "1"
           | _, _ => false
  | _, _ => false

def psTestDualSourceSimpleParse : Bool :=
  match
      psParseLeanSource "import A\ndef x : Nat := 1",
      psParseProofScriptSource "import A; def x : Nat := 1;" with
  | Except.ok leanModule, Except.ok proofScriptModule =>
      psTestParsedModuleShape leanModule
        && psTestParsedModuleShape proofScriptModule
  | _, _ => false

def psTestBinderKindExplicit (binder : PsSyntaxBinderHead) : Bool :=
  match binder.kind with
  | PsSyntaxBinderKind.explicit => true
  | _ => false

def psTestParsedBinderApplicationShape (module : PsSyntaxModule) : Bool :=
  match module.declarations with
  | [
      PsSyntaxDeclaration.definition
        idName
        [(binder, binderType)]
        idType
        idValue
        _,
      PsSyntaxDeclaration.definition
        oneName
        []
        oneType
        oneValue
        _
    ] =>
      psTestSyntaxNameSingle idName "id"
        && psTestSyntaxNameSingle binder.name "x"
        && psTestBinderKindExplicit binder
        && psTestSyntaxNameSingle oneName "one"
        && match binderType, idType, idValue, oneType, oneValue with
           | PsSyntaxTerm.reference binderTypeName,
             PsSyntaxTerm.reference idTypeName,
             PsSyntaxTerm.reference idValueName,
             PsSyntaxTerm.reference oneTypeName,
             PsSyntaxTerm.app
               (PsSyntaxTerm.reference callName)
               [PsSyntaxTerm.natural argumentText _]
               _ =>
               psTestSyntaxNameSingle binderTypeName "Nat"
                 && psTestSyntaxNameSingle idTypeName "Nat"
                 && psTestSyntaxNameSingle idValueName "x"
                 && psTestSyntaxNameSingle oneTypeName "Nat"
                 && psTestSyntaxNameSingle callName "id"
                 && argumentText == "1"
           | _, _, _, _, _ => false
  | _ => false

def psTestDualSourceBinderApplicationParse : Bool :=
  match
      psParseLeanSource
        "def id (x : Nat) : Nat := x\ndef one : Nat := id 1",
      psParseProofScriptSource
        "def id(x : Nat) : Nat := x; def one : Nat := id(1);" with
  | Except.ok leanModule, Except.ok proofScriptModule =>
      psTestParsedBinderApplicationShape leanModule
        && psTestParsedBinderApplicationShape proofScriptModule
  | _, _ => false

def psSyntaxBinderKindEq
    (left : PsSyntaxBinderKind)
    (right : PsSyntaxBinderKind) : Bool :=
  match left, right with
  | .explicit, .explicit => true
  | .implicit, .implicit => true
  | .strictImplicit, .strictImplicit => true
  | .instanceImplicit, .instanceImplicit => true
  | _, _ => false

def psTestBinderEntry
    (entry : PsSyntaxBinderHead × PsSyntaxTerm)
    (expectedName : String)
    (expectedKind : PsSyntaxBinderKind) : Bool :=
  match entry with
  | (binder, PsSyntaxTerm.reference typeName) =>
      psTestSyntaxNameSingle binder.name expectedName
        && psSyntaxBinderKindEq binder.kind expectedKind
        && psTestSyntaxNameSingle typeName "Nat"
  | _ => false

def psTestParsedBinderKinds (module : PsSyntaxModule) : Bool :=
  match module.declarations with
  | [
      PsSyntaxDeclaration.definition
        name
        [explicitBinder, implicitBinder, strictBinder, instanceBinder]
        (PsSyntaxTerm.reference resultType)
        (PsSyntaxTerm.reference valueName)
        _
    ] =>
      psTestSyntaxNameSingle name "binders"
        && psTestBinderEntry explicitBinder "x" PsSyntaxBinderKind.explicit
        && psTestBinderEntry implicitBinder "y" PsSyntaxBinderKind.implicit
        && psTestBinderEntry strictBinder "z" PsSyntaxBinderKind.strictImplicit
        && psTestBinderEntry instanceBinder "w" PsSyntaxBinderKind.instanceImplicit
        && psTestSyntaxNameSingle resultType "Nat"
        && psTestSyntaxNameSingle valueName "x"
  | _ => false

def psTestDualSourceBinderKindsParse : Bool :=
  match
      psParseLeanSource
        "def binders (x : Nat) {y : Nat} {{z : Nat}} [w : Nat] : Nat := x",
      psParseProofScriptSource
        "def binders(x : Nat){y : Nat}{{z : Nat}}[w : Nat] : Nat := x;" with
  | Except.ok leanModule, Except.ok proofScriptModule =>
      psTestParsedBinderKinds leanModule
        && psTestParsedBinderKinds proofScriptModule
  | _, _ => false

def psTestProofScriptEmptyCallUsesUnit : Bool :=
  match psParseProofScriptSource "def u : Unit := f();" with
  | Except.error _ => false
  | Except.ok module =>
      match module.declarations with
      | [
          PsSyntaxDeclaration.definition
            _
            []
            _
            (PsSyntaxTerm.app
              (PsSyntaxTerm.reference fnName)
              [PsSyntaxTerm.unit _]
              _)
            _
        ] =>
          psTestSyntaxNameSingle fnName "f"
      | _ => false

def psTestProofScriptRejectSpacedCall : Bool :=
  match psParseProofScriptSource "def u : Nat := f (1);" with
  | Except.error _ => true
  | Except.ok _ => false

def psTestCoreDeclarationEq : PsDeclaration -> PsDeclaration -> Bool
  | PsDeclaration.axiomDecl leftName leftLevels leftType,
    PsDeclaration.axiomDecl rightName rightLevels rightType =>
      psNameEq leftName rightName
        && psNameListEq leftLevels rightLevels
        && psExprAlphaEq leftType rightType
  | PsDeclaration.definitionDecl leftName leftLevels leftType leftValue,
    PsDeclaration.definitionDecl rightName rightLevels rightType rightValue =>
      psNameEq leftName rightName
        && psNameListEq leftLevels rightLevels
        && psExprAlphaEq leftType rightType
        && psExprAlphaEq leftValue rightValue
  | PsDeclaration.theoremDecl leftName leftLevels leftType leftValue,
    PsDeclaration.theoremDecl rightName rightLevels rightType rightValue =>
      psNameEq leftName rightName
        && psNameListEq leftLevels rightLevels
        && psExprAlphaEq leftType rightType
        && psExprAlphaEq leftValue rightValue
  | PsDeclaration.opaqueDecl leftName leftLevels leftType leftValue,
    PsDeclaration.opaqueDecl rightName rightLevels rightType rightValue =>
      psNameEq leftName rightName
        && psNameListEq leftLevels rightLevels
        && psExprAlphaEq leftType rightType
        && psExprAlphaEq leftValue rightValue
  | _, _ => false

def psTestCoreDeclarationListsEq :
    List PsDeclaration -> List PsDeclaration -> Bool
  | [], [] => true
  | left :: leftRest, right :: rightRest =>
      psTestCoreDeclarationEq left right
        && psTestCoreDeclarationListsEq leftRest rightRest
  | _, _ => false

def psTestElaboratedBinderApplicationShape
    (result : PsElabModuleResult) : Bool :=
  let natType := PsExpr.constE psNatName []
  let idName := psTestName "id"
  let oneName := psTestName "one"
  let xName := psTestName "x"
  let expectedIdType :=
    PsExpr.forallE
      xName
      natType
      natType
      PsBinderInfo.explicit
  let expectedIdValue :=
    PsExpr.lam
      xName
      natType
      (PsExpr.bvar 0)
      PsBinderInfo.explicit
  let expectedOneValue :=
    PsExpr.app
      (PsExpr.constE idName [])
      (PsExpr.lit (PsLiteral.natural 1))
  match result.declarations with
  | [
      PsDeclaration.definitionDecl actualIdName [] actualIdType actualIdValue,
      PsDeclaration.definitionDecl actualOneName [] actualOneType actualOneValue
    ] =>
      psNameEq actualIdName idName
        && psExprAlphaEq actualIdType expectedIdType
        && psExprAlphaEq actualIdValue expectedIdValue
        && psNameEq actualOneName oneName
        && psExprAlphaEq actualOneType natType
        && psExprAlphaEq actualOneValue expectedOneValue
  | _ => false

def psTestDualSourceCoreElaboration : Bool :=
  match
      psParseLeanSource
        "def id (x : Nat) : Nat := x\ndef one : Nat := id 1",
      psParseProofScriptSource
        "def id(x : Nat) : Nat := x; def one : Nat := id(1);" with
  | Except.ok leanModule, Except.ok proofScriptModule =>
      match
          psElabModule psTestNatEnvironment leanModule,
          psElabModule psTestNatEnvironment proofScriptModule with
      | Except.ok leanResult, Except.ok proofScriptResult =>
          psTestElaboratedBinderApplicationShape leanResult
            && psTestElaboratedBinderApplicationShape proofScriptResult
            && psTestCoreDeclarationListsEq
              leanResult.declarations
              proofScriptResult.declarations
      | _, _ => false
  | _, _ => false

def psTestElaboratedBinderKindsShape
    (result : PsElabModuleResult) : Bool :=
  let natType := PsExpr.constE psNatName []
  let name := psTestName "binders"
  let xName := psTestName "x"
  let yName := psTestName "y"
  let zName := psTestName "z"
  let wName := psTestName "w"
  let expectedType :=
    PsExpr.forallE
      xName
      natType
      (PsExpr.forallE
        yName
        natType
        (PsExpr.forallE
          zName
          natType
          (PsExpr.forallE
            wName
            natType
            natType
            PsBinderInfo.instanceImplicit)
          PsBinderInfo.strictImplicit)
        PsBinderInfo.implicit)
      PsBinderInfo.explicit
  let expectedValue :=
    PsExpr.lam
      xName
      natType
      (PsExpr.lam
        yName
        natType
        (PsExpr.lam
          zName
          natType
          (PsExpr.lam
            wName
            natType
            (PsExpr.bvar 3)
            PsBinderInfo.instanceImplicit)
          PsBinderInfo.strictImplicit)
        PsBinderInfo.implicit)
      PsBinderInfo.explicit
  match result.declarations with
  | [PsDeclaration.definitionDecl actualName [] actualType actualValue] =>
      psNameEq actualName name
        && psExprAlphaEq actualType expectedType
        && psExprAlphaEq actualValue expectedValue
  | _ => false

def psTestDualSourceBinderKindsElaboration : Bool :=
  match
      psParseLeanSource
        "def binders (x : Nat) {y : Nat} {{z : Nat}} [w : Nat] : Nat := x",
      psParseProofScriptSource
        "def binders(x : Nat){y : Nat}{{z : Nat}}[w : Nat] : Nat := x;" with
  | Except.ok leanModule, Except.ok proofScriptModule =>
      match
          psElabModule psTestNatEnvironment leanModule,
          psElabModule psTestNatEnvironment proofScriptModule with
      | Except.ok leanResult, Except.ok proofScriptResult =>
          psTestElaboratedBinderKindsShape leanResult
            && psTestElaboratedBinderKindsShape proofScriptResult
            && psTestCoreDeclarationListsEq
              leanResult.declarations
              proofScriptResult.declarations
      | _, _ => false
  | _, _ => false

structure PsNamedTest where
  name : String
  passed : Bool

def psBootstrapTestCases : List PsNamedTest := [
  { name := "dual-source core elaboration", passed := psTestDualSourceCoreElaboration },
  { name := "dual-source binder kinds elaboration", passed := psTestDualSourceBinderKindsElaboration },
  { name := "dual-source simple parse", passed := psTestDualSourceSimpleParse },
  { name := "dual-source binder application parse", passed := psTestDualSourceBinderApplicationParse },
  { name := "dual-source binder kinds parse", passed := psTestDualSourceBinderKindsParse },
  { name := "ProofScript empty call uses Unit", passed := psTestProofScriptEmptyCallUsesUnit },
  { name := "ProofScript rejects spaced call", passed := psTestProofScriptRejectSpacedCall },
  { name := "lexer UTF-8 byte offsets", passed := psTestLexerUtf8Offset },
  { name := "lexer nested trivia", passed := psTestLexerNestedTrivia },
  { name := "module graph", passed := psTestModuleGraph },
  { name := "global instance synthesis", passed := psTestGlobalInstanceSynthesis },
  { name := "generic instance synthesis", passed := psTestGenericInstanceSynthesis },
  { name := "dependent instance synthesis", passed := psTestDependentInstanceSynthesis },
  { name := "local instance synthesis", passed := psTestLocalInstanceSynthesis },
  { name := "transactional unification", passed := psTestTransactionalUnify },
  { name := "binder-info unification", passed := psTestBinderInfoIgnoredByUnify },
  { name := "level metavariable unification", passed := psTestLevelMetaUnify },
  { name := "scoped metavariable assignment", passed := psTestScopedMetaAssignment },
  { name := "reject out-of-scope assignment", passed := psTestRejectOutOfScopeMetaAssignment },
  { name := "beta WHNF", passed := psTestBetaWhnf },
  { name := "infer identity", passed := psTestInferIdentity }
]

def psBootstrapTests : Bool :=
  psBootstrapTestCases.all (fun test => test.passed)

def psRunNamedTests : List PsNamedTest -> IO Bool
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSC1_TEST_PASS: " ++ test.name)
      else
        IO.println ("PSC1_TEST_FAIL: " ++ test.name)
      let restPassed ← psRunNamedTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psRunNamedTests psBootstrapTestCases
  if passed then
    IO.println "PSC1_BOOTSTRAP_TESTS: PASS"
  else
    throw (IO.userError "PSC1_BOOTSTRAP_TESTS: FAIL")
