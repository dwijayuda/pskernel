import Lean
import Init.Internal.Order.Basic

-- Native-only acceptance and executable observations for the selected P1
-- Option bind boundary. This file never installs portable declarations.
namespace M3OptionBindNative

def auditOptionBind (n : Nat) : Option Nat :=
  match n with
  | 0 => some 0
  | k + 1 =>
    Option.bind (auditOptionBind k) (fun value =>
      Option.bind (auditOptionBind value) (fun previous => some (Nat.succ previous)))
partial_fixpoint

theorem auditOptionBindEquation (n : Nat) :
    auditOptionBind n = (match n with
      | 0 => some 0
      | k + 1 =>
        Option.bind (auditOptionBind k) (fun value =>
          Option.bind (auditOptionBind value) (fun previous => some (Nat.succ previous)))) :=
  auditOptionBind.eq_def n

/-- error: Could not prove -/
#guard_msgs (error, drop warning, substring := true) in
def auditOptionInspection (n : Nat) : Option Nat :=
  match auditOptionInspection n with
  | none => some 0
  | some _ => none
partial_fixpoint

end M3OptionBindNative

def main : IO Unit := do
  unless Lean.githash == "eb6cafb7290e8bd5f2937522d8d804f58f02bafc" do
    throw (IO.userError "Option bind qualification requires pinned Lean 4.35.0")
  for (argument, expected) in [(0, 0), (3, 3), (4, 4)] do
    unless M3OptionBindNative.auditOptionBind argument == some expected do
      throw (IO.userError ("native Option bind observation differs at " ++ toString argument))
  IO.println "PSCV0_M3_P1_OPTION_BIND_NATIVE: PASS checked recursive action and continuation, original equation, nonmonotone inspection refusal and exact 0/3/4 observations"
