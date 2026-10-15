import Ps.Core.Expr
import Ps.Environment.LocalContext

structure PsInstanceEntry where
  value : PsExpr
  type : PsExpr
  priority : Nat := 1000
  className : Option PsName := none
  levelParams : List PsName := []

structure PsInstanceIndex where
  entries : List PsInstanceEntry
  -- Default candidates are considered only after ordinary synthesis is stuck.
  defaults : List PsInstanceEntry := []

def psInstanceIndexEmpty : PsInstanceIndex :=
  { entries := [] }

def psInstanceListAppend
    (left : List PsInstanceEntry)
    (right : List PsInstanceEntry) : List PsInstanceEntry :=
  match left with
  | [] => right
  | entry :: rest =>
      List.cons entry (psInstanceListAppend rest right)

-- Higher priority precedes lower priority; equal priorities prefer the most
-- recently registered declaration, matching the native instance stack.
def psInstanceInsert (entry : PsInstanceEntry) (entries : List PsInstanceEntry) :
    List PsInstanceEntry :=
  match entries with
  | [] => [entry]
  | first :: rest =>
    if entry.priority >= first.priority then entry :: entries
    else first :: psInstanceInsert entry rest

def psInstanceIndexAdd
    (index : PsInstanceIndex)
    (entry : PsInstanceEntry) : PsInstanceIndex :=
  { index with entries := psInstanceInsert entry index.entries }

def psLocalInstanceEntriesFromList
    (declarations : List PsLocalDecl) : List PsInstanceEntry :=
  match declarations with
  | [] => []
  | declaration :: rest =>
      match declaration with
      | .binding id _ type binder =>
          match binder with
          | .instanceImplicit =>
              let instanceEntry : PsInstanceEntry := {
                value := PsExpr.fvar id
                type := type
              };
              List.cons instanceEntry (psLocalInstanceEntriesFromList rest)
          | _ =>
              psLocalInstanceEntriesFromList rest
      | _ => psLocalInstanceEntriesFromList rest

def psLocalInstanceEntries (context : PsLocalContext) : List PsInstanceEntry :=
  psLocalInstanceEntriesFromList context.declarations

def psAllInstanceEntries
    (context : PsLocalContext)
    (index : PsInstanceIndex) : List PsInstanceEntry :=
  psInstanceListAppend
    (psLocalInstanceEntries context)
    index.entries

-- Keep the same priority/tie ordering, but a separate semantic registry.
def psInstanceIndexAddDefault (index : PsInstanceIndex)
    (entry : PsInstanceEntry) : PsInstanceIndex :=
  { index with defaults := psInstanceInsert entry index.defaults }
