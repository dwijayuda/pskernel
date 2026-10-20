# PSC1 current work state — Practical Core v7.2 continuation

Updated 2026-10-20. Branch: `feature/psc1-v7.2-practical-core-v1`.
Continuation [draft PR #163](https://github.com/dwijayuda/pskernel/pull/163).

## Authorized work and preserved lineage

Continue the repaired PSC1 implementation with **PSC1 Practical Core — v7.2 subset**:
retained supported functionality plus exactly fourteen approved feature families.
The selected reference is `PSC1_LANGUAGE_REFERENCE_v7.2.md`; the acceptance
matrix is `docs/PSC1_PRACTICAL_CORE_STATUS.json`.

PR #162 remains open with head `a2778be648850a1f6a2381e28babcd4a6e783e31`,
targeting `psc1/direct-multibackend-v1`. This continuation is stacked on that
unchanged repair branch. The parent implementation
`f933691a1d6fa578c59623636afbb02119909837` passed run 39332460452;
the repaired head passed run 39333660822. The f933-to-a277 difference is three
documentation files. Historical repair evidence remains intact, and the prior
work state is in `docs/history/AI_WORK_STATE_BEFORE_PRACTICAL_CORE_2026-10-20.md`.

## Completed checkpoint: first coherent slice

**The scoped first slice is implemented and qualified** at
[`4be91b111c1773f02a009fb2f643b18912cee920`](https://github.com/dwijayuda/pskernel/commit/4be91b111c1773f02a009fb2f643b18912cee920),
[Linux run 39348537989](https://github.com/dwijayuda/pskernel/actions/runs/39348537989), conclusion **success**.
CI checkout `aa3afeb4f7087f7b9781d67230dda919ff0b38ff` has the same tree
`cb778954f86ce09fe22b4ed36240cb89f4e16382` as that implementation commit.
Later documentation-only commits record this evidence; they do not redefine the
tested implementation checkpoint.

The exact receipt is
`docs/PSC1_PRACTICAL_CORE_SLICE_1_QUALIFICATION.json`; the readable explanation is
`docs/PSC1_PRACTICAL_CORE_SLICE_1.md`.
[Readable output bundles and execution records](https://github.com/dwijayuda/pskernel/actions/runs/39348537989/artifacts/12231958323)
have digest `sha256:df0ba1a2cef4b11caf640b9bc2f1b1b2fdf817758a1525cb99216772d235374f` and expire
2026-11-03T00:38:16Z. The versioned scripts reproduce the evidence.

Passed groups: 15 host tests; 18 native owned-kernel regressions; IR specialization,
maps, official provider and host boundaries; 24 preserved backend groups; five
source-edge groups; 25 contextual-inference checks; 32 typed-do checks; operator
Core-equivalence/negative tests; ordinary admission/opacity/pairing/budget tests;
36 executed forms artifacts with 132 result assertions; all nine ordinary runtime
and negative-boundary groups.

### Implemented and qualified boundaries

- Transactional expected-result constraints for ordinary nondependent call
  arguments, preserving sequential dependent/intervening-implicit checking.
- Fixed-precedence selected Nat/Int/Bool operators and checked equality forms.
  Genuine Prop-valued ordering such as `a < b` is still unsupported.
- Shared Type0 Id/Except/checked CompilerM do sequencing, immutable typed/inferred
  locals and binds, Unit actions, terminal return, aliases and roundtrips.
  The CompilerM kernel fixture observes both reading 7 and updating state to 8.
- Explicit ordinary partial execution with a safe opaque constructive inhabitant
  plus independently checked exact executable-body declaration. Runtime erasure
  consumes the original body only after recomputing and comparing the exact
  ordered logical graph. Verified mode refuses without fallback.
- Shared runtime-prelude selection for host ownership and erasure; checked
  Sort-valued declarations erased from runtime only; quote-preserving formatting
  with the strict AST gate retained; Wasm function/heap type grouping corrected.

Forms coverage is explicit: numeric inference/Prod/Array/operator examples ran
on JS/TS/Rust in both syntaxes; Bool operators and Id/Except do ran on all five
targets in both syntaxes. Ordinary countdown ran on JS in both syntaxes; ordinary
recursive Bool dependencies ran on all five targets from Lean. ProofScript
ordinary also has native admission and strict IR evidence. CompilerM has kernel/IR
evidence, not general source-IO or all-target runtime qualification.

The witness constructor shares a total attempt budget across product children
and failed Except alternatives. This bounds compilation work. Runtime recursion
has no semantic fuel cutoff. Intentional divergence passed an external 1000 ms
process-timeout check.

## Completed prerequisite: Lean 4.35 migration

The separate pin-only checkpoint
`1bd0854f735cf8d0c8f3d07f705195c131acbd61` passed
[run 39344155280](https://github.com/dwijayuda/pskernel/actions/runs/39344155280)
before feature changes. The actual compiler/provider pin is Lean 4.35.0 commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
Native identity and bundle provenance enforce the current version and commit.
Historical 4.34 assets retain their original pins and receipts. The owned kernel
is separately native-tested; official Lean remains the direct admission provider.

The normative PSC0 reference remains commit
`33676076bcda7b0de5ec1f9803f49b8b1d28a058`, blob
`694115223777599ba28ee175e14bb642b7b6aa4b`. PSC0 stays read-only.

## Remaining selected work and next slices

Every full family remains incomplete. Continue from the qualified checkpoint;
do not repeat the completed pin migration as unfinished work.

1. Add genuine proposition-valued comparisons and the checked decision/if path,
   then qualify remaining bounded operator and inference interactions.
2. Extend shared control lowering to branch/handler early return, lexical
   mutation, finite for iteration and while. Reuse the explicit ordinary
   logical/runtime separation; do not add forbidden control forms or fuel cutoffs.
3. Complete selected tuple/array literals, patterns and indexing; typed
   try/catch/throw; namespace declarations and lookup.
4. Add small typed source IO through an explicit bounded adapter contract and
   qualify each claimed target/source-form interaction.

The matrix remains authoritative for all fourteen families. Qualification of this
subset does not mean full v7.2, unrestricted Lean, behavioral certification, or
complete family coverage.

## Architecture invariants and execution rules

Preserve captured immutable source closure, exact admitted graph/runtime identity,
specialization input/output rechecks, source ownership, collision-aware symbols,
implementation/.d.ts agreement, useful maps with unmapped generated regions, and
transactional target publication. Component public ABI remains Bool-only.
DirectJS has no hidden TS compiler. JS host helpers perform layout/filesystem work,
not source elaboration or trust decisions.

Use connected GitHub and focused Linux cloud CI only. No local checkout/build/test,
full self-host generation/census/fixed-point tests, package publication, releases,
merge, force updates, kernel fuel increases or new assumption allowlist.
Read actual HEAD before writes and use non-force expected-HEAD updates.
Keep repair PR #162 separate and continuation PR #163 as a draft.
