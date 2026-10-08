# PSCVL PSCV-v1 conformance ledger

**Authority:** [ProofScript PSCV Language Reference](../pscv0/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md), normative design candidate PSCV-RC-v2, Lean semantic pin 4.35.0-rc3. **Implementation state:** partial language frontend/preflight only. **Not a conformance certificate.**

Legend: **Covered** = executable positive+negative smoke tests of the bounded stated subset; **Partial** = some behavior exists but required PSCV-v1 closure remains unimplemented; **Missing** = no conforming implementation/evidence. Lean availability outside `PSCVL/` does **not** count as PSCV source conformance.

| Spec family | Status | Implemented fragment / evidence boundary |
|---|---|---|
| §2 profiles, feature-closure | Partial | Pinned semantic version, preflight profile; exact source/environment and certificate identities missing |
| §5 lexical grammar | Partial | Lean lexer, syntax aliases, noWs call; not PSCV token closure |
| §6 imports, modules and public import | **Missing** | User imports fail; no PSCV module graph, public import, or dependency manifests |
| §7 names, namespaces, scopes | Partial | Some Lean-compatible names/commands; no PSCV deterministic scope/conformance proof |
| §8 basic `def`, `const`, `function` | Partial | Plain Lean declarations, comma binders, defaults and Unit sugar; not full PSCV ownership |
| §8 `abbrev`, `opaque`, `instance` | Partial | Lean subset, subject to gate and trusted imported environment |
| §9 binders and explicit groups | Partial | Explicit/default and `{implicit}`/`{{strict}}`/`[C α]` on functions; no full declaration-family coverage |
| §10 terms/calls/records/if | Partial | Native Lean terms, adjacent positional curried `f(a,b)`, finite braced grouping and if; named calls, record separators and full precedence not frozen |
| §§11–15 structures, inductives, patterns | Partial | Lean-compatible `structure`, `inductive`, `match`; not full PSCV comma and pattern profile |
| §§16–19 dependent types, reduction, proofs | Partial | Delegate to official Lean elaborator and kernel; exact PSCV Standard unifier/environment remains unpinned |
| §20 tactic grammar | Partial | Default `check` rejects unbraced `by` and unenumerated known tactic heads; complete exact tactic variants and non-Latin source spellings still not limited to the reference's exact Standard tactic grammar |
| §21 pure function contracts | Partial | Lean 4.35 `Std.WP` intrinsic builds `.spec`; opens VCs reject; no complete PSCV contract syntax or independently pinned semantics |
| §21 verified loop/assert/do | Partial | Lean intrinsic `assert`, `for` invariant and `while` decreasing in explicit **preview** mode; owned `ghost` and braced `do` fragment admitted by strict mode; owned PSCV for/while bodies remain to implement |
| §21 `given`, frame, `old`, errors | Partial | Pinned `given` and concrete `Except` error-proof subset available; full `reads`/`modifies`/`old` syntax and effect model/certificate missing |
| §21 effect models | Partial | `Id`, `StateM`, `ReaderM`, and `Except` with checked local/pinned-WP correspondence; verified closure/registry/digests pending |
| §22 elaborate/unify/typeclasses/default/named | Partial | Lean engine; PSCV's specified source/default/named rules not implemented in full |
| §23 computational meaning and erasure | **Missing** | No checked IR, executable provenance or erasure-preservation evidence |
| §24 Standard environment and manifest | **Missing** | Built-in pinned Lean prelude only; missing approved PSCV Standard environment manifest and digest |
| §§25–27 logical basis and collections | Partial | Lean `Nat`, `Int`, `List`, `Array`, `Subtype` subset; whole profile coverage untested |
| §§28–29 Lean compatibility/extensions | Partial | Top-level command-kind and attribute rejection; nested/fine-grained Lean syntax and untrusted extensions not isolated |
| §30 verified compile gate | **Missing** | No approved spec identity, full closure, kernel-check evidence bundle, PSCV-CERT, or artifact emission. Preflight deliberately emits nothing |
| §31 source/verification conformance | **Missing** | No full rule-to-test matrix or independent conformance oracle |
| §32 closed verified profile | **Missing** | Cannot claim verified executable status |

## Validation modes and authoritative source

The uploaded Normative RC v2 is the exact same Git blob as `../pscv0/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md`, blob `208f128c13be2e07fde25ca413641a48df214324`. See [NORMATIVE_ALIGNMENT.md](NORMATIVE_ALIGNMENT.md).

`check` is strict about an implemented RC-v2 fragment but remains **not release-conformant**. `check-preview` preserves earlier Lean frontend feasibility tests and must not be used as PSCV source-conformance evidence. Both remain uncertified.

## Validated positive examples

`pass.ps`, `pass_contract.ps`, `pass_language.ps`, `pass_lean_core.ps`,
`pass_state.ps`, `pass_while.ps`, `pass_binders.ps`,
`pass_standard_attr.ps`, `pass_braces_and_contracts.ps`, `pass_given.ps`, `pass_effect_relations.ps`, `pass_ghost.ps`, `pass_typed_errors.ps` (**development preview**), plus `normative/pass_minimal.ps`, `normative/pass_strict_binders.ps` under strict source checking.

## Negative example families

`unsafe`, `partial`, source `axiom`, `sorry`, missing annotation, unproved
contracts, missing exports, source `macro`, `#eval`, `set_option`,
`import`, unreferenced `sorry`, malformed refinement predicates,
`IO`, `noncomputable`, missing explicit/implicit arguments, unsupported
attributes, deriving and scoped syntax.

## Release milestones and blocking acceptance criteria

1. **Language L1:** mechanically list and implement each normative parser rule / Appendix-I mapping and both positive and negative conformance tests; enforce term/tactic grammar after macro expansion.
2. **Verification V1:** all PSCV contract/VC/effect/loop/ghost rules with checked evidence; no dependence on experimental Lean semantics that can drift unpinned.
3. **Specification S1:** externally approved immutable spec identity; formal coverage and implementation-refinement association; comprehensive import-closure integrity.
4. **Certificate C1:** full proof/effect/assumption/erasure closure and independent checker replay with accurate bound assumptions, `PSCV-CERT-v1` issued only if all checks pass.
5. **Native N1:** Lean-native code generation wired to certified source with checked semantic preservation and no executable emission if any required obligation is open.
6. **Ecosystem E1:** versioned modules/imports/extensions and npm packaging with trust-domain separation, CI across full corpus.

The current PSCVL has **not passed any complete L1/V1/S1/C1/N1/E1 gate**. The evidence so far is valuable feasibility and subsystem smoke-test evidence, not a full implementation score.

## Acceptance invariants

- The normal `check` result must say **UNCERTIFIED**; it cannot be promoted to a verified-build success by renaming an artifact.
- For safety, artifacts remain disabled even after a green preflight and Lean kernel check.
- Unknown syntax, declarations, imported code, proof axioms, and source extension capabilities require explicit policy, not an implicit Lean fallback.
- The original PSCV compiler, PSKernel checker and assurance workstreams retain their distinct authority boundaries.
