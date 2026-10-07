import Ps.Compiler.Candidate

-- Side table only; source identity and checked capability binding belong to
-- the host. Source indices refer to the exact ordered preparation inputs.
structure PsCompilerDeclarationOrigin where
  sourceIndex : Nat
  declarationName : PsName
  sourceSpan : PsSourceSpan

structure PsCompilerOriginPreparationState where
  environment : PsEnvironment
  declarationsRev : List PsDeclaration
  originsRev : List PsCompilerDeclarationOrigin
  sourceCount : Nat

structure PsCompilerPreparedOriginProduct where
  prepared : PsCompilerAdmissionReadyModule
  origins : String

def psCompilerPrependSourceOrigins
    (sourceIndex : Nat)
    (origins : List PsElabDeclarationOrigin) :
    List PsCompilerDeclarationOrigin -> List PsCompilerDeclarationOrigin :=
  match origins with
  | List.nil =>
      fun (originsRev : List PsCompilerDeclarationOrigin) => originsRev
  | List.cons origin rest =>
      let smaller :
          List PsCompilerDeclarationOrigin -> List PsCompilerDeclarationOrigin :=
        psCompilerPrependSourceOrigins sourceIndex rest;
      fun (originsRev : List PsCompilerDeclarationOrigin) =>
        smaller
          (List.cons
            (PsCompilerDeclarationOrigin.mk
              sourceIndex
              origin.declarationName
              origin.sourceSpan)
            originsRev)

def psCompilerOriginPosition (position : PsSourcePos) : String :=
  psJsonArray [
    psCheckedAdmissionNatToString position.byteOffset,
    psCheckedAdmissionNatToString position.line,
    psCheckedAdmissionNatToString position.column
  ]

def psCompilerEncodeDeclarationOrigins
    (origins : List PsCompilerDeclarationOrigin) : List String :=
  match origins with
  | List.nil => List.nil
  | List.cons origin rest =>
      List.cons
        (psJsonArray [
          psCheckedAdmissionNatToString origin.sourceIndex,
          psEncodeCodecName origin.declarationName,
          psCompilerOriginPosition origin.sourceSpan.start,
          psCompilerOriginPosition origin.sourceSpan.stop
        ])
        (psCompilerEncodeDeclarationOrigins rest)

def psCompilerFinishOriginPreparation
    (state : PsCompilerOriginPreparationState) :
    Except PsCompilerError PsCompilerPreparedOriginProduct :=
  match
      psCompilerPrepareElaborated
        (PsElabModuleResult.mk
          state.environment
          (psListReverse state.declarationsRev)) with
  | Except.error error => Except.error error
  | Except.ok prepared =>
      Except.ok
        (PsCompilerPreparedOriginProduct.mk
          prepared
          (psJsonArray [
            psJsonQuote "psc-declaration-origins/1",
            psJsonQuote "declaration-batch",
            psCheckedAdmissionNatToString state.sourceCount,
            psJsonArray
              (psCompilerEncodeDeclarationOrigins
                (psListReverse state.originsRev))
          ]))

def psCompilerPrepareOriginSourceStep
    (sourceKind : PsCompilerSourceKind)
    (state : PsCompilerOriginPreparationState)
    (source : String) :
    Except PsCompilerError PsCompilerOriginPreparationState :=
  match psCompilerParseSource sourceKind source with
  | Except.error error => Except.error error
  | Except.ok sourceModule =>
      match psElabModuleWithOrigins state.environment sourceModule with
      | Except.error error => Except.error (PsCompilerError.elaboration error)
      | Except.ok elaborated =>
          Except.ok
            (PsCompilerOriginPreparationState.mk
              elaborated.semantic.environment
              (psListAppend
                (psListReverse elaborated.semantic.declarations)
                state.declarationsRev)
              (psCompilerPrependSourceOrigins
                state.sourceCount
                elaborated.origins
                state.originsRev)
              (Nat.succ state.sourceCount))

def psCompilerPrepareOriginsWorker
    (sourceKind : PsCompilerSourceKind)
    (sources : List String) :
    PsCompilerOriginPreparationState ->
    Except PsCompilerError PsCompilerPreparedOriginProduct :=
  match sources with
  | List.nil =>
      fun (state : PsCompilerOriginPreparationState) =>
        psCompilerFinishOriginPreparation state
  | List.cons source rest =>
      let smaller :
          PsCompilerOriginPreparationState ->
          Except PsCompilerError PsCompilerPreparedOriginProduct :=
        psCompilerPrepareOriginsWorker sourceKind rest;
      fun (state : PsCompilerOriginPreparationState) =>
        match psCompilerPrepareOriginSourceStep sourceKind state source with
        | Except.error error => Except.error error
        | Except.ok next => smaller next

def psCompilerPrepareSourcesWithOrigins
    (sourceKind : PsCompilerSourceKind)
    (sources : List String) :
    Except PsCompilerError PsCompilerPreparedOriginProduct :=
  psCompilerPrepareOriginsWorker
    sourceKind
    sources
    (PsCompilerOriginPreparationState.mk
      psSelfHostProdPreludeEnvironment
      List.nil
      List.nil
      0)

def psCompilerPrepareSourceWithOrigins
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerError PsCompilerPreparedOriginProduct :=
  psCompilerPrepareSourcesWithOrigins sourceKind (List.cons source List.nil)
