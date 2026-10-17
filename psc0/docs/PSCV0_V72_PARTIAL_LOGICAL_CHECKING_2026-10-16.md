# v7.2 partial declarations — constructive logical-checking slice

16 October 2026. **Implementation candidate; exact qualification is pending. M3+B remains OPEN.** This slice follows the user's attached prompt and stage directive, preserves the accepted M2 and runtime work, and uses v7.2 only. It is not full P0 execution, P1 fixedpoint construction, verified refinement, or whole-v7.2 conformance.

## Inspected baseline and authority

Baseline `648a91b71e8274821366d001d61e9eb1843ae201` passed native `38845047662` (job `116793557510`, all 33 reported steps), F1 `38845047681`, F2 `38845047708`, and F3/F4 `38845047632`. That baseline only parsed and retained partialDefinition, then refused it during elaboration. Its correction was source-span construction, not a change to negative semantic fixtures. Older chat descriptions claiming implemented partial logical safety at that SHA were inaccurate.

The unchanged authoritative reference is `PSCV0_LANGUAGE_REFERENCE_v7.2.md`, blob `694115223777599ba28ee175e14bb642b7b6aa4b`, SHA256 `c65487eccbd2829d1d9e5e1be3bc7f4cb37849b841ab3257ea0dd47665b8a30e`. Relevant requirements are PSCV0-TERM-02, PSCV0-REC-STRATEGY-01, PSCV0-TRUST-01, PSCV0-VERIFY-PARTIAL-01, and the declaration/module ownership rules. No older grammar mode is added.

## Pinned study and design

Official Lean 4.35.0 at `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`:

- [PreDefinition/Main.lean](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/PreDefinition/Main.lean): addAndCompilePartial first creates a separately inhabited opaque logical definition, then separately compiles the actual recursive body. No recovery/sorry path is adopted.
- [PreDefinition/MkInhabitant.lean](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/PreDefinition/MkInhabitant.lean): the constructive path uses Inhabited search and parameter-derived local inhabitants. Native Lean additionally has a Nonempty fallback; this slice does not import classical choice to reproduce that fallback.
- [tests/elab/1337.lean](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/tests/elab/1337.lean): partial source can contain nonterminating computation. Studying this test is not evidence that its loop/array program is an admitted PSC0 fixture.

The existing scoped command elaborator owns source resolution, section capture, private names and actual origin records. It now routes partialDefinition through a shared partial batch rather than the historical raw partial helper's provisional axiom header. The full header must resolve before recursive-body checking. A genuine function type is required, including the existing Unit sugar for nullary function.

An independent constructive inhabitant is built before introducing recursive self. Parameter values provide local Inhabited dictionaries only within the witness search; existing constraint synthesis, universes and budgets are reused. The witness is closed and type-checked. No instance registration escapes into the source environment.

The batch owns two distinct declarations:

1. Public `opaqueDecl f`, whose body is the independent inhabitant.
2. Private numeric-identity `partialDecl f.0`, retaining the actual typed source body against the opaque `f`.

The numeric identity is not source-spellable, is checked for collision by ordinary insertion, and is hidden from imported source interfaces. Its actual body/source information remains in the prepared project and dependency closure. There is no generated equation connecting the opaque public function to this body, and no termination claim.

## Official checking and executable boundary

`Ps.Compiler.Api` constructs a canonical checking view that maps retained partial body markers to ordinary opaque declarations. The official kernel checks both the public inhabitant and the actual body; it receives no unchecked partial declaration or new axiom. The original prepared graph keeps its partial markers. A checking view is not an executable replacement and is not stored as the runtime graph.

All existing source-owned executable targets share `psCompilerVerifiedIrFromPrepared`. It now rejects any retained partial body with `PSCV0-PARTIAL-RUNTIME-PENDING` before erasure or target emission. This includes imported and unused partial declarations in the prepared closure; it is deliberately conservative in this stage. Never run the logical inhabitant as the source program. No ordinary/verified downgrade or invented assurance identity is introduced.

This distinction is necessary because the pre-existing low-level eraser can lower a partialDecl body; an assumed automatic erasure refusal would have been incorrect. The new gate is explicit and above all backends. Low-level preparation/IR data structures remain non-authoritative; only the checked source-owned host path establishes acceptance.

## Focused qualification candidate

The existing host measurement executable retains its source grammar suite and unchanged benchmark operations, iterations, checksums, runtime source and budgets. Before measurements it checks actual logical/body ownership, private numeric names, unchanged instance registry and retained preparation marker. After the original measured requests, the same immutable prelude supports a compact family of 12 cases:

- Check-only recursive Nat body plus reflexivity, universe-polymorphic parameter inhabitance, private nullary source, captured section parameter, and imported logical interface.
- Intended-phase refusals for an empty result type, False result without an inhabitant, incorrect body type, unavailable defining equation, and non-function partial declaration.
- Explicit refusal of all requested targets and of an imported runtime dependency after successful logical/kernel checking.

A generic unsupported-source error is not accepted as an inhabited-result or opacity test. No executable partial run is claimed. Successful tests establish only their stated bounded cases, not full elaborator equivalence or general semantic preservation.

## Remaining work and performance

Pending: full P0 ordinary execution/assurance identity, broader inhabited/header-inference cases, nonconstructive witness policy where relevant, partial where/mutual integration, P1 fixedpoint monotonicity and equations, operational model/refinement, broader M3 data/elimination/total recursion/deriving. Keep unsupported cases unavailable without expanding assumptions. Native `.lean` language semantics are not restricted by `.ps` rules.

The qualified runtime remains `133af061d6aaff0eb6ed990abd341ca2a44d15e9`. Same-runner study `38840337837` measured 9.25–10.11x fromList improvement, smaller head/array gains, and no meaningful deep-list/reversal improvement. This logical slice makes no new performance claim and does not change those workloads. Continue actual-IR closure/dictionary and safe direct-call analysis from the recorded evidence rather than restarting architecture or substituting JavaScript Number semantics.

GitHub/cloud Linux only; native portable `.lean`; only propext/Quot.sound; no pskernel-core, self-hosting, compiler-source migration, C5, weaker gates or increased budgets. Preserve PR109 draft/open and both histories. Exact CI receipts must be recorded before promoting this candidate.
