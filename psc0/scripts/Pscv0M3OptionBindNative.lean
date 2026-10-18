import Lean
import Init.Internal.Order.Basic

-- Native-only acceptance and executable observations for the selected P1
-- Option bind boundary. This file never installs portable declarations.
namespace M3OptionBindNative

def auditOptionBind (n : Nat) : Option Nat :=
  match n with
  | 0 => Option.some 0
  | k + 1 =>
    Bind.bind (auditOptionBind k) (fun value =>
      Bind.bind (auditOptionBind value) (fun previous => Option.some (Nat.succ previous)))
partial_fixpoint

theorem auditOptionBindEquation (n : Nat) :
    auditOptionBind n = (match n with
      | 0 => Option.some 0
      | k + 1 =>
        Bind.bind (auditOptionBind k) (fun value =>
          Bind.bind (auditOptionBind value) (fun previous => Option.some (Nat.succ previous)))) :=
  auditOptionBind.eq_def n

/-- error: Could not prove -/
#guard_msgs (error, drop warning, substring := true) in
def auditOptionDirectBindRefusal (n : Nat) : Option Nat :=
  match n with
  | 0 => Option.some 0
  | k + 1 =>
    Option.bind (auditOptionDirectBindRefusal k) (fun value =>
      Option.bind (auditOptionDirectBindRefusal value) (fun previous => Option.some (Nat.succ previous)))
partial_fixpoint

/-- error: Could not prove -/
#guard_msgs (error, drop warning, substring := true) in
def auditOptionInspection (n : Nat) : Option Nat :=
  match auditOptionInspection n with
  | Option.none => Option.some 0
  | Option.some _ => Option.none
partial_fixpoint

-- Eligible declaration heads are measured separately from the def/function
-- runtime surface above. Opaque publication and lazy equation generation are
-- independent native behaviors.
abbrev auditP1Abbrev (n : Nat) : Nat :=
  match n with
  | 0 => 29
  | k + 1 => auditP1Abbrev k
partial_fixpoint

theorem auditP1AbbrevEquation (n : Nat) :
    auditP1Abbrev n = (match n with | 0 => 29 | k + 1 => auditP1Abbrev k) :=
  auditP1Abbrev.eq_def n

example : auditP1Abbrev 2 = 29 := by
  fail_if_success rfl
  simp only [auditP1Abbrev.eq_def]

opaque auditP1Opaque (n : Nat) : Nat :=
  match n with
  | 0 => 31
  | k + 1 => auditP1Opaque k
partial_fixpoint

run_meta do
  match ← Lean.getConstInfo ``auditP1Abbrev with
  | .defnInfo _ => pure ()
  | _ => throwError "native P1 abbrev lost its definition kind"
  unless (← Lean.getReducibilityStatus ``auditP1Abbrev) == .reducible do
    throwError "native P1 abbrev lost its reducible status"
  match ← Lean.getConstInfo ``auditP1Opaque with
  | .opaqueInfo _ => pure ()
  | _ => throwError "native P1 opaque lost its opaque declaration kind"
  unless (← Lean.getReducibilityStatus ``auditP1Opaque) == .irreducible do
    throwError "native P1 opaque changed its fixedpoint reducibility metadata"

/-- error: Unknown constant `M3OptionBindNative.auditP1Opaque.eq_def` -/
#guard_msgs (error, drop warning, substring := true) in
#check auditP1Opaque.eq_def

/-- error: Could not prove -/
#guard_msgs (error, drop warning, substring := true) in
abbrev auditP1AbbrevInspection (n : Nat) : Nat :=
  auditP1AbbrevInspection n + 1
partial_fixpoint

/-- error: Could not prove -/
#guard_msgs (error, drop warning, substring := true) in
opaque auditP1OpaqueInspection (n : Nat) : Nat :=
  auditP1OpaqueInspection n + 1
partial_fixpoint

-- P1 where-clique publication is measured independently: the local helper
-- keeps its own declaration kind while the main keeps its written head.
abbrev auditP1AbbrevWhere (n : Nat) : Nat := loop n
partial_fixpoint
where
  loop (n : Nat) : Nat :=
    match n with
    | 0 => 37
    | k + 1 => auditP1AbbrevWhere k
  partial_fixpoint

opaque auditP1OpaqueWhere (n : Nat) : Nat := loop n
partial_fixpoint
where
  loop (n : Nat) : Nat :=
    match n with
    | 0 => 39
    | k + 1 => auditP1OpaqueWhere k
  partial_fixpoint

theorem auditP1AbbrevWhereEquation (n : Nat) :
    auditP1AbbrevWhere n = auditP1AbbrevWhere.loop n :=
  auditP1AbbrevWhere.eq_def n

theorem auditP1AbbrevWhereLoopEquation (n : Nat) :
    auditP1AbbrevWhere.loop n =
      (match n with | 0 => 37 | k + 1 => auditP1AbbrevWhere k) :=
  auditP1AbbrevWhere.loop.eq_def n

run_meta do
  match ← Lean.getConstInfo ``auditP1AbbrevWhere.loop with
  | .defnInfo _ => pure ()
  | _ => throwError "native P1 abbrev local helper lost its definition kind"
  match ← Lean.getConstInfo ``auditP1OpaqueWhere.loop with
  | .defnInfo _ => pure ()
  | _ => throwError "native P1 opaque local helper inherited the main's opaque kind"
  match ← Lean.getConstInfo ``auditP1OpaqueWhere with
  | .opaqueInfo _ => pure ()
  | _ => throwError "native P1 where main lost its opaque kind"
  for name in [``auditP1AbbrevWhere, ``auditP1AbbrevWhere.loop,
      ``auditP1OpaqueWhere, ``auditP1OpaqueWhere.loop] do
    let some info := Lean.Elab.PartialFixpoint.eqnInfoExt.find? (← Lean.getEnv) name
      | throwError "native P1 where member lost its checked equation metadata: {name}"
    let auxiliary ← Lean.getConstInfo info.declNameNonRec
    let kind := match auxiliary with
      | .defnInfo _ => "definition"
      | .opaqueInfo _ => "opaque"
      | .thmInfo _ => "theorem"
      | _ => "other"
    let equation ← Lean.withoutModifyingEnv do
      try
        match ← Lean.Meta.getUnfoldEqnFor? name with
        | some equation => pure s!"some {equation}"
        | none => pure "none"
      catch error =>
        pure ("error " ++ (← error.toMessageData.toString))
    Lean.logInfo m!"PSCV0_M3_P1_WHERE_NATIVE: member={name} auxiliary={info.declNameNonRec} kind={kind} equation={equation}"

end M3OptionBindNative

def main : IO Unit := do
  unless Lean.githash == "eb6cafb7290e8bd5f2937522d8d804f58f02bafc" do
    throw (IO.userError "Option bind qualification requires pinned Lean 4.35.0")
  for (argument, expected) in [(0, 0), (3, 3), (4, 4)] do
    unless M3OptionBindNative.auditOptionBind argument == some expected do
      throw (IO.userError ("native Option bind observation differs at " ++ toString argument))
  IO.println "PSCV0_M3_P1_OPTION_BIND_NATIVE: PASS checked generic Bind action and continuation, original equation, direct Option.bind and nonmonotone inspection refusals and exact 0/3/4 observations"
  for argument in ([0, 3, 4] : List Nat) do
    unless M3OptionBindNative.auditP1Abbrev argument == 29 &&
        M3OptionBindNative.auditP1Opaque argument == 31 do
      throw (IO.userError ("native registered P1 observation differs at " ++ toString argument))
  IO.println "PSCV0_M3_P1_HEADS_NATIVE: PASS abbrev equation/reducibility and opaque declaration/execution with unavailable unfolding equation; exact nonmonotone refusals"
  for argument in ([0, 3, 4] : List Nat) do
    unless M3OptionBindNative.auditP1AbbrevWhere argument == 37 &&
        M3OptionBindNative.auditP1OpaqueWhere argument == 39 do
      throw (IO.userError ("native registered P1 where observation differs at " ++ toString argument))
  IO.println "PSCV0_M3_P1_WHERE_RUNTIME_NATIVE: PASS same-clique main/local calls and exact 37/39 observations"
