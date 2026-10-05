# PSC15 / PSC2 Workstream Coordination

Status: active coordination policy for parallel development.

This file records the division of responsibility agreed after two ChatGPT sessions were discovered to be committing to the same branch concurrently.

## Branch ownership

### `psc2/minimal-selfhost-psc15`

Authoritative owner: the **minimal PSC2 self-host workstream**.

Purpose:
- build the smallest stable PSC2 self-host compiler inside `psc15selfhost/`;
- use official Lean 4 + Lake as the temporary bootstrap host;
- write the portable compiler in the PSC1-compatible `.lean` subset;
- generate canonical `.ps` source and close a repeatable self-host fixed point;
- keep TypeScript/JavaScript as the single bootstrap backend;
- keep the semantic compiler backend-neutral and keep Rust/Wasm outside the fixed-point dependency closure;
- preserve package boundaries while shrinking the bootstrap dependency closure;
- keep kernel/provider integration as an explicit seam rather than silently enlarging the bootstrap TCB.

This is the main branch for self-host architecture and compiler/bootstrap work. Future work on this branch must prioritize fixed-point correctness, bootstrap closure, portable source discipline, frontend/elaboration, admission-ready boundary, erasure, VerifiedIR, TS bootstrap composition, source generation, and self-host gates.

### `psc2/pskernel-core.old3`

Authoritative owner: the **minimal trusted kernel-core workstream**.

Purpose:
- develop `psc15selfhost/packages/pskernel-core.old3` only as the new small portable kernel implementation;
- use the mature `psc15selfhost/packages/pskernel` implementation as reference/oracle where appropriate;
- implement and test foundational semantics such as Name, Level, Expr, substitution/instantiation, declarations, environments, reduction, definitional equality, type checking, and later kernel admission;
- keep `pskernel-core.old3` outside the active self-host bootstrap closure until its integration milestone is explicitly accepted;
- avoid changing compiler/bootstrap architecture merely to make kernel development convenient.

The branch was created from shared head `72f32ac718ae75725ca3d63aa28477bccf897927` so no kernel-core work already committed on the previously shared branch is lost.

## Why the split was necessary

The two workstreams accidentally shared `psc2/minimal-selfhost-psc15`. After the minimal-selfhost commits, the same history accumulated many kernel-core commits (`Name`, `Level`, `Expr`, kernel gates and kernel plans) while self-host fixes continued in the same linear history.

From this point forward, do not use one branch for both workstreams.

Existing mixed history is preserved; do not rewrite or force-reset it merely to make history look cleaner. Separation applies to new work first. Later cleanup or selective integration can be done deliberately after both branches are stable.

## What this minimal-selfhost chat has been working on

The self-host workstream established these design decisions:

1. **Smallest stable semantic self-host, not all PSC2 at once.**
   The compiler implementation profile remains PSC1-compatible Lean while the accepted profile can grow as PSC2. A compiler does not need to use a feature in order to implement that feature.

2. **Lean 4 bootstrap.**
   `.lean` is the handwritten portable compiler source during bootstrap. Official Lean 4.34 + Lake builds the bootstrap compiler. Canonical `.ps` is generated and becomes authoritative only after parity/fixed-point gates.

3. **One bootstrap backend.**
   TypeScript/JavaScript is the fixed-point backend. Rust and Wasm remain valuable VerifiedIR consumers but do not block self-host closure.

4. **Backend-neutral semantic compiler.**
   `packages/compiler` must end at semantic compiler services / VerifiedIR and must not import target backends. Backend selection belongs at the composition edge.

5. **Tiny composition root.**
   `packages/bootstrap` selects the TS bootstrap backend and imports the portable compiler/library closure needed to produce the next compiler generation.

6. **Honest admission boundary.**
   The current compiler has an `AdmissionReadyModule` boundary. Canonical admission encoding is not falsely called `CheckedCore`. Real `CheckedCore` should appear only after an actual kernel provider admits the module.

7. **Future kernel seam.**
   Intended long-term path:

   ```text
   source
     -> parse / resolve / elaborate
     -> Core
     -> kernel provider
     -> CheckedCore / CheckedModule
     -> erasure
     -> VerifiedIR
     -> TS / Rust / Wasm / future backends
   ```

8. **Grow upward.**
   - ordinary capability -> library;
   - syntax convenience -> desugaring/elaboration;
   - proof construction -> Meta/tactic layer;
   - declaration generation -> controlled derive/plugin;
   - target-specific behavior -> backend or FFI/InterfaceIR;
   - kernel changes only for genuinely foundational proof-acceptance semantics.

9. **Post-fixed-point PSC2 growth.**
   Preferred early PSC2 usability features after the minimum fixed point are richer patterns, namespace ergonomics, method notation, practical local/mutual recursion lowering, and structured proof terms. Contracts/VCs, simplifier/automation, deriving, async/Task/Resource, FFI, large libraries and external plugin loading are platform growth, not initial self-host blockers.

## File ownership guidance

### Minimal-selfhost branch normally owns

- `psc15selfhost/packages/bootstrap/**`
- `psc15selfhost/packages/compiler/**`
- `psc15selfhost/packages/backend-ts/**` when required for bootstrap
- `psc15selfhost/packages/{foundation,syntax,core,environment,meta,elab,bridge,compiler-ir,erasure}/**`
- `psc15selfhost/host/**`
- `psc15selfhost/scripts/**` for bootstrap/self-host/fixed-point infrastructure
- `psc15selfhost/psconfig.json`
- `psc15selfhost/package.json`
- `psc15selfhost/lakefile.lean`
- self-host architecture, bootstrap and acceptance documentation

The main chat may read kernel packages but should not develop `pskernel-core.old3` internals in parallel with the kernel chat.

### Kernel-core branch normally owns

- `psc15selfhost/packages/pskernel-core.old3/**`
- kernel-core differential/parity tests
- kernel-core-specific source-profile checks
- kernel-core-specific plans/docs/gates

If kernel-core work requires a change to shared files such as `lakefile.lean`, `package.json` or bootstrap-closure scripts, keep that change as narrowly scoped as possible and do not make `pskernel-core.old3` part of the bootstrap closure unless an explicit integration milestone has been approved.

## Integration rules

1. Do not push new kernel-core feature work directly to `psc2/minimal-selfhost-psc15`.
2. Do not push self-host/compiler refactors directly to `psc2/pskernel-core.old3` except when synchronizing from the minimal branch.
3. Kernel work may periodically merge/rebase the latest minimal-selfhost architecture so it stays compatible.
4. Minimal-selfhost must not automatically absorb kernel-core changes just because they exist. Integration happens only when the kernel has a concrete provider boundary and the self-host branch is ready to consume it.
5. Before integration, require both workstreams' gates to pass independently.
6. Prefer PR/cherry-pick/selective merge for kernel integration so the semantic boundary remains reviewable.
7. Never weaken bootstrap gates, differential tests, or soundness checks merely to reduce merge friction.

## Immediate next steps

### Minimal-selfhost workstream

Continue reducing and verifying the bootstrap closure, run/fix the real Lean/bootstrap/self-host/fixed-point gates, keep `pskernel-core.old3` excluded, and close the smallest stable PSC2 compiler fixed point before adding broad PSC2 features.

### Kernel-core workstream

Continue only on `psc2/pskernel-core.old3`, complete the minimal portable kernel in independently testable slices, and treat the mature PSC1 kernel / Lean 4.34 behavior as reference evidence. Do not modify the active bootstrap path until a deliberate kernel-provider integration milestone.

## Source of truth

For current code behavior, the repository and branch contents are authoritative. This document records workstream intent and ownership; it does not override executable gates or semantic evidence.
