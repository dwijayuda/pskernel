import PSKernelFast.CoreSyntax

/-!
G4.0 independent, proof-oriented symbolic universe equivalence.

A YES answer is intended to be valid for *every* assignment of universe
parameters, not the result of sampling a few ground valuations.

This is a deliberately incomplete **positive-only** normalizer. It is NOT the
full Lean Level.normalize/is_equivalent algorithm and cannot accept proofs.
No old kernel source, con-leche checker or foreign soundness axiom is imported.
-/

namespace PSKernelFast.Core

/-- Mathematical interpretation of a level under any parameter valuation. -/
def ULevel.denote (ρ : KName → Nat) : ULevel → Nat
  | .zero => 0
  | .succ l => ULevel.denote ρ l + 1
  | .max a b => Nat.max (ULevel.denote ρ a) (ULevel.denote ρ b)
  | .imax a b => numericImax (ULevel.denote ρ a) (ULevel.denote ρ b)
  | .param n => ρ n
  | .mvar n => ρ n

/--
Canonical orientation of a binary max. Hashes are **ordering hints only**.
When they tie, deterministic representation order is used, but semantic
correctness never depends on collision freedom.
-/
def levelOrder (a b : ULevel) : Bool :=
  let ha := hash a
  let hb := hash b
  if ha < hb then true
  else if hb < ha then false
  else toString (repr a) ≤ toString (repr b)

/-- Syntax-level max simplification without an unproved equivalence shortcut. -/
def smartMax (a b : ULevel) : ULevel :=
  if a = .zero then b
  else if b = .zero then a
  else if a = b then a
  else if levelOrder a b then .max a b
  else .max b a

/--
imax x 0 = 0; imax 0 y = y; imax x x = x;
if the right argument is syntactically a successor, it cannot evaluate to 0.
-/
def smartIMax (a b : ULevel) : ULevel :=
  if b = .zero then .zero
  else if a = .zero then b
  else if a = b then a
  else
    match b with
    | .succ _ => smartMax a b
    | _ => .imax a b

/-- Structural recursive normalizer; no expensive full max flattening yet. -/
def normalize : ULevel → ULevel
  | .zero => .zero
  | .param n => .param n
  | .mvar n => .mvar n
  | .succ l => .succ (normalize l)
  | .max a b => smartMax (normalize a) (normalize b)
  | .imax a b => smartIMax (normalize a) (normalize b)

/--
A Boolean *positive* equivalence test. A false result means unresolved,
not semantically different: Lean's full normalizer recognizes additional cases.
-/
def positiveEquivalent (a b : ULevel) : Bool :=
  decide (normalize a = normalize b)

/-- Explicit result categories prevent confusing a failure to decide with ≠. -/
inductive LevelDecision where
  | equal
  | unresolved
  | malformed
  deriving Repr, BEq, Inhabited

/--
Validate universe parameters first; a known equality cannot be inferred from
an undeclared parameter or a metavariable supplied by untrusted input.
-/
def compare (params : List KName) (a b : ULevel) : LevelDecision :=
  if !a.validParams params || !b.validParams params then
    .malformed
  else if positiveEquivalent a b then
    .equal
  else
    .unresolved

end PSKernelFast.Core
