import Ps.KernelCore.Research.ExprV2

/-
Expression V2 / M1b: linear-in-DAG-node-count metadata replay validator.

Unlike the independent but expensive legacy-oracle validator, this check
does not expand shared subexpressions. It rebuilds nodes in topological order
using only verified prior entries, and compares every cached field.

This is a research capability, NOT an admission proof. Equivalence to the old
expressions still needs independent differential/or formal evidence; no kernel
provider consumes the result of this function yet.
-/

def psKernelExprV2ReplayNode
    (already : PsKernelExprV2Arena)
    (node : PsKernelExprV2Node) :
    Except String (PsKernelExprV2Arena × Nat) :=
  match node with
  | .bvar index =>
      .ok (psKernelExprV2MkBVar already index)
  | .fvar name =>
      .ok (psKernelExprV2MkFVar already name)
  | .mvar name =>
      .ok (psKernelExprV2MkMVar already name)
  | .sort level =>
      .ok (psKernelExprV2MkSort already level)
  | .const name levels =>
      .ok (psKernelExprV2MkConst already name levels)
  | .lit literal =>
      .ok (psKernelExprV2MkLit already literal)
  | .app fn arg =>
      psKernelExprV2MkApp already fn arg
  | .lam name type body binderInfo =>
      psKernelExprV2MkLam already name type body binderInfo
  | .forallE name type body binderInfo =>
      psKernelExprV2MkForall already name type body binderInfo
  | .letE name type value body nondep =>
      psKernelExprV2MkLet already name type value body nondep
  | .mdata metadata body =>
      psKernelExprV2MkMData already metadata body
  | .proj name index body =>
      psKernelExprV2MkProj already name index body

def psKernelExprV2SameMetadata
    (expected observed : PsKernelExprV2Entry) : Bool :=
  expected.hash == observed.hash &&
  expected.looseRange == observed.looseRange &&
  expected.hasFVar == observed.hasFVar &&
  expected.hasExprMVar == observed.hasExprMVar &&
  expected.depth == observed.depth

/-
Return a freshly replayed, topologically checked arena.
Invalid child IDs, forward edges or counterfeit metadata cause Except.error.
The caller must not use unaudited original entries for trusted fast paths.
-/
def psKernelExprV2ValidateLinear
    (source : PsKernelExprV2Arena) :
    Except String PsKernelExprV2Arena := do
  let mut checked := psKernelExprV2Empty
  for sourceEntry in source.nodes do
    let (next, id) ← psKernelExprV2ReplayNode checked sourceEntry.node
    let computed ← psKernelExprV2Lookup next id
    if !psKernelExprV2SameMetadata sourceEntry computed then
      throw "PSKERNEL_V2_REPLAY_METADATA_MISMATCH"
    checked := next
  return checked
