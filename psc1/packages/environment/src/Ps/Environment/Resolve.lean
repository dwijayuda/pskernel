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

def psResolveAppendName (prefix : PsName) : PsName -> PsName
  | .anonymous => prefix
  | .str parent segment => .str (psResolveAppendName prefix parent) segment
  | .num parent value => .num (psResolveAppendName prefix parent) value

def psResolveGlobalCandidate
    (environment : PsEnvironment) (self : Option PsName) (name : PsName) : Bool :=
  match self with
  | .some target =>
      if psNameEq target name then true
      else match psEnvironmentFind environment name with
        | .some _ => true
        | .none => false
  | .none =>
      match psEnvironmentFind environment name with
      | .some _ => true
      | .none => false

def psResolveGlobalInNamespace
    (environment : PsEnvironment) (self : Option PsName) (name : PsName) :
    PsName -> Option PsName
  | .anonymous =>
      if psResolveGlobalCandidate environment self name then .some name else .none
  | .str parent segment =>
      let current := PsName.str parent segment
      let candidate := psResolveAppendName current name
      if psResolveGlobalCandidate environment self candidate then .some candidate
      else psResolveGlobalInNamespace environment self name parent
  | .num parent value =>
      let current := PsName.num parent value
      let candidate := psResolveAppendName current name
      if psResolveGlobalCandidate environment self candidate then .some candidate
      else psResolveGlobalInNamespace environment self name parent

def psResolveNameInNamespace
    (localContext : PsLocalContext) (environment : PsEnvironment)
    (currentNamespace : PsName) (name : PsName)
    (self : Option PsName := Option.none) : Option PsResolvedName :=
  match psLocalFindUser localContext name with
  | .some declaration => .some (.local (psLocalDeclId declaration))
  | .none =>
      match psResolveGlobalInNamespace environment self name currentNamespace with
      | .some selected => .some (.global selected)
      | .none => .none

def psResolveNameIsTarget
    (localContext : PsLocalContext) (environment : PsEnvironment)
    (currentNamespace name target : PsName) : Bool :=
  match psResolveNameInNamespace localContext environment currentNamespace name (.some target) with
  | .some (.global selected) => psNameEq selected target
  | _ => false
