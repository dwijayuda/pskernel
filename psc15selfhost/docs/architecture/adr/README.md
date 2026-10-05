# ProofScript architecture decision records

These ADRs record long-lived production-architecture decisions derived from the current bootstrap architecture, next-bootstrap design, post-PSC platform design, current codebase review, and external compiler/security/build-system research.

**Status convention**

- `Accepted design direction` — future work should preserve the decision unless a later reviewed ADR supersedes it.
- An accepted design direction is **not** a claim that implementation or formal proof is complete.

## ADRs

- [0001 — Preserve the semantic spine](0001-preserve-semantic-spine.md)
- [0002 — CheckedCore is a kernel authority capability](0002-checked-core-kernel-authority.md)
- [0003 — Separate construction IR from VerifiedIR](0003-construction-ir-and-verified-ir.md)
- [0004 — Own direct JS and Wasm backends](0004-own-direct-js-and-wasm.md)
- [0005 — Capability-sandbox third-party semantic plugins](0005-capability-sandboxed-plugins.md)
- [0006 — Hermetic content-addressed production builds](0006-hermetic-content-addressed-builds.md)

When superseding an ADR, add a new ADR and link both directions. Do not silently rewrite historical decisions after implementation depends on them.
