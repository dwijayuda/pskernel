import Ps.KernelOne.Level
import Lean

-- Host-only differential harness. Lean APIs never enter KernelOne source.
private def toLeanName : PsKernelOneName → Lean.Name
  | .anonymous => .anonymous
  | .str p s => .str (toLeanName p) s
  | .num p n => .num (toLeanName p) n

private def toLeanLevel : PsKernelOneLevel → Lean.Level
  | .zero => .zero
  | .succ u => .succ (toLeanLevel u)
  | .max u v => .max (toLeanLevel u) (toLeanLevel v)
  | .imax u v => .imax (toLeanLevel u) (toLeanLevel v)
  | .param n => .param (toLeanName n)
  | .mvar n => .mvar ⟨toLeanName n⟩

private def param (s : String) : PsKernelOneLevel :=
  .param (.str .anonymous s)

private def checkCase (env : Lean.Environment) (label : String)
    (left right : PsKernelOneLevel) (expected : Bool) : IO Unit := do
  let a := toLeanLevel left
  let b := toLeanLevel right
  let reference ← match Lean.Kernel.isDefEq env {} (.sort a) (.sort b) with
    | .ok value => pure value
    | .error _ => throw (IO.userError s!"REFERENCE_FAILURE: {label}")
  unless reference == expected do
    throw (IO.userError s!"REFERENCE_EXPECTATION: {label}: {reference}")
  let actual := psKernelOneLevelEquivalent left right
  unless actual == reference do
    throw (IO.userError s!"LEVEL_PARITY: {label}: one={actual}, lean={reference}")

def main : IO Unit := do
  let env ← Lean.mkEmptyEnvironment
  let u := param "u"
  let v := param "v"
  let w := param "w"
  let cases : List (String × PsKernelOneLevel × PsKernelOneLevel × Bool) := [
    ("max-reassociation", .max (.max u v) w, .max u (.max v w), true),
    ("max-permutation", .max (.max u v) w, .max w (.max v u), true),
    ("duplicate-leaf", .max u (.max v u), .max u v, true),
    ("missing-parameter", .max (.max u v) w, .max u v, false),
    ("different-parameter", .max u v, .max u w, false),
    ("successor-different", .succ u, u, false),
    ("imax-zero", .imax u .zero, .zero, true),
    ("imax-not-max", .imax u v, .max u v, false),
    ("zero-identity", .max .zero (.max u v), .max v u, true),
    ("name-boundary", param "a.b", .param (.str (.str .anonymous "a") "b"), false),
    ("unicode-equal", param "a𝄞", param "a𝄞", true),
    ("unicode-different", param "a𝄞", param "a𝄢", false),
    ("numeric-name-width", .param (.num .anonymous 9007199254740992),
      .param (.num .anonymous 9007199254740993), false)
  ]
  for (label, left, right, expected) in cases do
    checkCase env label left right expected
  -- Exhaust all ordered pairs in the finite free-max corpus, independently
  -- expecting the OR of atom masks. This is a bounded property test, not proof.
  let corpus : List (PsKernelOneLevel × Nat) := [
    (.zero, 0), (u, 1), (v, 2), (w, 4), (.max u v, 3),
    (.max v u, 3), (.max u w, 5), (.max v w, 6),
    (.max (.max u v) w, 7), (.max u (.max w v), 7),
    (.max w (.max v u), 7), (.max u (.max v u), 3)
  ]
  for (left, lm) in corpus do
    for (right, rm) in corpus do
      checkCase env "finite-max-corpus" left right (lm == rm)
  IO.println s!"PSKERNEL_ONE_LEVEL_PARITY: PASS ({cases.length} focused + {corpus.length * corpus.length} ordered pairs)"
