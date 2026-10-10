# PSC0 checked-host P0/P1/P2 implementation checkpoint

This is host integration, not a new compiler, language version, kernel or proof system. The qualified `ps-0.9-r3`/strict-SH/1 source and selected seed remain unchanged. Existing kernel development belongs to another branch.

## Canonical owners

| Owner | Role |
| --- | --- |
| `npm-cli/checked-session.mjs` | Provider-neutral frozen prepared graph, session-local handles, exact admission re-encoding, revocation |
| `scripts/checked-prepared-session.mjs` | Thin existing-host adapter; retains its explicit historical provider identity/default |
| `npm-cli/snapshot.mjs` | Bounded byte capture, absent-input records, realpath checks, immutable digest and revalidation |
| `npm-cli/libraries.mjs` | Declarative npm source resolution with recorded metadata; no library JS execution |
| `npm-cli/source-graph.mjs` | Compiler-owned parsing plus bounded homogeneous source/import traversal |
| `npm-cli/build.mjs` | Installed CLI checking and emission through the shared session, source revalidation and pinned toolchain |
| `npm-cli/publication.mjs` | Private immutable generation, writer lock, single executable entry-point switch |
| `scripts/npm-host-packaging.mjs` | Shared complete host staging for release and retained-runtime qualification |

The CLI no longer has its own independent prepare/check/emit sequence. Existing checked-build scripts reuse the same neutral session owner; their historical provider selection is not silently changed to a different kernel. Kernel code and its JS adapter are unchanged.

## Output contract

`psc build Main.ps --out Main.js` now publishes an ES-module entry point that re-exports a complete immutable generation under `.psc-artifacts/`. That generation contains the actual generated `.ts`, `.js`, `.d.ts`, source map and JSON receipt. A failed build does not switch the entry point. The JSON result identifies the canonical files and hashes.

Copy `.psc-artifacts/` with the entry point. A requested `.ts` entry is a TypeScript module re-export; the actual generated TypeScript is in the immutable generation. This avoids misrepresenting five independent file renames as an atomic transaction. Old generations are retained; garbage collection is deliberately not part of this checkpoint.

The guarantee is one local filesystem commit point under a trusted installation/OS, not a power-loss durability or hostile-OS guarantee. The receipt is audit data, never reusable proof authority. Target semantic preservation and full PSCV policy verification are not claimed.

## Cost-controlled compiler self-host preservation

The fast gate compares all twelve compiler source-package trees with qualified source `1fa5559a72b293defc56ef7e7020cf82d4b44b79`. It traverses the actual bootstrap import closure, rejects noncompiler dependencies and verifies seed/grammar/toolchain identity against the pre-change baseline. It also refuses changes to kernel implementation or its adapter.

Installed-host tests reuse immutable runtime artifact `11678641329` from successful run `38075437516` at `2f42a52814f3785ff2d92bd826f6e7fb3eb9bc8a`. They verify retained tarball and runtime digests, repack the current host, perform ordinary offline npm installation on Linux/Node22 and Windows/Node26, and compile both source editions. Compiler and kernel generation is **not repeated**.

This proves source preservation and bounded installed-host behavior. It does not create a new C2/C3 receipt. If compiler/language/seed/toolchain code changes, the guard fails; do not casually update its baseline. Run the corresponding compiler-only qualification deliberately before adopting such a change. Kernel self-hosting is outside the user's present scope.

The full npm generation workflow remains available through explicit `workflow_dispatch` only. Routine host edits use `.github/workflows/psc0-checked-host.yml`. No source-library conversion, new kernel build or full fixed-point is part of that fast edit cycle. If the retained artifact expires, renew it through a reviewed release; missing evidence must not trigger an unchecked fallback.

## Enforcement and limits

Budgets: 4 MiB per ordinary source, 32 MiB aggregate captured inputs, 2,048 observed files, import depth 128. Metadata and trusted-runtime reads have explicit larger caps within the aggregate budget. Inputs are revalidated after checking and before the public switch; source/package/lock drift, cycles, namespace changes, malformed UTF-8, output collisions and kernel failure refuse publication.

These controls do not sandbox malicious in-process JavaScript. No executable third-party plugin loading is introduced. Full frontend CPU isolation, complete axiom/effect/specification policies, lockfile-to-registry authenticity, cross-process durable checked authority, arbitrary guest isolation and formal code-generation preservation remain later architecture phases.

The initial test suite includes the existing checked-session tests plus source drift, absent metadata, symlink/junction containment, resource limits, source graph cycles, publication failure, input-overwrite and writer ownership cases. CI—not this text—determines pass status; consult `AI_WORK_STATE.md` for the actual qualified source/run.
