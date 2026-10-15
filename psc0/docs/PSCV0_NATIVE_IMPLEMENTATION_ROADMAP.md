# PSCV0 v7 native implementation roadmap

## Literal/operator metadata independently measured — 15 October 2026

Native run [38754937813](https://github.com/dwijayuda/pskernel/actions/runs/38754937813) at `a829bb49b26ec133c00113674c4d5a40599202e1` compiled all native targets, including the corrected raw-numeral projection oracle, and passed the pinned native signature/reducibility audit. Both strict qualification boundaries independently reported FNV `4909868320704722088`, declaration SHA-256 `990f59c079198da859bbe7b98e11dc96ca6668851825f48df5fadeb24524148f`, and surface SHA-256 `e188d6f21d7ac7604ebbd41d34f48b626b1385789da98c0f288bbc1162fe2098`. These reviewed metadata values are now pinned; declarations and counts are unchanged. Independent F1 38754937765, F2 38754937822 and F3 logical 38754937715 replays passed at the same commit.

The reducer now checks unfoldability and class-projection eligibility before instantiating declaration universes, preserving the cheap ordinary opaque-constant path. Semantics, fuel, foundation and acceptance gates are unchanged. Full source/backend qualification of the literal/operator slice is still pending; previous failures are retained as diagnostic history. Main development remains qualified at the default-instance milestone (858 observations). Scientific literal frontend work is staged separately and F3 runtime conversion/scientific execution remains unselected.
## Native projection oracle resolved; instance metadata aligned — 15 October 2026

The diagnostic from native38754279462 confirmed the native result was raw `857`; the oracle itself had accidentally built its expected value with `Lean.mkNatLit`, which constructs overloaded `OfNat` syntax. It now uses `Lean.mkRawNatLit`, exactly as pinned `BuiltinTerm.elabNumLit` does. Assertions are unchanged. Portable source literals already use raw Core parameters.

The whole affected instance family was reviewed: newly constructed Standard dictionaries registered after the early prelude had no explicit reducibility status, preventing their class projections from reducing at instance transparency. The shared Standard instance factory now applies the native instance-command default `instanceReducible` only when no status was supplied; explicitly imported or overridden statuses are preserved. Environment metadata now exposes an optional lookup so absence is distinct from an explicit semireducible choice. This applies to the family once rather than patching numerical operations separately. Existing exact native status audit and strict selected snapshot will independently check and measure the delta; pins intentionally remain at the previous reviewed values until that measurement. No Core declaration bodies, assumptions, source expectations or budgets are weakened. Qualification pending.

## Shared class-projection reduction prerequisite — 15 October 2026

Native38751673594 reached the older `Numeric.generic` regression and exposed a general reduction gap: instance transparency could not reduce a checked class field such as `OfNat.ofNat Nat 857 instOfNatNat` inside a dependent instance index. Restoring raw Nat literal shortcuts would hide the defect and break local dictionaries. Pinned Lean `src/Lean/Meta/WHNF.lean` (`isProjInst`, `unfoldProjInst?`, `unfoldProjInstWhenInstances?`, `unfoldDefault`) provides the correct rule; `GetUnfoldableConst.lean`, `tests/elab/instanceReducibility.lean` and `tests/elab/isDefEqProjInstWithMVar.lean` were studied.

Portable WHNF now recognizes checked generated class fields through their class constructor telescope, delta-beta reduces only that field, and reduces its actual dictionary at instance transparency. Stuck class projections retain their original application; irreducible fields/dictionaries stay blocked. Ordinary definitions do not gain extra transparency. A small independent native WHNF oracle and the existing transparency suite validate reducible/instances/implicit behavior, custom evidence, stuck evidence and irreducibility; the full existing generic-numeral/backend suite remains mandatory. No Standard declaration, pin, assumption or resource budget changed. Qualification remains pending. Scientific syntax work is prepared in memory only and has not been published or selected.


## Literal/operator metadata review — 15 October 2026

At `195a077f9f4747ce1731a382ba471b40974ab43e`, [native38748876958](https://github.com/dwijayuda/pskernel/actions/runs/38748876958) built the compiler and independent Lean literal/operator oracles, passed the strengthened native signature/reducibility audit, and regenerated the prior checked assets. Both strict boundaries independently refused the intentional selected registry expansion and reported the same values: FNV `2999019441064509306`, declaration SHA-256 `6d8074129e70b3bd01c9d18ab92701edadf5932061e13988a491fa00c0efef10`, surface SHA-256 `0386344f5ade3df16048d155d650a7f1a197117c72971fb55002de9172a88069`. Those reviewed values are now pinned. No check, assumption or budget is relaxed.

The source closure now explicitly registers the new portable Lake root; its explicit imports and record-update layout are complete. The architecture and 14 paired observations are unchanged. Full source/backend qualification remains pending; passing the native oracles and asset gates alone does not qualify the slice. Exact-development default-instance qualification remains complete at `5e07de1006ab3539888f68015b3470bdfd921cf8` (native38745398231, 858 observations, F1/F2/F3 replay green). F3 scientific/conversion runtime selection remains pending.

## Literal constraints and homogeneous operators prepared — 15 October 2026

This F3 prerequisite now reuses the six native checked homogeneous classes and H* bridges already present in the selected logical assets. The selected final instance catalogue replaces redundant ground H* search entries with homogeneous ground dictionaries built from the same checked operation values. No class or bridge body is copied or replaced. Six native bridges are ordinary/default instances at priority 1000; OfNat Nat defaults at 100 and Neg Int at 500. Earlier logical asset boundaries remain immutable, and the final runtime catalogue emits the selected dictionaries and native bridges.

Numerals now follow pinned Lean `Lean/Elab/BuiltinTerm.elabNumLit`: a fresh Type-valued target, expected-type constraint, raw Nat parameter and shared synthetic OfNat goal. Applications and literals share one constraint-completion operation. The special source-level Nat fallback and its unused defaulting flag are removed. This preserves local OfNat dictionaries, enables adjacent-operand inference and allows generic Add/Sub/Mul/Div/Mod/Append code.

Primary references: pinned `Init/Prelude.lean`, `Init/Data/Int/Basic.lean`, `Lean/Elab/BuiltinTerm.lean`; tests `elab/{hmulDefaultInstance,dotNotationAndDefaultInstance,ofNat_class}.lean` and the previously qualified default-instance tests. The native signature audit now checks all 24 selected class/constructor/projection/bridge identities. The registry audit checks the replacement rules and exact default priorities.

One paired native/source fixture adds 14 shared observations (intended total **872**): all six bridges, custom numeric operands on either side, local OfNat Nat override, Nat/negative defaulting, a higher universe, executable Float generic addition and heterogeneous multiplication. Existing refusal checks and full backend/integration/performance gates remain mandatory. Strict registry/surface pins intentionally retain the previous qualified values until independent cloud measurement is reviewed. **This slice is prepared, not qualified.**

Default-instance integration is at `5e07de1006ab3539888f68015b3470bdfd921cf8`; [native38745398231](https://github.com/dwijayuda/pskernel/actions/runs/38745398231) is the exact-development gate. Independent F1 38745397954, F2 38745398267 and F3 logical 38745398095 are green. Record native completion before claiming the integration fully qualified.

F1/F2 and the Array prerequisite are already qualified. F3 scientific syntax and executable conversion IR remain pending; its 134-declaration logical candidate is still unselected. Next: finish this literal-family qualification, then exact scientific syntax/OfScientific and cross-target conversions, F4 display and remaining M2+A exits. No new assumptions, budgets, pskernel-core, self-hosting or C5.

## Shared default instances: research qualified, integration checkpoint — 15 October 2026

Research commit `144da8fb916c63eb7057e6f2d5b6b43d465d9d87` passed [native38743248005](https://github.com/dwijayuda/pskernel/actions/runs/38743248005): **858 shared runtime observations** on TypeScript, direct JavaScript and Rust, GC Wasm/core/component execution, repeated Wasmtime calls, source/kernel/IR checks, module integration, exact assets and unchanged performance gates. Independent [F1 replay38743110807](https://github.com/dwijayuda/pskernel/actions/runs/38743110807), [F2 replay38743111243](https://github.com/dwijayuda/pskernel/actions/runs/38743111243) and [F3 logical replay38743111380](https://github.com/dwijayuda/pskernel/actions/runs/38743111380) passed at parent `9823ce526bad037e1de7da40c2485e91e7a9825b`; the sole descendant changes two fixture declarations to normative `where` syntax. Exact-development integration qualification is pending.

Implemented together: separate ordered ordinary/default registries; `@[default_instance priority]`; checked class-result registration; scoped, transactional dependency solving; ordinary quiescence before one default commitment; universe instantiation; public/private imports, newest-first ties and diamond deduplication. Search exhaustion rolls back rather than choosing a lower-priority fallback. Lean distinguishes success, definite failure and stuck synthesis: top-level defaults apply only to stuck goals with compatible ordinary candidates. Nested default dependencies follow Lean's reverse-telescope, goal-first policy. Native differential oracles and compact negative/budget/module checks enforce these boundaries.

Primary reference: pinned Lean 4.35.0 `Lean/Meta/{Instances,SynthInstance}.lean`, `Lean/Elab/SyntheticMVars.lean`, `Lean/Elab/Term/TermElabM.lean`; tests `elab/{defaultInstanceWithPrio,defaultInstBacktrackIssue}.lean`, `elab_fail/defaultInstance.lean`. Adaptation attribution is recorded in Synthetic.lean. PSC0 retains its immutable portable contexts and bounded tabled search.

Reviewed selected pins: FNV `7059557959118648847`; declaration SHA-256 `2b0475103206285b3107cd646ea04a365bf682aef2c4c0c8bf16d21e67c65995`; surface SHA-256 `babd8330a9143aad468400ffdf5ae27fe8b5b389e0dbe087ad83cbb4056f1388`. Snapshot v3 / surface v2 explicitly record the default registry and attribute. Roster remains **3,122 declarations /25 classes /250 ordinary instances /zero Standard defaults**. The strict pins were independently measured at both existing boundaries, not relaxed.

Array prerequisite is already exact-development qualified at `e3902f3d91556af40b85f65566ff6787620346ee` ([native38739411239](https://github.com/dwijayuda/pskernel/actions/runs/38739411239), 851 observations, F1/F2/F3 replays green). F1 and F2 executable families are complete. F3's 134-declaration logical candidate remains **unselected**; scientific syntax, literal constraints, numeric conversions, F4 display, target-sized profiles and remaining M2+A exits remain open.

Next coherent F3 work: replace eager Nat fallback with shared OfNat constraints; implement pinned homogeneous operator/default bridges (Add/Sub/Mul/Div/Mod/Append -> heterogeneous operations) so surrounding operands constrain literals; retain exact scientific mantissa/exponent until OfScientific is chosen. Inspect existing logical declarations before adding any class. Then implement shared typed conversion IR across all backends, with direct target-width rounding. Do not implement Float32 by a potentially double-rounded binary64 intermediate. No new assumptions, budgets, pskernel-core, self-hosting or C5.

## Historical checkpoints (superseded where the current checkpoint differs)

## Polymorphic Array prerequisite: research qualified, main integration — 15 October 2026

[Native38737651266](https://github.com/dwijayuda/pskernel/actions/runs/38737651266) passed all 30 steps at `3642e8835f36f238c88e4097914df55b199fd58e`: **851 shared runtime observations**, checked source, exact assets, readable JS/TS/Rust, GC Wasm/component and repeated Wasmtime calls, module integration and unchanged performance gates. Independent [F1 replay38736528638](https://github.com/dwijayuda/pskernel/actions/runs/38736528638), [F2 replay38736528346](https://github.com/dwijayuda/pskernel/actions/runs/38736528346), and [F3 logical replay38736528477](https://github.com/dwijayuda/pskernel/actions/runs/38736528477) passed at parent `80205a9bd25bdaa5eb6c08c75cdf7b34eba2000a`; the sole descendant change parenthesizes a type-ascribed fixture argument. No expected result was relaxed.

Pinned Lean 4.35.0 `Init/Prelude.lean`, `Init/Data/Array/{Basic,BasicAux}.lean`, and tests `compile/{array,arrayMk}.lean`, `elab/{arrayGetU,array_map_module}.lean` govern this repair. Array, mk/toList, recursor, selected operations and dictionaries now carry element universe u; map/fold result and recursor motive universes are independent. ByteArray explicitly specializes to zero. Existing list-backed logical semantics and runtime layouts are preserved. Seven obsolete Type-0 audit exceptions are replaced by exact normalized signature checks. Eight observations cover both map/fold directions, default, Repr, ToFormat and Hashable; generic list/size identities are kernel checked.

Strict reviewed pins: FNV `14544844717468498892`; declaration SHA-256 `373b27a0b77083baa58810055d68b6639ec00c2038da7641d3dd5c042e8f4e0d`; surface SHA-256 `579f461576427a5daf711943613979e4517803475779e40b0200f359450744fa`. Registry counts and approved assumptions are unchanged from F2. Independent native prelude measurement was 6.524s; this is an observation, not a performance-equivalence claim.

This fixes the general native dependency mismatch that prevented F3's scientific fast-path tables and proofs from replaying. The **unselected** F3 logical candidate now passes: 42 roots /134 declarations /one recursor /3,286 shared nodes /617,019 UTF-8 bytes, SHA-256 `45e6c8b81fbd971c891d173acef36c2ce6f6c59b674a06ffc9bfbe2e8cff6391`. No new axioms, quotient primitives or replaced definitions.

**Exact-main Array qualification is pending on this integration commit.** F2 remains main-qualified at `ef5c5e342015bfabcb58ae1f3291f0fe544cec5a`. Next coherent slice is scoped, transactional, priority-ordered default instances, followed by exact scientific syntax and typed scalar conversions. It is prepared on the F3 research branch; no claim of F3 or M2+A completion. Both handoffs track the live frontier.


## F2 executable MAIN QUALIFIED — 15 October 2026

**Qualified development commit:** `ef5c5e342015bfabcb58ae1f3291f0fe544cec5a`.
[Native/backend38736277605](https://github.com/dwijayuda/pskernel/actions/runs/38736277605),
[independent F1 replay38736277937](https://github.com/dwijayuda/pskernel/actions/runs/38736277937), and
[independent F2 replay38736278026](https://github.com/dwijayuda/pskernel/actions/runs/38736278026) all pass at this exact SHA. All 30 native job steps succeeded, including 843 shared runtime observations, checked source and Standard, exact proof assets, readable target artifacts, GC core/component ABI execution, repeated Wasmtime calls, module integration and existing performance gates. The approved assumption boundary and resource limits are unchanged.

F2 scope and hashes are those recorded below. This closes executable Float arithmetic/comparison/classification F2 after the already qualified F1 bit/model transport. It does **not** close F3 scientific literals/numeric conversions, F4 display, platform-word profiles, remaining M2+A, C5 or whole-backend correctness proofs.

Active prerequisite work is on `psc0/pscv0-v7-f3-conversions-research`: polymorphic Array has passed signature audit, existing asset regeneration and independent F1/F2/F3 logical replay. Its full runtime qualification continues after fixing the new fixture's required parentheses around an ascribed argument. The F3 candidate remains unselected. Shared default-instance support is being designed/implemented against pinned Lean `Meta/Instances`, `Elab/SyntheticMVars` and the default-instance priority/backtracking tests. Finish the Array milestone before integrating that next coherent change. Keep both handoffs updated; native Lean/cloud CI only, no pskernel-core or self-hosting.


## F2 executable family: research qualified, main integration — 15 October 2026

[Native38734252078](https://github.com/dwijayuda/pskernel/actions/runs/38734252078) passed completely at `9ffdd799a05ee256368266831bbaec74bee18ed2`: **843 shared runtime observations** across readable JS/TS/Rust and GC Wasm/core/component, native oracles, official-kernel source admission, exact asset regeneration, ABI/WIT/WAT checks, multi-module programs, repeated Wasmtime calls and unchanged performance gates. Independent [F1 replay38733051176](https://github.com/dwijayuda/pskernel/actions/runs/38733051176) and [F2 replay38733051136](https://github.com/dwijayuda/pskernel/actions/runs/38733051136) pass at `c3081a0e0c102ba8f8fad16940301af893dcfe5b`; the descendant only corrects six constant observations to the established `args: null` schema and updates handoffs. No expected values changed.

This integration selects Float/Float32 add/sub/mul/div, neg/abs, IEEE equality/order, NaN/infinity classification and checked logical equality decisions, including generic, partial and Model calls. The original Lean logical family contains 1,229 declarations /24 recursor rules /91,024 shared nodes /11,179,796 UTF-8 bytes, SHA-256 `ad82f59b48460a3b306312c3e9d72537e8b48201e432271a3be0424a576909df`. Only approved propext/Quot.sound are assumed; no new axioms or proof replacements. Proof dependencies stay out of runtime support.

The typed IR adds float unary/test operations; ECMA enforces binary32 rounding per operation, Rust uses safe scalar operations, and Wasm uses native arithmetic plus memory-free classification helpers. Canonical NaN observation and signed-zero behavior follow F1. The shared constant/application erasure path now handles nullary primitives and preserves partial application. Its design follows pinned Lean `Lean/Compiler/LCNF/ToLCNF.lean` (visitCore/visitAppCore/etaIfUnderApplied). The instance registry now validates each key against the reduced result class, following `Lean/Meta/Instances.lean`; DecidableEq registers under Decidable.

Reviewed selected Standard: **3,122 declarations /25 classes /250 instances**; FNV `11971833863653521941`, declaration SHA-256 `8a3fbf1e59845739e6926b7e52add0059a33054cf74625f64923d4f360c43c7e`, surface SHA-256 `ff2b3e2ed6e043cb11a332d5175ff1116f8e4c1a4c13a91baca71bb53a917fc3`. All guards remain strict. Native prelude initialization measured 7.608s separately; performance gates passing does not establish optimal performance or a backend preservation theorem.

**Exact-main qualification subsequently passed; see the current receipt above.** F1 remains previously main-qualified at `262c5819c499256fcd2093746deae4ef3aa2012b`. Do not call all M2+A complete. Next: finish exact-main F2 checks; qualify/integrate the universe-polymorphic Array prerequisite from `psc0/pscv0-v7-f3-conversions-research`; then scientific literals, shared priority-ordered default instances and numeric conversions (F3), display (F4), and remaining M2+A exits. The F3 logical candidate already passes [38734094036](https://github.com/dwijayuda/pskernel/actions/runs/38734094036) but remains unselected. No pskernel-core, self-hosting, compiler-source translation or C5 work.


## F1 executable MAIN QUALIFIED — 15 October 2026

**Main implementation qualified:** `262c5819c499256fcd2093746deae4ef3aa2012b`.
[Full native/backend run 38721711653](https://github.com/dwijayuda/pskernel/actions/runs/38721711653) and
[independent Float proof replay 38721711679](https://github.com/dwijayuda/pskernel/actions/runs/38721711679) both passed at that exact SHA; all 29 native steps passed. Research `bcd102cdac80b19367b461c204d6663e8526e2f7` passed native38720893666 and Float38720893532 before integration. This receipt changes documentation only.

F1 implements checked `UInt64 ↔ Float` / `UInt32 ↔ Float32` bit transport, model construction/projection/elimination and partial applications. Logical Model records retain real validity proofs in checked Core and ordinary record layout after proof erasure. JS and TS share readable DataView helpers; Rust uses safe f32/f64 bit APIs; Wasm uses native scalars and GC boxes only at generic crossings. Every NaN denotes the unique logical NaN; bit/model/explicit ABI observations canonicalize it. Other patterns, including signed zero, are preserved.

The one Canonical ABI plan now supports f32/f64 scalar, aggregate, list, generic-record and indirect signatures. Variant joins restore payloads by reinterpretation/wrapping. Typed post-return metadata drives runtime definitions, binary alias indices and readable WAT together; linear memory remains ABI-only. The primitive audit explicitly records Float bit/model runtime overrides. No proof closure was added to runtime support.

Qualification passed **755 shared observations** (56 new F1 cases) on JS/TS/Rust and GC Wasm/core/component paths, native Lean bit-corpus checks, wrong source/IR width refusals, full WIT extraction and binary/WAT agreement, mixed float/integer ABI variants, indirect parameters, signed-zero/NaN memory observations, repeated Wasmtime calls, exact proof-asset regeneration and existing performance gates. This is scoped conformance evidence, not a backend preservation theorem or full M2+A completion.

Selected Standard and its exact hashes are unchanged: **1,879 declarations /25 classes /226 instances**; FNV `fnv1a64:9256054256618924345`; declaration SHA `0f62a5df0a7273a183e10700bf8eb49563afd0ff8d03b7be3935d4d310a12f04`; surface SHA `240050e325b7c7d06827c36bffe7ed017ef18680b61ccf4fa7701807a62874b4`. Foundation remains exactly approved propext/Quot.sound.

**Next: remaining M2+A in the existing order.** F2 arithmetic/equality/classification needs checked native logical dependencies before enabling its still-refused IR operations; F3 scientific/conversions, F4 complete Float qualification, explicit target-word profile propagation and authoritative Standard/manifest exits remain open. Pinned Lean 4.35.0 Float/Model/Unpacked Operations Add/Mul/Div/Compare and Round plus tests/elab/floatModelDefeq.lean were studied: reuse unpack/operate/round/pack; ties-to-even residual bits and IEEE versus propositional equality are semantic requirements. Do not substitute bit-helper observations for checked floating definitions. Keep M2+A → M3+B → M4+C/D → M5/E.

Native .lean only; no pskernel-core, self-hosting/bootstrap or C5. PR109 stays draft on its original base. Update BOTH handoff files each slice, preserve expected-HEAD history, and report exact completed/pending evidence.


## Previous qualified checkpoint — 15 October 2026

**Qualified implementation: `38dbbfb9826490d02a44e6ab5b518a9946849345`.** [Native compiler/backend CI 38715710210](https://github.com/dwijayuda/pskernel/actions/runs/38715710210) and [independent portable Float replay 38715710273](https://github.com/dwijayuda/pskernel/actions/runs/38715710273) both passed at this exact commit. The subsequent handoff update changes documentation only.

Completed this continuation:
- **Checked Int arithmetic:** 28 native declarations/laws replace exactly four historical computational axioms; existing runtime intrinsics remain independently audited. Main `e322eff798a96db14b5deed24824ccf3c2fcc783` passed native38706796031 and Float38706795768.
- **Complete universe-polymorphic List indexing and actual kernel-counter isolation:** main `e5d1bdd6d667057bfd5376e8b39f3069f1dfc93c` passed native38711192827 and Float38711192777. One shared awaited pooled-task mechanism owns independent admission; source requests keep the cumulative 2,000,000-heartbeat /20,000-depth budget. IO allocation telemetry is a separate counter.
- **Logical Float constructors:** only 21 checked validity/constructor declarations plus Float.ofBits/Float32.ofBits typed wrappers are selected. The 307,290-byte source asset regenerates exactly (SHA-256 `3042b3db951a1c68f8df24c5161889841082f9f4ee03783e1e5b4da918b3f9a7`). Checked source accepts both widths and bit projections; wrong-width arguments and unsupported executable Float are refused.
- **Independent proof closure:** 30 roots /922 declarations /11 recursor rules, including the four mask-equivalence bridges, replay successfully with only propext/Quot.sound. The 11,097,675-byte audit asset (SHA-256 `564b48590fde9074679ec5e8d72f746fda4069f382b7cbcdd6101ba0c7bda622`) stays outside selected Standard.

The native workflow passed all 29 steps, including **699 existing observations each for JS, TypeScript and Rust**, GC Wasm/core and component validation, repeated native Wasmtime calls, asset byte comparison, source refusals and performance checks. These observations are scoped evidence, not backend metatheory or full v7 conformance.

Selected Standard: **1,879 declarations /25 classes /226 instances**. FNV `fnv1a64:9256054256618924345`; declaration SHA-256 `0f62a5df0a7273a183e10700bf8eb49563afd0ff8d03b7be3935d4d310a12f04`; surface SHA-256 `240050e325b7c7d06827c36bffe7ed017ef18680b61ccf4fa7701807a62874b4`.

**M2 + Phase A is NOT complete.** Next required work is F1 executable model erasure, typed IR, GC boxing, all backends and explicit ABI, followed by F2 arithmetic/equality, F3 scientific/conversions, F4 qualification, target-sized words and remaining authoritative language/Standard exits. The existing scalar-completion design records the studied Lean runtime representation and Canonical ABI dependencies. C5, self-hosting/bootstrap, compiler-source .ps translation and pskernel-core remain excluded.

No new trusted assumptions or proof placeholders. Native upstream Float correspondence still transitively imports Classical.choice and remains unselected. PR109 stays draft on its original base. Read live HEAD before further writes.

## 15 October — minimal logical Float constructors integrated; main qualification pending

Research `41a4474b7cbbb04c9e83b4a7fae111631be58e7a` passed both [full native integration 38715004637](https://github.com/dwijayuda/pskernel/actions/runs/38715004637) and [independent full proof replay 38715004629](https://github.com/dwijayuda/pskernel/actions/runs/38715004629). All 29 native steps passed, including exact asset regeneration, source/type/runtime boundaries, 699 observations each on JS/TS/Rust, GC Wasm/component validation, repeated Wasmtime calls and performance checks. This main integration still requires the same exact-commit pair before main qualification is claimed.

The selected constructor layer adds **21 checked declarations plus two public typed wrappers**, retaining actual Format.Valid evidence. Asset: **307,290 UTF-8 bytes /1,702 shared nodes**, SHA-256 `3042b3db951a1c68f8df24c5161889841082f9f4ee03783e1e5b4da918b3f9a7`. Regeneration uses its frozen pre-constructor declaration boundary and mandatory byte comparison. The independent **30-root /922-declaration /11 MB** representation audit remains separate from selected Standard. No new assumptions, axioms or runtime overrides.

Standard now has **1,879 declarations /25 classes /226 instances**. Strict independently measured pins: `fnv1a64:9256054256618924345`; declaration `sha256:0f62a5df0a7273a183e10700bf8eb49563afd0ff8d03b7be3935d4d310a12f04`; surface `sha256:240050e325b7c7d06827c36bffe7ed017ef18680b61ccf4fa7701807a62874b4`. Logical Float.ofBits/Float32.ofBits and toBits source admission is checked, a wrong-width argument is refused, and executable Float remains refused at the shared IR gate.

The full audit's pre-constructor boundary prevents selected roots from cutting their own replay. Host authoring uses the local Ps namespace first: Lean/Util/Path.lean resolves the first root directory, so plain lake env alone is insufficient when both parent and native packages use Ps. This ordering matches the independently qualified proof workflow.

M2+A remains incomplete. Next: coherent F1 model erasure, typed IR, all backends and explicit ABI; then F2-F4, target-sized words and remaining selected language/Standard obligations. Continue M2+A -> M3+B -> M4+C/D. No pskernel-core, self-hosting, C5 or trust expansion.

## 15 October — complete List indexing and actual kernel-scope integration

Research `556904b96a9d70306a92278cebaaa358095c3749` passed [full native CI 38710034211](https://github.com/dwijayuda/pskernel/actions/runs/38710034211) and [expanded portable Float replay 38710034341](https://github.com/dwijayuda/pskernel/actions/runs/38710034341). All 28 native steps passed: higher-universe List indexing/lawful inference, the actual kernel-counter boundary, exact existing asset regeneration, 699 observations each on JS/TS/Rust, GC Wasm/components and repeated Wasmtime calls.

Integrated changes:
- All selected List index workers/public/internal bang aliases, positive/negative proofs, GetElem/GetElem?/LawfulGetElem dictionaries and instance registrations consistently carry universe u. No extra length pass or algorithm change.
- One awaited pooled native IO task owns each independent authoring admission. Source requests use the same helper and retain their existing cumulative 2,000,000-heartbeat /20,000-depth budget. No dedicated OS thread per declaration, unchecked admission, retry or limit increase.
- Lean has separate allocation and C++ kernel counters. IO.setNumHeartbeats only changes the former; runtime/object.cpp:run_task resets the latter. NativeV7's redundant dedicated-thread wrapper is removed; allocation telemetry is no longer mislabeled as kernel heartbeats.
- The four compact Float mask-equivalence bridges join the authoritative contractRoots roster used by native assumption auditing and portable replay. Duplicate mask audit lists are removed. Native upstream pack/unpack correspondence remains separately labelled and unselected.

Selected Standard remains **1,856 declarations /25 classes /226 instances**. Independently measured strict pins: `fnv1a64:14729641192328177589`, declaration `sha256:8b956d8f7b7f5bbebaf6480454e528380cd53f513772460a5a8f60648ad8bc2b`, surface `sha256:58d4afa2cb069f078ab68f358b4e1718edd10cbc9f316f90357faeca381cb77d`.

The expanded candidate checked **30 roots /922 declarations /11 recursor rules**, with only propext/Quot.sound, no new axioms or replaced-definition axioms. Research artifact: **11,097,675 bytes /83,125 shared nodes**, SHA-256 `564b48590fde9074679ec5e8d72f746fda4069f382b7cbcdd6101ba0c7bda622`. This candidate is **not** added wholesale to selected Standard or executable Float. Assess its proof dependency cost and integrate the minimal coherent F1 source/IR representation boundary next.

**This main integration still requires exact-commit native/backend and expanded Float CI.** The qualified research result is not substituted for that check. M2+A/F1-F4 remain incomplete. No pskernel-core, self-hosting, C5 or trust expansion.

Primary pinned Lean references studied: Init/GetElem.lean, Init/Data/List/Basic.lean; runtime/alloc.cpp, runtime/io.cpp, runtime/interrupt.cpp, runtime/object.cpp; Lean/AddDecl.lean and Compiler/LCNF/EmitC.lean. Relevant tests: elab/getElemV.lean, elab_fail/getElem.lean, elab/kernel_maxheartbeats.lean, elab/taskState.lean. task_test_io.lean exits early upstream and is not qualification evidence. The allocation-only first probe was insufficient; the final probe consumes actual C++ kernel work, observes unscoped timeout, checks fresh scoped acceptance and invalid-type rejection.

## 15 October — target-word semantic ownership and fast-gate policy

**Last qualified executable:** `f5f9c7f87b77d9700bc52ca02882ae1f1dbab73e`,
[27-gate Linux CI 38654008436](https://github.com/dwijayuda/pskernel/actions/runs/38654008436);
[canonical Float kernel replay 38654008396](https://github.com/dwijayuda/pskernel/actions/runs/38654008396) also passed.

**New candidate:** `Ps.CompilerIr.Model` owns the *only* typed-IR
USize/ISize width selector (`bits32`/`bits64`) and exact canonical signed/
unsigned literal range. `CheckTypes` delegates fixed-width validation to
the same policy while still refusing unprofiled target-sized IR. The JS
profile-specific literal path reuses the shared selector rather than
duplicating 32/64-bit numeric limits. A short native boundary suite checks
signed minima/maxima, unsigned limits, fixed width and absent-profile
rejection against pinned `Init/System/Platform.lean` and `Init/Data/SInt/Basic.lean`.
No platform word capability is newly admitted and no backend semantic
promise is inferred. The original upstream F1 import's **known negative**
research-only workflow remains dispatchable by hand but no longer runs and
fails on each ordinary source change; the successful small canonical-model
replay and main CI are unchanged.

**Remaining:** carry this explicit target profile through compiler IR
admission and each JS/TS/Rust/Wasm execution/ABI lane; implement Float F1-F4,
scientific, the remaining selected P0 APIs and complete assurance/manifest.
Do not claim M2+A finished. No pskernel-core, self-hosting or C5.

## 15 October — surface digest frozen and per-project source graph candidate

The selected source-surface SHA-256 from complete CI 38653018583
(commit 078ec135da8b205400ba14a8ac3d68ac3fd23f71) is now frozen
to sha256:0bc4bfaa0f9afb9e0c1c58d652c51db8732530cd1b50b9e8772cca90f5bac0cf.
That independent strict gate complements both existing FNV/SHA checks
over the underlying selected Standard Core/instances/aliases.

New candidate: the native --audit-project-graph command consumes the
same path-safe source manifest and source-owned imports as the real project
compiler, refuses duplicate/missing/cyclic dependencies, resolves a
deterministic topological order and entry reachability, and hashes
actual source bytes, imported module identities, source paths, and the
selected global Standard-surface SHA into one project source-graph SHA-256.
The three-module CI fixture now emits project-source-graph.json.
This is a source-graph identity receipt, not a kernel proof, published
ABI-equivalence claim, or full transitive Lean import manifest.
Full M2+A remains incomplete; no pskernel-core, self-hosting, C5.

## 15 October — canonical Float model replay qualified; full selected-surface digest candidate

The native Float canonical proof model produced 24 officially checked
portable declarations and **no new axioms** at
[research CI 38652410627](https://github.com/dwijayuda/pskernel/actions/runs/38652410627),
commit `42eb74a26121be7f355ca273a959d475c166a3a1`.
This does not enable runtime Float or resolve the original full F1
List/Int incompatibility. The normal 27-gate executable CI runs separately.

**New native Phase A manifest candidate:** record a canonical length-delimited
digest over the selected operator/notation table, the actual deriving
handler roster, selected tactics, source/elaboration effect policies,
module policies, and ordered checked instances with class/priority/universes.
The human-readable JSON reports the new surface SHA-256 and underlying strict
Standard SHA-256 independently. `--audit-standard-surface` and native CI
publish this artifact; its deriving registry is checked against the *actual*
elaborator-owned handler list. This is still a **selected** manifest, not
a claim of complete transitive Lean module imports, all available effects,
or a full compiled-language semantics proof. The per-project import graph
remains validated separately. No trust/instance/class extension and no
pskernel-core, self-hosting or C5.

## 15 October — reusable constructive Float proof-model candidate

The last green executable checkpoint is `1fd22ead9f5c32e57e189251be94db7c1245a542`,
[27-step CI 38648695550](https://github.com/dwijayuda/pskernel/actions/runs/38648695550).
A native all-bitpattern `Format.Valid` theorem and real Float32/Float64
constructors passed kernel, axiom and existing runtime regression gates.

**New unqualified authoring batch:** move this proof and constructors from
the native oracle into `Ps.Host.FloatCanonical`; add universal
`canonicalPacked_of_valid` and `canonicalPacked_idempotent` theorems.
An isolated research workflow attempts portable-kernel replay of this
small proof-bearing model against the unmodified frozen Standard, instead
of importing the 1,038-declaration original Float.ofBits dependency graph
that was correctly refused for List/Int model mismatches. Never weaken
the strict assumption allowlist or publisher. Source-level Float
construction, F2 arithmetic, F3 scientific syntax, F4 ABI/runtime and
full Phase A/M2+A remain unqualified. No pskernel-core/self-hosting/C5.

## 15 October — F2 bit equalities green; constructive Format.Valid candidate

The checked Float32/Float64 *bit-level* two-equality models passed all
[27 Linux CI 38647823991](https://github.com/dwijayuda/pskernel/actions/runs/38647823991)
steps at `ecdff92f3b59981f78aaadbf2c6022178d8ce8d3`.
IEEE Bool equality (NaN unequal, signed zeros equal) is kept distinct
from canonical logical bit identity (all NaN payloads normalized,
signed zeros distinct). Sixteen native-reference/cross-target observations
passed, without declaring source Float instances or additional axioms.

**Research-only next candidate:** direct constructive Lean 4.35.0 proof
for `Format.Valid spec (canonicalPacked spec bits)` for *all*
bitvectors in any permitted Float.Model.Format. The definition branches
on the original pinned `unpackExponent`/`unpackMantissa`, preserving
non-NaN bits and mapping NaNs to `packedNaN spec`. This avoids the
previous 1,038-declaration original Float.ofBits import and its
independently refused List/Int proof-model mismatch. The native oracle
also constructs actual Float and Float32 values with proof-bearing
model fields and checks a handful of reference bit patterns.

This does **not** publish Float.ofBits into the selected Standard, prove
all-input equivalence to the full original upstream ofBits, or qualify
JS/TS/Rust/Wasm floating runtime/ABI behavior. Strict transitive
assumption auditing forbids Classical.choice/sorryAx; kernel/erasure and
all native CI still apply. No pskernel-core, self-hosting or C5.

## 15 October — Float32/64 bit classification fully qualified; two equalities candidate

Commit `5bb8c9c9f3c731263d910cfed8eda394b1d75ac6` passed all
[27 Linux CI 38646612366](https://github.com/dwijayuda/pskernel/actions/runs/38646612366)
steps, qualifying four additional `isInf*` and `isFinite*` checked
UInt32/UInt64 bit helper declarations and sixteen shared target observations
against pinned native Lean 4.35.0 reference behavior. The earlier
`canonical*` and `isNaN*` helpers are unchanged, and full Float F1,
arithmetic and scientific syntax remain unimplemented.

**Next candidate only:** two distinct Bool-valued bit models per width:
`beqFloat32/64Bits` reflects upstream IEEE BEq (NaN never equal,
positive/negative zero equal, other canonical bit encodings compared);
`logicalEqFloat32/64Bits` models *canonical structural bit identity*
(NaN payloads normalize, signed zero distinct). Both use checked existing
UInt, Nat.beq and Bool.rec definitions with one shared recursion helper.
They **do not** supply an Eq proof or selected BEq/DecidableEq Float
instance and must pass separate native reference, kernel/erasure,
JS/TS/Rust/Wasm GC/Wasmtime and performance checks. The strict Standard
FNV/SHA changes must first be measured independently, never guessed.
Full M2+A remains open; no pskernel-core, self-hosting, or C5.

## 15 October — checked F1 bit canonicalization fully qualified; finite/inf candidate

Commit `832764c6ec47b34e330e25441c258c4f4cbcfe05` passed all 27
[Linux CI 38644795298](https://github.com/dwijayuda/pskernel/actions/runs/38644795298)
gates, including independent native official Lean 4.35.0 bit reference cases,
strict FNV/SHA review, kernel admissions, JS/TypeScript/Rust/Wasm GC/Wasmtime
and resource qualification. The four selected `PsStandard.isNaN*` and
`canonical*` UInt32/UInt64 bit definitions are executable and checked; no
`Float.ofBits` or floating arithmetic is published.

**New pending candidate:** extend the same generic native checked bit helper
family with four `isInf*` and `isFinite*` definitions. Their exact IEEE
predicates come from pinned Lean 4.35.0 `Float.Model.UnpackedFloat.unpack`:
all exponent bits set with a zero fraction is ±infinity; any exponent other
than all ones is finite (including signed zero/subnormals). The selected
`Float.Model.isFinite`/`isInf` delegates to this unpacked model. A
small independent pinned native oracle and 16 cross-target observations cover
±infinity, both NaNs, positive/negative zero and subnormals.

No Float constructors, proof fabrication, unchecked runtime cast, platform
word-size assumption, pskernel-core, self-hosting or C5 are involved.
**Do not qualify** until CI independently measures the new strict FNV/SHA
and the entire runtime/Wasmtime/performance gate passes. Full F1–F4 and
remaining M2+A are still open.

## 15 October — native checked Float32/64 bit canonicalization candidate

The upstream F1 export at
[research CI 38643459231](https://github.com/dwijayuda/pskernel/actions/runs/38643459231)
reached 1,038 original Lean declarations but *correctly refused* their
portable replay: the current selected List.get universe signature and
multiple Int addition/ordering theorem bodies differ from the upstream
kernel dependencies. This is a real architecture/semantic boundary, not
an opportunity to weaken checking or mark the full F1 import complete.

**New coherent F1 bit-layer candidate:** native
`StandardFloatCanonical.lean` contains four ordinary checked UInt32/64
helper definitions, shared by the entire runtime prelude. IEEE exponent
and mantissa masks normalize any NaN sign/payload to the positive quiet
NaN while preserving all non-NaN bits (including signed zero/infinity).
Their exact observable cases are checked against independent pinned
Lean 4.35.0 Float/Float32 native oracles and twelve common-source
JS/TS/Rust/Wasm observations. Neither a Float constructor, unchecked
Validity witness nor an executable float arithmetic operation is added.
The new Standard fingerprints require an independent CI observation,
then a full green native/backends/Wasmtime/performance run. Candidate only.

## 15 October — checked constructive theorem cut green; full F1 closure research

The isolated theorem-only authoring/export candidate passed
[Linux research CI 38641629995](https://github.com/dwijayuda/pskernel/actions/runs/38641629995)
at `4d1a4a5896471ea92c8a8fdce25b05de6e333bff`.
It generated two independently portable-kernel-checked declarations with no
new axioms; the official Lean 4.35.0 kernel checked the theorem type at the
original `Nat.pow_eq_zero` signature. `propext` and `Quot.sound` remain
the only permitted imported assumptions. This proves the authoring
replacement mechanism works, not yet that Float F1 is usable.

**Next experimental research candidate:** extend the same *theorem-only*
cut to `Float.ofBits/toBits/isNaN/isFinite` and Float32 counterparts.
The upstream `Nat.pow_eq_zero` dependency is closed at its original
theorem name and replaced with a separately checked constructive proof.
All further upstream definitions and proof dependencies must still be
replayed by the official native/portable kernels. Refuse unknown axioms,
unsupported dependencies and any target runtime emission; record independent
CI evidence before promotion. Float F1–F4, platform sizes and complete
M2+A/Phase A remain incomplete.

## 15 October — constructive Float F1 theorem green; proof-only exporter research

Commit `2677ba11f240f950c96be95e3ad5e9bf35b19393` passed all
[27 Linux CI 38636902147](https://github.com/dwijayuda/pskernel/actions/runs/38636902147)
checks, including the native Lean 4.35.0 theorem and strict transitive
`Classical.choice`/`sorryAx` refusal. Selected Standard and all
JS/TS/Rust/Wasm GC/Wasmtime behavior remained unchanged.

**Unqualified experimental authoring:** move the constructive theorem to
host-only `Ps.Host.FloatConstructive` and supply a theorem-only proof cut.
The official Lean native kernel must check signature definitional equality
with `Nat.pow_eq_zero`, then the portable kernel independently replays the
renamed proof with the existing approved assumption allowlist. A separate
research CI workflow qualifies this study; no F1 acceptance or executable
Float is implied. No new axiom, pskernel-core, self-hosting or C5.

## 15 October — selected Standard manifest qualified; F1 constructive oracle candidate

Commit `2f97571130954eeadb9d9941f0c8fb4bdfef81b8` passed all 27
[Linux CI 38635410220](https://github.com/dwijayuda/pskernel/actions/runs/38635410220)
steps. The host-only selected Standard surface manifest is now qualified:
live notation precedence audit (22 spellings), five deriving handlers, 19
proof tactic spellings, bounded effects, module policy, registered axioms
and the existing strict FNV/SHA roster. This is **selected**, not complete
Lean-wide module/notation/effect closure.

**F1 constructive research candidate (not qualified):** separately prove
the exact pinned `Nat.pow_eq_zero` logical statement in native Lean 4.35.0
using Nat constructor and positivity cases, then invoke the official
`Lean.collectAxioms` on its complete proof dependency graph, strictly
rejecting `Classical.choice` and `sorryAx`. Historical native F1 export
[CI 38543575033](https://github.com/dwijayuda/pskernel/actions/runs/38543575033)
reported the upstream path via a generated private `Nat.pow_eq_zero`
simp proof. Passing this independent proof does **not** authorize
replacement of upstream theorem bodies, construction of floats or changes
to the F1 publisher; those remain explicitly blocked until separate kernel
and runtime acceptance. No pskernel-core, self-hosting, C5 or new assumptions.

## 15 October — checked ByteArray copySlice fully qualified

Commit `e871e4024d7ca9e3e3b85adc2b028ea7f9c33173` passed
[Linux CI 38634048433](https://github.com/dwijayuda/pskernel/actions/runs/38634048433)
with all 27 steps. Source, exact optional `copySlice` argument, checked
`extract` delegation, independently frozen FNV/SHA, official kernel
replay, negative conformance, JS/TS/Rust, Wasm GC/Wasmtime and performance
gates all passed. This is the latest fully qualified executable checkpoint.

**Next manifest candidate:** native `Ps.Host.StandardManifest` validates
the existing strict Standard roster *and* the selected infix operator
spelling/precedence table against the live parser, records deriving and
proof tactics, bounded effects and module boundaries, and inventories actual
registered axioms separately from the approved source-proof assumptions.
It must pass its own CI. This is an auditable **selected** manifest, not
full Lean 4.35.0 or all M2+A: Float F1–F4/scientific, USize/ISize width
profiles, remaining deriving/search and complete imported notation/effects
still require implementation. No pskernel-core, self-hosting or C5.

## 15 October — append fully qualified; shared copySlice candidate

Commit `13595a906abec60b39dccf54567d83d53e730fa0` passed all
[27 Linux CI 38620235817](https://github.com/dwijayuda/pskernel/actions/runs/38620235817)
steps, qualifying the native checked `ByteArray.append` model, the
general Lean 4.35.0 model proofs, JS/TypeScript/Rust/Wasm GC, Wasmtime and
resource gates. This is the last **fully accepted executable checkpoint**
until newer independent CI evidence.

**Next candidate (not qualified):** implement `ByteArray.copySlice` as
a pure checked List/Array sequence of prefix, clipped source middle and
remaining destination suffix; refactor `ByteArray.extract` to reuse
`copySlice` as in pinned Lean 4.35.0. Preserve default
`exact : Bool := true` as real `optParam Bool true` and do not pretend
the capacity hint changes logical bytes or that packed runtime performance
is implemented. Add all-input native Lean proof that exact true/false
produces the same logical result, plus bounded source/oracle/runtime cases.
Keep the unchanged strict registry guard until independent CI measures both
new fingerprints. No new axiom, pskernel-core, self-hosting or C5.

## 15 October — list conversion/extract fully qualified; append candidate

Commit `070d7d4d2c72b52cecc39f576128119ed2261b19` passed
[Linux CI 38618782594](https://github.com/dwijayuda/pskernel/actions/runs/38618782594),
all 27 gates (official Lean, replay, strict registry, native oracle,
direct JS/TS/Rust, Wasm GC/components/Wasmtime, performance). Selected
`List.toByteArray` and `ByteArray.extract` are now the last **fully
qualified executable** extension; no packed-buffer performance claim.

**Next pending candidate:** `ByteArray.append` follows the exact native
Lean 4.35.0 `Init/Data/ByteArray/Bootstrap.lean` logical expression:
`⟨⟨a.data.toList ++ b.data.toList⟩⟩`, reusing checked List.append
and List.toArray without a new backend primitive. General native
Lean proofs of list-to-byte-array representation and append
definitional equality complement three shared target observations.
Do not promote until separate strict FNV/SHA review and full CI.
Remaining Float F1–F4, USize/ISize profiles, selected deriving/search,
and comprehensive Standard manifest are still open.

## 15 October — qualified toList and next checked conversion/slice candidate

Commit `314b0cd67d70a4664da1957fd96f4676ad6e1524` passed all 27
[Linux CI 38616800244](https://github.com/dwijayuda/pskernel/actions/runs/38616800244)
steps: the selected logical `ByteArray.toList` passed official kernel,
strict FNV/SHA, native oracle, shared JS/TS/Rust/Wasm GC/Wasmtime and
performance gates. It is the last fully green executable checkpoint.

**Next candidate only:** add the Lean 4.35.0-pinned
`List.toByteArray : List UInt8 → ByteArray` and
`ByteArray.extract : ByteArray → Nat → Nat → ByteArray`.
Use checked List/Array conversions and `take (stop-start) (drop start xs)`
for exact half-open, bounded index semantics; no packed-buffer shortcut,
unchecked assumption, new kernel, self-hosting or C5. Native oracle and
shared-target cases cover order, empty/reversed range and out-of-range stop.
Qualify independently; the next registry FNV/SHA must be measured by
strict CI before updating its expected values. This new slice is not green.

## 15 October — checked ByteArray indexed API fully qualified

Commit `05d4c1cec39bf7cb93089041982e60f802563c5d` passed all 27
[Linux CI 38607736899](https://github.com/dwijayuda/pskernel/actions/runs/38607736899)
steps. The approved selected Standard fingerprint is FNV
`fnv1a64:18073559988743207974`, SHA-256
`sha256:bbf06e5a2091c8cb1af14a0b7c35177b9ce029aea402e853072cccc1d43abfac`.
Native Lean checked the proof-indexed `ByteArray.get`/`set`, genuine
`GetElem ByteArray Nat UInt8`/`GetElem?`/`LawfulGetElem` dictionaries,
registered instances and metadata. Independent native checks and shared
JS/TypeScript/Rust/Wasm executions (including Wasmtime) passed. It is the
last fully qualified executable checkpoint until a newer run succeeds.

**Next checked candidate:** the logical `ByteArray.toList` conversion
reuses the existing checked Array/List representation and has bounded
native / cross-target observations. It remains pending full kernel,
registry, erasure, runtime and performance qualification. The logical
construction alone is not a proof of general equivalence with Lean's
native optimized toList loop.

Outstanding M2+A: further pinned collection APIs; Float/Float32 F1–F4
without unapproved `Classical.choice`; explicit USize/ISize profiles;
selected deriving corner cases; remaining instance/search fidelity;
a reproducible complete Standard module/notation/effect/assumption
manifest. No pskernel-core, self-hosting or C5 has been started.

## 15 October — ByteArray cross-target green and indexed API next

**Last fully qualified executable:** `4ae7631c18ef9062f8a552015624b6af2d2a341d`;
[Linux CI 38606086921](https://github.com/dwijayuda/pskernel/actions/runs/38606086921)
passed all 27 steps, including official Lean 4.35.0 checking, both strict
Standard fingerprints, native ByteArray oracles, source and negative
conformance, JS/TS/Rust runtime, Wasm GC/components/Wasmtime and
resource measurements. The earlier Standard drift and JS top-level
initialization ordering were corrected without bypassing checks; the
shared Wasm trap oracle now preserves the checked UInt8 result type.

**New pending candidate:** native proof-indexed `ByteArray.get` and
`ByteArray.set` plus real checked `GetElem`, `GetElem?` and
`LawfulGetElem` instances and minimal independent source/runtime cases.
The existing checked Array and index-lawfulness machinery are reused.
This new slice is **not qualified** until its *own* strict registry
and full cross-target CI run succeed; new fingerprints must be measured,
not inferred from the previous green. Continue other M2+A tasks only
while retaining the green baseline and strict assumptions boundary.

## M2+A selected signed-to-Int snapshot — independently observed (14 October 2026)

The native Lean 4.35.0 kernel compiled all four `IntN.toInt` implementations and the source-model equality certificates at `09965258ad0fb0c206fe7ea7a0386241b5078496`. The pinned semantic audit independently refused a missing `implicit_reducible` status at `6fe1a56`; commit `09965258` corrected it to the exact upstream metadata without relaxing any checks. [Linux 38563557310](https://github.com/dwijayuda/pskernel/actions/runs/38563557310) then correctly refused the previous Standard fingerprint and independently observed **FNV `fnv1a64:12853239104520417295`** and **SHA-256 `sha256:7b6a29baea2279dc88dd94de1635937a23befd79830330874daeb5fdad778c43`**. Both are now pinned unchanged in the strict registry guards. The projected selected Standard is **1,683 declarations, 23 classes, 189 ordered instances** (previously 1,679 declarations). The four definitions add no search instance or axiom and are generated from the identical native `BitVec.toInt` two's-complement formula. **Full execution qualification is still pending**: next Linux run must pass ten common-source conversion vectors and all other JS/TS/Rust/Wasm GC/Wasmtime checks. Last fully green is the earlier `fe88e7f` signed/bitvector model proof checkpoint (27 steps, 457 runtime observations). Signed shifts, comparisons, `IntN.ofInt`, Float, platform-width integers and comprehensive Phase A exit remain incomplete.



## M2+A signed dictionary candidate — independently measured strict registry (14 October 2026)

Linux [run 38556955048](https://github.com/dwijayuda/pskernel/actions/runs/38556955048)
at `a4fdce4089f544311487048c6d773e4754eff1d7` compiled
the complete new signed dictionary source, regenerated all prior
reviewed logical assets, and correctly refused the outdated Standard
hashes before source/runtime admission. The newly observed selected
Standard fingerprints are **FNV
`fnv1a64:11697716145196202262`** and **SHA-256
`sha256:47b1598e2faa1ccbe80d183aeeaaa9f1a5444d1fd2878ae40f4bbe21c3d25cc4`**.
These exact independent values are now pinned in both strict snapshot
guards; **the new stage is not yet fully qualified**. Its 36 checked
HAdd/HSub/HMul/HDiv/HMod/Neg/OfNat/BEq/Inhabited dictionary declarations
and 36 explicit registrations should extend the preceding
1,643-declaration /23-class /153-instance roster; do not assert
new counts or cross-target parity until the next full green Linux run.
The previous fully green accepted executable remains `514f537`,
[CI 38555495881](https://github.com/dwijayuda/pskernel/actions/runs/38555495881)
(448 shared observations, native Lean signed oracle, V8 GC and Wasmtime).
No new axioms, psKernel-core, self-hosting, or Float-ofBits approval.



## M2+A checked signed operations and Float bit reads — snapshot review (14 October 2026)

At commit `7bea16a0614be79e51c1ebbb99f926eda342b1fa`, [Linux CI 38549762258](https://github.com/dwijayuda/pskernel/actions/runs/38549762258) compiled and independently regenerated the two disjoint selected Core assets **byte-for-byte**: 62 checked Int8/Int16/Int32/Int64/BitVec method definitions and six Float/Float32 read-only bit-model definitions. The original frozen /61+signed identity prelude was preserved as the noncircular export boundary; no axiom, choice, source acceptance exception, instance or class was added. Official kernel replay and candidate checks passed before the selected Standard correctly refused the old digest. The observed next snapshot is **FNV `fnv1a64:2992617569121253333`** and **SHA-256 `sha256:4fc70a9fac595be03500185122459263e1a9e75141bc8fd39a680785d682e8a3`**. The expected 1,643 declarations (previously 1,575 plus 68, unchanged 23 classes and 153 instances) are subject to full regression confirmation; this edit pins only these independently measured hashes.

**Important remaining work:** These imported definitions are logical Core, not yet executable signed/Float operations. F1 `ofBits`, NaN canonicalization, arithmetic and scientific literals, signed Int-valued conversions, signed shifts and comparisons, typed signed/float IR and ABI, all-target runtime evidence, selected arrays/bytes/library and comprehensive environment manifest remain open. The latest fully green selected Standard before this digest edit remains `d112580` in CI 38546207955. Continue M2+A in native portable `.lean`; no pskernel-core, self-hosting or unsound foundation expansion.



## M2+A logical-operation dependency qualification — 14 October 2026

**Latest green selected Standard:** `d1125803720ceb347a23acdd6f21f8140355fac5`, [Linux 38546207955](https://github.com/dwijayuda/pskernel/actions/runs/38546207955), full 25-step workflow passed. The selected environment includes checked native Float/Float32 models and `Int8/Int16/Int32/Int64/ISize` identity structures: **1,575 declarations, 23 classes, 153 instances** and unchanged 426 prior cross-target observations. FNV `fnv1a64:545524655185859287`, SHA-256 `sha256:2675059835d6278a4c7ac8871a3df937835d2ee57912dfd7b9b296576df30c1f`. Source/runtime Float and signed arithmetic remain disabled until qualified.

Next independent native Lean 4.35.0 reference slices, now under strict candidate review: (1) F1a logical `Float.toBits` and `Float32.toBits` projections, deliberately excluding `ofBits` whose full proof closure needs unapproved `Classical.choice`; and (2) a four-width coherent signed `ofNat/ofInt/toInt`, BitVec, arithmetic, division, modulus, bitwise, shift, comparison and `OfNat` root family. The 20 source methods per width are selected directly from pinned `src/Init/Data/SInt/Basic.lean` and checked against `tests/elab/test_extern_int.lean`. A green candidate would qualify source/Core authoring only; complete typed erasure, integer/Float IR validation, JS/TS/Rust/Wasm GC/ABI behavior and official native runtime observations are separate mandatory gates. No new trusted foundation assumptions, pskernel-core, self-hosting or release claim.



## Current signed selected Standard — independent digest review (14 October 2026)

At commit `8bee79d6c116ef102d0bc5bc4b4be7ae97f135e7`, [Linux 38545886718](https://github.com/dwijayuda/pskernel/actions/runs/38545886718) compiled the checked 15-entry SInt family asset, regenerated it **byte-for-byte** from the original pre-signed Standard, and rechecked all five recursor rule contracts. Its selected-Standard guard correctly refused the previous snapshot and independently reported **1,575 declarations, 23 classes and 153 instances** (net +10 actual declarations replacing five axioms); FNV `fnv1a64:545524655185859287`; SHA-256 `sha256:2675059835d6278a4c7ac8871a3df937835d2ee57912dfd7b9b296576df30c1f`. These precise observed values are now pinned without weakening the two strict registry guards. **This revision still needs its next complete green Linux regression.** No new trusted axioms, signed runtime arithmetic, portable USize/ISize execution or F1 Float bit interfaces are claimed. F1 awaits a sound resolution of the `Classical.choice` proof dependency; other M2+A exits remain open.



## Signed checked Standard integration — digest qualification required (14 October 2026)

The native candidate at `4c42b5b1ca4e7fccfc84d56dab20e2fb293ac976` passed [Linux 38544426724](https://github.com/dwijayuda/pskernel/actions/runs/38544426724) and source-transport run `7486f326f2f65da9d9ebff433ed24d83ff7ba5ce` passed [Linux 38545090626](https://github.com/dwijayuda/pskernel/actions/runs/38545090626), each with all 25 checks. The signed logical identity candidate has **15 checked declarations, five compared recursor rules, no new axioms, 93 shared nodes and 106,050 UTF-8 source bytes**, replacing the five old `Int8/Int16/Int32/Int64/ISize` type axioms. The signed stage is now imported after F0 Float logical identities using a separately frozen pre-signed export boundary, preserving byte-for-byte native regeneration. Prospective selected Standard count: 1,575 declarations (formerly 1,565); 23 classes and 153 instances unchanged. **This selected change is not yet qualified until independently observed new FNV/SHA hashes and full kernel/runtime regression pass.** F1 Float bits still cannot import unapproved `Classical.choice`; signed arithmetic and portable platform-width execution remain incomplete.



## M2+A next dependency: signed logical wrappers and F1 constructive Float blocker (14 October 2026)

The selected F0 Float/Float32 logical identity environment passed all 24 Linux gates at commit fbda73e1635fe35a5b7c31e2eda59a39f5e64b21, [CI 38534425757](https://github.com/dwijayuda/pskernel/actions/runs/38534425757). The F1 native bit/classification candidate at 5fc60b939efe0d509e9f98035bbee57a72369d2e failed its mandatory gate at [CI 38543575033](https://github.com/dwijayuda/pskernel/actions/runs/38543575033): its 1,075-declaration closure requires unapproved Classical.choice along Float.ofBits → Float.Model.ofBits → Float.Model.UnpackedFloat.unpack → Nat.pow_eq_zero. No source bit APIs or new trusted axioms were admitted. The native authoring command remains for constructive research; its unapproved candidate is not a mandatory regression gate.

Pinned Lean 4.35.0 src/Init/Data/SInt/Basic.lean provides an independent completion path: Int8/16/32/64 and ISize are genuine one-carrier checked inductives over their unsigned counterparts. A strict signed identity exporter is being qualified now, without runtime enabling, pskernel-core or self-hosting. Next: validate exported metadata and original-kernel replay, then sign-correct conversions and runtime operations. Remaining M2+A and F1–F4 are incomplete.



## F0 selected Standard digest — independently observed (14 October 2026)

Linux [run #38534047864](https://github.com/dwijayuda/pskernel/actions/runs/38534047864) at `bdfdb6b6402618908c1d52aa6494f37df7483713` compiled the newly selected 51-entry Float/Float32 Core model, independently regenerated its 254,044-byte source **byte-for-byte**, passed the F0 annotation and native-kernel negative probes, and correctly refused the previous /61 Standard digest. The run's independent candidate for the new selected Standard fingerprint was **FNV `fnv1a64:4585335486592655667`** and **SHA-256 `sha256:3bed7c1104a6209f6af124e932ce7c7ae6401f0f9483896e6730c51ffd35d0ca`**. These are now pinned in `StandardSnapshot.lean` without weakening either validation guard. The new selected environment is **pending full official kernel, source, runtime and CI qualification**; the last fully green regression remains `bb2dbbcc` on the unchanged /61 environment. F1–F4 executable Float, M2+A and later milestones remain open.



## F0 logical identity asset selected — kernel/registry qualification in progress (14 October 2026)

The pinned native F0 candidate passed all 24 Linux regression steps at `bb2dbbcc6432401fedf7f73f1b174d7ee765c3ab`, [CI #38532887281](https://github.com/dwijayuda/pskernel/actions/runs/38532887281), including rejection of a forged Format.mk signature. Exactly 51 logical entries were generated, with 8 independently compared recursor rules, no new axioms, and only pre-approved `propext` and `Quot.sound` in the existing foundation. Frozen candidate source: 254,044 UTF-8 bytes / SHA-256 `47e9e2ac59dc256d108e801e38c57a238c7cdfa1d1f06c16df2fd3390cf50501`. New pre-F0 exporter stage keeps the original /61 boundary. Integrating the selected source replaces exactly 2 legacy type axioms, so the prospective Standard declaration count is 1,565 (previously 1,516); classes and instances are not modified. **Selection is not qualified until a new independently observed FNV/SHA registry snapshot, official kernel replay, negative conformance and broad Linux workflow pass.** Float ofBits/equality/arithmetic/scientific/runtime/ABI (F1–F4), M2+A and later milestones are still incomplete.



## F0 Float identity — checked candidate qualification (14 October 2026)

Commit [`9b5f04e`](https://github.com/dwijayuda/pskernel/commit/9b5f04ed5b87707410dd859a247e0d724f326cc8) completed all 24 Linux gates in [Actions run 38531327231](https://github.com/dwijayuda/pskernel/actions/runs/38531327231). Native authoring exported **51 dependency-closed Float/Float32 logical identity declarations**, replaced exactly the legacy `Float`/`Float32` type axioms inside a discarded candidate, compared **8 recursor computation rules**, and independently replayed the candidate through the official pinned Lean 4.35.0 kernel. Imported candidate axioms: **none**; approved pre-existing foundation: exactly `propext` and `Quot.sound`. Source: 254,044 bytes / 1,444 shared source nodes. The **/61 selected Standard remains unchanged**, with 1,516 declarations / 23 classes / 153 instances, 426 cross-target observations and original frozen fingerprints. **F0 is not yet selected/published; runtime Float functionality, F1–F4 and M2+A remain incomplete.**

Root cause: pinned `Float.Model.Format.mk` constructor carries elaborator-generated `autoParam` tactic annotations. These transitively refer to `Lean.Syntax` but are definitionally equivalent to their annotated proof types. The native F0-only exporter removes only fully applied `autoParam` wrappers, proves each transformed signature in the original native environment with an ephemeral official-kernel typed alias, refuses altered term bodies, and separately replays the portable Core with exact regenerated metadata. Unrelated `optParam`/real Syntax dependencies remain untouched. The next authoring checkpoint adds negative policy probes and publishes the full verified candidate source through Linux Actions text logs for review; **no snapshot or release capability change is claimed until integration and requalification.**



## Qualified /61 checkpoint — 14 October 2026

Executable `34ff236b6fe9f936d7d44b8ace1c70612c7cc66e` passed all established Linux gates in [run 38515443060](https://github.com/dwijayuda/pskernel/actions/runs/38515443060).
Selected Standard: 1516 declarations, 23 classes, 153 instances; FNV `fnv1a64:6333670853941549394`; SHA `sha256:ebf02f5f8dfecf3769cbaeaa52e39dac3ba9c8dc034ea5284655da324bc75d60`.
426 shared runtime observations for JS/TS/Rust, GC Wasm/Wasmtime component, source/official kernel, negative conformance and existing performance gates passed.
APP-03 PUnit empty invocation now resolves only known Unit/PUnit universe constraints via checked unification and validates the inserted inhabitant; it does not invent arbitrary empty arguments.
This is a qualified selected /61 integration; remaining M2+A, full v7, C5, self-hosting, and formal backend preservation are not complete.
Pinned upstream Lean 4.35.0 commit: `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Earlier /60 and failed /61 evidence below is historical.


## Current qualified boundary — Hashable and stable erased calls (14 October 2026)

Executable `d72fc7779b2e8d130915dfe4ace339634ba0addd`;
[green Linux 38466179341](https://github.com/dwijayuda/pskernel/actions/runs/38466179341).
**399 shared runtime observations**, four panic contracts, **217 portable /
227 native modules**, profile `pscv0-v7-native-bounded/60`.
Official **Lean 4.35.0**, independent oracle, semantic/refusal/search checks,
strict IR, JS/TS/Rust, V8/Wasmtime GC, WIT/WAT/component/ABI, projects and
existing performance gates pass. Performance parity is not established.

Standard: **672 declarations /23 classes /109 instances**.
FNV `fnv1a64:10680386315174967875`;
SHA `sha256:9a54d5747d3047abff68e3bd872b791f3489f719cf83e8aba6776d342f045cc0`.

Qualified: ToFormat/Repr and selected nonrecursive deriving; real UInt/BitVec
construction/conversions; unsigned Canonical ABI widths; Hashable class,
17 checked instances, selected nonrecursive deriving, native-compatible pair
and UTF-8 string hashes. Hashable's Prop and implicit fields retain pinned
semantics. Hash runtime algorithms are separately audited overrides of checked
opaque declarations, not kernel proofs of runtime implementation equivalence.

Shared erasure now lowers builtin Int.rec through a once-evaluated sign split.
Known generic calls preserve their original declaration binder masks when Sort
parameters specialize to Prop; irrelevant carriers and proof slots use Unit.
The same integration suite covers these mechanisms across every existing target.

The Nat.mod_lt and UInt/BitVec and hash foundation assets regenerate byte-for-byte
through the native-only exporter and fresh official kernel replay.
No new axioms, pskernel-core or self-hosting. Prior complete-spine WHNF and
reflexivity-before-evaluation repairs remain in place; the latest Wasm observation
source elaborates in 243 ms. This is a bounded measurement, not performance parity.

[Design, sources and qualification](PSCV0_A_FORMAT_REPR_2026-10-14.md).
**Full M2+A remains incomplete.** Continue the unsigned-operation closure
candidate, signed/platform words, Float/scientific/BitVec/selected library APIs,
comprehensive manifest, broader M2 evidence and C5 semantic retention.
Recursive/indexed/dependent deriving remains M3+B.

## Historical qualified boundary — stable Lean and pure Format (14 October 2026)

Executable `a2bcf0375c5f9acfa0d50847d44253657d5cd3cd`;
[green Linux 38443246672](https://github.com/dwijayuda/pskernel/actions/runs/38443246672).
**313 shared runtime observations**, four panic contracts, **198 portable /
206 native modules**, profile `pscv0-v7-native-bounded/55`.
Official **Lean 4.35.0** at `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`;
independent oracle, official kernel, semantic/refusal and graph gates, strict IR,
JS/TS/Rust, V8/Wasmtime GC, WIT/WAT/component/ABI, project and existing performance
gates passed. These measurements do not establish performance parity.

Standard: **394 declarations /18 classes /54 instances**, canonical v2:
FNV `fnv1a64:17804548636281664114`;
SHA `sha256:ec394b9e9c70bf92cb829060fcfee1e36aaf38f1f5e92b198a646c553ff259b1`.
The pure Std.Format algebra, measurement and renderer are ordinary checked
definitions over the shared IR, including hard-line/fill behavior, Unicode
columns, signed nesting, alignment and initial column. No formatting axiom,
backend formatter or new runtime primitive. WAT constructor discriminator names
are allocated separately from payload fields; physical indices are unchanged.

Quoting and checked Int.toNat remain qualified. Quoting comparisons use native
evaluation because upstream String.Internal.append is kernel-opaque; they are
not kernel equality proofs. Int runtime conversion preserves arbitrary precision.
Historical RC4 receipts retain their original identities.

Full M2+A is **not complete**. Next: ToFormat/Repr and remaining A/M2.


## Pinned Lean reference rule (14 October 2026)

Current pin: **Lean 4.35.0**, `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
[Migration and source comparison](PSCV0_LEAN_435_PIN_2026-10-14.md).
Before any feature design, implementation or redesign, study the corresponding
official implementation and relevant tests at this pin. Record algorithms,
data structures, semantics, invariants, optimizations and the comparison with
PSC0; justify simplifications and validate against Lean where applicable.
Retain licensing/attribution when adapting code. This applies to M0–M5,
A–E, C5 and all future development; do not preserve obsolete internals merely
for compatibility.


## Historical qualified boundary — M2+A transparency (13 October 2026)

Executable `35e239193e69cc466b81ac57282df1b1500f4927`;
[green Linux 38433276797](https://github.com/dwijayuda/pskernel/actions/runs/38433276797).
**293 shared runtime observations**, four panic contracts, **188 portable /
196 native modules**, profile `pscv0-v7-native-bounded/51`.
Official RC4 kernel and independent oracle, all existing semantic/refusal and
instance graph gates, strict IR, readable JS/TS/Rust, V8/Wasmtime GC,
WIT/WAT/component/ABI, project and performance gates passed.

Standard remains **308 declarations /18 classes /54 instances**. Its canonical
v2 payload includes declaration reducibility:
FNV `fnv1a64:1901246055571366448`;
SHA `sha256:799539fdf6557760d1c9134439ac6ea811915c7c6b054164310c11aa3e017136`.

Instance target/candidate preparation, selection unification and generator keys
now use pinned instance transparency. Checked evidence/default assignment uses
ordinary conversion. Flexible type inference preserves original checked terms
before delta reduction. Abbreviations and instance metadata survive imports.
The independent audit verifies selected upstream definition statuses.

[Transparency design and evidence](PSCV0_M2_INSTANCE_TRANSPARENCY_2026-10-13.md).
Full M2+A is **not complete**. Checked string quoting is the next implementation,
pending a strict digest review and all-target qualification.

## Current qualification — direct coercions and typed postponed results (13 October 2026)

Executable `35641f810e31f3c9d309c01028acd53ebe4112d9`;
[green Linux 38430940757](https://github.com/dwijayuda/pskernel/actions/runs/38430940757).
**293 shared runtime observations**, four panic contracts, **187 portable /
195 native modules**, profile `pscv0-v7-native-bounded/50`. Official RC4
kernel, independent oracle, all semantic/refusal gates, strict IR, readable
JS/TS/Rust, GC-Wasm V8/Wasmtime, WIT/WAT/components and project gates passed.

- Direct Coe, CoeFun and CoeSort use one checked class projection; no coercion
  chains or implicit lifting. Applications, annotations and expected types share
  these operations. Local dictionaries and APP-03 completion are qualified.
- Expected-term adaptation joins the transactional source/Core worklist.
  Mandatory defaults resolve before blocked result adaptation; failed attempts
  retain the original lexical scope and cannot leak assignments.
- Nonrecursive one-field wrappers whose erased uniform parameter determines
  their field use the concrete field representation. Type/proof-only fields
  erase; runtime fields depending on existential type fields remain refused.
  This does not introduce general higher-rank or existential runtime IR.

Standard: **308 declarations / 18 classes / 54 instances**, adding nine checked
coercion declarations and no global instances, axioms or primitives.
FNV `fnv1a64:946298686920218861`;
SHA `sha256:9afbebe8bf188a119b1bc223bc7f793da6f2dc08db9caa98e381d9e97662b234`.
See [direct coercion design/evidence](PSCV0_M2_DIRECT_COERCIONS_2026-10-13.md).

**M2+A remains incomplete.** The next source change introduces explicit
instance-search transparency, module-preserved reducibility and a reviewed
digest update; it is not yet qualified. Continue remaining Repr/Hashable,
faithful selected scalar/Float/BitVec/bytes/string/collection APIs, comprehensive
manifest, broader M2 coverage and C5 semantic retention. Keep the accepted
**M2+A → M3+B → M4+C/D → M5/E** dependencies and unchanged exit gates.
Native .lean and official Lean only; no pskernel-core, self-hosting or
compiler-source migration.


## Current qualification — M2+A scheduling, indexed lookup and literals (13 October 2026)

Executable `4d2e644d3974a6e6a4b68a15b7148bdb4f83e372`;
[green Linux 38425066964](https://github.com/dwijayuda/pskernel/actions/runs/38425066964).
**285 shared runtime observations**, four panic contracts, **186 portable /
194 native modules**, profile `pscv0-v7-native-bounded/50`.
Official Lean RC4 kernel, independent oracle, semantic refusals, strict IR,
JS/TS/Rust, V8/Wasmtime GC, WIT/WAT/component/ABI and project checks passed.

- One transactional worklist now serves Core constraints and captured source
  terms. Later arguments can determine record/lambda/tactic types; numeral
  fallback and mandatory defaults run after ordinary work reaches quiescence.
- Global instances are indexed by class while preserving priority/tie order.
  Generator buckets use rigid class plus lexical scope, followed by full
  definitionally-equal input checks. At 32 goals: zero generator comparisons
  across classes, 528 within one class. No general linearity claim.
- Numeric literals use genuine checked OfNat dictionaries. Typed Core
  application resolves class universes before search; deriving reuses it.
  Custom numeric types, local dictionaries and higher universes are qualified.

Standard: **299 declarations / 15 classes / 54 instances**.
The reviewed change adds OfNat/constructor/projection and Nat/Int dictionaries,
without new axioms or primitives.
FNV `fnv1a64:4206739069382061916`;
SHA-256 `sha256:00c6142b5f5b0e47abb8b317dc4fff3d595ab9f5e931822c4f48fca809758647`.

Direct Coe/CoeFun/CoeSort boundaries are implemented but **qualification is
pending** in subsequent source commits. They add nine checked declarations,
three classes and no global instances. Keep strict digest review.
See [scheduling and lookup](PSCV0_M2_POSTPONED_ELABORATION_2026-10-13.md)
and [direct coercion design](PSCV0_M2_DIRECT_COERCIONS_2026-10-13.md).

**M2+A is not complete.** Continue autonomously: remaining Repr/Hashable,
faithful scalar/Float/BitVec/bytes/string/collection APIs, comprehensive
module/notation/handler/tactic/effect/assumption manifest, broader M2 coverage
and C5 semantic retention. Keep dependent/indexed/recursive deriving with M3's
shared data/transport/termination work. Preserve
**M2+A → M3+B → M4+C/D → M5/E**; do not redefine the exit gates.
Native .lean, official kernel, GitHub source operations and Linux CI only.
No pskernel-core, self-hosting or compiler-source migration.

## Prior qualification — M2+A checked equality and structure defaults (13 October 2026)

Executable `d7e28a3870cdc399eca3c63c6d305b10109d2eca`; [green Linux 38418209663](https://github.com/dwijayuda/pskernel/actions/runs/38418209663).
**276 shared runtime observations** (all prior 263 retained), four panic
contracts, **183 portable / 191 native modules**, profile
`pscv0-v7-native-bounded/49`. Official Lean RC4 kernel, independent upstream
deriving oracle, 92 semantic refusals, existing do/opacity checks, strict IR,
JS/TS/Rust, V8/Wasmtime GC/component/ABI, declarations/maps and project gates pass.

- `DecidableEq` derives checked decisions for non-indexed, nonrecursive
  families with independent runtime fields, including generic universes,
  empty families and dependent proof fields. It uses Eq.rec/congruence and
  existing dependent-context substitution; no BEq-to-equality axiom.
- `BEq` skips proof fields and shares the new recursor builder.
  `Inhabited` honors explicit structure defaults and still prunes unused
  parameter assumptions. Record/constructor completion uses the shared queue.
- Typed proof conversion is shared by application/let inference and
  unification. Different propositions and runtime values remain distinct.
  Record and deriving diagnostics retain their source/constructor owners.

Standard now has **294 declarations / 14 classes / 52 instances**. The only
additions are checked `DecidableEq`/`decEq` definitions; no new axiom,
primitive, class or global instance.
FNV `fnv1a64:8231265721298810139`;
SHA-256 `sha256:89c4125cc3ca36bf198421e64673659a0acdf0207004af46738d36d32fcfd540`.

[Design, reviewed Standard change and exact evidence](PSCV0_M2_A_EQUALITY_DEFAULTS_2026-10-13.md).
**Selected milestone complete; full M2, Phase A and v7 remain open.**
Continue **M2+A → M3+B → M4+C/D → M5/E**. Repr needs faithful Std.Format,
quoting and rendering; Hashable needs UInt64/mixHash and their audited runtime
correspondence. Keep indexed/recursive deriving and dependent computational
fields with M3's general data/transport/termination mechanisms. Broader M2
scheduling/scoping/scaling, selected APIs, the complete manifest and C5
retention/publication remain on the existing roadmap. Native Lean only;
no pskernel-core, self-hosting or compiler-source migration.

## Prior qualification — M2+A generalized answers and synthetic constraints (13 October 2026)

Executable `c6468b17ef8f0a97c9e0df76c1ffe49f35c68279`;
[green Linux 38411211335](https://github.com/dwijayuda/pskernel/actions/runs/38411211335):
**263 shared runtime observations**, four panic contracts, **182 portable /
190 native modules**. Official Lean RC4 kernel and independent oracle,
92 phase-specific semantic refusals, existing do/opacity checks, strict IR,
JS/TS/Rust, V8/Wasmtime GC/component/ABI, declarations/maps and project gates passed.
Standard remains 292 declarations / 14 classes / 52 instances, with unchanged
FNV `fnv1a64:5949916575031563783` and
SHA-256 `sha256:f33d923e45baf8aa5dfa6755819737acabc09daf6d60934eb232133acaad069f`.

Scoped natural term/universe answer templates now freshen on shared replay.
The graph retains generalized answers and checks each receiving target;
root answers cannot retain term parameters. One scoped queue handles expected
types, instance holes and mandatory omitted defaults for calls/records/proof
applications. The old instance-only retry loop is removed. Global registration
also checks synthesis order and determined outputs. All mechanisms remain
portable native Lean under official checking.

[Design, exact evidence and boundaries](PSCV0_M2_GENERALIZED_CONSTRAINTS_2026-10-13.md).
The type-polymorphic local-dictionary case is kernel-qualified and explicitly
refused at erasure pending higher-rank runtime IR. Nat-indexed dictionary
sharing is qualified across every existing target. Generalized graph evidence:
6 generators / 6 answers / 1 generalized / 1 freshened shared answer. Earlier
widths 1/8/32 retain 2 generators, 3 candidates and 7/21/69 transitions.

**This completes the selected M2+A milestone, not full M2, A or v7.**
Continue **M2+A → M3+B → M4+C/D → M5/E**. Remaining M2 includes broader
postponed syntax/tactic scheduling, scoping/depth parity, search scaling and C5
occurrence retention. Remaining A includes Repr/DecidableEq/Hashable, structure
defaults, proof-field deriving and the comprehensive manifest. Keep dependent/
indexed/recursive deriving with M3+B. No pskernel-core or self-hosting.

## Prior qualification — M2 + Phase A deriving (13 October 2026)

Executable `f1ce3840c1943c9f78be20a5428fd4adfa9053af`;
[green Linux 38403318952](https://github.com/dwijayuda/pskernel/actions/runs/38403318952):
260 shared runtime observations, four panic contracts, 180 portable / 188 native
modules. Official Lean RC4 kernel/oracle, semantic refusals, strict IR and all
existing JS/TS/Rust/GC-Wasm/component gates passed. Standard remains
292 declarations / 14 classes / 52 instances with unchanged M1 FNV/SHA digests.

Parameter/universe-aware `Inhabited` and independent nonrecursive `BEq` now
share one family telescope and checked instance-search path. Inhabited uses
RC4 two-pass constructor selection and prunes unused requirements. Structures
keep projection comparisons; fieldless/payload inductives share a recursor
builder with actual motive universes and fresh local identities.

M2 also gains actual-universe projection inference, common-successor maximum
normalization, and checked rigid-spine matching that can defer head-level
constraints until typed arguments determine them. No unresolved equality is
committed, and the generator/consumer ownership/replay contract is unchanged.

[Design, boundaries and qualification](PSCV0_M2_A_DERIVING_2026-10-13.md);
[prior graph invariants and growth evidence](PSCV0_M2_INSTANCE_GRAPH_2026-10-13.md).
**Follow M2+A → M3+B → M4+C/D**, then M5/E. Full M2, A and v7 remain incomplete.
The later qualification above adds generalized answer abstraction/freshening
and the selected shared constraint queue; keep dependent/indexed/recursive
deriving with M3+B. Repr/DecidableEq/Hashable and the other documented A gaps
remain open. Native Lean / official checking only; no pskernel-core or self-hosting.

## Current roadmap integration — readable outputs (13 October 2026)

The [source, historical-branch and qualification audit](PSCV0_READABLE_OUTPUT_AUDIT_2026-10-13.md) is now the
current output plan. JS/TS/Rust/WAT/WIT are implemented for the qualified native
subset; existing bounded Lean/PS printers and historical round trips are reusable,
but full C5 reconstruction is not implemented. Do not rebuild existing emitters
or merge unrelated historical backends.

M1 is complete at the executable/run below. Next: M2 + remaining A, then M3 + B,
M4 + C/D, and M5/E. Retain C5 source/binder/occurrence information alongside its
M2–M4 semantic owners; complete C5 source publication and correspondence under
M5/E after the required A–D language closure. This replaces the old blanket
C5-after-all-A–E scheduling rule. No new milestone track is added.

**Current code boundary:** the qualifications above cover bounded M2 instance
search, generic deriving, generalized answers and the selected shared constraint
queue. Full postponed-syntax/tactic scheduling remains open.
No C5 source emitter or source-authority migration was added. Native `.lean`, official checking,
GitHub source operations and Linux CI remain authoritative. No pskernel-core
or self-hosting; Wasm GC internally and linear memory only at explicit ABI boundaries.

## M1 completion checkpoint — preserved baseline (13 October 2026)

This section records the M1 completion baseline. The M2 qualification above
supersedes its executable status. Older pending-M1 statements are historical.

- **Qualified executable:** `c00e146bd5c97788a4a6a39221849973aeafda84`.
- **Green Linux CI:** [38388627512](https://github.com/dwijayuda/pskernel/actions/runs/38388627512).
- **250 shared runtime observations**, four shared panic cases, official kernel,
  independent RC4 oracle, negative/coherence and all existing backend gates passed.
- **292 declarations / 14 classes / 52 instances**; **175 portable / 183 native modules**.
- FNV: `fnv1a64:5949916575031563783`.
- SHA-256: `sha256:f33d923e45baf8aa5dfa6755819737acabc09daf6d60934eb232133acaad069f`.

M1 acceptance, selected universe/proof-automation scope, runtime-override ledger
and measured compiler/runtime costs are recorded in
[M1 completion evidence](PSCV0_M1_COMPLETION_2026-10-13.md). Generated JS still has substantial overhead
versus native Lean (roughly 492–3357x in these small batch measurements).
M1 completion does not establish performance parity, full M2/A/v7 completion,
or formal compiler semantic preservation.

**Accepted interleaving:** M2 with remaining A; M3 with B; M4 with C/D;
final M5/E qualification. Collect E evidence and apply measured M5 improvements
throughout. Continue the shared instance-search architecture alongside
the Phase A handlers that rely on it. Preserve native portable Lean,
official checking, GitHub source operations, Linux CI, branch/draft PR 109,
Wasm GC internals and explicit ABI-only linear memory. C5 is integrated as above; compiler-source migration,
pskernel-core and self-hosting remain deferred.

## Prior qualified checkpoint — M1 coherence and measurements (13 October 2026)

- **Executable:** `6a6037c311f306d82e43221ed527c7326e5785dc`.
- **Green Linux qualification:** [38387492672](https://github.com/dwijayuda/pskernel/actions/runs/38387492672).
- **246 shared runtime observations**, all prior observations retained, four panic
  contracts, official kernel/RC4 oracle and all backend gates passed.
- Standard remains **292 declarations / 14 classes / 52 instances** and
  **175 portable / 183 native modules**, with the Array checkpoint digests below.

Explicit high-priority custom optional dictionaries take precedence over the
generic default. Direct and Fin-adapted lawfulness refuse the deliberately
unlawful optional implementation. Independent RC4 negative cases passed.

Controlled samples now exist in the CI artifact's `m1-performance/` directory.
At 16/128 declarations, checked-index elaboration medians were 2/15 ms versus
1/2 ms for direct-return bodies under identical binder telescopes; prelude
admission was 8 ms. Phase timings are recorded separately.

Generated JS lookup/conversion costs are substantially above native Lean:
the first measurement shows roughly 451–3206x batch-time ratios across these
small operations. Array and List-head lookup remain roughly size-independent;
List-tail and conversion costs grow with size. This is evidence of significant
remaining runtime overhead, not high-performance parity or a formal complexity
proof. Native Lean uses a different runtime and optimized standard library.
Retain the raw samples, setup exclusions and checksums when comparing changes.
M5 should address shared calling conventions, specialization and allocation,
not add Standard-name-specific backend shortcuts.

**Final M1 qualification is still pending** for the runtime-override ledger and
remaining representation-boundary probes (partial conversions, Array elimination,
empty Fin access and position coverage). Tail benchmark repetitions are reduced
from 128 to 16 per sample to keep routine CI economical while retaining five
measured samples and matched native/JS workloads. This changes measurement
duration, not correctness or acceptance criteria.

## Prior qualified checkpoint — M1 checked Array and conversions (13 October 2026)

This section supersedes older implementation-status statements below.

- **Executable:** [af96aa405a2b2f94df9a5dada607b4fc455fc624](https://github.com/dwijayuda/pskernel/commit/af96aa405a2b2f94df9a5dada607b4fc455fc624).
- **Green Linux qualification:** [38386745772](https://github.com/dwijayuda/pskernel/actions/runs/38386745772), official Lean 4.35.0-rc4.
- **Selected Standard:** 292 declarations, 14 classes, 52 ordered instances; 175 portable / 183 native modules.
- **Frozen FNV:** `fnv1a64:5949916575031563783`.
- **Frozen SHA-256:** `sha256:f33d923e45baf8aa5dfa6755819737acabc09daf6d60934eb232133acaad069f`.
- **244 shared runtime observations** passed in JS, strict TS, Rust, V8 Wasm GC and the native Wasmtime component host. All prior 198 remain.
- Four shared panic contracts passed, including empty Array bang access.

Array now has a checked List-backed logical model, actual size bounds, proof
access, optimized optional/bang dictionaries and both checked lawfulness laws.
The seven previous selected Array primitive axioms are replaced by checked
logical definitions. Efficient backend intrinsics remain a separately audited
runtime boundary; kernel checking is not a proof of backend equivalence.

Explicit Array.mk/List.toArray conversion uses a typed sized builder with
prepared List metadata. Every backend allocates private array storage and
traverses linearly; no backend hardcodes List tags or copies each persistent
prefix. Array.toList uses a typed fold and checked reverse, also linear.
Persistent updates, oversized indices, Fin adapter behavior and Nat/Bool
conversion cases passed. Array and List remain selected Type-0 collections;
Option and generic indexing/adapters retain the qualified universe closure.

**M1 remains incomplete pending final evidence:** explicit adverse-dictionary
coherence/priority checks and representative compiler/runtime performance
comparisons. Full M2 begins only after M1 acceptance, then interleaves with A.
No C5, self-hosting or pskernel-core.

## Prior qualified checkpoint — M1 List/Fin indexing (13 October 2026)

This section supersedes older checkpoint claims below.

- **Executable:** [e73ce2bbff522e5888a409b7b114042877d71943](https://github.com/dwijayuda/pskernel/commit/e73ce2bbff522e5888a409b7b114042877d71943).
- **Green Linux qualification:** [38384869133](https://github.com/dwijayuda/pskernel/actions/runs/38384869133), official Lean 4.35.0-rc4.
- **Selected Standard:** 277 declarations, 14 classes, 49 ordered instances; 173 portable / 181 native Lean modules.
- **Frozen FNV:** `fnv1a64:1660797324209886684`.
- **Frozen SHA-256:** `sha256:1937840a8a4fda1612e3e03e17860b4abad97b355beb6a896eee4c2171abbb3d`.
- **227 shared runtime observations** passed in direct JS, strict TS, Rust, V8 Wasm GC and the native Wasmtime component host. All prior 198 observations remain.
- Three panic cases passed in JS/TS/Rust and V8/Wasmtime core/component execution.

Qualified: checked Fin structure and original-predicate-preserving Nat-to-Fin
index adapters; List proof/automatic/optional/bang access; both List lawfulness
proofs; matching Fin adapter lawfulness. Optional List access uses a single
structural traversal, without a preliminary length pass. The official kernel
accepted every added logical definition. The pinned source oracle, negative
invalid-bound cases, strict IR and existing integration gates passed.

One family-parameter classification now erases numeric datatype parameters
without erasing ordinary computational Nat function arguments. List.get's Fin
value survives while its bound proof does not. A Fin bound does not authorize
access to a smaller collection. The selected List universe is still Type 0;
Option and generic Fin adapters retain their qualified universe parameters.

**M1 remains incomplete.** Next: checked Array logical model, genuine size-bound
indexing, explicit linear-time logical/runtime conversions, alias/large-index
coverage, and controlled representative performance comparisons. Full M2 starts
after M1 acceptance, interleaved with feature A as the user requested. C5,
pskernel-core and self-hosting remain excluded.

## Architecture milestones and feature phases: execution order

M0–M5 and A–E are two dependency-linked views of one project, not sequential
checklists. M1 is complete. Continue M2+A, then M3+B and M4+C/D, interleaving coherent
feature slices with their enabling architecture:

| Milestone | Architecture | Feature phase |
| --- | --- | --- |
| M0 | Shared typed erasure, proof/type/index masks, strict runtime IR | Foundation for A–E |
| M1 | Checked indexing and selected Standard closure | Indexing portion of A |
| M2 | Instance search, expected types, universes, priorities and rollback | Remaining A; enables B–D |
| M3 | Dependent/mutual data, elimination and total recursion | Primarily B |
| M4 | Class-driven effects, specifications, VC generation and assurance | Primarily C and D |
| M5 | Incremental compilation, validated optimization, tooling and performance | Consolidates A–D; final E integration |

A completes selected Standard APIs, deriving and the supported-language manifest.
B completes dependent data and total recursive programming. C completes typed
effects, state/control flow and explicit IO/FFI. D completes selected checked
tactics, specifications and verified-emission obligations. E establishes complete
conformance and cross-target integration evidence.

Collect E evidence with every feature slice; apply M5 performance/tooling work
when measurements and dependencies justify it. Do not delay all feature work
until M5: M5 acceptance itself requires A–E conformance. Do not implement feature
special cases ahead of their shared mechanisms. These dependencies do not claim
that M0's qualified subset or any later full milestone is already complete.

## Prior qualified checkpoint — M1 universes and bounded index proofs (13 October 2026)

This section supersedes older checkpoint claims below.

- **Executable:** [4fe35ca32b8f3b49f85b89bb9b699d95f7fd7b7d](https://github.com/dwijayuda/pskernel/commit/4fe35ca32b8f3b49f85b89bb9b699d95f7fd7b7d).
- **Green Linux qualification:** [38382777891](https://github.com/dwijayuda/pskernel/actions/runs/38382777891), official Lean 4.35.0-rc4.
- **Selected Standard:** 258 declarations, 14 classes, 43 ordered instances; 171 portable / 179 native Lean modules.
- **Frozen FNV:** `fnv1a64:7381279441732502588`.
- **Frozen SHA-256:** `sha256:c1444324de1014fa01b9c82fb09f2a6ab96b824ac08ae6b6e548e2145fd61c85`.
- **215 shared runtime observations** passed in direct JS, strict TS, Rust, V8 Wasm GC and the native Wasmtime component host. All prior 198 observations remain.

Qualified: universe-polymorphic Option constructors/recursor, map/bind/getD/filter,
BEq and Inhabited; GetElem?, default implementation and both LawfulGetElem laws
at the element universe; higher-universe dictionary synthesis and erasure.
Explicit Option.bind may change universes; monadic Option do fixes a single
universe as RC4 does. An independent oracle and a negative do case cover that boundary.

Index automation now constructs checked natural-order proofs from definitional
normalization, closed comparisons, successor rules and bounded local transitivity
search. It is not full omega. Large natural indices remain arbitrary precision.
The unifier first tries congruence for a shared named application head, retaining
dictionary argument identity; failure rolls back and uses ordinary reduction.
This avoids unfolding an inferable dictionary argument into applied metavariables.

The official kernel admitted the selected definitions and source proofs; strict
IR and all existing runtime gates passed. Single-run all-target timings: parse
110 ms, elaborate 93 ms, prepare 121 ms, kernel 70 ms, erase 251 ms, emit 494 ms.
These are observations, not a controlled performance comparison.

**M1 remains incomplete.** Next: checked List/Fin indexing and optimized optional
laws, Array logical model and genuine size bounds, panic/alias/large-index coverage,
and controlled representative performance comparisons. Full M2 waiter tabling,
C5, pskernel-core and self-hosting remain excluded. Read live HEAD and CI first.

## Prior qualified checkpoint — M1 natural order (13 October 2026)

This section supersedes older status statements below; historical evidence is preserved.

- **Executable:** [064baf31641ff19785feae1416eb353b38737794](https://github.com/dwijayuda/pskernel/commit/064baf31641ff19785feae1416eb353b38737794).
- **Green Linux qualification:** [38379674588](https://github.com/dwijayuda/pskernel/actions/runs/38379674588), official Lean 4.35.0-rc4.
- **Selected Standard:** 258 declarations, 14 classes, 43 ordered instances.
- **Frozen FNV:** `fnv1a64:10485782345918084284`.
- **Frozen SHA-256:** `sha256:37a8c7e027c548b59a82060556e194051867ee10d02e5b02b1f20c4875693ce5`.
- **Native closure:** 171 portable / 179 total Lean modules.
- **Runtime observations:** 206 shared cases, preserving the previous 198; direct JS, strict TS, Rust, Wasm GC and Wasmtime component gates passed.

Qualified additions: Prop-only Nat.le recursor; checked zero, successor,
transitivity, predecessor/inversion and impossible-zero proofs; checked
Nat.ble logical model; checked Boolean reflection; Nat.decLe/Nat.decLt
dictionaries. Decidable.intro and its computational projection now erase
consistently to Bool. The reflection field is erased, not trusted as an
unchecked witness. Runtime comparison keeps the existing Nat.ble intrinsic.

The same run checked the independent RC4 source oracle and false-bound
rejection, admitted source proofs with the official kernel, validated strict
IR and qualified emitted artifacts. This is **not a compiler correctness
proof or full M1 completion**. A single measured all-target application run
reported prelude 10 ms, parse 98 ms, elaborate 93 ms, prepare 297 ms,
kernel 66 ms, erase 112 ms and emit 455 ms; these are observations, not
controlled performance comparisons.

**Next M1 dependencies:** universe-polymorphic Option/GetElem?/laws and
universe-aware do binding; bounded proof-producing index automation; complete
List/Array/Fin indexing, optimized optional laws, coherent panic behavior and
representative performance comparisons. Full M2 tabling, C5, pskernel-core
and self-hosting remain excluded. Re-read live HEAD and CI before editing.
Do not repeat the older Decidable-uniqueness work: it was already qualified.


## Latest M1 foundation qualification — 13 October 2026

**Newest independently qualified executable:** [`e0ac8c69c928261e21e9593ed3f2f4aa5157385a`](https://github.com/dwijayuda/pskernel/commit/e0ac8c69c928261e21e9593ed3f2f4aa5157385a), Linux GitHub Actions [38335736466](https://github.com/dwijayuda/pskernel/actions/runs/38335736466) **passed** (13 October 2026). This supersedes older executable-status statements below, which remain as preserved history. The pinned upstream is Lean 4.35.0-rc4 (`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`). The selected Standard now contains **234 declarations, 14 classes, 40 instances**, FNV `fnv1a64:403111548970955669`, SHA-256 `sha256:6e6f1fad15d4f0cb401a09c1ebc219c3f60dd50acb21061ca9eee4ab782bd85e`; portable/native closure remains 170/178 `.lean` modules with 198 shared runtime observations on TS, direct JS, Rust, and Wasm GC/Wasmtime.

The selected RC4-compatible decision foundation has been replaced with checked `Decidable` structure, constructor, projections, Boolean reflection predicate and reducible dependent `dite`. Native metavariable-closed proof irrelevance unifies **actual proofs of the same checked Prop**, not arbitrary data or Bool terms. An official-kernel source oracle proves excluded middle from a provided `Decidable` and equality of any two witnesses of one proposition. The independently quantified decision-dictionary uniqueness theorem remains **unproved**, following a dependent-elaboration mismatch, and there is still **no generic `LawfulGetElem` instance**. List/Array/Fin indexing, Type-0 Option generalization and M2 waiter tabling remain unqualified. The older `fc8bc8b` milestone below is historical.


**New-chat handoff (13 October 2026):** `psc0/AI_WORK_STATE.md` and `psc0/AI_CONTINUE_PROMPT.md` now specify the M1-then-M2 implementation order. Last green executable remains `fc8bc8b`, [CI 38323422371](https://github.com/dwijayuda/pskernel/actions/runs/38323422371); newer documents are not executable qualifications. M1's checked optional default and target panic are done; generic lawfulness and collections are open. M2's scoped answer memo and independent budgets are done; generator/consumer waiters remain open. Keep native `.lean`, minimal milestone tests, no pskernel-core/self-hosting/C5.

## Latest qualified native compiler milestone — 13 October 2026

**Qualified executable SHA:** `fc8bc8b1f16ed993fb144e2d396c0760c068630b`.
**All-green Linux Actions:** https://github.com/dwijayuda/pskernel/actions/runs/38323422371.
**Official Lean:** 4.35.0-rc4 (`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`).
**Bounded source profile:** `pscv0-v7-native-bounded/48`, **not** complete v7.

**Newest qualified M1/M2 update (supersedes historical milestone prose below):**
The selected Type-0 `GetElem?` is automatically derived at low priority from a checked `GetElem` dictionary and a dependent `Decidable` function. Kernel-proof validity remains separate from runtime Bool. Executable `outOfBounds` has a typed multi-target panic path; the selected positive/negative optional observations passed. A general `LawfulGetElem` instance is NOT qualified: reflexivity cannot identify independently provided decision procedures. `Ps.Meta.SynthInstance` now bounds both candidate checks and goal visits independently, postpones unresolved inputs, and reuses validated completed answers. **230 declarations, 14 classes, 40 ordered instances, 198 shared runtime observations**. Detailed proof blocker and next dependencies are in [M1/M2 implementation audit](PSCV0_M1_M2_IMPLEMENTATION_AUDIT_2026-10-13.md). Full M1/M2 and v7 remain incomplete.

**Historical M0 checkpoint (superseded by the qualified M1/M2 update above):** The earlier Lean RC4-style `GetElem` typeclass and proof-carrying
`xs[i]`/`xs[i]'h` elaboration now qualify for user-defined instances.
The generated validity tactic tries genuine assumptions, definitional
reflexivity and fuel-bounded recursive constructor proofs, refusing
unresolved goals. At the M0 checkpoint, parsed `xs[i]?` and `xs[i]!` were **not yet executable conformance**:
the full `GetElem?`/default/lawfulness and out-of-bounds panic contracts
remain open. See [GetElem RC4 design/parity audit](PSCV0_GETELEM_RC4_DESIGN_AUDIT.md).

The **historical** selected prelude milestone was **221 declarations, 13 classes and
37 ordered instances**, at FNV `fnv1a64:4160132988510892817` and SHA-256
`sha256:a02c9f39e6de1830497114edfaad5e9bdd5730110b562585e3f6ecc30b80b6d3`. The source-closure guard passed
**170 portable / 178 native Lean modules**. All established **194 shared
JS/TS/Rust/Wasm runtime observations** and official Lean native checks
remain green. These are bounded qualification observations, not a proof
of full Lean RC4 Standard or complete v7.

Further Phase A work: universe-polymorphic `Option`/related Standard
prerequisites, actual indexed List/Array/Fin validity and lawfulness
proofs, `GetElem?`/panic boundaries, complete deriving and scalar/API
coverage, and pinned imports/notation/tactic/effect/assumption closure.
Phases B–E and C5 remain as documented below.

**Historical architecture audit (failed precursor, now resolved by M0):** `1cc7deb56b2b6ec37ee3a6c1eac148d113899ac7`, [Linux 38307096314](https://github.com/dwijayuda/pskernel/actions/runs/38307096314) failed at `ir/emit` because dependent `GetElem` predicate/index arguments become `unknown` runtime IR type annotations. Lean RC4 source-level oracle passed. See [`PSCV0_V7_LEAN435RC4_SOURCE_ARCHITECTURE_REVIEW_2026-10-13.md`](PSCV0_V7_LEAN435RC4_SOURCE_ARCHITECTURE_REVIEW_2026-10-13.md). **The last green executable remains `e1d463e10cbf5edd817e362ed35b21ee82c8c85b` and run 38304955212.**

**M1/M2 accepted subset:** See [native M1/M2 implementation audit](PSCV0_M1_M2_IMPLEMENTATION_AUDIT_2026-10-13.md) for precise status. `GetElem?` Type-0 selected and tabled positive-answer memoization passed 194 observations, but neither full M1 nor full M2 is complete. This supersedes the older “parsed only” status above and the historical GetElem audit statements.

## Current priority: core and essential language conformance first

Keep native portable .lean authoritative and preserve the qualified runtime
targets. M1 is complete at c00e146b / Linux 38388627512; the current matrix has
250 shared observations. M2 with remaining A is next, followed by M3/B, M4/C-D
and final M5/E. Full v7 remains incomplete.

The 12 October priority to finish semantics before full C5 publication remains
the guiding dependency. The 13 October integration refines it: retain source
information during M2–M4, then finish C5 under M5/E once required A–D semantics
exist. Compiler-source migration and self-hosting remain separate.

The canonical target is PSCV0_LANGUAGE_REFERENCE.md at its recorded v7 digest,
with Lean 4.35.0-rc4 semantics. Source preparation, official admission,
provenance, erasure, target execution and source correspondence are separate
assurance boundaries. Historical generated-source receipts do not certify the
current native source. Exact current evidence is recorded at the top of
AI_WORK_STATE.md and in the M1 completion and readable-output audits.

## Complete Phase A–E language-first execution plan (authoritative overview)

This is the full dependency plan for **core/essential `pscv0` v7**, not five independently measured percentage scores. Phases may overlap where dependencies demand it. All require checked native `.lean` semantics; no other proof kernel or unchecked runtime escape is permitted. Sub-phases and acceptance detail are also present at the TOP of `psc0/AI_WORK_STATE.md`.

| Phase | Focus | Status and completion evidence |
|---|---|---|
| **A** | Pinned Standard environment, selected P0 language and runtime APIs | **In progress.** M1 and the current M2 search/constraint/selected deriving slices are qualified. Standard: 1,879 declarations /25 classes /226 instances; 755 shared observations each on JS/TS/Rust, plus Wasm/Wasmtime gates. Executable Float F1 bit/model transport is qualified on the main development branch; Float arithmetic/scientific, target-sized words and remaining authoritative Standard/manifest exits remain open. |
| **B** | Dependent and mutual data, elimination, strict positivity and total recursive programming | **Planned.** Complete heterogeneous index reasoning, dependent motives, nested/mutual inductives, recursive pattern matrices and well-founded/structural termination; refuse invalid/partial constructs |
| **C** | General class-driven typed do, state, effectful control and explicit IO/FFI boundaries | **Planned.** Complete Monad/Except/State/Reader and selected transformers, mutable/erased state, loops/early returns, try/catch/finally, effect/capability evidence and all-target preservation |
| **D** | Kernel-checked tactics, intrinsic specifications, VC generation and assurance ledger | **Planned.** Complete selected rewrite/simp/automation, RC4 given/requires/ensures/assert/invariant/decreasing, WP/VC proof attachment, and verified-emission block on *any* unresolved mandatory obligation |
| **E** | Comprehensive conformance, independent evidence and final core/essential v7 integration | **Collected throughout; final gate open.** Reference-to-`PS-CONF-*` matrix, differential RC4 checking, cryptographic Standard/assumption closure, existing cross-target matrix, C5 source correspondence and audited verified acceptance gates. |

### Phase A detailed exit gate

- **GetElem:** implement pinned RC4 `GetElem` and `GetElem?` with actual Prop-valued validity and Decidable/proof instances; `xs[i]` and `xs[i]'h` cannot discard proofs; `xs[i]?` returns Option safely; `xs[i]!` is a separately declared panic/default behavior, not a bounds proof. Do not confuse existing checked `List.get?` with the four forms.
- **Deriving:** accepted selected trailing handlers `Inhabited`/`BEq`/`DecidableEq`/`Repr`/`Hashable` must produce genuine checked and registered definitions with generated-source provenance. Unsupported cases and arbitrary handlers fail closed.
- **Scalars/libraries:** complete pinned `Float`/`Float32`/scientific, fixed-width/`BitVec` and selected arrays/bytes/string/collection conversions, then prove and execute target parity.
- **Registry:** preserve both strict expected hashes in `StandardSnapshot.lean` for the current qualified selected roster; separately finish the comprehensive pinned module/notation/deriving/class/instance/tactic/effect/axiom manifest. Intentional semantic expansions require source review and independently observed digest values. A selected declaration snapshot is not the full environment manifest.

### Phase B detailed exit gate

Ensure formation/elimination of selected heterogeneous/indexed/dependent/recursive types, nested and mutual inductives, constructor consistency/positivity, independent motive checking, total structural and well-founded recursion. Check invalid indices/termination negative cases and runtime/proof erasure across all supported backends. No user `partial`/`unsafe` workaround.

### Phase C detailed exit gate

Generalize effects through common checked bind/pure/elaboration and appropriate instances, not a succession of one-off translations; add selected `StateT`/`ReaderT`/`ExceptT`, typed `do` and mutable/erased variables, loops, early return, throw/try/catch/finally and explicit world/IO boundaries. Specify effect and failure semantics independently of JS exceptions and validate the cross-target IR.

### Phase D detailed exit gate

Proof-producing tactics and rewriting/selected simp/omega/grind require pinned proof extensions and official kernel validation. Implement RC4-style `given`/`requires`/`ensures`, assertions, invariants/decreasing, `Std.WP`/`vcgen` and optional `where finally | spec` proof tails with a traceable obligation/effect/assumption/erasure ledger. **Verified executable output is forbidden while any mandatory proof, specification coverage, effect, assumption, termination or erasure obligation is unresolved.**

### Phase E detailed exit gate

Close a source-rule → positive/negative case → exact failure phase → Lean RC4 elaborated-term/semantic correspondence → verified IR/backend matrix. Independently validate assumption/primitive/erasure safety, crypto-pinned environment closure, multi-module linking and public APIs, JS/TS/Rust/Wasm GC/Wasmtime parity, and reproducible CI with fully recorded SHA, version/digest and evidence. Only then say core/essential v7 is complete. A green bounded profile is insufficient.

### Readable outputs within M2–M5, and deferred source migration

C0–C4b are delivered runtime/output foundations, not milestones to repeat.
[The current audit](PSCV0_READABLE_OUTPUT_AUDIT_2026-10-13.md) places C5 information retention in M2/A,
M3/B and M4/C-D, with full selected Lean/PS reconstruction and correspondence
completed under M5/E after required A–D semantics exist. This supersedes the
earlier blanket C5-after-all-A–E rule. Existing JS/TS/Rust/WAT/WIT are extended
through the same plans as features become available.

Existing backend **D** means measured performance/ownership work and is part
of **M5**; it is distinct from language Phase D proof/specification features.
Collect evidence throughout rather than waiting for a final integration pass.
Fine-grained Wasm debugger maps and optional TS/declaration maps remain explicit
capabilities, not hidden additions to the existing artifact acceptance gate.

Compiler-source `.ps` migration, bootstrap/self-hosting, `pskernel-core` and a
Rust-only source dialect remain deferred. Preserve branch history, draft PR 109,
Wasm GC internals and Canonical ABI-only linear memory.


## End state and current development contract

Keep the portable semantic compiler in shared .lean modules, executed natively
and checked by the official Lean kernel. Preserve syntax -> resolution ->
elaboration -> canonical prepared Core -> checking -> typed erasure -> validated
IR -> backend boundaries. The host retains the same prepared graph across check
and emit. No Lean frontend fallback, alternate kernel on failure, or fabricated
proof authority is permitted.

Native language growth precedes compiler-source translation. The final readable
.ps migration and fixed-point qualification remain separate future milestones;
pskernel-core, self-host generation and independent kernel suites are outside
this development loop.

## Capability dependencies

| Capability family | Existing implementation/evidence | Remaining mechanisms |
|---|---|---|
| Source categories and scopes | Native scoped terms/calls/binders, raw strings, grouped/radix literals, checked `s!` interpolation, selected proof/section grammar | Float/Float32/scientific tokens, remaining deriving handlers/modifiers and finer source diagnostics |
| Type inference and environment | Scoped unification/levels/typeclasses, checked arithmetic/BEq/ToString/Inhabited with polymorphic Prod, List and Option dictionaries, Standard signature/body/instance audit, official Lean RC4 checker | Remaining deriving handlers, floating/scalar/coercion semantics, full elaboration/search and comprehensive module/notation/effect/assumption manifest |
| Data and elimination | Structures, uniform indexed families, recursor-driven motives, dependent context reversion, homogeneous index constraints and impossible cases, nested/multiple typed pattern matrices and nomatch, proof-field storage erasure | Named discriminants, heterogeneous constraints, Type/existential fields, selected nested/mutual data |
| Recursion and runtime closure | Direct indexed recursion, changing-state workers; captured/nested recursor lifting qualified with typed traversal | Recursive pattern matrices, well-founded and mutual source recursion, complete runtime field profiles |
| Modules and libraries | Reachable import closure, private hygiene, selected re-exports/body opacity, JS/TS/Rust 3-file executable and V8/Wasmtime GC four-module execution, provenance and entry API | Complete RC4 generated public signature, collision/instance precedence and import ordering semantics |
| Proofs and contracts | Term proofs and typed goal state, exact/refine/apply/intro/assumption/rfl/constructor, focus/bullets/all_goals/any_goals, cases/induction/case/next checked by official Lean | Complete logical primitives, further goal control/elimination/rewriting, selected automation, VC/effect/spec generation and assumption closure |
| Control and effects | Checked Bool/Prop/if-let/match and selected Id/Option/Except typed do, checked Type-0 Except.bind/map/mapError/tryCatch/isOk/toOption and real cross-target error/recovery observations | General effect classes, mutable/early-return/loops, generalized do try/catch/finally and effect/fidelity laws |
| Executable assurance | Checked prepared graph, complete shared IR gate, native primitive signature/model audit, direct JS/TS/Rust integration with the same observations | Complete v7 assurance/axiom/effect ledger, specified runtime/library fidelity and final release criteria |
| Readable source and later source authority | Qualified readable runtime targets; bounded historical Lean/PS printers and round trips; native portable authoring/import guard | C5 retention in M2–M4 and source reconstruction/correspondence in M5/E. Compiler-source migration and fixed-point qualification remain separate later work. |

## Dependency-driven sequence

1. Captured/nested runtime recursion now uses checked Core helpers and the
   existing backend contract; broader well-founded/mutual recursion is separate.
2. The typed pattern matrix now serves nested/multiple discriminants,
   first-match behavior and pattern-derived terms through shared dependent
   telescopes/equality. Complete its remaining documented grammar/refinement
   boundaries as their type/recursion dependencies become available.
3. Extend data/instance and module environment ownership before broader library
   sugar, tactics and effects rely on it.
4. Build shared proof-goal and typed control mechanisms; implement selected
   automation and VC generation as proof-producing clients of those mechanisms.
5. Close the canonical capability and assurance ledger; only then begin the
   requested final compiler-source migration and generation qualification.

This ordering may change when source inspection reveals a stronger dependency.
A green compact fixture is evidence for its exact boundary, never completion of
an entire row. Validation first checks semantic invariants and actual admitted
terms, then the affected runtime path, while reusing compact integration inputs.

## Qualified backend milestones and remaining output work

Native profile 17 qualifies milestones A and B: one checked prepared graph,
actual shared IR validation, semantic/output name mapping, portable layout and
origin artifacts, plus Rust alongside TS. The same 285-declaration composite and
102 runtime observations pass in strict TypeScript/JavaScript and Rust. Target
representation and runtime policy remain in backend modules, never elaboration.
See PSCV0_NATIVE_CODEGEN.md and PSCV0_NATIVE_RUST.md for exact boundaries.

C0–C2 now implement validated artifact bundles, retained declaration spans and
generated-parent origins, a runtime API/WIT representability boundary, the
native primitive signature/model audit, shared structured ECMAScript lowering
and direct JS/declarations/source maps. See PSCV0_NATIVE_CODEGEN.md. Source maps
currently resolve to the owning declaration; token-level origins are not claimed.

The original C4/C4b integration profile was 35 with 142 observations; the current
profile is 48 with 250 observations at c00e146b / Linux 38388627512. One
ECMAScript Program supplies JS and TS output, and direct JS emission needs no
TypeScript compiler. Current qualification includes all existing runtime targets.

C3, C4 and C4b are qualified for the current checked runtime and synchronous
pure public profile. GC data/closures, generic conventions and current
Nat/Int/String/Array semantics use shared runtime IR. WIT, readable WAT and
direct component binaries share one explicit Canonical ABI plan, including
memory32 marshalling, allocation and post-return. Complete extracted contracts
and WAT/binary correspondence have independent qualification. The public profile
admits ordinary nonrecursive concrete aggregates and integer adapters; resources,
callbacks, recursive/proof-bearing foreign construction and effects require
separate explicit APIs. See PSCV0_NATIVE_WASM.md.

The user-selected option A is preserved: GC language values, linear memory only
at explicit ABI boundaries. Remaining backend work is C5 readable pre-erasure
Lean/ProofScript reconstruction and D measured performance/ownership work.
Compiler-source .ps migration, self-hosting and full v7 remain separate.
