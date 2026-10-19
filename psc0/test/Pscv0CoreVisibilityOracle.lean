module
import Lean

-- Host-only oracle for the corresponding selected Lean/ProofScript project
-- fixture. It contributes no declarations to PSC0's production source closure.
private def CoreSelectedIdentity (A : Type) (x : A) : A := x

namespace CoreVisibility

def before (A : Type) (x : A) : A := CoreSelectedIdentity A x

public section Visible

def first (A : Type) (x : A) : A := before A x

section Nested

def innerSection (A : Type) (x : A) : A := first A x

end Nested

namespace Nested

def innerNamespace (A : Type) (x : A) : A := innerSection A x
private def overridden (A : Type) (x : A) : A := before A x
def throughPrivate (A : Type) (x : A) : A := overridden A x

end Nested

mutual
def mutualPublic (A : Type) (x : A) : A := mutualPrivate A x
private def mutualPrivate (A : Type) (x : A) : A := Nested.throughPrivate A x
end

def afterNamespace (A : Type) (x : A) : A := mutualPublic A x

end Visible

def afterPublic (A : Type) (x : A) : A := afterNamespace A x
public def finalValue (A : Type) (x : A) : A := afterPublic A x

end CoreVisibility

def rootAfter (A : Type) (x : A) : A := CoreVisibility.finalValue A x

public section

def anonymousPublic (A : Type) (x : A) : A := CoreVisibility.finalValue A x

public section NestedPublic

def nestedPublic (A : Type) (x : A) : A := anonymousPublic A x

end NestedPublic

def afterNestedPublic (A : Type) (x : A) : A := nestedPublic A x

end

def afterAnonymous (A : Type) (x : A) : A := afterNestedPublic A x


namespace CoreScopeDotted.A.B

variable (T : Type)
public def beforeEnd (x : T) : T := x

end B

variable (T : Type)
public def afterOne (x : T) : T := B.beforeEnd T x

end CoreScopeDotted.A

namespace CoreScopeSeparate
namespace Inner

public def value (T : Type) (x : T) : T := x

end CoreScopeSeparate.Inner

namespace CoreScopeMixed
section Inner

public def value (T : Type) (x : T) : T := x

end CoreScopeMixed.Inner

public section CoreScopeSection.A.B

def coreScopeSectionBefore (T : Type) (x : T) : T := x

end B

def coreScopeSectionPartial (T : Type) (x : T) : T :=
  coreScopeSectionBefore T x

end CoreScopeSection.A

def coreScopeSectionAfter (T : Type) (x : T) : T :=
  coreScopeSectionPartial T x

namespace CoreScopeRootMarker
namespace _root_.Inner

public def value (T : Type) (x : T) : T := x

end _root_.Inner
end CoreScopeRootMarker


public section

namespace Outer
namespace _root_.Inner

def nestedIdentity (A : Type) (x : A) : A := x

end _root_.Inner
end Outer

namespace _root_.Inner

def directIdentity (A : Type) (x : A) : A := x
abbrev exposedIdentity (A : Type) (x : A) : A := directIdentity A x
def inferredIdentity (A : Type) (x : A) := x

def whereIdentity (A : Type) (x : A) : A := whereIdentity.helper x
where
  helper (y : A) : A := y

mutual
  def mutualFirst (A : Type) (x : A) : A := mutualSecond A x
  def mutualSecond (A : Type) (x : A) : A := x
end

private def privateIdentity (A : Type) (x : A) : A := x
def privateBridge (A : Type) (x : A) : A := privateIdentity A x

structure RootBox (A : Type) where
  value : A

def _root_.absoluteIdentity (A : Type) (x : A) : A := x

end _root_.Inner

def rootedClient (A : Type) (x : A) : A := _root_._root_.Inner.directIdentity A x
def nestedClient (A : Type) (x : A) : A := Outer._root_.Inner.nestedIdentity A x

end

-- Pinned native Lean closes this section and namespace at EOF.
public section
namespace AtEof

def value (A : Type) (x : A) : A := afterAnonymous A x

run_cmd do
  let observations : List (Lean.Name × Bool) :=
    [(``CoreVisibility.before, true),
     (``CoreVisibility.first, false),
     (``CoreVisibility.innerSection, false),
     (``CoreVisibility.Nested.innerNamespace, false),
     (``CoreVisibility.Nested.overridden, true),
     (``CoreVisibility.Nested.throughPrivate, false),
     (``CoreVisibility.mutualPublic, false),
     (``CoreVisibility.mutualPrivate, true),
     (``CoreVisibility.afterNamespace, false),
     (``CoreVisibility.afterPublic, true),
     (``CoreVisibility.finalValue, false),
     (``rootAfter, true),
     (``anonymousPublic, false),
     (``nestedPublic, false),
     (``afterNestedPublic, false),
     (``afterAnonymous, true),
     (``AtEof.value, false),
     (``CoreScopeDotted.A.B.beforeEnd, false),
     (``CoreScopeDotted.A.afterOne, false),
     (``CoreScopeSeparate.Inner.value, false),
     (``CoreScopeMixed.value, false),
     (``coreScopeSectionBefore, false),
     (``coreScopeSectionPartial, false),
     (``coreScopeSectionAfter, true),
     (``CoreScopeRootMarker._root_.Inner.value, false)]
  for (name, expectedPrivate) in observations do
    unless Lean.isPrivateName name == expectedPrivate do
      throwError
        "PSCV0-CORE-VISIBILITY-ORACLE: private classification mismatch for {name}"

  let literalRoot : Lean.Name := .str (.str .anonymous "_root_") "Inner"
  let nestedRoot : Lean.Name := .str (.str (.str .anonymous "Outer") "_root_") "Inner"
  let rootBox : Lean.Name := .str literalRoot "RootBox"
  let rootedObservations : List (Lean.Name × Lean.Name × Bool) :=
    [(``_root_.Outer._root_.Inner.nestedIdentity, .str nestedRoot "nestedIdentity", false),
     (``_root_._root_.Inner.directIdentity, .str literalRoot "directIdentity", false),
     (``_root_._root_.Inner.exposedIdentity, .str literalRoot "exposedIdentity", false),
     (``_root_._root_.Inner.inferredIdentity, .str literalRoot "inferredIdentity", false),
     (``_root_._root_.Inner.whereIdentity, .str literalRoot "whereIdentity", false),
     (``_root_._root_.Inner.mutualFirst, .str literalRoot "mutualFirst", false),
     (``_root_._root_.Inner.mutualSecond, .str literalRoot "mutualSecond", false),
     (``_root_._root_.Inner.privateIdentity, .str literalRoot "privateIdentity", true),
     (``_root_._root_.Inner.privateBridge, .str literalRoot "privateBridge", false),
     (``_root_._root_.Inner.RootBox, rootBox, false),
     (``_root_._root_.Inner.RootBox.mk, .str rootBox "mk", false),
     (``_root_._root_.Inner.RootBox.value, .str rootBox "value", false),
     (``_root_.absoluteIdentity, .str .anonymous "absoluteIdentity", false),
     (``_root_.rootedClient, .str .anonymous "rootedClient", false),
     (``_root_.nestedClient, .str .anonymous "nestedClient", false)]
  for (actual, expected, expectedPrivate) in rootedObservations do
    unless Lean.privateToUserName actual == expected do
      throwError
        "PSCV0-CORE-VISIBILITY-ORACLE: rooted name mismatch: actual {actual}, expected {expected}"
    unless Lean.isPrivateName actual == expectedPrivate do
      throwError
        "PSCV0-CORE-VISIBILITY-ORACLE: rooted private classification mismatch for {actual}"
  let env ← Lean.getEnv
  for text in
      ["private section", "public namespace Rejected", "private namespace Rejected"] do
    match Lean.Parser.runParserCategory env `command text with
    | .error _ => pure ()
    | .ok _ =>
      throwError
        "PSCV0-CORE-VISIBILITY-ORACLE: unsupported native scope parsed: {text}"
  Lean.logInfo
    "PSCV0_CORE_VISIBILITY_NATIVE: 25 native declaration classifications, 15 rooted name/classification checks, and three unsupported scope syntax refusals passed"
