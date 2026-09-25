import PSC1Kernel

open PSC1Kernel

structure ReplayTotals where
  records : Nat := 0
  names : Nat := 0
  levels : Nat := 0
  expressions : Nat := 0
  declarations : Nat := 0
  segments : Nat := 0

def ReplayTotals.add (totals : ReplayTotals) (stats : Replay.Stats) : ReplayTotals :=
  {
    records := totals.records + stats.records
    names := totals.names + stats.names
    levels := totals.levels + stats.levels
    expressions := totals.expressions + stats.expressions
    declarations := totals.declarations + stats.declarations
    segments := totals.segments + 1
  }

def isReplayContainerMarker (line : String) : Bool :=
  line.startsWith "{\"environment\":" ||
    line.startsWith "{\"batch\":"

def isReplaySegmentMarker (line : String) : Bool :=
  line.startsWith "{\"segment\":"

def finishReplaySegment
    (shared : Environment)
    (current : Option Replay.State)
    (totals : ReplayTotals) :
    Except String (Environment × ReplayTotals) := do
  match current with
  | none => pure (shared, totals)
  | some state =>
      let stats ← state.finish
      pure (state.env, totals.add stats)

partial def replaySegmentedLinesFrom
    (base : Environment)
    (lines : List String)
    (maxRecDepth : Nat := 0)
    (maxNatSize : Nat := leanNatMaxSizeDefault)
    (nativeEvaluator : Option NativeEvaluator := none) :
    Except String (Environment × ReplayTotals) := do
  let rec go
      (shared : Environment)
      (current : Option Replay.State)
      (totals : ReplayTotals)
      (lineNo : Nat)
      (remaining : List String) :
      Except String (Environment × ReplayTotals) := do
    match remaining with
    | [] =>
        finishReplaySegment shared current totals
    | line :: rest =>
        let trimmed := line.trim
        if trimmed.isEmpty then
          go shared current totals (lineNo + 1) rest
        else if isReplayContainerMarker trimmed then
          go shared current totals (lineNo + 1) rest
        else if isReplaySegmentMarker trimmed then
          let (shared', totals') ←
            finishReplaySegment shared current totals
          go shared' (some (Replay.State.empty shared' maxRecDepth maxNatSize nativeEvaluator)) totals'
            (lineNo + 1) rest
        else
          let state :=
            match current with
            | some value => value
            | none => Replay.State.empty shared maxRecDepth maxNatSize nativeEvaluator
          let next ←
            match ReplayJson.replayLine state line with
            | .ok value => pure value
            | .error err =>
                throw ("line " ++ toString lineNo ++ ": " ++ err)
          go shared (some next) totals (lineNo + 1) rest
  go base none {} 1 lines

def replaySegmentedLines
    (lines : List String) :
    Except String (Environment × ReplayTotals) :=
  replaySegmentedLinesFrom .empty lines

def replayFileFrom
    (base : Environment)
    (path : String)
    (maxRecDepth : Nat := 0)
    (maxNatSize : Nat := leanNatMaxSizeDefault)
    (nativeEvaluator : Option NativeEvaluator := none) :
    IO (Environment × ReplayTotals) := do
  let content ← IO.FS.readFile path
  match replaySegmentedLinesFrom
      base (content.splitOn "\n") maxRecDepth maxNatSize nativeEvaluator with
  | .ok value => pure value
  | .error err =>
      throw <| IO.userError (
        "Lean4Export replay failed for " ++ path ++ ": " ++ err)

def liftReplayResult
    (path : String)
    (lineNo : Nat)
    (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error err =>
      throw <| IO.userError (
        "Lean4Export replay failed for " ++ path ++
        " at line " ++ toString lineNo ++ ": " ++ err)

def isPushEqAppendName (name : Name) : Bool :=
  Replay.replayNameString name == "Array.push_eq_append"

def replayPushEqAppendTheorem
    (state : Replay.State)
    (record : Replay.TheoremRecord) : IO Replay.State := do
  let name ← liftReplayResult "<diagnostic>" 0 (state.nameAt record.name)
  let levelParams ← liftReplayResult "<diagnostic>" 0
    (Replay.resolveNames state record.levelParams)
  let type ← liftReplayResult "<diagnostic>" 0 (state.exprAt record.type)
  let value ← liftReplayResult "<diagnostic>" 0 (state.exprAt record.value)
  let info : TheoremInfo := {
    base := { name := name, levelParams := levelParams, type := type }
    value := value
  }
  IO.println "PSC1 Lean theorem PHASE header-begin"
  liftReplayResult "<diagnostic>" 0
    (Kernel.checkConstantBase state.env info.base .safe
      state.maxRecDepth state.maxNatSize state.nativeEvaluator)
  IO.println "PSC1 Lean theorem PHASE header-end"
  let ctx := Kernel.mkChecker state.env info.base.levelParams .safe
    state.maxRecDepth state.maxNatSize state.nativeEvaluator
  IO.println "PSC1 Lean theorem PHASE isProp-begin"
  let prop ← liftReplayResult "<diagnostic>" 0 (isProp ctx info.base.type)
  unless prop do throw <| IO.userError "theorem type is not a proposition"
  IO.println "PSC1 Lean theorem PHASE isProp-end"
  liftReplayResult "<diagnostic>" 0 (Kernel.checkNoMVarNoFVar info.value)
  liftReplayResult "<diagnostic>" 0
    (Kernel.checkLevelParams info.value info.base.levelParams)
  IO.println "PSC1 Lean theorem PHASE proof-check-begin"
  let valueType ← liftReplayResult "<diagnostic>" 0 (check ctx info.value)
  IO.println "PSC1 Lean theorem PHASE proof-check-end"
  IO.println "PSC1 Lean theorem PHASE final-defeq-begin"
  let eq ← liftReplayResult "<diagnostic>" 0
    (isDefEq ctx valueType info.base.type)
  unless eq do throw <| IO.userError "theorem proof type mismatch"
  IO.println "PSC1 Lean theorem PHASE final-defeq-end"
  let env ← liftReplayResult "<diagnostic>" 0 (state.env.add (.thmInfo info))
  pure { state with env := env }

partial def replaySegmentedLinesFromProgress
    (path : String)
    (base : Environment)
    (lines : List String)
    (progressEvery : Nat := 10000)
    (maxRecDepth : Nat := 0)
    (maxNatSize : Nat := leanNatMaxSizeDefault)
    (nativeEvaluator : Option NativeEvaluator := none) :
    IO (Environment × ReplayTotals) := do
  let rec go
      (shared : Environment)
      (current : Option Replay.State)
      (totals : ReplayTotals)
      (lineNo : Nat)
      (remaining : List String) :
      IO (Environment × ReplayTotals) := do
    match remaining with
    | [] =>
        liftReplayResult path lineNo
          (finishReplaySegment shared current totals)
    | line :: rest =>
        let trimmed := line.trim
        if trimmed.isEmpty || isReplayContainerMarker trimmed then
          go shared current totals (lineNo + 1) rest
        else if isReplaySegmentMarker trimmed then
          let (shared', totals') ←
            liftReplayResult path lineNo
              (finishReplaySegment shared current totals)
          go shared'
            (some (Replay.State.empty shared' maxRecDepth maxNatSize nativeEvaluator))
            totals' (lineNo + 1) rest
        else
          let state :=
            match current with
            | some value => value
            | none => Replay.State.empty shared maxRecDepth maxNatSize nativeEvaluator
          if lineNo >= 190530 && lineNo <= 190680 then
            IO.println s!"PSC1 Lean replay RAW-BEGIN line={lineNo} chars={line.length}"
          let record ←
            liftReplayResult path lineNo (ReplayJson.decodeLine line)
          if lineNo >= 190530 && lineNo <= 190680 then
            let recordLabel :=
              match record with
              | .metaR _ => "meta"
              | .nameR value => "name#" ++ toString value.index
              | .levelR value => "level#" ++ toString value.index
              | .exprR value => "expr#" ++ toString value.index
              | .axiomR value => "axiom-name#" ++ toString value.name
              | .definitionR value => "def-name#" ++ toString value.name
              | .theoremR value => "thm-name#" ++ toString value.name
              | .opaqueR value => "opaque-name#" ++ toString value.name
              | .quotR value => "quot-name#" ++ toString value.name
              | .inductiveR _ => "inductive"
            IO.println s!"PSC1 Lean replay RECORD-BEGIN line={lineNo} record={recordLabel} namesDense={state.names.dense.size} namesSparse={state.names.sparse.length} levelsDense={state.levels.dense.size} levelsSparse={state.levels.sparse.length} exprsDense={state.exprs.dense.size} exprsSparse={state.exprs.sparse.length}"
          match record.declarationNameIndex? with
          | some nameIndex =>
              let name ←
                liftReplayResult path lineNo (state.nameAt nameIndex)
              IO.println s!"PSC1 Lean replay DECL-BEGIN file={path} line={lineNo} decl={Replay.replayNameString name} segmentDecls={state.declarations} env={state.env.size}"
          | none => pure ()
          let next ←
            match record with
            | .theoremR theoremRecord =>
                let theoremName ←
                  liftReplayResult path lineNo (state.nameAt theoremRecord.name)
                if isPushEqAppendName theoremName then
                  let next ← replayPushEqAppendTheorem state theoremRecord
                  pure {
                    next with
                    records := state.records + 1
                    declarations := state.declarations + 1
                  }
                else
                  liftReplayResult path lineNo (state.replay record)
            | _ =>
                liftReplayResult path lineNo (state.replay record)
          if lineNo >= 190530 && lineNo <= 190680 then
            IO.println s!"PSC1 Lean replay RECORD-END line={lineNo} namesDense={next.names.dense.size} namesSparse={next.names.sparse.length} levelsDense={next.levels.dense.size} levelsSparse={next.levels.sparse.length} exprsDense={next.exprs.dense.size} exprsSparse={next.exprs.sparse.length} env={next.env.size}"
          if progressEvery > 0 then
            if lineNo % progressEvery == 0 then
              IO.println s!"PSC1 Lean replay PROGRESS file={path} line={lineNo} segmentDecls={next.declarations} totalDecls={totals.declarations + next.declarations} env={next.env.size}"
          go shared (some next) totals (lineNo + 1) rest
  go base none {} 1 lines

def replayFileFromProgress
    (base : Environment)
    (path : String)
    (progressEvery : Nat := 10000)
    (maxRecDepth : Nat := 0)
    (maxNatSize : Nat := leanNatMaxSizeDefault)
    (nativeEvaluator : Option NativeEvaluator := none) :
    IO (Environment × ReplayTotals) := do
  let content ← IO.FS.readFile path
  replaySegmentedLinesFromProgress path base (content.splitOn "\n")
    progressEvery maxRecDepth maxNatSize nativeEvaluator

def printReplayTotals (path : String) (totals : ReplayTotals) : IO Unit :=
  IO.println s!"PSC1 Lean replay PASS file={path} records={totals.records} names={totals.names} levels={totals.levels} exprs={totals.expressions} declarations={totals.declarations} segments={totals.segments}"

partial def replayTargets
    (base : Environment)
    (paths : List String)
    (maxRecDepth : Nat := 0)
    (maxNatSize : Nat := leanNatMaxSizeDefault)
    (nativeEvaluator : Option NativeEvaluator := none) : IO Unit := do
  match paths with
  | [] => pure ()
  | path :: rest => do
      let (_, totals) ←
        replayFileFrom base path maxRecDepth maxNatSize nativeEvaluator
      printReplayTotals path totals
      replayTargets base rest maxRecDepth maxNatSize nativeEvaluator

def main (args : List String) : IO Unit := do
  match args with
  | ["--progress", path] => do
      let (_, totals) ← replayFileFromProgress .empty path
      printReplayTotals path totals
  | [path] => do
      let (_, totals) ← replayFileFrom .empty path
      printReplayTotals path totals
  | "--base" :: basePath :: target :: rest => do
      let (baseEnv, _) ← replayFileFrom .empty basePath
      replayTargets baseEnv (target :: rest)
  | ["--native-map", mapPath, path] => do
      let provider ← PSC1Kernel.NativeMap.loadNativeMap mapPath
      let (_, totals) ←
        replayFileFrom .empty path 0 leanNatMaxSizeDefault (some provider)
      printReplayTotals path totals
  | "--native-map" :: mapPath :: "--base" :: basePath :: target :: rest => do
      let provider ← PSC1Kernel.NativeMap.loadNativeMap mapPath
      let (baseEnv, _) ←
        replayFileFrom .empty basePath 0 leanNatMaxSizeDefault (some provider)
      replayTargets
        baseEnv (target :: rest) 0 leanNatMaxSizeDefault (some provider)
  | _ =>
      throw <| IO.userError (
        "usage: ReplayFile [--progress] <lean4export.ndjson> | " ++
        "ReplayFile --base <base.ndjson> <delta.ndjson> [delta.ndjson ...] | " ++
        "ReplayFile --native-map <native.tsv> <lean4export.ndjson> | " ++
        "ReplayFile --native-map <native.tsv> --base <base.ndjson> " ++
        "<delta.ndjson> [delta.ndjson ...]")
