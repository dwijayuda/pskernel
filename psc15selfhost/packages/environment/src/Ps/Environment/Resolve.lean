import Ps.Environment.Basic
import Ps.Environment.LocalContext

inductive PsResolvedName where
  | local (id : Nat)
  | global (name : PsName)

def psResolveGlobalInNamespace
    (environment : PsEnvironment)
    (namespacePrefix : PsName)
    (name : PsName) : Option PsName :=
  match namespacePrefix with
  | PsName.anonymous =>
      match psEnvironmentFind environment name with
      | Option.some _ => Option.some name
      | Option.none => Option.none
  | PsName.str parent _ =>
      let candidate := psNameAppendName namespacePrefix name;
      match psEnvironmentFind environment candidate with
      | Option.some _ => Option.some candidate
      | Option.none =>
          psResolveGlobalInNamespace environment parent name
  | PsName.num parent _ =>
      let candidate := psNameAppendName namespacePrefix name;
      match psEnvironmentFind environment candidate with
      | Option.some _ => Option.some candidate
      | Option.none =>
          psResolveGlobalInNamespace environment parent name

def psResolveNameScoped
    (localContext : PsLocalContext)
    (environment : PsEnvironment)
    (namespacePrefix : PsName)
    (name : PsName) : Option PsResolvedName :=
  match psLocalFindUser localContext name with
  | Option.some declaration =>
      Option.some (PsResolvedName.local (psLocalDeclId declaration))
  | Option.none =>
      match
          psResolveGlobalInNamespace
            environment
            namespacePrefix
            name with
      | Option.some resolved =>
          Option.some (PsResolvedName.global resolved)
      | Option.none =>
          Option.none

def psResolveName
    (localContext : PsLocalContext)
    (environment : PsEnvironment)
    (name : PsName) : Option PsResolvedName :=
  psResolveNameScoped
    localContext
    environment
    PsName.anonymous
    name
