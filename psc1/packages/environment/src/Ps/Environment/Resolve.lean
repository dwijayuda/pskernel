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
  | Option.some declaration => Option.some (PsResolvedName.local (psLocalDeclId declaration))
  | Option.none =>
      match psEnvironmentFind environment name with
      | Option.some _ => Option.some (PsResolvedName.global name)
      | Option.none => Option.none
