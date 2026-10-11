# PSC0 / PSCV0 v7 — Complete Language Feature Ownership and Ranked Implementation Plan

**Created:** 2026-10-11. **Status:** source-grounded plan, not compiler feature implementation or complete conformance. **Only normative ProofScript language reference:** [PSC0/PSCV0_LANGUAGE_REFERENCE.md](../PSCV0_LANGUAGE_REFERENCE.md), v7, SHA-256 843940bd7f6a9b286e80b01d8c891a7e01b8868a9de7b05833fce32d49be6cd5. Target Lean 4.35.0-rc4 exact commit c29b6dda4f7c20e3eeaa717c4e565663c5cfa364. Earlier PSC1 and older PSCV grammars are historical bootstrap sources, not compatible active source languages.

## Decision

**Shift development focus from bulk source conversion to systematic v7 feature completion, with real self-host source migration as an acceptance workload.** Otherwise we risk rewriting the whole compiler in a mechanically verbose, narrow programming subset. Current portable v7 source adapter declares capability declaration-except-do/1 and full-conformance = false; it selects ordinary def/function/const, structure, inductive, theorem and a narrow Except do, but explicitly refuses more do and command families. This is not enough to implement the full v7 grammar, which covers Lean-native proof language, typeclasses, dependent pattern matching, numerics, collections, contracts, verification effects and selected rich standard APIs.

**Last qualified development checkpoint:** [Linux 20-module five-v7-authored-source closure CI #38134451122](https://github.com/dwijayuda/pskernel/actions/runs/38134451122) passed on source 0e8996d2. Five real PSCV0-authored modules plus 15 retained Lean modules emitted byte-identical canonical admissions, TypeScript 7 and JavaScript compared with the previous qualified artifact. Compiler preparation 497482 ms, total script 819997 ms. **This is a bounded compiler-source milestone, not complete 64-module self-host fixed point, not all v7 features, not kernel admission on that run.** No Windows or independent PSKernel tests were run.

## How to interpret the feature registry

The accompanying [100-feature-group machine-readable registry](PSCV0_V7_FEATURE_INVENTORY.json) is the tracking source. These are **feature families**, not 100 individual parser test cases: each group needs several grammar/elaboration/runtime/error-phase tests. Initial classification: **82 P0 Standard obligations; 11 separately gated P1 requirements; 5 forbidden-source/assurance groups; 2 explicitly deferred proposals**. This is NOT a percentage completion score.

- **evidenced-bounded:** positive source/program evidence in one qualified restricted v7 path only; does not imply all variants.
- **partial:** some PSC0 implementation or concrete evidence exists, but normative coverage not closed.
- **not-qualified:** mandatory v7 feature has not been demonstrated in the generated source compiler; may already exist in Lean or other branches.
- **planned-staged:** selected P1 module/import/extension requirement; NOT silently part of initial Standard.
- **deferred:** intentionally outside current v7 base. An exclusion is a required *refusal*, not a missing implementation.

For every feature follow v7 §0A, §0B, §13 and §14.1A: exact RC4 source/parser/elab locator, selected PS source shape, positive case, phase-specific negative case, source tree/typed output, Standard environment/assumption identity, and target/runtime correspondence where executable.

## Keep the actual existing package boundaries

The live PSC0 source tree already has foundation, syntax, core, environment, meta, elab, bridge, compiler, compiler-ir, erasure, stdlib, backend-ts, backend-js, backend-wasm and backend-rust. Retain them. **Do not rename the workspace to pscore/psfrontend or put every feature into a monolithic PSCV package.** The platform PSCV P0 design branch previously recommended the same modular ownership. That older design reference uses an RC3 spec; reuse its boundary principles only, and let v7 RC4 override obsolete grammar and ghost wording.

| Actual package / optional service | Owns | Does NOT own |
|---|---|---|
| foundation | UTF-8 spans/positions, names and minimal pure support types | language semantics/proofs |
| syntax with Ps.Syntax.Pscv0 modules | lexer, v7 selected category grammar, concrete source AST, separator/call ownership, source maps, source printing | typeclass search, WPs, proof certificate |
| core + bridge | compiler-level Lean term/universe encodings, checked-term representation/encoding | v7 source syntax, new logical primitives |
| environment | pinned imports, Std classes/instances, simp/notation/deriving registries, fixed priorities/defaults | unchecked plugin-based grammar mutation |
| meta + elab | unification/elaboration, binders, defaults, type-directed coercion, recursors and termination candidates | hidden fallback to historical .ps grammar |
| compiler + bootstrap | dependency graph/incremental source preparation, provenance, exact compiled product, self-host stage | arbitrary externally asserted verified flags |
| compiler-ir + erasure | typed execution IR, relevant effect/data/erasure correspondence | logical theorem acceptance |
| backend-ts | currently qualified TS7/JS executable target and target ABI | proof scripts, interpreter tricks |
| stdlib + pinned Lean/Std APIs | List/Array/Option/Except, scalar functions, ByteArray/BitVec, formatting/strings, later maps/JSON | new language syntax when library suffices |
| future optional tactic/prover service | Lean RC4-selected tactic execution/goal states, concrete proof-term proposals, explicitly pinned proof environment | a second kernel, unchecked proof oracle |
| future reusable verification service | contracts, WP models, verification conditions, complete obligation/effect/erasure plans | proof authority or unverifiable verified emission |
| future official PSCV policy descriptor | closed v7 edition and Standard fingerprint, selected assurance policy and required capabilities | all real syntax/tactic/backend implementation |
| independent pskernel-core/checker | release-time proof/term acceptance only | compiler feature ergonomics; NO TESTS in current loop |
| optional backend-js / backend-wasm / backend-rust | separately qualified target mappings after shared IR | initial v7 language-coverage gate |
| tool/host platform (psc/psdev/pslsp) | diagnostics/InfoView source mapping, boundary-controlled publication and editor workflows | semantic authority or hidden source grammar |

**New package rule:** Do not add empty prover, tactics, verified-stdlib, spec or SDK packages now. Add a genuine optional module only when a feature has executable code, a necessary boundary and its own conformance tests. General-purpose typing/elaboration remains in existing packages. The source-language profile selects features but is not their implementation bucket.

## Ranked waves — dependencies before breadth

| Wave | Priority | Implementation and scope | Fast exit gate |
|---|---|---|---|
| W0 | Immediate prerequisite | Sole source edition, minimal versioned Standard manifest and environment digest scaffold, phase-aware feature tests, exact compiler/cache identities, source-graph trust boundaries | identity checks and no old parser fallback; preserve 5-authored-source closure |
| W1 | **Highest ROI now** | Grammar-category ownership; fix local typed-let String -> Nat -> List Char := ... lookahead, calls/grouping/Unit completion, ordered binder and named/default args, where locals, priority operators, source comments/trivia/formatter | parser/typed-source/AST roundtrip and same 5-source compiler admissions/TS7 on Linux |
| W2 | High | everyday expressions/data: literals, lambdas/ascription, typed if, record/update, field/method, tuples, list/array literals and selected simple patterns. Include basic structural recursion and small curated APIs. | small compiler snippets, v7-authored dependent modules, typed IR/TS7 behavior |
| W3 | High dependency, significant complexity | exact RC4 Standard classes/instances/coercions/deriving, broader numeric and BitVec/ByteArray runtime, indexed inductives, multi-discriminant/dependent match, rich patterns | environment fingerprint, type-directed compiler differential, exact RC4 conformance slices |
| W4 | High everyday capability | broaden base do beyond bounded Except; do-if/do-if-let, mutation/assignment and early returns under typed monadic semantics | compiler-only typed do and TS7 first-error/correct-control-flow runtime |
| W5 | Proof-language target | native Lean proof terms, by { ... }, goals, case/next/bullets, simp/omega/grind, well-founded recursion | exact selected Lean RC4 proof-production and goal-state/source-location evidence; release checker separate |
| W6 | Strict verified executable target | given/requires/ensures, where-finally spec proof, vcgen, erased/assert, verified loops/WP effects, complete VC/assumption/erasure coverage | incomplete obligations block verified emission; do not trust success flags |
| W7 | Opt-in P1 | typed throw/try/catch/finally in selected P1 environment, pinned proof extensions, maps/sets/JSON/codecs, typed world/TS/npm boundaries | explicit import/handler/effect environment and boundary identity |
| W8 | Deferred | extended async, alternative targets, proposed native Rust owner/FFI semantics, new old/reads/modifies/errors syntax | not a blocker for full **initial** v7 Standard |

### Next three concrete feature slices

**Slice 1 — source-category correctness, not a test patch.** Fix typed local type-application/assignment ownership at the grammar level (the current Parser/Read workaround List(Char) is valid, but List Char := must be parsed correctly where v7 admits native application). Add parser property tests across terms, binders, tactics, #check, grouping and patterns. Support full v7 default/named args and exactly-one-Unit empty calls. Keep AST/source spans and comments coherent.

**Slice 2 — typed program features that eliminate compiler verbosity.** Add proper operators/precedence, type ascription, short lambda/let/where, fields and record updates, List/Array literals, safe indexing and selected richer single-match patterns/if-let. Each feature must be exercised in both a small useful program and an actual v7-authored compiler module. Require canonical compiler admissions/TS7 parity to historical source where the refactoring claims semantic equivalence.

**Slice 3 — RC4 environment before expanding implicit behavior.** Freeze the currently supported imported aliases, basic numeral/default types, typeclass instances/notations, source handlers and an environment fingerprint. Expand only with pinned signatures. Then develop a Lean-RC4-selected theorem language and proof-producing tactic service, **rather than rewriting every native tactic, class solver and recursive equation compiler from scratch**.

## Efficient self-host preservation protocol

**Every small edit:** run source grammar/negative cases (phase correct), Linux node syntax check and cached generated frontend -> recipient-owned AST -> actual PSC0 elaboration -> TS7 -> Node runtime. The current tiny compiler test measured about 1–2s of process time, *not including CI setup*. No Windows or kernel suite execution.

**When a compiler-source module changes, with grammar unchanged:** run the cached in-memory dependency graph; memoized preparation keys must include all previous source hashes, exact selected edition and Standard environment digest. The source graph qualified four independently authored v7 modules over nine configurations with identical admissions/TS7, then a five-source 20-module closure. Do not convert this into a kernel claim.

**When the frontend/grammar implementation changes:** the previous generated grammar cache becomes stale and MUST fail closed. Run native only affected compiler-package typechecking first; at an intentional milestone regenerate the 20-module v7 frontend and compile the whole current selected v7 source closure. Retain the previous source hash, generated JS digest and failure evidence. Never modify qualified old compiler or kernel seed in place.

**At intentional compiler self-hosting milestones:** execute the full historical ~64-module compiler-only bootstrap/fixed-point cycle with exact source, canonical core/admissions, TS7 and JS identity (C0–C3 as qualified by the older workflow), not on every small iteration. Preserve the 69-file historical source inventory as immutable seed evidence, not a second grammar standard. Promotion should be a non-force expected-HEAD integration only after the new source identities and Linux results pass.

**Separate, deferred release/assurance:** independently check all submitted terms/proofs, the complete VC/effect/assumption/erasure closure and target/backend validity. That gate is unchanged but is NOT invoked by this user's Linux-only compiler-development request. Every development report must mark independent-kernel-tests=false, windows-tests=false, verified-executable=false and full-compiler-fixed-point=false until actually earned. Windows portability is static review via path.join/pathToFileURL, UTF-8 source hashes, canonical logical names, and OS-agnostic TS7/JS code, **not a Windows pass**.

**Avoid architectural drift:** Lean RC4 itself has sophisticated separate command/term/tactic/do/attribute syntax categories and elaborators; PSCV0 should select and adapt these actual semantics, not construct a parallel Lean theorem prover, invented JS-specific data meaning, arbitrary TypeScript cast semantics or a generic syntax plugin bypass. If reusing Lean native elaboration for an advanced feature, disclose that dependency and separately qualify the portable self-host source path rather than pretending a native oracle is part of the tiny generated PSC0 frontend.

Official background: [Lean syntax and categories](https://lean-lang.org/doc/reference/latest/Notations-and-Macros/Defining-New-Syntax/), [Lean elaboration/core/compilation](https://lean-lang.org/doc/reference/latest/Elaboration-and-Compilation/), [Lean 4.35.0-rc4 release notes](https://lean-lang.org/doc/reference/latest/releases/v4.35.0/). The RC4 SHA above—not mutable /latest pages—is the semantic pin.

## Full inventory by ranked wave

Each row is a **feature family** linked to the sole v7 reference section, not an implementation-success claim. See JSON for exact stable feature IDs and stage/acceptance metadata.

### W0 — edition, provenance and policy (13 entries)

| ID | v7 feature requirement | Class | Owner | Current evidence | Cost | Source/acceptance |
|---|---|---|---|---|:---:|---|
| POL-01 | sole v7 edition and no legacy fallback | P0 | syntax,compiler | evidenced-bounded | S | §0A,§0B; frozen source and explicit refusal |
| POL-02 | exact Lean 4.35.0-rc4 semantics pin; bridge from historical 4.34 | P0 | environment,core,bridge | partial | XL | §0A,§14; RC4 reference against exact emitted terms; no silent version swap |
| POL-03 | frozen Standard environment manifest/digest incl. classes/notation/coercions | P0 | environment,meta,compiler | not-qualified | XL | §0A,§8,§14; deterministic environment import and identity check |
| POL-04 | conformance catalog and phase-specific positive/negative classification | P0 | syntax,elab,compiler | partial | M | §0B,§13; one source-to-artifact fixture per feature and negative stage |
| POL-05 | incremental checked syntax graph and in-memory self-host state reuse | P0 | compiler,bootstrap,tools/abi | evidenced-bounded | M | §14; SHA-pinned Linux compiler-only graph; milestone compiler fixed point |
| ENV-01 | approved import graph/export/typeclass and simp registries | P0 | environment,compiler | not-qualified | XL | §0A,§1,§14; exact ordered Standard environment snapshot |
| VERIFY-06 | checked vs verified artifacts and assumption ledger | P0 | compiler,host,pscv-policy | partial | L | §0A,§7B; independent admission/certificate gating retained |
| VERIFY-07 | noncomputable executable dependence and sorryAx refusal | P0 | compiler,host,erasure | partial | M | §0A,§5; fail-closed closure checks across sources |
| EXCL-01 | partial/unsafe and user-written axiom forbidden in .ps | EXCLUDED | syntax,host | evidenced-bounded | S | §0A,§5; specific negative grammar cases for every mode |
| EXCL-02 | sorry/sorryAx proof holes forbidden in emitted artifacts | EXCLUDED | compiler,host | partial | M | §0A,§7B; no artifact before complete checked obligation closure |
| EXCL-03 | ghost/verify/refine type/invariant self redundant aliases | EXCLUDED | syntax,host | evidenced-bounded | S | §0A,§7; grammar must never silently accept removed syntax |
| EXCL-04 | unrestricted macros/syntax/notation/plugins/set_option | EXCLUDED | syntax,environment,host | partial | M | §0A,§6,§7A; closed registry; only named opt-in proof env |
| EXCL-05 | JS any/null/undefined/typeof/casts/automatic truthiness | EXCLUDED | syntax,elab | partial | M | §8,§10A; no dynamic loophole in v7 |

### W1 — compiler source syntax (18 entries)

| ID | v7 feature requirement | Class | Owner | Current evidence | Cost | Source/acceptance |
|---|---|---|---|---|:---:|---|
| SRC-01 | Unicode identifiers, comments, BOM, separators, indentation and UTF-8 origins | P0 | syntax,foundation | partial | M | §1,§12; lexical and source origin corpus; comments preserved, not dropped |
| SRC-02 | implicit module header, import and public import visibility | P0 | syntax,environment,compiler | partial | M | §1; cross-module import/export visibility and exact graph |
| SRC-05 | source trivia/comment anchoring and printer/parser round-trip | P0 | syntax,foundation | partial | M | §1,§12; round-trip preserving source meaning, comments, span IDs |
| SRC-06 | separate binder, pattern, tactic and term application grammar ownership | P0 | syntax | partial | M | §0B,§2,§11; property tests across local let/proof/match/command contexts |
| DEC-01 | def/function/const ordinary total declarations | P0 | syntax,elab | evidenced-bounded | S | §2; source AST/elaboration equality to selected Lean cases |
| DEC-02 | implicit, strict-implicit, instance and interleaved explicit binder telescope | P0 | syntax,elab | partial | M | §2,§11; ordered telescope/implicit insertion vs RC4 |
| DEC-03 | default/optional, named positional arguments and duplicate refusals | P0 | syntax,elab | not-qualified | M | §2; typed defaults, named args, omitted required-arg refusal |
| DEC-04 | function f() Unit insertion and empty invocation rules | P0 | syntax,elab | partial | M | §2,§11; exactly-one-Unit/optional allowed; def f() refusal |
| DEC-05 | single-term braces; local lets, where and local recursive definitions | P0 | syntax,elab | partial | M | §2,§3; where local scope plus source and compiler equivalence |
| APP-01 | native whitespace f x y and adjacent comma calls f(x,y) | P0 | syntax,elab | evidenced-bounded | S | §2,§11; flattening/nested-application ownership equivalence |
| APP-02 | f (x) / f () gap-application rejection with context exceptions | P0 | syntax | evidenced-bounded | S | §2,§11; token-level APP-02 plus context-negative controls |
| APP-03 | f() defaults/Unit and explicit f(()) tuple argument | P0 | syntax,elab | partial | M | §2,§11; type-driven callable/default checks; no arbitrary missing args |
| APP-04 | mixed f x(y) versus (f x)(y) and canonical printer grouping | P0 | syntax,elab | evidenced-bounded | M | §2,§11; source tree and generated Lean grouping parity |
| APP-05 | tuple arguments, tuple literals/products and trailing comma | P0 | syntax,elab | partial | M | §3,§11; distinguish product from grouped call/Unit |
| TERM-02 | lambda with selected native binders and immutable typed let | P0 | syntax,elab | evidenced-bounded | M | §3; lambda-local abstraction and typed annotations |
| TERM-04 | if boolean/propositional and dependent proof-binder if | P0 | syntax,elab | partial | M | §3; native ite/dite; proof binder scoping |
| TERM-06 | precedence table for arithmetic, logical, bitwise and comparison operators | P0 | syntax,elab,environment | not-qualified | M | §8,§11; exact precedence/associativity and source roundtrip |
| ENV-02 | frozen notation and operator binding power, no silent plugin grammar | P0 | syntax,environment | partial | M | §0B,§8; versioned syntax environment and precedence |

### W2 — typed expressions and data (18 entries)

| ID | v7 feature requirement | Class | Owner | Current evidence | Cost | Source/acceptance |
|---|---|---|---|---|:---:|---|
| APP-06 | static projections, generalized fields and x.method(y) | P0 | syntax,elab,environment | partial | L | §2,§4; field search, deterministic resolution, no JS receiver semantics |
| TERM-01 | Prop/Type/Sort universes and dependent Pi/arrow | P0 | core,elab,meta | partial | L | §3,§8; dependent binder elaboration/level constraints |
| TERM-03 | typed ascription and mathematical quantifiers/Unicode aliases | P0 | syntax,elab | not-qualified | M | §3,§8; ∀/exists/λ aliases plus class-based resolution |
| TERM-05 | if let, matches, nomatch and irrefutable pattern let | P0 | syntax,elab | not-qualified | L | §3,§4; checked pattern bind and impossible elimination |
| TERM-07 | literals: naturals, negatives, scientific, Bool, Char, String, Unit | P0 | syntax,elab,environment | partial | M | §3,§8; type-directed literal instances and numerical semantics |
| TERM-08 | native string interpolation s! and raw r# strings | P0 | syntax,elab,stdlib | not-qualified | M | §3,§8; source interpolation terms respect APP-02 |
| TERM-09 | List/Array literals [] and #[] | P0 | syntax,elab,stdlib | not-qualified | M | §3,§8; typed literal constructors; independent JS backend parity |
| DAT-01 | nominal structures, field declarations, dependent fields | P0 | syntax,elab | evidenced-bounded | M | §4; typed constructor/field elaboration |
| DAT-02 | record literals with comma/trailing comma and expected type | P0 | syntax,elab | partial | M | §4; first-class typed record values, no JS shape guess |
| DAT-03 | record update {s with ...}, defaults and dependent update | P0 | syntax,elab | not-qualified | L | §4; typed field update and proof obligations |
| DAT-04 | inductive constructors and positivity | P0 | syntax,elab,core | evidenced-bounded | L | §4; constructor/recursor generation and positivity |
| DAT-05 | rich constructor/list/tuple/Nat successor pattern grammar | P0 | syntax,elab | partial | L | §4; PATTERN-01; no expression-call patterns |
| REC-01 | structural termination and positivity for total recursion | P0 | elab,meta,core | evidenced-bounded | L | §5; recursive source equivalence and decrease evidence |
| STD-01 | core logical base True/False/Eq/Exists/Quot | P0 | core,environment | partial | L | §8; RC4 theory/prelude evidence; no new axioms |
| STD-02 | Nat/Int/Bool/Unit/Char/String semantics | P0 | environment,stdlib,backend-ts | partial | M | §8; backend differential on scalars and source literals |
| STD-06 | Option/Except/List/Array/Prod/Sum/Empty/Fin/Subtype APIs | P0 | stdlib,environment,elab | partial | L | §8,§8A; curated exact signatures and runtime parity |
| DO-01 | do { let value, monadic bind, action, return } | P0 | syntax,elab | evidenced-bounded | M | §3,§0B; initial Except do only, expand to selected Lean monads |
| DIAG-01 | #check, #print and #print axioms | P0 | syntax,compiler,tools | not-qualified | M | §7A; scoped development inspection; source spans |

### W3 — advanced typing and Standard environment (20 entries)

| ID | v7 feature requirement | Class | Owner | Current evidence | Cost | Source/acceptance |
|---|---|---|---|---|:---:|---|
| SRC-03 | namespace, open, section, end, variable/include/omit | P0 | syntax,environment,elab | not-qualified | L | §1; scope/generalization and module regression |
| SRC-04 | private and public names, module projection and import reducibility | P0 | syntax,environment,compiler | not-qualified | M | §1,§2; public-by-default with faithful Lean name resolution |
| DEC-06 | abbrev, opaque, example and selected noncomputable proof-only declarations | P0 | syntax,elab,environment | not-qualified | L | §2,§5,§8; typed visibility; reject executable noncomputable closure |
| DEC-07 | selected attributes, modifiers and private declaration order | P0 | syntax,environment | not-qualified | M | §2,§6; one supported modifier order and register allowed values |
| TERM-10 | GetElem xs[i], xs[i]?, xs[i]!, xs[i]'h | P0 | syntax,elab,environment,stdlib | not-qualified | L | §3,§8; exact proof/Option/panic classification |
| TERM-11 | Subtype and Fin proof-indexed syntax/value construction | P0 | core,syntax,elab | not-qualified | L | §3,§8; proof carrying values and erasure |
| DAT-06 | exhaustive multi-discriminant match and dependent generalization | P0 | syntax,elab,meta | not-qualified | XL | §4; motive/elimination correspondence to pinned RC4 |
| DAT-07 | indexed/dependent inductive families, Vec and dependent recursors | P0 | syntax,elab,core | partial | XL | §4; indexed family constructors and universe/recursor parity |
| DAT-08 | typeclass class/instance declaration and implicit synthesis | P0 | syntax,elab,environment,meta | not-qualified | XL | §4; priority/order and local/imported instance resolution |
| DAT-09 | instance header priorities/visibility/field method binders | P0 | syntax,environment,elab | not-qualified | L | §4; named/anonymous/prio grammar and tie-breaking |
| DAT-10 | type-directed coercions Coe/CoeFun/CoeSort | P0 | elab,meta,environment | not-qualified | XL | §3,§4; bounded deterministic search and no JS casting |
| DAT-11 | allowlisted trailing deriving Repr/BEq/DecidableEq/Inhabited/Hashable | P0 | syntax,environment,elab | not-qualified | L | §4; handler manifest and ordinary checked generated definitions |
| REC-02 | mutual recursive def/function and structural call graph | P0 | syntax,elab | not-qualified | L | §5; SCC decreasing evidence, no partial fallback |
| ENV-03 | overload/default instance and coercion specificity | P0 | environment,meta | not-qualified | XL | §2,§3,§4; typed elaboration inference matrix |
| STD-03 | fixed UInt8-64/Int8-64/USize/ISize overflow model | P0 | stdlib,backend-ts,compiler-ir | not-qualified | XL | §8; exact fixed-width/numeric overflow behavior |
| STD-04 | Float/Float32 IEEE semantics and scientific literals | P0 | stdlib,backend-ts,compiler-ir | not-qualified | XL | §3,§8; bit-pattern/rounding and special values |
| STD-05 | ByteArray and BitVec n representation and operations | P0 | stdlib,backend-ts,elab | not-qualified | XL | §8; byte/bit width and type-driven operation matching |
| STD-07 | P0 map/filter/fold/push/getD/append/formatting APIs | P0 | stdlib,environment | not-qualified | M | §8A; pinned API manifest and positive compiler snippets |
| PROOF-07 | source attributes simp/instance/default_instance | P0 | syntax,environment | not-qualified | L | §6; freeze attribute handlers and source ordering |
| BACK-01 | TypeScript7 backend semantics, erasure, source-map | P0 | compiler-ir,erasure,backend-ts | evidenced-bounded | XL | §7B,§8; exact source/TS/JS differential, target runtime laws |

### W4 — general do (3 entries)

| ID | v7 feature requirement | Class | Owner | Current evidence | Cost | Source/acceptance |
|---|---|---|---|---|:---:|---|
| DO-02 | do statement if/if let, proof-binder condition and optional else | P0 | syntax,elab | not-qualified | L | §3,§0B; correct doSeq vs term-if selection and branch scoping |
| DO-03 | do mutation let mut, local assignment and early return | P0 | syntax,elab,compiler-ir | not-qualified | L | §7; typed mutable locals, no shared JS aliases |
| DIAG-02 | #reduce and pure-total bounded #eval | P0 | syntax,elab,compiler | not-qualified | M | §7A; evaluation without world/unsafe emission |

### W5 — proof language (8 entries)

| ID | v7 feature requirement | Class | Owner | Current evidence | Cost | Source/acceptance |
|---|---|---|---|---|:---:|---|
| REC-03 | termination_by measure / decreasing_by by { tactics } | P0 | syntax,elab,proof-service | not-qualified | XL | §5; checked well-founded decreasing proof replay |
| DO-04 | for/break/continue selected iterator and termination semantics | P0 | syntax,elab,stdlib | not-qualified | XL | §7; linear effect modeling and typed iterator APIs |
| PROOF-01 | theorem declarations and explicit proof terms | P0 | syntax,elab,core | partial | L | §6; admitted term proofs; no sorry/axiom from source |
| PROOF-02 | by { tactic sequence }, Lean native bullet/case/next/focus | P0 | syntax,proof-service | not-qualified | XL | §6; exact tactic syntax and goal focusing |
| PROOF-03 | have/show/suffices/calc/classical selected proof terms | P0 | syntax,elab,proof-service | not-qualified | L | §6; proof synthesis with checked elaboration |
| PROOF-04 | intro/constructor/apply/exact/rfl/cases/induction/rintro/obtain | P0 | proof-service | not-qualified | XL | §6; actual proof term producer and goals |
| PROOF-05 | rw/simp/simpa/dsimp/unfold/ext/decide/by_cases | P0 | proof-service,environment | not-qualified | XL | §6; pinned theorem/simp registries and replay |
| PROOF-06 | omega/grind/exact? and selected tactic combinators | P0 | proof-service | not-qualified | XL | §6; reuse exact Lean tactic services; proof-term output |

### W6 — verification (7 entries)

| ID | v7 feature requirement | Class | Owner | Current evidence | Cost | Source/acceptance |
|---|---|---|---|---|:---:|---|
| DO-05 | while invariant/decreasing and verified loop obligations | P0 | syntax,verification | not-qualified | XL | §7; loop VC completeness and totality |
| DO-06 | verification-only erased state and proof assert | P0 | syntax,verification,erasure | not-qualified | XL | §7; erasure/noninterference with checked goals |
| VERIFY-01 | given? requires? ensures? ordered contracts | P0 | syntax,verification | not-qualified | XL | §7; checked Std.WP-generated specs, exact RC4 |
| VERIFY-02 | where finally \| spec => ... and vcgen | P0 | syntax,verification,proof-service | not-qualified | XL | §7; complete VC/contract proof closure |
| VERIFY-03 | spec coverage, caller proof obligations and termination closure | P0 | verification,compiler | not-qualified | XL | §7; missing VC blocks certified emission |
| VERIFY-04 | pure/State/Reader/Except WP and effect laws | P0 | verification,stdlib,environment | not-qualified | XL | §7; checked WP laws and effect/erasure closure |
| VERIFY-05 | proof-only assertion, structure proof invariants, Subtype | P0 | verification,elab | not-qualified | XL | §7; explicit proof fields and precise VC phase |

### W7 — staged P1 libraries and extensions (9 entries)

| ID | v7 feature requirement | Class | Owner | Current evidence | Cost | Source/acceptance |
|---|---|---|---|---|:---:|---|
| REC-04 | equation-style definitions (selected P1) | P1 | syntax,elab | planned-staged | XL | §4; pin native equation compiler and source ownership |
| DO-07 | typed throw, try/catch/finally (explicit P1 environment) | P1 | syntax,elab,environment | planned-staged | L | §7B,§0B; precise MonadExcept/MonadFinally handlers |
| PROOF-08 | optional pinned proof/tactic/notation packages | P1 | proof-service,pscv-policy | planned-staged | L | §6; explicit qualified manifest; no proof oracle |
| DIAG-03 | Lean-like goal state and accurate .ps LSP mapping | P1 | tools,pslsp | planned-staged | L | §7A; source-map and proof state/InfoView correctness |
| LIB-01 | Std HashMap/HashSet/TreeMap/TreeSet exact APIs | P1 | stdlib,environment | planned-staged | L | §8,§8A; pin upstream signatures, typed sample apps |
| LIB-02 | JSON AST, validated decoder and codecs | P1 | stdlib,compiler-ir | planned-staged | L | §8A; typed Except decoders, no dynamic any |
| LIB-03 | Vector/Sigma/Range/ForIn library types | P1 | stdlib,environment | planned-staged | M | §8; curated exact imports and typed instantiations |
| LIB-04 | IO filesystem/network/clock/FFI typed boundary | P1 | stdlib,host | planned-staged | XL | §7B,§8A; explicit external models and audited signatures |
| LIB-06 | TS/npm/JS typed adapters and project libraries | P1 | host,compiler-ir,backend-ts | partial | L | §8A; signature checks and runtime validation for external values |

### W8 — deferred and alternative targets (4 entries)

| ID | v7 feature requirement | Class | Owner | Current evidence | Cost | Source/acceptance |
|---|---|---|---|---|:---:|---|
| LIB-05 | tasks async cancellation without JS keywords | P1 | stdlib,host | planned-staged | L | §8A; typed task/effect semantics, not Promise mimicry |
| BACK-02 | optional JS/Wasm/Rust backend extensions | P1 | backend-js,backend-wasm,backend-rust | not-qualified | XL | §7B,§8A; shared verified IR semantics; separate backend gates |
| DEFER-01 | old/reads/modifies/errors and custom refinement keywords | DEFERRED | syntax,verification | deferred | L | §7; use predicates/WP models, not new syntax |
| DEFER-02 | Rust native ownership/FFI grammar ps-rust-native/0 | DEFERRED | backend-rust,host | deferred | XL | separate proposal; not part of sole v7 base; explicit future edition |

## Evidence and interpretation

This inventory was authored after directly reading all v7 chapters and the selected PSC0 syntax/ELAB implementation files. It is a first-pass human classification and must be updated by per-feature CI evidence; exact lexical/semantic support of unqualified features is not presumed. The full v7 Standard environment manifest and RC4 semantic acceptance remain open; P1 features are not automatically part of default Standard. Do not count negative-source exclusions as missing positive features.
