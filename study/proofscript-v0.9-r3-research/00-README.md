# ProofScript v0.9 r3 Research Workstream

Status: **research branch; not a language release, compiler release, or proof of soundness**  
Branch: <code>research/proofscript-v0.9-r3</code>  
Baseline: ProofScript v0.9.0 draft revision 2 (<code>ps-0.9-r2</code>)  
Semantic pin: Lean 4.34.0, commit <code>293d5d0c0c3f3dded4688b3ccd6a33939ac5102b</code>

## Mission

This workstream tests a possible r3 surface and platform revision without changing ProofScript's logical foundation.

The invariant is:

~~~text
.ps source
  -> category-aware ProofScript parsing
  -> owned surface AST
  -> explicit Lean-compatible lowering
  -> Lean-compatible elaboration
  -> candidate declarations
  -> genuine kernel admission
  -> CheckedModule
  -> justified erasure/runtime lowering
  -> RuntimeIR
  -> target lowering / validation
  -> JS / Wasm / optional other artifacts
~~~

The project does **not** equate parser success, elaboration, proof acceptance, compiler correctness, backend correctness, self-hosting, hashes, tests, or AI confidence.
## Research questions

The r3 study is organized around ten linked decisions:

1. Make native <code>.ps</code> parenthesized calls insensitive to ordinary trivia, with explicit tuple grouping.
2. Make ProofScript-owned braces genuinely structural instead of visually brace-delimited but secretly layout-delimited.
3. Study and specify <code>function f()</code> as explicit Unit-function sugar.
4. Decide whether <code>const</code> remains worth its TypeScript familiarity cost.
5. Separate <code>ps-standard</code> from <code>ps-lean-extensible</code> without weakening the type theory.
6. Define stable PSC-owned contracts rather than relying semantically on experimental Lean intrinsic verification.
7. Freeze one application error/resource/async model.
8. Define a versioned npm / <code>.d.ts</code> boundary and exercise it with applications.
9. Complete a first formal overlay theorem and a first backend-preservation slice.
10. Design a real TypeScript-developer usability study before syntax freeze.

## Current recommended direction

The current research recommendation is deliberately opinionated but remains reviewable:

- replace r2 <code>D-CALL</code> with an r3 parenthesized-call **surface exception**, because <code>f (x, y)</code> will no longer retain the r2 native-tuple neighbor inside <code>.ps</code>;
- keep <code>.lean</code> entirely unchanged;
- make owned brace bodies explicitly delimited with category-specific separators;
- add Unit-function sugar;
- provisionally retain top-level <code>const</code>, with a usability gate before 1.0;
- freeze a closed-syntax Standard profile and a separately extensible Lean-oriented profile;
- define contracts as ordinary checkable logical artifacts tied to the actual implementation;
- standardize <code>App</code>, <code>Fiber</code>, <code>Resource</code>, <code>Stream</code>, and explicit execution outcomes as library/runtime concepts, not kernel primitives.
## Evidence discipline

Each decision document distinguishes:

- **research evidence**: source/reference reading or precedent;
- **design decision**: a proposed language contract;
- **prototype evidence**: a parser/runtime experiment;
- **native oracle evidence**: an exact pinned Lean run;
- **formal theorem**: a theorem checked by the selected proof checker;
- **differential evidence**: agreement between implementations on a test corpus;
- **usability evidence**: observations from human participants;
- **unproved assumption**: an explicit remaining boundary.

A green test does not promote itself into a theorem.

## Document map

- <code>01-DESIGN-CONSTITUTION.md</code> — constraints and decision criteria.
- <code>02-DCALL-DESIGN.md</code> — r3 call ownership and migration.
- <code>03-BRACES-AND-LAYOUT.md</code> — structural brace grammar.
- <code>04-ZERO-ARG-FUNCTIONS.md</code> — Unit-function sugar.
- <code>05-CONST-DECISION.md</code> — retain/remove analysis.
- <code>06-STANDARD-VS-EXTENSIBLE-PROFILES.md</code> — two source profiles.
- <code>07-CONTRACTS-AND-SPECIFICATIONS.md</code> — stable PSC contracts.
- <code>08-APPLICATION-EFFECTS-ASYNC-RESOURCES.md</code> — standard application model.
- <code>09-NPM-DTS-INTEROP.md</code> — InterfaceIR and JS/TS boundaries.
- <code>10-REFERENCE-APPLICATIONS.md</code> — application corpus and executed prototypes.
- <code>11-FORMAL-OVERLAY-PROOF.md</code> — proposed first overlay theorem and proof plan.
- <code>12-BACKEND-PRESERVATION-SLICE.md</code> — proposed first backend-preservation theorem plan.
- <code>13-USABILITY-STUDY.md</code> — human-study protocol and status.
- <code>14-MIGRATION-FROM-R2.md</code> — edition-aware migration.
- <code>15-CONFORMANCE-PLAN.md</code> — parser/runtime/proof matrices.
- <code>16-OPEN-QUESTIONS.md</code> — unresolved items.
- <code>DECISIONS.md</code> — compact decision ledger.
- <code>MANIFEST.json</code> — machine-readable identities and evidence.
- <code>RESEARCH-SOURCES.md</code> — local and current official research sources.
- <code>ProofScript_Language_Reference_v0.9.0_r3_candidate.md</code> — integrated candidate, created after the decision documents.
## Research sources

Primary local sources remain the repository's pinned <code>study/</code> material: the v0.7 language lineage, Lean 4.34 parser/source, the Lean language-reference mirror, TypeScript documentation mirror, Lean4Lean divergence notes, theorem-proving material, and language-design books.

Current official sources are used when current ecosystem behavior matters. In particular:

- Lean function application and extensible syntax: https://lean-lang.org/doc/reference/latest/
- TypeScript handbook and compatibility: https://www.typescriptlang.org/docs/
- Go specification and engineering account: https://go.dev/ref/spec and https://go.dev/talks/2012/splash.article
- ReScript interop and JSX: https://rescript-lang.org/docs/
- Gleam externals: https://gleam.run/documentation/externals/
- F* proof-oriented programming: https://fstar-lang.org/tutorial/book/
- Verus guide: https://verus-lang.github.io/verus/guide/
- Dafny guide: https://dafny.org/dafny/OnlineTutorial/guide
- Koka effect research: https://koka-lang.github.io/koka/
- WebAssembly Component Model async/WASI: https://component-model.bytecodealliance.org/

Source popularity is not a language-design proof.

## Repository safety

This directory is additive. It must not overwrite v0.7, v0.9-r2, compiler code, kernel code, or main-branch policy. r3 syntax is not activated merely because this documentation exists.

The integrated r3 candidate now exists as documentation research only. Language freeze still requires future implementation work, formal proofs, application experiments, and the human usability study; none of those are claimed by this branch.