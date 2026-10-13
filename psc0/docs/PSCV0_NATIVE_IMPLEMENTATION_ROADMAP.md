# PSCV0 v7 native implementation roadmap

## Current qualified boundary — ToFormat/Repr (14 October 2026)

Executable `e565bbe6bab75baf4fa511640e1f82744f400032`;
[green Linux 38451656694](https://github.com/dwijayuda/pskernel/actions/runs/38451656694).
**341 shared runtime observations**, four panic contracts, **204 portable /
212 native modules**, profile `pscv0-v7-native-bounded/56`.
Official **Lean 4.35.0**, independent oracle, semantic/refusal/search checks,
strict IR, JS/TS/Rust, V8/Wasmtime GC, WIT/WAT/component/ABI, projects and
existing performance gates pass. Performance parity is not established.

Standard: **460 declarations /22 classes /88 instances**.
FNV `fnv1a64:2548399426123262483`;
SHA `sha256:79e34c4fd2bb8e491d624c86ccb644bf96b2442e090137d01b3c74ca72bfaeaf`.

Genuine ToFormat/Repr/ReprAtom/ReprTuple classes, checked scalar/collection
display methods, selected nonrecursive Repr deriving, precedence, quoting,
proof/type placeholders, UTF-8 soft lines, tuple flattening and fill layouts
are qualified. List and selected APIs/defaults/BEq retain element universes;
map/folds retain independent result universes. Array/Prod and proof-taking
List indexing retain their documented Type-0 boundary.

Shared fixes preserve aliases' actual raw lambda entry prefixes, complete
omitted defaults under unknown expected types, and retain empty Type-valued
class dictionaries as runtime singletons. Explicit OfNat Id follows upstream;
no broader instance transparency or special literal rewrite was introduced.

[Design, sources and qualification](PSCV0_A_FORMAT_REPR_2026-10-14.md).
**Full M2+A remains incomplete.** Continue Hashable/scalar dependencies,
remaining selected Standard APIs, comprehensive manifest, broader M2 evidence
and C5 semantic retention. Recursive/indexed/dependent deriving remains M3+B.

## Historical qualified boundary — stable Lean and pure Format (14 October 2026)

Executable `a2bcf0375c5f9acfa0d50847d44253657d5cd3cd`;
[green Linux 38443246672](https://github.com/dwijayuda/pskernel/actions/runs/38443246672).
**313 shared runtime observations**, four panic contracts, **198 portable /
206 native modules**, profile `pscv0-v7-native-bounded/55`.
Official **Lean 4.35.0** at `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`;
independent oracle, official kernel, semantic/refusal and graph gates, strict IR,
JS/TS/Rust, V8/Wasmtime GC, WIT/WAT/component/ABI, project and existing performance
gates passed. These measurements do not establish performance parity.

Standard: **394 declarations /18 classes /54 instances**, canonical v2:
FNV `fnv1a64:17804548636281664114`;
SHA `sha256:ec394b9e9c70bf92cb829060fcfee1e36aaf38f1f5e92b198a646c553ff259b1`.
The pure Std.Format algebra, measurement and renderer are ordinary checked
definitions over the shared IR, including hard-line/fill behavior, Unicode
columns, signed nesting, alignment and initial column. No formatting axiom,
backend formatter or new runtime primitive. WAT constructor discriminator names
are allocated separately from payload fields; physical indices are unchanged.

Quoting and checked Int.toNat remain qualified. Quoting comparisons use native
evaluation because upstream String.Internal.append is kernel-opaque; they are
not kernel equality proofs. Int runtime conversion preserves arbitrary precision.
Historical RC4 receipts retain their original identities.

Full M2+A is **not complete**. Next: ToFormat/Repr and remaining A/M2.


## Pinned Lean reference rule (14 October 2026)

Current pin: **Lean 4.35.0**, `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
[Migration and source comparison](PSCV0_LEAN_435_PIN_2026-10-14.md).
Before any feature design, implementation or redesign, study the corresponding
official implementation and relevant tests at this pin. Record algorithms,
data structures, semantics, invariants, optimizations and the comparison with
PSC0; justify simplifications and validate against Lean where applicable.
Retain licensing/attribution when adapting code. This applies to M0–M5,
A–E, C5 and all future development; do not preserve obsolete internals merely
for compatibility.


## Historical qualified boundary — M2+A transparency (13 October 2026)

Executable `35e239193e69cc466b81ac57282df1b1500f4927`;
[green Linux 38433276797](https://github.com/dwijayuda/pskernel/actions/runs/38433276797).
**293 shared runtime observations**, four panic contracts, **188 portable /
196 native modules**, profile `pscv0-v7-native-bounded/51`.
Official RC4 kernel and independent oracle, all existing semantic/refusal and
instance graph gates, strict IR, readable JS/TS/Rust, V8/Wasmtime GC,
WIT/WAT/component/ABI, project and performance gates passed.

Standard remains **308 declarations /18 classes /54 instances**. Its canonical
v2 payload includes declaration reducibility:
FNV `fnv1a64:1901246055571366448`;
SHA `sha256:799539fdf6557760d1c9134439ac6ea811915c7c6b054164310c11aa3e017136`.

Instance target/candidate preparation, selection unification and generator keys
now use pinned instance transparency. Checked evidence/default assignment uses
ordinary conversion. Flexible type inference preserves original checked terms
before delta reduction. Abbreviations and instance metadata survive imports.
The independent audit verifies selected upstream definition statuses.

[Transparency design and evidence](PSCV0_M2_INSTANCE_TRANSPARENCY_2026-10-13.md).
Full M2+A is **not complete**. Checked string quoting is the next implementation,
pending a strict digest review and all-target qualification.

## Current qualification — direct coercions and typed postponed results (13 October 2026)

Executable `35641f810e31f3c9d309c01028acd53ebe4112d9`;
[green Linux 38430940757](https://github.com/dwijayuda/pskernel/actions/runs/38430940757).
**293 shared runtime observations**, four panic contracts, **187 portable /
195 native modules**, profile `pscv0-v7-native-bounded/50`. Official RC4
kernel, independent oracle, all semantic/refusal gates, strict IR, readable
JS/TS/Rust, GC-Wasm V8/Wasmtime, WIT/WAT/components and project gates passed.

- Direct Coe, CoeFun and CoeSort use one checked class projection; no coercion
  chains or implicit lifting. Applications, annotations and expected types share
  these operations. Local dictionaries and APP-03 completion are qualified.
- Expected-term adaptation joins the transactional source/Core worklist.
  Mandatory defaults resolve before blocked result adaptation; failed attempts
  retain the original lexical scope and cannot leak assignments.
- Nonrecursive one-field wrappers whose erased uniform parameter determines
  their field use the concrete field representation. Type/proof-only fields
  erase; runtime fields depending on existential type fields remain refused.
  This does not introduce general higher-rank or existential runtime IR.

Standard: **308 declarations / 18 classes / 54 instances**, adding nine checked
coercion declarations and no global instances, axioms or primitives.
FNV `fnv1a64:946298686920218861`;
SHA `sha256:9afbebe8bf188a119b1bc223bc7f793da6f2dc08db9caa98e381d9e97662b234`.
See [direct coercion design/evidence](PSCV0_M2_DIRECT_COERCIONS_2026-10-13.md).

**M2+A remains incomplete.** The next source change introduces explicit
instance-search transparency, module-preserved reducibility and a reviewed
digest update; it is not yet qualified. Continue remaining Repr/Hashable,
faithful selected scalar/Float/BitVec/bytes/string/collection APIs, comprehensive
manifest, broader M2 coverage and C5 semantic retention. Keep the accepted
**M2+A → M3+B → M4+C/D → M5/E** dependencies and unchanged exit gates.
Native .lean and official Lean only; no pskernel-core, self-hosting or
compiler-source migration.


## Current qualification — M2+A scheduling, indexed lookup and literals (13 October 2026)

Executable `4d2e644d3974a6e6a4b68a15b7148bdb4f83e372`;
[green Linux 38425066964](https://github.com/dwijayuda/pskernel/actions/runs/38425066964).
**285 shared runtime observations**, four panic contracts, **186 portable /
194 native modules**, profile `pscv0-v7-native-bounded/50`.
Official Lean RC4 kernel, independent oracle, semantic refusals, strict IR,
JS/TS/Rust, V8/Wasmtime GC, WIT/WAT/component/ABI and project checks passed.

- One transactional worklist now serves Core constraints and captured source
  terms. Later arguments can determine record/lambda/tactic types; numeral
  fallback and mandatory defaults run after ordinary work reaches quiescence.
- Global instances are indexed by class while preserving priority/tie order.
  Generator buckets use rigid class plus lexical scope, followed by full
  definitionally-equal input checks. At 32 goals: zero generator comparisons
  across classes, 528 within one class. No general linearity claim.
- Numeric literals use genuine checked OfNat dictionaries. Typed Core
  application resolves class universes before search; deriving reuses it.
  Custom numeric types, local dictionaries and higher universes are qualified.

Standard: **299 declarations / 15 classes / 54 instances**.
The reviewed change adds OfNat/constructor/projection and Nat/Int dictionaries,
without new axioms or primitives.
FNV `fnv1a64:4206739069382061916`;
SHA-256 `sha256:00c6142b5f5b0e47abb8b317dc4fff3d595ab9f5e931822c4f48fca809758647`.

Direct Coe/CoeFun/CoeSort boundaries are implemented but **qualification is
pending** in subsequent source commits. They add nine checked declarations,
three classes and no global instances. Keep strict digest review.
See [scheduling and lookup](PSCV0_M2_POSTPONED_ELABORATION_2026-10-13.md)
and [direct coercion design](PSCV0_M2_DIRECT_COERCIONS_2026-10-13.md).

**M2+A is not complete.** Continue autonomously: remaining Repr/Hashable,
faithful scalar/Float/BitVec/bytes/string/collection APIs, comprehensive
module/notation/handler/tactic/effect/assumption manifest, broader M2 coverage
and C5 semantic retention. Keep dependent/indexed/recursive deriving with M3's
shared data/transport/termination work. Preserve
**M2+A → M3+B → M4+C/D → M5/E**; do not redefine the exit gates.
Native .lean, official kernel, GitHub source operations and Linux CI only.
No pskernel-core, self-hosting or compiler-source migration.

## Prior qualification — M2+A checked equality and structure defaults (13 October 2026)

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

## Architecture milestones and feature phases: execution order

M0–M5 and A–E are two dependency-linked views of one project, not sequential
checklists. Finish the current M1 acceptance boundary before full M2. Thereafter,
interleave coherent feature slices with their enabling architecture:

| Milestone | Architecture | Feature phase |
| --- | --- | --- |
| M0 | Shared typed erasure, proof/type/index masks, strict runtime IR | Foundation for A–E |
| M1 | Checked indexing and selected Standard closure | Indexing portion of A |
| M2 | Instance search, expected types, universes, priorities and rollback | Remaining A; enables B–D |
| M3 | Dependent/mutual data, elimination and total recursion | Primarily B |
| M4 | Class-driven effects, specifications, VC generation and assurance | Primarily C and D |
| M5 | Incremental compilation, validated optimization, tooling and performance | Consolidates A–D; final E integration |

A completes selected Standard APIs, deriving and the supported-language manifest.
B completes dependent data and total recursive programming. C completes typed
effects, state/control flow and explicit IO/FFI. D completes selected checked
tactics, specifications and verified-emission obligations. E establishes complete
conformance and cross-target integration evidence.

Collect E evidence with every feature slice; apply M5 performance/tooling work
when measurements and dependencies justify it. Do not delay all feature work
until M5: M5 acceptance itself requires A–E conformance. Do not implement feature
special cases ahead of their shared mechanisms. These dependencies do not claim
that M0's qualified subset or any later full milestone is already complete.

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


## Latest M1 foundation qualification — 13 October 2026

**Newest independently qualified executable:** [`e0ac8c69c928261e21e9593ed3f2f4aa5157385a`](https://github.com/dwijayuda/pskernel/commit/e0ac8c69c928261e21e9593ed3f2f4aa5157385a), Linux GitHub Actions [38335736466](https://github.com/dwijayuda/pskernel/actions/runs/38335736466) **passed** (13 October 2026). This supersedes older executable-status statements below, which remain as preserved history. The pinned upstream is Lean 4.35.0-rc4 (`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`). The selected Standard now contains **234 declarations, 14 classes, 40 instances**, FNV `fnv1a64:403111548970955669`, SHA-256 `sha256:6e6f1fad15d4f0cb401a09c1ebc219c3f60dd50acb21061ca9eee4ab782bd85e`; portable/native closure remains 170/178 `.lean` modules with 198 shared runtime observations on TS, direct JS, Rust, and Wasm GC/Wasmtime.

The selected RC4-compatible decision foundation has been replaced with checked `Decidable` structure, constructor, projections, Boolean reflection predicate and reducible dependent `dite`. Native metavariable-closed proof irrelevance unifies **actual proofs of the same checked Prop**, not arbitrary data or Bool terms. An official-kernel source oracle proves excluded middle from a provided `Decidable` and equality of any two witnesses of one proposition. The independently quantified decision-dictionary uniqueness theorem remains **unproved**, following a dependent-elaboration mismatch, and there is still **no generic `LawfulGetElem` instance**. List/Array/Fin indexing, Type-0 Option generalization and M2 waiter tabling remain unqualified. The older `fc8bc8b` milestone below is historical.


**New-chat handoff (13 October 2026):** `psc0/AI_WORK_STATE.md` and `psc0/AI_CONTINUE_PROMPT.md` now specify the M1-then-M2 implementation order. Last green executable remains `fc8bc8b`, [CI 38323422371](https://github.com/dwijayuda/pskernel/actions/runs/38323422371); newer documents are not executable qualifications. M1's checked optional default and target panic are done; generic lawfulness and collections are open. M2's scoped answer memo and independent budgets are done; generator/consumer waiters remain open. Keep native `.lean`, minimal milestone tests, no pskernel-core/self-hosting/C5.

## Latest qualified native compiler milestone — 13 October 2026

**Qualified executable SHA:** `fc8bc8b1f16ed993fb144e2d396c0760c068630b`.
**All-green Linux Actions:** https://github.com/dwijayuda/pskernel/actions/runs/38323422371.
**Official Lean:** 4.35.0-rc4 (`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`).
**Bounded source profile:** `pscv0-v7-native-bounded/48`, **not** complete v7.

**Newest qualified M1/M2 update (supersedes historical milestone prose below):**
The selected Type-0 `GetElem?` is automatically derived at low priority from a checked `GetElem` dictionary and a dependent `Decidable` function. Kernel-proof validity remains separate from runtime Bool. Executable `outOfBounds` has a typed multi-target panic path; the selected positive/negative optional observations passed. A general `LawfulGetElem` instance is NOT qualified: reflexivity cannot identify independently provided decision procedures. `Ps.Meta.SynthInstance` now bounds both candidate checks and goal visits independently, postpones unresolved inputs, and reuses validated completed answers. **230 declarations, 14 classes, 40 ordered instances, 198 shared runtime observations**. Detailed proof blocker and next dependencies are in [M1/M2 implementation audit](PSCV0_M1_M2_IMPLEMENTATION_AUDIT_2026-10-13.md). Full M1/M2 and v7 remain incomplete.

**Historical M0 checkpoint (superseded by the qualified M1/M2 update above):** The earlier Lean RC4-style `GetElem` typeclass and proof-carrying
`xs[i]`/`xs[i]'h` elaboration now qualify for user-defined instances.
The generated validity tactic tries genuine assumptions, definitional
reflexivity and fuel-bounded recursive constructor proofs, refusing
unresolved goals. At the M0 checkpoint, parsed `xs[i]?` and `xs[i]!` were **not yet executable conformance**:
the full `GetElem?`/default/lawfulness and out-of-bounds panic contracts
remain open. See [GetElem RC4 design/parity audit](PSCV0_GETELEM_RC4_DESIGN_AUDIT.md).

The **historical** selected prelude milestone was **221 declarations, 13 classes and
37 ordered instances**, at FNV `fnv1a64:4160132988510892817` and SHA-256
`sha256:a02c9f39e6de1830497114edfaad5e9bdd5730110b562585e3f6ecc30b80b6d3`. The source-closure guard passed
**170 portable / 178 native Lean modules**. All established **194 shared
JS/TS/Rust/Wasm runtime observations** and official Lean native checks
remain green. These are bounded qualification observations, not a proof
of full Lean RC4 Standard or complete v7.

Further Phase A work: universe-polymorphic `Option`/related Standard
prerequisites, actual indexed List/Array/Fin validity and lawfulness
proofs, `GetElem?`/panic boundaries, complete deriving and scalar/API
coverage, and pinned imports/notation/tactic/effect/assumption closure.
Phases B–E and C5 remain as documented below.

**Historical architecture audit (failed precursor, now resolved by M0):** `1cc7deb56b2b6ec37ee3a6c1eac148d113899ac7`, [Linux 38307096314](https://github.com/dwijayuda/pskernel/actions/runs/38307096314) failed at `ir/emit` because dependent `GetElem` predicate/index arguments become `unknown` runtime IR type annotations. Lean RC4 source-level oracle passed. See [`PSCV0_V7_LEAN435RC4_SOURCE_ARCHITECTURE_REVIEW_2026-10-13.md`](PSCV0_V7_LEAN435RC4_SOURCE_ARCHITECTURE_REVIEW_2026-10-13.md). **The last green executable remains `e1d463e10cbf5edd817e362ed35b21ee82c8c85b` and run 38304955212.**

**M1/M2 accepted subset:** See [native M1/M2 implementation audit](PSCV0_M1_M2_IMPLEMENTATION_AUDIT_2026-10-13.md) for precise status. `GetElem?` Type-0 selected and tabled positive-answer memoization passed 194 observations, but neither full M1 nor full M2 is complete. This supersedes the older “parsed only” status above and the historical GetElem audit statements.

## Current priority: core and essential language conformance first

Keep native portable .lean authoritative and preserve the qualified runtime
targets. M1 is complete at c00e146b / Linux 38388627512; the current matrix has
250 shared observations. M2 with remaining A is next, followed by M3/B, M4/C-D
and final M5/E. Full v7 remains incomplete.

The 12 October priority to finish semantics before full C5 publication remains
the guiding dependency. The 13 October integration refines it: retain source
information during M2–M4, then finish C5 under M5/E once required A–D semantics
exist. Compiler-source migration and self-hosting remain separate.

The canonical target is PSCV0_LANGUAGE_REFERENCE.md at its recorded v7 digest,
with Lean 4.35.0-rc4 semantics. Source preparation, official admission,
provenance, erasure, target execution and source correspondence are separate
assurance boundaries. Historical generated-source receipts do not certify the
current native source. Exact current evidence is recorded at the top of
AI_WORK_STATE.md and in the M1 completion and readable-output audits.

## Complete Phase A–E language-first execution plan (authoritative overview)

This is the full dependency plan for **core/essential `pscv0` v7**, not five independently measured percentage scores. Phases may overlap where dependencies demand it. All require checked native `.lean` semantics; no other proof kernel or unchecked runtime escape is permitted. Sub-phases and acceptance detail are also present at the TOP of `psc0/AI_WORK_STATE.md`.

| Phase | Focus | Status and completion evidence |
|---|---|---|
| **A** | Pinned Standard environment, selected P0 language and runtime APIs | **In progress.** M1 indexing/universe/proof closure is qualified: 292 declarations / 14 classes / 52 instances; the M2 graph is qualified with 251 observations. Remaining: broader deriving/scalars/APIs and comprehensive notation/import/effect/assumption manifest; develop these with M2 and later dependencies. |
| **B** | Dependent and mutual data, elimination, strict positivity and total recursive programming | **Planned.** Complete heterogeneous index reasoning, dependent motives, nested/mutual inductives, recursive pattern matrices and well-founded/structural termination; refuse invalid/partial constructs |
| **C** | General class-driven typed do, state, effectful control and explicit IO/FFI boundaries | **Planned.** Complete Monad/Except/State/Reader and selected transformers, mutable/erased state, loops/early returns, try/catch/finally, effect/capability evidence and all-target preservation |
| **D** | Kernel-checked tactics, intrinsic specifications, VC generation and assurance ledger | **Planned.** Complete selected rewrite/simp/automation, RC4 given/requires/ensures/assert/invariant/decreasing, WP/VC proof attachment, and verified-emission block on *any* unresolved mandatory obligation |
| **E** | Comprehensive conformance, independent evidence and final core/essential v7 integration | **Collected throughout; final gate open.** Reference-to-`PS-CONF-*` matrix, differential RC4 checking, cryptographic Standard/assumption closure, existing cross-target matrix, C5 source correspondence and audited verified acceptance gates. |

### Phase A detailed exit gate

- **GetElem:** implement pinned RC4 `GetElem` and `GetElem?` with actual Prop-valued validity and Decidable/proof instances; `xs[i]` and `xs[i]'h` cannot discard proofs; `xs[i]?` returns Option safely; `xs[i]!` is a separately declared panic/default behavior, not a bounds proof. Do not confuse existing checked `List.get?` with the four forms.
- **Deriving:** accepted selected trailing handlers `Inhabited`/`BEq`/`DecidableEq`/`Repr`/`Hashable` must produce genuine checked and registered definitions with generated-source provenance. Unsupported cases and arbitrary handlers fail closed.
- **Scalars/libraries:** complete pinned `Float`/`Float32`/scientific, fixed-width/`BitVec` and selected arrays/bytes/string/collection conversions, then prove and execute target parity.
- **Registry:** preserve the current selected SHA-256 (`sha256:f33d923e45baf8aa5dfa6755819737acabc09daf6d60934eb232133acaad069f`) and FNV (`fnv1a64:5949916575031563783`) roster drift gates; separately finish a comprehensive cryptographic RC4 module/notation/deriving/class/instance/tactic/effect/axiom manifest (not yet qualified). Recompute/approve intentional semantic changes; never silently overwrite a frozen expected hash.

### Phase B detailed exit gate

Ensure formation/elimination of selected heterogeneous/indexed/dependent/recursive types, nested and mutual inductives, constructor consistency/positivity, independent motive checking, total structural and well-founded recursion. Check invalid indices/termination negative cases and runtime/proof erasure across all supported backends. No user `partial`/`unsafe` workaround.

### Phase C detailed exit gate

Generalize effects through common checked bind/pure/elaboration and appropriate instances, not a succession of one-off translations; add selected `StateT`/`ReaderT`/`ExceptT`, typed `do` and mutable/erased variables, loops, early return, throw/try/catch/finally and explicit world/IO boundaries. Specify effect and failure semantics independently of JS exceptions and validate the cross-target IR.

### Phase D detailed exit gate

Proof-producing tactics and rewriting/selected simp/omega/grind require pinned proof extensions and official kernel validation. Implement RC4-style `given`/`requires`/`ensures`, assertions, invariants/decreasing, `Std.WP`/`vcgen` and optional `where finally | spec` proof tails with a traceable obligation/effect/assumption/erasure ledger. **Verified executable output is forbidden while any mandatory proof, specification coverage, effect, assumption, termination or erasure obligation is unresolved.**

### Phase E detailed exit gate

Close a source-rule → positive/negative case → exact failure phase → Lean RC4 elaborated-term/semantic correspondence → verified IR/backend matrix. Independently validate assumption/primitive/erasure safety, crypto-pinned environment closure, multi-module linking and public APIs, JS/TS/Rust/Wasm GC/Wasmtime parity, and reproducible CI with fully recorded SHA, version/digest and evidence. Only then say core/essential v7 is complete. A green bounded profile is insufficient.

### Readable outputs within M2–M5, and deferred source migration

C0–C4b are delivered runtime/output foundations, not milestones to repeat.
[The current audit](PSCV0_READABLE_OUTPUT_AUDIT_2026-10-13.md) places C5 information retention in M2/A,
M3/B and M4/C-D, with full selected Lean/PS reconstruction and correspondence
completed under M5/E after required A–D semantics exist. This supersedes the
earlier blanket C5-after-all-A–E rule. Existing JS/TS/Rust/WAT/WIT are extended
through the same plans as features become available.

Existing backend **D** means measured performance/ownership work and is part
of **M5**; it is distinct from language Phase D proof/specification features.
Collect evidence throughout rather than waiting for a final integration pass.
Fine-grained Wasm debugger maps and optional TS/declaration maps remain explicit
capabilities, not hidden additions to the existing artifact acceptance gate.

Compiler-source `.ps` migration, bootstrap/self-hosting, `pskernel-core` and a
Rust-only source dialect remain deferred. Preserve branch history, draft PR 109,
Wasm GC internals and Canonical ABI-only linear memory.


## End state and current development contract

Keep the portable semantic compiler in shared .lean modules, executed natively
and checked by the official Lean kernel. Preserve syntax -> resolution ->
elaboration -> canonical prepared Core -> checking -> typed erasure -> validated
IR -> backend boundaries. The host retains the same prepared graph across check
and emit. No Lean frontend fallback, alternate kernel on failure, or fabricated
proof authority is permitted.

Native language growth precedes compiler-source translation. The final readable
.ps migration and fixed-point qualification remain separate future milestones;
pskernel-core, self-host generation and independent kernel suites are outside
this development loop.

## Capability dependencies

| Capability family | Existing implementation/evidence | Remaining mechanisms |
|---|---|---|
| Source categories and scopes | Native scoped terms/calls/binders, raw strings, grouped/radix literals, checked `s!` interpolation, selected proof/section grammar | Float/Float32/scientific tokens, remaining deriving handlers/modifiers and finer source diagnostics |
| Type inference and environment | Scoped unification/levels/typeclasses, checked arithmetic/BEq/ToString/Inhabited with polymorphic Prod, List and Option dictionaries, Standard signature/body/instance audit, official Lean RC4 checker | Remaining deriving handlers, floating/scalar/coercion semantics, full elaboration/search and comprehensive module/notation/effect/assumption manifest |
| Data and elimination | Structures, uniform indexed families, recursor-driven motives, dependent context reversion, homogeneous index constraints and impossible cases, nested/multiple typed pattern matrices and nomatch, proof-field storage erasure | Named discriminants, heterogeneous constraints, Type/existential fields, selected nested/mutual data |
| Recursion and runtime closure | Direct indexed recursion, changing-state workers; captured/nested recursor lifting qualified with typed traversal | Recursive pattern matrices, well-founded and mutual source recursion, complete runtime field profiles |
| Modules and libraries | Reachable import closure, private hygiene, selected re-exports/body opacity, JS/TS/Rust 3-file executable and V8/Wasmtime GC four-module execution, provenance and entry API | Complete RC4 generated public signature, collision/instance precedence and import ordering semantics |
| Proofs and contracts | Term proofs and typed goal state, exact/refine/apply/intro/assumption/rfl/constructor, focus/bullets/all_goals/any_goals, cases/induction/case/next checked by official Lean | Complete logical primitives, further goal control/elimination/rewriting, selected automation, VC/effect/spec generation and assumption closure |
| Control and effects | Checked Bool/Prop/if-let/match and selected Id/Option/Except typed do, checked Type-0 Except.bind/map/mapError/tryCatch/isOk/toOption and real cross-target error/recovery observations | General effect classes, mutable/early-return/loops, generalized do try/catch/finally and effect/fidelity laws |
| Executable assurance | Checked prepared graph, complete shared IR gate, native primitive signature/model audit, direct JS/TS/Rust integration with the same observations | Complete v7 assurance/axiom/effect ledger, specified runtime/library fidelity and final release criteria |
| Readable source and later source authority | Qualified readable runtime targets; bounded historical Lean/PS printers and round trips; native portable authoring/import guard | C5 retention in M2–M4 and source reconstruction/correspondence in M5/E. Compiler-source migration and fixed-point qualification remain separate later work. |

## Dependency-driven sequence

1. Captured/nested runtime recursion now uses checked Core helpers and the
   existing backend contract; broader well-founded/mutual recursion is separate.
2. The typed pattern matrix now serves nested/multiple discriminants,
   first-match behavior and pattern-derived terms through shared dependent
   telescopes/equality. Complete its remaining documented grammar/refinement
   boundaries as their type/recursion dependencies become available.
3. Extend data/instance and module environment ownership before broader library
   sugar, tactics and effects rely on it.
4. Build shared proof-goal and typed control mechanisms; implement selected
   automation and VC generation as proof-producing clients of those mechanisms.
5. Close the canonical capability and assurance ledger; only then begin the
   requested final compiler-source migration and generation qualification.

This ordering may change when source inspection reveals a stronger dependency.
A green compact fixture is evidence for its exact boundary, never completion of
an entire row. Validation first checks semantic invariants and actual admitted
terms, then the affected runtime path, while reusing compact integration inputs.

## Qualified backend milestones and remaining output work

Native profile 17 qualifies milestones A and B: one checked prepared graph,
actual shared IR validation, semantic/output name mapping, portable layout and
origin artifacts, plus Rust alongside TS. The same 285-declaration composite and
102 runtime observations pass in strict TypeScript/JavaScript and Rust. Target
representation and runtime policy remain in backend modules, never elaboration.
See PSCV0_NATIVE_CODEGEN.md and PSCV0_NATIVE_RUST.md for exact boundaries.

C0–C2 now implement validated artifact bundles, retained declaration spans and
generated-parent origins, a runtime API/WIT representability boundary, the
native primitive signature/model audit, shared structured ECMAScript lowering
and direct JS/declarations/source maps. See PSCV0_NATIVE_CODEGEN.md. Source maps
currently resolve to the owning declaration; token-level origins are not claimed.

The original C4/C4b integration profile was 35 with 142 observations; the current
profile is 48 with 250 observations at c00e146b / Linux 38388627512. One
ECMAScript Program supplies JS and TS output, and direct JS emission needs no
TypeScript compiler. Current qualification includes all existing runtime targets.

C3, C4 and C4b are qualified for the current checked runtime and synchronous
pure public profile. GC data/closures, generic conventions and current
Nat/Int/String/Array semantics use shared runtime IR. WIT, readable WAT and
direct component binaries share one explicit Canonical ABI plan, including
memory32 marshalling, allocation and post-return. Complete extracted contracts
and WAT/binary correspondence have independent qualification. The public profile
admits ordinary nonrecursive concrete aggregates and integer adapters; resources,
callbacks, recursive/proof-bearing foreign construction and effects require
separate explicit APIs. See PSCV0_NATIVE_WASM.md.

The user-selected option A is preserved: GC language values, linear memory only
at explicit ABI boundaries. Remaining backend work is C5 readable pre-erasure
Lean/ProofScript reconstruction and D measured performance/ownership work.
Compiler-source .ps migration, self-hosting and full v7 remain separate.
