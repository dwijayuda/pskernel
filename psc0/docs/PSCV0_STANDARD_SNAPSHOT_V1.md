# PSCV0 Native Standard Environment Snapshot v1

## Latest qualified selected roster — 13 October 2026

**Newest independently qualified executable:** [`e0ac8c69c928261e21e9593ed3f2f4aa5157385a`](https://github.com/dwijayuda/pskernel/commit/e0ac8c69c928261e21e9593ed3f2f4aa5157385a), Linux GitHub Actions [38335736466](https://github.com/dwijayuda/pskernel/actions/runs/38335736466) **passed** (13 October 2026). This supersedes older executable-status statements below, which remain as preserved history. The pinned upstream is Lean 4.35.0-rc4 (`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`). The selected Standard now contains **234 declarations, 14 classes, 40 instances**, FNV `fnv1a64:403111548970955669`, SHA-256 `sha256:6e6f1fad15d4f0cb401a09c1ebc219c3f60dd50acb21061ca9eee4ab782bd85e`; portable/native closure remains 170/178 `.lean` modules with 198 shared runtime observations on TS, direct JS, Rust, and Wasm GC/Wasmtime.

The four additional checked declarations reconstruct `Decidable` as a computational decision with checked reflection evidence, rather than relying on the older opaque declarations. Both digest gates use the exact new selected AST payload and were tested by GitHub Actions. The older 230-declaration counts and fingerprints below are preserved historical baselines, not the current selected registry. This does **not** prove consistency, complete Lean compatibility or runtime correctness beyond tested observations.


**Status:** Reviewed and frozen *selected* 230-declaration source roster, not the full Lean RC4 Standard universe, dependency closure or ProofScript v7 conformance.

- Official Lean baseline: **4.35.0-rc4**, source commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.
- Selected native environment: `psSelfHostProdPreludeEnvironment`.
- Current qualified executable source: `fc8bc8b1f16ed993fb144e2d396c0760c068630b`; [all-green Linux run 38323422371](https://github.com/dwijayuda/pskernel/actions/runs/38323422371).
- Earlier 208-declaration FNV qualification: `c810d6fe15d064968008d09849efd9ac5b2820de`, [Linux 38292170524](https://github.com/dwijayuda/pskernel/actions/runs/38292170524). Portable SHA-256 first qualified in `2a75d31c`, [Linux 38295519668](https://github.com/dwijayuda/pskernel/actions/runs/38295519668); mandatory dual gate qualified `381ae99f`, [Linux 38295808926](https://github.com/dwijayuda/pskernel/actions/runs/38295808926).
- Snapshot records: **230 checked declarations**, **14 registered classes**, **40 ordered instance registrations**.
- Selected roster FNV: **`fnv1a64:17137083495666611555`**.
- Selected roster SHA-256: **`sha256:b0ddaa7acc463b9457aac13bd8f08a2f6f8e64bba32b76f7e469ebf1a973f08f`**.

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
registrations fail closed.
This mandatory validator is now called by direct PSCV0 elaboration, the native
multi-module project planner and once per native batch host invocation before
admission or executable emission. The host reports Standard integrity drift
at the `prelude` phase; it does not substitute for official Lean kernel checks. No crypto FFI or unchecked hash primitive is used.

The previous 212-entry freeze added four checked `List.take`/`List.drop`
and `List.rec`/`Nat.rec` worker definitions. The current 215-entry
selected roster adds exactly the kernel-checked `GetElem` inductive class,
constructor and method projection, with one extra class registration; no
List/Array `GetElem` instance has been installed. Its full selected
Core/class/instance/alias serialization and both digests were explicitly
reviewed and pinned at `e1d463e10cbf5edd817e362ed35b21ee82c8c85b` ([Linux 38304955212](https://github.com/dwijayuda/pskernel/actions/runs/38304955212)).

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

