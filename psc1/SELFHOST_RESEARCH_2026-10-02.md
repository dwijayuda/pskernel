# PSC2 self-host implementation and reference audit — 2 October 2026

Repository: `dwijayuda/pskernel`.
Active branch: `psc2/minimal-selfhost-psc15`.
Baseline: `e9bf3316b5cdd3152a45a0cf98b05b0ac43fb949`.
Tested implementation: `a309f2c8562045f045c3fbd7ef840edf7a6e0c1e`.

## COMMITTED

All writes in this work are under `psc15selfhost/`. Other branch snapshots were read as reference only. No branch was merged, no optional backend was added to the portable bootstrap closure, and AdmissionReady was not relabeled as real kernel admission.

- `44b91b4925d85121907b69d078cd6a1843cfd264`: generated-compiler CLI compilation now consumes a validated canonical `.ps` source closure. Added fourteen production-CLI orchestration regression cases and wired them through the existing manifest tests.
- `c19a58286fc839ecfb8400ef68bf4f5f51ea55a7`: append source-profile guard; detached the temporary documentation collector from CI.
- `b6ce9c8780226dc8cfa42a9eca81dfe262835255`: normalized all four append operators in `psEraseFinishApplicationWithFuel`; added a structural runtime-argument append helper, native behavioral tests, an append-order theorem, and a whole-closure parse audit. Preserved and mutation-tested all six existing sequencing terminators.
- `a678e186b76aafea5adca02204a3b14479a353ac`: moved the audit to a compiled Lake executable with explicit subprocess time bounds.
- `a309f2c8562045f045c3fbd7ef840edf7a6e0c1e`: corrected both lambda binders in the new helper to the explicit typed PSC1 form after the real parser rejected the original untyped form. The diff also contains one line-wrap-only change to an unrelated existing error branch; no expression was changed there.

The reference collector was introduced in `401ae08f228a061f721c9c70585bb9f75b86e178`, corrected in `44b91b4`, and detached from the source-check chain in `c19a582`. It remains explicit opt-in research tooling (`node scripts/reference-docs-audit.mjs --fetch`), not a compiler dependency or completion gate.

## What generated-source isolation now enforces

A recognized generation manifest is a workspace boundary. The generated-compiler CLI validates its generation, entry, canonical file list and hash, resolves only `.ps` files within that workspace, rejects missing or unlisted dependencies, rejects unreachable manifest entries and import cycles, and bounds real filesystem paths to prevent symlink escape. It hashes the in-memory source snapshot actually consumed rather than rereading the files later.

The fourteen cases cover nested and standalone generated workspaces, stale Lean siblings, source tampering, missing sources, file-set and entry mismatches, malformed/ambiguous manifests, generation tags, cycles, symlinks and both bootstrap/selfhost manifest kinds. They invoke the actual CLI but intentionally use compiler and TypeScript-compiler test doubles. They establish orchestration and source-selection behavior, not generated compiler semantics or end-to-end self-host success. The separate native bootstrap host resolver is not replaced by this JavaScript CLI change.

## CI VERIFIED

The latest completed implementation run is `36910864466`, job `110532876828`, at **`a309f2c8562045f045c3fbd7ef840edf7a6e0c1e`**. The job completed on 2 October 2026 at 02:02:23 Jakarta time (1 October 2026, 19:02:23 UTC). Its overall conclusion is **failure**, because the real fixed point still encounters a parser error.

The log confirms these narrower results:

- KernelCore boundary and Name/Level/Expr parity tests: PASS.
- Aggregate self-host source gates, including append and six sequencing mutations: PASS.
- Explicit `Ps.Elab.Term` build: PASS.
- Fourteen generated-source isolation CLI cases: PASS, using compiler/tsc test doubles.
- Existing native minimal-selfhost regressions: PASS.
- Native finish-application cases: PASS for runtime parameter/argument order, proof erasure/local IDs, sanitized names, base cases, fuel and unsupported type binders.
- The append-order theorem was accepted during the compiled native audit build.
- Whole-closure parser audit: 54 reachable modules, 46 PASS and 8 FAIL.
- Actual fixed-point command: FAIL at the next tuple-construction parser blocker.

Source: https://github.com/dwijayuda/pskernel/actions/runs/36910864466/job/110532876828

The prior run at `a678e186` caught untyped lambda binders in the newly added helper. Both binders were corrected in `a309f2c`; the latest replay passed those sites. The locally retained RED/GREEN logs distinguish old failing source-selection behavior and source guards from their replacements. Lean was not installed in the local working container: native build, proof-checking and execution claims here are CI claims.

## Parser inventory at a309f2c

Paths below are relative to `psc15selfhost/`. These are each file's first parse error, not an exhaustive count of incompatible constructs.

| Source | First diagnostic |
| --- | --- |
| `packages/backend-ts/src/Ps/BackendTs/Expr.lean` | `7:16: expected identifier, got natural` |
| `packages/backend-ts/src/Ps/BackendTs/Module.lean` | `13:28: expected ', or }', got '++'` |
| `packages/backend-ts/src/Ps/BackendTs/Type.lean` | `15:5: expected identifier, got symbol` |
| `packages/erasure/src/Ps/Erasure/Basic.lean` | `44:20: expected 'end of structure field', got ':='` |
| `packages/erasure/src/Ps/Erasure/Expr.lean` | `168:43: expected ')', got ','` |
| `packages/erasure/src/Ps/Erasure/Inductive.lean` | `52:15: expected ';', got 'let'` |
| `packages/erasure/src/Ps/Erasure/Structure.lean` | `13:6: expected 'term', got '!'` |
| `packages/erasure/src/Ps/Erasure/StructureRecursor.lean` | `44:18: expected 'term', got '!'` |

Parsing 46 of 54 modules is not a self-host completion percentage. Parsing does not prove elaboration, erasure, emitted TypeScript correctness, generated-JavaScript behavior or compiler-generation convergence. The diagnostic inventory does not weaken the unchanged real fixed-point acceptance gate.

## REAL FIXED-POINT VERIFIED

Replay advanced from the baseline append rejection at `Expr.lean:151:44` to:

```text
PSC1_PROJECT_PARSE_FAILED:
packages/erasure/src/Ps/Erasure/Expr.lean:
168:43: expected ')', got ','
```

The remaining expression is `List.cons (pushed.id, parameterName) scope.runtimeLocals` inside `psEraseFinishApplicationWithFuel`. The bounded next candidate is explicit `Prod.mk` construction, with corresponding guard and behavioral checks; that change is **not implemented by this checkpoint**.

**No successful fixed point has been established.** Whole-closure source compatibility, full generated-compiler execution and exact generation comparisons remain required. The new parser audit exposes failures in other reachable modules rather than treating the first failing file as the whole backlog.

The generated-JavaScript CLI isolation fix must not be generalized to the whole pipeline: the native bootstrap host has its own import resolver and its consumed-source provenance still requires separate validation or hardening. Before accepting a first fixed point, validate the complete native-bootstrap-to-generated-compiler route. Executing another compiler generation is additional assurance; it has not been implemented or demonstrated here.

## Reference coverage

A read-only shallow snapshot of all advertised branch tips was scanned in CI run `36906167562`, job `110517132675`. The collector reported **323 branch tips, 140,645 text-document occurrences, 841 unique text-document blobs, and 6,642,465 UTF-8 bytes**. It selected 116 self-host/compiler-related document blobs for complete text output and found no PDF/DOCX/ODT files matching its binary-document inventory.

Coverage means the filename conventions and extensions implemented in `scripts/reference-docs-audit.mjs`: Markdown, RST, AsciiDoc, TXT, Org and conventional README/license names. This is a branch-tip inventory and mechanical text scan, not a review of every historical commit, every possible document format, or every line of all 841 documents. The large CI log was truncated by the connector; relevant design documents were fetched separately for close review.

Closely reviewed repository references:

- Active `psc15selfhost/ARCHITECTURE.md`, `STATUS.md` and `WORKSTREAM_COORDINATION.md` at the baseline.
- Architecture checkpoint `72f32ac718ae75725ca3d63aa28477bccf897927`: `psc15selfhost/ARCHITECTURE.md`.
- Resolver checkpoint `4419c265e524935603f96559eb988cfaa75e254b`: `psc15selfhost/STATUS.md`.
- Governance checkpoint `16267b2b5818349e4d70802a4062d511aa9de448`: `docs/selfhost/PSC1_LEAN_BOOTSTRAP.md` and `docs/selfhost/POST_PSC1_PLATFORM.md`, both complete; first 200 lines of `docs/STUDY_REFERENCE_POLICY.md`.
- Executable bootstrap policy, generated-source pipeline, manifest validators, comparison scripts, source guards and native test sources.

These references are not interchangeable. Older bootstrap documents describe a broader kernel-backed trajectory and adjacent source lanes. The active minimal branch uses an AdmissionReady integrity boundary and excludes kernel/provider and optional backend work. The active code and explicit user scope govern this implementation; historical plans do not override them.

## External primary-source research and decisions

GCC's official build documentation describes staged bootstrapping and comparison of stage-2 and stage-3 compilers: https://gcc.gnu.org/install/build.html

Reproducible Builds documents the requirement for a deterministic build process, including stable input ordering and avoiding uncontrolled timestamps and paths: https://reproducible-builds.org/docs/deterministic-build-systems/

These are engineering references, not certifications of ProofScript or definitions of its semantics. The applied decisions were:

1. Bind generated compilation to its canonical manifest and the exact bytes consumed; reject a handwritten fallback inside a recognized generation boundary.
2. Normalize the proven append class inside one declaration instead of broadening the parser or importing a richer language implementation.
3. Keep sequencing protection but stop pinning obsolete infix spellings; independently mutation-test all six terminators.
4. Add native behavior checks and an append-order theorem. This does not turn the entire compiler's AdmissionReady boundary into real kernel admission.
5. Use a compiled, host-only parser audit to expose the full reachable module inventory. Its imports are not added to the portable closure.
6. Keep actual generated-compiler execution and exact source/compiler comparisons as acceptance requirements. A further generation cycle should later strengthen stability evidence, but was not implemented or demonstrated in this checkpoint.
