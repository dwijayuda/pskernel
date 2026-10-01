import Ps.Core.Expr
import Ps.Environment.LocalContext

structure PsInstanceEntry where
  value : PsExpr
  type : PsExpr

structure PsInstanceIndex where
  entries : List PsInstanceEntry

def psInstanceIndexEmpty : PsInstanceIndex :=
  { entries := [] }

def psInstanceListAppend
    (left : List PsInstanceEntry)
    (right : List PsInstanceEntry) : List PsInstanceEntry :=
  match left with
  | [] => right
  | entry :: rest =>
      List.cons entry (psInstanceListAppend rest right)

def psInstanceIndexAdd
    (index : PsInstanceIndex)
    (entry : PsInstanceEntry) : PsInstanceIndex :=
  { entries := psInstanceListAppend index.entries (List.cons entry []) }

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
