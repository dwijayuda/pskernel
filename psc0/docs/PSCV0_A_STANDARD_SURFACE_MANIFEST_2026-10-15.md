# PSCV0 M2+A — selected Standard surface manifest

## Current qualified checkpoint — 15 October 2026

**Qualified implementation: `38dbbfb9826490d02a44e6ab5b518a9946849345`.** [Native compiler/backend CI 38715710210](https://github.com/dwijayuda/pskernel/actions/runs/38715710210) and [independent portable Float replay 38715710273](https://github.com/dwijayuda/pskernel/actions/runs/38715710273) both passed at this exact commit. The subsequent handoff update changes documentation only.

Completed this continuation:
- **Checked Int arithmetic:** 28 native declarations/laws replace exactly four historical computational axioms; existing runtime intrinsics remain independently audited. Main `e322eff798a96db14b5deed24824ccf3c2fcc783` passed native38706796031 and Float38706795768.
- **Complete universe-polymorphic List indexing and actual kernel-counter isolation:** main `e5d1bdd6d667057bfd5376e8b39f3069f1dfc93c` passed native38711192827 and Float38711192777. One shared awaited pooled-task mechanism owns independent admission; source requests keep the cumulative 2,000,000-heartbeat /20,000-depth budget. IO allocation telemetry is a separate counter.
- **Logical Float constructors:** only 21 checked validity/constructor declarations plus Float.ofBits/Float32.ofBits typed wrappers are selected. The 307,290-byte source asset regenerates exactly (SHA-256 `3042b3db951a1c68f8df24c5161889841082f9f4ee03783e1e5b4da918b3f9a7`). Checked source accepts both widths and bit projections; wrong-width arguments and unsupported executable Float are refused.
- **Independent proof closure:** 30 roots /922 declarations /11 recursor rules, including the four mask-equivalence bridges, replay successfully with only propext/Quot.sound. The 11,097,675-byte audit asset (SHA-256 `564b48590fde9074679ec5e8d72f746fda4069f382b7cbcdd6101ba0c7bda622`) stays outside selected Standard.

The native workflow passed all 29 steps, including **699 existing observations each for JS, TypeScript and Rust**, GC Wasm/core and component validation, repeated native Wasmtime calls, asset byte comparison, source refusals and performance checks. These observations are scoped evidence, not backend metatheory or full v7 conformance.

Selected Standard: **1,879 declarations /25 classes /226 instances**. FNV `fnv1a64:9256054256618924345`; declaration SHA-256 `0f62a5df0a7273a183e10700bf8eb49563afd0ff8d03b7be3935d4d310a12f04`; surface SHA-256 `240050e325b7c7d06827c36bffe7ed017ef18680b61ccf4fa7701807a62874b4`.

**M2 + Phase A is NOT complete.** Next required work is F1 executable model erasure, typed IR, GC boxing, all backends and explicit ABI, followed by F2 arithmetic/equality, F3 scientific/conversions, F4 qualification, target-sized words and remaining authoritative language/Standard exits. The existing scalar-completion design records the studied Lean runtime representation and Canonical ABI dependencies. C5, self-hosting/bootstrap, compiler-source .ps translation and pskernel-core remain excluded.

No new trusted assumptions or proof placeholders. Native upstream Float correspondence still transitively imports Classical.choice and remains unselected. PR109 stays draft on its original base. Read live HEAD before further writes.

## Historical checkpoints (superseded by the current receipt)

## 15 October — surface digest frozen and per-project source graph candidate

The selected source-surface SHA-256 from complete CI 38653018583
(commit 078ec135da8b205400ba14a8ac3d68ac3fd23f71) is now frozen
to sha256:0bc4bfaa0f9afb9e0c1c58d652c51db8732530cd1b50b9e8772cca90f5bac0cf.
That independent strict gate complements both existing FNV/SHA checks
over the underlying selected Standard Core/instances/aliases.

New candidate: the native --audit-project-graph command consumes the
same path-safe source manifest and source-owned imports as the real project
compiler, refuses duplicate/missing/cyclic dependencies, resolves a
deterministic topological order and entry reachability, and hashes
actual source bytes, imported module identities, source paths, and the
selected global Standard-surface SHA into one project source-graph SHA-256.
The three-module CI fixture now emits project-source-graph.json.
This is a source-graph identity receipt, not a kernel proof, published
ABI-equivalence claim, or full transitive Lean import manifest.
Full M2+A remains incomplete; no pskernel-core, self-hosting, C5.

## 15 October — canonical Float model replay qualified; full selected-surface digest candidate

The native Float canonical proof model produced 24 officially checked
portable declarations and **no new axioms** at
[research CI 38652410627](https://github.com/dwijayuda/pskernel/actions/runs/38652410627),
commit `42eb74a26121be7f355ca273a959d475c166a3a1`.
This does not enable runtime Float or resolve the original full F1
List/Int incompatibility. The normal 27-gate executable CI runs separately.

**New native Phase A manifest candidate:** record a canonical length-delimited
digest over the selected operator/notation table, the actual deriving
handler roster, selected tactics, source/elaboration effect policies,
module policies, and ordered checked instances with class/priority/universes.
The human-readable JSON reports the new surface SHA-256 and underlying strict
Standard SHA-256 independently. `--audit-standard-surface` and native CI
publish this artifact; its deriving registry is checked against the *actual*
elaborator-owned handler list. This is still a **selected** manifest, not
a claim of complete transitive Lean module imports, all available effects,
or a full compiled-language semantics proof. The per-project import graph
remains validated separately. No trust/instance/class extension and no
pskernel-core, self-hosting or C5.

**Pinned upstream:** Lean 4.35.0, `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
**Accepted executable before this candidate:** `e871e4024d7ca9e3e3b85adc2b028ea7f9c33173`,
[CI 38634048433](https://github.com/dwijayuda/pskernel/actions/runs/38634048433).
**Scope:** selected P0/M2+A surface, not all Lean or full v7.

## Architectural decision

Do not mix distinct assurance artifacts. The existing
`psStandardSnapshotPayload` owns length-delimited exact declarations,
class metadata, ordered instance entries, reducibility and source aliases.
Both FNV-1a64 and SHA-256 expected values remain strict, and the official
Lean kernel remains the admission authority.

The native `Ps.Host.StandardManifest` adds the source-visible selected
notation table, deriving handlers, proof tactics, effect eligibility,
module behavior and the actual `axiomDecl` roster. Its notation entries
are checked directly against `psPscv0InfixInfo` on every regression run.
Unknown symbols remain rejected. Stated unsupported areas remain visible.
This is a separate audit of a bounded parser/surface manifest, not proof
that the *entire* Lean syntax extension registry has been captured.

## Pinned implementation references

- Lean 4.35.0 `src/Init/Notation.lean` for arithmetic/Boolean/logic/list
  precedence, including `infixl:65 +/−/++`, `infixl:70 */%`,
  `infixr:67 ::`, and `infixl:35/30 &&/||`.
- `src/Lean/Parser/Term.lean` and the native
  `Ps.Syntax.Pscv0.Operators`, `ProofRead`, `Module` readers for
  language/spelling/selected tactic and import behavior.
- `src/Lean/Elab/Deriving/Basic.lean` and selected
  `Ps.Elab.Deriving` handlers (Inhabited, BEq, DecidableEq, Repr, Hashable).
- `src/Lean/Meta/SynthInstance.lean` for the existing tabling and
  instance search reference. A bounded green search suite is not global
  equivalence with Lean's elaborator.
- `src/Init/Prelude.lean` and `src/Init/System/Platform.lean`
  for optParam, logical assumptions and nonconstant platform word width.

## Validation / omissions

The minimal native test invokes the existing dual strict registry gate,
then checks selected notation, records current axioms and verifies that
manifest sections render. It does not modify parser acceptance or instance
priority, inject a source axiom, change kernel checking, grant a new runtime
intrinsic or silently authorize a previously blocked Float or platform
operation. Until independent CI passes, this manifest implementation is a
candidate. Completing Phase A additionally requires the full pinned
module/import/notation/effect closure and the remaining runtime/scalar
semantics; this document does not assert the full exit is satisfied.
