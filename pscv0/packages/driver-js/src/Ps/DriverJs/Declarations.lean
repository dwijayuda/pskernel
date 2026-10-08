import Ps.Compiler.Model
import Ps.InterfaceTs.Request

-- Bootstrap transform entry. A serialized request grants no checking authority;
-- production calls this only through the live checked-session boundary.
def psCompilerJavaScriptDeclarationsFromPrepared
    (request : String) (prepared : PsCompilerAdmissionReadyModule) :
    Except PsTsDeclarationRequestError String :=
  match psTsDecodeDeclarationCommand request with
  | Except.error error => Except.error error
  | Except.ok command =>
      match psTsEmitDeclarationsWithLimits command.profile 1000000 command.maxBytes
          (psPublicApiProjectModule prepared.declarations) command.requests with
      | Except.error error => Except.error (PsTsDeclarationRequestError.emit error)
      | Except.ok output => Except.ok output
