import PSC1Kernel

open PSC1Kernel

def isContainerLine (line : String) : Bool :=
  line.startsWith "{\"environment\":" ||
    line.startsWith "{\"batch\":" ||
    line.startsWith "{\"segment\":"

partial def decodeLines
    (path : String)
    (lineNo decoded : Nat)
    (lines : List String) : IO Nat := do
  match lines with
  | [] => pure decoded
  | line :: rest =>
      let trimmed := line.trim
      if trimmed.isEmpty || isContainerLine trimmed then
        decodeLines path (lineNo + 1) decoded rest
      else
        match ReplayJson.decodeLine line with
        | .ok _ => decodeLines path (lineNo + 1) (decoded + 1) rest
        | .error err =>
            throw <| IO.userError s!"decode failed {path}:{lineNo}: {err}"

def main (args : List String) : IO Unit := do
  match args with
  | [path] => do
      let content ← IO.FS.readFile path
      let decoded ← decodeLines path 1 0 (content.splitOn "\n")
      IO.println s!"PSC1 decode-only PASS file={path} decoded={decoded}"
  | _ => throw <| IO.userError "usage: DecodeFile <lean4export.ndjson>"
