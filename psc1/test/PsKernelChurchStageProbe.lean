import Lean
import PsKernelChurchSource

open Lean

/- Bounded native diagnosis. The original public checker remains authoritative.
   The staged copy calls actual production operations and threads every owner.
   It publishes no declaration and creates no checking receipt. -/

private def errorPair : PsKernelError → String × String
  | .rejectedInvalid message => ("rejected", message)
  | .declinedUnsupported message => ("unsupported", message)
  | .resourceExhausted _ message => ("resource_exhausted", message)
  | .internalError message => ("internal_error", message)

private def stringIO {α : Type} : Except String α → IO α
  | .ok value => pure value
  | .error message => throw (IO.userError message)

private def kernelIO {α : Type} : Except PsKernelError α → IO α
  | .ok value => pure value
  | .error error => throw (IO.userError (errorPair error).snd)

private def emit (tag : String) (fields : List (String × Lean.Json)) : IO Unit :=
  IO.println (tag ++ " " ++ (Lean.Json.mkObj fields).compress)

@[noinline] private def step {α : Type} (label : String)
    (run : Unit → Option (Except String α)) : IO (Except String α) := do
  IO.eprintln s!"PSC1_CHURCH_STAGE_BEGIN {label}"
  let start ← IO.monoMsNow
  let result := run ()
  let elapsed := (← IO.monoMsNow) - start
  match result with
  | none =>
      emit "PSC1_CHURCH_STAGE" [("stage", toJson label), ("status", toJson "declined"), ("milliseconds", toJson elapsed)]
      pure (.error "PROBE_DIRECT_DECLINED")
  | some (.error message) =>
      emit "PSC1_CHURCH_STAGE" [("stage", toJson label), ("status", toJson "error"),
        ("milliseconds", toJson elapsed), ("reason", toJson message)]
      pure (.error message)
  | some (.ok value) =>
      emit "PSC1_CHURCH_STAGE" [("stage", toJson label), ("status", toJson "ok"), ("milliseconds", toJson elapsed)]
      pure (.ok value)

private def staged (session : PsKernelKernelSession)
    (installed : PsKernelDagGeneratedState)
    (request : PsKernelDagDeclarationRequest) : ExceptT String IO Unit := do
  let declaration ← ExceptT.mk (pure (psKernelDagDecodeDeclaration installed.built request))
  let plan ← match psKernelDagSimpleAdmissionPlan request declaration with
    | none => throw "PROBE_SIMPLE_PLAN_MISSING"
    | some value => pure value
  match plan.info with
  | .thmInfo _ => pure ()
  | _ => throw "PROBE_EXPECTED_REAL_THEOREM"
  let checker := psKernelMkCheckerSession (psKernelKernelSessionEnvironment session)
    plan.base.levelParams plan.safety session.resources.maxRecDepth session.resources.maxNatSize
  let context := psKernelExprV2CheckContextEmpty checker.context
  let initial := psKernelExprV2CheckStateWithWhnf (psKernelExprV2CheckStateEmpty installed.arena)
    (psKernelExprV2WhnfStateForDeclarations installed.arena installed.declarations)
  let fuel := session.resources.fuel
  let afterHeader ← ExceptT.mk (step "header" (fun _ =>
    psKernelExprV2AdmissionCheckHeaderWithFuel fuel context initial plan.base plan.typeRoot))
  let prepared ← ExceptT.mk (step "is-prop" (fun _ =>
    psKernelExprV2AdmissionPrepareBodyWithFuel fuel context afterHeader plan))
  let body ← match plan.body with
    | none => throw "PROBE_THEOREM_BODY_MISSING"
    | some body => pure body
  let _ ← ExceptT.mk (step "body-static" (fun _ => some
    (psKernelExprV2AdmissionStaticOnCanonical prepared.whnf.arena body.snd plan.base.levelParams)))
  let checked ← ExceptT.mk (step "body-check" (fun _ =>
    psKernelExprV2TryCheckStateWithFuel fuel context prepared body.snd))
  let compared ← ExceptT.mk (step "final-defeq" (fun _ =>
    psKernelExprV2TryDefEqStateWithFuel fuel context checked.fst checked.snd plan.typeRoot))
  if compared.snd then pure () else throw plan.mismatch

def main (args : List String) : IO Unit := do
  let [mode] := args | throw (IO.userError "Expected baseline or stages")
  unless mode == "baseline" || mode == "stages" do
    throw (IO.userError "Unknown probe mode")
  let (arena, requests) ← stringIO psKernelChurchSource
  let [first, second, third, request] := requests | throw (IO.userError "Four authentic requests required")
  let policy := psKernelResourcePolicyDefault
  unless policy.fuel == 4096 && policy.maxRecDepth == 0 && policy.maxNatSize == 134217728 &&
      policy.maxDeclarations == 0 && !policy.cancelled do
    throw (IO.userError "Published resource policy changed")
  unless arena.size == 197 do throw (IO.userError "Authentic 197-node input required")
  let session ← kernelIO (psKernelKernelSessionEmpty policy psKernelProviderDefault)
  let start ← IO.monoMsNow
  let result : Except PsKernelError Unit ← if mode == "baseline" then
      pure ((psKernelV1RunDag session [] .safe arena (requests.map PsKernelDagCommand.admit)).map (fun _ => ()))
    else do
      let canonical ← stringIO (psKernelExprV2PagedValidate arena)
      let admittedPrefix ← kernelIO (psKernelV1RunDag session [] .safe canonical
        ([first, second, third].map PsKernelDagCommand.admit))
      let decoded ← stringIO (psKernelExprV2DecodeChecked canonical)
      let installed ← stringIO (psKernelDagGeneratedFromSession admittedPrefix.session canonical decoded)
      emit "PSC1_CHURCH_PREFIX" [("requests", toJson (3 : Nat)),
        ("sourceNodes", toJson arena.size), ("ownedNodes", toJson installed.arena.size),
        ("declarations", toJson (psKernelEnvironmentSize admittedPrefix.session.environment))]
      let attempted ← (staged admittedPrefix.session installed request).run
      pure (attempted.mapError psKernelErrorFromMessage)
  let elapsed := (← IO.monoMsNow) - start
  let (verdict, reason) := match result with
    | .ok _ => ("accepted", "")
    | .error error => errorPair error
  emit "PSC1_CHURCH_RESULT" [("schema", toJson "psc1-church-stages-v1"),
    ("runtime", toJson "native"), ("mode", toJson mode), ("verdict", toJson verdict),
    ("reason", toJson reason), ("milliseconds", toJson elapsed),
    ("fuel", toJson (4096 : Nat)), ("sourceNodes", toJson arena.size)]
