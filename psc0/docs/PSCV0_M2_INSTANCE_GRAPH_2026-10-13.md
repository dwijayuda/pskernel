# M2 instance graph — 13 October 2026

Status: **qualified** at `a98062b2ac346c66c7f687bfe7e190d12470ba4d`,
[Linux 38398901889](https://github.com/dwijayuda/pskernel/actions/runs/38398901889).
This is the first bounded M2 generator/consumer slice, not completion of M2,
Phase A or v7. M1 remains complete for its selected scope; its Standard definitions
and digests are unchanged.

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

## Qualification evidence

The official Lean 4.35.0-rc4 build/oracle, compact native checks, 92 phase-specific
semantic refusals, do/opacity boundaries, strict IR, project linking and all
existing backend gates passed. There are 177 portable / 185 native closure
modules and 251 shared runtime observations, with four panic contracts.
Direct JS declaration mappings increased to 531 because the source fixture grew;
the 14 generated-parent origins and declaration-level precision are unchanged.

The repeated-dependency widths 1/8/32 produced exactly 2 generators and 3 candidate
attempts each, with 7/21/69 transitions. The seeded-cycle runtime result is 1466
in the pinned source oracle and every qualified runtime.

The existing M1 compiler measurement reported checked-index elaboration medians
of 2/14 ms at 16/128 declarations; direct-return medians were 0/2 ms, with 8 ms
prelude admission. These are single-run measurements, not a controlled
before/after speedup. Generated-JS/native-Lean runtime ratios still span roughly
457–3232x in the small existing workloads; this solver change makes no generated
runtime performance claim. Raw samples remain in the CI artifact.

The initial source build failed on four Lean record-layout syntax errors;
a syntax-only correction then passed the whole pipeline. Architectural review
subsequently added explicit snapshot ownership and its nested output constraint
check; the final run above qualified that implementation. No acceptance checks,
Standard digests, backend requirements or proof obligations were relaxed.

## Remaining M2 and interleaving

This slice shares only meta-closed canonical answers, not abstract generalized
answers. Generalized term/universe answer abstraction and freshening, unified
synthetic constraints for defaults/expected types/unknown inputs, and broader
adversarial scaling remain M2 work. Goal lookup is a linear scan with conversion
comparison, not a claim of indexed asymptotic lookup. No performance-parity claim.

Next extend the existing Phase A deriving handlers with shared parameter/universe
telescope handling, using checked local field dictionaries and constructor
prerequisites. Continue M2 generalization as those dependencies require it; retain
binder/resolution/occurrence information for C5 at semantic owners. Do not recreate
qualified readable JS/TS/Rust/WAT/WIT infrastructure or start self-hosting.
