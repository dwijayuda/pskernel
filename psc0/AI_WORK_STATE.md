# PSC0 AI WORK STATE — native v7 binder groups

## 11 October 2026 — shared annotation scope for multi-name native groups

Active branch: `psc0/pscv0-v7-native-lean-v1`; draft PR #109.
The user requested multi-name native binder groups with correct annotation scope,
authored in native `.lean`, with clean architecture, minimal checks, no
pskernel-core and no self-hosting. Work uses GitHub source operations and Linux
cloud CI; no local checkout, build or tests.

The binder head now represents a nonempty group: one first name, additional names,
binder kind and span, paired with one annotation in the existing recursive AST.
A unary construction helper preserves existing callers. Native group parsing
retains this boundary in lambdas, quantifiers (including bare `forall A B : Type`),
explicit dependent arrows, variables and nonexplicit value-declaration parameters.
Declaration explicit parameters still require individual comma entries.

The scope walker visits the annotation before adding any group name. The shared
elaborator elaborates a non-placeholder annotation in that outer context once,
then introduces each name with the resulting Core type. Whole-domain inference
holes obtain their own expected domains per name. Thus a grouped lambda such as
`fun (T: Type) (T x: T) => x` retains the outer type identity in both inner
parameter types. Expected telescopes still advance one actual parameter at a time.

Section dependency selection filters names within groups, preserving shared
annotations and dependency order without capturing unused siblings. Inclusion,
instance eligibility and fixed recursive section arguments all use the same name
enumeration. The recursion walker respects group scope; normalization splits
groups only after renaming annotations to inaccessible parameter identities.
Constructor metadata counts elaborated fields rather than source groups.

Shared native binder printers preserve all group names. The declaration-only PSC
printer explicitly refuses grouped explicit parameters requiring a future
scope-preserving lowering. There is no compiler-source translation milestone here.

**Qualified in [Linux run 38156237259](https://github.com/dwijayuda/pskernel/actions/runs/38156237259)**
at source commit `8c0504c4ba8c9f8a6118bcf65e9803824a6dd2af`, using native Lean 4.35.0-rc4
(`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`), profile
`pscv0-v7-native-bounded/5`. The first run passed.

The 28 existing parser cases remain unchanged. The same three accepted semantic
programs now cover grouped local/global shadowing, bare quantifiers, dependent
arrows, heterogeneous inferred lambda parameters, implicit/strict implicit groups,
selective section capture and changing-state recursion. The composite application
admits 72 declarations, including its generated recursive worker. The existing
five-declaration instance/Except case now uses grouped proposition variables.
Three new refusal inputs check declaration-vs-native grammar, an unavailable
outer annotation name and duplicate names within a section-variable group,
bringing the compact batch to 25 phase-specific refusals.

Native compiler/check binaries, official kernel acceptance, CLI emission,
TypeScript 7.0.2 compilation and JavaScript runtime assertions all passed.
The inventory remains 69 portable and 75 native closure modules, no pskernel-core.
Measured cached source rebuild: 17,613 ms; unchanged rebuild: 490 ms.
CLI application parsing took 2 ms, elaboration 1 ms, bridge preparation 3 ms,
official kernel checking 3 ms and erasure 4 ms. These are small-workload
measurements, not a broad performance benchmark. Existing unrelated unused-name
warnings remain. The following evidence-recording commit changes this document only.

Remaining binder limitations: pattern binders, lambda result annotations and
automatic insertion of omitted implicit lambda binders. Inductive/structure source
headers retain the selected legacy data grammar. The older Lean-source parser,
full source translation and roundtrip qualification remain outside this native
development increment. Imports, universes, global classes/instances and the other
broader v7 milestones remain pending. No complete-v7 or self-hosting claim.

The following records are historical and apply to their exact source commits.

---

# PSC0 AI WORK STATE — native v7 quantified types and shared binders

## 11 October 2026 — native binder syntax through shared semantics

Active branch: `psc0/pscv0-v7-native-lean-v1`; draft PR #109.
The user authorized continued native `.lean` implementation with clean portable
architecture, minimal checks, no pskernel-core and no self-hosting. Source changes
and qualification use GitHub operations and Linux cloud CI.

The v7 binder module now accepts annotation/value readers as callbacks. Declaration
parameters, variable commands, native lambda/quantifier groups and explicit
dependent arrows use the same entry/group grammar. Declaration comma groups and
defaults retain their own policy; native term binders cannot introduce a hidden
Unit or accept declaration commas. Parameter accumulation now uses a reversed
accumulator instead of repeatedly appending the growing prefix.

Implemented `forall`/`∀`, `fun`/`λ`, `=>`/`↦`, Unicode strict implicit
`⦃...⦄`, and anonymous `[ClassTerm]` binders. Quantifiers feed the existing
forall AST and ordered binder elaborator. Anonymous instances have inaccessible,
source-local names and use existing lexical instance synthesis and section
generalization. A common printer renders these binders anonymously and preserves
binder kinds in quantified source. No new Core expression, proof algorithm,
host elaborator fallback or kernel implementation change is involved.

**Qualified in [Linux run 38155402871](https://github.com/dwijayuda/pskernel/actions/runs/38155402871)**
at source commit `7c80638275e979689473d5bf43ba9f2d054edd59`, with native Lean 4.35.0-rc4
(`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`), profile
`pscv0-v7-native-bounded/4`. The first run passed.

The existing 28 parser cases passed unchanged. The compact semantic batch still
uses three accepted programs and one checked immutable prelude, now with 22
phase-specific refusals. The first application has 54 declarations and checks
quantified explicit/implicit polymorphism, dependent arrows and Unicode aliases.
The existing Except do program also checks anonymous instances in declarations,
lambdas, quantifiers and section variables (five declarations). Four new negative
inputs reject lambda declaration commas, nullary lambdas, a missing quantifier
comma and an unavailable instance.

The official kernel accepted both programs and the request-isolation case. The
CLI checked and emitted the 54-declaration application; pinned TypeScript 7.0.2
compilation and JavaScript runtime assertions passed. The import inventory stays
at 69 portable modules and 75 native closure modules, without pskernel-core.

Measured cached source rebuild: 14,612 ms; immediate unchanged build: 480 ms.
For the CLI fixture: prelude setup 1 ms, parsing 1 ms, elaboration 1 ms, bridge
preparation 2 ms, official kernel checking 2 ms, erasure 2 ms, emission 1 ms.
These are compact-workload measurements, not a large-program performance claim.
The affected compiler source has 194 added and 223 removed lines. The following
evidence-recording commit changes only this work-state document.

Remaining binder limits: one name per native group, one final bare quantified
binder, lambda result annotations/pattern binders and automatic insertion of
omitted implicit lambda binders. Multi-name typed groups require shared annotation
scope in the AST; copying their annotation into unary entries could capture an
earlier name. These forms remain explicitly unsupported. Global class/instance
declarations, universes, imports and the wider v7 milestones remain pending.
There is no full-v7, self-hosting or printer-roundtrip qualification claim.

The following records are historical and apply to their exact source commits.

---

# PSC0 AI WORK STATE — native v7 command scopes and defaults

## 11 October 2026 — ordered scopes and optional parameters

Active branch: `psc0/pscv0-v7-native-lean-v1`; draft PR #109.
The user authorized namespace/open/section scopes and default arguments in native
`.lean`, with minimal checks and no `pskernel-core` or self-hosting. Work continues
through GitHub source operations and Linux cloud CI only.

The ordered program AST retains namespace/section/end/open/variable/include/omit
commands independently of the legacy flat translation API. The shared source
preparation owns lexing budgets, selected do parsing and hygiene. A capture-aware
Scope traversal qualifies names and collects section dependencies; Command applies
scope transitions and admits ordinary declarations through the existing elaborator.
Local binders shadow globals, namespace ancestors are searched before unique open
candidates, and `_root_` bypasses source scope. Generated Unit/Except helpers use
rooted names. End restores variables, opens and inclusion state; declarations remain.

Definitions generalize section variables used in their headers or bodies;
theorems generalize header dependencies, explicitly included variables and eligible
instances. Dependency selection uses ordered reverse/forward passes. Variables are
typechecked at declaration time; omitted/unrelated parameters are not carried into
ordinary signatures. Selected structural self-calls receive fixed captured explicit
parameters before existing recursion elaboration. Shadowed captured parameters
are refused rather than rebound.

Defaults are checked at declaration scope and represented by canonical
`optParam` type applications. The portable prelude contains the same reducible
definition as RC4 Init.Prelude, checked by the official native kernel. Application
instantiation substitutes preceding arguments into dependent defaults; no source
reparsing, call-site name lookup, side metadata table or kernel change is involved.
Named/positional/default/implicit arguments share one ordered engine. Expected
function types retain partial applications; explicit empty invocation completes
defaults and at most one required Unit argument. Final `function f()` declaration
groups lower to a required Unit parameter. Diagnostics retain the declaration name.

**Qualified in [Linux run 38154247902](https://github.com/dwijayuda/pskernel/actions/runs/38154247902)**
at source commit `8a0806345b2d7cdfc2942953934193e1fffc70ff`, with native Lean 4.35.0-rc4
(`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`), profile
`pscv0-v7-native-bounded/3`.

The unchanged 28 parser cases passed. The existing semantic batch now contains
three accepted programs and 18 phase-specific refusals; it still shares one
checked immutable prelude. One 43-declaration application covers namespace
ancestors/opens, defaults closed over earlier parameters and declaration scope,
expected-result completion, preserved function values, section dependency/order,
local shadowing, theorem include/omit, fixed recursive parameters and nullary/Unit
completion. The existing Except do case now runs inside a namespace. The CLI
checked and emitted that same composite application; TypeScript 7.0.2 compilation
and JavaScript assertions passed. The source inventory found 69 portable modules
and 75 native closure modules, without pskernel-core.

Measured cached incremental build: 6,010 ms; immediate unchanged build: 504 ms.
For the CLI fixture, prelude setup took 2 ms, elaboration 1 ms, official kernel
checking 2 ms and erasure 2 ms. These small-workload observations are not a
large-program benchmark; zero-millisecond phases are timer resolution.
The following evidence-recording commit changes only this work-state document.

Selected remaining limits: module imports/visibility, universe commands, full native
binder grammar, rebinding active section variables, open modifiers/expected-type
overloads, autoParam, general CoeFun, named recursive self-calls and recursion under
shadowed captured section parameters. Source translation of scoped programs is
explicitly refused until that printer has its own ownership. This increment does
not claim complete v7 or compiler self-hosting. The import/source profile guard
is not a full portable authoring-profile verifier.

The following records are historical and apply to their exact source commits.

---

# PSC0 AI WORK STATE — rich native v7 terms

## 11 October 2026 — shared lexical scopes, applications and expected types

Active branch: `psc0/pscv0-v7-native-lean-v1`; draft PR #109.
The user authorized continuing v7 in native `.lean`, starting with rich syntax
and shared elaboration. No `pskernel-core`, compiler-source `.ps` generation,
self-hosting, local builds/tests or Windows runs.

Implemented: richer term nodes preserve labeled calls, empty invocation, ascription
and inference holes. Shared binder/application engines implement expected lambda
domains, telescope-order argument checking, named arguments, implicit insertion
and the selected one-required-Unit completion. Lexical scope exit retains meta
constraints and fresh local identities. Shared elaboration is split into Basic,
Binders, Application and the remaining Term dispatcher/control implementation.

**Qualified in [Linux run 38151599948](https://github.com/dwijayuda/pskernel/actions/runs/38151599948)**
at source commit `0c7aa371e6101b25c34ed689191c186107fd03b0`.
Native Lean 4.35.0-rc4 compilation, the 28-case parser corpus (19 positive,
9 negative), three accepted semantic programs and 11 phase-specific refusals,
CLI emission, TypeScript 7.0.2 compilation and JavaScript execution all passed.
The named-call parser case moved from refusal to acceptance because it is now
implemented; unknown/duplicate names and invalid argument order have specific
refusals. One 14-declaration application covers the new accepted behavior.

The shared type-only result is used for binder, ascription, local-let and ordinary
declaration annotation inference, including inferred annotations. Declaration
closure still rejects unresolved term/universe metavariables before preparation.
The exact source inventory is 65 portable modules and 71 native closure modules.
The actual native identity remains checked against the pinned RC4 version/commit.

Cached incremental rebuild: 5,991 ms; immediate unchanged rebuild: 383 ms.
These observations concern this compact workload, not a cold build or full v7
performance benchmark. The evidence-recording commit changes documentation only.

Scope is lexical term/declaration binders, not namespace/open/section semantics.
Defaults, general CoeFun, named recursive self-calls, full lambda binder grammar,
richer dependent matching, automation/contracts and full v7 remain pending.
Historical evidence below applies only to its recorded source commits.

---

# PSC0 AI WORK STATE — native Lean v7 implementation

## 11 October 2026 — native development foundation

The user selected the existing portable semantic compiler, authored/run natively
in Lean and checked by official Lean. Implementation stays in `.lean`; compiler
`.ps` generation and full self-host qualification are deferred to the final
migration milestone. No `pskernel-core` development/tests or slow fallback.

Active branch: `psc0/pscv0-v7-native-lean-v1`, based on
`b4bd7e7d6c48443e56eaf96099515a29a83982bf`.
The new `v7-native/` workspace uses exact Lean 4.35.0-rc4, imports shared compiler
sources, and connects the active v7 parser to the existing semantic compiler,
canonical admission bridge, official native kernel and TS backend. Native batches
reuse one checked prelude with independent request environments. Historical 4.34
bootstrap/provider identities remain intact. Old M1 regeneration workflows are
manual-only on this branch; a dedicated incremental native Linux job replaces
them in ordinary work.

**Status: native development foundation qualified on Linux.**
[Run 38150035834](https://github.com/dwijayuda/pskernel/actions/runs/38150035834)
passed at executable/source commit `7672b5f9f0c905fc19cdf251ac080f1a2e7ac072`:
native compiler/check executable build; 28 existing M1 parser cases; three accepted
programs and four phase-specific refusals with batch isolation; CLI emission;
pinned TypeScript 7.0.2 compilation and JavaScript runtime. Source inventory found
61 portable and 67 native closure modules, with no `pskernel-core`. Actual runtime
identity is checked against Lean 4.35.0-rc4 commit
`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.

The cached incremental build took 1,943 ms and the immediate unchanged build
424 ms. The small CLI fixture initialized its prelude in 1 ms and recorded 1 ms
for kernel checking; 0 ms phase values mean millisecond timer resolution, not zero
work. These are small-workload observations, not a cold-build measurement, a
large-program benchmark, or a speedup ratio against earlier compiler regeneration.

The initial target deliberately rejects module imports until v7 module semantics
land. This is a bounded compiler development foundation, not full v7 conformance
or a portable compiler fixed point. Rich source representation, scopes/applications
and expected types, dependent patterns/recursion, general typed control, proof
automation/contracts and the Standard/P1 environment remain semantic milestones.
Elaborator/backend errors currently retain phase-level codes, not rich source
diagnostics. Do not infer these capabilities from host Lean's available features.

[Draft PR #109](https://github.com/dwijayuda/pskernel/pull/109) contains this change.
The work-state update after the passing run changes documentation only.

**Corrected predecessor evidence:** M1 run
[38144002557](https://github.com/dwijayuda/pskernel/actions/runs/38144002557)
passed the bounded 21-module, one-v7 versus five-v7 source comparison at the base
commit. Candidate preparation 587,868 ms; emission 370,963 ms; total 960,809 ms.
The 18 positive/10 negative parser cases are retained, with no inferred broader
language conformance.

Current work uses GitHub source operations and Linux cloud CI only. No local
compiler builds/tests, Windows tests, independent kernel suites or kernel-source
changes. Source-profile and timings artifacts distinguish parser checks, native
kernel acceptance, runtime behavior and eventual self-hosting evidence.

See [native development commands and boundaries](v7-native/README.md).
The entries below are preserved historical records; their pending statuses and
source-authority policies may be superseded by this entry.

---

# PSC0 AI WORK STATE — v7 M1 parser ownership candidate

## 11 October 2026 — M1 implementation in progress

The user approved continuation of the systematic v7 compiler roadmap after the implementation audit. Active implementation branch: `psc0/pscv0-v7-m1-parser-ownership-v1`, based on `0e8996d2aff414986f04dbc68c2689aaf118fb48`. M1 introduces a v7-owned term dispatcher with explicit annotation assignment ownership, reuses predecessor token/AST/category-neutral readers, and preserves historical compiler implementation files. Declaration types, nested immutable let annotations, theorem term proofs and supported typed do lets use the reader. The declaration scanner is removed so nested let assignments are parsed grammatically.

**Status: candidate, not qualified yet.** Linux syntax/foundation typecheck and an 18-positive/10-negative shared native/generated parser corpus are being introduced. Generated compiler qualification is still pending. No full v7 conformance, full portable compiler self-host fixed point, performance improvement, independent kernel admission or Windows execution is claimed.

**Correction to the historical pending text below:** Linux five-v7-source closure run [38134451122](https://github.com/dwijayuda/pskernel/actions/runs/38134451122) at the base commit succeeded: five actual v7 modules plus fifteen retained Lean modules (20-module frontend/foundation closure), identical admissions/TS/JS and passing Linux runtime. Preparation 497,482ms, total 819,997ms. TS SHA `407fc682eb1798adb48701b9310edff6282bf16d24f564d494272a41840f29b3`; JS SHA `8fc8f9cacedf56e245c11ba094e58c254ae8550eea1f417a52a83816165ce9a5`. This was not the complete compiler.

Policy remains GitHub-only source operations and cloud Linux compiler CI; no local compiler builds/tests, Windows execution, kernel modifications, independent kernel/metatheory/conformance/differential suites or kernel rebuilds. v7 is the sole prospective .ps edition; original release assurance remains separate. New parser source invalidates reuse of the old frontend cache as current-source authority.

The following sections are retained historical work-state entries and may contain superseded pending statuses.

---

# PSC0 AI WORK STATE — five v7 source modules in Linux-only 20-module compiler-closure candidate

## 11 October 2026 — new active source-closure milestone

**Policy:** only Linux compiler packages are tested now; **no Windows tests** and **no independent kernel/PSKernel/metatheory/arena tests**. Windows is a static portability pattern only and must not be described as a runtime-qualified platform. PSCV0 v7 is the sole forward-looking .ps grammar; no old edition parser fallback. Retain the original kernel and release assurance design without executing it in this development loop.

**Latest real Linux source graph:** [run 38134033244](https://github.com/dwijayuda/pskernel/actions/runs/38134033244), commit c1f6b97419f85de0eb4dd09755108e1a01ab6e27, **SUCCESS**. Nine scenario combinations with Ps.Foundation.Source, Ps.Syntax.Cursor, Ps.Syntax.Token and Ps.Foundation.List alternate v7 .ps sources each yielded byte-identical canonical compiler admissions and TypeScript7: admissions SHA a8eb6c2ef657200072ba314cc45bd4df9b668a477d2239fca3a2cee9b33fa042, TS SHA 7e5682ea38342adf20b252a3eb668d727849100a22f6b2b0ff71a853b812d447. Four-module graph 65,401ms measured, 21 unique in-memory preparation states, 15 prefix reuse hits out of 36 source steps and 8 parsed module forms. Typed dependent Cursor and Token compile under either Source variant; Linux TS7/JS runtime passed. **No independent kernel/Windows tests.** An initial source parser `List Char :=` ownership issue was addressed using supported v7 adjacent `List(Char)` in one local type; the broader type-vs-field assignment parser context remains a recorded future frontend improvement, not an old-language compatibility mode.

**Current one-shot compiler-closure branch:** `psc0/pscv0-linux-source-closure-v1`, branched from that exact Linux graph-green commit. New [source selection manifest](pscv0-linux-source-closure.json) chooses all FIVE v7-authored compiler modules together: Source, Cursor, Token, Translate and List. The remaining FIFTEEN unchanged syntax/foundation modules retain their existing Lean source. New [one-pass Linux-only compiler builder](tools/abi/compiler-linux-closure.mjs) consumes the exact qualified 20-module source artifact from [38128357665](https://github.com/dwijayuda/pskernel/actions/runs/38128357665) as the generated current v7 parser. It validates all source SHA-256 identities and maps v7 modules to the historical order; uses closed AST transfer and unchanged compiler elaboration; outputs full 20-module canonical admissions and TypeScript7/JS **in one pass**. Requirement: exact bytes of all three products must match the previous already-qualified a640a2d2 one-module artifact. This is a **compiler-only product differential** and must never inherit the old artifact's independent checker/release proof claim. [Architecture and deferred Windows/kernel boundaries](docs/PSCV0_LINUX_FIVE_SOURCE_CLOSURE.md).

**Status: pending its own CI.** A new .github/workflows/psc0-pscv0-linux-closure.yml contains ONE Ubuntu job with no Windows runner, no pskernel checker imports, no kernel proof tests; it reuses immutable exact npm/toolchain artifacts. The full 20-module source closure remains an expensive **milestone-only** test; the existing sub-2-second fast-process compiler and cached graph CI remain primary routine development tools. **Do not mark five-module full source authority complete unless exact new Linux result succeeds.** Do not claim full 64-module compiler self-host fixed point or v7 general conformance.

**Next:** inspect the actual Linux-only full compiler closure, identify any first typed semantics/TS7 mismatch (do not change acceptance to make tests pass), and preserve its exact output/progress evidence. Then reconcile with concurrently advancing primary branch via non-force expected-HEAD operations only if user accepts a compiler-source promotion; leave kernel source/history untouched. Windows stays pattern-only until a future explicit request.

---

# PSC0 AI WORK STATE — v7 Cursor local-type grammar boundary

## 11 October 2026 — latest attempted dependent compiler source

**Policy remains:** only Linux compiler tests; Windows is static portability review, not actual tested status. No PSKernel/kernel soundness/metatheory tests or changes in this iteration. V7 alone defines future .ps source language; no old source compatibility.

**Cursor first attempt failed at the source reader, not typed elaboration.** Linux [run 38133808088](https://github.com/dwijayuda/pskernel/actions/runs/38133808088) (source 6687ead5d9d18bd370428745d58cabbb636a738f) completed **failure** in the eighth scenario `cursor-v7-only`, diagnostic `PSCV0-PARSE: := at 19:46; got Char`. The preceding seven scenarios ALL passed with unchanged canonical compiler admissions/TS7 SHA; their earlier [run 38133538760](https://github.com/dwijayuda/pskernel/actions/runs/38133538760) remains fully green. The issue arises when the existing bounded source reader parses `let smaller: String -> Nat -> List Char := ...`: an application lookahead wrongly interprets the terminal `Char :=` as a named-assignment start and stops the type prematurely. This is **a systematic source grammar category ownership problem**, distinct from any actual wrong compiler semantics or kernel issue.

**Current canonical v7 candidate:** use the already admitted explicit adjacent type-call spelling `List(Char)` inside that let binder, to retain the same intended type. Source doc [Cursor v7 grammar issue and plan](docs/PSCV0_CURSOR_V7_SOURCE_CANDIDATE.md) explains that native `List Char` must still be supported in correct v7 expression contexts: a later owned parser must implement proper typed-local and record-assignment delimiters, not permanently narrow the normative v7 grammar. The **new candidate is pending fresh Linux CI** until its full nine-scenario source/typed/admission/TS7 comparisons succeed. Do not weaken tests, edit history, enable old parser fallback, run Windows or kernel tests.

---

# PSC0 AI WORK STATE — fifth source candidate Cursor.ps on Linux-only graph

## Current checkpoint, October 11, 2026

**Explicit user constraints:** Linux CI only. Windows is a *static pattern review*, not an executed compatibility pass. No independent PSKernel/core checker tests, metatheory work or full fixed-point kernel runs in this self-host compiler development loop. The sole .ps language specification remains PSCV0 v7, without prior-edition compatibility.

**Fourth module source qualified at compiler-only graph level:** [38133538760](https://github.com/dwijayuda/pskernel/actions/runs/38133538760), exact source 798f1aefdc59fbdaa75bc4423741e27aec1d0e65, **SUCCESS**. Ps.Syntax.Token.ps (an inductive, function with nested pattern matches, and structure) compiled consistently as either Lean or v7 source in the 4-node Source/Cursor/Token/List dependency graph. All **seven** source combinations yielded byte-identical canonical compiler admission SHA-256 a8eb6c2ef657200072ba314cc45bd4df9b668a477d2239fca3a2cee9b33fa042 and TypeScript7 SHA-256 7e5682ea38342adf20b252a3eb668d727849100a22f6b2b0ff71a853b812d447. Compiler graph **43,694ms measured**, **15 unique prepared prefix states** with **13 actual reuse hits out of 28 steps**, 7 parsed source modules. Linux TypeScript/JS runtime smoke passed, no Windows or independent kernel tests. This remains compiler-only product equivalence, NOT the complete generated self-host compiler or an independently admitted proof output.

**Fifth candidate being attempted:** [Ps.Syntax.Cursor.ps](packages/syntax/src-ps/Ps/Syntax/Cursor.ps), 2 structures/9 functions, genuinely dependent on Source and using Unicode/UTF-8 cursor data, higher-order fuel-recursion lambdas, nested matches, option, records and conditional v7 syntax. [Source review](docs/PSCV0_CURSOR_V7_SOURCE_CANDIDATE.md). The new candidate manifest has four alternative v7 modules: Source, Cursor, Token, List; graph manifest now has **nine** source combinations, including Cursor-v7-only and all-four-v7. The complete graph must still produce identical canonical compiler admission and TypeScript bytes, and the test must run on Linux only. **New Cursor source is PENDING CI; do not count it as qualified until its actual source, elaboration and product results pass.**

**Current evidence distinctions:** Translate.ps remains the first actual 20-module generated bridge qualified in [38128357665](https://github.com/dwijayuda/pskernel/actions/runs/38128357665). Source.ps, List.ps and Token.ps are separate compiler-only equivalent source candidates and are not yet selected in that full bridge. Cursor.ps is still unqualified. This distinction must not be collapsed into claims of a full compiler fixed point. Preserve prior source graph green commit, history and all kernel branches.

**Next:** inspect the Linux-only nine-scenario CI source parser/elaboration/TS outputs. If Cursor genuinely requires an unimplemented v7 surface family, pinpoint the general grammar semantics and revise the architecture/source appropriately rather than weakening tests or enabling old-source fallback. After green, start a source-closure selection plan with incremental dependency topological ordering and full compiler-only source evidence while still deferring kernel and Windows tests.

---

# PSC0 AI WORK STATE — Linux incremental graph passed; Token.ps source candidate

## Active compiler-only development checkpoint — 11 October 2026

**Development policy (user directive):** run **Linux only**. Do not start Windows CI or PSKernel/kernel proof/consistency tests. Windows support is a **static portability-pattern review only** and remains unverified by this branch. Retain separate checked-release gates but do not execute them in the fast compiler loop. PSCV0 v7 remains the sole prospective .ps grammar; no old language reference or compatibility mode.

**Verified incremental source graph:** [Linux run 38133290733](https://github.com/dwijayuda/pskernel/actions/runs/38133290733), source 4e800e57478882616d4da28b3a88734cabdbad1e, **SUCCESS**. Four scenarios covering Ps.Foundation.Source, Ps.Syntax.Cursor, Ps.Syntax.Token and Ps.Foundation.List all produced the **same exact canonical compiler admission and TypeScript7 outputs**, with independent Linux TypeScript/JS runtime smoke. In-memory compiler preparation reused **6 out of 16 dependency preparation steps**, building **10 distinct states**, with **6 parsed source modules**; measured graph script elapsed time **31,209 ms**, excluding CI startup and cached artifact download. All 20 source closure hashes were rechecked before use. No independent kernel or Windows execution. This is a bounded compiler source dependency result, not a full compiler fixed point.

**New candidate being tried:** fourth v7 .ps module [Ps.Syntax.Token.ps](packages/syntax/src-ps/Ps/Syntax/Token.ps), currently **unqualified**; it uses v7 inductive, nested constructor matches and structure grammar. It imports Source and therefore exercises the typed dependency semantics of the Linux compiler graph. [Source candidate plan](docs/PSCV0_TOKEN_V7_SOURCE_CANDIDATE.md). Updated [candidate registry](pscv0-fast-candidates.json) includes Token (3 declarations) alongside Source (2) and List (10). Updated [graph manifest](pscv0-fast-graph.json) adds Token-only, Source+Token and all-three-v7 combinations. The exact new Linux CI must show **seven scenarios with identical full compiler admission and TypeScript output**; do not claim qualification from a previous run.

**Next:** check the generated frontend's actual v7 Token.ps parser and typed constructor-pattern handling under the fast Linux workflow. Any failure is an implementation/grammar boundary to diagnose against v7, not a reason to weaken tests or enable an older .ps source mode. If green, record source SHA/equality and explore v7 Cursor.ps (first lexical runtime source module with dependent Source). Keep the full 20-module generated bridge stable; no kernel build or Windows job.

---

# PSC0 AI WORK STATE — Linux-only incremental compiler preparation graph

## 11 October 2026 — active fast development milestone

**User decision:** only **Linux** compiler tests now. No Windows CI runs and no independent PSKernel/consistency/arena/kernel-metatheory tests in this development phase. Windows is handled as **static portability patterns**, explicitly *not a Windows pass*. Keep production independent-checking obligations intact for a future deliberate release milestone. The sole prospective ProofScript grammar remains complete PSCV0 v7 (reference SHA-256 843940bd7f6a9b286e80b01d8c891a7e01b8868a9de7b05833fce32d49be6cd5); no old source compatibility target.

**Stable baseline (actual evidence):** fast compiler-only run [38131347281](https://github.com/dwijayuda/pskernel/actions/runs/38131347281) SUCCESS, latest code check SHA 0cde1e2e3707e6550431d30e589e785b46fcdc72. The exact cached generated 20-source frontend is from the previously fully qualified 38128357665 bridge at source a640a2d22adeabd4ca7919839a8991667bcc3eae. Separate compiler-only v7 candidates are Ps.Foundation.Source (2 structures) and Ps.Foundation.List (10 recursive definitions); each matched original retained Lean compiler's complete canonical admission/TS7 products byte-for-byte under the same compiler. Ps.Syntax.Translate.ps remains first source module qualified in the actual 20-module generated bridge. Neither other candidate has been promoted into that full source closure.

**New architectural work:** an **in-memory topological source graph** (no disk-state deserialization or checker authority) to prepare dependencies and v7-source variants without repeated elaboration of unchanged prefixes. [Source graph config](pscv0-fast-graph.json): roots Ps.Syntax.Cursor, Ps.Syntax.Token and Ps.Foundation.List. Actual dependency edges are Cursor→Source and Token→Source; List independent. Four variants are historical Lean baseline, List-v7 only, Source-v7 only, and both Source/List-v7. The selected candidate's v7 parser produces a source AST transferred through the validated versioned recipient-owned codec. Each variant must produce identical compiler admissions and TypeScript7 bytes in the **same dependency closure**. Prefix keys include previously selected sources, exact source SHA, module identity, and pinned generator/recipient toolchain; only state values in the single CI JavaScript process are memoized.

**New code, pending validation:** [qualified-cache.mjs](tools/abi/qualified-cache.mjs) checks the same 20 cached source hashes, builder identity and v7 reference, [compiler-graph.mjs](tools/abi/compiler-graph.mjs) calculates a closed import graph and reuses pure compiler state, and [Linux-only graph design](docs/PSCV0_LINUX_INCREMENTAL_COMPILER_GRAPH.md) states source assumptions, Windows portability patterns and no-kernel boundaries. The fast Linux workflow's second pass replaces redundant independent single-module compilations with these four dependent source variants and one TypeScript7/Node JS runtime smoke. **DO NOT claim this new scenario graph passed until live CI confirms it.** Existing three-module candidate evidence is retained separately.

**Immediate next step:** review actual Linux-only fast CI and inspect exact graph admission/TS source discrepancies or runtime errors. Avoid test patches: diagnose wrong source import topology, typed AST correctness, source printer group ownership and correct elaboration environment. If green, record unique/hit prefix counts and measured timings, then migrate Ps.Syntax.Cursor.ps only after confirming dependency-closure semantics and exact v7 grammar. Do not run Windows and do not change kernel.

---

# PSC0 AI WORK STATE — three v7-authored compiler modules, fast development only

## Latest verified checkpoint — October 11, 2026

**Current branch:** psc0/pscv0-compiler-fast-loop-v1. **Sole language reference:** exact PSCV0 v7 SHA-256 843940bd7f6a9b286e80b01d8c891a7e01b8868a9de7b05833fce32d49be6cd5. No backward-compatibility parser or historical language reference is required for new code.

**New observed compiler-only CI:** [run 38131142962](https://github.com/dwijayuda/pskernel/actions/runs/38131142962), source commit 4c79d8854d453b27111e8675cd4240fc2de58112, **SUCCESS**. The one reusable [multi-module source manifest](pscv0-fast-candidates.json) qualified **both** alternate PSCV0 v7-authored source files against their unchanged historical Lean predecessor using exactly the same retained PSC0 compiler, generated v7 frontend and versioned recipient-owned AST schema. Source module: Ps.Foundation.Source, **two structure declarations**, 236 AST nodes, admission stream SHA 976e966131f71d2ab80aac725cd236be1790ca6538d11390202e1532b4269119, TS7 SHA 851d74e325381ee236632853296815c0d1f2e1f4630722bcf1bf68cfd2b47e77, both byte-identical to Lean baseline; 634ms compiler differential. List module: Ps.Foundation.List, **ten generic recursive definitions**, 4,882 AST nodes, admission SHA 88975c455e2d8a69d7123f0a320306c65897e0022fa90b3913eab2f946b0a7b6 and TS7 SHA efa2692bf423d9cbfb7115780d1e299db19a8ee431e4c63d7489ff05e6f37b9d, both byte-identical to Lean baseline; 7,680ms. Total multi-source compiler differential **8,318ms**, excluding CI provisioning/tool installation. **No independent kernel, kernel proof suite, checker conformance or new fixed-point cycle ran.**

**Total bounded source migration evidence so far:** Ps.Syntax.Translate.ps remains the FIRST qualified real 20-module generated bridge candidate ([full Linux/Windows/RC4 run 38128357665](https://github.com/dwijayuda/pskernel/actions/runs/38128357665)); Source.ps and List.ps are SECOND and THIRD *separately checked source-product-equivalence candidates*, NOT selected into that full bridge. Do not aggregate their separate cheap results into a claim of three modules already self-hosting the current full compiler. The original Lean baselines are immutable and still selected outside the bounded first-module candidate.

**Efficiency achieved:** fast compiler-only generated AST -> elaboration -> TS7 -> JS runtime step measured **1,411ms** compiler-process execution on [38131142962](https://github.com/dwijayuda/pskernel/actions/runs/38131142962), full two-module source differential **8,318ms**. Cached 20-module parser remains valid only if all source raw SHA-256 identities match the qualified artifact; any changed frontend source must fail with FAST_CACHE_STALE and require native compiler-source typecheck plus deliberate future regenerated self-host milestone. These are compiler development results; all release-time independent checking/verification obligations remain unchanged but are not executed by this loop.

**Architectural improvement:** migration source candidates are chosen in [pscv0-fast-candidates.json](pscv0-fast-candidates.json) and validated by the ONE generalized [compiler-source-differential.mjs](tools/abi/compiler-source-differential.mjs). It is intended to replace obsolete module-specific test scripts to avoid duplicate logic and chase individual test quirks. Strict exact admissions and TS output compare unchanged. See [fast development design](docs/PSCV0_COMPILER_ONLY_FAST_DEVELOPMENT.md) and [Source candidate evidence](docs/PSCV0_THIRD_MODULE_FOUNDATION_SOURCE.md).

**Completed cleanup:** obsolete single-module List differential runner retired from active tree (history preserved), replaced by the generic source manifest and differential. The consolidated [fast compiler-only CI 38131347281](https://github.com/dwijayuda/pskernel/actions/runs/38131347281) **PASSED** at commit 0cde1e2e3707e6550431d30e589e785b46fcdc72 after cleanup; no independent kernel tests ran.

**Next recommended compiler-only actions:** extend candidate manifest to another useful source family only after verifying its dependency imports and typed environmental closure; build a source-graph-aware, cached preparation prefix for dependent compiler modules; improve v7 source readability/trivia/diagnostic origins without reintroducing older parser compatibility. Deliberately schedule full candidate compiler source authority/fixed-point requalification separately, and avoid independent kernel tests until explicitly requested.

---

# PSC0 AI WORK STATE — manifest-driven v7 compiler-only multi-source migration

## Current checkpoint (11 October 2026)

**Workstream:** self-host compiler packages only. No PSKernel implementation, kernel differential tests, kernel metatheory or independent checker in routine development. Language specification: exact sole PSCV0 v7, no prior ProofScript grammar compatibility.

**Verified second v7-authored compiler module:** [38130835390](https://github.com/dwijayuda/pskernel/actions/runs/38130835390) **SUCCESS** at source d01f9bd470a2fd58ae5bcc09d5cb7993aa4c984d. The conservative Ps.Foundation.List.ps candidate has ten generic recursion/list operations, **4,882** AST nodes and original/candidate compiler products are **byte-identical**: canonical admission SHA-256 88975c455e2d8a69d7123f0a320306c65897e0022fa90b3913eab2f946b0a7b6 and TS7 SHA-256 efa2692bf423d9cbfb7115780d1e299db19a8ee431e4c63d7489ff05e6f37b9d. Baseline Lean 66 physical lines, v7 source 90: **do not claim code-length improvement** from this first conservative conversion. Compiler differential 670ms parse + 5,793ms preparation, excl. runner provisioning. **Zero kernel tests** and no new full fixed point. The initial error from v7's strict APP-02 rule was resolved by using the *actual v7 explicit adjacent type-call syntax*, not by weakening the parser.

**Next architectural milestone, now authored:** a single [closed candidate manifest](pscv0-fast-candidates.json) and [manifest-driven differential tool](tools/abi/compiler-source-differential.mjs) replace individual test harnesses. It handles existing List and new third candidate [Ps.Foundation.Source.ps](packages/foundation/src-ps/Ps/Foundation/Source.ps), two structure declarations. For each module, it validates source identities and correct declaration counts; parses current v7 source with the cached exact source compiler; uses receiver-owned AST transfer; elaborates both the original Lean and v7 source through the same retained PSC0 compiler; compares canonical admission and emitted TS7 byte-for-byte, and reports elapsed time and first differences. This is **compiler-only product equivalence**, not a production verified build. The third candidate is **pending actual cloud CI** and not promoted to authoritative full compiler source.

**Next:** observe fresh rapid compiler-only workflow result for both candidate modules, diagnose any actual AST or source-grammar mismatch at its invariant rather than patching expected outputs. After green, consider the next meaningful source feature family (e.g. typed compiler APIs with source comments and do-based error propagation), but keep parser/trivia/source span obligations explicit. Only later deliberately construct a new 21/22-module generated self-host candidate and fixed-point work with independent release gates, without requiring kernel test runs during the current loop.

**Stable fast-loop baseline:** [38130403756](https://github.com/dwijayuda/pskernel/actions/runs/38130403756) passed **1,723 ms compiler-process** time for 20 source file cache identity, 2,440 existing Translate.ps AST nodes and three compiled TS7/Javascript programs; native source typecheck [38130403714](https://github.com/dwijayuda/pskernel/actions/runs/38130403714) green, both without PSKernel tests. Full generated bridge [38128357665](https://github.com/dwijayuda/pskernel/actions/runs/38128357665) fully green at ABI source commit a640a2d2; this stronger historical result cannot automatically qualify new candidate source identities.

---

# PSC0 AI WORK STATE — fast compiler-only loop qualified; second .ps module candidate

## Active checkpoint (11 October 2026)

**Fast compiler-only inner loop is operational.** At exact commit 2f1d9169b12bd689fa109071a19d3b5cd58708fd, GitHub [run 38130403756](https://github.com/dwijayuda/pskernel/actions/runs/38130403756) **PASSED**. The measured **compiler process** took 1,723 milliseconds, excluding CI provisioning/artifact download and retained compiler installation. It validated all 20 cached frontend source hashes, all 2,440 selected Translate.ps source nodes, exact sole v7 document, source AST transfer, actual compiler elaboration, TypeScript 7.0.2 emission and three JS results 3, 8 and 4. Four v7-only source refusals passed. **Zero** new frontend generation, independent kernel checks, checked-admission provider calls or kernel-proof suites. Reports explicitly state kernel-admission false, not a verified release. The separate [native syntax/foundation CI 38130403714](https://github.com/dwijayuda/pskernel/actions/runs/38130403714) also **PASSED** with five portable source modules, no PSKernel package tests. Both are qualified *development lanes only*.

**Second migration candidate now authored, not promoted:** [Ps.Foundation.List.ps](packages/foundation/src-ps/Ps/Foundation/List.ps) maps the ten existing generic list helper functions from the immutable 66-line Lean file. The v7 source candidate uses typed comma groups, implicit binders, match and application syntax. Its purpose is proving reusable compiler-source migration breadth, **not claiming that mechanical transliteration is shorter**. A new [compiler-only differential](tools/abi/foundation-list-probe.mjs) must parse the candidate with generated PSCV0 JS, reconstruct the receiver-owned syntax ABI, elaborate both the candidate and original Lean source with the same retained compiler and demand exact canonical admissions and TypeScript7 output. The new result is **PENDING CI**. Investigate substantive model/AST discrepancies systematically; do not change tests to accept unequal semantics.

**Efficiency rule:** routine compiler-source/ABI fixes invoke the cached frontend compiler-only tier (currently 1.7 seconds measured compiler process, not total CI wall-clock); changes to the 20-file parser/frontend closure fail closed on stale source hash and require native compiler-source typechecks plus intentional regenerated milestone bridge. The independent kernel/checked release gates remain unchanged and are not part of this development loop.

**No full compiler self-host claim:** only the first Translate.ps module was qualified by the 20-module generated bridge [38128357665](https://github.com/dwijayuda/pskernel/actions/runs/38128357665), and full source-fixed-point C0-C3, general v7 semantics and complete compiler proof work remain later. Preserve user decision of v7 as sole language reference and zero backward-compatibility requirement for older ProofScript source.

---

# PSC0 AI WORK STATE — Compiler-only rapid development loop

## Current checkpoint: 2026-10-11

**User instruction:** for now work on the self-host compiler packages only, prioritize the most efficient iteration path, and **do not run independent PSKernel tests or kernel metatheory tasks in the fast loop**. This is not a release-policy change. PSCV0 v7 remains the sole forward-looking ProofScript language reference; no older .ps grammar compatibility is required.

**Production-like baseline established before optimization:** [full generated 20-module bridge run 38128357665](https://github.com/dwijayuda/pskernel/actions/runs/38128357665), source a640a2d22adeabd4ca7919839a8991667bcc3eae, **overall SUCCESS** including Linux 44 bridge + 12 authoring tests, Windows and Lean RC4 reference proof gate. That exact source imported the generated v7 PSCV0 parser, crossed the validated closed source-AST ABI into the retained compiler without old Lean text reparse, elaborated the first actual Translate.ps module, emitted the checked candidate JS and independently tested the grouped call; no complete compiler 64-module .ps fixed point was claimed.

**Current branch:** psc0/pscv0-compiler-fast-loop-v1, separate from psc0/pscv0-v7-abi-v1. Its new [fast compiler-only design](docs/PSCV0_COMPILER_ONLY_FAST_DEVELOPMENT.md) and [GitHub CI workflow](../.github/workflows/psc0-pscv0-compiler-fast.yml) reuse only that exact full-run surface-bootstrap artifact. A cheap script checks all 20 original source SHA-256 identities and exact retained toolchain, parses the current .ps compiler module, validates and reconstitutes its AST, executes the real PSC0 elaborator/TypeScript7/JS runtime on representative typed programs and writes a timed report.

**No kernel in fast lane:** the script intentionally does not import pskernel-core or call checkCanonicalAdmissions. It may serialize compiler admission data for comparison but does **not** claim an independently checked module. Reports must explicitly carry independentlyKernelAdmitted=false, kernelOrKernelProofTestsExecuted=false, fullV7Conformance=false, fullSelfhostFixedPoint=false. Native source typecheck workflow [compiler-only native](../.github/workflows/psc0-pscv0-compiler-native.yml) builds only PsSyntax/PsFoundation and the five portable language modules when their Lean source changes; it does not run PSKernel tests. Full generated bridge/Windows/RC4 qualifications are reserved for milestones and verified release actions, not routine edits.

**Cache invariant:** any change to one of the 20 cached generated-source Lean modules causes FAST_CACHE_STALE. Never use the previous v7 generated JavaScript bundle as proof of a newly changed parser or old-language fallback. Rerun the full generator intentionally and pin a new immutable artifact after a source-closure change. Changes to the current authored .ps module itself are read directly from GitHub and can receive fast source/AST/typecheck/TS7 runtime feedback while grammar remains unchanged.

**Current acceptance status:** these new fast workflows are created and require their **own** observed CI success before claims of working optimized feedback. The earlier full run and cheap ABI model already passed; the latter had 2,440 selected Translate source nodes and 257 standalone AST nodes. Do not conflate it with a full compiler-source or kernel proof. Preserve all branches/history, current Rust-target proposal on primary and user instructions.

**Next actions:** check the initial fast CI for actual elapsed time and correctness; research any refusal at the parser/typed boundary, not by altering fixture expectations. Keep kernel work separately dormant. Once the fast tier is green, use it to iterate through next cheap v7 grammar/portable source improvements and .ps compiler modules. At promotion explicitly do full source-identity qualification and record actual results before merging.

---

# PSC0 AI WORK STATE — v7 closed AST ABI and generated compiler integration

## Latest milestone, October 11, 2026

**User intent is unchanged:** `psc0/PSCV0_LANGUAGE_REFERENCE.md` revision **v7** is the sole forward-looking `.ps` language specification, SHA-256 `843940bd7f6a9b286e80b01d8c891a7e01b8868a9de7b05833fce32d49be6cd5`; **no backward compatibility** for earlier PSC1, ps-0.9-r3, or older PSCV0 language references is needed. Historical compiler seeds/source and receipts are immutable bootstrap/provenance, not supported new grammar options. No kernel modifications or public/npm compiler switch in this workstream.

**Root-cause run:** [38125532982](https://github.com/dwijayuda/pskernel/actions/runs/38125532982), exact source `6e811feabba89bf8ea3ebbf50916453169d100ed`, completed **failure** after successful generated 20-module bootstrap and eight actual first-module correspondence proofs. The source bridge's newly direct PSCV0 AST failed in retained compiler elaboration with `invalid ProofScript constructor tag` because generated frontend and retained compiler inhabit **separate JavaScript private-Symbol ADT domains**. A direct `PsSyntaxModule` object cannot simply cross between their two module instances. No source/kernal consistency claim follows from this failure.

**Architecture fix:** a closed, pinned, versioned source AST interop codec lives at [`tools/abi/transport.mjs`](tools/abi/transport.mjs), contract `psc0-pscv0-source-ast-transport/1`. It reconstructs recipient-owned `List`/`Option`/syntax-term/declaration union constructors with recipient factories after full source-field, source brand, constructor symbol-identity, depth/list/byte/span/fuel and exact reference validation. It deliberately does not share or forge private Symbols. Its output is still **untrusted syntax**, not a proof token: caller MUST invoke unchanged source elaboration, canonical admissions and independent kernel check. [Architecture/limitations](docs/PSCV0_V7_CROSS_RUNTIME_AST_ABI.md).

**Verified cheap real cloud evidence:**
- [38127436381](https://github.com/dwijayuda/pskernel/actions/runs/38127436381) passed inspecting actual generated 20-module artifact and retained compiler exports; mismatched Symbol identities confirmed. This is empirical runtime/ABI source analysis, not a proof that all constructs work.
- [38127922986](https://github.com/dwijayuda/pskernel/actions/runs/38127922986) **passed** validating/rebuilding **257** typed source nodes of v7 `(add(1))(2)`; existing retained compiler elaborated it, independent kernel accepted canonical admissions, TypeScript emitter produced output **without an old Lean text parse**; wrong-module tags and extra fields were rejected.
- [38128089427](https://github.com/dwijayuda/pskernel/actions/runs/38128089427) **passed** source schema coverage on the exact authoritative `Ps.Syntax.Translate.ps` module: **2,440** AST nodes, source SHA-256 `938288af9c8476d592fc69c4e6f2c01ecb8e1f371fdd5bac1f789a3097710428`. It did **not** run that module's full prepared prefix/elaboration in isolation.

**Now integrating the real bounded compiler source** on `psc0/pscv0-v7-abi-v1` (forked from `psc0/pscv0-v7-app-model-v1` commit `6e811fe...`). The generated candidate builder now decodes the actual `Translate.ps` source AST with versioned source/runtime identity; passes **recipient-owned** `PsSyntaxModule` to pure `psCompilerPreparationStepParsedWithOrigins`; leaves readable Lean as independently checked projection; adds precise ABI receipt to build-report, source-content/no-fallback enforcement and generated JS/Windows APP-04 runtime/checker test. All prior 43 bridge and 12 authoring tests, Lean RC4 proofs, full builder toolchain, semantic checks and immutable 69-file historic source gate stay in place. **DO NOT CLAIM changed 20-module bridge success until its new CI completes on exact new source commit.**

**Already green predecessor evidence, not transferable:** primary `psc0/pscv0-readable-selfhost-v1` [38122341583](https://github.com/dwijayuda/pskernel/actions/runs/38122341583), source `2394fc7e`, Linux/Windows 43+12 tests each and RC4 proofs; native source APP-04 positive and eight axiom-free formal model lemmas [38124980640](https://github.com/dwijayuda/pskernel/actions/runs/38124980640) at `0e664233`. These do not certify newly changed artifacts.

**Next checkpoint:** get actual new [PSC0 portable bridge](https://github.com/dwijayuda/pskernel/actions/workflows/psc0-pscv0-bridge.yml) Linux generation, source provenance, kernel/runtime and Windows/RC4 results; resolve any *real* ABI/elaboration semantic mismatch systematically rather than patching negative tests or relying on old Lean parsing. Then compare to current primary HEAD (includes concurrent separate Rust-target documentation commit) and preserve both histories; integrate with non-force expected-HEAD only after evidence. Update work state with actual outcome. Unqualified v7 full Standard/verified contracts, 64-module source migration, self-host C0/C3 and kernel consistency remain separate work.

---

# PSC0 AI WORK STATE — direct generated v7 AST handoff and APP-04 verification

## Current milestone: 2026-10-11 — source model passed; generated direct-AST pipeline pending

**Sole language authority remains PSCV0 v7**, SHA-256 `843940bd7f6a9b286e80b01d8c891a7e01b8868a9de7b05833fce32d49be6cd5`, Lean pin `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`. No old PSC1/older PSCV0 `.ps` compatibility profiles or parser fallback. Historical fixed-point sources are immutable qualified bootstrap artifacts, not new source-language requirements.

**Proved model / native positive:** abstract APP-04 eight-lemma model checked axiom-free [38124512189](https://github.com/dwijayuda/pskernel/actions/runs/38124512189). Source-owned recursive application printer in `Ps.Syntax.Pscv0.Surface.lean` passed [38124980640](https://github.com/dwijayuda/pskernel/actions/runs/38124980640), source `0e664233f90895e6baa90d377b2821e5fd4d01ce`. Exact RC4 accepted the actually produced `(add 1) 2` and checked the generated `grouped = 3` proof with no axioms. The `.ps` printer/parser preserved nested grouping; mixed native/postfix calls were tested. This is a real native source/Lean correspondence, **not** a generated JS backend proof.

**Architecture/root fix:** avoid the historical Lean reader as a second semantic compiler input. `Ps.Syntax.Pscv0.Module.psPscv0LowerModule` already supplies `PsSyntaxModule` from the **generated PSCV0 JS** source parser. The qualified old compiler exposes a pure `psCompilerPreparationStepParsedWithOrigins(state, sourceModule)` and elaborates with `psElabModuleWithOrigins`; it does not require a text parse. The new bridge now passes this owned, untrusted syntax module **directly** to existing elaboration/preparation, with a mandatory no-fallback check on the `pscv0` source kind. Readable Lean remains a separate independently checked view. Source imports must exactly match the frozen selected module's imported source closure during first-module migration; full source/module manifest identity remains a later gate. No kernel or trust-policy change.

**New executable acceptance under development:** generated JS `B.psPscv0ParseSource` + `B.psPscv0LowerModule` crosses into retained compiler `C.psCompilerPreparationStepParsedWithOrigins`, followed by complete typechecking, canonical admissions, independent `pskernel-core` check, TypeScript 7.0.2 emission/compilation, and actual JavaScript runtime `grouped = 3`. The exact same test runs on Linux and Windows and records checked source/admission/runtime digests. This is an *architectural end-to-end* validation of the semantic AST boundary, not a test-output change. Full generated 20-module bridge and RC4 correspondence are required before declaring the changed source qualified; no results claimed yet.

**Stable prior M1:** integrated v7-only branch [38122341583](https://github.com/dwijayuda/pskernel/actions/runs/38122341583) completed Linux/Windows/RC4 successfully at source `2394fc7d`. New model/direct-AST source needs independent qualification. No complete 64-module v7 `.ps` compiler migration, new public CLI, full Standard digest or C2/C3 compiler-only fixed point yet.

**Next:** examine actual newly triggered cloud CI rather than assuming constructor ABI compatibility across the generated PSCV0 and retained compiler runtimes. If in-memory cross-runtime data representation fails, establish a canonical typed-data ABI and source-derived proof/admission identity rather than falling back to the legacy Lean text parser. Preserve both old validated branch and its proof history.

---

# PSC0 AI WORK STATE — model-first v7 source APP-04 printer implementation

## 2026-10-11 source compiler milestone in progress

**Validated model:** [run 38124512189](https://github.com/dwijayuda/pskernel/actions/runs/38124512189) **SUCCESS**, pinned Lean 4.35.0-rc4 commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`; all **eight** abstract application-grouping theorems reported **no axioms**. This is a model, *not* the production compiler semantic preservation theorem.

**Systematic architectural adjustment:** The goal is canonical `.ps` source (sole v7 grammar) → semantically faithful Lean projection → pinned Lean elaboration/checking. PSC0 need not implement a universal reverse `.lean`→`.ps` parser to self-host or prove its source transformations. The failed experimental reverse conversion for a grouped Lean head is retained as an **optional migration-tool gap**, not silently patched or used to require preservation of old source-language parsing behavior. The previously qualified first-module *bounded* source roundtrip remains valid on its original recorded source. This is an acceptance-contract clarification, not a waiver of source soundness or proof closure.

**New portable production work (model branch, pending CI):** selected APP-04 application rendering in `Ps.Syntax.Pscv0.Surface.lean` is now a compositional, bounded traversal of nested `PsSyntaxTerm.app` source trees, parenthesizing non-atomic callee/argument subtrees; no special error-fallback on compound heads, flattened AST head, copied historical Lean parser, or kernel changes. `scripts/Pscv0App04CoreSmoke.lean` checks v7 PS canonicalization, compares source APP grouping, prints `(add 1) 2` from actual v7 `(add(1))(2)`, then hands the generated Lean theorem `grouped = 3` to the immutable RC4 toolchain. This is a typed positive correspondence gate as well as a syntax-ownership gate. Its exact compiled and generated test results have not yet been observed. The separate full generated JavaScript/Windows bridge still requires a new run after source changes.

**Source authority and trust:** The model branch `psc0/pscv0-v7-app-model-v1` inherits primary `8213f02e`. The public compiler and kernel remain unchanged; no old `.ps` compatibility mode, executable plugin authority, release, 64-module migration, or C2/C3 requalification has occurred. Keep the source-only printer changes separate until RC4 native, actual generated JS and Windows validations are complete.

---

# PSC0 AI WORK STATE — APP-04 ownership model (new isolated research branch)

## 2026-10-11 abstract-model checkpoint

**Branch:** `psc0/pscv0-v7-app-model-v1`, cut from primary at `8213f02ea3874f329c96855f46638717219b26e8`. This branch is deliberately separate from the failing `psc0/pscv0-v7-call-ownership-v1` prototype and the green main compiler-bridge qualification. Future `.ps` grammar remains **only PSCV0 v7**; no older ProofScript syntax/backwards-compatible parser mode is part of the target.

**New diagnostic conclusion:** The `psPscv0TranslateReadable(false,true,grouped)` call fails while **reading the generated Lean code**, before it can print ProofScript. In the older `Ps.Syntax.ParseLean` code, grouped initial terms do not consistently own a following application suffix, and `psLeanApplicationWithArgument` eagerly flattens an application spine. This explains why more tweaks to PS printing alone are an inadequate general fix; the exact class of all contexts must still be established with executable checks. Historical compiler source is protected by the 69-file immutable source-closure gate, so do not casually modify the old reader to pass an isolated fixture.

**New deliverables:** [PSCV0 APP-04 source-ownership architectural model](docs/PSCV0_V7_APPLICATION_OWNERSHIP_MODEL.md) plus [pinned Lean 4.35.0-rc4 abstract application-tree model](test/pscv0/reference/ApplicationOwnershipModel.lean), with eight abstract source/core grouping facts. This proves only construction-level properties, **not the correctness of the actual parser or generated backend**. A new targeted GitHub CI job checks Lean version, exact pin, theorem dependencies and lack of axioms; **no CI claim is made until its actual result is observed**.

**Production design:** maintain the source-only `group`, native-whitespace app and adjacent-postfix app boundaries through a structured, precedence-owned PSCV0 syntax reader. Only lower them to existing normal `PsSyntaxTerm.app` after ownership is known. Give the Lean readable projection its own selected parser context; never use old `.ps` grammar fallback, hidden span heuristics, flattened-head reconstruction, untyped text rewrites or new kernel primitives. Printer correspondence must be tested at the AST partition level and typed Lean admission separately; preserve comments/origins, fail-closed limits and pinned environment.

**Known passing bounds:** first PS compiler module on 20-module generated bridge [run 38120695522](https://github.com/dwijayuda/pskernel/actions/runs/38120695522) passed all Linux/Windows/RC4 lanes at source `8603f7dc`. Integrated v7-only policy [run 38122341583](https://github.com/dwijayuda/pskernel/actions/runs/38122341583) likewise **overall passed** at source `2394fc7d`. Still not complete v7 or full 64-module compiler source fixed point. The experimental APP-04 [run 38122847916](https://github.com/dwijayuda/pskernel/actions/runs/38122847916) passed only a narrower source case, while deeper [38122996299](https://github.com/dwijayuda/pskernel/actions/runs/38122996299) and [38124012051](https://github.com/dwijayuda/pskernel/actions/runs/38124012051) revealed the grouped Lean-reader obstruction.

**Next gate:** first prove the abstract APP-04 model under RC4 via CI. Then implement an owned portable source parser/printer with explicit group ownership (not a test-specific fallback) and compile it with existing retained generated source pipeline; compare actual source AST partition, Linux/Windows generated semantics and RC4 kernel-accepted terms before integration into main. No source/CLI/seed switches, old receipts rewrites or kernel edits occur in this model branch.

---

# PSC0 AI WORK STATE — v7-only source policy integrated on primary branch

## Integration checkpoint — 2026-10-11

Primary development branch `psc0/pscv0-readable-selfhost-v1` was **non-force fast-forwarded** from successful bounded first-module checkpoint `8603f7dcf6af6295335c4e11912a10aac86c85a4` to `2394fc7e8ea327869b6cbe57ef41417de82e5408`. This incorporates the separate v7-only parser and historical-source-document work *without altering the already-qualified old evidence* or touching the independent kernel proof branch. User instruction is explicit: **PSCV0 v7 is the only new `.ps` language reference; no older PSC1/PSC0/previous PSCV0 source-language backwards compatibility is needed.** Frozen historical bootstrap seeds are reconstruction evidence only, not a compatibility/fallback feature.

**Exact new-HEAD CI launched:** native source/10-policy-refusal test [38122341557](https://github.com/dwijayuda/pskernel/actions/runs/38122341557) and generated 20-module/Windows/RC4 candidate test [38122341583](https://github.com/dwijayuda/pskernel/actions/runs/38122341583), both source `2394fc7d`, were **in progress** at this checkpoint. Run [38120695522](https://github.com/dwijayuda/pskernel/actions/runs/38120695522) already **fully succeeded** at original source `8603f7dc`, but its result must NOT be carried forward automatically to the changed v7-only parser source. Check the new CI's actual final conclusions before marking it qualified. An updated document-only checkpoint must not be mistaken for new compiler generation.

**Next:** inspect source and bridge logs; if the new integrated candidate passes, record the exact 43 generated bridge test results (prior 38 plus five new v7-only source refusals), twelve authoring/arrow tests, Windows identities and RC4 proof dependencies. Then begin the next small portable source feature/trivia-mapping milestone, not a premature whole-compiler `.ps` switch or public npm release. Preserve no-fallback admission and artifact gates.

---

# PSC0 AI WORK STATE — first PSCV0 v7-authored module: complete bounded CI; v7-only extension pending integration

## Latest proven checkpoint — 2026-10-11

**Only prospective ProofScript source language:** [PSCV0 v7](PSCV0_LANGUAGE_REFERENCE.md), exact SHA-256 `843940bd7f6a9b286e80b01d8c891a7e01b8868a9de7b05833fce32d49be6cd5`. There is no required backwards compatibility with any older PSC1, old PSCV0, or ps-0.9-r3 `.ps` grammar. Historical old bootstrap code and receipt archives remain for reconstruction, not parser fallback or alternate v7 semantics.

**NEW ACTUAL RESULTS — [run 38120695522](https://github.com/dwijayuda/pskernel/actions/runs/38120695522), immutable source [`8603f7dcf6af6295335c4e11912a10aac86c85a4`](https://github.com/dwijayuda/pskernel/commit/8603f7dcf6af6295335c4e11912a10aac86c85a4):** **overall SUCCESS** (Linux generated bridge job `114414631646`, Windows `114418588840`, Lean RC4 reference `114418588824`). The former 900-second generation timeout was solved at the declared 1600-second generation budget; this actual run completed with one `Translate.ps`-authored module among the generated 20-module syntax/foundation candidate and **13 shared-prefix modules prepared once**. Linux **38/38** bridge tests plus **12/12** candidate authoring/arrow tests passed; Windows likewise **38/38 + 12/12**. Each platform recorded **36** old/new API comparisons (**24 accepted**, **12 refused**), exact source/readable/lowered replay, `noFallback=true`, ten kernel-accepted fixture functions, first-error and runtime results. Generated candidate JS SHA-256 `fa5728347204ea683c6a22f900f2a2474d8f178ae0b093a01d141c2557605e27`; authoritative module source SHA-256 `938288af9c8476d592fc69c4e6f2c01ecb8e1f371fdd5bac1f789a3097710428`; independent fixture admission SHA-256 `6f14a42e22bf0e0fb41fbe4af07ada5bcbc82b21776e7f6b40149176d629ddb2` matched on both platforms.

Lean 4.35.0-rc4 checked the generated `pscv0_do_correspondence` fixture with **no axioms**. Both actual readable and lowered candidate API versions were proved equal to all four original translation APIs for **every String input**, yielding eight concrete equations with **exactly inherited `[propext]`** assumptions (and no new ones); the two generic error-map algebra lemmas plus generated error mapper had **no axioms**. Evidence is *module correspondence* and finite generated bridge tests, NOT universal translator correctness, JS backend semantic preservation or kernel consistency.

Artifacts of successful run: generated Linux/bridge `11695282564` (ZIP SHA-256 `e9aa3ac1089bed9465fd01e83bdf5a6facea673fe9de1d289840738003d49e57`), native authoring `11695122822` (`6d223b0ac47382e99fe2e0d811ad8a41564bd64a6df1e87e25d6239a73ace564`), Windows `11695114280` (`6085c35c27418bdbf72425d16f5c915ebf6f1b34019815461cab6e0cd54813bb`), independent RC4 `11695019450` (`861a9f197df2f4f2ce5fae8a4eaa325e877c718a7516364e533339ecf940d46c`). These are scoped to exact `8603f7dcf6af6295335c4e11912a10aac86c85a4` source, not necessarily the next policy-integrated SHA.

**Separate v7-only policy candidate:** `psc0/pscv0-v7-sole-source-policy-v1`, initial implementation `b7c6211b`. Explicitly closes the command dispatch to selected current v7 forms and refuses obsolete source `partial`, `unsafe`, `axiom`, `verify`, `ghost` and unselected arbitrary command syntax. Native CI runs [38121307578](https://github.com/dwijayuda/pskernel/actions/runs/38121307578) and [38121717749](https://github.com/dwijayuda/pskernel/actions/runs/38121717749) **passed** (5 round trips, 10 refusals, zero-axiom native do theorem; second run also v7 byte-identity preflight). The source policy adds five more generated rejection cases. **Those changed generated JS tests have NOT yet run**, so they cannot inherit the prior `8603f7dcf6af6295335c4e11912a10aac86c85a4` qualification. The current branch has historical-doc supersession notices and [next module candidates](docs/PSCV0_V7_NEXT_SOURCE_MIGRATION_CANDIDATES.md).

**Immediate next action:** after this source-policy branch and the exact successful `8603f7dcf6af6295335c4e11912a10aac86c85a4` checkpoint are reconciled, fast-forward/integrate into primary `psc0/pscv0-readable-selfhost-v1` with a non-force expected-HEAD lease; no unrelated kernel source changes. Run the full generated 20-module Linux/Windows/RC4 candidate job **again** for the changed source. Do not call the source-policy-integrated SHA M1-qualified before observing that distinct run. After that, move to source-trivia/source-span preservation and representative next compiler modules, and only later full 64-module v7 `.ps` source authority with a deliberately qualified compiler-only C0→C1→C2→C3 fixed point. Old `.lean` bootstrap source is not a language compatibility lane.

**Still NOT established:** full PSCV0 v7 grammar/Standard environment digest, v7 proof/verified effects, arbitrary source comments formatting, generated JS universal semantic theorem, full compiler-source migration, installed compiler/kernel fixed point, kernel consistency proof, public npm release or merged main. Never turn this first-module milestone into any of those stronger claims.

---

# PSC0 AI WORK STATE — v7-only source-policy checkpoint

## 2026-10-11 — latest implementation and CI evidence

**Further native validation:** [run 38121717749](https://github.com/dwijayuda/pskernel/actions/runs/38121717749), revision `964427027b7edd9b8d1a3edb33d4be36841832d8`, **SUCCESS**. This adds a cheap CI guard verifying the exact v7 reference file, size, SHA-256, Git blob, adoption manifest and Lean RC4 pin **before** Lean source compilation. The existing native 10-refusal, positive round-trip and axiom-free correspondence gates passed again. This is *source qualification only*, not completed generated JavaScript, Windows, or new compiler self-host acceptance.

**Sole future .ps source-language authority:** `psc0/PSCV0_LANGUAGE_REFERENCE.md`, PSCV0 v7, SHA-256 `843940bd7f6a9b286e80b01d8c891a7e01b8868a9de7b05833fce32d49be6cd5`. **No backwards-compatible PSC1/ps-0.9-r3/old-PSCV0 source edition is required or selected for this candidate.** Historical frozen JavaScript/Lean compiler artifacts remain bootstrap tools and provenance, **not** compatibility promises. The public installed old compiler has NOT been promoted to v7.

**Dedicated source-policy branch:** `psc0/pscv0-v7-sole-source-policy-v1` from the v7 adoption commit `8603f7dcf6af6295335c4e11912a10aac86c85a4`. Code commit [b7c6211b](https://github.com/dwijayuda/pskernel/commit/b7c6211b4698c8895279db49428a1e9cdce4c5f2) makes `psPscv0ReadDeclaration` dispatch only explicitly selected v7 command families, with direct refusals for source `partial`, `unsafe`, `axiom`, old `verify`, `ghost`, and unselected new parser extensions. The three retained `theorem`/`structure`/`inductive` families still reuse existing parser code as a *selected v7 subset*, **not** an old-language fallback. `pscv0-authoring.json` now encodes `sourcePolicy=pscv0-v7-only-no-legacy-fallback`, `backwardCompatibilityRequired=false` and `supersededLanguageReferenceAllowed=false`; the materializer checks these before generated source selection. Unknown v7 constructs explicitly decline until implemented and qualified.

**Native cloud proof/test:** [run 38121307578](https://github.com/dwijayuda/pskernel/actions/runs/38121307578) **SUCCESS** at policy commit b7c6211b. Native `PsSyntax`/`PsFoundation` built, all five portable PSCV0 source modules typechecked, `Pscv0BridgeSourceSmoke` reported **five positive source round trips and ten explicit negative refusals**, then `pscv0_native_do_correspondence` was checked **axiom-free**. This is a bounded native source policy/proof gate, **not** updated generated JavaScript, full v7 conformance, Windows, or the whole compiler self-host fixed point. The generated regression script adds five new policy refusals; it still requires independent generation and execution.

**Legacy-document routing:** [new v7-only source policy](docs/PSCV0_V7_ONLY_SOURCE_POLICY.md). Earlier `docs/selfhost-language/{CURRENT,SPEC,PS_GRAMMAR_ADOPTION,README,MIGRATION}.md` now have historical-evidence notices, and the root README labels the currently deployed old grammar historical, so no active document purports to supersede v7.

**Integration boundary:** The separate mainline candidate run [38120695522](https://github.com/dwijayuda/pskernel/actions/runs/38120695522), commit 8603f7dc, was still generating the 20-module bridge when the policy branch was created. **Do not cancel it prematurely by advancing the main branch.** After its actual conclusion, inspect Linux/Windows/RC4 jobs, distinguish timeout/semantic failures, then integrate this policy branch into `psc0/pscv0-readable-selfhost-v1` without deleting histories and requalify the changed candidate. Do not claim passing generated tests before they complete. All kernel branches and public npm source remain unchanged.

### Next actions and conditions

1. Verify the main 20-module candidate job's final status and exact source/JS/TS/proof artifacts. If it finishes and all Linux/Windows/RC4 lanes pass, record its bounded source identity, **not** full compiler or v7 language conformance.
2. Integrate the narrow v7-only policy and historical-doc clarification into the primary readable-self-host branch with current-HEAD validation and non-force expected-SHA update.
3. Run native/generation/cloud CI on integrated source; the added five generated refusals must pass, alongside existing 38 bridge assertions, source/Lean correspondence, 36 API comparisons and cross-platform checks.
4. Only after one genuine candidate qualification, expand high-value portable v7 grammar/lowering and migrate additional actual compiler modules, preserving trivia/source spans. A final deliberate 64-module source migration and C0–C3 fixed point remains later.

---

# PSC0 AI WORK STATE — PSCV0 v7 authority and ongoing first-module qualification

## Active checkpoint — 2026-10-11

**Branch:** `psc0/pscv0-readable-selfhost-v1`. **Pre-adoption HEAD:** `29c12e9eb8cf00966c03b4636ff9d6d243b010a3`. The source-language **design** authority for all new PSC0 work is now the full, byte-identical [PSCV0 v7 reference](PSCV0_LANGUAGE_REFERENCE.md): 308,462 bytes, SHA-256 `843940bd7f6a9b286e80b01d8c891a7e01b8868a9de7b05833fce32d49be6cd5`, Git blob `d9e9d7c21337881175b19ccc4c508a792a430195`, Lean 4.35.0-rc4 pin `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`. The previous document SHA `a419955383fd3e35d873f82c939ecf3a92dc65b162cc9d0d3cadf5b853a0f4b0` and PSC1/old PSCV0 references are historical, not alternate grammar or supported compatibility fallbacks. Preserve old exact bootstrap seeds and source-specific test receipts.

**Actual compiler status:** v7 is a design reference, **not implemented full conformance**. Public installed PSC0 still uses the earlier bounded grammar and TypeScript 7.0.2 reference backend. First selected `.ps` compiler source `packages/syntax/src-ps/Ps/Syntax/Translate.ps` has 40 lines versus 63 in frozen handwritten Lean; compiler source authority remains unchanged outside the bounded candidate. Do not change the separate kernel/proof workstream or claim a verified executable.

**Verified latest prior run:** [38112642444](https://github.com/dwijayuda/pskernel/actions/runs/38112642444) completed **failure** at the 900-second explicit generator timeout (exit 124) while preparing `Ps.Syntax.Pscv0.Module` in the candidate suffix. Contrary to older work-state wording, native preflight, actual generated surface bootstrap, authoritative `.ps` source materialization, owned Lean reader round-trip, all eight concrete source-equation proofs and two axiom-free algebra lemmas **passed first**. The concrete original parser/printer/API and changed equations retain exactly inherited `[propext]`; the generic helper/algebra require zero axioms. The 20-module candidate generation, Windows tests and RC4 candidate proof job did **not** finish. Earlier 19-module `Except do` bridge had bounded 38/38 Linux/Windows tests plus RC4 fixture replay [38108354566](https://github.com/dwijayuda/pskernel/actions/runs/38108354566); that historical success is not evidence of the changed candidate or complete v7.

**This change:** commit original v7 file unchanged; pin authoring/adoption manifests and the portable bridge constant/tests to the new digest; install a cheap full-file bytes/SHA256/Git-blob/RC4 identity check before costly CI; raise only the explicit generation ceiling `timeout 900 → 1600` and bridge job budget `25 → 40 minutes`. Preserve all semantic, proof, source, identity, kernel/no-fallback and negative test gates. This budget change does not certify speed or guarantee the next run will pass. See [v7 adoption matrix](docs/PSCV0_V7_ADOPTION_AND_MIGRATION_MATRIX.md). The previous AI state is preserved verbatim in [history](docs/history/AI_WORK_STATE_BEFORE_V7_ADOPTION.md).

### Ordered milestone acceptance (no assumed success)

**V7-M0:** exact 308,462-byte reference committed; automated identity guard passes in actual CI; historical earlier reference preserved and separately labeled.

**V7-M1:** finish the **20-module** candidate using the *generated retained PSC0 JavaScript compiler*, with one in-memory shared prefix; no native fallback or fabricated checked state. Require both readable/lowered projections and their eight equations, unchanged 38 bridge tests, eight selected authoring tests, four arrow regressions, 36 old/new API comparisons, identical source/admission/TS/JS identity, Windows check and independent Lean RC4 generated-proof replay. No completed runs means no candidate promotion.

**V7-M2:** review/migrate selected additional `.ps` compiler modules; introduce useful portable features only with v7 syntax/typing/negative conformance evidence; preserve comments/docstrings/source spans and evaluation order. Avoid JS-only language semantics and duplicate tiny packages. Don't repeatedly run a full compiler fixed point for every routine edit.

**V7-M3:** convert complete actual 64-module compiler-source closure to authoritative `.ps` and reproducibly generated readable `.lean`. Promote explicit new grammar and source/seed manifest identities, not historical SH/1 receipts.

**V7-M4:** deliberate compiler-only C0→C1→C2→C3 with source/admission/TS/JS parity, checked host, typed environment and negative gates. Kernel model-consistency and backend behavior preservation are separate formal obligations.

**V7-specific risks:** `function f()` alone gets one required Unit; `def f()` is invalid; `f ()` gap is banned in term application but binder and grouped-initial terms remain legal; mixed `f x(y)` and `(f x)(y)` differ; proof terms share call syntax; patterns are not comma-call expressions. `psDoItem` is the explicit selected base / verified P0 / environment-gated P1 union. RC4 modules/public imports, Std.WP contract-spec `where finally`, Standard registry digest, accurate `.ps` spans and full P0 APIs remain unqualified. Source `axiom`/`unsafe`/`partial` and emitted `sorryAx` are prohibited by v7, but code paths must earn actual release enforcement evidence. Ordinary checked is not verified executable.

**Process:** GitHub/cloud CI only; no local checkouts/tests, Desktop Commander, kernel edits, force updates or automatic publication. Read current HEAD and CI before each write; preserve history and use expected-HEAD lease. Update this state after *observed* CI outcomes without retroactively relabeling historical artifacts.

---

## Historical work-state snapshot (content below predates this checkpoint)

# PSC0 AI work state — first PSCV0 module, source integration and assumption audit

## Current status (2026-10-11)

Work branch `psc0/pscv0-readable-selfhost-v1`. The actual compiler module `Ps.Syntax.Translate` is authored in `packages/syntax/src-ps/Ps/Syntax/Translate.ps`, selected explicitly by `pscv0-authoring.json`. It has40 physical lines instead of63 in the frozen predecessor. Native PS/readable-Lean/PS round trip works. A portable arrow-type printer repairs the higher-order parameter round trip without changing old69 source files or the kernel.

**Still a candidate.** The generated20-module bridge, final Linux/Windows tests and independent RC4 module proofs have not passed yet. Every attempt so far stopped in cheap native preflight before expensive retained-compiler preparation. The stable public `psc` and default npm source root remain unchanged. Do not claim complete compiler migration or a new full self-host fixed point.

## Important correction: original native dependencies are not axiom-free

Run `38112266804`, job `114390104605`, at `d510124ad9cbbaefab1dcabb51e2049352a5b6d4` checked the unchanged original declarations. The two parsers, two printers and four original translation APIs report exactly **[propext]**; PsTranslationError reports no axioms. The readable correspondence equations close with the same dependency. Prior attempts to remove it solely by changing proof tactics were misdirected.

The original empty-closure gate assumed the concrete compiler APIs had the same empty dependency closure as the isolated Except/Nat fixture. That assumption was wrong. It is explicitly replaced with **exact baseline closure + zero-axiom refactoring algebra**. See [PSCV0_MODULE_ASSUMPTION_AUDIT.md](docs/PSCV0_MODULE_ASSUMPTION_AUDIT.md).

The runner now checks original, migrated and theorem dependencies separately. Concrete equations must add no assumptions beyond exactly [propext]; unexpected dependencies fail. Two generic error-map/bind and error-map/match lemmas over abstract parser/printer results, and the actual generated error helper, must have zero axioms. A baseline reflexivity theorem exposes inherited dependencies. All eight concrete API equations and generated source products are unchanged. This updates qualification scope, not production kernel/axiom acceptance.

## Source authority and immutable boundaries

Reference: user's PSCV0 Lean4.35.0-rc4 document, SHA256 `a419955383fd3e35d873f82c939ecf3a92dc65b162cc9d0d3cadf5b853a0f4b0`; upstream `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`. Use its base do, arrows, binder visibility and formatting semantics. No old-.ps backward-compatible mode is required.

Candidate source selection has no .lean fallback. Original Translate.lean blob `eafd7159b14a251fe11ffdbfb1e2482bcc773c9b` is a frozen predecessor, not a second candidate master. src-ps keeps it outside the old release packer's source-collision path. The other compiler source, public npm host, seed/toolchain and kernel source/JS adapter remain unchanged. Kernel work stays on the other branch.

Candidate PS SHA256 `938288af9c8476d592fc69c4e6f2c01ecb8e1f371fdd5bac1f789a3097710428`.
Native readable SHA256 `21ac2a83f37c5aac102a9343ea0f310503449dc8a800f0ca6c3493f77e8b11e5`.
Native lowered SHA256 `c11d75f3f6a3ecda32bd2014bbab80d387d1f5fae6b822f44481300a490aefeb`.
These native views are NOT substituted for generated compiler inputs.

## Ordered bootstrap and validation

1. Cloud native preflight: build only syntax/foundation dependencies, type-check Surface/Read/Commands/TypePrint/Module, execute original smoke and real authoring round trip, then prove both generated projections equal the original four APIs and audit dependencies/algebra.
2. Retained C0 JavaScript prepares the unchanged syntax prefix once. Preserve its pure in-memory preparation state just before Translate; do not serialize it as proof authority.
3. Generate the current20-module surface bootstrap with predecessor Translate. Use THAT generated JS to parse/print/lower the selected Translate.ps. All three views must equal native preflight, and proofs run on generated products again.
4. Resume the same pure prefix with PS-derived Translate, compile only the suffix, and emit the final candidate. Record both stages and exact source/JS/TS identities. This avoids repeating expensive prefix preparation.
5. Linux and Windows run the original38 tests unchanged plus8 authoring tests (36 original/candidate input comparisons) and4 arrow regressions. The new bridge must read/lower its own selected PS module and reproduce readable/lowered views.
6. RC4 checks the existing actual generated do fixture with zero axioms and all eight concrete module equations under their exact baseline dependencies, plus two zero-axiom refactoring lemmas.

No full64-module compiler rebuild, C2/C3, kernel regeneration, public CLI change, npm publication or main merge. Old qualification is not inherited by changed source; the candidate must earn its own bounded evidence.

## Canonical owners

- syntax/src-ps/Ps/Syntax/Translate.ps: sole candidate module source, four original APIs + generic error adapter.
- Syntax/Pscv0/TypePrint.lean and Module.lean: portable readable/lowered declaration-type printing; no new kernel/Pi semantics.
- scripts/pscv0-authoring.mjs: IO, source selection/hashes and portable bridge invocation; proof-source assembly is test tooling.
- scripts/pscv0-build-bridge.mjs: two-stage generation with one shared pure prefix.
- scripts/Pscv0AuthoringSmoke.lean: native preflight only.
- scripts/pscv0-authoring-proof.mjs and test/pscv0/reference/TranslationAlgebra.lean: exact dependency audit and actual projection equations/algebra.
- scripts/pscv0-authoring.test.mjs, pscv0-arrow.test.mjs: genuinely generated JS tests.

## Retained evidence and failures

Retained C0: source `2f42a52814f3785ff2d92bd826f6e7fb3eb9bc8a`, run38075437516, artifact11678641329, JS SHA256 `6cddc3c34c38f1524ef9a355c46b0eb17949c45c54fd59367ea370c1af861ab3`; TypeScript7.0.2, Lean4.34.0.
Previous19-module bridge: implementation1ed94be7b1d3, run38098425773 Linux/Windows38 passed, overall failed dueRC4 setup; successful separate reference replay38108354566. Full ledger in docs/PSCV0_BRIDGE_CAPABILITIES.json applies to that exact old source only.

First module run38110082840 at1d578cd6: printer produced anonymous binder inside higher-order type, owned reader refused. General portable arrow correction at364740af restored round trip.
Runs38111345101 and38111578077: incomplete native proof scripts, not changed source behavior. Run38111837339 at8ccd191b: readable proofs closed, zero-axiom audit refused propext. Run38112058253 at58525ea3: delta proof still same dependency. Run38112266804 atd510124a: original dependency audit established the true baseline. All remain failed; no generated candidate claims. Last diagnostic artifact11691727987 SHA256 `6903cc573c49bd79419d775b3b8ad59cc546dc5d5554190f296a7c7e43516781`.

## Continuation and limits

First module contains no original/new comments and exact source replay is checked. Do not strip comments from later modules: full comment anchoring remains pending. Compiler diagnostics after lowering still use generated-Lean coordinates; source remapping is pending before public promotion. Full inferred lambdas, record updates and broader language features remain later work.

GitHub repository reads/writes and cloud CI execution only. No local checkout/build/test, Desktop Commander, force push, kernel edits or automatic releases. Fetch live HEAD before writing and use expected-HEAD non-force updates; preserve concurrent commits. Do not call a pending run success or silently relax source/semantic assertions. Update this state after actual results.

Prior full state retained byte-for-byte at docs/history/AI_WORK_STATE_BEFORE_MODULE_AXIOM_AUDIT.md (blob1149451ec45760127d7511bb4a54a793bc018f93); initial module state at docs/history/AI_WORK_STATE_BEFORE_FIRST_PS_MODULE.md.
