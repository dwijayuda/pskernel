# PSC1 minimal-kernel architecture

## R2 qualified normalized-profile checkpoint — continue with R3

R2 passes both standalone Linux jobs at
**`028dcd98fabcb0bf196c0d6f27a80bad3b666745`**, run
[40469648092](https://github.com/dwijayuda/pskernel/actions/runs/40469648092):
proof/native **122073398746**, portability/census/source witness **122073398515**.
The user-confirmed setting is GPT-6.1 Sol / High. All project builds, proof checks,
source compilation and tests in this batch ran on GitHub Actions Linux.

Read the [R2 profile and precise boundary](PSC1_MIN_KERNEL_R2_PROFILE.md) before
editing. The isolated executable checks closed Type-0 codes and ordered regular
datatype descriptors, derives constructor/fixed-result recursor signatures, and
checks sequential declarations from an empty environment. The generic concrete
tree model discharges the signature model; actual inference/admission success
gives a model and Empty consistency. The iota law covers the entire declared
descriptor family. Stable chronological quotation names are proved injective
and preserved when relative slots rebase.

All **24** new printed model/validation/name/source bridge reports contain
no axioms or exactly `[propext]`. The native and actual PSC1-generated corpus
passes **23 positives, 38 refusals and two out-of-range probes**. The complete
five-module source/test graph is admitted by official Lean 4.35. Its bundle is
105087 B TS / 221393 B JS; these include test/shared runtime code. The two-module
checker source has 307 lines/12268 B; naming adds Foundation.Name and
RegularNames (four-module checker-plus-naming closure 17081 B). The original
Check.lean remains 93 lines/3322 B with its original source SHA.

The concrete source-image theorem connects the checked normalized recursor to
the exact retained PsMinTy.rec spine, with its actual host PsMinTy/Bool model and
R1 motive-instantiation law. CI locates the native proof witness structurally
once in the current source-origin-bound psMinTyEq worker. This is a representative
typed source-image result, not a general decoder, external name resolver or proof
for all 115 canonical foundation declarations. Internal quotation names do not
authorize arbitrary canonical source-name binding.

Previous R1 main 40460549124 and installed 40459838431 are terminal success.
**Historical broader-regression snapshot at 07:55 UTC / 14:55 Asia/Jakarta:** R2
main 40469652253 and installed 40468550390 were in progress. Reporting commits may
supersede main; query the live PR checks rather than infer current status from
this snapshot. The dated receipt preserves each exact commit/run/artifact scope.

**Next batch is R3:** measured lets, declaration projections and exact pinned
foundation instance semantics, keeping the real acceptance-to-model bridge.
Any delta conversion needs a definition-body/evaluation invariant. R4 still
owns general canonical ingress/name binding/translation and generated execution/
resource obligations. Canonical min/dual still refuse; full min coverage remains
0/124 compiler modules, 0/37 Practical Core and no qualified min G1/G2/G3.
Do not repeat R1/R2 or promote the representative witness to full self-check.


This research branch implements a small, directly modeled checker before extending
it to dependent PSC1 Core. It does not replace the independently checked production
compiler. The [research comparison](PSC1_MIN_KERNEL_RESEARCH.md) selects approach A
for the first complete fragment; the [coverage matrix](PSC1_MIN_KERNEL_COVERAGE.md)
records what is still required by the actual compiler.

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
