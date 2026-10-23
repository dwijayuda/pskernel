import Ps.Compiler.Service

private def require (name : String) (condition : Bool) : IO Unit := do
  if !condition then throw (IO.userError ("PSC1_TARGET_PLAN_PROFILE_FAIL: " ++ name))
  IO.println ("PSC1_TARGET_PLAN_PROFILE_PASS: " ++ name)

def main : IO Unit := do
  let stringT : PsVerifiedIrType := .primitive .string
  let natT : PsVerifiedIrType := .primitive .nat
  let alpha : PsVerifiedIrType := .typeParameter "A"
  let helper : PsVerifiedIrDeclaration := .mk "helper" [.mk "A"] [.mk "value" alpha]
    (.function [natT] alpha) (.lambda [.mk "count" natT] alpha (.var "value"))
  let entry : PsVerifiedIrDeclaration := .mk "entry" [] [.mk "value" stringT] stringT
    (.call (.call (.var "helper") [stringT] [.var "value"]) [] [.literal (.natural 0)])
  let generic : PsVerifiedIrDeclaration := .mk "identity" [.mk "A"] [.mk "value" alpha] alpha (.var "value")
  let callback : PsVerifiedIrDeclaration := .mk "callback" []
    [.mk "f" (.function [natT] natT),.mk "x" natT] natT (.call (.var "f") [] [.var "x"])
  let raw : PsVerifiedIrModule := .mk [] [] [] [helper,entry,generic,callback]
  let source ← match psStrictValidateModule raw with
    | .error _ => throw (IO.userError "PSC1_TARGET_PLAN_PROFILE_IR_INVALID")
    | .ok value => pure value
  require "scalar selected interface chooses closed eligibility"
    (Ps.Internal.CompilerService.scalarInterface ["entry"] raw.declarations)
  require "open public generic interface keeps generic eligibility"
    (!Ps.Internal.CompilerService.scalarInterface ["identity"] raw.declarations)
  require "public callback ABI keeps existing eligibility"
    (!Ps.Internal.CompilerService.scalarInterface ["callback"] raw.declarations)
  require "empty public interface keeps existing eligibility"
    (!Ps.Internal.CompilerService.scalarInterface [] raw.declarations)
  for target in [PsBackendTarget.rust,PsBackendTarget.ts] do
    let planned ← match Ps.Internal.CompilerService.targetPlan target source ["entry"] with
      | .error _ => throw (IO.userError "PSC1_TARGET_PLAN_PROFILE_CLOSED_FAILED")
      | .ok value => pure value
    require "closed scalar program contains no open generic declarations"
      (!planned.raw.declarations.any (fun d => !d.typeParameters.isEmpty))
    let preserved ← match Ps.Internal.CompilerService.targetPlan target source ["identity"] with
      | .error _ => throw (IO.userError "PSC1_TARGET_PLAN_PROFILE_GENERIC_FAILED")
      | .ok value => pure value
    require "public generic signature remains present"
      (preserved.raw.declarations.any (fun d => d.name == "identity" && d.typeParameters.length == 1))
  IO.println "PSC1_TARGET_PLAN_PROFILE: existing strict closed plan; generic/public ABI fallback retained"
