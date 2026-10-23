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

def psResolveAppendName (namespacePrefix : PsName) (name : PsName) : PsName :=
  match name with
  | PsName.anonymous => namespacePrefix
  | PsName.str parent segment => PsName.str (psResolveAppendName namespacePrefix parent) segment
  | PsName.num parent value => PsName.num (psResolveAppendName namespacePrefix parent) value

-- A leading _root_ belongs to reference syntax, never declaration identity.
-- Preserve its spelling in the AST and remove it only during global selection.
def psResolveExplicitRoot (name : PsName) : Option PsName :=
  match name with
  | PsName.anonymous => Option.none
  | PsName.str parent segment =>
      match parent with
      | PsName.anonymous =>
          if psStringEq segment "_root_" then Option.some PsName.anonymous else Option.none
      | _ =>
          match psResolveExplicitRoot parent with
          | Option.none => Option.none
          | Option.some absolute => Option.some (PsName.str absolute segment)
  | PsName.num parent value =>
      match psResolveExplicitRoot parent with
      | Option.none => Option.none
      | Option.some absolute => Option.some (PsName.num absolute value)

def psResolveGlobalCandidate
    (environment : PsEnvironment) (self : Option PsName) (name : PsName) : Bool :=
  match self with
  | Option.some target =>
      if psNameEq target name then true
      else match psEnvironmentFind environment name with
        | Option.some _ => true
        | Option.none => false
  | Option.none =>
      match psEnvironmentFind environment name with
      | Option.some _ => true
      | Option.none => false

def psResolveGlobalInNamespaceWorker
    (environment : PsEnvironment) (self : Option PsName) (name : PsName)
    (currentNamespace : PsName) : Option PsName :=
  match currentNamespace with
  | PsName.anonymous =>
      if psResolveGlobalCandidate environment self name then Option.some name else Option.none
  | PsName.str parent segment =>
      let current := PsName.str parent segment;
      let candidate := psResolveAppendName current name;
      if psResolveGlobalCandidate environment self candidate then Option.some candidate
      else psResolveGlobalInNamespaceWorker environment self name parent
  | PsName.num parent value =>
      let current := PsName.num parent value;
      let candidate := psResolveAppendName current name;
      if psResolveGlobalCandidate environment self candidate then Option.some candidate
      else psResolveGlobalInNamespaceWorker environment self name parent

def psResolveGlobalInNamespace
    (environment : PsEnvironment) (self : Option PsName) (name currentNamespace : PsName) :
    Option PsName :=
  match psResolveExplicitRoot name with
  | Option.some absolute =>
      if psResolveGlobalCandidate environment self absolute then Option.some absolute else Option.none
  | Option.none => psResolveGlobalInNamespaceWorker environment self name currentNamespace

def psResolveNameInNamespaceWithSelf
    (localContext : PsLocalContext) (environment : PsEnvironment)
    (currentNamespace : PsName) (name : PsName)
    (self : Option PsName) : Option PsResolvedName :=
  match psResolveExplicitRoot name with
  | Option.some absolute =>
      if psResolveGlobalCandidate environment self absolute then Option.some (PsResolvedName.global absolute)
      else Option.none
  | Option.none =>
      match psLocalFindUser localContext name with
      | Option.some declaration => Option.some (PsResolvedName.local (psLocalDeclId declaration))
      | Option.none =>
          match psResolveGlobalInNamespaceWorker environment self name currentNamespace with
          | Option.some selected => Option.some (PsResolvedName.global selected)
          | Option.none => Option.none

-- The default namespace resolver is explicit; self-candidates use the helper above.
def psResolveNameInNamespace
    (localContext : PsLocalContext) (environment : PsEnvironment)
    (currentNamespace : PsName) (name : PsName) : Option PsResolvedName :=
  psResolveNameInNamespaceWithSelf localContext environment currentNamespace name Option.none

def psResolveNameIsTarget
    (localContext : PsLocalContext) (environment : PsEnvironment)
    (currentNamespace name target : PsName) : Bool :=
  match psResolveNameInNamespaceWithSelf localContext environment currentNamespace name (Option.some target) with
  | Option.some resolved =>
      match resolved with
      | PsResolvedName.global selected => psNameEq selected target
      | _ => false
  | Option.none => false
