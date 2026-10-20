# PSC1 Wasm architecture v2

Status: selected architecture with direct Bool-component foundation qualified at 5496943a30423269654fffcd7579b3c5dd16b4f9, run39495181966. Compound ABI milestones remain planned.
Only the exact qualifying SHA/run recorded in AI_WORK_STATE and
PSC1_ULTRA_EXECUTION_STATUS establishes implementation completion.

## Source comparison and evidence

PSC1 reference: `da880d864ca5f9e35729255fd7e4f8a17953cd39`.
PSC0 native reference fetched on 21 October 2026:
`33676076bcda7b0de5ec1f9803f49b8b1d28a058`,
branch `psc0/pscv0-v7-native-lean-v1`.

| Boundary | PSC1 baseline | Applicable PSC0 design |
| --- | --- | --- |
| Logical authority | Captured session; official Lean 4.35 admission; strict executable IR | Same conceptual boundaries, richer native frontend/public API metadata |
| Internal values | GC structs/arrays, specialized concrete closures, exact Nat binary GC constructors | GC value supertype, boxes at generic crossings, normalized u32 Nat limbs |
| Core output | Owned Binary encoder; structure/typing validators | Owned typed module, checkedCore, native named binary/readable WAT |
| Components | One Bool export; wasm-tools embed/new subprocesses | Shared scalar/aggregate plan; direct component binary/readable WAT |
| Compound ABI | Refused | First-order nonrecursive concrete data, checked GC/memory conversion, realloc/post-return |
| Runtime selection | RuntimePlan closes helper calls; user declarations retained | Full function reachability |
| Construction invariants | PSC1 IR has no foreignData evidence | Pre-erasure classification; proof-bearing/dependent construction refused |

Source anchors:
- PSC1 `packages/backend-wasm/src/Ps/BackendWasm/{Model,Type,RuntimeNat,Lower,Binary,ValidateIr,ValidateTyping,RuntimePlan}.lean`.
- PSC1 `host/src/Ps/Host/WasmComponent.lean` and `packages/backend-common/src/Ps/BackendCommon/Plan.lean`.
- PSC0 `packages/backend-wasm/src/Ps/BackendWasm/{Module,Value,Natural,Component,AbiPlan,AbiRuntime,AbiMarshal,AbiSchema,AbiComponent}.lean`.
- PSC0 `docs/PSCV0_NATIVE_WASM.md` and `docs/PSCV0_DIRECT_JS_WASM_ARCHITECTURE.md`.

PSC0's document reports historical C4/C4b qualification at c00e146b,
run 38388627512, with 250 observations. That is reference evidence rather than
qualification of a PSC1 port. Full workflow-runs API results for the fetched
PSC0 tip show successful native
[39099546592](https://github.com/dwijayuda/pskernel/actions/runs/39099546592),
M3 39099546513, F1 39099546493, F2 39099546574 and F3 39099546446 push runs.
The narrow commit-workflow wrapper returns only PR-triggered runs and missed
these push runs. The component Module blob
`7c3b2512ded6677d2423e5ec10d207d1ca316cfa` is identical on native,
core-first and M3 preparation branches. These states support selecting the
reference; they do not transfer qualification to PSC1.

## Decision

Retain PSC1's common checked executable IR and existing GC core lowerer.
Core and component targets share that lowering. Add a portable component plan
and encoder after lowering, keeping each working boundary until its replacement
passes independent execution.

Use GC for all language values and linear memory only for explicit Canonical
ABI conversion. Do not add another language heap, C/LLVM pipeline, JS semantic
imports or unchecked host primitives. GC-native canonical conversion is not
the production ABI.

Reuse PSC0 algorithms selectively. Copying its backend wholesale would import
different IR metadata, representations, generic boxing and API assumptions.
Migrating binary-tree Nat to limbs is separate measured runtime work and is
unnecessary for the first component encoder.

## Candidate foundation

`Ps.BackendWasm.Component` owns a concrete Bool schema, WIT printer and direct
component encoder. `psWasmComponentMakePlan` rechecks raw IR and the shared
component capability boundary even if a caller constructs its wrapper.
`psWasmComponentCheckCore` checks target IR, the exact export set and every
physical i32 calling signature. A schema is ordinary data, never independent
logical admission or publication authority.

`Ps.Host.WasmComponent` preserves captured source admission and atomic
publication. It writes the direct component bytes instead of invoking embed/new.
Independent wasm-tools core/component validation, WAT printing and complete
extracted-WIT comparison remain. Production still needs wasm-tools for those
retained services; fully owned readable WAT is a later boundary.

The ABI remains Bool-only, synchronous and pure, with one CLI-selected
function. More than 16 flat parameters require indirect arguments and are
explicitly refused until adapters exist. Names are preserved and collisions
refused. This does not enable compound values, effects, resources, callbacks
or previously unqualified machine primitives.

## Dependency-ordered implementation

| Milestone | Modules and behavior | Executable acceptance |
| --- | --- | --- |
| W0 direct Bool component | Component schema/encoder and host | Existing 0/1/2 Bool runtime cases in both grammars; embed/new disabled; extracted-WIT equality; embedded core equals standalone bytes; WAT reassembly/execution; deterministic output; refusal preserves prior artifacts |
| W1 native readable WAT | Wat/Names over the same validated core module; component text from the same schema | Independently reassemble both texts; normalized binary equality excluding only named debug metadata; execute direct and reassembled outputs |
| W2 concrete ABI plan | AbiPlan/AbiSchema; pre-erasure foreign-constructibility metadata; strict propagation through specialization | One graph drives WIT/component/layouts; refuse forged safety metadata, recursive/functions/dependent/proof-bearing public construction, name/type collisions |
| W3 adapter instructions/runtime | Extend Model/Binary/target validators for reserved memory/globals/load/store; AbiRuntime | GC-only core has no memory; ABI helpers exclusively access adapter state; checked range/alignment/product/grow failure/realloc prefix; correct post-return lifecycle |
| W4 String/Nat/Int | AbiMarshal consumes existing GC representations; wire limbs independent of internal Nat | Huge exact values; redundant-zero and negative-zero normalization; valid/malformed UTF-8/scalars; repeated Unicode calls; live outputs until post-return; stable arena capacity |
| W5 arrays/plain aggregates | Concrete arrays/records/variants; flat and indirect signatures; reachability | Lists/records/variants/concrete generic roundtrips; internal alias preservation; bad tags/ranges; >16 args and >1 flat result; full extracted interface equality |
| W6 effects/resources | Separate versioned host-import and lifetime design, only when needed | Explicit imports/reentry/error/cleanup policy; owned/borrowed root lifecycle where exposed; no reuse of the pure arena policy across callbacks |

For the first compound profile, adapt PSC0's bounded pure synchronous memory32
arena: reserve null, track an active call, keep nested outputs live until
canonical post-return, reset after cleanup, reject reentry, discard trapped
instances. Do not expose resources until root-table/destructor/borrow rules
exist. Do not transform traps into source Except.

W2 separates foreign construction from erased layout. A record with erased
proofs must not become externally constructible merely because its remaining
fields can be encoded. Retain classification from checked source/Core and
verify its association through transformations; an untrusted Boolean flag is
not authority. Initially refuse such types or expose checked validating
functions and finite views.

## ABI invariants

- Apply the pinned Canonical ABI rules separately for the selected lift/lower direction.
- Synchronous flat parameter limit 16 and flat result limit 1 determine indirection.
- Variant slot joining transports bits; it is not a numeric cast.
- Nat wire values are little-endian u32 limbs with empty canonical zero. Int uses sign/magnitude and normalizes negative zero.
- Select UTF-8 explicitly and check bounds, products, scalars, encoding and tags before constructing GC values.
- Generate public WIT/component/layout identities from one schema; debug names never control linking.
- Preserve internal records, closures and recursive data when their public WIT export is refused.
- Publish binary, text, interface and provenance in one atomic generation.

## Upstream references and pins

Read on 21 October 2026:
- [Canonical ABI](https://github.com/WebAssembly/component-model/blob/main/design/mvp/CanonicalABI.md).
  Initial implementation reference is the existing pinned revision
  `6c48079bbc808bb3bdeb9554f338ab3a5b187388`; document any deliberate repin.
- [GC Canonical ABI pre-proposal 525](https://github.com/WebAssembly/component-model/issues/525)
  remains open. The author reported on 23 February 2026 that the parser has
  a prototype and Wasmtime only the beginning of an implementation. That
  does not qualify production PSC1 interoperability.
- [Wasmtime proposal matrix](https://docs.wasmtime.dev/stability-wasm-proposals.html)
  lists core GC, typed function references and tail calls as supported.
  Component proposal maturity is a separate question.
- [WIT reference](https://component-model.bytecodealliance.org/design/wit.html).
- [wasm-tools component encoder](https://github.com/bytecodealliance/wasm-tools/tree/v1.261.0/crates/wasm-encoder/src/component).

Keep PSC1's currently qualified tool pins during W0; upgrade tools separately.
PSC0 historically qualified a different set, which must not silently replace
PSC1's toolchain. Target validation and differential execution remain separate
from logical admission and a backend preservation proof. Wasm compiler
self-hosting follows the immediate JS/Rust compiler-only bootstrap.

The qualified plan now rejects every bare keyword in the exact
[wasm-tools1.254.0 lexer](https://github.com/bytecodealliance/wasm-tools/blob/v1.254.0/crates/wit-parser/src/ast/lex.rs#L338-L381),
including option/result/list/own/error-context. Independent host validation had already
prevented invalid-WIT publication; this closes plan validation earlier.

Upstream Component Model HEAD observed on21 October is d095e2f60ddae1f9a1e9b1e2fb547ec1114da677.
Keep the explicit implementation reference6c48079bbc808bb3bdeb9554f338ab3a5b187388.
Issue525 remains open; the [18 October discussion](https://github.com/WebAssembly/component-model/issues/525#issuecomment-6253238588)
still discusses copying and unresolved lifetime support. No production GC-native
Canonical ABI interoperability is inferred from core engine GC support.
