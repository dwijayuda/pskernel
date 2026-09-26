import PSC1Kernel

open PSC1Kernel

private def targetDecl : Nat := 2277

private def isContainer (line : String) : Bool :=
  line.startsWith "{\"environment\":" ||
  line.startsWith "{\"batch\":"

private def isSegment (line : String) : Bool :=
  line.startsWith "{\"segment\":"

private def replayTargetProfile (path : String) : IO Unit := do
  let content ← IO.FS.readFile path
  let lines := content.splitOn "\n"
  let totalStart ← IO.monoMsNow
  let rec go
      (shared : Environment)
      (current : Option Replay.State)
      (lineNo declNo : Nat)
      (remaining : List String) : IO Unit := do
    match remaining with
    | [] =>
        throw <| IO.userError s!"target declaration {targetDecl} was not reached"
    | raw :: rest =>
        let trimmed := raw.trim
        if trimmed.isEmpty || isContainer trimmed then
          go shared current (lineNo + 1) declNo rest
        else if isSegment trimmed then
          let shared' :=
            match current with
            | none => shared
            | some st => st.env
          go shared' (some (Replay.State.empty shared')) (lineNo + 1) declNo rest
        else
          let state :=
            match current with
            | some st => st
            | none => Replay.State.empty shared
          let record ←
            match ReplayJson.decodeLine raw with
            | .ok r => pure r
            | .error err =>
                throw <| IO.userError s!"line {lineNo}: decode failed: {err}"
          let isDecl := record.declarationNameIndex?.isSome
          let nextDecl := if isDecl then declNo + 1 else declNo
          let declName ←
            if isDecl then
              match record.declarationNameIndex? with
              | some idx =>
                  match state.nameAt idx with
                  | .ok n => pure (Replay.replayNameString n)
                  | .error _ => pure s!"name#{idx}"
              | none => pure "<none>"
            else
              pure ""
          if isDecl && nextDecl == targetDecl then
            IO.println s!"TARGET START decl={nextDecl} line={lineNo} name={declName}"
          let start ← IO.monoMsNow
          let next ←
            match state.replay record with
            | .ok st => pure st
            | .error err =>
                throw <| IO.userError s!"line {lineNo} decl={nextDecl} name={declName}: {err}"
          let stop ← IO.monoMsNow
          if isDecl && nextDecl == targetDecl then
            let totalStop ← IO.monoMsNow
            IO.println s!"TARGET DONE decl={nextDecl} ms={stop - start} totalMs={totalStop - totalStart} name={declName}"
            return
          go shared (some next) (lineNo + 1) nextDecl rest
  go .empty none 1 0 lines

def main (args : List String) : IO Unit := do
  match args with
  | [path] => replayTargetProfile path
  | _ => throw <| IO.userError "usage: ReplayTargetProfile <lean4export.ndjson>"
