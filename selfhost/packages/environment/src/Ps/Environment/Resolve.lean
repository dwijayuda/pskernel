import Ps.Environment.Basic
import Ps.Environment.LocalContext

inductive PsResolvedName where
  | local (id : Nat)
  | global (name : PsName)

def psResolveName
    (localContext : PsLocalContext)
    (environment : PsEnvironment)
    (name : PsName) : Option PsResolvedName :=
  match psLocalFindUser localContext name with
  | some declaration => some (PsResolvedName.local (psLocalDeclId declaration))
  | none =>
      match psEnvironmentFind environment name with
      | some _ => some (PsResolvedName.global name)
      | none => none
