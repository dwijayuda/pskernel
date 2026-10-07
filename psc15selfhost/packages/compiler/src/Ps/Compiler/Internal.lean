import Ps.Compiler.Origins
import Ps.Erasure.Definition
import Ps.CompilerIr.Validate
import Ps.CompilerIr.PublicApiEncode

-- Unchecked transformation implementation. Only bootstrap drivers and the trusted
-- checked host composition may invoke this layer; candidate preparation cannot.
def psCompilerEnvironmentFromPrepared
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerError PsEnvironment :=
  match psCompilerValidatePrepared prepared with
  | Except.error error =>
      Except.error error
  | Except.ok _ =>
      match
          psAddDeclarationList
            psSelfHostProdPreludeEnvironment
            prepared.declarations with
      | Except.error error =>
          Except.error (PsCompilerError.elaboration error)
      | Except.ok environment =>
          Except.ok environment

def psCompilerErasedIrFromPrepared
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerError PsErasedIrModule :=
  match psCompilerEnvironmentFromPrepared prepared with
  | Except.error error =>
      Except.error error
  | Except.ok environment =>
      match
          psEraseCoreModuleWithRuntimePrelude
            environment
            psSelfHostRuntimePreludeDeclarationsWithProd
            prepared.declarations with
      | Except.error error =>
          Except.error (PsCompilerError.erasure error)
      | Except.ok ir =>
          Except.ok (PsErasedIrModule.mk ir)

def psCompilerVerifiedIrFromPrepared
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerError PsValidatedIrModule :=
  match psCompilerErasedIrFromPrepared prepared with
  | Except.error error =>
      Except.error error
  | Except.ok erased =>
      match psValidateErasedIrModule erased with
      | Except.error error =>
          Except.error (PsCompilerError.irValidation error)
      | Except.ok validated =>
          Except.ok validated

def psCompilerVerifiedIrFromElaborated
    (elaborated : PsElabModuleResult) :
    Except PsCompilerError PsValidatedIrModule :=
  match psCompilerPrepareElaborated elaborated with
  | Except.error error =>
      Except.error error
  | Except.ok prepared =>
      psCompilerVerifiedIrFromPrepared prepared

def psCompilerVerifiedIrSource
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerError PsValidatedIrModule :=
  match psCompilerPrepareSource sourceKind source with
  | Except.error error =>
      Except.error error
  | Except.ok prepared =>
      psCompilerVerifiedIrFromPrepared prepared

-- Exact source-semantic projection before erasure/specialization. Like every
-- Internal transform, this is candidate data until selected by a live host
-- checked session; the JSON itself carries no authority.
def psCompilerPublicApiFromPrepared
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerError String :=
  match psPublicApiEncodeModule (psPublicApiProjectModule prepared.declarations) with
  | Except.error error =>
      Except.error (PsCompilerError.admission error)
  | Except.ok encoded =>
      Except.ok encoded

-- Actual source-declaration to RuntimeIR-declaration inventory. This records
-- names/dispositions, not expression correspondence or preservation evidence.
structure PsCompilerErasureProduct where
  erased : PsErasedIrModule
  correspondence : String

def psCompilerErasureDispositionJson
    (disposition : PsErasureDeclarationDisposition) : String :=
  match disposition with
  | PsErasureDeclarationDisposition.runtime name =>
      psJsonArray [psJsonQuote "runtime", psJsonQuote name]
  | PsErasureDeclarationDisposition.proofErased =>
      psJsonArray [psJsonQuote "proof-erased"]
  | PsErasureDeclarationDisposition.noRuntimeDeclaration =>
      psJsonArray [psJsonQuote "no-runtime-declaration"]

def psCompilerErasureCorrespondenceEntries
    (entries : List PsErasureDeclarationCorrespondence) : List String :=
  match entries with
  | List.nil => List.nil
  | List.cons entry rest =>
      List.cons
        (psJsonArray [
          psEncodeCodecName entry.sourceName,
          psCompilerErasureDispositionJson entry.disposition
        ])
        (psCompilerErasureCorrespondenceEntries rest)

def psCompilerErasureProductFromPrepared
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerError PsCompilerErasureProduct :=
  match psCompilerEnvironmentFromPrepared prepared with
  | Except.error error => Except.error error
  | Except.ok environment =>
      match
          psEraseCoreModuleObserved
            true
            environment
            psSelfHostRuntimePreludeDeclarationsWithProd
            prepared.declarations with
      | Except.error error => Except.error (PsCompilerError.erasure error)
      | Except.ok product =>
          Except.ok
            (PsCompilerErasureProduct.mk
              (PsErasedIrModule.mk product.raw)
              (psJsonArray [
                psJsonQuote "psc-erasure-declarations/1",
                psJsonQuote "declaration-inventory",
                psJsonArray
                  (psCompilerErasureCorrespondenceEntries product.correspondence)
              ]))
