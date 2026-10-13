# M2 instance graph — 13 October 2026

Status: implemented; Linux qualification pending. This is the first bounded M2
generator/consumer slice, not completion of M2, Phase A or v7. M1 remains qualified
at c00e146bd5c97788a4a6a39221849973aeafda84 / run 38388627512.

## Design and ownership

The prior solver combined depth-first traversal, active-key cycle rejection and
a checked positive memo. Repeated dependent goals now share an invocation-owned
generator. Candidates are consumers with private metavariable snapshots. A
repeated active goal registers a waiter. A finite answer wakes those consumers;
an unseeded cycle drains the queue without manufacturing recursive evidence.

The design follows the generator/consumer and resume-before-generate organization
in [pinned Lean SynthInstance](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Meta/SynthInstance.lean),
while retaining PSCV0's current closed-answer contract. It does not import Lean
elaboration into the portable closure.

- InstanceCandidate owns telescope preparation and checked cross-snapshot replay.
- InstanceSearch owns generators, consumers, scope IDs, work queue and budgets.
- SynthInstance retains the public entry points and Application's existing
  pending-dictionary dependency passes. There is one search engine.

Ordered local/global candidates are unchanged. Output parameters/output-only
universes are fresh for selection; callers reconcile against their original
target only after an answer is selected. A mismatched preferred output cannot
choose a lower-priority instance. Failed speculative assignments never escape. The first requester owns the new
generator's snapshot and may commit its checked descendant context when it
resumes. This preserves output constraints inside local dictionary types even
when they do not appear in the result class. The root likewise commits only its
selected branch. Later subscribers own unrelated snapshots: they receive only
the meta-closed witness, re-infer it and unify its actual type against their exact
target. A shared consumer never imports a donor context. Unresolved local
signatures cannot share a generator, so ownership is unambiguous.

Each Pi introduction owns a fresh local-instance scope. Sharing also checks that
the instantiated local signature is closed and identical across snapshots.
Pi witnesses close real bound variables and are checked again at publication.

## Bounded work and validation contract

Defaults remain 4096 distinct goal generators and 4096 candidate attempts, with
an additional 32768 queue-transition cap. Synthesis fuel now bounds derivation
height rather than the host recursion stack. The iterative graph has no recursive
search calls; finite-fuel scheduler recursion is structurally decreasing.
Every exhausted resource fails closed and returns the original caller context.
The returned table is diagnostics, not a caller-reusable cache.

The compact native check contains one seeded cycle/diamond/conversion graph,
one unseeded cycle, a Pi scope leak refusal, private-context output propagation,
independent budget refusals, and
repeated-dependency widths 1/8/32. Growth counters must show constant generators
and candidate checks, with transitions linear in dependency edges. Existing
output-priority, unknown-input, rollback, universe and M1 checks remain intact.
One source-level seeded cycle adds a shared runtime observation and an independent
pinned-Lean oracle; existing backend checks consume the same observation.

## Remaining M2 and interleaving

This slice shares only meta-closed canonical answers, not abstract generalized
answers. Generalized term/universe answer abstraction and freshening, unified
synthetic constraints for defaults/expected types/unknown inputs, and broader
adversarial scaling remain M2 work. Goal lookup is a linear scan with conversion
comparison, not a claim of indexed asymptotic lookup. No performance-parity claim.

Continue M2 with its dependent Phase A deriving/library capabilities; retain
binder/resolution/occurrence information for C5 at semantic owners. Do not recreate
qualified readable JS/TS/Rust/WAT/WIT infrastructure or start self-hosting.
