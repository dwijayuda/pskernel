import Lean.Data.Json
import Init.Util
import Ps.KernelCore.Checker.Session

/- Host-only failure observer for the immutable kernel source369bee.
   This file is never part of the portable kernel closure. It introduces no
   unsafe declaration, external declaration, cached judgment or trusted result.
   Existing Lean dbgTrace is used only to print an error AFTER the original
   stage returned. Its logical definition returns its thunk unchanged.
   The frozen worker below is copied verbatim from Checker/Knot.lean at
   369bee5801bd5e4476837684fad3f7e1ca8c422c, except its own recursive name.
   Every helper/callback/fuel/guard/publication remains the original function. -/
namespace NativeChurchDefEqTrace
open Lean

private def sourceSha : String := "369bee5801bd5e4476837684fad3f7e1ca8c422c"

private def selectedFuel (fuel : Nat) : Bool :=
  fuel <= 4096 && (fuel >= 4080 || fuel <= 16 || fuel % 256 == 0)

private def natView (value : Nat) : Json :=
  if value <= 18446744073709551615 then toJson value
  else Json.mkObj [("largerThanUInt64", toJson true)]

private def textView (value : String) : Json :=
  let bytes := value.utf8ByteSize
  if bytes <= 256 then
    Json.mkObj [
      ("text", toJson (String.ofList (value.toList.take 64))),
      ("utf8ByteSize", natView bytes),
      ("truncated", toJson (decide (value.length > 64)))]
  else Json.mkObj [("utf8ByteSize", natView bytes), ("truncated", toJson true)]

private def nameView : Nat → PsKernelName → Json
  | 0, _ => Json.mkObj [("truncated", toJson true)]
  | remaining + 1, name =>
      match name with
      | .anonymous => Json.mkObj [("kind", toJson "anonymous")]
      | .str parent value => Json.mkObj [
          ("kind", toJson "str"), ("parent", nameView remaining parent),
          ("value", textView value)]
      | .num parent index => Json.mkObj [
          ("kind", toJson "num"), ("parent", nameView remaining parent),
          ("index", natView index)]

private def levelHead : PsKernelLevel → Json
  | .zero => toJson "zero"
  | .succ _ => toJson "succ"
  | .max _ _ => toJson "max"
  | .imax _ _ => toJson "imax"
  | .param name => Json.mkObj [("kind", toJson "param"), ("name", nameView 8 name)]
  | .mvar name => Json.mkObj [("kind", toJson "mvar"), ("name", nameView 8 name)]

private def binderName : PsKernelBinderInfo → String
  | .default => "default"
  | .implicit => "implicit"
  | .strictImplicit => "strictImplicit"
  | .instImplicit => "instImplicit"

private def item (path kind : String) (fields : List (String × Json) := []) : Json :=
  Json.mkObj ([("path", toJson path), ("kind", toJson kind)] ++ fields)

/- One global visitation budget per term, not a branching depth bound.
   The pending stack contains only unvisited expressions; no full subtree scan,
   hash, normal form or semantic decision is computed by this observer. -/
private def exprItems : Nat → List (String × PsKernelExpr) →
    List Json → (List Json × Bool)
  | 0, pending, observed => (observed.reverse, !pending.isEmpty)
  | _ + 1, [], observed => (observed.reverse, false)
  | remaining + 1, (path, expression) :: rest, observed =>
      match expression with
      | .bvar index =>
          exprItems remaining rest (item path "bvar" [("index", natView index)] :: observed)
      | .fvar name =>
          exprItems remaining rest (item path "fvar" [("name", nameView 8 name)] :: observed)
      | .mvar name =>
          exprItems remaining rest (item path "mvar" [("name", nameView 8 name)] :: observed)
      | .sort level =>
          exprItems remaining rest (item path "sort" [("levelHead", levelHead level)] :: observed)
      | .const name levels =>
          exprItems remaining rest (item path "const" [
            ("name", nameView 8 name), ("levelHeads", toJson (levels.take 4 |>.map levelHead)),
            ("levelsTruncated", toJson (!(levels.drop 4).isEmpty))] :: observed)
      | .app fn arg =>
          exprItems remaining ((path ++ ".fn", fn) :: (path ++ ".arg", arg) :: rest)
            (item path "app" :: observed)
      | .lam name type body info =>
          exprItems remaining ((path ++ ".type", type) :: (path ++ ".body", body) :: rest)
            (item path "lam" [("name", nameView 8 name), ("binder", toJson (binderName info))] :: observed)
      | .forallE name type body info =>
          exprItems remaining ((path ++ ".type", type) :: (path ++ ".body", body) :: rest)
            (item path "forallE" [("name", nameView 8 name), ("binder", toJson (binderName info))] :: observed)
      | .letE name type value body nondep =>
          exprItems remaining ((path ++ ".type", type) :: (path ++ ".value", value) ::
            (path ++ ".body", body) :: rest)
            (item path "letE" [("name", nameView 8 name), ("nondep", toJson nondep)] :: observed)
      | .lit value =>
          let fields := match value with
            | .nat number => [("nat", natView number)]
            | .str text => [("string", textView text)]
          exprItems remaining rest (item path "lit" fields :: observed)
      | .mdata metadata body =>
          exprItems remaining ((path ++ ".body", body) :: rest)
            (item path "mdata" [("metadata", natView metadata)] :: observed)
      | .proj typeName index body =>
          exprItems remaining ((path ++ ".body", body) :: rest)
            (item path "proj" [("typeName", nameView 8 typeName), ("index", natView index)] :: observed)

def exprView (expression : PsKernelExpr) : Json :=
  let (nodes, truncated) := exprItems 24 [("", expression)] []
  Json.mkObj [
    ("nodeVisitLimit", toJson (24 : Nat)), ("shapeOnly", toJson true),
    ("truncated", toJson truncated), ("nodes", toJson nodes)]

private def event (fuel : Nat) (stage : String)
    (context : PsKernelCheckerContext) (state : PsKernelCheckerState)
    (left right : PsKernelExpr) (message : String) : String :=
  let guarded := stage == "zero-guard" || stage == "depth-guard"
  let fields :=
    if guarded then []
    else [
      ("recDepth", natView context.recDepth), ("nextFresh", natView state.nextFresh),
      ("left", exprView left), ("right", exprView right)]
  "PSC1_ARENA_NATIVE_DEFEQ_EVENT " ++ (Json.mkObj ([
    ("protocol", toJson "pskernel-arena-native-defeq-event/1"),
    ("sourceSha", toJson sourceSha), ("ownerFuel", toJson fuel),
    ("recursiveDefEqFuel", toJson (fuel - 1)), ("stage", toJson stage),
    ("message", textView message), ("phase", toJson "error"),
    ("guardWithoutSyntaxInspection", toJson guarded)] ++ fields)).compress

def traceAttempt {α : Type} (fuel : Nat) (stage : String)
    (context : PsKernelCheckerContext) (state : PsKernelCheckerState)
    (left right : PsKernelExpr) (result : Except String α) : Except String α :=
  match result with
  | .ok value => .ok value
  | .error message =>
      if selectedFuel fuel then
        dbgTrace (event fuel stage context state left right message)
          (fun _ => .error message)
      else .error message

theorem traceAttempt_identity {α : Type} (fuel : Nat) (stage : String)
    (context : PsKernelCheckerContext) (state : PsKernelCheckerState)
    (left right : PsKernelExpr) (result : Except String α) :
    traceAttempt fuel stage context state left right result = result := by
  cases result <;> simp [traceAttempt, dbgTrace]

def frozenWithFuel
    (fuel : Nat) :
    PsKernelCheckerContext ->
    PsKernelCheckerState ->
    PsKernelExpr ->
    PsKernelExpr ->
    Except String
      (Prod Bool PsKernelCheckerState) :=
  match fuel with
  | Nat.zero =>
      fun
        (_context : PsKernelCheckerContext)
        (_state : PsKernelCheckerState)
        (_left : PsKernelExpr)
        (_right : PsKernelExpr) =>
        Except.error
          "kernel definitional equality budget exhausted"
  | Nat.succ remaining =>
      fun
        (context : PsKernelCheckerContext)
        (state : PsKernelCheckerState)
        (left : PsKernelExpr)
        (right : PsKernelExpr) =>
        let defeq :
            PsKernelCheckerContext ->
            PsKernelCheckerState ->
            PsKernelExpr ->
            PsKernelExpr ->
            Except String
              (Prod Bool PsKernelCheckerState) :=
          frozenWithFuel remaining;
        match
            psKernelCheckerContextEnterRecDepth
              context with
        | Except.error error =>
            Except.error error
        | Except.ok nextContext =>
            if psKernelExprEq left right then
              Except.ok
                (psKernelDefEqFinish
                  state
                  left
                  right
                  true)
            else if
                psKernelExprPairSetContains
                  state.success
                  left
                  right then
              Except.ok
                (Prod.mk true state)
            else
              let whnf :=
                psKernelWhnfWithRecursorFuel
                  remaining
                  defeq;
              let coreWhnf :=
                psKernelWhnfCoreWithRecursorFuel
                  remaining
                  defeq;
              let inferType :=
                psKernelInferWithRecursorFuel
                  remaining
                  defeq;
              match
                  psKernelDefEqQuick
                    defeq
                    nextContext
                    state
                    left
                    right
                    true with
              | Except.error error =>
                  Except.error error
              | Except.ok quickResult =>
                  match Prod.fst quickResult with
                  | Option.some value =>
                      Except.ok
                        (psKernelDefEqFinish
                          (Prod.snd quickResult)
                          left
                          right
                          value)
                  | Option.none =>
                      match
                          psKernelDefEqReflectionWith
                            whnf
                            nextContext
                            (Prod.snd quickResult)
                            left
                            right with
                      | Except.error error =>
                          Except.error error
                      | Except.ok reflectionResult =>
                          match Prod.fst reflectionResult with
                          | Option.some value =>
                              Except.ok
                                (psKernelDefEqFinish
                                  (Prod.snd reflectionResult)
                                  left
                                  right
                                  value)
                          | Option.none =>
                              match
                                  coreWhnf
                                    nextContext
                                    (Prod.snd reflectionResult)
                                    left
                                    false
                                    true with
                              | Except.error error =>
                                  Except.error error
                              | Except.ok leftCoreResult =>
                                  match
                                      coreWhnf
                                        nextContext
                                        (Prod.snd leftCoreResult)
                                        right
                                        false
                                        true with
                                  | Except.error error =>
                                      Except.error error
                                  | Except.ok rightCoreResult =>
                                      let leftCore :=
                                        Prod.fst leftCoreResult;
                                      let rightCore :=
                                        Prod.fst rightCoreResult;
                                      match
                                          psKernelDefEqQuick
                                            defeq
                                            nextContext
                                            (Prod.snd rightCoreResult)
                                            leftCore
                                            rightCore
                                            false with
                                      | Except.error error =>
                                          Except.error error
                                      | Except.ok coreQuick =>
                                          match Prod.fst coreQuick with
                                          | Option.some value =>
                                              Except.ok
                                                (psKernelDefEqFinish
                                                  (Prod.snd coreQuick)
                                                  left
                                                  right
                                                  value)
                                          | Option.none =>
                                              match
                                                  inferType
                                                    nextContext
                                                    (Prod.snd coreQuick)
                                                    leftCore with
                                              | Except.error error =>
                                                  Except.error error
                                              | Except.ok leftTypeResult =>
                                                  match
                                                      psKernelDefEqIsPropWith
                                                        inferType
                                                        whnf
                                                        nextContext
                                                        (Prod.snd leftTypeResult)
                                                        (Prod.fst leftTypeResult) with
                                                  | Except.error error =>
                                                      Except.error error
                                                  | Except.ok proofResult =>
                                                      if Prod.fst proofResult then
                                                        match
                                                            inferType
                                                              nextContext
                                                              (Prod.snd proofResult)
                                                              rightCore with
                                                        | Except.error error =>
                                                            Except.error error
                                                        | Except.ok rightTypeResult =>
                                                            match
                                                                defeq
                                                                  nextContext
                                                                  (Prod.snd rightTypeResult)
                                                                  (Prod.fst leftTypeResult)
                                                                  (Prod.fst rightTypeResult) with
                                                            | Except.error error =>
                                                                Except.error error
                                                            | Except.ok proofEqual =>
                                                                Except.ok
                                                                  (psKernelDefEqFinish
                                                                    (Prod.snd proofEqual)
                                                                    left
                                                                    right
                                                                    (Prod.fst proofEqual))
                                                      else
                                                        match
                                                            psKernelDefEqLazyReductionWithFuel
                                                              remaining
                                                              defeq
                                                              whnf
                                                              coreWhnf
                                                              nextContext
                                                              (Prod.snd proofResult)
                                                              leftCore
                                                              rightCore with
                                                        | Except.error error =>
                                                            Except.error error
                                                        | Except.ok deltaResult =>
                                                            match Prod.fst deltaResult with
                                                            | PsKernelDeltaResult.decided value =>
                                                                Except.ok
                                                                  (psKernelDefEqFinish
                                                                    (Prod.snd deltaResult)
                                                                    left
                                                                    right
                                                                    value)
                                                            | PsKernelDeltaResult.residual leftDelta rightDelta =>
                                                                match
                                                                    psKernelDefEqProjectionShortcut
                                                                      defeq
                                                                      nextContext
                                                                      (Prod.snd deltaResult)
                                                                      leftDelta
                                                                      rightDelta with
                                                                | Except.error error =>
                                                                    Except.error error
                                                                | Except.ok shortcutResult =>
                                                                    match Prod.fst shortcutResult with
                                                                    | Option.some value =>
                                                                        Except.ok
                                                                          (psKernelDefEqFinish
                                                                            (Prod.snd shortcutResult)
                                                                            left
                                                                            right
                                                                            value)
                                                                    | Option.none =>
                                                                        match
                                                                            coreWhnf
                                                                              nextContext
                                                                              (Prod.snd shortcutResult)
                                                                              leftDelta
                                                                              false
                                                                              false with
                                                                        | Except.error error =>
                                                                            Except.error error
                                                                        | Except.ok leftFullResult =>
                                                                            match
                                                                                coreWhnf
                                                                                  nextContext
                                                                                  (Prod.snd leftFullResult)
                                                                                  rightDelta
                                                                                  false
                                                                                  false with
                                                                            | Except.error error =>
                                                                                Except.error error
                                                                            | Except.ok rightFullResult =>
                                                                                let leftFull :=
                                                                                  Prod.fst leftFullResult;
                                                                                let rightFull :=
                                                                                  Prod.fst rightFullResult;
                                                                                let changed :=
                                                                                  if
                                                                                      psKernelExprEq
                                                                                        leftFull
                                                                                        leftDelta then
                                                                                    if
                                                                                        psKernelExprEq
                                                                                          rightFull
                                                                                          rightDelta then
                                                                                      false
                                                                                    else
                                                                                      true
                                                                                  else
                                                                                    true;
                                                                                if changed then
                                                                                  match
                                                                                      defeq
                                                                                        nextContext
                                                                                        (Prod.snd rightFullResult)
                                                                                        leftFull
                                                                                        rightFull with
                                                                                  | Except.error error =>
                                                                                      Except.error error
                                                                                  | Except.ok changedResult =>
                                                                                      Except.ok
                                                                                        (psKernelDefEqFinish
                                                                                          (Prod.snd changedResult)
                                                                                          left
                                                                                          right
                                                                                          (Prod.fst changedResult))
                                                                                else
                                                                                  match
                                                                                      psKernelDefEqFullShapeWith
                                                                                        defeq
                                                                                        inferType
                                                                                        whnf
                                                                                        nextContext
                                                                                        (Prod.snd rightFullResult)
                                                                                        leftFull
                                                                                        rightFull with
                                                                                  | Except.error error =>
                                                                                      Except.error error
                                                                                  | Except.ok shapeResult =>
                                                                                      match Prod.fst shapeResult with
                                                                                      | Option.some value =>
                                                                                          Except.ok
                                                                                            (psKernelDefEqFinish
                                                                                              (Prod.snd shapeResult)
                                                                                              left
                                                                                              right
                                                                                              value)
                                                                                      | Option.none =>
                                                                                          psKernelIsDefEqAfterFullShape
                                                                                            defeq
                                                                                            inferType
                                                                                            whnf
                                                                                            nextContext
                                                                                            (Prod.snd shapeResult)
                                                                                            left
                                                                                            right
                                                                                            leftFull
                                                                                            rightFull

def tracedWithFuel
    (fuel : Nat) :
    PsKernelCheckerContext ->
    PsKernelCheckerState ->
    PsKernelExpr ->
    PsKernelExpr ->
    Except String
      (Prod Bool PsKernelCheckerState) :=
  match fuel with
  | Nat.zero =>
      fun
        (_context : PsKernelCheckerContext)
        (_state : PsKernelCheckerState)
        (_left : PsKernelExpr)
        (_right : PsKernelExpr) =>
        traceAttempt 0 "zero-guard" _context _state _left _right
          (Except.error
            "kernel definitional equality budget exhausted")
  | Nat.succ remaining =>
      fun
        (context : PsKernelCheckerContext)
        (state : PsKernelCheckerState)
        (left : PsKernelExpr)
        (right : PsKernelExpr) =>
        let defeq :
            PsKernelCheckerContext ->
            PsKernelCheckerState ->
            PsKernelExpr ->
            PsKernelExpr ->
            Except String
              (Prod Bool PsKernelCheckerState) :=
          tracedWithFuel remaining;
        match
            traceAttempt fuel "depth-guard" context state left right
              (psKernelCheckerContextEnterRecDepth
                context) with
        | Except.error error =>
            Except.error error
        | Except.ok nextContext =>
            if psKernelExprEq left right then
              Except.ok
                (psKernelDefEqFinish
                  state
                  left
                  right
                  true)
            else if
                psKernelExprPairSetContains
                  state.success
                  left
                  right then
              Except.ok
                (Prod.mk true state)
            else
              let whnf :=
                psKernelWhnfWithRecursorFuel
                  remaining
                  defeq;
              let coreWhnf :=
                psKernelWhnfCoreWithRecursorFuel
                  remaining
                  defeq;
              let inferType :=
                psKernelInferWithRecursorFuel
                  remaining
                  defeq;
              match
                  traceAttempt fuel "quick" nextContext state left right
                    (psKernelDefEqQuick
                      defeq
                      nextContext
                      state
                      left
                      right
                      true) with
              | Except.error error =>
                  Except.error error
              | Except.ok quickResult =>
                  match Prod.fst quickResult with
                  | Option.some value =>
                      Except.ok
                        (psKernelDefEqFinish
                          (Prod.snd quickResult)
                          left
                          right
                          value)
                  | Option.none =>
                      match
                          traceAttempt fuel "reflection" nextContext (Prod.snd quickResult) left right
                            (psKernelDefEqReflectionWith
                              whnf
                              nextContext
                              (Prod.snd quickResult)
                              left
                              right) with
                      | Except.error error =>
                          Except.error error
                      | Except.ok reflectionResult =>
                          match Prod.fst reflectionResult with
                          | Option.some value =>
                              Except.ok
                                (psKernelDefEqFinish
                                  (Prod.snd reflectionResult)
                                  left
                                  right
                                  value)
                          | Option.none =>
                              match
                                  traceAttempt fuel "cheap-left" nextContext (Prod.snd reflectionResult) left right
                                    (coreWhnf
                                      nextContext
                                      (Prod.snd reflectionResult)
                                      left
                                      false
                                      true) with
                              | Except.error error =>
                                  Except.error error
                              | Except.ok leftCoreResult =>
                                  match
                                      traceAttempt fuel "cheap-right" nextContext (Prod.snd leftCoreResult) (Prod.fst leftCoreResult) right
                                        (coreWhnf
                                          nextContext
                                          (Prod.snd leftCoreResult)
                                          right
                                          false
                                          true) with
                                  | Except.error error =>
                                      Except.error error
                                  | Except.ok rightCoreResult =>
                                      let leftCore :=
                                        Prod.fst leftCoreResult;
                                      let rightCore :=
                                        Prod.fst rightCoreResult;
                                      match
                                          traceAttempt fuel "quick-after-core" nextContext (Prod.snd rightCoreResult) leftCore rightCore
                                            (psKernelDefEqQuick
                                              defeq
                                              nextContext
                                              (Prod.snd rightCoreResult)
                                              leftCore
                                              rightCore
                                              false) with
                                      | Except.error error =>
                                          Except.error error
                                      | Except.ok coreQuick =>
                                          match Prod.fst coreQuick with
                                          | Option.some value =>
                                              Except.ok
                                                (psKernelDefEqFinish
                                                  (Prod.snd coreQuick)
                                                  left
                                                  right
                                                  value)
                                          | Option.none =>
                                              match
                                                  traceAttempt fuel "left-type" nextContext (Prod.snd coreQuick) leftCore rightCore
                                                    (inferType
                                                      nextContext
                                                      (Prod.snd coreQuick)
                                                      leftCore) with
                                              | Except.error error =>
                                                  Except.error error
                                              | Except.ok leftTypeResult =>
                                                  match
                                                      traceAttempt fuel "is-proposition" nextContext (Prod.snd leftTypeResult) (Prod.fst leftTypeResult) rightCore
                                                        (psKernelDefEqIsPropWith
                                                          inferType
                                                          whnf
                                                          nextContext
                                                          (Prod.snd leftTypeResult)
                                                          (Prod.fst leftTypeResult)) with
                                                  | Except.error error =>
                                                      Except.error error
                                                  | Except.ok proofResult =>
                                                      if Prod.fst proofResult then
                                                        match
                                                            traceAttempt fuel "right-type" nextContext (Prod.snd proofResult) leftCore rightCore
                                                              (inferType
                                                                nextContext
                                                                (Prod.snd proofResult)
                                                                rightCore) with
                                                        | Except.error error =>
                                                            Except.error error
                                                        | Except.ok rightTypeResult =>
                                                            match
                                                                traceAttempt fuel "proof-type-defeq" nextContext (Prod.snd rightTypeResult) (Prod.fst leftTypeResult) (Prod.fst rightTypeResult)
                                                                  (defeq
                                                                    nextContext
                                                                    (Prod.snd rightTypeResult)
                                                                    (Prod.fst leftTypeResult)
                                                                    (Prod.fst rightTypeResult)) with
                                                            | Except.error error =>
                                                                Except.error error
                                                            | Except.ok proofEqual =>
                                                                Except.ok
                                                                  (psKernelDefEqFinish
                                                                    (Prod.snd proofEqual)
                                                                    left
                                                                    right
                                                                    (Prod.fst proofEqual))
                                                      else
                                                        match
                                                            traceAttempt fuel "lazy-delta" nextContext (Prod.snd proofResult) leftCore rightCore
                                                              (psKernelDefEqLazyReductionWithFuel
                                                                remaining
                                                                defeq
                                                                whnf
                                                                coreWhnf
                                                                nextContext
                                                                (Prod.snd proofResult)
                                                                leftCore
                                                                rightCore) with
                                                        | Except.error error =>
                                                            Except.error error
                                                        | Except.ok deltaResult =>
                                                            match Prod.fst deltaResult with
                                                            | PsKernelDeltaResult.decided value =>
                                                                Except.ok
                                                                  (psKernelDefEqFinish
                                                                    (Prod.snd deltaResult)
                                                                    left
                                                                    right
                                                                    value)
                                                            | PsKernelDeltaResult.residual leftDelta rightDelta =>
                                                                match
                                                                    traceAttempt fuel "projection-shortcut" nextContext (Prod.snd deltaResult) leftDelta rightDelta
                                                                      (psKernelDefEqProjectionShortcut
                                                                        defeq
                                                                        nextContext
                                                                        (Prod.snd deltaResult)
                                                                        leftDelta
                                                                        rightDelta) with
                                                                | Except.error error =>
                                                                    Except.error error
                                                                | Except.ok shortcutResult =>
                                                                    match Prod.fst shortcutResult with
                                                                    | Option.some value =>
                                                                        Except.ok
                                                                          (psKernelDefEqFinish
                                                                            (Prod.snd shortcutResult)
                                                                            left
                                                                            right
                                                                            value)
                                                                    | Option.none =>
                                                                        match
                                                                            traceAttempt fuel "full-left" nextContext (Prod.snd shortcutResult) leftDelta rightDelta
                                                                              (coreWhnf
                                                                                nextContext
                                                                                (Prod.snd shortcutResult)
                                                                                leftDelta
                                                                                false
                                                                                false) with
                                                                        | Except.error error =>
                                                                            Except.error error
                                                                        | Except.ok leftFullResult =>
                                                                            match
                                                                                traceAttempt fuel "full-right" nextContext (Prod.snd leftFullResult) (Prod.fst leftFullResult) rightDelta
                                                                                  (coreWhnf
                                                                                    nextContext
                                                                                    (Prod.snd leftFullResult)
                                                                                    rightDelta
                                                                                    false
                                                                                    false) with
                                                                            | Except.error error =>
                                                                                Except.error error
                                                                            | Except.ok rightFullResult =>
                                                                                let leftFull :=
                                                                                  Prod.fst leftFullResult;
                                                                                let rightFull :=
                                                                                  Prod.fst rightFullResult;
                                                                                let changed :=
                                                                                  if
                                                                                      psKernelExprEq
                                                                                        leftFull
                                                                                        leftDelta then
                                                                                    if
                                                                                        psKernelExprEq
                                                                                          rightFull
                                                                                          rightDelta then
                                                                                      false
                                                                                    else
                                                                                      true
                                                                                  else
                                                                                    true;
                                                                                if changed then
                                                                                  match
                                                                                      traceAttempt fuel "changed-retry" nextContext (Prod.snd rightFullResult) leftFull rightFull
                                                                                        (defeq
                                                                                          nextContext
                                                                                          (Prod.snd rightFullResult)
                                                                                          leftFull
                                                                                          rightFull) with
                                                                                  | Except.error error =>
                                                                                      Except.error error
                                                                                  | Except.ok changedResult =>
                                                                                      Except.ok
                                                                                        (psKernelDefEqFinish
                                                                                          (Prod.snd changedResult)
                                                                                          left
                                                                                          right
                                                                                          (Prod.fst changedResult))
                                                                                else
                                                                                  match
                                                                                      traceAttempt fuel "full-shape" nextContext (Prod.snd rightFullResult) leftFull rightFull
                                                                                        (psKernelDefEqFullShapeWith
                                                                                          defeq
                                                                                          inferType
                                                                                          whnf
                                                                                          nextContext
                                                                                          (Prod.snd rightFullResult)
                                                                                          leftFull
                                                                                          rightFull) with
                                                                                  | Except.error error =>
                                                                                      Except.error error
                                                                                  | Except.ok shapeResult =>
                                                                                      match Prod.fst shapeResult with
                                                                                      | Option.some value =>
                                                                                          Except.ok
                                                                                            (psKernelDefEqFinish
                                                                                              (Prod.snd shapeResult)
                                                                                              left
                                                                                              right
                                                                                              value)
                                                                                      | Option.none =>
                                                                                          traceAttempt fuel "final-rules" nextContext (Prod.snd shapeResult) leftFull rightFull
                                                                                            (psKernelIsDefEqAfterFullShape
                                                                                              defeq
                                                                                              inferType
                                                                                              whnf
                                                                                              nextContext
                                                                                              (Prod.snd shapeResult)
                                                                                              left
                                                                                              right
                                                                                              leftFull
                                                                                              rightFull)

theorem frozen_eq_original (fuel : Nat) :
    frozenWithFuel fuel = psKernelIsDefEqWithFuel fuel := by
  induction fuel with
  | zero => rfl
  | succ remaining ih =>
      funext context state left right
      simp only [frozenWithFuel, psKernelIsDefEqWithFuel, ih] <;> rfl

theorem traced_eq_frozen (fuel : Nat) :
    tracedWithFuel fuel = frozenWithFuel fuel := by
  induction fuel with
  | zero =>
      funext context state left right
      simp only [tracedWithFuel, frozenWithFuel, traceAttempt_identity]
  | succ remaining ih =>
      funext context state left right
      simp only [tracedWithFuel, frozenWithFuel, traceAttempt_identity, ih] <;> rfl

theorem traced_eq_original (fuel : Nat) :
    tracedWithFuel fuel = psKernelIsDefEqWithFuel fuel :=
  (traced_eq_frozen fuel).trans (frozen_eq_original fuel)

def sessionIsDefEq (fuel : Nat) (session : PsKernelCheckerSession)
    (left right : PsKernelExpr) : Except String (Bool × PsKernelCheckerSession) :=
  match tracedWithFuel fuel session.context session.state left right with
  | .error message => .error message
  | .ok result => .ok (result.fst, PsKernelCheckerSession.mk session.context result.snd)

theorem session_eq_original (fuel : Nat) (session : PsKernelCheckerSession)
    (left right : PsKernelExpr) :
    sessionIsDefEq fuel session left right =
      psKernelSessionIsDefEq fuel session left right := by
  simp only [sessionIsDefEq, psKernelSessionIsDefEq, psKernelIsDefEq, traced_eq_original] <;> rfl

#print axioms traceAttempt_identity
#print axioms frozen_eq_original
#print axioms traced_eq_frozen
#print axioms traced_eq_original
#print axioms session_eq_original

end NativeChurchDefEqTrace
