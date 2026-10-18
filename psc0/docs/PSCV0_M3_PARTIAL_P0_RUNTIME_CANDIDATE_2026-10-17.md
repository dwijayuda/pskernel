# M3+B selected ordinary partial P0 executable candidate — NOT YET QUALIFIED

**Candidate only:** native portable PSC0 `.lean`, pinned Lean 4.35.0 `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. No full P0 or M3+B acceptance claim until exact native/F1/F2/F3-F4/focused qualification.

## Logical/runtime separation (source owned)

The existing `Ps.Elab.Command.psElabPartialCommandBatch` has already checked a public `opaqueDecl f : T := inhabitant` and retained the actual source body as private `partialDecl f.0 : T := body`. The canonical `psCompilerLogicalCheckingView` lets the *official kernel* independently check the public logical inhabitant and the private actual body's typing; it establishes **no equation** `f = body` and no termination/refinement theorem.

This candidate adds `psCompilerOrdinaryPartialRuntimeDeclarations`, a **runtime-only** transformation after actual `Ps.Host.NativeV7.checkWithScopedHeartbeats` succeeds. The transform finds a uniquely matching private `f.0` for each public logical opaque `f`, verifies exact universe-parameter and Core type identity, drops the private marker from the runtime *representation only*, and substitutes the actual source body for public `f` in the *runtime declaration view*. The **logical environment and canonical checking stream remain unchanged**. The shared checked erasure/IR/backend path consumes that runtime view; the general library `psCompilerVerifiedIrFromPrepared` still conservatively rejects arbitrary retained partial markers.

No unknown runtime type, fabricated proof, new axiom, reduction equation, or unchecked kernel-replay shortcut is accepted. This is the selected ordinary semantics of the actual body, not a theorem about its runtime behavior. Non-termination, traps, effects and resource behavior remain separate obligations and may be unsupported by selected targets.

## Explicit assurance identity and fail-closed verified refusal

The native host now has three *request* tags, with its existing development default explicitly `ordinaryChecked`. Accepted results include machine-readable `ordinary-checked`; any requested `closedVerified` or `boundaryQualifiedVerified` is **rejected at assurance phase before any artifact**, with no automatic ordinary downgrade. No verified output or boundary-assumption policy is implemented.

## Minimal selected conformance

The existing focused recursive-deriving suite gains one **nonrecursive selected partial function** `m3partial(n) := n + 5`; a native Lean partial function oracle and `m3partialoutput : Bool → UInt64` independently distinguish the *actual executable body* from the public logical inhabitant (for input values 9 and 17). Direct JS, strict compiled TS, Rust, V8 GC and Wasmtime verify both outputs under the unchanged scalar ABI; original observations and phase-correct refusal cases remain. A separate explicit closed-verified request for the same source must fail with `PSCV0-ASSURANCE-DOWNGRADE` and zero published artifacts. The general partial marker's logical opacity proof checks from earlier M3 remain intact.

**Not included:** selected recursive partial functions/loops, broad divergence/trace semantics, mutual partial groups, verified partial model/body refinement, fixedpoint P1, contracts/effects, assumption expansion or complete M3+B. If runtime lowering fails, correct the shared source/body ownership; do not emit the logical inhabitant or weaken a kernel/erasure/IR check.

**Qualification:** exact same-SHA full native 33-step, F1, F2, F3/F4 and focused oracle/JS/TS/Rust/Wasm. PR109 draft/open/unmerged, original base. Current M2+A, deriving, shared positive nested container and performance receipts immutable.
