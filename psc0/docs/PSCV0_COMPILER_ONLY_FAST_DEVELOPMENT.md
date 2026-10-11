# PSC0 — Fast compiler-only PSCV0 v7 development

**Decision:** 11 October 2026. Sole future ProofScript language reference: [PSCV0 v7](../PSCV0_LANGUAGE_REFERENCE.md), SHA-256 843940bd7f6a9b286e80b01d8c891a7e01b8868a9de7b05833fce32d49be6cd5. No old ProofScript language-edition compatibility. The new development branch is **psc0/pscv0-compiler-fast-loop-v1**.

## Why this development workflow is needed

The real first-module compiler milestone already qualified the closed v7 AST transport with Linux, Windows and independent Lean RC4 checks at [full bridge run 38128357665](https://github.com/dwijayuda/pskernel/actions/runs/38128357665), source a640a2d22adeabd4ca7919839a8991667bcc3eae. That workload generates a 20-module source frontend from the retained self-host compiler and is expensive to repeat after each routine compiler change.

For the current development phase, **focus entirely on self-host compiler packages**: syntax, AST transport, elaboration, type checking, TypeScript 7 output and JavaScript runtime. No PSKernel-core implementation work, independent kernel differential tests or kernel metatheory jobs are needed for normal edits. Production checked-admission and verified build gates are not weakened or relabeled; they are deliberately **not executed** by the new cheap development lane.

## Three distinct feedback tiers

| Change | Development check | Boundary |
|---|---|---|
| JavaScript host glue, AST transport, compiler-authored ProofScript while the 20-source frontend closure is unchanged | [Fast compiler-only workflow](../../.github/workflows/psc0-pscv0-compiler-fast.yml): cached generated v7 reader to compiler-owned AST, actual elaboration, TS7 emission and JavaScript execution | No independent kernel test; development evidence only |
| Portable Lean syntax/frontend source | [Cheap native compiler source workflow](../../.github/workflows/psc0-pscv0-compiler-native.yml): build only Syntax/Foundation and check five v7 source modules | Does not certify changed generated JavaScript |
| Changes to the generated frontend implementation, parser rules or promotion | Explicitly run the **full** generated bridge on a milestone and preserve all its exact source/JS identities | Independent release-time proof/admission gates remain elsewhere |

### Exact compiled frontend cache

The fast workflow downloads the immutable successful bootstrap artifact **pscv0-bridge-a640a2d22adeabd4ca7919839a8991667bcc3eae**, run 38128357665. That artifact contains a 20-module source closure with original raw SHA-256 for every module and exact generator JavaScript provenance. The new script checks **all 20 files** against the current GitHub checkout and rejects with **FAST_CACHE_STALE** if any has changed. The retained old compiler is also checked against its actual builder SHA. No silent use of the old parser as evidence for a changed compiler language feature is permitted; regenerate a new exact artifact when the grammar changes.

Current authored compiler source, packages/syntax/src-ps/Ps/Syntax/Translate.ps, is read from the **current** GitHub checkout, not from the cache. Its SHA-256 and number of schema-validated AST nodes are recorded. The source parser enforces v7-only syntax with explicit negative input tests.

### Compiler-only fast pipeline

1. Verify the exact v7 document identity, script syntax, cached 20-module implementation hashes and pinned retained compiler/TypeScript 7.0.2 source.
2. Parse the current authored ProofScript source with the already-generated v7 parser, lower its source AST and cross the **closed recipient-owned v7 AST ABI**. Refuse malformed structure, incorrect symbols, version or constructor sets.
3. Run three representative **actual compiler-package** programs, including nested-call grouping, mixed native/postfix application and ordinary calls. Give the compiler the validated syntax AST directly, without an old Lean text-parser fallback.
4. Run the compiler's real elaboration/preparation and TypeScript backend; compile using the exact TypeScript 7 compiler and execute the resulting JavaScript. Preserve source/admission/TS digests, byte provenance, observed result and elapsed milliseconds. Canonical admission serialization may run as ordinary compiler output, but **the independent kernel checker is not invoked**.
5. Emit a report explicitly saying compiler-development-only, independentlyKernelAdmitted false, kernelOrKernelProofTestsExecuted false, fullV7Conformance false, fullSelfhostFixedPoint false. This is an iteration tool, **not** a verified software certificate.

The generated JS frontend is still an independent component with private ADT symbols. The closed AST ABI translates source trees to receiver-owned constructors; it creates no proof authority. Any verification claim must later use the separate exact-source release build and independent checker.

## Actual early measurements and reusable multi-module expansion

The first fast compiler-only cloud job [38130403756](https://github.com/dwijayuda/pskernel/actions/runs/38130403756) **passed** with **1,723 milliseconds measured compiler-test execution**: all 20 cached-source SHA-256 identities, 2,440 actual Translate.ps source AST nodes, source typing/elaboration/TS7 runtime and three results 3, 8 and 4. The separate cheap native compiler-source typecheck [38130403714](https://github.com/dwijayuda/pskernel/actions/runs/38130403714) also passed. Neither ran an independent PSKernel checker.

The exact second-module v7 compiler-only differential [38130835390](https://github.com/dwijayuda/pskernel/actions/runs/38130835390) **passed** on the real ten-function Ps.Foundation.List module. It validated 4,882 AST nodes and yielded **byte-identical compiler canonical admissions and TypeScript7 source** compared with the original Lean version. This stage took 670ms source parsing and 5,793ms compiler preparation (not including CI provisioning). It did not run a kernel checker or promote source into the 20-module build.

To scale cheaply, the source candidates are now selected by one closed [v7 candidate manifest](../pscv0-fast-candidates.json), and the reusable [compiler source differential](../tools/abi/compiler-source-differential.mjs) performs the same source/AST/elaboration/admission/TS7 comparisons for every selected module. The third candidate Ps.Foundation.Source covers structure declarations rather than generic recursion. Both Source and List have now passed the strict compiler-only differential at source commit 4c79d8854d453b27111e8675cd4240fc2de58112; a future full generated compiler-source promotion still requires a separate milestone. No per-module test-output relaxation or old language compatibility is introduced.

**Multi-source compiler differential result — [38131142962](https://github.com/dwijayuda/pskernel/actions/runs/38131142962), SUCCESS:** Under the exact source-pinned generated v7 frontend and the same retained PSC0 compiler, both second-module List and third-module Source candidates produced **byte-identical canonical compiler admission streams AND TypeScript output** relative to their corresponding historical Lean files. Source contributed 2 structure declarations and 236 source-AST nodes; List contributed 10 generic recursive declarations and 4,882 AST nodes. The reusable manifest-driven implementation completed both in **8,318 milliseconds** measured process time, excluding runner/setup. **No independent kernel test ran.** The source files remain unpromoted migration candidates, distinct from the already qualified full-bridge Translate.ps module.

## Efficiency and development discipline

Prefer invariant-level fixes for parsing, grouping, comments/trivia, scoped environments, source positions and AST shape. Do not change tests to fit a deficient parser. A small typechecked v7 source and actual compiler TS7 output offer cheap feedback, then run the full 20-module bridge only at intentional milestones. Native Lean typechecking uses the existing host compiler toolchain; selecting another independent kernel for this no-kernel development tier would be unnecessary, with no measured benefit. If kernel testing resumes, choose and qualify a fast checker separately rather than silently replacing trusted policy.

Never delete retained fixed-point history, merge unqualified compiler changes, downgrade user-visible release proof requirements, or enable backward-compatible old ProofScript syntax. Update AI_WORK_STATE.md with exact observed CI and measured fast-loop timings.
