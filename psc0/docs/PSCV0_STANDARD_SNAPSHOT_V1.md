# PSCV0 Native Standard Environment Snapshot v1

**Status:** Reviewed and frozen *selected* 212-declaration source roster, not the full Lean RC4 Standard universe, dependency closure or ProofScript v7 conformance.

- Official Lean baseline: **4.35.0-rc4**, source commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.
- Selected native environment: `psSelfHostProdPreludeEnvironment`.
- Current qualified executable source: `03ea9ac53664ce0c9b45ee4b23b09c284bf01264`; [all-green Linux run 38296669991](https://github.com/dwijayuda/pskernel/actions/runs/38296669991).
- Earlier 208-declaration FNV qualification: `c810d6fe15d064968008d09849efd9ac5b2820de`, [Linux 38292170524](https://github.com/dwijayuda/pskernel/actions/runs/38292170524). Portable SHA-256 first qualified in `2a75d31c`, [Linux 38295519668](https://github.com/dwijayuda/pskernel/actions/runs/38295519668); mandatory dual gate qualified `381ae99f`, [Linux 38295808926](https://github.com/dwijayuda/pskernel/actions/runs/38295808926).
- Snapshot records: **212 checked declarations**, **11 registered classes**, **36 ordered instance registrations**.
- Selected roster FNV: **`fnv1a64:9152255662807064572`**.
- Selected roster SHA-256: **`sha256:13e7007c324ca40d0d871d2bc4856084796dd451891d7a0096216e94197b211e`**.

## Canonical encoding and exact coverage

`Ps.Environment.StandardSnapshot` deterministically serializes each *installed
selected* Core declaration: kind, name, universe parameters, types and bodies,
constructor/recursor metadata and recursive field identities. It also records
class names and input/output metadata, instance types, values, priorities and
ordering, class identity and source aliases. All nodes are tagged; every
component is length-prefixed by UTF-8 byte length. The payload includes the
upstream Lean 4.35.0-rc4 commit and exact declaration representation.

Two **independent expected digests** now guard that same payload. FNV-1a 64-bit
is a fast reproducible drift detector and not cryptographic. The portable,
pure-native Lean SHA-256 computes the standard 256-bit digest of the canonical
UTF-8 bytes (FIPS 180-4 algorithm); it is tested against the published empty,
ASCII and Unicode known-answer vectors. `psStandardSnapshotValidate` must
first pass exact selected declaration/instance auditing, then match the
explicit FNV and SHA-256 constants. Wrong expected SHA-256 and added alias
registrations fail closed. No crypto FFI or unchecked hash primitive is used.

The four new declarations since the previous 208-entry freeze implement
`List.take`/`List.drop` and their checked `List.rec`/`Nat.rec`
workers. Their boundary cases were checked by Lean equality proofs before the
212-entry roster was explicitly reviewed and pinned.

## Limitations and remaining acceptance gates

A cryptographic digest protects integrity *of the encoded payload*; it does not
make an incomplete manifest complete or confer formal soundness. This payload
does **not** yet cover all official Lean RC4 declarations or upstream module
imports, notation, coercions, all deriving handlers, tactic registrations,
effects/IO/FFI capabilities, exhaustive assumptions and erasure provenance,
the external build supply chain or a metatheory/consistency proof.
Independent official Lean kernel admission and backend/primitive audits remain
separate from hash matching. Runtime preservation for newly added APIs on all
backends still requires its own observation corpus where not yet included.

For every intentional selected Standard change: review changed Core semantics
and trust inputs; run official Lean and negative tests; capture the new FNV
and SHA-256 **from the reviewed source**; update both expected values explicitly
and qualify the full Linux matrix. Do not auto-accept observed drift. Preserve
historical qualified source commits and CI evidence.

