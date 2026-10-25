import Ps.Foundation.Source
import Ps.Environment.LocalContext

/-! Opt-in source provenance from actual allocation and resolution.
Raw local IDs are scoped lookup keys. Event ordinals are unique within one
actual declaration execution; the host attaches module/snapshot/member identity.
Disabled tracing never accumulates events. None of these records grants editing,
admission or publication authority. -/

structure PsElabSourceBinder where
  index : Nat
  localId : Nat
  name : PsName
  type : PsExpr
  parent : Option Nat
  source : Option PsSourceSpan

inductive PsElabSourceTarget where
  | local (localId : Nat) (binder : Option Nat)
  | global (name : PsName)
  | sort

structure PsElabSourceReference where
  index : Nat
  sourceName : PsName
  span : PsSourceSpan
  baseSegments : Nat
  target : PsElabSourceTarget

structure PsElabSourceTrace where
  enabled : Bool
  nextId : Nat
  bindersRev : List PsElabSourceBinder
  referencesRev : List PsElabSourceReference
  active : List (Prod Nat Nat)
  complete : Bool

def psElabSourceTraceEmpty (enabled : Bool) : PsElabSourceTrace :=
  PsElabSourceTrace.mk enabled 0 [] [] [] true

def psElabSourceTraceFind (active : List (Prod Nat Nat)) (localId : Nat) : Option Nat :=
  match active with
  | [] => Option.none
  | entry :: rest =>
      if Nat.beq entry.fst localId then Option.some entry.snd
      else psElabSourceTraceFind rest localId

def psElabSourceTracePrune (active : List (Prod Nat Nat)) (locals : PsLocalContext) :
    List (Prod Nat Nat) :=
  match active with
  | [] => []
  | entry :: rest =>
      let tail := psElabSourceTracePrune rest locals;
      if psLocalContainsId locals entry.fst then List.cons entry tail else tail

def psElabSourceTraceAddLocal (trace : PsElabSourceTrace) (entry : PsLocalDecl) :
    PsElabSourceTrace :=
  match psElabSourceTraceFind trace.active (psLocalDeclId entry) with
  | Option.some _ => trace
  | Option.none =>
      let parent := match trace.active with
        | [] => Option.none
        | first :: _ => Option.some first.snd;
      let binder := PsElabSourceBinder.mk trace.nextId (psLocalDeclId entry)
        (psLocalDeclUserName entry) (psLocalDeclType entry) parent Option.none;
      PsElabSourceTrace.mk true (Nat.succ trace.nextId)
        (List.cons binder trace.bindersRev) trace.referencesRev
        (List.cons (Prod.mk binder.localId binder.index) trace.active) trace.complete

-- Oldest allocation first, even though local contexts store newest first.
def psElabSourceTraceLocalsFold (entries : List PsLocalDecl) :
    PsElabSourceTrace -> PsElabSourceTrace :=
  match entries with
  | [] => fun (trace : PsElabSourceTrace) => trace
  | entry :: rest =>
      let smaller : PsElabSourceTrace -> PsElabSourceTrace :=
        psElabSourceTraceLocalsFold rest;
      fun (trace : PsElabSourceTrace) =>
        psElabSourceTraceAddLocal (smaller trace) entry

def psElabSourceTraceWithLocals (trace : PsElabSourceTrace) (locals : PsLocalContext) :
    PsElabSourceTrace :=
  if trace.enabled then
    let pruned := PsElabSourceTrace.mk true trace.nextId trace.bindersRev
      trace.referencesRev (psElabSourceTracePrune trace.active locals) trace.complete;
    psElabSourceTraceLocalsFold locals.declarations pruned
  else trace

def psElabSourceTraceMarkBinder (binders : List PsElabSourceBinder)
    (index : Nat) (span : PsSourceSpan) : List PsElabSourceBinder :=
  match binders with
  | [] => []
  | head :: rest =>
      if Nat.beq head.index index then
        List.cons (PsElabSourceBinder.mk head.index head.localId head.name head.type
          head.parent (Option.some span)) rest
      else List.cons head (psElabSourceTraceMarkBinder rest index span)

def psElabSourceTraceAtBinder (trace : PsElabSourceTrace)
    (localId : Nat) (span : PsSourceSpan) : PsElabSourceTrace :=
  if trace.enabled then
    match psElabSourceTraceFind trace.active localId with
    | Option.none =>
        PsElabSourceTrace.mk true trace.nextId trace.bindersRev trace.referencesRev
          trace.active false
    | Option.some index =>
        PsElabSourceTrace.mk true trace.nextId
          (psElabSourceTraceMarkBinder trace.bindersRev index span)
          trace.referencesRev trace.active trace.complete
  else trace

def psElabSourceTraceReference (trace : PsElabSourceTrace)
    (sourceName : PsName) (span : PsSourceSpan) (baseSegments : Nat)
    (target : PsElabSourceTarget) : PsElabSourceTrace :=
  if trace.enabled then
    let complete := match target with
      | PsElabSourceTarget.local _ Option.none => false
      | _ => trace.complete;
    let entry := PsElabSourceReference.mk trace.nextId sourceName span baseSegments target;
    PsElabSourceTrace.mk true (Nat.succ trace.nextId) trace.bindersRev
      (List.cons entry trace.referencesRev) trace.active complete
  else trace

-- Restore lexical scope while retaining the successful inner execution's log.
-- Failed speculative branches return no context and therefore no events.
def psElabSourceTraceRestore (outer inner : PsElabSourceTrace) : PsElabSourceTrace :=
  if outer.enabled then
    if inner.enabled then
      PsElabSourceTrace.mk true inner.nextId inner.bindersRev inner.referencesRev
        outer.active (if Nat.blt inner.nextId outer.nextId then false else outer.complete && inner.complete)
    else PsElabSourceTrace.mk true outer.nextId outer.bindersRev outer.referencesRev
      outer.active false
  else outer
