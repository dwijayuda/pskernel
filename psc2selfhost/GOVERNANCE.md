# PSC2 implementation governance

Status: implementation policy for this workspace, established 2026-09-27.
Normative words apply to future changes; they do not assert present compliance.

## Mission and boundaries

Build one portable compiler and an independently checked kernel integration that
can progress from Lean-hosted source to ordinary ProofScript source and repeated
self-compilation. Deliver PSC2 programming, prover and verification capabilities
without reopening PSC1 or growing the logical trusted base for convenience.

The first critical path is workspace repair, independent admission, actual
compiler-source closure and the JavaScript fixed point. Preserve Rust/Wasm
implementations and regression coverage; their separate host-completion work
must not become an accidental prerequisite for that first fixed point.

## Authority by concern

| Question | Authority |
| --- | --- |
| What is authorized now? | Current explicit user instructions and accepted decisions. |
| What actually works? | Source and executed evidence at the exact revision, not prose status labels. |
| What is PSC2 supposed to mean? | `PSC2 Lang/PSC2_LANGUAGE_REFERENCE.md`, with PSC1 inheritance; resolve draft conflicts explicitly. |
| What does claimed Lean compatibility mean? | Pinned Lean source/tests under the declared semantic profile. |
| How is this workspace developed? | These governance, architecture, bootstrap and acceptance documents. |
| What can other branches contribute? | Their inspected source and revision-specific evidence after integration review. |
| What do memories establish? | User intent and historical context; they cannot certify current implementation. |

Language lineage is ProofScript v0.7 with the compatible v0.6.1 compiler-ready
baseline. v0.8 is not normative. Consult the repository
[study policy](../docs/STUDY_REFERENCE_POLICY.md). The compatibility baseline is
Lean 4.34.0, pinned commit `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`;
new Lean releases require a separately recorded compatibility campaign.

Scope clarification: historical `docs/plans/07_SELF_HOSTING_FOUNDATION.md`
continues to govern the PSC1 lane. Its priority lessons apply here, but its
old generation names and TypeScript-only production-kernel assumption do not
override the explicitly staged PSC2 kernel migration. This policy does not
rewrite that other lane's acceptance evidence.

## Invariants

1. Preserve one source-semantic pipeline and one target-neutral runtime IR.
2. Keep kernel checking independent of elaborator inference/unification.
3. Only independent admission grants CheckedCore status. Decoding, serialization,
   metadata, hashes and a `checked` flag cannot grant it.
4. Verified erasure consumes admitted declarations with their environment,
   profile and assumption identity. Proof-only declarations need no runtime IR.
5. Unsupported syntax, semantics, dependency versions and target capabilities
   fail explicitly. Never silently weaken verification or select another checker.
6. Runtime-only partial/unsafe/FFI behavior cannot manufacture proof evidence.
7. Preserve exact Nat/Int and the inherited machine scalar contract, including
   `USize`/`ISize` profile widths and defined overflow/conversion behavior. Never
   infer portable meaning from host defaults.
8. Keep effects, evaluation order, persistence and aliasing observable semantics
   stable across TS/Rust/Wasm. Host capabilities and their trust are explicit.
9. Keep one authoritative source tree per component. No manually synchronized
   Lean/ProofScript implementations or hand-edited generated compiler output.
10. Retain independent oracle checking when the compiler also builds its kernel.
    A self-hosted kernel accepting itself does not establish soundness.
11. Preserve existing gates. Do not relabel bounded replay as exhaustive replay,
    runtime tests as proofs, or self-hosting as compiler-preservation proof.
12. Backends, tactics, plugins, solvers, AI and optimizers have no logical
    admission authority. Their correctness still matters to end-to-end claims.

## Extension decision order

Prefer an ordinary library. Put foreign behavior behind capabilities/FFI.
Implement surface conveniences through desugaring. Use controlled Meta/tactic
or plugin APIs where compiler participation is necessary. Change Core/kernel
semantics only with a separate versioned semantic proposal, compatibility and
assurance argument. Do not create a second checker to make a feature work.

## Feature/change record

Every semantic feature or migration change records:

```text
id; requirement/reference; owner package
implementationProfile; acceptedLanguageProfile
loweringTarget; kernelProfile; assumptions
backendCapabilities; hostCapabilities
positive cases; negative cases; dual-source cases
bootstrap dependency; prerequisite gates
evidence revision/commands/artifacts; remaining exclusions
```

For a source convenience, the record must explain how it lowers to existing
semantics. For a kernel change, add a pinned Lean oracle case and independent
review of the admission boundary. Keep optional work off the critical path
unless a concrete compiler dependency makes it necessary.

## Branch and integration policy

Use `main` as the integration base and focused PSC2 branches for changes under
this directory. Existing active branches are reference/donor lanes, not
automatically authoritative successors. Compare behavior and contracts before
porting changes across different physical paths. Never merge all diagnostic
branches or select the newest commit solely because it is newest.

A merge candidate records its base/head, affected gates, executed tests and
known limitations. Refresh after conflicts or semantic changes; preserve
unrelated user work. Red required gates remain red until repaired. Separate
expensive assurance gates may remain explicitly open for a narrower milestone,
but cannot be omitted from a claim that requires them.

## Completion reporting

Report the strongest demonstrated named milestone, the first remaining blocker
and the next evidence-producing action. Avoid completion percentages without a
frozen denominator. Distinguish compiler self-host, kernel self-host, language
profile completion, production qualification and formal preservation.
