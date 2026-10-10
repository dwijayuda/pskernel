import Std

/-!
Lean-compatible raw name *shape* for an independent kernel.
No host string parser or hash is a logical name-equality oracle.
-/
namespace PSKernelFast

inductive Name where
  | anonymous
  | str (parent : Name) (value : String)
  | num (parent : Name) (index : Nat)
deriving Repr, BEq, Hashable, Inhabited

def Name.simple (value : String) : Name := .str .anonymous value

end PSKernelFast
