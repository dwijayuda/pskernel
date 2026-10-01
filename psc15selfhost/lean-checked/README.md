# PSC2 Lean-checked compiler profile

Work branch: `psc2/selfhost-lean-kernel`, based on compiler checkpoint `90d02086146fce06df6d0a720e50f340adcbf52a`.

This work continues compiler self-hosting with `@proofscript/pskernel-lean` as the checked profile's required kernel. It does not modify the separate `pskernel-one` workstream or claim a completed compiler fixed point.

## Boundaries

The twelve-package portable compiler closure remains unchanged. The original compiler-only `npm run fixed-point` and root CLI remain diagnostic/development paths; they are not silently relabeled as kernel checked. This directory supplies a separate Lake project and checked CLI. The imported provider package is the exact subtree `134d2a9d9866e14fb9c41e4dabbae4050310c367` from provider checkpoint `88b18bbcec82bad02cb3db8ee5b5b96cae91ae86`, with a narrowly hardened Node adapter (timeout and profile validation). No older compiler/resolver implementation is imported from that branch.

Pinned checking identity: Lean 4.34.0, commit `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`, protocol `pskernel-lean/1`, provider `lean4-cpp`, profile `lean4.34-core`. TypeScript is pinned to 5.8.3. CI verifies the native Lean commit before building.

The native seed parses and prepares once, revalidates canonical admissions, calls the real provider, then erases the same immutable Lean prepared value. The generated-JavaScript host path prepares once, freezes the semantic graph, associates successful admission with a private session handle, revalidates its canonical encoding, and emits from the same prepared object. No check-then-filesystem-reread operation is used for emission.

Only homogeneous `.lean` or `.ps` source projects are supported by this checked loader. Missing `.ps` imports must not fall back to `.lean` siblings. Generated workspaces reuse the manifest-aware resolver, including exact file-set/hash and real-path validation. The native checked path receives that same bounded in-memory snapshot instead of using the old native project resolver.

This host session is an integrity boundary for a trusted selected compiler and provider; it is not a sandbox against arbitrary malicious host/compiler JavaScript or a replacement of all portable compiler APIs with a universal CheckedCore type. The original low-level preparation/emission APIs remain available. Kernel acceptance is relative to the provider-owned prelude and declared assumptions, and does not prove erasure or backend correctness.

## Commands

Run from `psc15selfhost/`, with the pinned Lean toolchain and `tsc` 5.8.3 available:

```sh
npm --prefix lean-checked run build
npm --prefix lean-checked test
node lean-checked/psc.mjs --help
```

Before a full generated compiler exists, explicitly select the native checked seed:

```sh
printf 'def answer: Nat := 42;\n' > /tmp/psc2-checked-answer.ps
node lean-checked/psc.mjs build /tmp/psc2-checked-answer.ps \
  --seed lean-checked/.lake/build/bin/psc2_lean_checked_seed \
  --out dist/checked-example/answer.js
```

On Windows the native executable has an `.exe` suffix. The current integration workflow validates Linux; it is not new cross-platform release evidence.

Once the generated compiler has actually been built, omitted `--compiler` selects `dist/lean-checked/bootstrap/packages/compiler/index.js`. It never silently selects a native or unchecked fallback. `--kernel lean434` is the checked profile's only currently supported kernel selector and is the default. `pskernel-one` can be integrated through a separately reviewed provider selection later.

## Checked generation target

```sh
npm --prefix lean-checked run fixed-point
```

The command preserves the existing bootstrap prerequisite gates, checks the complete handwritten compiler closure with the native checked seed, emits canonical `.ps`, checks/emits the first JS compiler, and uses generated compiler generations to produce two further checked generations. Outputs live under `dist/lean-checked/{bootstrap,selfhost,repeat}`. It compares the existing canonical source and exact TypeScript compiler outputs. It does not count a standalone receipt inspection as an executed fixed point.

This complete target is still blocked by compiler-source compatibility. Its command graph being implemented is not evidence of completed generated-compiler execution. The current parser inventory must remain visible and a failing full target must fail CI.

## Artifacts and trust

Each successful checked build stores `.ts`, `.js`, `.d.ts`, `.js.map`, the checked canonical `.admissions.json`, and a `.checked.json` audit record binding source, compiler, admissions and emitted hashes. Kernel rejection occurs before output staging. `tsc` writes into staging with `--noEmitOnError`; final outputs are promoted only after success, and the receipt is written last. Existing outputs may remain after a failed new build and must be interpreted using their recorded hashes.

Audit receipts are identities/provenance records, not signed certificates or portable proof objects. A generation integrity check must not be presented as fresh kernel checking. `verify-selfhost` checks recorded identities and exact parity; only the full `fixed-point` invocation that rebuilt every generation can emit `PSC2_LEAN_CHECKED_FIXED_POINT: PASS`.

## Evidence discipline

The native seed tests include real frontend acceptance, real post-admission erasure/TypeScript emission, forged prepared encoding rejection, and a codec-valid ill-typed declaration rejected by the real kernel. The Node suite contains both real native-seed -> kernel -> tsc -> JS tests and explicitly bounded host/transport tests using doubles. No test-double result establishes full generated-compiler correctness.

The integration CI independently retains native build/tests, Node execution tests, source guards, whole-closure parser inventory, checked fixed-point failure and compiler-only replay diagnostics as artifacts. Read the exact completed run/head rather than inferring self-host success from an earlier passing component.
