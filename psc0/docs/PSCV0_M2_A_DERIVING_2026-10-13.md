# M2 + Phase A: parameter and universe-aware deriving

**Subsequent qualification:** [checked equality/defaults](PSCV0_M2_A_EQUALITY_DEFAULTS_2026-10-13.md)
at `d7e28a3870cdc399eca3c63c6d305b10109d2eca`, [Linux 38418209663](https://github.com/dwijayuda/pskernel/actions/runs/38418209663).
This adds selected DecidableEq, proof-field BEq, structure defaults and shared
typed proof conversion. The historical evidence below remains revision-specific;
the latest Standard has 294 declarations / 14 classes / 52 instances.

**Subsequent qualification:** [generalized answers and shared constraints](PSCV0_M2_GENERALIZED_CONSTRAINTS_2026-10-13.md)
at `c6468b17ef8f0a97c9e0df76c1ffe49f35c68279`, [Linux 38411211335](https://github.com/dwijayuda/pskernel/actions/runs/38411211335).
It supersedes the earlier closed-answer/pending-instance boundary while
preserving deriving and ownership invariants. The evidence below remains tied
to its original revision; full M2/A/v7 remain open.

Date: 13 October 2026. Qualified executable `f1ce3840c1943c9f78be20a5428fd4adfa9053af`;
[green Linux run 38403318952](https://github.com/dwijayuda/pskernel/actions/runs/38403318952).

## Roadmap placement

Follow **M2+A → M3+B → M4+C/D**. This slice connects Phase A deriving to
M2's existing checked instance graph. It does not finish M2 or Phase A.
Indexed/dependent/recursive deriving stays with the M3 data and recursion
work it needs. C5 source reconstruction, richer origins and performance work
remain on the existing roadmap; no new milestone is introduced.

## Shared mechanism and invariants

`DerivingContext` opens the admitted family's uniform-parameter telescope
using the ordinary binder/context machinery. The handler carries its actual
universe parameters, fresh local identities, and a fully applied family.
Class requirements use ordinary constant freshening, type inference and
unification; value parameters never receive bogus typeclass assumptions.
Constructor parameter application uses the same universe substitution and
telescope primitives as ordinary elaboration.

Each handler returns one ordinary definition with the established
`instInhabited` / `instBEq` name. Command elaboration retains handler order,
instance registration, privacy and origin ownership. Both type and value must
have no unresolved metavariables or escaped locals. Official Lean admission
remains authoritative; no host elaborator enters the portable closure.

- `Inhabited`: try every constructor without extra requirements first, then
  retry with type-correct parameter requirements. Fill fields in telescope
  order and substitute each default into later field types. Close only the
  requirements used by the selected value; phantom parameters do not create
  unnecessary `Inhabited` assumptions.
- `BEq`: build type-correct parameter requirements and synthesize each field
  comparison once. Independent nonrecursive fields may inhabit different
  universes. Structures use projections. Fieldless/payload inductives share
  one recursor builder with separate, inferred outer and inner motive
  universes and collision-free opened field telescopes.

The selected boundary remains non-indexed families and independent,
nonrecursive BEq fields. Dependent comparison requires evidence-producing
transport, and recursive comparison requires structural workers. Function
fields without BEq, unsupported deriving handlers, and these unimplemented
families continue to fail closed. Structure field-default semantics and
proof-field skipping are not added by this slice.

## M2 mechanisms strengthened

Projection inference and source projection lookup instantiate constructor
universe parameters with the actual major's levels before consuming its
uniform parameters. Raw projection inference also checks universe arity.

Level normalization factors a common successor:
`max (succ u) (succ v) = succ (max u v)`. This is the reusable normalization
law needed for mixed-universe record sorts to unify with `BEq : Type u → Type u`;
handlers do not guess universe predecessors or add a separate level solver.

Rigid application congruence retains the existing universe-first path and can
defer a failed head-universe equation until its typed arguments have fixed the
universe metavariables. The argument-first attempt starts from the original
snapshot, checks every argument, then must discharge all head-level equations
before committing. This handles max-universe instances without guessing levels
or publishing delayed unchecked equalities. It is a bounded spine mechanism,
not the still-open unified synthetic-constraint scheduler.

The generator/consumer instance graph and its ownership, replay and resource
bounds are unchanged. This slice exercises local polymorphic requirements
through that public synthesis API.

## Focused qualification and evidence

One combined source fixture adds generic, phantom, value-parameter,
Sort-polymorphic and mixed-universe families, kernel-checked reduction
equalities, and nine observations shared by JS/TS/Rust/GC-Wasm. Three
elaboration refusals cover missing parameter dictionaries, dependent fields
and a recursive generic family. The pinned Lean oracle independently checks
constructor selection, assumption pruning and runtime equality semantics.
A runtime nested `Option α` projection checks actual universe substitution;
a separate kernel-only type-valued projection checks the same invariant without
claiming runtime support for type-valued fields.
The complete existing native Linux workflow passed, including all existing
checks and unchanged snapshot digest guards.

The final qualification has **260 shared observations** (251 retained + nine),
four panic contracts, 180 portable / 188 native closure modules, 92 existing
phase-specific semantic refusals, the three deriving refusals, and the pinned
source oracle. JS, TS, Rust, GC core V8/Wasmtime, repeated component calls,
WIT/WAT/binary/ABI, strict IR, module interfaces and project linking all passed.
Direct JS has **572 declaration mappings / 26 generated-parent origins**;
mapping precision remains declaration-level. The Standard environment remains
292 declarations / 14 classes / 52 instances with unchanged identities:
`fnv1a64:5949916575031563783` and
`sha256:f33d923e45baf8aa5dfa6755819737acabc09daf6d60934eb232133acaad069f`.

The deriving implementation is 46 source lines smaller than the previous
combined handler after splitting shared context and the two handlers.
This is a source-size observation, not a performance proof. No benchmark
speedup is claimed. The existing M1 samples in this run record checked-index
elaboration at 4/27 ms for 16/128 declarations, versus 1/4 ms for direct-return
bodies; prelude admission is 12 ms. Generated-JS/native-Lean ratios span roughly
500–4123x on the small existing workloads. These uncontrolled run-to-run
samples do not establish a regression or improvement; raw evidence is retained
in the CI artifact. High-performance parity remains open M5 work.

Initial build attempts found Lean do/pattern scoping and a harness API-name
error; these were corrected without changing the design. Semantic qualification
then exposed the composite-universe matching gap fixed in shared congruence.
The additional type-valued-field probe passed the kernel but exposed the
existing runtime subset boundary, so it remains an explicit kernel-only check;
a nested Option field validates runtime universe projection across all targets.
No existing acceptance criteria, digest guards or supported runtime observations
were weakened. Full M2, Phase A, v7 and compiler semantic-preservation proofs
remain incomplete. pskernel-core and self-hosting remain deferred.

## Pinned design references

Official Lean at `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`:

- [Inhabited deriving](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Elab/Deriving/Inhabited.lean):
  two-pass constructor selection and used-requirement pruning.
- [BEq deriving](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Elab/Deriving/BEq.lean)
  and [shared deriving utilities](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Elab/Deriving/Util.lean):
  type-correct parameter requirements, constructor comparisons, and the
  evidence/recursion mechanisms needed for the larger deferred domain.

This uses the reference algorithms and invariants, not the host's syntax or
deriving implementation inside the portable compiler.

