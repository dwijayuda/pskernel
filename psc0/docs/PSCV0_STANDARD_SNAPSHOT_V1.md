# PSCV0 Native Standard Environment Snapshot v1

**Status:** Frozen, bounded semantic environment snapshot, not full ProofScript v7 conformance.

- Lean baseline: **4.35.0-rc4**, source commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.
- Selected native environment: `psSelfHostProdPreludeEnvironment`.
- Qualified snapshot source: `c3445fc108856617e20aa86b64ca35a19a513425`.
- Successful Linux Actions: https://github.com/dwijayuda/pskernel/actions/runs/38291606077
- Snapshot records: **208 checked declarations; 11 registered classes; 36 instance entries**.
- Fingerprint: **`fnv1a64:3890664716772208725`**.

## Canonical encoding and scope

`Ps.Environment.StandardSnapshot` deterministically serializes every installed
Core declaration, including declaration kind, names, universe parameters,
types, values/axioms, constructor and recursor metadata and recursive
field identities. It also serializes class identities, class input/output
metadata, priority-ordered instance values/types/priorities and source aliases.

Every node is tagged and every child field is length-prefixed by its UTF-8
byte size. Structural names distinguish numeric and string segments;
literals, binder kinds and levels remain distinct. The fingerprint uses
FNV-1a 64-bit on the UTF-8 serialization with explicit arbitrary-precision
Nat modulo `2^64`; it is reproducible across supported native Lean targets
and not dependent on pointer width or platform hash seeds. The snapshot
includes the pinned upstream Lean source identity.

This hash is **non-cryptographic**. A collision, malicious replacement or
altered compiler is not independently ruled out by the fingerprint.
The existing `psStandardExceptAudit` checks the exact selected signatures,
declaration bodies and instance priorities before the expected fingerprint
is compared. A compact refusal demonstrates that an otherwise installable
additional source alias changes the snapshot.

## What is not yet frozen

This is not the full RC4 Standard registry, a content-addressed cryptographic
supply-chain root, a successful kernel model/consistency proof, or an
assumption-free verification certificate. It does not yet include every
upstream notation/coercion/deriving handler/module import identity, tactic
registry, effect capability or complete axiomatic/erasure closure. These
remain mandatory for full v7.

Any intentional addition to the selected Standard environment should
recompute the fingerprint under Linux CI, re-audit types and bodies,
update the expected fingerprint, and record the source SHA and CI evidence.
Never rebase the acceptance criterion to an observed arbitrary value without
reviewing the semantic changes that caused the drift.
