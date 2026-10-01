# PSC2 Lean-checked compiler profile

Work branch: `psc2/selfhost-lean-kernel`, based on compiler checkpoint `90d02086146fce06df6d0a720e50f340adcbf52a`.

This work continues compiler self-hosting with `@proofscript/pskernel-lean-wasm` as the temporary default checked provider and `@proofscript/pskernel-lean` as an explicit native alternative. It does not modify the separate `pskernel-one` workstream and does not claim a completed compiler fixed point.

## Boundaries

The twelve-package portable compiler closure remains unchanged. Both Lean providers are host/toolchain dependencies outside that closure. The original compiler-only `npm run fixed-point` remains a diagnostic/development path and is not silently relabeled as kernel checked.

The native provider snapshot comes from `psc2/pskernel-lean-provider` checkpoint `88b18bbcec82bad02cb3db8ee5b5b96cae91ae86`. The WASM package snapshot comes from `psc2/pskernel-lean-wasm` checkpoint `d6bd812e42b28893e60d52efa9b8a5d17f78e44f`; its real build, prebuilt verification, runtime admission, native/WASM differential parity, and packed npm consumer all passed in workflow run `36916202568`. The integration branch does not wholesale-merge either provider branch: only provider package snapshots and narrowly reviewed host integration are carried here.

Both providers identify the same pinned semantic implementation:

```text
Lean 4.34.0
commit   293d5d0c0c3f3dded4688b3ccd6a33939ac5102b
protocol pskernel-lean/1
provider lean4-cpp
profile  lean4.34-core
```

The execution selector is recorded separately in every checked build receipt. Native and WASM are therefore alternative transports/executions of the same Lean semantic provider, not two independent logical kernels.

## Default and alternative kernels

```text
lean434-wasm   @proofscript/pskernel-lean-wasm   default
lean434        @proofscript/pskernel-lean        native alternative
```

There is no automatic fallback. If the selected provider is missing, malformed, times out, reports a mismatched identity, or rejects the declarations, the checked build fails.

The WASM adapter verifies its bundled manifest before default execution, validates the full provider/profile identity, and applies a mandatory process timeout. The native adapter retains its verified package/prebuilt selection and source-checkout development binary path.

## Prepare once, check, then emit

Generated JavaScript compilers already use an in-memory prepared-session boundary: prepare one module, freeze it, encode its admissions, invoke the selected kernel, then emit from the exact same prepared object.

The native bootstrap seed now has a two-phase session protocol. It reads and prepares the flattened source once, returns canonical admissions, and waits. The Node host invokes the selected provider (WASM by default). Only after successful acceptance does the host send `emit`; the still-live seed then erases and emits from the same prepared Lean value. This avoids using the native provider merely because the seed itself is native.

The seed's existing `--test` path continues to exercise the native provider as an independent alternative/regression. Linking that test support into the bootstrap executable is not evidence that the production WASM-selected session called it.

## Source identity

Only homogeneous `.lean` or `.ps` projects are accepted by this checked loader. Missing `.ps` imports cannot fall back to `.lean` siblings. Generated workspaces reuse the manifest-aware resolver, including file-set/hash and real-path validation. The checked seed receives the same bounded in-memory flattened snapshot rather than the older parent-directory resolver behavior.

## Commands

Run from `psc15selfhost/` with the pinned Lean toolchain and TypeScript 5.8.3 available:

```sh
npm --prefix lean-checked run build
npm --prefix lean-checked test
node lean-checked/psc.mjs --help
```

Default WASM-checked build:

```sh
node lean-checked/psc.mjs build Main.ps \
  --seed lean-checked/.lake/build/bin/psc2_lean_checked_seed \
  --out dist/checked-example/main.js
```

Explicit native alternative:

```sh
node lean-checked/psc.mjs build Main.ps \
  --seed lean-checked/.lake/build/bin/psc2_lean_checked_seed \
  --kernel lean434 \
  --out dist/checked-example/main.js
```

The generated compiler defaults to `dist/lean-checked/bootstrap/packages/compiler/index.js` when available. It never silently selects an unchecked compiler or a different kernel.

## Checked generation target

```sh
npm --prefix lean-checked run fixed-point
```

This defaults to `lean434-wasm`. To exercise the native alternative explicitly:

```sh
node scripts/checked-selfhost.mjs fixed-point --kernel lean434
```

The command preserves the existing bootstrap prerequisite gates, checks the complete handwritten compiler closure, emits canonical `.ps`, builds the first JS compiler, and uses generated compiler generations to produce later checked generations. Outputs live under `dist/lean-checked/{bootstrap,selfhost,repeat}` and are compared using the repository's canonical source and exact TypeScript equality rules.

The full target is still blocked by compiler-source compatibility. Provider integration being green is not fixed-point evidence. The current replay frontier must remain visible and a failing full target must fail CI.

## Artifacts and trust

Each successful checked build stores `.ts`, `.js`, `.d.ts`, `.js.map`, canonical `.admissions.json`, and a `.checked.json` audit record binding source, compiler, semantic provider identity, selected execution provider, admissions and emitted hashes. Receipts are provenance records, not signed certificates or portable proof objects.

Kernel acceptance proves only that the selected pinned Lean provider accepted the submitted canonical declarations under its provider-owned prelude. It does not prove erasure or backend correctness. Native/WASM agreement is useful execution/differential assurance but is not independence of kernel semantics.

Only a real invocation that rebuilt and kernel-checked all configured generations and passed the comparisons may emit `PSC2_LEAN_CHECKED_FIXED_POINT: PASS`.
