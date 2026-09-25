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

def psTestAddDeclaration
    (environment : PsEnvironment)
    (declaration : PsDeclaration) : PsEnvironment :=
  match psEnvironmentAdd environment declaration with
  | some next => next
  | none => environment

def psTestConditionalEnvironment : PsEnvironment :=
  let uName := psTestName "u"
  let alphaName := psTestName "α"
  let aName := psTestName "a"
  let bName := psTestName "b"
  let pName := psTestName "p"
  let cName := psTestName "c"
  let hName := psTestName "h"
  let tName := psTestName "t"
  let eName := psTestName "e"
  let boolType := PsExpr.constE psBoolName []
  let propType := PsExpr.sortE PsLevel.zero
  let typeType := PsExpr.sortE (PsLevel.succ PsLevel.zero)
  let eqType :=
    PsExpr.forallE
      alphaName
      (PsExpr.sortE (PsLevel.param uName))
      (PsExpr.forallE
        aName
        (PsExpr.bvar 0)
        (PsExpr.forallE
          bName
          (PsExpr.bvar 1)
          propType
          PsBinderInfo.explicit)
        PsBinderInfo.explicit)
      PsBinderInfo.implicit
  let decidableType :=
    PsExpr.forallE
      pName
      propType
      typeType
      PsBinderInfo.explicit
  let eqAB :=
    PsExpr.app
      (PsExpr.app
        (PsExpr.app
          (PsExpr.constE
            psEqName
            [PsLevel.succ PsLevel.zero])
          boolType)
        (PsExpr.bvar 1))
      (PsExpr.bvar 0)
  let boolDecEqType :=
    PsExpr.forallE
      aName
      boolType
      (PsExpr.forallE
        bName
        boolType
        (PsExpr.app
          (PsExpr.constE psDecidableName [])
          eqAB)
        PsBinderInfo.explicit)
      PsBinderInfo.explicit
  let iteType :=
    PsExpr.forallE
      alphaName
      (PsExpr.sortE (PsLevel.param uName))
      (PsExpr.forallE
        cName
        propType
        (PsExpr.forallE
          hName
          (PsExpr.app
            (PsExpr.constE psDecidableName [])
            (PsExpr.bvar 0))
          (PsExpr.forallE
            tName
            (PsExpr.bvar 2)
            (PsExpr.forallE
              eName
              (PsExpr.bvar 3)
              (PsExpr.bvar 4)
              PsBinderInfo.explicit)
            PsBinderInfo.explicit)
          PsBinderInfo.instanceImplicit)
        PsBinderInfo.explicit)
      PsBinderInfo.implicit
  let env0 := psTestNatEnvironment
  let env1 :=
    psTestAddDeclaration
      env0
      (PsDeclaration.axiomDecl
        psBoolName
        []
        typeType)
  let env2 :=
    psTestAddDeclaration
      env1
      (PsDeclaration.axiomDecl
        psBoolTrueName
        []
        boolType)
  let env3 :=
    psTestAddDeclaration
      env2
      (PsDeclaration.axiomDecl
        psBoolFalseName
        []
        boolType)
  let env4 :=
    psTestAddDeclaration
      env3
      (PsDeclaration.axiomDecl
        psEqName
        [uName]
        eqType)
  let env5 :=
    psTestAddDeclaration
      env4
      (PsDeclaration.axiomDecl
        psDecidableName
        []
        decidableType)
  let env6 :=
    psTestAddDeclaration
      env5
      (PsDeclaration.axiomDecl
        psBoolDecEqName
        []
        boolDecEqType)
  psTestAddDeclaration
    env6
    (PsDeclaration.axiomDecl
      psIteName
      [uName]
      iteType)

def psTestStringEnvironment : PsEnvironment :=
  psTestAddDeclaration
    psTestNatEnvironment
    (PsDeclaration.axiomDecl
      psStringName
      []
      (PsExpr.sortE (PsLevel.succ PsLevel.zero)))

def psTestUnitEnvironment : PsEnvironment :=
  let typeType := PsExpr.sortE (PsLevel.succ PsLevel.zero)
  let unitType := PsExpr.constE psUnitName []
  let env1 :=
    psTestAddDeclaration
      psTestNatEnvironment
      (PsDeclaration.axiomDecl
        psUnitName
        []
        typeType)
  psTestAddDeclaration
    env1
    (PsDeclaration.axiomDecl
      psUnitUnitName
      []
      unitType)

def psTestCharEnvironment : PsEnvironment :=
  let typeType := PsExpr.sortE (PsLevel.succ PsLevel.zero)
  let natType := PsExpr.constE psNatName []
  let charType := PsExpr.constE psCharName []
  let nName := psTestName "n"
  let env1 :=
    psTestAddDeclaration
      psTestNatEnvironment
      (PsDeclaration.axiomDecl
        psCharName
        []
        typeType)
  psTestAddDeclaration
    env1
    (PsDeclaration.axiomDecl
      psCharOfNatName
      []
      (PsExpr.forallE
        nName
        natType
        charType
        PsBinderInfo.explicit))

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

def psTestTypedLambdaShape
    (parsed : PsParseResult PsSyntaxTerm) : Bool :=
  psTokenCursorDone parsed.cursor
    && match parsed.value with
       | PsSyntaxTerm.lambda
           [binderEntry]
           (PsSyntaxTerm.reference bodyName)
           _ =>
           psTestBinderEntry
             binderEntry
             "x"
             PsSyntaxBinderKind.explicit
             && psTestSyntaxNameSingle bodyName "x"
       | _ => false

def psTestDualSourceTypedLambdaParse : Bool :=
  match
      psLex "fun (x : Nat) => x",
      psLex "fun (x : Nat) => x" with
  | Except.ok leanTokens, Except.ok proofScriptTokens =>
      match
          psParseLeanTerm (psTokenCursorFromTokens leanTokens),
          psParseProofScriptTerm
            (psTokenCursorFromTokens proofScriptTokens) with
      | Except.ok leanTerm, Except.ok proofScriptTerm =>
          psTestTypedLambdaShape leanTerm
            && psTestTypedLambdaShape proofScriptTerm
      | _, _ => false
  | _, _ => false

def psTestAnonymousPiShape
    (parsed : PsParseResult PsSyntaxTerm) : Bool :=
  psTokenCursorDone parsed.cursor
    && match parsed.value with
       | PsSyntaxTerm.forallE
           [(binder, PsSyntaxTerm.reference domainName)]
           (PsSyntaxTerm.reference bodyName)
           _ =>
           psTestSyntaxNameSingle binder.name "_"
             && psSyntaxBinderKindEq
               binder.kind
               PsSyntaxBinderKind.explicit
             && psTestSyntaxNameSingle domainName "Nat"
             && psTestSyntaxNameSingle bodyName "Nat"
       | _ => false

def psTestNamedPiShape
    (parsed : PsParseResult PsSyntaxTerm) : Bool :=
  psTokenCursorDone parsed.cursor
    && match parsed.value with
       | PsSyntaxTerm.forallE
           [(binder, PsSyntaxTerm.reference domainName)]
           (PsSyntaxTerm.reference bodyName)
           _ =>
           psTestSyntaxNameSingle binder.name "x"
             && psSyntaxBinderKindEq
               binder.kind
               PsSyntaxBinderKind.explicit
             && psTestSyntaxNameSingle domainName "Nat"
             && psTestSyntaxNameSingle bodyName "Nat"
       | _ => false

def psTestDualSourcePiParse : Bool :=
  match
      psLex "Nat -> Nat",
      psLex "(x : Nat) -> Nat" with
  | Except.ok arrowTokens, Except.ok dependentTokens =>
      match
          psParseLeanTerm (psTokenCursorFromTokens arrowTokens),
          psParseProofScriptTerm (psTokenCursorFromTokens arrowTokens),
          psParseLeanTerm (psTokenCursorFromTokens dependentTokens),
          psParseProofScriptTerm (psTokenCursorFromTokens dependentTokens) with
      | Except.ok leanArrow,
        Except.ok proofScriptArrow,
        Except.ok leanDependent,
        Except.ok proofScriptDependent =>
          psTestAnonymousPiShape leanArrow
            && psTestAnonymousPiShape proofScriptArrow
            && psTestNamedPiShape leanDependent
            && psTestNamedPiShape proofScriptDependent
      | _, _, _, _ => false
  | _, _ => false

def psTestPiLambdaDeclarationShape
    (result : PsElabModuleResult) : Bool :=
  let natType := PsExpr.constE psNatName []
  let idName := psTestName "id"
  let anonymousName := psTestName "_"
  let xName := psTestName "x"
  let expectedType :=
    PsExpr.forallE
      anonymousName
      natType
      natType
      PsBinderInfo.explicit
  let expectedValue :=
    PsExpr.lam
      xName
      natType
      (PsExpr.bvar 0)
      PsBinderInfo.explicit
  match result.declarations with
  | [PsDeclaration.definitionDecl actualName [] actualType actualValue] =>
      psNameEq actualName idName
        && psExprAlphaEq actualType expectedType
        && psExprAlphaEq actualValue expectedValue
  | _ => false

def psTestDualSourcePiLambdaDeclaration : Bool :=
  match
      psParseLeanSource
        "def id : Nat -> Nat := fun (x : Nat) => x",
      psParseProofScriptSource
        "def id : Nat -> Nat := fun (x : Nat) => x;" with
  | Except.ok leanModule, Except.ok proofScriptModule =>
      match
          psElabModule psTestNatEnvironment leanModule,
          psElabModule psTestNatEnvironment proofScriptModule with
      | Except.ok leanResult, Except.ok proofScriptResult =>
          psTestPiLambdaDeclarationShape leanResult
            && psTestPiLambdaDeclarationShape proofScriptResult
      | _, _ => false
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

def psTestInductiveInfoEq
    (left : PsInductiveInfo)
    (right : PsInductiveInfo) : Bool :=
  psNameEq left.name right.name
    && psNameListEq left.levelParams right.levelParams
    && psExprAlphaEq left.type right.type
    && left.numParams == right.numParams
    && left.numIndices == right.numIndices
    && left.isStructure == right.isStructure
    && psNameListEq left.constructors right.constructors

def psTestConstructorInfoEq
    (left : PsConstructorInfo)
    (right : PsConstructorInfo) : Bool :=
  psNameEq left.name right.name
    && psNameListEq left.levelParams right.levelParams
    && psExprAlphaEq left.type right.type
    && psNameEq left.inductiveName right.inductiveName
    && left.constructorIndex == right.constructorIndex
    && left.numParams == right.numParams
    && left.numFields == right.numFields

def psTestRecursorInfoEq
    (left : PsRecursorInfo)
    (right : PsRecursorInfo) : Bool :=
  psNameEq left.name right.name
    && psNameListEq left.levelParams right.levelParams
    && psExprAlphaEq left.type right.type
    && psNameListEq left.inductiveNames right.inductiveNames
    && left.numParams == right.numParams
    && left.numIndices == right.numIndices
    && left.numMotives == right.numMotives
    && left.numMinors == right.numMinors

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
  | PsDeclaration.partialDecl leftName leftLevels leftType leftValue,
    PsDeclaration.partialDecl rightName rightLevels rightType rightValue =>
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
  | PsDeclaration.inductiveDecl leftInfo,
    PsDeclaration.inductiveDecl rightInfo =>
      psTestInductiveInfoEq leftInfo rightInfo
  | PsDeclaration.constructorDecl leftInfo,
    PsDeclaration.constructorDecl rightInfo =>
      psTestConstructorInfoEq leftInfo rightInfo
  | PsDeclaration.recursorDecl leftInfo,
    PsDeclaration.recursorDecl rightInfo =>
      psTestRecursorInfoEq leftInfo rightInfo
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

def psTestElaboratedTypedLambdaShape
    (result : PsElabTermResult) : Bool :=
  let natType := PsExpr.constE psNatName []
  let xName := psTestName "x"
  let expectedTerm :=
    PsExpr.lam
      xName
      natType
      (PsExpr.bvar 0)
      PsBinderInfo.explicit
  let expectedType :=
    PsExpr.forallE
      xName
      natType
      natType
      PsBinderInfo.explicit
  result.context.localContext.nextId == 0
    && result.context.localContext.declarations.isEmpty
    && psExprAlphaEq result.term expectedTerm
    && psExprAlphaEq result.type expectedType

def psTestDualSourceTypedLambdaElaboration : Bool :=
  match
      psLex "fun (x : Nat) => x",
      psLex "fun (x : Nat) => x" with
  | Except.ok leanTokens, Except.ok proofScriptTokens =>
      match
          psParseLeanTerm (psTokenCursorFromTokens leanTokens),
          psParseProofScriptTerm
            (psTokenCursorFromTokens proofScriptTokens) with
      | Except.ok leanTerm, Except.ok proofScriptTerm =>
          let initial := psElabContextEmpty psTestNatEnvironment
          match
              psElabTerm initial leanTerm.value,
              psElabTerm initial proofScriptTerm.value with
          | Except.ok leanResult, Except.ok proofScriptResult =>
              psTestElaboratedTypedLambdaShape leanResult
                && psTestElaboratedTypedLambdaShape proofScriptResult
                && psExprAlphaEq leanResult.term proofScriptResult.term
                && psExprAlphaEq leanResult.type proofScriptResult.type
          | _, _ => false
      | _, _ => false
  | _, _ => false

def psTestLetDeclarationShape
    (result : PsElabModuleResult) : Bool :=
  let natType := PsExpr.constE psNatName []
  let oneName := psTestName "one"
  let xName := psTestName "x"
  let expectedValue :=
    PsExpr.letE
      xName
      natType
      (PsExpr.lit (PsLiteral.natural 1))
      (PsExpr.bvar 0)
  match result.declarations with
  | [PsDeclaration.definitionDecl actualName [] actualType actualValue] =>
      psNameEq actualName oneName
        && psExprAlphaEq actualType natType
        && psExprAlphaEq actualValue expectedValue
  | _ => false

def psTestDualSourceAnnotatedLet : Bool :=
  match
      psParseLeanSource
        "def one : Nat := let x : Nat := 1; x",
      psParseProofScriptSource
        "def one : Nat := let x : Nat := 1; x;" with
  | Except.ok leanModule, Except.ok proofScriptModule =>
      match
          psElabModule psTestNatEnvironment leanModule,
          psElabModule psTestNatEnvironment proofScriptModule with
      | Except.ok leanResult, Except.ok proofScriptResult =>
          psTestLetDeclarationShape leanResult
            && psTestLetDeclarationShape proofScriptResult
            && psTestCoreDeclarationListsEq
              leanResult.declarations
              proofScriptResult.declarations
      | _, _ => false
  | _, _ => false

def psTestDualSourceInferredLet : Bool :=
  match
      psParseLeanSource
        "def one : Nat := let x := 1; x",
      psParseProofScriptSource
        "def one : Nat := let x := 1; x;" with
  | Except.ok leanModule, Except.ok proofScriptModule =>
      match
          psElabModule psTestNatEnvironment leanModule,
          psElabModule psTestNatEnvironment proofScriptModule with
      | Except.ok leanResult, Except.ok proofScriptResult =>
          psTestLetDeclarationShape leanResult
            && psTestLetDeclarationShape proofScriptResult
            && psTestCoreDeclarationListsEq
              leanResult.declarations
              proofScriptResult.declarations
      | _, _ => false
  | _, _ => false

def psTestBoolLiteralDeclarationShape
    (result : PsElabModuleResult) : Bool :=
  let boolType := PsExpr.constE psBoolName []
  let yesName := psTestName "yes"
  match result.declarations with
  | [PsDeclaration.definitionDecl actualName [] actualType actualValue] =>
      psNameEq actualName yesName
        && psExprAlphaEq actualType boolType
        && psExprAlphaEq
          actualValue
          (PsExpr.constE psBoolTrueName [])
  | _ => false

def psTestDualSourceBoolLiteral : Bool :=
  match
      psParseLeanSource
        "def yes : Bool := true",
      psParseProofScriptSource
        "def yes : Bool := true;" with
  | Except.ok leanModule, Except.ok proofScriptModule =>
      match
          psElabModule psTestConditionalEnvironment leanModule,
          psElabModule psTestConditionalEnvironment proofScriptModule with
      | Except.ok leanResult, Except.ok proofScriptResult =>
          psTestBoolLiteralDeclarationShape leanResult
            && psTestBoolLiteralDeclarationShape proofScriptResult
            && psTestCoreDeclarationListsEq
              leanResult.declarations
              proofScriptResult.declarations
      | _, _ => false
  | _, _ => false

def psTestIfDeclarationShape
    (result : PsElabModuleResult) : Bool :=
  let natType := PsExpr.constE psNatName []
  let boolType := PsExpr.constE psBoolName []
  let trueTerm := PsExpr.constE psBoolTrueName []
  let condition :=
    psExprApplyMany
      (PsExpr.constE
        psEqName
        [PsLevel.succ PsLevel.zero])
      [boolType, trueTerm, trueTerm]
  let decider :=
    psExprApplyMany
      (PsExpr.constE psBoolDecEqName [])
      [trueTerm, trueTerm]
  let expectedValue :=
    psExprApplyMany
      (PsExpr.constE
        psIteName
        [PsLevel.succ PsLevel.zero])
      [
        natType,
        condition,
        decider,
        PsExpr.lit (PsLiteral.natural 1),
        PsExpr.lit (PsLiteral.natural 2)
      ]
  match result.declarations with
  | [PsDeclaration.definitionDecl actualName [] actualType actualValue] =>
      psNameEq actualName (psTestName "pick")
        && psExprAlphaEq actualType natType
        && psExprAlphaEq actualValue expectedValue
  | _ => false

def psTestDualSourceIf : Bool :=
  match
      psParseLeanSource
        "def pick : Nat := if true then 1 else 2",
      psParseProofScriptSource
        "def pick : Nat := if (true) { 1 } else { 2 };" with
  | Except.ok leanModule, Except.ok proofScriptModule =>
      match
          psElabModule psTestConditionalEnvironment leanModule,
          psElabModule psTestConditionalEnvironment proofScriptModule with
      | Except.ok leanResult, Except.ok proofScriptResult =>
          psTestIfDeclarationShape leanResult
            && psTestIfDeclarationShape proofScriptResult
            && psTestCoreDeclarationListsEq
              leanResult.declarations
              proofScriptResult.declarations
      | _, _ => false
  | _, _ => false

def psTestStringLiteralDeclarationShape
    (result : PsElabModuleResult) : Bool :=
  let stringType := PsExpr.constE psStringName []
  let expectedValue := "A\nBAλ"
  match result.declarations with
  | [PsDeclaration.definitionDecl actualName [] actualType actualValue] =>
      psNameEq actualName (psTestName "message")
        && psExprAlphaEq actualType stringType
        && psExprAlphaEq
          actualValue
          (PsExpr.lit (PsLiteral.string expectedValue))
  | _ => false

def psTestDualSourceStringLiteral : Bool :=
  match
      psParseLeanSource
        "def message : String := \"A\\nB\\x41\\u03bb\"",
      psParseProofScriptSource
        "def message : String := \"A\\nB\\x41\\u03bb\";" with
  | Except.ok leanModule, Except.ok proofScriptModule =>
      match
          psElabModule psTestStringEnvironment leanModule,
          psElabModule psTestStringEnvironment proofScriptModule with
      | Except.ok leanResult, Except.ok proofScriptResult =>
          psTestStringLiteralDeclarationShape leanResult
            && psTestStringLiteralDeclarationShape proofScriptResult
            && psTestCoreDeclarationListsEq
              leanResult.declarations
              proofScriptResult.declarations
      | _, _ => false
  | _, _ => false

def psTestRejectInvalidStringEscapes : Bool :=
  match
      psDecodeStringLiteral "\"\\uD800\"",
      psDecodeStringLiteral "\"\\q\"" with
  | none, none => true
  | _, _ => false

def psTestDualSourceGrouping : Bool :=
  match
      psParseLeanSource
        "def one : Nat := (((1)))",
      psParseProofScriptSource
        "def one : Nat := (((1)));" with
  | Except.ok leanModule, Except.ok proofScriptModule =>
      match
          psElabModule psTestNatEnvironment leanModule,
          psElabModule psTestNatEnvironment proofScriptModule with
      | Except.ok leanResult, Except.ok proofScriptResult =>
          match leanResult.declarations, proofScriptResult.declarations with
          | [PsDeclaration.definitionDecl leanName [] leanType leanValue],
            [PsDeclaration.definitionDecl proofName [] proofType proofValue] =>
              psNameEq leanName (psTestName "one")
                && psNameEq proofName (psTestName "one")
                && psExprAlphaEq leanType (PsExpr.constE psNatName [])
                && psExprAlphaEq proofType (PsExpr.constE psNatName [])
                && psExprAlphaEq
                  leanValue
                  (PsExpr.lit (PsLiteral.natural 1))
                && psExprAlphaEq
                  proofValue
                  (PsExpr.lit (PsLiteral.natural 1))
          | _, _ => false
      | _, _ => false
  | _, _ => false

def psTestDualSourceUnit : Bool :=
  match
      psParseLeanSource
        "def u : Unit := ()",
      psParseProofScriptSource
        "def u : Unit := ();" with
  | Except.ok leanModule, Except.ok proofScriptModule =>
      match
          psElabModule psTestUnitEnvironment leanModule,
          psElabModule psTestUnitEnvironment proofScriptModule with
      | Except.ok leanResult, Except.ok proofScriptResult =>
          match leanResult.declarations, proofScriptResult.declarations with
          | [PsDeclaration.definitionDecl leanName [] leanType leanValue],
            [PsDeclaration.definitionDecl proofName [] proofType proofValue] =>
              psNameEq leanName (psTestName "u")
                && psNameEq proofName (psTestName "u")
                && psExprAlphaEq leanType (PsExpr.constE psUnitName [])
                && psExprAlphaEq proofType (PsExpr.constE psUnitName [])
                && psExprAlphaEq
                  leanValue
                  (PsExpr.constE psUnitUnitName [])
                && psExprAlphaEq
                  proofValue
                  (PsExpr.constE psUnitUnitName [])
          | _, _ => false
      | _, _ => false
  | _, _ => false

def psTestLeanParenthesizedApplication : Bool :=
  match psParseLeanSource
      "def id (x : Nat) : Nat := x\ndef one : Nat := id (id 1)" with
  | Except.error _ => false
  | Except.ok module =>
      match psElabModule psTestNatEnvironment module with
      | Except.error _ => false
      | Except.ok result =>
          let idName := psTestName "id"
          let natType := PsExpr.constE psNatName []
          let oneValue :=
            PsExpr.app
              (PsExpr.constE idName [])
              (PsExpr.app
                (PsExpr.constE idName [])
                (PsExpr.lit (PsLiteral.natural 1)))
          match result.declarations with
          | [
              PsDeclaration.definitionDecl _ [] _ _,
              PsDeclaration.definitionDecl oneName [] oneType actualValue
            ] =>
              psNameEq oneName (psTestName "one")
                && psExprAlphaEq oneType natType
                && psExprAlphaEq actualValue oneValue
          | _ => false

def psTestCharLiteralDeclarationShape
    (result : PsElabModuleResult) : Bool :=
  let charType := PsExpr.constE psCharName []
  let expectedValue :=
    PsExpr.app
      (PsExpr.constE psCharOfNatName [])
      (PsExpr.lit (PsLiteral.natural 955))
  match result.declarations with
  | [PsDeclaration.definitionDecl actualName [] actualType actualValue] =>
      psNameEq actualName (psTestName "letter")
        && psExprAlphaEq actualType charType
        && psExprAlphaEq actualValue expectedValue
  | _ => false

def psTestDualSourceCharLiteral : Bool :=
  match
      psParseLeanSource
        "def letter : Char := '\\u03bb'",
      psParseProofScriptSource
        "def letter : Char := '\\u03bb';" with
  | Except.ok leanModule, Except.ok proofScriptModule =>
      match
          psElabModule psTestCharEnvironment leanModule,
          psElabModule psTestCharEnvironment proofScriptModule with
      | Except.ok leanResult, Except.ok proofScriptResult =>
          psTestCharLiteralDeclarationShape leanResult
            && psTestCharLiteralDeclarationShape proofScriptResult
            && psTestCoreDeclarationListsEq
              leanResult.declarations
              proofScriptResult.declarations
      | _, _ => false
  | _, _ => false

def psTestRejectInvalidCharacterEscapes : Bool :=
  match
      psDecodeCharacterLiteral "'\\uD800'",
      psDecodeCharacterLiteral "'\\q'" with
  | none, none => true
  | _, _ => false

def psTestInductiveMetadataLookup : Bool :=
  let boxName := psTestName "Box"
  let ctorName := psNameAppendStr boxName "mk"
  let recName := psNameAppendStr boxName "rec"
  let boxType := PsExpr.sortE (PsLevel.succ PsLevel.zero)
  let inductiveInfo : PsInductiveInfo := {
    name := boxName
    levelParams := []
    type := boxType
    numParams := 0
    numIndices := 0
    constructors := [ctorName]
  }
  let constructorInfo : PsConstructorInfo := {
    name := ctorName
    levelParams := []
    type := PsExpr.constE boxName []
    inductiveName := boxName
    constructorIndex := 0
    numParams := 0
    numFields := 0
  }
  let recursorInfo : PsRecursorInfo := {
    name := recName
    levelParams := []
    type := PsExpr.constE boxName []
    inductiveNames := [boxName]
    numParams := 0
    numIndices := 0
    numMotives := 1
    numMinors := 1
  }
  let env1 :=
    psTestAddDeclaration
      psEnvironmentEmpty
      (PsDeclaration.inductiveDecl inductiveInfo)
  let env2 :=
    psTestAddDeclaration
      env1
      (PsDeclaration.constructorDecl constructorInfo)
  let env3 :=
    psTestAddDeclaration
      env2
      (PsDeclaration.recursorDecl recursorInfo)
  match
      psEnvironmentFindInductive env3 boxName,
      psEnvironmentFindConstructor env3 ctorName,
      psEnvironmentFindRecursor env3 recName with
  | some inductiveInfo, some constructor, some recursor =>
      psNameEq inductiveInfo.name boxName
        && inductiveInfo.numParams == 0
        && inductiveInfo.numIndices == 0
        && inductiveInfo.constructors.length == 1
        && psNameEq constructor.inductiveName boxName
        && constructor.constructorIndex == 0
        && constructor.numFields == 0
        && recursor.numMotives == 1
        && recursor.numMinors == 1
  | _, _, _ => false

def psTestBasicMatchShape
    (parsed : PsParseResult PsSyntaxTerm) : Bool :=
  psTokenCursorDone parsed.cursor
    && match parsed.value with
       | PsSyntaxTerm.matchE
           (PsSyntaxTerm.bool true _)
           [
             (PsSyntaxPattern.bool true _, PsSyntaxTerm.natural "1" _, _),
             (PsSyntaxPattern.bool false _, PsSyntaxTerm.natural "2" _, _)
           ]
           _ => true
       | _ => false

def psTestDualSourceBasicMatchParse : Bool :=
  match
      psLex "match true with | true => 1 | false => 2",
      psLex "match true with { | true => 1; | false => 2 }" with
  | Except.ok leanTokens, Except.ok proofScriptTokens =>
      match
          psParseLeanTerm (psTokenCursorFromTokens leanTokens),
          psParseProofScriptTerm
            (psTokenCursorFromTokens proofScriptTokens) with
      | Except.ok leanTerm, Except.ok proofScriptTerm =>
          psTestBasicMatchShape leanTerm
            && psTestBasicMatchShape proofScriptTerm
      | _, _ => false
  | _, _ => false

def psTestLeanNestedMatchDedentParse : Bool :=
  let source :=
    "match true with\n" ++
    "  | true =>\n" ++
    "      match false with\n" ++
    "      | true => 1\n" ++
    "      | false => 2\n" ++
    "  | false => 3"
  match psLex source with
  | Except.error _ => false
  | Except.ok tokens =>
      match psParseLeanTerm (psTokenCursorFromTokens tokens) with
      | Except.error _ => false
      | Except.ok parsed =>
          psTokenCursorDone parsed.cursor
            && match parsed.value with
               | PsSyntaxTerm.matchE
                   (PsSyntaxTerm.bool true _)
                   [
                     (
                       PsSyntaxPattern.bool true _,
                       PsSyntaxTerm.matchE
                         (PsSyntaxTerm.bool false _)
                         [
                           (
                             PsSyntaxPattern.bool true _,
                             PsSyntaxTerm.natural "1" _,
                             _
                           ),
                           (
                             PsSyntaxPattern.bool false _,
                             PsSyntaxTerm.natural "2" _,
                             _
                           )
                         ]
                         _,
                       _
                     ),
                     (
                       PsSyntaxPattern.bool false _,
                       PsSyntaxTerm.natural "3" _,
                       _
                     )
                   ]
                   _ => true
               | _ => false

def psTestPreludeCollectionTypeConstructors : Bool :=
  psEnvironmentContains psBootstrapPreludeEnvironment psListName
    && psEnvironmentContains psBootstrapPreludeEnvironment psOptionName
    && match
        psEnvironmentFind psBootstrapPreludeEnvironment psListName,
        psEnvironmentFind psBootstrapPreludeEnvironment psOptionName with
       | some (PsDeclaration.axiomDecl _ _ _),
         some (PsDeclaration.axiomDecl _ _ _) => true
       | _, _ => false

def psTestLeanProductInsideApplicationParse : Bool :=
  let source := "List (Nat × String)"
  match psLex source with
  | Except.error _ => false
  | Except.ok tokens =>
      match psParseLeanTerm (psTokenCursorFromTokens tokens) with
      | Except.error _ => false
      | Except.ok parsed =>
          psTokenCursorDone parsed.cursor
            && match parsed.value with
               | PsSyntaxTerm.app
                   (PsSyntaxTerm.reference listName)
                   [
                     PsSyntaxTerm.app
                       (PsSyntaxTerm.reference prodName)
                       [
                         PsSyntaxTerm.reference natName,
                         PsSyntaxTerm.reference stringName
                       ]
                       _
                   ]
                   _ =>
                   listName.segments == ["List"]
                     && prodName.segments == ["Prod"]
                     && natName.segments == ["Nat"]
                     && stringName.segments == ["String"]
               | _ => false

def psTestConstructorMatchPatternShape : Bool :=
  match psLex "match x with | Option.some y => y | Option.none => 0" with
  | Except.error _ => false
  | Except.ok tokens =>
      match psParseLeanTerm (psTokenCursorFromTokens tokens) with
      | Except.error _ => false
      | Except.ok parsed =>
          psTokenCursorDone parsed.cursor
            && match parsed.value with
               | PsSyntaxTerm.matchE
                   (PsSyntaxTerm.reference scrutinee)
                   [
                     (
                       PsSyntaxPattern.constructor
                         someName
                         [binder]
                         _,
                       PsSyntaxTerm.reference bodyName,
                       _
                     ),
                     (
                       PsSyntaxPattern.constructor noneName [] _,
                       PsSyntaxTerm.natural "0" _,
                       _
                     )
                   ]
                   _ =>
                   psTestSyntaxNameSingle scrutinee "x"
                     && someName.segments == ["Option", "some"]
                     && psTestSyntaxNameSingle binder "y"
                     && psTestSyntaxNameSingle bodyName "y"
                     && noneName.segments == ["Option", "none"]
               | _ => false

def psTestChoiceEnvironment : PsEnvironment :=
  let choiceName := psTestName "Choice"
  let leftName := psNameAppendStr choiceName "left"
  let rightName := psNameAppendStr choiceName "right"
  let recName := psNameAppendStr choiceName "rec"
  let uName := psTestName "u"
  let motiveName := psTestName "motive"
  let leftCaseName := psTestName "leftCase"
  let rightCaseName := psTestName "rightCase"
  let majorName := psTestName "major"
  let choiceType := PsExpr.constE choiceName []
  let choiceSort := PsExpr.sortE (PsLevel.succ PsLevel.zero)
  let motiveType :=
    PsExpr.forallE
      (psTestName "_choice")
      choiceType
      (PsExpr.sortE (PsLevel.param uName))
      PsBinderInfo.explicit
  let recursorType :=
    PsExpr.forallE
      motiveName
      motiveType
      (PsExpr.forallE
        leftCaseName
        (PsExpr.app (PsExpr.bvar 0) (PsExpr.constE leftName []))
        (PsExpr.forallE
          rightCaseName
          (PsExpr.app (PsExpr.bvar 1) (PsExpr.constE rightName []))
          (PsExpr.forallE
            majorName
            choiceType
            (PsExpr.app (PsExpr.bvar 3) (PsExpr.bvar 0))
            PsBinderInfo.explicit)
          PsBinderInfo.explicit)
        PsBinderInfo.explicit)
      PsBinderInfo.explicit
  let indInfo : PsInductiveInfo := {
    name := choiceName
    levelParams := []
    type := choiceSort
    numParams := 0
    numIndices := 0
    constructors := [leftName, rightName]
  }
  let leftInfo : PsConstructorInfo := {
    name := leftName
    levelParams := []
    type := choiceType
    inductiveName := choiceName
    constructorIndex := 0
    numParams := 0
    numFields := 0
  }
  let rightInfo : PsConstructorInfo := {
    name := rightName
    levelParams := []
    type := choiceType
    inductiveName := choiceName
    constructorIndex := 1
    numParams := 0
    numFields := 0
  }
  let recInfo : PsRecursorInfo := {
    name := recName
    levelParams := [uName]
    type := recursorType
    inductiveNames := [choiceName]
    numParams := 0
    numIndices := 0
    numMotives := 1
    numMinors := 2
  }
  let env1 :=
    psTestAddDeclaration
      psTestNatEnvironment
      (PsDeclaration.inductiveDecl indInfo)
  let env2 :=
    psTestAddDeclaration
      env1
      (PsDeclaration.constructorDecl leftInfo)
  let env3 :=
    psTestAddDeclaration
      env2
      (PsDeclaration.constructorDecl rightInfo)
  psTestAddDeclaration
    env3
    (PsDeclaration.recursorDecl recInfo)

def psTestBasicMatchDeclarationShape
    (result : PsElabModuleResult) : Bool :=
  let recName := psNameAppendStr (psTestName "Choice") "rec"
  let natType := PsExpr.constE psNatName []
  match result.declarations with
  | [PsDeclaration.definitionDecl actualName [] actualType actualValue] =>
      let view := psExprAppView actualValue
      psNameEq actualName (psTestName "pick")
        && psExprAlphaEq actualType natType
        && match view.head with
           | PsExpr.constE name levels =>
               psNameEq name recName
                 && levels.length == 1
                 && view.args.length == 4
           | _ => false
  | _ => false

def psTestDualSourceBasicMatchElaboration : Bool :=
  match
      psParseLeanSource
        "def pick : Nat := match Choice.left with | Choice.left => 1 | Choice.right => 2",
      psParseProofScriptSource
        "def pick : Nat := match Choice.left with { | Choice.left => 1; | Choice.right => 2 };" with
  | Except.ok leanModule, Except.ok proofScriptModule =>
      match
          psElabModule psTestChoiceEnvironment leanModule,
          psElabModule psTestChoiceEnvironment proofScriptModule with
      | Except.ok leanResult, Except.ok proofScriptResult =>
          psTestBasicMatchDeclarationShape leanResult
            && psTestBasicMatchDeclarationShape proofScriptResult
            && psTestCoreDeclarationListsEq
              leanResult.declarations
              proofScriptResult.declarations
      | _, _ => false
  | _, _ => false

def psTestBoxNatEnvironment : PsEnvironment :=
  let boxName := psTestName "BoxNat"
  let ctorName := psNameAppendStr boxName "mk"
  let recName := psNameAppendStr boxName "rec"
  let uName := psTestName "u"
  let motiveName := psTestName "motive"
  let minorName := psTestName "minor"
  let fieldName := psTestName "x"
  let majorName := psTestName "major"
  let natType := PsExpr.constE psNatName []
  let boxType := PsExpr.constE boxName []
  let boxSort := PsExpr.sortE (PsLevel.succ PsLevel.zero)
  let ctorType :=
    PsExpr.forallE
      fieldName
      natType
      boxType
      PsBinderInfo.explicit
  let motiveType :=
    PsExpr.forallE
      (psTestName "_box")
      boxType
      (PsExpr.sortE (PsLevel.param uName))
      PsBinderInfo.explicit
  let minorType :=
    PsExpr.forallE
      fieldName
      natType
      (PsExpr.app
        (PsExpr.bvar 1)
        (PsExpr.app
          (PsExpr.constE ctorName [])
          (PsExpr.bvar 0)))
      PsBinderInfo.explicit
  let recursorType :=
    PsExpr.forallE
      motiveName
      motiveType
      (PsExpr.forallE
        minorName
        minorType
        (PsExpr.forallE
          majorName
          boxType
          (PsExpr.app (PsExpr.bvar 2) (PsExpr.bvar 0))
          PsBinderInfo.explicit)
        PsBinderInfo.explicit)
      PsBinderInfo.explicit
  let boxInfo : PsInductiveInfo := {
    name := boxName
    levelParams := []
    type := boxSort
    numParams := 0
    numIndices := 0
    constructors := [ctorName]
  }
  let ctorInfo : PsConstructorInfo := {
    name := ctorName
    levelParams := []
    type := ctorType
    inductiveName := boxName
    constructorIndex := 0
    numParams := 0
    numFields := 1
  }
  let recInfo : PsRecursorInfo := {
    name := recName
    levelParams := [uName]
    type := recursorType
    inductiveNames := [boxName]
    numParams := 0
    numIndices := 0
    numMotives := 1
    numMinors := 1
  }
  let env1 :=
    psTestAddDeclaration
      psTestNatEnvironment
      (PsDeclaration.inductiveDecl boxInfo)
  let env2 :=
    psTestAddDeclaration
      env1
      (PsDeclaration.constructorDecl ctorInfo)
  psTestAddDeclaration
    env2
    (PsDeclaration.recursorDecl recInfo)

def psTestFieldMatchDeclarationShape
    (result : PsElabModuleResult) : Bool :=
  let boxName := psTestName "BoxNat"
  let recName := psNameAppendStr boxName "rec"
  let natType := PsExpr.constE psNatName []
  let boxType := PsExpr.constE boxName []
  match result.declarations with
  | [
      PsDeclaration.definitionDecl
        actualName
        []
        actualType
        actualValue
    ] =>
      let expectedType :=
        PsExpr.forallE
          (psTestName "v")
          boxType
          natType
          PsBinderInfo.explicit
      psNameEq actualName (psTestName "unwrap")
        && psExprAlphaEq actualType expectedType
        && match actualValue with
           | PsExpr.lam _ _ body PsBinderInfo.explicit =>
               let view := psExprAppView body
               match view.head with
               | PsExpr.constE name levels =>
                   psNameEq name recName
                     && levels.length == 1
                     && view.args.length == 3
                     && match view.args with
                        | [_motive, minor, _major] =>
                            match minor with
                            | PsExpr.lam
                                binderName
                                binderType
                                binderBody
                                PsBinderInfo.explicit =>
                                psNameEq binderName (psTestName "x")
                                  && psExprAlphaEq binderType natType
                                  && psExprAlphaEq binderBody (PsExpr.bvar 0)
                            | _ => false
                        | _ => false
               | _ => false
           | _ => false
  | _ => false

def psTestDualSourceFieldMatchElaboration : Bool :=
  match
      psParseLeanSource
        "def unwrap (v : BoxNat) : Nat := match v with | BoxNat.mk x => x",
      psParseProofScriptSource
        "def unwrap(v : BoxNat) : Nat := match v with { | BoxNat.mk x => x };" with
  | Except.ok leanModule, Except.ok proofScriptModule =>
      match
          psElabModule psTestBoxNatEnvironment leanModule,
          psElabModule psTestBoxNatEnvironment proofScriptModule with
      | Except.ok leanResult, Except.ok proofScriptResult =>
          psTestFieldMatchDeclarationShape leanResult
            && psTestFieldMatchDeclarationShape proofScriptResult
            && psTestCoreDeclarationListsEq
              leanResult.declarations
              proofScriptResult.declarations
      | _, _ => false
  | _, _ => false

def psTestDefEqBetaUnderForall : Bool :=
  let natType := PsExpr.constE psNatName []
  let left :=
    PsExpr.forallE
      (psTestName "x")
      natType
      (PsExpr.app
        (PsExpr.lam
          (psTestName "_")
          natType
          natType
          PsBinderInfo.explicit)
        (PsExpr.bvar 0))
      PsBinderInfo.explicit
  let right :=
    PsExpr.forallE
      (psTestName "x")
      natType
      natType
      PsBinderInfo.explicit
  psDefEqReadOnlyWithEnv
    psTestNatEnvironment
    psMetaEmpty
    psLocalEmpty
    left
    right

def psTestInductiveEnumShape
    (module : PsSyntaxModule) : Bool :=
  match module.declarations with
  | [
      PsSyntaxDeclaration.inductiveDecl
        name
        []
        none
        [leftCtor, rightCtor]
        _
    ] =>
      psTestSyntaxNameSingle name "Choice"
        && psTestSyntaxNameSingle leftCtor.name "left"
        && leftCtor.fields.isEmpty
        && psTestSyntaxNameSingle rightCtor.name "right"
        && rightCtor.fields.isEmpty
  | _ => false

def psTestDualSourceInductiveEnumParse : Bool :=
  match
      psParseLeanSource
        "inductive Choice where | left | right",
      psParseProofScriptSource
        "inductive Choice where { | left; | right; };" with
  | Except.ok leanModule, Except.ok proofScriptModule =>
      psTestInductiveEnumShape leanModule
        && psTestInductiveEnumShape proofScriptModule
  | _, _ => false

def psTestInductiveFieldShape
    (module : PsSyntaxModule) : Bool :=
  match module.declarations with
  | [
      PsSyntaxDeclaration.inductiveDecl
        name
        []
        none
        [constructor]
        _
    ] =>
      psTestSyntaxNameSingle name "BoxNat"
        && psTestSyntaxNameSingle constructor.name "mk"
        && match constructor.fields with
           | [(binder, PsSyntaxTerm.reference typeName)] =>
               psTestSyntaxNameSingle binder.name "x"
                 && psSyntaxBinderKindEq
                   binder.kind
                   PsSyntaxBinderKind.explicit
                 && psTestSyntaxNameSingle typeName "Nat"
           | _ => false
  | _ => false

def psTestDualSourceInductiveFieldParse : Bool :=
  match
      psParseLeanSource
        "inductive BoxNat where | mk (x : Nat)",
      psParseProofScriptSource
        "inductive BoxNat where { | mk(x : Nat); };" with
  | Except.ok leanModule, Except.ok proofScriptModule =>
      psTestInductiveFieldShape leanModule
        && psTestInductiveFieldShape proofScriptModule
  | _, _ => false

def psTestSourceInductiveEnumShape
    (result : PsElabModuleResult) : Bool :=
  let choiceName := psTestName "Choice"
  let leftName := psNameAppendStr choiceName "left"
  let rightName := psNameAppendStr choiceName "right"
  let recName := psNameAppendStr choiceName "rec"
  let natType := PsExpr.constE psNatName []
  match result.declarations with
  | [
      PsDeclaration.inductiveDecl inductiveInfo,
      PsDeclaration.constructorDecl leftInfo,
      PsDeclaration.constructorDecl rightInfo,
      PsDeclaration.recursorDecl recInfo,
      PsDeclaration.definitionDecl pickName [] pickType pickValue
    ] =>
      psNameEq inductiveInfo.name choiceName
        && inductiveInfo.numParams == 0
        && inductiveInfo.numIndices == 0
        && psNameListEq
          inductiveInfo.constructors
          [leftName, rightName]
        && psNameEq leftInfo.name leftName
        && leftInfo.constructorIndex == 0
        && leftInfo.numFields == 0
        && psNameEq rightInfo.name rightName
        && rightInfo.constructorIndex == 1
        && rightInfo.numFields == 0
        && psNameEq recInfo.name recName
        && recInfo.numParams == 0
        && recInfo.numIndices == 0
        && recInfo.numMotives == 1
        && recInfo.numMinors == 2
        && psNameEq pickName (psTestName "pick")
        && psExprAlphaEq pickType
          (PsExpr.forallE
            (psTestName "v")
            (PsExpr.constE choiceName [])
            natType
            PsBinderInfo.explicit)
        && match pickValue with
           | PsExpr.lam _ _ body PsBinderInfo.explicit =>
               let view := psExprAppView body
               match view.head with
               | PsExpr.constE name levels =>
                   psNameEq name recName
                     && levels.length == 1
                     && view.args.length == 4
               | _ => false
           | _ => false
  | _ => false

def psTestDualSourceInductiveEnumElaboration : Bool :=
  match
      psParseLeanSource
        "inductive Choice where | left | right\ndef pick (v : Choice) : Nat := match v with | Choice.left => 1 | Choice.right => 2",
      psParseProofScriptSource
        "inductive Choice where { | left; | right; }; def pick(v : Choice) : Nat := match v with { | Choice.left => 1; | Choice.right => 2 };" with
  | Except.ok leanModule, Except.ok proofScriptModule =>
      match
          psElabModule psTestNatEnvironment leanModule,
          psElabModule psTestNatEnvironment proofScriptModule with
      | Except.ok leanResult, Except.ok proofScriptResult =>
          psTestSourceInductiveEnumShape leanResult
            && psTestSourceInductiveEnumShape proofScriptResult
            && psTestCoreDeclarationListsEq
              leanResult.declarations
              proofScriptResult.declarations
      | _, _ => false
  | _, _ => false

def psTestSourceInductiveFieldShape
    (result : PsElabModuleResult) : Bool :=
  let boxName := psTestName "BoxNat"
  let ctorName := psNameAppendStr boxName "mk"
  let recName := psNameAppendStr boxName "rec"
  let natType := PsExpr.constE psNatName []
  match result.declarations with
  | [
      PsDeclaration.inductiveDecl inductiveInfo,
      PsDeclaration.constructorDecl ctorInfo,
      PsDeclaration.recursorDecl recInfo,
      PsDeclaration.definitionDecl unwrapName [] unwrapType unwrapValue
    ] =>
      psNameEq inductiveInfo.name boxName
        && inductiveInfo.constructors.length == 1
        && psNameEq ctorInfo.name ctorName
        && ctorInfo.constructorIndex == 0
        && ctorInfo.numFields == 1
        && match ctorInfo.type with
           | PsExpr.forallE
               binderName
               binderType
               resultType
               PsBinderInfo.explicit =>
               psNameEq binderName (psTestName "x")
                 && psExprAlphaEq binderType natType
                 && psExprAlphaEq resultType
                   (PsExpr.constE boxName [])
           | _ => false
        && psNameEq recInfo.name recName
        && recInfo.numMinors == 1
        && psNameEq unwrapName (psTestName "unwrap")
        && match unwrapType, unwrapValue with
           | PsExpr.forallE
               _
               domain
               codomain
               PsBinderInfo.explicit,
             PsExpr.lam _ _ body PsBinderInfo.explicit =>
               psExprAlphaEq domain (PsExpr.constE boxName [])
                 && psExprAlphaEq codomain natType
                 && match (psExprAppView body).head with
                    | PsExpr.constE name levels =>
                        psNameEq name recName
                          && levels.length == 1
                    | _ => false
           | _, _ => false
  | _ => false

def psTestDualSourceInductiveFieldElaboration : Bool :=
  match
      psParseLeanSource
        "inductive BoxNat where | mk (x : Nat)\ndef unwrap (v : BoxNat) : Nat := match v with | BoxNat.mk x => x",
      psParseProofScriptSource
        "inductive BoxNat where { | mk(x : Nat); }; def unwrap(v : BoxNat) : Nat := match v with { | BoxNat.mk x => x };" with
  | Except.ok leanModule, Except.ok proofScriptModule =>
      match
          psElabModule psTestNatEnvironment leanModule,
          psElabModule psTestNatEnvironment proofScriptModule with
      | Except.ok leanResult, Except.ok proofScriptResult =>
          psTestSourceInductiveFieldShape leanResult
            && psTestSourceInductiveFieldShape proofScriptResult
            && psTestCoreDeclarationListsEq
              leanResult.declarations
              proofScriptResult.declarations
      | _, _ => false
  | _, _ => false

def psTestSortDeclarationShape
    (result : PsElabModuleResult) : Bool :=
  let typeSort := PsExpr.sortE (PsLevel.succ PsLevel.zero)
  let propSort := PsExpr.sortE PsLevel.zero
  match result.declarations with
  | [
      PsDeclaration.definitionDecl
        idName
        []
        idType
        idValue,
      PsDeclaration.definitionDecl
        propName
        []
        propType
        propValue
    ] =>
      psNameEq idName (psTestName "idType")
        && psExprAlphaEq
          idType
          (PsExpr.forallE
            (psTestName "α")
            typeSort
            typeSort
            PsBinderInfo.explicit)
        && psExprAlphaEq
          idValue
          (PsExpr.lam
            (psTestName "α")
            typeSort
            (PsExpr.bvar 0)
            PsBinderInfo.explicit)
        && psNameEq propName (psTestName "P")
        && psExprAlphaEq propType typeSort
        && psExprAlphaEq propValue propSort
  | _ => false

def psTestDualSourceTypePropElaboration : Bool :=
  match
      psParseLeanSource
        "def idType (α : Type) : Type := α\ndef P : Type := Prop",
      psParseProofScriptSource
        "def idType(α : Type) : Type := α; def P : Type := Prop;" with
  | Except.ok leanModule, Except.ok proofScriptModule =>
      match
          psElabModule psTestNatEnvironment leanModule,
          psElabModule psTestNatEnvironment proofScriptModule with
      | Except.ok leanResult, Except.ok proofScriptResult =>
          psTestSortDeclarationShape leanResult
            && psTestSortDeclarationShape proofScriptResult
            && psTestCoreDeclarationListsEq
              leanResult.declarations
              proofScriptResult.declarations
      | _, _ => false
  | _, _ => false

def psTestParametricInductiveShape
    (result : PsElabModuleResult) : Bool :=
  let maybeName := psTestName "Maybe"
  let noneName := psNameAppendStr maybeName "none"
  let someName := psNameAppendStr maybeName "some"
  let recName := psNameAppendStr maybeName "rec"
  let natType := PsExpr.constE psNatName []
  let maybeNat :=
    PsExpr.app (PsExpr.constE maybeName []) natType
  match result.declarations with
  | [
      PsDeclaration.inductiveDecl inductiveInfo,
      PsDeclaration.constructorDecl noneInfo,
      PsDeclaration.constructorDecl someInfo,
      PsDeclaration.recursorDecl recInfo,
      PsDeclaration.definitionDecl
        getName
        []
        getType
        getValue
    ] =>
      psNameEq inductiveInfo.name maybeName
        && inductiveInfo.numParams == 1
        && inductiveInfo.numIndices == 0
        && psNameListEq
          inductiveInfo.constructors
          [noneName, someName]
        && psNameEq noneInfo.name noneName
        && noneInfo.numParams == 1
        && noneInfo.numFields == 0
        && psNameEq someInfo.name someName
        && someInfo.numParams == 1
        && someInfo.numFields == 1
        && psNameEq recInfo.name recName
        && recInfo.numParams == 1
        && recInfo.numMinors == 2
        && psNameEq getName (psTestName "getOrZero")
        && psExprAlphaEq
          getType
          (PsExpr.forallE
            (psTestName "v")
            maybeNat
            natType
            PsBinderInfo.explicit)
        && match getValue with
           | PsExpr.lam _ _ body PsBinderInfo.explicit =>
               match (psExprAppView body).head with
               | PsExpr.constE name levels =>
                   psNameEq name recName
                     && levels.length == 1
               | _ => false
           | _ => false
  | _ => false

def psTestDualSourceParametricInductive : Bool :=
  match
      psParseLeanSource
        "inductive Maybe (α : Type) where | none | some (value : α)\ndef getOrZero (v : Maybe Nat) : Nat := match v with | Maybe.none => 0 | Maybe.some x => x",
      psParseProofScriptSource
        "inductive Maybe(α : Type) where { | none; | some(value : α); }; def getOrZero(v : Maybe(Nat)) : Nat := match v with { | Maybe.none => 0; | Maybe.some x => x };" with
  | Except.ok leanModule, Except.ok proofScriptModule =>
      match
          psElabModule psTestNatEnvironment leanModule,
          psElabModule psTestNatEnvironment proofScriptModule with
      | Except.ok leanResult, Except.ok proofScriptResult =>
          psTestParametricInductiveShape leanResult
            && psTestParametricInductiveShape proofScriptResult
            && psTestCoreDeclarationListsEq
              leanResult.declarations
              proofScriptResult.declarations
      | _, _ => false
  | _, _ => false


def psTestImplicitConstructorApplicationShape
    (result : PsElabModuleResult) : Bool :=
  let maybeName := psTestName "Maybe"
  let noneName := psNameAppendStr maybeName "none"
  let someName := psNameAppendStr maybeName "some"
  let natType := PsExpr.constE psNatName []
  let maybeNat :=
    PsExpr.app (PsExpr.constE maybeName []) natType
  let expectedPresent :=
    PsExpr.app
      (PsExpr.app
        (PsExpr.constE someName [])
        natType)
      (PsExpr.lit (PsLiteral.natural 1))
  let expectedAbsent :=
    PsExpr.app
      (PsExpr.constE noneName [])
      natType
  match result.declarations with
  | [
      PsDeclaration.inductiveDecl _,
      PsDeclaration.constructorDecl _,
      PsDeclaration.constructorDecl _,
      PsDeclaration.recursorDecl _,
      PsDeclaration.definitionDecl
        presentName
        []
        presentType
        presentValue,
      PsDeclaration.definitionDecl
        absentName
        []
        absentType
        absentValue
    ] =>
      psNameEq presentName (psTestName "present")
        && psExprAlphaEq presentType maybeNat
        && psExprAlphaEq presentValue expectedPresent
        && psNameEq absentName (psTestName "absent")
        && psExprAlphaEq absentType maybeNat
        && psExprAlphaEq absentValue expectedAbsent
  | _ => false

def psTestLeanImplicitConstructorElaborates : Bool :=
  match psParseLeanSource
      "inductive Maybe (α : Type) where | none | some (value : α)\ndef present : Maybe Nat := Maybe.some 1\ndef absent : Maybe Nat := Maybe.none" with
  | Except.error _ => false
  | Except.ok module =>
      match psElabModule psTestNatEnvironment module with
      | Except.ok _ => true
      | Except.error _ => false

def psTestProofScriptImplicitConstructorElaborates : Bool :=
  match psParseProofScriptSource
      "inductive Maybe(α : Type) where { | none; | some(value : α); }; def present : Maybe(Nat) := Maybe.some(1); def absent : Maybe(Nat) := Maybe.none;" with
  | Except.error _ => false
  | Except.ok module =>
      match psElabModule psTestNatEnvironment module with
      | Except.ok _ => true
      | Except.error _ => false

def psTestLeanImplicitConstructorApplication : Bool :=
  match psParseLeanSource
      "inductive Maybe (α : Type) where | none | some (value : α)\ndef present : Maybe Nat := Maybe.some 1\ndef absent : Maybe Nat := Maybe.none" with
  | Except.error _ => false
  | Except.ok module =>
      match psElabModule psTestNatEnvironment module with
      | Except.error _ => false
      | Except.ok result =>
          psTestImplicitConstructorApplicationShape result

def psTestProofScriptImplicitConstructorApplication : Bool :=
  match psParseProofScriptSource
      "inductive Maybe(α : Type) where { | none; | some(value : α); }; def present : Maybe(Nat) := Maybe.some(1); def absent : Maybe(Nat) := Maybe.none;" with
  | Except.error _ => false
  | Except.ok module =>
      match psElabModule psTestNatEnvironment module with
      | Except.error _ => false
      | Except.ok result =>
          psTestImplicitConstructorApplicationShape result

def psTestDualSourceImplicitConstructorApplication : Bool :=
  match
      psParseLeanSource
        "inductive Maybe (α : Type) where | none | some (value : α)\ndef present : Maybe Nat := Maybe.some 1\ndef absent : Maybe Nat := Maybe.none",
      psParseProofScriptSource
        "inductive Maybe(α : Type) where { | none; | some(value : α); }; def present : Maybe(Nat) := Maybe.some(1); def absent : Maybe(Nat) := Maybe.none;" with
  | Except.ok leanModule, Except.ok proofScriptModule =>
      match
          psElabModule psTestNatEnvironment leanModule,
          psElabModule psTestNatEnvironment proofScriptModule with
      | Except.ok leanResult, Except.ok proofScriptResult =>
          psTestImplicitConstructorApplicationShape leanResult
            && psTestImplicitConstructorApplicationShape proofScriptResult
            && psTestCoreDeclarationListsEq
              leanResult.declarations
              proofScriptResult.declarations
      | _, _ => false
  | _, _ => false

def psRecursiveListLeanSource : String :=
  "inductive List1 (α : Type) where | nil | cons (head : α) (tail : List1 α)\n" ++
  "def length1 (xs : List1 Nat) : Nat := " ++
  "match xs with | List1.nil => 0 | List1.cons head tail => length1 tail"

def psRecursiveListProofScriptSource : String :=
  "inductive List1(α : Type) where { | nil; | cons(head : α)(tail : List1(α)); }; " ++
  "def length1(xs : List1(Nat)) : Nat := " ++
  "match xs with { | List1.nil => 0; | List1.cons head tail => length1(tail); };"

def psTestDualSourceStructuralRecursion : Bool :=
  match
      psParseLeanSource psRecursiveListLeanSource,
      psParseProofScriptSource psRecursiveListProofScriptSource with
  | Except.ok leanModule, Except.ok proofScriptModule =>
      match
          psElabModule psTestNatEnvironment leanModule,
          psElabModule psTestNatEnvironment proofScriptModule with
      | Except.ok leanResult, Except.ok proofScriptResult =>
          psTestCoreDeclarationListsEq
            leanResult.declarations
            proofScriptResult.declarations
            && match leanResult.declarations.reverse with
               | PsDeclaration.definitionDecl _ _ _ value :: _ =>
                   !psExprHasConst (psTestName "length1") value
               | _ => false
      | _, _ => false
  | _, _ => false

def psTestRejectNonDecreasingStructuralRecursion : Bool :=
  let source :=
    "inductive ListBad (α : Type) where | nil | cons (head : α) (tail : ListBad α)\n" ++
    "def bad (xs : ListBad Nat) : Nat := " ++
    "match xs with | ListBad.nil => 0 | ListBad.cons head tail => bad xs"
  match psParseLeanSource source with
  | Except.error _ => false
  | Except.ok module =>
      match psElabModule psTestNatEnvironment module with
      | Except.error PsElabError.structuralRecursionNotDecreasing => true
      | _ => false

def psTestRejectChangedInvariantStructuralRecursion : Bool :=
  let source :=
    "inductive ListInv (α : Type) where | nil | cons (head : α) (tail : ListInv α)\n" ++
    "def badInv (base : Nat) (xs : ListInv Nat) : Nat := " ++
    "match xs with | ListInv.nil => base | ListInv.cons head tail => badInv head tail"
  match psParseLeanSource source with
  | Except.error _ => false
  | Except.ok module =>
      match psElabModule psTestNatEnvironment module with
      | Except.error PsElabError.structuralRecursionInvariantArgument => true
      | _ => false

def psTestDualSourcePartialDefinition : Bool :=
  match
      psParseLeanSource
        "partial def loop (n : Nat) : Nat := loop n",
      psParseProofScriptSource
        "partial def loop(n : Nat) : Nat := loop(n);" with
  | Except.ok leanModule, Except.ok proofScriptModule =>
      match
          psElabModule psTestNatEnvironment leanModule,
          psElabModule psTestNatEnvironment proofScriptModule with
      | Except.ok leanResult, Except.ok proofScriptResult =>
          psTestCoreDeclarationListsEq
              leanResult.declarations
              proofScriptResult.declarations
            && match leanResult.declarations with
               | [declaration@(PsDeclaration.partialDecl name [] type value)] =>
                   psNameEq name (psTestName "loop")
                     && psExprHasConst (psTestName "loop") value
                     && (match psDeclarationValue declaration with
                         | none => true
                         | some _ => false)
                     && match type with
                        | PsExpr.forallE _ _ _ PsBinderInfo.explicit => true
                        | _ => false
               | _ => false
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
  { name := "dual-source typed lambda parse", passed := psTestDualSourceTypedLambdaParse },
  { name := "dual-source typed lambda elaboration", passed := psTestDualSourceTypedLambdaElaboration },
  { name := "dual-source Pi parse", passed := psTestDualSourcePiParse },
  { name := "dual-source Pi lambda declaration", passed := psTestDualSourcePiLambdaDeclaration },
  { name := "dual-source annotated let", passed := psTestDualSourceAnnotatedLet },
  { name := "dual-source inferred let", passed := psTestDualSourceInferredLet },
  { name := "dual-source Bool literal", passed := psTestDualSourceBoolLiteral },
  { name := "dual-source if", passed := psTestDualSourceIf },
  { name := "inductive metadata lookup", passed := psTestInductiveMetadataLookup },
  { name := "bootstrap List/Option type constructors", passed := psTestPreludeCollectionTypeConstructors },
  { name := "Lean product inside application parse", passed := psTestLeanProductInsideApplicationParse },
  { name := "dual-source basic match parse", passed := psTestDualSourceBasicMatchParse },
  { name := "Lean nested match dedent parse", passed := psTestLeanNestedMatchDedentParse },
  { name := "constructor match pattern parse", passed := psTestConstructorMatchPatternShape },
  { name := "dual-source basic match elaboration", passed := psTestDualSourceBasicMatchElaboration },
  { name := "dual-source field match elaboration", passed := psTestDualSourceFieldMatchElaboration },
  { name := "defeq beta under forall", passed := psTestDefEqBetaUnderForall },
  { name := "dual-source inductive enum parse", passed := psTestDualSourceInductiveEnumParse },
  { name := "dual-source inductive field parse", passed := psTestDualSourceInductiveFieldParse },
  { name := "dual-source inductive enum elaboration", passed := psTestDualSourceInductiveEnumElaboration },
  { name := "dual-source inductive field elaboration", passed := psTestDualSourceInductiveFieldElaboration },
  { name := "dual-source Type Prop elaboration", passed := psTestDualSourceTypePropElaboration },
  { name := "dual-source parametric inductive", passed := psTestDualSourceParametricInductive },
  { name := "Lean implicit constructor elaborates", passed := psTestLeanImplicitConstructorElaborates },
  { name := "ProofScript implicit constructor elaborates", passed := psTestProofScriptImplicitConstructorElaborates },
  { name := "Lean implicit constructor application", passed := psTestLeanImplicitConstructorApplication },
  { name := "ProofScript implicit constructor application", passed := psTestProofScriptImplicitConstructorApplication },
  { name := "dual-source implicit constructor application", passed := psTestDualSourceImplicitConstructorApplication },
  { name := "dual-source structural recursion", passed := psTestDualSourceStructuralRecursion },
  { name := "dual-source controlled partial definition", passed := psTestDualSourcePartialDefinition },
  { name := "reject non-decreasing structural recursion", passed := psTestRejectNonDecreasingStructuralRecursion },
  { name := "reject changed invariant structural recursion", passed := psTestRejectChangedInvariantStructuralRecursion },
  { name := "dual-source String literal", passed := psTestDualSourceStringLiteral },
  { name := "reject invalid String escapes", passed := psTestRejectInvalidStringEscapes },
  { name := "dual-source grouping", passed := psTestDualSourceGrouping },
  { name := "dual-source Unit", passed := psTestDualSourceUnit },
  { name := "Lean parenthesized application", passed := psTestLeanParenthesizedApplication },
  { name := "dual-source Char literal", passed := psTestDualSourceCharLiteral },
  { name := "reject invalid Char escapes", passed := psTestRejectInvalidCharacterEscapes },
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
