import Ps.Syntax.Translate
import Ps.Bridge.CheckedAdmissions
import Ps.Elab.Declaration
import Ps.Erasure.Basic
import Ps.CompilerIr.Model

inductive PsCompilerSourceKind where
  | lean
  | proofScript

inductive PsCompilerError where
  | translation (error : PsTranslationError)
  | leanFrontend (error : PsLeanFrontendError)
  | proofScriptFrontend (error : PsProofScriptFrontendError)
  | elaboration (error : PsElabError)
  | admission (error : PsCheckedAdmissionCodecError)
  | erasure (error : PsErasureError)
  | irValidation (error : PsVerifiedIrValidationError)

structure PsCompilerAdmissionReadyModule where
  declarations : List PsDeclaration

