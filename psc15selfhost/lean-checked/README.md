# PSC2 checked compiler and owned kernel bootstrap

The default kernel is pskernel-core. The bootstrap entry includes all 15 owned
kernel modules alongside the compiler: 70 source modules across 13 packages.
The old core package and routing have been retired. Neither Lean provider is in
the portable closure; neither provider branch is wholesale-merged.

| Selector | Implementation | Role |
| --- | --- | --- |
| pskernel-core | PSC-generated owned JavaScript | Default; bounded checker fragment |
| lean434-wasm | Lean 4.34.0 kernel in WebAssembly | Explicit reference alternative |
| lean434 | Native Lean 4.34.0 kernel | Explicit reference alternative |

No failure, timeout, exhaustion, rejection or unsupported declaration triggers
fallback. Making the owned kernel the default does not complete its release gates.

The owned runtime checks closed universe-polymorphic transparent definitions from an empty
environment. Generated semantic transitions perform dependent typing, beta/zeta/delta
reduction, binding and universe normalization. Host code validates and converts the
wire representation, runs those transitions, enforces bounds and transports results.
A disposable worker enforces a wall clock limit; a shared transition budget stops
nested work. The generated module digest is checked before loading. Failure exposes
no checked environment.

The full joint bootstrap currently fails at admission 0: the universe-polymorphic
_pscCheckedNestedUnit inductive. Inductive admission, generated recursors,
prelude primitives, proof irrelevance and eta
remain required development work. See the exact measured checkpoint in
[OWNED_DEFAULT_BOOTSTRAP_2026-10-02.md](../docs/continuity/OWNED_DEFAULT_BOOTSTRAP_2026-10-02.md).

## Check before emission

Generated compilers prepare and freeze one module graph, encode admissions, invoke
the selected checker, and emit from that same graph. Checked handles are held in a
session-local WeakMap. Copying a handle or constructing a receipt cannot authorize
emission. The native seed uses a two-phase session: the host sends emit only after
the selected kernel accepts its admissions.

Receipts use schema 3 and kind psc2-checked-build. They bind the source closure,
compiler, actual provider identity, admissions and emitted hashes. They are audit
records, not transferable proof objects. Owned and Lean results have distinct identities.

## Commands

Run from psc15selfhost with the pinned Lean toolchain and TypeScript 5.8.3:

    node lean-checked/psc.mjs build Main.ps --seed lean-checked/.lake/build/bin/psc2_lean_checked_seed --out dist/checked-example/main.js
    node lean-checked/psc.mjs fixed-point

Select an explicit reference provider with --kernel lean434-wasm or --kernel lean434.
Outputs are isolated by selector under dist/checked/<selector>/{bootstrap,selfhost,repeat}.
Previously preserved dist/lean-checked outputs are not overwritten by the new path.

The fixed-point command fails while any required declaration is unsupported. Successful
checking and rebuilding of every generation, canonical source parity and exact TypeScript
parity establish its compiler fixed-point result. The joint release additionally requires
the generated owned kernel from each pair to check declarations used to build the next
pair. That release gate has not passed: the host currently uses the pinned package build.

## Reference identity

Both Lean transports use Lean 4.34.0 commit 293d5d0c0c3f3dded4688b3ccd6a33939ac5102b,
protocol pskernel-lean/1, provider lean4-cpp, profile lean4.34-core. Rebuilt Wasm source
checkpoint: 1b21b2483df7e8de7542873c24eaff2501539b1b. Provider execution and full
compiler admission pass. CI run 37014379617 was cancelled during its fixed-point
step and is not a completed fixed-point result.
