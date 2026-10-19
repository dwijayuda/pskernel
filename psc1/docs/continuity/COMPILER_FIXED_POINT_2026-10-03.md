# Compiler-only fixed point — 2026-10-03

Branch: `psc2/selfhost-lean-kernel`.

Bootstrap pivot commits:

- `c4be878018001f3c71a1427a924e7e8bccc6085a` — Return bootstrap to compiler-only Lean WASM checking.
- `6598991a8e75b85f4d0806651f5d78d9b9908a9a` — Keep compiler bootstrap portable with host-side WASM checking.

## Bootstrap boundary

`packages/bootstrap/src/Ps/Bootstrap/SelfHost.lean` imports only `Ps.BackendTs.Compiler`. Every kernel package is outside the generated compiler bootstrap closure. The closure guard reports:

```text
PSC2_BOOTSTRAP_ROOT_MINIMALITY: PASS (1 direct imports; 55 ordered closure modules; compiler-only=55)
PSC2_BOOTSTRAP_CLOSURE: PASS (manifest-v2; 55 modules; backend-ts, bootstrap, bridge, compiler, compiler-ir, core, elab, environment, erasure, foundation, meta, syntax)
```

The default checked provider is `lean434-wasm`; `pskernel-core` and native `lean434` remain explicit alternatives. Provider rejection does not trigger fallback.

## Compiler fixed point

The canonical compiler-only fixed point completed successfully with the pinned TypeScript 5.8.3 toolchain.

```text
PSC2_CHECK: PASS (1916 declarations)
PSC1_SELFHOST_REEMIT_FILES: 55
PSC1_SELFHOST_REEMIT_CLOSURE_SHA256: ee6dd22f1b74b97113cc1a5e36aadad3cceecb2b152653f2c0dc26dd07aa22f7
PSC1_SELFHOST_SOURCE_FIXED_POINT: PASS
files=55
closure.sha256=ee6dd22f1b74b97113cc1a5e36aadad3cceecb2b152653f2c0dc26dd07aa22f7
PSC1_SELFHOST_FIXED_POINT: PASS
sha256=fb173a348d1555d1ff224b9977f6fee68591b79f781a6b292c2572648415b033
```

Exact generated artifacts:

| Artifact | SHA-256 |
| --- | --- |
| bootstrap compiler TypeScript | `fb173a348d1555d1ff224b9977f6fee68591b79f781a6b292c2572648415b033` |
| selfhost compiler TypeScript | `fb173a348d1555d1ff224b9977f6fee68591b79f781a6b292c2572648415b033` |
| bootstrap compiler JavaScript | `74dcebb7b296d81924d92987e99146b5d1c5ff9fbe3d8076ca591952d2ef7f76` |
| selfhost compiler JavaScript | `74dcebb7b296d81924d92987e99146b5d1c5ff9fbe3d8076ca591952d2ef7f76` |
| canonical generated source closure | `ee6dd22f1b74b97113cc1a5e36aadad3cceecb2b152653f2c0dc26dd07aa22f7` |

The bootstrap and selfhost manifests both contain exactly 55 generated `.ps` modules and the same closure hash.

## Portability evidence

The source-isolation harness reports **13 pass + 1 explicit POSIX-only skip on Windows**, because unprivileged Windows cannot create the symlink fixture. The same harness under WSL reports **14/14 pass**, including rejection of a symlink escaping the generated workspace. This skip does not weaken the POSIX security assertion.

The Lean build phase completed all **82 jobs** required by the compiler bootstrap path before the compiler semantic check and generation stages.

## Scope

This is a **compiler fixed point**. It deliberately does not claim an owned-kernel fixed point or joint compiler/kernel self-hosting. The next gate is to run bootstrap/selfhost/repeat through the default Lean 4.34 WASM checker and preserve the same generation integrity and parity.
