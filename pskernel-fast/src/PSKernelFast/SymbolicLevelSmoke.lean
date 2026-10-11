import PSKernelFast.SymbolicLevelProofs

/-!
Oracle use is limited to this executable *test* module; the implementation
never calls official Lean's Level.isEquiv to issue a positive result.
-/

namespace PSKernelFast.Core

private def assertIO (ok : Bool) (name : String) : IO Unit :=
  if ok then pure () else throw <| IO.userError name

private def KName.toOfficial : KName → Lean.Name
  | .anonymous => .anonymous
  | .str parent segment => .str (KName.toOfficial parent) segment
  | .num parent index => .num (KName.toOfficial parent) index

private def ULevel.toOfficial : ULevel → Lean.Level
  | .zero => .zero
  | .succ l => .succ (ULevel.toOfficial l)
  | .max a b => .max (ULevel.toOfficial a) (ULevel.toOfficial b)
  | .imax a b => .imax (ULevel.toOfficial a) (ULevel.toOfficial b)
  | .param name => .param (KName.toOfficial name)
  | .mvar name => .mvar ⟨KName.toOfficial name⟩

private def checkPair (params : List KName)
    (left right : ULevel) (expected : LevelDecision) :
    IO Unit := do
  let actual := compare params left right
  assertIO (actual == expected)
    s!"unexpected symbolic decision: {repr actual} vs {repr expected}"
  if actual == .equal then
    assertIO (Lean.Level.isEquiv left.toOfficial right.toOfficial)
      "independent positive equality not accepted by official Lean 4.35"

/-- Declarative finite test corpus; no guessed negative verdict on mismatch. -/
def symbolicLevelSmoke : IO Unit := do
  let u : KName := .str .anonymous "u"
  let v : KName := .str .anonymous "v"
  let lu : ULevel := .param u
  let lv : ULevel := .param v

  checkPair [u, v] lu lu .equal
  checkPair [u, v] (.max lu lv) (.max lv lu) .equal
  checkPair [u, v] (.max .zero lu) lu .equal
  checkPair [u, v] (.max lu lu) lu .equal
  checkPair [u, v] (.imax lu .zero) .zero .equal
  checkPair [u, v] (.imax .zero lu) lu .equal
  checkPair [u, v] (.imax lu lu) lu .equal
  checkPair [u, v] (.imax lu (.succ lv)) (.max lu (.succ lv)) .equal
  checkPair [u, v] (.imax (.succ .zero) lu) lu .equal
  checkPair [u, v] (.succ (.max lu lv))
    (.max (.succ lu) (.succ lv)) .equal

  checkPair [u, v] (.imax lu lv) (.max lu lv) .unresolved
  checkPair [u, v] (.max lu lv) lu .unresolved
  checkPair [u] (.max lu lv) lu .malformed
  checkPair [u] (.mvar v) lu .malformed
  checkPair [] (.param u) (.param u) .malformed

  -- Positive direction must agree with official on a broader structured
  -- sample, regardless of hash table ordering. False means "unresolved".
  let samples : Array ULevel := #[
    .zero, .succ .zero, .succ (.succ .zero), lu, lv,
    .succ lu, .succ lv, .succ (.succ lu),
    .max lu lv, .max lv lu, .max .zero lu, .max lu lu,
    .max lu (.succ lv), .max (.succ lv) lu,
    .max (.max lu lv) (.succ lu),
    .max lu (.max lv (.succ lu)),
    .max (.max lu lv) (.max lv lu),
    .max (.succ lu) (.succ lv),
    .succ (.max lu lv), .succ (.max lv lu),
    .max (.succ .zero) lu, .max (.succ (.succ .zero)) (.succ lu),
    .imax .zero lu, .imax lu .zero, .imax lu lu,
    .imax lu lv, .imax lv lu,
    .imax lu (.succ lv), .max lu (.succ lv),
    .imax (.succ .zero) lu,
    .imax lu (.max (.succ .zero) lv),
    .max lu (.max (.succ .zero) lv),
    .imax (.max lu lv) (.succ lu),
    .max (.max lu lv) (.succ lu),
    .succ (.imax lu lv),
    .imax (.succ lu) lv
  ]
  let mut positives : Nat := 0
  let mut unresolvedOfficialPositives : Nat := 0
  for a in samples do
    for b in samples do
      match compare [u, v] a b with
      | .equal =>
          positives := positives + 1
          assertIO (Lean.Level.isEquiv a.toOfficial b.toOfficial)
            "symbolic positive mismatch against pinned official Lean"
      | .unresolved =>
          if Lean.Level.isEquiv a.toOfficial b.toOfficial then
            unresolvedOfficialPositives := unresolvedOfficialPositives + 1
      | .malformed =>
          throw <| IO.userError "well-formed sample was rejected"
  assertIO (positives >= 13) "unexpectedly few positive normalization cases"
  IO.println s!"G4.0 symbolic universe matrix: expressions={samples.size}, pairs={samples.size * samples.size}, positive={positives}, official-positive-but-unresolved={unresolvedOfficialPositives}; no false equality on sampled oracle pairs"
  IO.println "G4.0 limit: positive-only subset; no complete Lean symbolic level equivalence or theorem checker"

end PSKernelFast.Core

def main : IO Unit := PSKernelFast.Core.symbolicLevelSmoke
