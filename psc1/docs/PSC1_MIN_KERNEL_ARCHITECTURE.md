# PSC1 minimal-kernel architecture

## R3 operational profile qualified — continue with R4

The normalized R3 operational profile passes standalone Linux
[40486405765](https://github.com/dwijayuda/pskernel/actions/runs/40486405765) at
**`695c68701437899b17a39205300cf26988322b15`**:
proof/native **122129166896**, source/portability/census **122129166670**.
The user-confirmed continuation setting is GPT-6.1 Sol / High. All project builds,
proof checks, source compilation and tests ran on GitHub Actions Linux.

Read the [R3 profile and exact boundary](PSC1_MIN_KERNEL_R3_PROFILE.md) and
[dated R3 receipt](PSC1_MIN_KERNEL_R3_QUALIFICATION_2026-10-27.json).
The separate operational layer adds annotated lets, descriptor-derived
single-constructor projections, and closed Nat/List/Option/Bool-decision schemas.
Every actual inference/admission success has a concrete model and Empty
consistency proof. R2 source/proofs remain intact.

The actual typed projection-model iota equation is proved for arbitrary supported
fields. The sequential fold carries DefinitionHistory for actual checked bodies;
checked_definition_unfold relates real constant interpretation to that body.
Conversion is structural code equality with a model-soundness theorem. There is
no general beta/delta type-conversion engine or dependent-alias acceptance.

All **26** new printed reports are no axioms or exactly `[propext]`.
The actual native/generated corpus passes **36 positives, 40 refusals and two
out-of-range probes**. Fifteen initial contracts were expanded to **29** exact
selected foundation declarations, including required types and constructors.
The actual source-owned ite/Decidable.rec AST equations and constructive
conditional model are checked. Canonical primitive contract comparisons are CI
evidence, never fixture/hash admission rules.

The checker closure is four source modules, 518 lines/22339 B; the two added
modules are 211 lines/10071 B. The five-module source/test graph is independently
admitted by official Lean 4.35. Its bundle is 134690 B TS/318436 B JS, including the
test/shared runtime, not an isolated checker payload or performance measurement.

Historical broader-regression snapshot at 2026-10-27 10:14 UTC: main 40486414934
and installed 40483267987 were still in progress. A reporting push may supersede
main; requery live PR checks. The source/standalone theorem qualification above
is complete; terminal broader outcomes are recorded separately.

**Next is R4:** bounded exact byte decoding, exact source-name/slot binding and
profile translation, then the actual generated checker acceptance-to-model path.
Check matching Eq Bool operands and Bool.decEq operands before constructing
boolEqIte; no arbitrary proof/decision term may be erased. Recompute the complete
connected R1/R2/R3/naming/ingress closure and required String/Char semantics.
The old Check-only 12 records and R2's 37-record view are not this enlarged checker.

R3 does not prove a general raw-Core translator/byte decoder or full foundation
closure. Generated-code preservation and hostile-input aggregate/heap/stack
bounds remain open. Canonical min/dual still refuse; full min coverage remains
0/124 modules, 0/37 Practical Core and no qualified min G1/G2/G3. Preserve official
Lean Wasm as default. Do not repeat R1/R2/R3 or promote official generations.

## Selected base

`refactor/psc1-layout-20261026` at
`94e0c13f6a4b434f73c859cc0c716cb6fb8d1340` was the newest qualified coherent
base at branch creation. Live PR #193 was eleven commits ahead and zero behind,
but its watch/runtime qualification and runs 40437789669/40437783359 were pending.
PR #192 retained passing source 40344469855, installed 40344458391, current-source
Wasm G1 40344458240 and documentation 40352122925. Later progress on either parent
does not change this branch's immutable base or acquire qualification here.

## Complete initial calculus

Types are Empty, Unit, Nat and simple function arrows. Terms are scoped de Bruijn
variables, positional references to earlier checked declarations, Unit/Nat
literals, annotated lambdas and applications. A declaration contains a type and
a closed body. Sequential admission starts from an empty constant environment;
only an inferred body of the declared type extends it. There is no axiom or
unchecked-import constructor, forward reference, general recursion, dependent Pi,
universe, inductive declaration or arbitrary conversion rule.

Simple type equality is structural and fuel bounded. Application typing needs no
term normalization because types cannot depend on terms. There is consequently
no reason to add substitution, WHNF, delta/iota reduction or a cache to this
fragment. This is a specific restricted calculus, not Lean Core with omitted cases.

`packages/pskernel-min/src/Ps/MinKernel/Check.lean` is the single executable module.
Its public operations are `psMinTyEq`, `psMinLookup`, `psMinInfer`, `psMinCheckDeclarations` and
`psMinCheckEnvironment`. It imports no proof, reference kernel or compiler module.
The runtime Lake project has explicit roots. A separate full-Lean proof project
builds this exact source in place and imports it into `MainTheorem.lean`.
No proof artifact is needed to compile the executable source under PSC1.

## Proof and execution boundary

The concrete model interprets Empty as Lean `Empty`, Unit as `Unit`, Nat as `Nat`
and arrows as functions. Successful inference constructs a denotation using
models of its global/local contexts. Successful sequential admission extends the
model with the interpreted checked body. The consistency theorem consumes the
actual executable acceptance equation and rules out any successful closed Empty
query in the admitted environment. See [proof status](PSC1_MIN_KERNEL_PROOF_STATUS.md).

The theorem covers the safe Lean definitions. Compilation of those definitions
through PSC1 and execution of emitted TypeScript/JS is separately exercised in CI.
Vector parity, strict IR and exact source/admission hashes do not prove compiler
semantic preservation or extend the theorem automatically to generated machine code.
The model requires the ambient Lean logic and its reported standard dependencies;
it does not assume an unmodeled initial logical environment.

## Host selection

The research adapter at `packages/pskernel-min/host/toolchain.mjs` has explicit
`min`, `lean-wasm`, `lean-native` and `dual` spellings. The trusted caller chooses
the mode. The default is `lean-wasm`; official modes use the existing installed
`host-tools/kernel-toolchain.mjs`, including its pinned distribution, actual
checking, byte identities, refusal and process limits.

| Mode | Current canonical PSC1 behavior |
| --- | --- |
| `lean-wasm` | Existing official Lean 4.35 linear-memory Wasm toolchain |
| `lean-native` | Existing official Lean 4.35 native toolchain |
| `min` | Explicit `PSC1_MIN_CANONICAL_BRIDGE_UNPROVED` refusal; no delegation |
| `dual` | Same explicit refusal until a common canonical domain is proved and qualified |

The typed fragment's executable source is available independently. Its canonical
decoder/translation is not implemented or proved. The adapter therefore does not
pretend that a min/dual canonical admission succeeded. It is not wired into
production publication or the installed closed official provider set. Source
metadata and copied receipts cannot authorize checker selection. Actual official
both-provider comparison retains its existing meaning; it is distinct from future
min-plus-official dual mode.

The pinned official commit remains
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. The official C++/Emscripten Wasm
kernel retains linear memory; PSC1 compiler-Wasm retains GC. Official kernel
compatibility does not extend PSC1's supported frontend to arbitrary Lean source.

## Resource boundary

Term/type fuel bounds recursive inference/equality depth; declaration fuel bounds
the number of admitted declarations. Exhaustion returns `none`/`false` and cannot
grant admission. List lookup is structurally terminating. These are not aggregate
work, heap, host stack, annotation-size or raw-input limits. The initial API accepts
finite typed Lean ASTs and has no hostile-byte decoder. Raw generated JS object
graphs, cycles and hostile getters are outside this interface's qualification.
Before exposing arbitrary fragment input, add bounded ingress, aggregate work and
process controls and connect their acceptance to this theorem. Canonical mode
currently refuses before executing such input.

## Why full compiler self-hosting remains open

The census at `d6bebd230bcaadf35a254bfbc5a26a17228db55f` in Linux
run40444275459 measures the actual124-module compiler graph. It has dependent Core, inductives/recursors,
projections, polymorphism and a nonempty primitive foundation. The census measures
the exact canonical graph and prelude instead of assuming the surface syntax is
the kernel language. A model for 60 declared foundation axioms and an acceptance
proof for the dependent rules are substantial missing mathematical obligations.
No runtime fallback or canned receipt can discharge them. Reusing a full proved
checker or constructing a proved translation remains an option if measured
extension cost makes direct modeling unsuitable.

G1/G2/G3 under the new kernel is gated on complete generated-checker admission of
the current compiler closure. It is not meaningful to run an official-checked
generation and relabel it minimal-checked. Existing frozen release fixed points
remain attached to their original sources.

## Restricted next target after the runtime ledger

The exact-source ledger and actual Core scope theorem pass Linux40455022116
at579642626daa67bd167dd1af626f5b0e0401cb00. Based on17 syntactically constant
recursor motives and3 regular owned data groups, the next bounded target is a
direct model of a closed-type/regular-data profile. This selects a research
sequence, not a completed dependent architecture or a new acceptance mode.
[Current profile and R1–R4](PSC1_MIN_KERNEL_RUNTIME_PROFILE.md) owns that sequence:
proved executable binder lowering, modeled datatype/recursor instances, exact
foundation and projection rules, then bounded canonical ingress and self-check.
No metadata/hash/fixture-based admission or silent proof erasure is permitted.
