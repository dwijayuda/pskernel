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
     (``AtEof.value, false)]
  for (name, expectedPrivate) in observations do
    unless Lean.isPrivateName name == expectedPrivate do
      throwError
        "PSCV0-CORE-VISIBILITY-ORACLE: private classification mismatch for {name}"
  let env ← Lean.getEnv
  for text in
      ["private section", "public namespace Rejected", "private namespace Rejected"] do
    match Lean.Parser.runParserCategory env `command text with
    | .error _ => pure ()
    | .ok _ =>
      throwError
        "PSCV0-CORE-VISIBILITY-ORACLE: unsupported native scope parsed: {text}"
  Lean.logInfo
    "PSCV0_CORE_VISIBILITY_NATIVE: 17 native declaration classifications and three unsupported scope syntax refusals passed"
