# PSCV0 Native Standard Environment Snapshot v1

## Current qualification — M2+A checked equality and structure defaults (13 October 2026)

Executable `d7e28a3870cdc399eca3c63c6d305b10109d2eca`; [green Linux 38418209663](https://github.com/dwijayuda/pskernel/actions/runs/38418209663).
**276 shared runtime observations** (all prior 263 retained), four panic
contracts, **183 portable / 191 native modules**, profile
`pscv0-v7-native-bounded/49`. Official Lean RC4 kernel, independent upstream
deriving oracle, 92 semantic refusals, existing do/opacity checks, strict IR,
JS/TS/Rust, V8/Wasmtime GC/component/ABI, declarations/maps and project gates pass.

- `DecidableEq` derives checked decisions for non-indexed, nonrecursive
  families with independent runtime fields, including generic universes,
  empty families and dependent proof fields. It uses Eq.rec/congruence and
  existing dependent-context substitution; no BEq-to-equality axiom.
- `BEq` skips proof fields and shares the new recursor builder.
  `Inhabited` honors explicit structure defaults and still prunes unused
  parameter assumptions. Record/constructor completion uses the shared queue.
- Typed proof conversion is shared by application/let inference and
  unification. Different propositions and runtime values remain distinct.
  Record and deriving diagnostics retain their source/constructor owners.

Standard now has **294 declarations / 14 classes / 52 instances**. The only
additions are checked `DecidableEq`/`decEq` definitions; no new axiom,
primitive, class or global instance.
FNV `fnv1a64:8231265721298810139`;
SHA-256 `sha256:89c4125cc3ca36bf198421e64673659a0acdf0207004af46738d36d32fcfd540`.

[Design, reviewed Standard change and exact evidence](PSCV0_M2_A_EQUALITY_DEFAULTS_2026-10-13.md).
**Selected milestone complete; full M2, Phase A and v7 remain open.**
Continue **M2+A → M3+B → M4+C/D → M5/E**. Repr needs faithful Std.Format,
quoting and rendering; Hashable needs UInt64/mixHash and their audited runtime
correspondence. Keep indexed/recursive deriving and dependent computational
fields with M3's general data/transport/termination mechanisms. Broader M2
scheduling/scoping/scaling, selected APIs, the complete manifest and C5
retention/publication remain on the existing roadmap. Native Lean only;
no pskernel-core, self-hosting or compiler-source migration.

## Prior qualification — M2+A generalized answers and synthetic constraints (13 October 2026)

Executable `c6468b17ef8f0a97c9e0df76c1ffe49f35c68279`;
[green Linux 38411211335](https://github.com/dwijayuda/pskernel/actions/runs/38411211335):
**263 shared runtime observations**, four panic contracts, **182 portable /
190 native modules**. Official Lean RC4 kernel and independent oracle,
92 phase-specific semantic refusals, existing do/opacity checks, strict IR,
JS/TS/Rust, V8/Wasmtime GC/component/ABI, declarations/maps and project gates passed.
Standard remains 292 declarations / 14 classes / 52 instances, with unchanged
FNV `fnv1a64:5949916575031563783` and
SHA-256 `sha256:f33d923e45baf8aa5dfa6755819737acabc09daf6d60934eb232133acaad069f`.

Scoped natural term/universe answer templates now freshen on shared replay.
The graph retains generalized answers and checks each receiving target;
root answers cannot retain term parameters. One scoped queue handles expected
types, instance holes and mandatory omitted defaults for calls/records/proof
applications. The old instance-only retry loop is removed. Global registration
also checks synthesis order and determined outputs. All mechanisms remain
portable native Lean under official checking.

[Design, exact evidence and boundaries](PSCV0_M2_GENERALIZED_CONSTRAINTS_2026-10-13.md).
The type-polymorphic local-dictionary case is kernel-qualified and explicitly
refused at erasure pending higher-rank runtime IR. Nat-indexed dictionary
sharing is qualified across every existing target. Generalized graph evidence:
6 generators / 6 answers / 1 generalized / 1 freshened shared answer. Earlier
widths 1/8/32 retain 2 generators, 3 candidates and 7/21/69 transitions.

**This completes the selected M2+A milestone, not full M2, A or v7.**
Continue **M2+A → M3+B → M4+C/D → M5/E**. Remaining M2 includes broader
postponed syntax/tactic scheduling, scoping/depth parity, search scaling and C5
occurrence retention. Remaining A includes Repr/DecidableEq/Hashable, structure
defaults, proof-field deriving and the comprehensive manifest. Keep dependent/
indexed/recursive deriving with M3+B. No pskernel-core or self-hosting.

## Prior qualification — M2 + Phase A deriving (13 October 2026)

Executable `f1ce3840c1943c9f78be20a5428fd4adfa9053af`;
[green Linux 38403318952](https://github.com/dwijayuda/pskernel/actions/runs/38403318952):
260 shared runtime observations, four panic contracts, 180 portable / 188 native
modules. Official Lean RC4 kernel/oracle, semantic refusals, strict IR and all
existing JS/TS/Rust/GC-Wasm/component gates passed. Standard remains
292 declarations / 14 classes / 52 instances with unchanged M1 FNV/SHA digests.

Parameter/universe-aware `Inhabited` and independent nonrecursive `BEq` now
share one family telescope and checked instance-search path. Inhabited uses
RC4 two-pass constructor selection and prunes unused requirements. Structures
keep projection comparisons; fieldless/payload inductives share a recursor
builder with actual motive universes and fresh local identities.

M2 also gains actual-universe projection inference, common-successor maximum
normalization, and checked rigid-spine matching that can defer head-level
constraints until typed arguments determine them. No unresolved equality is
committed, and the generator/consumer ownership/replay contract is unchanged.

[Design, boundaries and qualification](PSCV0_M2_A_DERIVING_2026-10-13.md);
[prior graph invariants and growth evidence](PSCV0_M2_INSTANCE_GRAPH_2026-10-13.md).
**Follow M2+A → M3+B → M4+C/D**, then M5/E. Full M2, A and v7 remain incomplete.
The later qualification above adds generalized answer abstraction/freshening
and the selected shared constraint queue; keep dependent/indexed/recursive
deriving with M3+B. Repr/DecidableEq/Hashable and the other documented A gaps
remain open. Native Lean / official checking only; no pskernel-core or self-hosting.

## Current roadmap integration — readable outputs (13 October 2026)

The [source, historical-branch and qualification audit](PSCV0_READABLE_OUTPUT_AUDIT_2026-10-13.md) is now the
current output plan. JS/TS/Rust/WAT/WIT are implemented for the qualified native
subset; existing bounded Lean/PS printers and historical round trips are reusable,
but full C5 reconstruction is not implemented. Do not rebuild existing emitters
or merge unrelated historical backends.

M1 is complete at the executable/run below. Next: M2 + remaining A, then M3 + B,
M4 + C/D, and M5/E. Retain C5 source/binder/occurrence information alongside its
M2–M4 semantic owners; complete C5 source publication and correspondence under
M5/E after the required A–D language closure. This replaces the old blanket
C5-after-all-A–E scheduling rule. No new milestone track is added.

**Current code boundary:** the qualifications above cover bounded M2 instance
search, generic deriving, generalized answers and the selected shared constraint
queue. Full postponed-syntax/tactic scheduling remains open.
No C5 source emitter or source-authority migration was added. Native `.lean`, official checking,
GitHub source operations and Linux CI remain authoritative. No pskernel-core
or self-hosting; Wasm GC internally and linear memory only at explicit ABI boundaries.

## M1 completion checkpoint — preserved baseline (13 October 2026)

This section records the M1 completion baseline. The M2 qualification above
supersedes its executable status. Older pending-M1 statements are historical.

- **Qualified executable:** `c00e146bd5c97788a4a6a39221849973aeafda84`.
- **Green Linux CI:** [38388627512](https://github.com/dwijayuda/pskernel/actions/runs/38388627512).
- **250 shared runtime observations**, four shared panic cases, official kernel,
  independent RC4 oracle, negative/coherence and all existing backend gates passed.
- **292 declarations / 14 classes / 52 instances**; **175 portable / 183 native modules**.
- FNV: `fnv1a64:5949916575031563783`.
- SHA-256: `sha256:f33d923e45baf8aa5dfa6755819737acabc09daf6d60934eb232133acaad069f`.

M1 acceptance, selected universe/proof-automation scope, runtime-override ledger
and measured compiler/runtime costs are recorded in
[M1 completion evidence](PSCV0_M1_COMPLETION_2026-10-13.md). Generated JS still has substantial overhead
versus native Lean (roughly 492–3357x in these small batch measurements).
M1 completion does not establish performance parity, full M2/A/v7 completion,
or formal compiler semantic preservation.

**Accepted interleaving:** M2 with remaining A; M3 with B; M4 with C/D;
final M5/E qualification. Collect E evidence and apply measured M5 improvements
throughout. Continue the shared instance-search architecture alongside
the Phase A handlers that rely on it. Preserve native portable Lean,
official checking, GitHub source operations, Linux CI, branch/draft PR 109,
Wasm GC internals and explicit ABI-only linear memory. C5 is integrated as above; compiler-source migration,
pskernel-core and self-hosting remain deferred.

## Prior qualified checkpoint — M1 coherence and measurements (13 October 2026)

- **Executable:** `6a6037c311f306d82e43221ed527c7326e5785dc`.
- **Green Linux qualification:** [38387492672](https://github.com/dwijayuda/pskernel/actions/runs/38387492672).
- **246 shared runtime observations**, all prior observations retained, four panic
  contracts, official kernel/RC4 oracle and all backend gates passed.
- Standard remains **292 declarations / 14 classes / 52 instances** and
  **175 portable / 183 native modules**, with the Array checkpoint digests below.

Explicit high-priority custom optional dictionaries take precedence over the
generic default. Direct and Fin-adapted lawfulness refuse the deliberately
unlawful optional implementation. Independent RC4 negative cases passed.

Controlled samples now exist in the CI artifact's `m1-performance/` directory.
At 16/128 declarations, checked-index elaboration medians were 2/15 ms versus
1/2 ms for direct-return bodies under identical binder telescopes; prelude
admission was 8 ms. Phase timings are recorded separately.

Generated JS lookup/conversion costs are substantially above native Lean:
the first measurement shows roughly 451–3206x batch-time ratios across these
small operations. Array and List-head lookup remain roughly size-independent;
List-tail and conversion costs grow with size. This is evidence of significant
remaining runtime overhead, not high-performance parity or a formal complexity
proof. Native Lean uses a different runtime and optimized standard library.
Retain the raw samples, setup exclusions and checksums when comparing changes.
M5 should address shared calling conventions, specialization and allocation,
not add Standard-name-specific backend shortcuts.

**Final M1 qualification is still pending** for the runtime-override ledger and
remaining representation-boundary probes (partial conversions, Array elimination,
empty Fin access and position coverage). Tail benchmark repetitions are reduced
from 128 to 16 per sample to keep routine CI economical while retaining five
measured samples and matched native/JS workloads. This changes measurement
duration, not correctness or acceptance criteria.

## Prior qualified checkpoint — M1 checked Array and conversions (13 October 2026)

This section supersedes older implementation-status statements below.

- **Executable:** [af96aa405a2b2f94df9a5dada607b4fc455fc624](https://github.com/dwijayuda/pskernel/commit/af96aa405a2b2f94df9a5dada607b4fc455fc624).
- **Green Linux qualification:** [38386745772](https://github.com/dwijayuda/pskernel/actions/runs/38386745772), official Lean 4.35.0-rc4.
- **Selected Standard:** 292 declarations, 14 classes, 52 ordered instances; 175 portable / 183 native modules.
- **Frozen FNV:** `fnv1a64:5949916575031563783`.
- **Frozen SHA-256:** `sha256:f33d923e45baf8aa5dfa6755819737acabc09daf6d60934eb232133acaad069f`.
- **244 shared runtime observations** passed in JS, strict TS, Rust, V8 Wasm GC and the native Wasmtime component host. All prior 198 remain.
- Four shared panic contracts passed, including empty Array bang access.

Array now has a checked List-backed logical model, actual size bounds, proof
access, optimized optional/bang dictionaries and both checked lawfulness laws.
The seven previous selected Array primitive axioms are replaced by checked
logical definitions. Efficient backend intrinsics remain a separately audited
runtime boundary; kernel checking is not a proof of backend equivalence.

Explicit Array.mk/List.toArray conversion uses a typed sized builder with
prepared List metadata. Every backend allocates private array storage and
traverses linearly; no backend hardcodes List tags or copies each persistent
prefix. Array.toList uses a typed fold and checked reverse, also linear.
Persistent updates, oversized indices, Fin adapter behavior and Nat/Bool
conversion cases passed. Array and List remain selected Type-0 collections;
Option and generic indexing/adapters retain the qualified universe closure.

**M1 remains incomplete pending final evidence:** explicit adverse-dictionary
coherence/priority checks and representative compiler/runtime performance
comparisons. Full M2 begins only after M1 acceptance, then interleaves with A.
No C5, self-hosting or pskernel-core.

## Prior qualified checkpoint — M1 List/Fin indexing (13 October 2026)

This section supersedes older checkpoint claims below.

- **Executable:** [e73ce2bbff522e5888a409b7b114042877d71943](https://github.com/dwijayuda/pskernel/commit/e73ce2bbff522e5888a409b7b114042877d71943).
- **Green Linux qualification:** [38384869133](https://github.com/dwijayuda/pskernel/actions/runs/38384869133), official Lean 4.35.0-rc4.
- **Selected Standard:** 277 declarations, 14 classes, 49 ordered instances; 173 portable / 181 native Lean modules.
- **Frozen FNV:** `fnv1a64:1660797324209886684`.
- **Frozen SHA-256:** `sha256:1937840a8a4fda1612e3e03e17860b4abad97b355beb6a896eee4c2171abbb3d`.
- **227 shared runtime observations** passed in direct JS, strict TS, Rust, V8 Wasm GC and the native Wasmtime component host. All prior 198 observations remain.
- Three panic cases passed in JS/TS/Rust and V8/Wasmtime core/component execution.

Qualified: checked Fin structure and original-predicate-preserving Nat-to-Fin
index adapters; List proof/automatic/optional/bang access; both List lawfulness
proofs; matching Fin adapter lawfulness. Optional List access uses a single
structural traversal, without a preliminary length pass. The official kernel
accepted every added logical definition. The pinned source oracle, negative
invalid-bound cases, strict IR and existing integration gates passed.

One family-parameter classification now erases numeric datatype parameters
without erasing ordinary computational Nat function arguments. List.get's Fin
value survives while its bound proof does not. A Fin bound does not authorize
access to a smaller collection. The selected List universe is still Type 0;
Option and generic Fin adapters retain their qualified universe parameters.

**M1 remains incomplete.** Next: checked Array logical model, genuine size-bound
indexing, explicit linear-time logical/runtime conversions, alias/large-index
coverage, and controlled representative performance comparisons. Full M2 starts
after M1 acceptance, interleaved with feature A as the user requested. C5,
pskernel-core and self-hosting remain excluded.

## Prior qualified checkpoint — M1 universes and bounded index proofs (13 October 2026)

This section supersedes older checkpoint claims below.

- **Executable:** [4fe35ca32b8f3b49f85b89bb9b699d95f7fd7b7d](https://github.com/dwijayuda/pskernel/commit/4fe35ca32b8f3b49f85b89bb9b699d95f7fd7b7d).
- **Green Linux qualification:** [38382777891](https://github.com/dwijayuda/pskernel/actions/runs/38382777891), official Lean 4.35.0-rc4.
- **Selected Standard:** 258 declarations, 14 classes, 43 ordered instances; 171 portable / 179 native Lean modules.
- **Frozen FNV:** `fnv1a64:7381279441732502588`.
- **Frozen SHA-256:** `sha256:c1444324de1014fa01b9c82fb09f2a6ab96b824ac08ae6b6e548e2145fd61c85`.
- **215 shared runtime observations** passed in direct JS, strict TS, Rust, V8 Wasm GC and the native Wasmtime component host. All prior 198 observations remain.

Qualified: universe-polymorphic Option constructors/recursor, map/bind/getD/filter,
BEq and Inhabited; GetElem?, default implementation and both LawfulGetElem laws
at the element universe; higher-universe dictionary synthesis and erasure.
Explicit Option.bind may change universes; monadic Option do fixes a single
universe as RC4 does. An independent oracle and a negative do case cover that boundary.

Index automation now constructs checked natural-order proofs from definitional
normalization, closed comparisons, successor rules and bounded local transitivity
search. It is not full omega. Large natural indices remain arbitrary precision.
The unifier first tries congruence for a shared named application head, retaining
dictionary argument identity; failure rolls back and uses ordinary reduction.
This avoids unfolding an inferable dictionary argument into applied metavariables.

The official kernel admitted the selected definitions and source proofs; strict
IR and all existing runtime gates passed. Single-run all-target timings: parse
110 ms, elaborate 93 ms, prepare 121 ms, kernel 70 ms, erase 251 ms, emit 494 ms.
These are observations, not a controlled performance comparison.

**M1 remains incomplete.** Next: checked List/Fin indexing and optimized optional
laws, Array logical model and genuine size bounds, panic/alias/large-index coverage,
and controlled representative performance comparisons. Full M2 waiter tabling,
C5, pskernel-core and self-hosting remain excluded. Read live HEAD and CI first.

## Prior qualified checkpoint — M1 natural order (13 October 2026)

This section supersedes older status statements below; historical evidence is preserved.

- **Executable:** [064baf31641ff19785feae1416eb353b38737794](https://github.com/dwijayuda/pskernel/commit/064baf31641ff19785feae1416eb353b38737794).
- **Green Linux qualification:** [38379674588](https://github.com/dwijayuda/pskernel/actions/runs/38379674588), official Lean 4.35.0-rc4.
- **Selected Standard:** 258 declarations, 14 classes, 43 ordered instances.
- **Frozen FNV:** `fnv1a64:10485782345918084284`.
- **Frozen SHA-256:** `sha256:37a8c7e027c548b59a82060556e194051867ee10d02e5b02b1f20c4875693ce5`.
- **Native closure:** 171 portable / 179 total Lean modules.
- **Runtime observations:** 206 shared cases, preserving the previous 198; direct JS, strict TS, Rust, Wasm GC and Wasmtime component gates passed.

Qualified additions: Prop-only Nat.le recursor; checked zero, successor,
transitivity, predecessor/inversion and impossible-zero proofs; checked
Nat.ble logical model; checked Boolean reflection; Nat.decLe/Nat.decLt
dictionaries. Decidable.intro and its computational projection now erase
consistently to Bool. The reflection field is erased, not trusted as an
unchecked witness. Runtime comparison keeps the existing Nat.ble intrinsic.

The same run checked the independent RC4 source oracle and false-bound
rejection, admitted source proofs with the official kernel, validated strict
IR and qualified emitted artifacts. This is **not a compiler correctness
proof or full M1 completion**. A single measured all-target application run
reported prelude 10 ms, parse 98 ms, elaborate 93 ms, prepare 297 ms,
kernel 66 ms, erase 112 ms and emit 455 ms; these are observations, not
controlled performance comparisons.

**Next M1 dependencies:** universe-polymorphic Option/GetElem?/laws and
universe-aware do binding; bounded proof-producing index automation; complete
List/Array/Fin indexing, optimized optional laws, coherent panic behavior and
representative performance comparisons. Full M2 tabling, C5, pskernel-core
and self-hosting remain excluded. Re-read live HEAD and CI before editing.
Do not repeat the older Decidable-uniqueness work: it was already qualified.


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

