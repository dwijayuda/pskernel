# PSC2 checked compiler and owned kernel bootstrap

The default kernel is pskernel-core. The bootstrap entry includes all 20 owned
kernel modules alongside the compiler: 75 source modules across 13 packages.
The old core package and routing have been retired. Neither Lean provider is in
the portable closure; neither provider branch is wholesale-merged.

| Selector | Implementation | Role |
| --- | --- | --- |
| pskernel-core | PSC-generated owned JavaScript | Default; bounded checker fragment |
| lean434-wasm | Lean 4.34.0 kernel in WebAssembly | Explicit reference alternative |
| lean434 | Native Lean 4.34.0 kernel | Explicit reference alternative |

No failure, timeout, exhaustion, rejection or unsupported declaration triggers
fallback. Making the owned kernel the default does not complete its release gates.

The owned runtime checks closed universe-polymorphic transparent definitions and
zero-term-parameter unit and monomorphic zero/successor inductives. Generated
bootstrap checks its initial Nat declaration from an empty environment. Semantic
transitions validate natural literals and derive unit and Nat-like dependent recursors and perform dependent typing, beta/zeta/delta/iota
reduction, binding and universe normalization. Host code validates and converts the
wire representation, runs those transitions, enforces bounds and transports results.
A disposable worker enforces a wall clock limit; a shared transition budget stops
nested work. The generated module digest is checked before loading. Failure exposes
no checked environment.

The actual bootstrap prefix now admits `_pscCheckedNestedUnit` and fails at
admission 1, `PsSourcePos`, because its constructor fields require record
inductive support. Nat is now available through owned prelude checking. Prelude primitives, general recursors, proof
irrelevance, eta and the generated pair fixed point remain development work.
See [OWNED_NAT_LITERALS_2026-10-03.md](../docs/continuity/OWNED_NAT_LITERALS_2026-10-03.md).

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
