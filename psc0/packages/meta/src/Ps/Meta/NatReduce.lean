import Ps.Core.Builtin
import Ps.Core.Expr
import Ps.Core.Equality

def psReduceNatBinary (name : PsName) : Option (Nat → Nat → PsExpr) :=
  if psNameEq name psNatAddName then some (fun a b => .lit (.natural (a + b)))
  else if psNameEq name psNatSubName then some (fun a b => .lit (.natural (a - b)))
  else if psNameEq name psNatMulName then some (fun a b => .lit (.natural (a * b)))
  else if psNameEq name (psNameAppendStr psNatName "pow") then some (fun a b => .lit (.natural (a ^ b)))
  else if psNameEq name psNatDivName then some (fun a b => .lit (.natural (a / b)))
  else if psNameEq name psNatModName then some (fun a b => .lit (.natural (a % b)))
  else if psNameEq name psNatBeqName then
    some (fun a b => .constE (if a == b then psBoolTrueName else psBoolFalseName) [])
  else if psNameEq name psNatBleName then
    some (fun a b => .constE (if a <= b then psBoolTrueName else psBoolFalseName) [])
  else none

-- The selected primitive operations have the pinned kernel's closed-literal
-- equations. Unknown heads and nonliteral operands remain stuck. This belongs
-- to conversion, not to individual elaborators or proof tactics.
def psReduceNatPrimitive (reduce : PsExpr → PsExpr) (expr : PsExpr) : Option PsExpr := do
  match expr with
  | .app (.constE name []) value =>
    if !psNameEq name psNatSuccName then none else do
      let .lit (.natural n) := reduce value | none
      return .lit (.natural (n + 1))
  | .app (.app (.constE name []) left) right =>
    let rightReduced := reduce right
    -- Pinned Lean 4.35.0 Init.Prelude defines Nat.add by recursion on
    -- its SECOND operand: Nat.add a 0 reduces to a even when a is open.
    -- Do not introduce the propositionally true but non-definitional
    -- reverse rule Nat.add 0 a = a. Pinned Nat.sub a 0 has the same
    -- zero-right definitional identity. No positive subtraction or
    -- arithmetic-decrease shortcut is introduced. Infix HAdd/HSub
    -- projections require their checked instances to unfold.
    if (psNameEq name psNatAddName || psNameEq name psNatSubName) &&
        psExprAlphaEq rightReduced (.lit (.natural 0)) then
      return left
    let operation ← psReduceNatBinary name
    let .lit (.natural a) := reduce left | none
    let .lit (.natural b) := rightReduced | none
    return operation a b
  | _ => none
