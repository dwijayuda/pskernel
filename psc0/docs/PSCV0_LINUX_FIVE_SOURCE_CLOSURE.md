# PSCV0 v7 — Linux-only five-authored-source compiler closure

**Status:** source-selection compiler milestone **pending cloud CI**. **Branch:** `psc0/pscv0-linux-source-closure-v1`. **Source language:** solely [PSCV0 v7](../PSCV0_LANGUAGE_REFERENCE.md), SHA-256 `843940bd7f6a9b286e80b01d8c891a7e01b8868a9de7b05833fce32d49be6cd5`. There are no old .ps parser compatibility paths.

## Why this milestone is different from the fast graph

The previously validated fast graph [38134033244](https://github.com/dwijayuda/pskernel/actions/runs/38134033244) qualified the **compiler-only source-product equivalence** of four alternate modules: `Ps.Foundation.Source`, `Ps.Syntax.Cursor`, `Ps.Syntax.Token`, and `Ps.Foundation.List`, including their typed interdependencies. All nine source variants produced identical original/candidate canonical compiler-admission and TypeScript7 bytes; the fourth authored source `Cursor.ps` was accepted after making one higher-kinded local type's explicit v7 syntax unambiguous. The earlier full 20-module generated syntax bridge [38128357665](https://github.com/dwijayuda/pskernel/actions/runs/38128357665) selected the first v7-authored `Ps.Syntax.Translate.ps` only and was qualified on Linux, Windows and Lean RC4 **at that historical exact source identity**.

The next milestone must therefore **select all five v7-authored modules together in the actual complete 20-module generated syntax/foundation compiler closure**, with the original Lean source retained for the remaining 15 modules. This is distinct from merely testing the four small modules separately; the dependent elaboration environment and final generated compiler products must agree.

## Actual source-to-compiler route

The [Linux-only closure manifest](../pscv0-linux-source-closure.json) identifies the five exact source modules and the qualified cached frontend source commit `a640a2d22adeabd4ca7919839a8991667bcc3eae`. The [one-shot builder](../tools/abi/compiler-linux-closure.mjs) uses the exact saved [generated 20-module artifact from run 38128357665](https://github.com/dwijayuda/pskernel/actions/runs/38128357665) as the current v7 parser—not a newly handwritten JavaScript parser or an older .ps edition—and the exact retained self-host PSC0 compiler plus TypeScript 7.0.2. It verifies all 20 original frontend source SHA-256 identities before starting.

Input order is the **qualified original 20-module topological closure order** from the saved artifact, not a guessed module list. Each v7 source must match its corresponding retained Lean module name and import closure. The generated v7 parser and portable lowerer produce a source AST, which crosses the [closed versioned source AST ABI](../tools/abi/transport.mjs) into recipient-owned algebraic data type constructors. The immutable retained compiler **elaborates** that AST in the same ordered, pure preparation state used for the other source files. Source comments, positions and import identities are checked or produce explicit refusals rather than silently being discarded or reinterpreted as an old parser mode.

At the end of this single pass, the compiler emits the full candidate's canonical admission stream, TypeScript 7 program and Linux JavaScript. The acceptance requirement is **byte-for-byte identical admissions, TypeScript and JavaScript** to the already-qualified one-module `a640a2d2` generated artifact. A mismatch records the first differing source/target bytes and causes an explicit failure; the test cannot be made green by weakening assertions or falling back to the old source.

## Linux-only / no-kernel development mode

**Only `ubuntu-latest` runs. There is no Windows job and no Windows execution.** Windows portability is reviewed through host-independent path resolution (`path.join`, `pathToFileURL`), canonical logical module identifiers, platform-neutral UTF-8/source SHA-256 and TypeScript/JS semantics. These patterns are not evidence of Windows qualification and must not be labeled as such.

The one-shot builder **does not import an independent pskernel-core package, call `checkCanonicalAdmissions`, run Lean proof suites, rebuild kernels or change a trusted checker**. It does use the compiler's normal type elaboration, canonical admission serialization and TypeScript backend, as is necessary to exercise compiler source semantics. Its report explicitly sets independent checker false and fixed-point false. A successful compiler-only 20-module test is a major source migration checkpoint, **not** a verified executable release and **not** the complete 64-module compiler self-host fixed point.

This expensive 20-module rebuild is **milestone-only**. Routine edits remain on the fast Linux-only checked-source-identity loop with ~1–2 seconds of measured basic compiler process checks and tens of seconds for source dependency differential. Do not rerun the full milestone on every syntax/host/README change or create a second redundant compiler implementation.

## Acceptance pending and follow-ups

1. Compile the 20-source dependency closure with all five authored v7 modules selected in one pass, from the qualified baseline and immutable retained bootstrap.
2. Verify identical canonical admissions, TypeScript7 text and generated JavaScript SHA-256 to the historical qualified compiler product.
3. Run small Linux application-level smoke for list/token/cursor functions and generated parser exports, and retain the exact source-closure report, per-module source hashes, process timings and artifacts.
4. Only after actual green CI, record the source candidate identities and next compiler-module migration choices in `AI_WORK_STATE.md`. Windows and kernel checks remain deferred by user instruction.
5. Later, build a deliberate compiler-only C0–C3 fixed point and independent release qualification when authorized. Avoid treating five source modules as the whole PSC0 compiler.

**No result is asserted here before the new GitHub Actions job completes.**
