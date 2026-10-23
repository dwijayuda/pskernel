# Rust and TypeScript self-host architecture

Current evidence and queue live in [AI_WORK_STATE.md](../AI_WORK_STATE.md),
[the roadmap](PSC1_DEVELOPMENT_ROADMAP.md) and
[the canonical receipt](PSC1_RUST_TS_SELFHOST_QUALIFICATION_2026-10-23.json).
[Earlier architecture analysis](https://github.com/dwijayuda/pskernel/blob/2cf71d1b0cccbd7f8e3991c99ac9f2b377ed4cce/psc1/docs/PSC1_RUST_TS_SELFHOST_ARCHITECTURE.md)
and every previous experiment remain preserved in Git and historical receipts.

## One compiler and a fixed verification boundary

Ps.Compiler.Service owns the existing source/frontend/elaborator, original
checked IR, closed target planning, canonical admissions and origins. Thin Rust
and TS service facades use existing emitters. There is no separate handwritten
compiler, native semantic delegation after the one seed, or replacement checker.

Read registered owned source closures, pin source/tool/request identities, call
one native seed, then remove native compiler executables. Each generated compiler
actually produces the next candidate. A separate host verifies wire/source/
artifact identities and independently admits canonical graphs with official
Lean4.35.0 commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Original and transformed strict IR checks, public API validation, negatives,
unsupported ABI refusals, semantic fuel and memory/stack policies remain.

## Profiles and demonstrated qualification

[Profile machinery](PSC1_SELFHOST_QUALIFICATION_PROFILES.md) changes scheduling
and wall clock only. Default performance-240s retains240000ms requests/builds and
15-minute jobs. correctness-1800s extends only actual G2-self/G3-self requests
to1800000ms, with120-minute jobs,110-minute execution steps and5s cleanup guards.
G1/corpus/builds retain240000ms; independent admission retains120000ms;
streams32MiB and wire128MiB remain. Nested process trees, including new sessions,
are killed on deadline. Malformed wire reaches existing generated refusals.

Rust source5e0b548e/request7d8865a0/run39908529181 genuinely passes G1/G2/G3,
independent admission, ten cases per generation and exact source/closure/
admission/original/transformed IR/observations. G2/G3 complete692788/660042ms.
All three executable hashes also match within this pipeline. This is correctness
qualification for that isolated source;240s and separate clean build repeats
remain independent requirements.

TypeScript shared-codec source29e871ea/requestb5ba1452/run39908439190 passes G1
and ten cases, then times out at1800240ms. No G2 admission, G3 or fixed point.
Original240s attempts fail separately. Native proof, diagnostic success,
G1, G2/G3 and publication are distinct claims.

The active main source5ce2fc74 passes normal run39909569028, all47 full steps and
37 finite Practical Core criteria. Both grammars/all7 backends and installed
native distribution remain qualified. Later source/backend candidates have not
been promoted merely because Rust self-host qualification passes.

## Measured implementation mechanisms

Preserve checked scalar closed specialization/fusion with generic fallback and
strict pre/post checks. Earlier source-wrapper changes did not alter synthesized
generic workers; do not remove the generic guard without correct instantiation
of type parameters, call spines and captures.

Rust uses checked last-use String transfers and safe iterative destruction only
for private regular last-field linear inductives with an empty sentinel. Preserve
shared-tail/order/public ABI guards and500000-node regression. Shared cursor/
lexer accumulation has official all-input equality proofs and100001-token cases.
TypeScript result annotations derive from checked IR and retain strict native
checking; structured generator output retains old/current equality/refusal tests.

Current canonical codec schemas remove temporary field lists and share fixed
key/tag quote values with definitionally equal source definitions. Official
all-input Name/Level/List/Expr equality against retained encoders passes.
TS emits zero-argument values once; Rust functions do not imply identical cache
behavior. Early literal-quote reductions failed on opaque String primitives;
those failed proofs remain preserved and were not bypassed.

Current TS replay39912539573 samples last30s of a220s G2 request and shows
generator/thunk work in escape predicates, codec and constructor lookup. A small
shared-source trial replaces lazy Boolean disjunction with explicit branches.
Its all-Char proof/native comparisons/regressions/audits and G1 pass; G2 times out1800199ms in run39913434540. Cache/index hypotheses remain hypotheses; neither
the two-entry UTF8 cache nor raw-position semantics have been changed.

Combined TS trial39914906360 then normalizes constructor/height lookups into
fully applied workers, avoiding eager suffix-closure construction. Existing
function types remain. Universal list/name/fuel/index/hash equalities, first
duplicate and100001-entry miss checks plus G1 pass; G2 times out1800149ms.
No index/cache/resource policy changed in that source. Predicate-only trial is a separate terminal control.

Rust late stack39906025465 reaches strict IR checking and nominal-arity lookup.
A derived bounded index may reduce repeated searches if exact lookup and
resource/report behavior are proved. A single stack is not total CPU attribution.

## Acceptance and integration

Require actual emitted generations and exact fixed points for each target.
Compare complete real compiler requests, wall time/RSS, target tool build time
and source sizes separately; censored timeouts are not complete-workload speed
rankings. Same-run identical executable bytes are not independent clean-build
reproducibility. No formal backend preservation theorem is claimed.

Preserve all seven backend mappings, both grammars, the frozen Practical Core
contract and real applications. Promote dependency-coherent validated changes
with fresh full normal qualification. Keep DirectJS as reference/G1 regression,
its original G2 heap defect tracked, and ExpressionV2 research separate from
compiler work and official Lean admission. No merge or publication is authorized.

## Terminal later experiments

The applied-lookup source's actual IR workers are fully applied (two parameters,
data/scalar result, zero body lambdas). Its current220s replay39918874112 shows
StringEqual61.8% under psStringEqFromWithFuel. This diagnoses a remaining path,
not the full1800s tail or a complete workload runtime.

Bounded two-view Map sourceaae4aac4/request9f39ab51/run39920694158 preserves exactly
two view objects and insertion/eviction order. Strict TS7 differential checks
pass1458 comparisons across Unicode/surrogates, invalid raw positions and equal
separately allocated strings. G1 passes ten cases; G2 times out1800169ms at
1787220KiB. Single synthetic prefix timing establishes no advantage. The extra
cache index is not selected for promotion. Preserve all experiments, prefer
applied-lookup baseline0938c895/a10c0162 for measured next work and do not infer
G2/G3 from native proofs or a lower observed peak on a different censored run.
