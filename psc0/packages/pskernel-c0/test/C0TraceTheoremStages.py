#!/usr/bin/env python3
"""Instrument only the disposable C0 NDJSON test runner at one source record.

No production Lean source is modified. The original C0 declaration checker
still executes normally after an independent, diagnostic-only staged replay.
Never use stage replay as an admission certificate.
"""
from pathlib import Path
import argparse

MARKER = "def c0ExportVerdictFromFileTrace\n"
SITE = "      let outcome := c0ExportStepDetailed state line fuel"

HELPER = r'''
/-- Diagnostic-only stage timing; the attempt is a thunk so BEGIN prints
    *before* the potentially expensive pure checker call. -/
def c0ExportTraceStage {α : Type}
    (stage : String) (attempt : Unit → Except String α) : IO (Option α) := do
  IO.println s!"C0_INIT_STAGE_BEGIN stage={stage} record=5068793"
  match attempt () with
  | .ok value =>
      IO.println s!"C0_INIT_STAGE_OK stage={stage} record=5068793"
      return some value
  | .error reason =>
      IO.println s!"C0_INIT_STAGE_ERROR stage={stage} reason={reason}"
      return none

/-- Independently run the *actual* checker steps in the same environment,
    then return no checked result or environment. The real source checker
    below remains the exclusive admission authority. -/
def c0ExportTraceTheoremStages
    (env : PsKernelEnvironment) (theoremInfo : PsKernelTheoremInfo)
    (fuel : Nat) : IO Unit := do
  IO.println "C0_INIT_STAGE_THEOREM_START record=5068793"
  let session := psKernelMkCheckerSession env theoremInfo.base.levelParams
    PsKernelDefinitionSafety.safe 4096 psKernelLeanNatMaxSizeDefault
  let some afterHeader ← c0ExportTraceStage "header"
      (fun _ => psKernelCheckConstantBaseWithSession
        fuel session theoremInfo.base) | return
  let some propResult ← c0ExportTraceStage "is_prop"
      (fun _ => psKernelSessionIsProp
        fuel afterHeader theoremInfo.base.type) | return
  if !propResult.fst then
    IO.println "C0_INIT_STAGE_ERROR stage=is_prop_result reason=not_prop"
    return
  let some _ ← c0ExportTraceStage "closed_proof"
      (fun _ => psKernelCheckNoMVarNoFVar theoremInfo.value) | return
  let some _ ← c0ExportTraceStage "level_params"
      (fun _ => psKernelCheckLevelParams
        theoremInfo.value theoremInfo.base.levelParams) | return
  let some checkedProof ← c0ExportTraceStage "proof_check"
      (fun _ => psKernelSessionCheck
        fuel propResult.snd theoremInfo.value) | return
  let some equality ← c0ExportTraceStage "proof_type_defeq"
      (fun _ => psKernelSessionIsDefEq
        fuel checkedProof.snd checkedProof.fst theoremInfo.base.type) | return
  IO.println s!"C0_INIT_STAGE_FINISHED is_defeq={equality.fst} diagnostic_only=true"

'''
INJECTION = r'''      if consumed == 5068793 then
        IO.println "C0_INIT_TRACE_EXACT_ENTER record=5068793"
        match Lean.Json.parse line with
        | .error error =>
            IO.println s!"C0_INIT_TRACE_PARSE_ERROR reason={error}"
        | .ok record =>
            match c0ExportParseRecord state.tables record with
            | .error error =>
                IO.println s!"C0_INIT_TRACE_DECODE_ERROR reason={error}"
            | .ok decoded =>
                for declaration in decoded.declarations do
                  match declaration with
                  | .theoremDecl info =>
                      c0ExportTraceTheoremStages state.environment info fuel
                  | _ =>
                      IO.println "C0_INIT_TRACE_NOT_THEOREM record=5068793"
'''

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("--record", type=int, default=5068793)
    args = parser.parse_args()
    if args.record < 1:
        raise ValueError("record must be positive")
    code = args.source.read_text(encoding="utf8")
    if code.count(MARKER) != 1 or code.count(SITE) != 1:
        raise ValueError("unrecognized source: refusing diagnostic instrumentation")
    if "C0_INIT_STAGE_BEGIN" in code:
        raise ValueError("already instrumented: refusing duplicate")
    code = code.replace(MARKER, HELPER.replace("5068793", str(args.record)) + "\n" + MARKER)
    code = code.replace(SITE, INJECTION.replace("5068793", str(args.record)) + SITE)
    args.source.write_text(code, encoding="utf8")
    print("C0_INIT_STAGE_INSTRUMENTED disposable_test_only=true")


if __name__ == "__main__":
    main()
