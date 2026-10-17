# PSCV0 v7.1 — iterative consistency, source-fidelity and assurance audit

**Audit date:** 2026-10-16  
**Repository and branch:** dwijayuda/pskernel · psc0/pscv0-v7-native-lean-v1  
**Audited document:** [psc0/PSCV0_LANGUAGE_REFERENCE_v7.1.md](https://github.com/dwijayuda/pskernel/blob/psc0/pscv0-v7-native-lean-v1/psc0/PSCV0_LANGUAGE_REFERENCE_v7.1.md)  
**Audited file blob SHA:** e727b1bdbd23af6d886096dce17d4e2b4030eef3  
**Normative target pin:** stable Lean 4.35.0, commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc  
**Status:** source-grounded document audit; **no document modifications or compiler/Lean execution claimed**.

## Executive assessment

**The revised v7.1 is directionally sound but NOT ready to freeze as a grammar/assurance specification.** The new partial-recursion distinction, opaque-partial rule, kernel-checked fixed-point equations, and fail-closed verified-artifact policy are sound design directions. However, there are **confirmed grammar/consistency defects** and **semantics/evidence decisions** still needing exact normative resolutions. Staged/unimplemented functionality is not itself a contradiction.

This review does **not** assert that every imaginable defect has been found. It iterated over full-text syntax, grammar linkage, the original and amended verification policy, fixture expectations, release metadata, live documentation links, and pinned Lean 4.35.0 source. The final focused passes found no further distinct high-confidence source-rule contradictions beyond those catalogued here, but actual Lean/PSC0 conformance must still be run.

### Classification

- **C:** independently identifiable contradiction, omission, bad reference, or missing normative grammar binding.
- **S:** consequential semantic/policy underspecification, **not** a confirmed logical contradiction.
- **H:** documentation quality/provenance issue.
- **P0:** essential before freezing v7.1; **P1:** required before verified feature activation; **P2:** polish or future capability.

## Pass 1 — actual new v7.1 grammar, registration and clause cross-check

| ID | Severity | Exact location | Finding | Required resolution |
|---|---|---|---|---|
| C01 | **High / P0** | §5 lines 1444–1455; §0B line 160 | Four productions use **selectedModifiers**, but the registry defines **psModifiers**. The former has no definition. | Introduce one formally defined **restricted modifier-prefix** category. Avoid granting both the modifier and a second copy of it from a declaration production. |
| C02 | **High / P0** | §2 lines 567–580; §5 lines 1444–1455 | **psDeclVal** admits the total **psTermination** suffix, not **partial_fixpoint**. The separate **psFixpointDecl** appends the suffix to the entire function-like declaration, which may already consume **where**. Lean's termination/fixpoint suffix belongs after the body and before local where-declarations. | Unify one body/termination/fixpoint/where grammar with mutually exclusive total/partial-fixpoint hints. Add tests with/without where and with braced/unbraced bodies. |
| C03 | **Medium / P0** | §0B line 165; §7 line 1757; §11.7 lines 2648–2659 | **psWhilePartial** is defined but not admitted by the actual selected **psDoItem** union. Describing it as a separate staged extension does not specify how grammar activates it. | Define a distinct P2 staged do-item arm, explicitly unavailable until its trace verification environment is registered. |
| C04 | **High / P0** | §7 line 1762 versus §0B line 165 and §11.7 lines 2650–2655 | The text says **plain ordinary loops** retain their runtime behavior, yet the selected while-grammar only explicitly admits invariant/decreasing total while and staged invariant-only partial while. A bare ordinary while has no binding source production. | Either explicitly admit a normal ordinary checked while production without certified invariant/termination (with an ordinary identity), or remove the claim that plain loops are admitted. Document interaction with the selected proof policy. |
| C05 | **High / P0** | §0B line 160; §5 lines 1447–1455 | Modifier and suffix families are not formally exclusive: the undefined **selectedModifiers** could include partial or unsafe already, and the grammar does not explicitly reject **unsafe + partial_fixpoint**, **partial + partial_fixpoint**, or doubled prefixes. Lean's pinned predefinition dispatcher routes unsafe/partial before partial-fixpoint and rejects invalid termination hints. | Define a finite modifier × recursion-strategy admissibility matrix and phase-specific negative tests. Preserve requested PSCV restrictions separately from Lean's broader modifier grammar. |
| C06 | **High / P0** | §0B lines 158–161; §5 line 1438; §7 lines 1812–1846 | **psContractSeq** is available on all selected def/function heads, including potentially unsafe ones. The pinned contract macro expands such a definition into a separate **f.spec theorem** referencing the function, but an unsafe declaration is not ordinary kernel-checkable proof evidence. | Source-reject intrinsic contracts on unsafe heads for the closed profile unless a separately specified, *safe reified model* is verified; use explicit boundary contracts for unsafe implementation behavior. For partial heads, specify distinct obligations rather than inferring an unfolding proof from the opaque body. |
| C07 | **Medium / P0** | §0B lines 158–160 versus §11.3 lines 2505–2511 | §11.3 summarizes command productions as selectedLeanDeclaration, psConstDecl and psFunctionDecl, omitting **psDefDecl**, while §0B makes **psDefDecl** an owned declaration core. This could erroneously bypass head-specific binder restrictions. | Explicitly include **psDefDecl** and state that general Lean alternatives cannot bypass its PSCV0 surface restrictions. |

The numbered links below correspond to current audited source **before any fixes**:
- [§0B registry](https://github.com/dwijayuda/pskernel/blob/psc0/pscv0-v7-native-lean-v1/psc0/PSCV0_LANGUAGE_REFERENCE_v7.1.md#L150-L169)
- [§2 declaration values](https://github.com/dwijayuda/pskernel/blob/psc0/pscv0-v7-native-lean-v1/psc0/PSCV0_LANGUAGE_REFERENCE_v7.1.md#L558-L580)
- [§5 partial/unsafe/fixpoint grammar](https://github.com/dwijayuda/pskernel/blob/psc0/pscv0-v7-native-lean-v1/psc0/PSCV0_LANGUAGE_REFERENCE_v7.1.md#L1428-L1479)
- [§7 while-loop policy](https://github.com/dwijayuda/pskernel/blob/psc0/pscv0-v7-native-lean-v1/psc0/PSCV0_LANGUAGE_REFERENCE_v7.1.md#L1741-L1780)
- [§11 combined do and declaration grammar](https://github.com/dwijayuda/pskernel/blob/psc0/pscv0-v7-native-lean-v1/psc0/PSCV0_LANGUAGE_REFERENCE_v7.1.md#L2493-L2521)

## Pass 2 — exact stable Lean 4.35.0 source and trust semantics

Lean's stable source was read, not inferred only from language-design analogies:

- [Parser declaration modifiers, lines 94–121](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Parser/Command.lean#L94-L121): the modifier order includes optional unsafe followed by partial/nonrec.
- [Term suffix parser, lines 620–710](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Parser/Term.lean#L620-L710): **partial_fixpoint** is a post-body termination/fixpoint alternative with optional monotonicity proof; not a declaration head or general standalone command.
- [Predefinition dispatcher, lines 298–337](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/PreDefinition/Main.lean#L298-L337): unsafe and partial have distinct handling from the fixed-point route; invalid combined hints fail.
- [Fixed-point elaboration, lines 76–112](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/PreDefinition/PartialFixpoint/Main.lean#L76-L112): synthesizes CCPO or uses a flat order with an inhabitant; the latter includes **Classical.ofNonempty**.
- [Contract elaborator, lines 86–154](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/Tactic/Do/Contract.lean#L86-L154): a contract transforms into a plain definition and a separately proved **f.spec** theorem, subject to an actual **Std.WP** environment.

**Correctly retained by v7.1:** (a) partial def is logically opaque, unlike partial_fixpoint; (b) a partial_fixpoint can supply checked unfolding equations but not an automatic application-specific proof; (c) user source axioms and sorry/sorryAx remain forbidden; (d) verified artifact emission is blocked while its mandatory proof obligations remain unresolved. There is no justification to roll these sound safeguards back.

## Pass 3 — verified-program semantics, trust closure and cross-backend evidence

These are **real blocking ambiguities** for a production checker, but are not presented as already-demonstrated kernel unsoundness.

| ID | Priority | Locations | Issue and why it matters | Required normative resolution |
|---|---|---|---|---|
| S01 | **P0** | §§0A, 5, 7B, lines 25, 137–138, 1470–1479 | **Proof-before-compilation has two meanings.** An explicitly selected ordinary executable can be emitted without behavioral proof, while a verified one cannot. If “if not proven, no compilation” applies literally to *all* executable output, this is a product-policy mismatch. | Define “proven” separately for ordinary (type/proof-term closure) and verified (behavioral obligations), or remove ordinary executable output. Preserve mandatory explicit selection/no silent downgrade. |
| S02 | **P0/P1** | §5 lines 1434–1479; §7B lines 2018–2043 | **Adequacy for partial_fixpoint divergence is unspecified.** Its logical value may be total/arbitrary on divergent inputs, while compiled code loops or traps. Equating returned values is not an adequate refinement relation on such inputs. | Define observables Return(v), Throw(e), Diverge, Trap, finite/infinite effect traces; use termination-sensitive result adequacy and distinct divergence/safety/liveness obligations. Do not interpret logical Option.none as runtime return-on-divergence. |
| S03 | **P1** | §5 line 1438; §7B lines 2025–2039 | **Formal proof about unsafe bodies has no stated representation.** Lean cannot simply use an unsafe function as a theorem proof term. Reify the safe operational model/typed IR and prove correspondence with the chosen implementation; a typed unsafe symbol alone is insufficient. | Specify what safe object is being proved about, how the target implementation is related, and which assumptions preclude a closed certificate. |
| S04 | **P1** | §5 lines 1434–1440; approved-axiom closure in §§0A/7B | **Classical axiom dependency is not categorized for fixed-point construction.** In the flat-order fallback, stable Lean uses Classical.ofNonempty. A profile forbidding relevant classical assumptions may therefore reject otherwise accepted partial_fixpoint constructions. | Pin and classify all logical dependencies generated by the fixed-point elaborator. Make permitted classical axioms explicit and reject only if absent from the selected manifest; do not claim axiom-free proofs automatically. |
| S05 | **P1** | §5 lines 1432–1442; §7 lines 1812–1846 | **Contract handling for partial/opaque definitions is unspecified.** Native f.spec generation is not an unfolding theorem for a partial body; verified body correctness needs a separate operational/refinement proof. | Define eligibility matrix: total def contract; partial_fixpoint contract plus generated equations/adequacy; opaque partial def with separately supplied verified body/model; unsafe requires modeled safe wrapper. |
| S06 | **P1** | §§7/7B, lines 1754–1780, 2020–2041 | **Trace verifier is explicitly staged but has no closed VC rule or effect observation model** for infinite loops and concurrency. This is an honest future feature, not currently usable assurance. | Define transition system, invariant rule for each continuation/exception path, trace granularity, fairness assumptions, and effect/model closure before activating. |
| S07 | **P1** | §5 line 1442, §7B, §14 line 3165 | **Logical vs executable dependency closure is not operationally defined.** partial_fixpoint may use logical noncomputable constructions that are not the compiled body. A naïve graph walk of logical dependencies would reject valid executables, whereas ignoring runtime replacements would miss errors. | Keep separately versioned logical, proof, executable, target-runtime, imported axioms, and erased dependency graphs with auditable transformations. |
| S08 | **P1** | §0A/§7B, lines 25–29, 137–138, 2020–2041 | **Assurance taxonomy is ambiguous.** The text says two outcomes but displays three labels: ordinary checked, closed verified, boundary-qualified verified. | State two broad families (ordinary and verified) with two distinct verified assurance grades; give each grade a non-interchangeable machine-readable identity. |
| S09 | **P1** | §7B and backend clauses, lines 29, 1474–1479, 2041 | **End-to-end backend obligations are demanded, but target-specific scope is not fixed** for resource exhaustion, panic, stack overflow, OOM, scheduling, host effects, and FFI contracts. | Pin observable trace/termination/failure semantics per JS, Wasm, Rust target and decide what resource behavior is outside the verified guarantee. |
| S10 | **P1** | §§0A, 5, 7B; source excludes proof escapes in .ps | **Unrestricted imported .lean/host code is allowed syntactically while its logical/runtime dependencies must be audited.** The profile has no frozen, executed complete import/effect/assumption manifest yet. | Specify precise transitive import-closure acceptance over logical constants, unsafe/runtime substitutions and generated theorem dependencies; reject unverifiable imports, without restricting .lean's own syntax. |

## Pass 4 — metadata, documentation and conformance-test hygiene

| ID | Severity | Location | Finding | Action |
|---|---|---|---|---|
| H01 | **Low / P0** | §14 line 3095 | Stable release **4.35.0** (published October 12, 2026) is mislabeled **prerelease**. | Replace with **stable release**; retain RC4 only as historical provenance. |
| H02 | **Medium / P1** | §5 line 1430 and many other links | Several pinned-version deep links for specific Lean reference chapters were inaccessible/returned 404 in live checks (notably Definitions/Recursive-Definitions and Definitions/Modifiers); version root and Source-Files-and-Modules are accessible. | Validate links; prefer working versioned chapters when available, exact pinned GitHub source links otherwise. Never substitute moving /latest/ as the *normative* semantic pin. |
| H03 | **Low / P2** | Whole Markdown | The source contains 81 balanced HTML table blocks in a .md file, in addition to ordinary Markdown tables. Valid in many renderers, but inconsistent with pure-Markdown authoring and harder to maintain/test. | If pure Markdown is required, convert HTML comparison tables to valid Markdown with multiline code shown outside cells; ensure code samples remain copyable. |
| H04 | **Medium / P1** | §§5/7/11, §13 fixtures | 179 unique P-/N- fixture IDs were found, with no duplicated table-case identifier. However, missing **interaction tests** include (partial + fixpoint), (unsafe + fixpoint), (unsafe + contracts), (partial + contracts), mutual combinations and where-placement. | Add explicit phase-specific positive/negative matrix tests. Existing cases are proposals, not passing CI evidence. |
| H05 | **Low / P1** | Intro scope vs §§0A, 5, 7B | Intro says implementation architecture/release gates are out of scope, while the edition also gives normative emission order, backend evidence/certificate distinctions, and CI gates. | Differentiate *semantic outcome requirements* within this language reference from out-of-scope operational pipeline architecture. |

## Negative/positive acceptance additions recommended

| ID | Source scenario | Required decision |
|---|---|---|
| N-V71-MOD-DOUBLE | modifier repeated or selectedModifiers permits double partial/unsafe | PARSE/profile reject |
| N-V71-MOD-FIX | unsafe def with partial_fixpoint; partial def with partial_fixpoint | PARSE/ELAB reject conflicting Lean recursion strategy |
| P-V71-FIX-WHERE | valid supported partial_fixpoint before admissible where declarations | Accept source/fixpoint construction only when pinned Lean admits it; no automatic verified behavioral claim |
| N-V71-FIX-AFTER-WHERE | partial_fixpoint placed after where block when Lean requires suffix first | PARSE/profile reject |
| N-V71-PARTIAL-CONTRACT | opaque partial function contract with no independent body/model proof | verified VC/ASSURANCE reject |
| N-V71-UNSAFE-CONTRACT | unsafe function with intrinsic f.spec theorem attempted without a reified safe implementation model | PARSE/profile or VC/ASSURANCE reject for closed proof |
| P-V71-WHILE-ORDINARY | plain while in explicitly ordinary executable profile, if admitted by final grammar | Type/effect/profile check; output is never verified by implication |
| P-V71-WHILE-TRACE | staged invariant-only loop with explicit registered trace proof rule | Accept verified only after all finite-prefix and promised liveness/effects obligations |
| N-V71-WHILE-UNREGISTERED | invariant-only loop without selected trace evaluator/model | ENV/VC/ASSURANCE fail-closed |
| N-V71-BACKEND-TRAP | compiled backend stack trap incorrectly equated with logical divergence or a result value | reject closed verified artifact |
| N-V71-IMPORT-UNSAFE | imported Lean unsafe implementation substituted for checked source without a proved boundary correspondence | ASSURANCE reject closed |
| N-V71-FIX-AXIOMS | fixed-point proof depends on a classical assumption outside approved set | ASSURANCE reject, distinguishing this from proof-hole rejection |
| N-V71-FAILOVER | requested verified build fails but emits an ordinary executable | reject all emission from requested build |

## Iterative re-audit log

1. **Pass 1 (static structure):** inspected full 3,329-line reference; 78 fenced-code markers (balanced), 81 balanced HTML table pairs and 64 conventional Markdown tables with no unescaped-pipe column-count errors. Normalization does not prove examples compile. Identified C01/C02, plus the need to reconcile recurrence syntax.
2. **Pass 2 (pinned Lean fidelity):** inspected parser, predefinition and partial-fixpoint elaborators, order/monotonicity source, and contract-expansion macro; confirmed upstream implementation boundary and C05/C06. Live reference navigation exposed H02.
3. **Pass 3 (independent cross-section scan):** compared §0B registry, §2 declaration values, §5 recursion, §7 loops, §7B assurance, §11 summary grammar, and §13 fixtures. Added C03/C04/C07 and S01–S10.
4. **Pass 4 (evidence/fixture scan):** checked source baselines, duplicated P/N test labels, “prerelease” remnants, and old unconditional bans. Added H01/H03/H04/H05. The old universal partial/unsafe source rejection is gone; verified build still fails closed by design.
5. **Pass 5 (reconciliation):** rechecked all identified interactions against explicit v7.1 staging and the pinned dispatcher. No **additional distinct, high-confidence** contradiction was established. Remaining items marked S are missing normative/evidence details, not allegations of a demonstrated unsound compiler.

**Confidence limitation:** This is a *document/source-level* iterative audit, not exhaustive formal model checking. No Lean binary/lake toolchain or PSC0 source execution is available in this audit. Tests, generative cases, backend traces, and source-mapping remain required before claiming all actual issues are found or proving a completed compiler conforms.

## Recommended repair order

**First (P0 — language grammar/spec freeze blockers):** C01–C07; resolve S01 assurance semantics; correct H01. Use **one** authoritative grammar ownership path across §0B, §2, §5, §7 and §11, with **no undefined aliases and no contradicting suffix ownership**.

**Second (P1 — verified-artifact enablement):** S02–S10. Prioritize a safe representation and proof rule for partial/unsafe executable bodies, precise trace/result/failure refinement, and the approved imported-axiom closure. Add the missing cross-feature negative tests.

**Third (P2 — document hygiene):** Fix deep links as supported by published/pinned sources; reconcile scope wording; optionally convert the historical HTML comparison tables to pure Markdown without damaging multiline examples.

### Conclusion

PSCV0 v7.1 contains **real correctable specification inconsistencies**, not merely stylistic preferences. Its central policy—verified emission only after all mandatory proof, effects, assumptions, erasure, runtime and backend correspondence gates pass—is a defensible design goal; the new recursion and unsafe features must not be implemented using parser admission alone. After the above repairs, rerun the full grammar/assurance audit and execute stable-Lean conformance tests before calling v7.1 frozen.
