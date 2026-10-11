import Init

/-!
Minimal, dependency-light PSCV source/profile contracts. The default compiler
must not import Lean.Environment, Lean.Declaration, the full elaborator or a
kernel checker only to identify source policy. These are *descriptive* values,
not semantic authority or a PSCV certificate.
-/
namespace Pscv

inductive Profile where
  | standard
  | verified
  | leanExtensible
  deriving Repr, BEq, Inhabited

def Profile.identity : Profile → String
  | .standard => "ps-standard-0.9-r3"
  | .verified => "pscv-v1"
  | .leanExtensible => "ps-lean-extensible-0.9-r3"

end Pscv
