# AI Prompt — ProofScript r3 Specification Completion Pass

Use this prompt with an AI research/design agent working on `dwijayuda/pskernel`.

---

You are the lead language-specification editor and programming-language researcher for ProofScript / PSC.

Repository:
`https://github.com/dwijayuda/pskernel`

Target branch:
`research/proofscript-v0.9-r3`

Primary accepted reference:
`study/proofscript-v0.9-r3-research/ProofScript_Language_Reference_v0.9.0_r3.md`

Historical normative baseline:
ProofScript Language Reference v0.9.0 r2, exact SHA-256:
`d29c0b2d5780e6cdb08a4c9ac00cc7442a64b1c8133b51c5f0c0e9a343b11b8d`

Semantic pin:
Lean 4.34.0, commit
`293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`

Do not confuse this project with unrelated ProofScript projects.

## Scope

This is a **documentation/specification research pass only**.

Do not modify the compiler, kernel, runtime, backends, bootstrap, generated code, npm packages, or application implementations.
Do not run compiler/backend experiments or claim human-study evidence.
Do not modify `main`.
Do not overwrite r2.

The objective is to make r3 precise enough to implement later without silently inventing semantics.

## Required work

1. Make r3 normatively complete. Prefer a formally complete r2-delta model if copying the entire r2 text would create transcription risk. Pin the exact inherited r2 artifact and define a total authority/override table. Every r2 rule must be either inherited, superseded, retired, or explicitly unsupported.

2. Resolve empty parenthesized calls versus optional/default parameters. Preserve TypeScript-familiar `f()` behavior where possible without importing JavaScript `undefined` semantics. Preserve Lean's native optional/automatic/implicit argument model. Keep zero-source-argument `function f()` distinct from a parameterless value and preserve function-as-value behavior.

3. Specify the exact r3 grammar and feature registry. Define parser ownership, call-gap/newline behavior, structural brace grammars, field separators, named arguments, trailing commas, empty calls, zero-arg declarations, patterns, native lifting, committed errors, diagnostics, and migration. No prose-only syntax feature may remain normative.

4. Fix generalized field notation examples. Do not accept whitespace before `.` unless r3 deliberately specifies a separate feature. Lean's pinned field notation requires adjacency to the dot.

5. Freeze `ps-standard` as an exact closed syntax/meta profile and `ps-lean-extensible` as the declared extension profile. Define the Standard registration closure, forbidden source registration commands, tactic/notation identity, cache identity, host permissions, and the canonical semantic-bundle format used when Standard consumes declarations produced by Extensible packages.

6. Finish the normative PSC contract core. Define exactly what is stable in r3. Include preconditions, postconditions, implementation identity, specification-dependency identity, assumption policy, outcome relations, effect/frame semantics, and higher-order callable contracts. Keep unfinished loop/state/effect syntax clearly non-normative if its semantics is not complete.

7. Freeze the application model at the semantic level. Decide whether `App` is cold or hot, define `Fiber` start/join/scope ownership, cancellation state transitions, cancellation shielding during cleanup, typed failure versus runtime fault, capability requirements, the relationship between Standard `App` and native Lean `IO`, and Stream subscription/backpressure semantics. Do not add async/await syntax.

8. Turn InterfaceIR into a real versioned binding format. Provide a machine-readable schema and deterministic Node/npm/`.d.ts` resolution identity. Bind together package version, package.json identity, export subpath, condition set/order, runtime entry, type entry, module-resolution profile, TypeScript declaration version/profile, and target. Provide a support matrix for difficult TypeScript declaration forms. Unsupported forms fail closed.

9. Restore r2's exact primitive/runtime/module/compiler-assurance obligations into the r3 authority model: source identity, module ambiguity, Nat/Int semantics, fixed-width types, strings/bytes, partial/unsafe/noncomputable execution, IO/Task distinction, compiler phases, admission, erasure, runtime primitives, artifact binding, diagnostics, evidence manifests, and release snapshots.

10. Define the pre-stable/1.0 evidence gates for the already-planned usability study, formal overlay proof, backend-preservation proof, npm/reference applications, and cross-target conformance. Do not fabricate results. Mark every unrun gate as pending.

## Design requirements

Preserve:

- `.lean` as genuine native Lean syntax;
- one Lean-compatible logical foundation;
- fail-closed unsupported/error/exhaustion behavior;
- category-aware ownership;
- canonical Lean meaning;
- explicit source/profile/environment identity;
- separate evidence states for parsing, elaboration, admission, specification proof, termination, erasure, backend preservation, artifact binding, runtime assumptions, tests, and human studies.

Reject:

- JavaScript ASI;
- generic JS statement blocks;
- implicit null/undefined;
- native `any`;
- JavaScript truthiness;
- Promise as PSC async semantics;
- `.d.ts` as proof/runtime validation;
- arbitrary syntax mutation in `ps-standard`;
- hidden fallback to another compiler/checker;
- calling tests, self-hosting, or hashes a preservation proof.

## Required outputs

Create or update:

- `R3-NORMATIVE-INHERITANCE.md`
- `17-R3-GRAMMAR-AND-FEATURE-REGISTRY.md`
- `r3-feature-registry.json`
- `18-PS-STANDARD-REGISTRY.md`
- `ps-standard-registry.json`
- `19-SEMANTIC-BUNDLE-FORMAT.md`
- `semantic-bundle.schema.json`
- `20-CONTRACT-CORE.md`
- `21-APPLICATION-SEMANTICS.md`
- `22-INTERFACEIR-V1.md`
- `interface-ir-v1.schema.json`
- `23-PRE-STABLE-EVIDENCE-GATES.md`
- the accepted integrated `ProofScript_Language_Reference_v0.9.0_r3.md`
- `DECISIONS.md`
- `MANIFEST.json`
- `16-OPEN-QUESTIONS.md`

## Evidence discipline

For every claim, label it as one of:

- inherited normative rule;
- accepted r3 normative rule;
- informative design rationale;
- planned implementation obligation;
- planned formal proof;
- planned usability evidence;
- planned application evidence;
- external assumption.

Do not silently promote a plan into evidence.

## Completion criterion

The pass is complete when a future implementer can answer, from the r3 documentation alone plus the exact pinned r2/Lean authorities:

- what source is accepted;
- which parser owns it;
- what it lowers to;
- which environment/profile is required;
- what errors are required;
- what defaults/empty calls mean;
- which syntax is closed in Standard;
- what contracts mean;
- what application effects mean;
- how npm declarations map to InterfaceIR;
- what primitive/runtime behavior must be preserved;
- which claims are actually proved/tested versus still pending.

Commit documentation changes only to the r3 research branch.
