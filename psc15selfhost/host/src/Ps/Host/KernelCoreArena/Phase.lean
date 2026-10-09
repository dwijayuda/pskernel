import Ps.Host.KernelCoreArena.Replay

namespace PsKernelCoreArena

/- Host-only timings. This command does NOT admit the declaration or serve as
   a substitute for the normal canonical Arena acceptance path. -/
def traceTheoremPhases
    (state : State)
    (record : PSC1Kernel.Replay.TheoremRecord) : IO UInt32 := do
  let parsed : Except Failure PsKernelTheoremInfo := do
    let name ← state.nameAt record.name
    let levels ← state.resolveNames record.levelParams
    let type ← state.exprAt record.type
    let value ← state.exprAt record.value
    pure { base := { name := name, levelParams := levels, type := type }, value := value }
  match parsed with
  | .error failure =>
      IO.eprintln ("PHASE_ERROR transport " ++ failure.message)
      pure failure.exitCode
  | .ok thmInfo => do
      let fuel := state.session.resources.fuel
      let resources := state.session.resources
      IO.eprintln ("PHASE_THEOREM " ++ coreNameText thmInfo.base.name)
      IO.eprintln ("PHASE_FUEL " ++ toString fuel)
      match psKernelKernelSessionPreflight state.session with
      | .error error =>
          let failure := fromKernelError error
          IO.eprintln ("PHASE_ERROR preflight " ++ failure.message)
          pure failure.exitCode
      | .ok _ => do
          let initial :=
            psKernelMkCheckerSession
              (psKernelKernelSessionEnvironment state.session)
              thmInfo.base.levelParams
              PsKernelDefinitionSafety.safe
              resources.maxRecDepth
              resources.maxNatSize
          IO.eprintln "PHASE_BEGIN header"
          let t0 ← IO.monoMsNow
          match psKernelCheckConstantBaseWithSession fuel initial thmInfo.base with
          | .error error =>
              IO.eprintln ("PHASE_ERROR header " ++ error)
              pure 1
          | .ok afterHeader => do
              let t1 ← IO.monoMsNow
              IO.eprintln ("PHASE_END header elapsed_ms=" ++ toString (t1-t0))
              IO.eprintln "PHASE_BEGIN proposition"
              let t2 ← IO.monoMsNow
              match psKernelSessionIsProp fuel afterHeader thmInfo.base.type with
              | .error error =>
                  IO.eprintln ("PHASE_ERROR proposition " ++ error)
                  pure 1
              | .ok propResult =>
                  if !(Prod.fst propResult) then
                    IO.eprintln "PHASE_ERROR theorem type not proposition"
                    pure 1
                  else do
                    let t3 ← IO.monoMsNow
                    IO.eprintln ("PHASE_END proposition elapsed_ms=" ++ toString (t3-t2))
                    IO.eprintln "PHASE_BEGIN closed_term"
                    let t4 ← IO.monoMsNow
                    match psKernelCheckNoMVarNoFVar thmInfo.value with
                    | .error error =>
                        IO.eprintln ("PHASE_ERROR closed_term " ++ error)
                        pure 1
                    | .ok _ => do
                        let t5 ← IO.monoMsNow
                        IO.eprintln ("PHASE_END closed_term elapsed_ms=" ++ toString (t5-t4))
                        IO.eprintln "PHASE_BEGIN universe_params"
                        let t6 ← IO.monoMsNow
                        match psKernelCheckLevelParams thmInfo.value thmInfo.base.levelParams with
                        | .error error =>
                            IO.eprintln ("PHASE_ERROR universe_params " ++ error)
                            pure 1
                        | .ok _ => do
                            let t7 ← IO.monoMsNow
                            IO.eprintln ("PHASE_END universe_params elapsed_ms=" ++ toString (t7-t6))
                            IO.eprintln "PHASE_BEGIN checked_inference"
                            let t8 ← IO.monoMsNow
                            match psKernelSessionCheck fuel (Prod.snd propResult) thmInfo.value with
                            | .error error =>
                                IO.eprintln ("PHASE_ERROR checked_inference " ++ error)
                                pure 1
                            | .ok inferred => do
                                let t9 ← IO.monoMsNow
                                IO.eprintln ("PHASE_END checked_inference elapsed_ms=" ++ toString (t9-t8))
                                IO.eprintln "PHASE_BEGIN final_defeq"
                                let t10 ← IO.monoMsNow
                                match psKernelSessionIsDefEq
                                    fuel (Prod.snd inferred) (Prod.fst inferred)
                                    thmInfo.base.type with
                                | .error error =>
                                    IO.eprintln ("PHASE_ERROR final_defeq " ++ error)
                                    pure 1
                                | .ok equal => do
                                    let t11 ← IO.monoMsNow
                                    IO.eprintln ("PHASE_END final_defeq elapsed_ms=" ++ toString (t11-t10))
                                    if Prod.fst equal then
                                      IO.eprintln "PHASE_DIAGNOSTIC_SUCCESS (not a declaration receipt)"
                                      pure 0
                                    else
                                      IO.eprintln "PHASE_ERROR theorem type mismatch"
                                      pure 1

partial def replayUntilTheorem
    (stream : IO.FS.Stream)
    (state : State)
    (lineNo : Nat)
    (target : String) : IO UInt32 := do
  let line ← stream.getLine
  if line.isEmpty then
    IO.eprintln ("PHASE_ERROR missing target theorem " ++ target)
    pure 3
  else
    match PSC1Kernel.ReplayJson.decodeLine line with
    | .error message =>
        IO.eprintln ("PHASE_ERROR decode at line " ++ toString lineNo ++ ": " ++ message)
        pure 3
    | .ok record =>
        let selected : Except Failure (Option PSC1Kernel.Replay.TheoremRecord) :=
          match record with
          | .theoremR value =>
              match state.nameAt value.name with
              | .error failure => .error failure
              | .ok name =>
                  if coreNameText name == target then
                    .ok (some value)
                  else
                    .ok none
          | _ => .ok none
        match selected with
        | .error failure =>
            IO.eprintln ("PHASE_ERROR name lookup " ++ failure.message)
            pure failure.exitCode
        | .ok (some value) => do
            IO.eprintln ("PHASE_TARGET_RECORD line=" ++ toString lineNo)
            traceTheoremPhases state value
        | .ok none =>
            match state.replayRecord record with
            | .error failure =>
                IO.eprintln ("PHASE_ERROR replay at line " ++ toString lineNo ++ ": " ++ failure.message)
                pure failure.exitCode
            | .ok next =>
                replayUntilTheorem stream next (lineNo+1) target

def runTheoremPhases (target : String) : IO UInt32 := do
  match State.empty false with
  | .error failure =>
      IO.eprintln ("PHASE_ERROR initializing " ++ failure.message)
      pure failure.exitCode
  | .ok initial => do
      let stream ← IO.getStdin
      replayUntilTheorem stream initial 1 target

end PsKernelCoreArena
