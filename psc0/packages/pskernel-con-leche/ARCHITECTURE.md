# PSC0 / con-leche architecture study and integration contract

Inspected 17 October 2026. Branch base:
`psc0/pscv0-v7-native-lean-v1` at `77f5fe75ad2731c2d7e8445d7aa953c8d41827bb`.
This document governs ONLY the new alternative-checker package. It does not
supersede `psc0/ARCHITECTURE.md` or change the accepted compiler milestones.

## 1. Actual active compiler, not historical PSC2/PS0

The active architecture authority is `psc0/ARCHITECTURE.md`, whose operative
pipeline is syntax/scopes/meta/elaboration -> owned Core plus origins -> canonical
checked admissions -> official Lean 4.35.0 -> retained prepared graph -> typed
erasure -> validated compiler IR -> shared ECMAScript/TS, Rust and Wasm GC ->
provenance and host publication. The `.ps` language authority is v7.2. The
historical npm/self-host architecture and old provider metadata are not the
current kernel-selection contract.

The inspected implementation anchors are:

- `host/src/Ps/Host/NativeV7.lean`: `check` decodes canonical admissions,
  sets definition heights, and replays `Lean.Kernel.Environment.addDeclCore`;
  `checkWithScopedHeartbeats` preserves per-source budgets; private `compile`
  retains `output.prepared` after checking and gates assurance before erasure.
  A JSON success value is not permission to submit a replacement Core graph.
- `v7-native/lakefile.lean`: native host and shared portable `.lean` libraries;
  reuses `PsKernelLean` conversion/protocol modules, not its historical identity
  functions or an independent PSKernel executable.
- `packages/pskernel-lean/provider/PsKernelLean/Protocol.lean`: canonical format
  `proofscript-checked-admissions`, version 2; structured names, levels, expressions;
  constants include definitions/theorems/opaque values; inductive input holds
  parameters/type formers/constructors, not a complete lean4export record set.
  The file still has historical 4.34 provider metadata, explicitly not used by
  NativeV7. Copying that metadata into a new checker would be wrong.
- `packages/pskernel-lean/package.json`: historical Node/provider packaging;
  it cannot be copied verbatim and presented as native v7.2 registration.

The active roadmap forbids an independent kernel in its M3+B path. The user's
explicit request for this separate branch is implemented WITHOUT replacing that
path, altering its assurance grades, or touching existing kernel/backend packages.

## 2. Why preserve the upstream implementation

Upstream pin `b47ea19d6864a1fd09db6144528f91baa5c550dd` uses the same Lean 4.35.0
compiler. Its own names/levels/expressions, parser, inductive installer, definition
checking and cached checker are distinct from the official C++ kernel. The
executable fold separates installation from pending checks against environment
prefixes. Success must cover both phases. The verified-mode model theorem is
conditional on a set-theoretic model; it is not a blanket PSC0 correctness proof.

Use a pinned Lake dependency, not a textual port or duplicate kernel. This keeps
upstream's compiler-simplification equations, parser correspondence, pin matching,
checker refinement and model proof on the SAME revision. A port to another term
representation would create new proof obligations, not inherit them for free.

## 3. Implemented package boundary

```
complete lean4export NDJSON byte chunks
 -> byte budget
 -> upstream builtinPreludeE + parseChunks
 -> declaration-record budget
 -> upstream preparePrelude (retains input declarations)
 -> exact PSC0 input-axiom policy on the complete prepared stream
 -> upstream Cached.checkDecls .verified natOpPinSets
 -> CheckedInput indexed by those chunks and bounds
 -> diagnostic JSON only; no compiler publication authority
```

The runtime uses the sequential pure fold. We do not claim upstream's parallel
performance or recreate its worker pool. Every request checks a fresh complete
closure; there is no incremental/session acceptance cache. The proof library is
separate from the executable's runtime imports. Input-policy assumptions and
metatheorem assumptions are reported separately.

## 4. Why not fake a drop-in canonical adapter

Canonical admissions v2 and lean4export 3.x are different protocols. In particular,
con-leche's inductive records include recursor/type/constructor data with redundant
field checks; canonical PSC0 admissions ask the official kernel to construct those
members. Feeding one format to the other, omitting recursors, or trusting an
officially populated environment as if con-leche checked it would not be an
independent replay. The pinned built-in con-leche prelude is also NOT PSC0's full
selected Standard closure. This initial package therefore refuses canonical input
and does not claim `.ps` compilation integration.

## 5. Required promotion gates

1. Implement a dedicated portable `.lean` exporter of the exact retained PSC0
   prepared graph AND complete selected Standard/import closure. Preserve
   structured names, universe scopes, declaration order/visibility, opaque/partial
   distinctions, mutual/nested inductive and recursor information. Handle every
   unsupported shape by an explicit refusal. Do not re-elaborate source and silently
   check a different graph. Any use of official generated recursors in the export
   must be treated as untrusted input independently rechecked by con-leche.
2. Add a HOST-OWNED, explicitly requested secondary-check path only after that
   exporter is tested. Official Lean remains mandatory initially. Both checkers
   must accept the same retained logical graph before publication; disagreements,
   policy declines, missing dependencies, timeouts and crashes all block the
   requested dual-check result. No fallback to an easier checker.
3. Qualify representative current Standard, modules, dependent/recursive data,
   quotient/axiom audit, malformed universes/bvars, duplicate declarations,
   unsupported indexed projections/native-evaluation assumptions, stale receipt
   replay, partial logical/body separation and all target publication gates.
4. State and prove the source/Core/export correspondence needed by any stronger
   claim. Qualify the adapter proof against the exact pinned capstone, audit the
   actual axioms, and retain exact source/CI evidence. Only then consider a
   separately reviewed standalone alternative-authority policy.
5. Measure latency, memory, cancellation, larger exports, and optional use of
   upstream's proof-carrying parallel driver before claiming production suitability.

No C5, general backend preservation, self-hosting, release, registry migration,
PSKernel-C0 repair, or metatheory-branch merge is included in this package creation.

## Source locators

PSC0 source: `https://github.com/dwijayuda/pskernel/tree/77f5fe75ad2731c2d7e8445d7aa953c8d41827bb/psc0`.
Upstream source: `https://github.com/leanprover/con-leche/tree/b47ea19d6864a1fd09db6144528f91baa5c550dd`.
Key upstream files reviewed: `lean-toolchain`, `lakefile.toml`, `Main.lean`,
`ConLeche/{MainTheorem,Accepts}.lean`, `ConLeche/Driver/Run.lean`,
`ConLeche/Frontend/{Export,Prelude,Scan/Types}.lean`,
`ConLeche/Kernel/{Name,Env,Core}.lean`, `ConLeche/Cached/Installed.lean`.
