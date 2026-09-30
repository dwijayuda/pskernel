import Ps.Environment.Prelude
import Ps.KernelCore

inductive PsCompilerKernelShadowError where
  | universeMetavariable
  | freeVariable
  | expressionMetavariable
  | unsupportedDeclaration
  | duplicatePreludeAssumption
  | kernelRejected (message : String)

structure PsCompilerKernelShadowReport where
  checkedDeclarations : Nat

def psCompilerKernelShadowName
    (name : PsName) : PsKernelCoreName :=
  match name with
  | PsName.anonymous => PsKernelCoreName.anonymous
  | PsName.str parent value =>
      PsKernelCoreName.str
        (psCompilerKernelShadowName parent)
        value
  | PsName.num parent value =>
      PsKernelCoreName.num
        (psCompilerKernelShadowName parent)
        value

def psCompilerKernelShadowNames
    (names : List PsName) :
    PsKernelCoreList PsKernelCoreName :=
  match names with
  | List.nil => PsKernelCoreList.nil
  | List.cons head tail =>
      PsKernelCoreList.cons
        (psCompilerKernelShadowName head)
        (psCompilerKernelShadowNames tail)

def psCompilerKernelShadowLevel
    (level : PsLevel) :
    Except PsCompilerKernelShadowError PsKernelCoreLevel :=
  match level with
  | PsLevel.zero => Except.ok PsKernelCoreLevel.zero
  | PsLevel.succ child =>
      match psCompilerKernelShadowLevel child with
      | Except.error error => Except.error error
      | Except.ok converted =>
          Except.ok (PsKernelCoreLevel.succ converted)
  | PsLevel.max left right =>
      match psCompilerKernelShadowLevel left with
      | Except.error error => Except.error error
      | Except.ok convertedLeft =>
          match psCompilerKernelShadowLevel right with
          | Except.error error => Except.error error
          | Except.ok convertedRight =>
              Except.ok
                (PsKernelCoreLevel.max convertedLeft convertedRight)
  | PsLevel.imax left right =>
      match psCompilerKernelShadowLevel left with
      | Except.error error => Except.error error
      | Except.ok convertedLeft =>
          match psCompilerKernelShadowLevel right with
          | Except.error error => Except.error error
          | Except.ok convertedRight =>
              Except.ok
                (PsKernelCoreLevel.imax convertedLeft convertedRight)
  | PsLevel.param name =>
      Except.ok
        (PsKernelCoreLevel.param
          (psCompilerKernelShadowName name))
  | PsLevel.mvar _ =>
      Except.error PsCompilerKernelShadowError.universeMetavariable

def psCompilerKernelShadowLevels
    (levels : List PsLevel) :
    Except PsCompilerKernelShadowError
      (PsKernelCoreList PsKernelCoreLevel) :=
  match levels with
  | List.nil => Except.ok PsKernelCoreList.nil
  | List.cons head tail =>
      match psCompilerKernelShadowLevel head with
      | Except.error error => Except.error error
      | Except.ok convertedHead =>
          match psCompilerKernelShadowLevels tail with
          | Except.error error => Except.error error
          | Except.ok convertedTail =>
              Except.ok
                (PsKernelCoreList.cons convertedHead convertedTail)

def psCompilerKernelShadowBinderInfo
    (binderInfo : PsBinderInfo) : PsKernelCoreBinderInfo :=
  match binderInfo with
  | PsBinderInfo.explicit => PsKernelCoreBinderInfo.default
  | PsBinderInfo.implicit => PsKernelCoreBinderInfo.implicit
  | PsBinderInfo.strictImplicit => PsKernelCoreBinderInfo.strictImplicit
  | PsBinderInfo.instanceImplicit => PsKernelCoreBinderInfo.instImplicit

def psCompilerKernelShadowLiteral
    (literal : PsLiteral) : PsKernelCoreLiteral :=
  match literal with
  | PsLiteral.natural value => PsKernelCoreLiteral.nat value
  | PsLiteral.string value => PsKernelCoreLiteral.str value

def psCompilerKernelShadowExpr
    (expr : PsExpr) :
    Except PsCompilerKernelShadowError PsKernelCoreExpr :=
  match expr with
  | PsExpr.bvar index =>
      Except.ok (PsKernelCoreExpr.bvar index)
  | PsExpr.fvar _ =>
      Except.error PsCompilerKernelShadowError.freeVariable
  | PsExpr.mvar _ =>
      Except.error PsCompilerKernelShadowError.expressionMetavariable
  | PsExpr.sortE level =>
      match psCompilerKernelShadowLevel level with
      | Except.error error => Except.error error
      | Except.ok converted =>
          Except.ok (PsKernelCoreExpr.sort converted)
  | PsExpr.constE name levels =>
      match psCompilerKernelShadowLevels levels with
      | Except.error error => Except.error error
      | Except.ok convertedLevels =>
          Except.ok
            (PsKernelCoreExpr.const
              (psCompilerKernelShadowName name)
              convertedLevels)
  | PsExpr.app fn arg =>
      match psCompilerKernelShadowExpr fn with
      | Except.error error => Except.error error
      | Except.ok convertedFn =>
          match psCompilerKernelShadowExpr arg with
          | Except.error error => Except.error error
          | Except.ok convertedArg =>
              Except.ok
                (PsKernelCoreExpr.app convertedFn convertedArg)
  | PsExpr.lam name type body binderInfo =>
      match psCompilerKernelShadowExpr type with
      | Except.error error => Except.error error
      | Except.ok convertedType =>
          match psCompilerKernelShadowExpr body with
          | Except.error error => Except.error error
          | Except.ok convertedBody =>
              Except.ok
                (PsKernelCoreExpr.lam
                  (psCompilerKernelShadowName name)
                  convertedType
                  convertedBody
                  (psCompilerKernelShadowBinderInfo binderInfo))
  | PsExpr.forallE name type body binderInfo =>
      match psCompilerKernelShadowExpr type with
      | Except.error error => Except.error error
      | Except.ok convertedType =>
          match psCompilerKernelShadowExpr body with
          | Except.error error => Except.error error
          | Except.ok convertedBody =>
              Except.ok
                (PsKernelCoreExpr.forallE
                  (psCompilerKernelShadowName name)
                  convertedType
                  convertedBody
                  (psCompilerKernelShadowBinderInfo binderInfo))
  | PsExpr.letE name type value body =>
      match psCompilerKernelShadowExpr type with
      | Except.error error => Except.error error
      | Except.ok convertedType =>
          match psCompilerKernelShadowExpr value with
          | Except.error error => Except.error error
          | Except.ok convertedValue =>
              match psCompilerKernelShadowExpr body with
              | Except.error error => Except.error error
              | Except.ok convertedBody =>
                  Except.ok
                    (PsKernelCoreExpr.letE
                      (psCompilerKernelShadowName name)
                      convertedType
                      convertedValue
                      convertedBody
                      false)
  | PsExpr.lit literal =>
      Except.ok
        (PsKernelCoreExpr.lit
          (psCompilerKernelShadowLiteral literal))
  | PsExpr.proj typeName index value =>
      match psCompilerKernelShadowExpr value with
      | Except.error error => Except.error error
      | Except.ok convertedValue =>
          Except.ok
            (PsKernelCoreExpr.proj
              (psCompilerKernelShadowName typeName)
              index
              convertedValue)

def psCompilerKernelShadowBase
    (declaration : PsDeclaration) :
    Except PsCompilerKernelShadowError PsKernelCoreConstantBase :=
  match psCompilerKernelShadowExpr (psDeclarationType declaration) with
  | Except.error error => Except.error error
  | Except.ok convertedType =>
      Except.ok {
        name :=
          psCompilerKernelShadowName
            (psDeclarationName declaration)
        levelParams :=
          psCompilerKernelShadowNames
            (psDeclarationLevelParams declaration)
        type := convertedType
      }

def psCompilerKernelShadowAssumptionEnvironmentWorker
    (declarations : List PsDeclaration) :
    PsKernelCoreEnvironment ->
    Except PsCompilerKernelShadowError PsKernelCoreEnvironment :=
  match declarations with
  | List.nil =>
      fun (environment : PsKernelCoreEnvironment) =>
        Except.ok environment
  | List.cons declaration rest =>
      let smaller :
          PsKernelCoreEnvironment ->
          Except PsCompilerKernelShadowError PsKernelCoreEnvironment :=
        psCompilerKernelShadowAssumptionEnvironmentWorker rest;
      fun (environment : PsKernelCoreEnvironment) =>
        match psCompilerKernelShadowBase declaration with
        | Except.error error => Except.error error
        | Except.ok base =>
            if psKernelCoreEnvironmentContains environment base.name then
              Except.error
                PsCompilerKernelShadowError.duplicatePreludeAssumption
            else
              let assumption : PsKernelCoreAxiomInfo := {
                base := base
                isUnsafe := false
              };
              let next :=
                psKernelCoreEnvironmentAddUnchecked
                  environment
                  (PsKernelCoreConstantInfo.axiomInfo assumption);
              smaller next

def psCompilerKernelShadowAssumptionEnvironment
    (declarations : List PsDeclaration) :
    Except PsCompilerKernelShadowError PsKernelCoreEnvironment :=
  psCompilerKernelShadowAssumptionEnvironmentWorker
    declarations
    psKernelCoreEnvironmentEmpty

def psCompilerKernelShadowPreludeEnvironment :
    Except PsCompilerKernelShadowError PsKernelCoreEnvironment :=
  psCompilerKernelShadowAssumptionEnvironment
    psBootstrapPreludeEnvironment.declarations

def psCompilerKernelShadowKernelResult
    (result : PsKernelCoreResult String PsKernelCoreEnvironment) :
    Except PsCompilerKernelShadowError PsKernelCoreEnvironment :=
  match result with
  | PsKernelCoreResult.error message =>
      Except.error (PsCompilerKernelShadowError.kernelRejected message)
  | PsKernelCoreResult.ok environment =>
      Except.ok environment

def psCompilerKernelShadowCheckDefinition
    (environment : PsKernelCoreEnvironment)
    (name : PsName)
    (levelParams : List PsName)
    (type value : PsExpr) :
    Except PsCompilerKernelShadowError PsKernelCoreEnvironment :=
  match psCompilerKernelShadowExpr type with
  | Except.error error => Except.error error
  | Except.ok convertedType =>
      match psCompilerKernelShadowExpr value with
      | Except.error error => Except.error error
      | Except.ok convertedValue =>
          let base : PsKernelCoreConstantBase := {
            name := psCompilerKernelShadowName name
            levelParams := psCompilerKernelShadowNames levelParams
            type := convertedType
          };
          let definition : PsKernelCoreDefinitionInfo := {
            base := base
            value := convertedValue
            hints := PsKernelCoreReducibilityHints.regular 0
            safety := PsKernelCoreDefinitionSafety.safe
          };
          psCompilerKernelShadowKernelResult
            (psKernelCoreAddDefinition 4096 environment definition)

def psCompilerKernelShadowCheckTheorem
    (environment : PsKernelCoreEnvironment)
    (name : PsName)
    (levelParams : List PsName)
    (type value : PsExpr) :
    Except PsCompilerKernelShadowError PsKernelCoreEnvironment :=
  match psCompilerKernelShadowExpr type with
  | Except.error error => Except.error error
  | Except.ok convertedType =>
      match psCompilerKernelShadowExpr value with
      | Except.error error => Except.error error
      | Except.ok convertedValue =>
          let base : PsKernelCoreConstantBase := {
            name := psCompilerKernelShadowName name
            levelParams := psCompilerKernelShadowNames levelParams
            type := convertedType
          };
          let theoremInfo : PsKernelCoreTheoremInfo := {
            base := base
            value := convertedValue
          };
          psCompilerKernelShadowKernelResult
            (psKernelCoreAddTheorem 4096 environment theoremInfo)

def psCompilerKernelShadowCheckDeclarationsWorker
    (declarations : List PsDeclaration) :
    PsKernelCoreEnvironment ->
    Nat ->
    Except PsCompilerKernelShadowError PsCompilerKernelShadowReport :=
  match declarations with
  | List.nil =>
      fun (_environment : PsKernelCoreEnvironment) (count : Nat) =>
        Except.ok { checkedDeclarations := count }
  | List.cons declaration rest =>
      let smaller :
          PsKernelCoreEnvironment ->
          Nat ->
          Except PsCompilerKernelShadowError PsCompilerKernelShadowReport :=
        psCompilerKernelShadowCheckDeclarationsWorker rest;
      fun (environment : PsKernelCoreEnvironment) (count : Nat) =>
        let nextResult :=
          match declaration with
          | PsDeclaration.definitionDecl name levelParams type value =>
              psCompilerKernelShadowCheckDefinition
                environment name levelParams type value
          | PsDeclaration.theoremDecl name levelParams type value =>
              psCompilerKernelShadowCheckTheorem
                environment name levelParams type value
          | _ =>
              Except.error
                PsCompilerKernelShadowError.unsupportedDeclaration;
        match nextResult with
        | Except.error error => Except.error error
        | Except.ok next => smaller next (Nat.succ count)

def psCompilerKernelShadowCheckDeclarations
    (declarations : List PsDeclaration) :
    Except PsCompilerKernelShadowError PsCompilerKernelShadowReport :=
  match psCompilerKernelShadowPreludeEnvironment with
  | Except.error error => Except.error error
  | Except.ok environment =>
      psCompilerKernelShadowCheckDeclarationsWorker
        declarations
        environment
        0
