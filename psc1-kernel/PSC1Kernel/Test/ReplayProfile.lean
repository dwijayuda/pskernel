import PSC1Kernel

open PSC1Kernel

def isContainer (line : String) : Bool :=
  line.startsWith "{\"environment\":" ||
  line.startsWith "{\"batch\":"

def isSegment (line : String) : Bool :=
  line.startsWith "{\"segment\":"

def replayProfile (path : String) : IO Unit := do
  let content ← IO.FS.readFile path
  let lines := content.splitOn "\n"
  let rec go
      (shared : Environment)
      (current : Option Replay.State)
      (lineNo declNo : Nat)
      (remaining : List String) : IO Unit := do
    match remaining with
    | [] => IO.println s!"PROFILE DONE declarations={declNo}"
    | raw :: rest =>
        let trimmed := raw.trim
        if trimmed.isEmpty || isContainer trimmed then
          go shared current (lineNo + 1) declNo rest
        else if isSegment trimmed then
          let shared' := match current with | none => shared | some st => st.env
          go shared' (some (Replay.State.empty shared')) (lineNo + 1) declNo rest
        else
          let state := match current with | some st => st | none => Replay.State.empty shared
          let record ← match ReplayJson.decodeLine raw with
            | .ok r => pure r
            | .error err => throw <| IO.userError s!"line {lineNo}: decode failed: {err}"
          let isDecl := record.declarationNameIndex?.isSome
          let declName ←
            if isDecl then
              match record.declarationNameIndex? with
              | some idx => match state.nameAt idx with
                | .ok n => pure (Replay.replayNameString n)
                | .error _ => pure s!"name#{idx}"
              | none => pure "<none>"
            else pure ""
          let start ← IO.monoMsNow
          if isDecl then IO.println s!"PROFILE START decl={declNo + 1} line={lineNo} name={declName}"
          let next ← match state.replay record with
            | .ok st => pure st
            | .error err => throw <| IO.userError s!"line {lineNo} decl={declNo + 1} name={declName}: {err}"
          let stop ← IO.monoMsNow
          let elapsed := stop - start
          if isDecl && (elapsed >= 100 || (declNo + 1) % 100 == 0) then
            IO.println s!"PROFILE DONE decl={declNo + 1} ms={elapsed} name={declName}"
          let nextDecl := if isDecl then declNo + 1 else declNo
          go shared (some next) (lineNo + 1) nextDecl rest
  go .empty none 1 0 lines

def main (args : List String) : IO Unit := do
  match args with
  | [path] => replayProfile path
  | _ => throw <| IO.userError "usage: ReplayProfile <lean4export.ndjson>"
