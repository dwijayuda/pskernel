# Native direct Wasm implementation

C4 and C4b implement current-runtime core parity and the synchronous pure
component profile described here. Native profile 35 remains authored and
executed in portable .lean and checked by official Lean 4.35.0-rc4. Exact source
and Linux qualification evidence are recorded in AI_WORK_STATE.md.

## Pipeline and architectural boundaries

The shared frontend elaborates/prepares one Core graph; official Lean checks
that graph before erasure. The complete target-neutral IR gate still precedes
every backend. Wasm lowering preserves evaluation order, lexical captures,
generic calling conventions and impossible branches. Direct concrete calls
avoid the generic closure convention. Free-variable discovery is shared with
Rust; target representation stays in backend-wasm.

Value/Layout define GC structs, packed UTF-8 byte arrays, limb arrays, generic
value arrays and typed closure references. Natural, Integer, String and Array
author the runtime through small named-local combinators. Lower/LowerState
consume shared IR; Intrinsic supplies one physical signature per operation.
Binary and Wat serialize the same independently structure/stack-checked module.
Reachability removes unused functions and helpers. The old scalar-only lowerer
is removed. Independent singleton function signatures remain outside aggregate
recursive groups, preserving canonical function type identity.

All language values live in Wasm GC. Natural values use normalized little-endian
unsigned 32-bit limbs; integers use sign plus magnitude. Published values are
immutable: arithmetic and persistent array updates mutate fresh working arrays.
Small-divisor division traverses limbs; general division traverses dividend
bits, never a quotient-sized subtraction loop. The representation limit is
134217727 limbs, checked at allocation and boundary admission. Exhaustion traps;
it never truncates source integers.

Strings retain valid UTF-8 and scalar length. Character conversion, byte
positions, continuation/end fallbacks, extraction and integer formatting follow
the selected native primitive model. Arrays preserve aliases; map/fold use the
same generic closure convention as source calls. Tail-position direct/closure
calls and runtime loops use Wasm tail calls. General stack safety for non-tail
source recursion is not claimed.

## Explicit foreign profile

The component target emits .wit, readable component .wat, direct .wasm and
standalone .core.wat/.core.wasm, with a provenance/capability manifest. Production
emission needs no wasm-tools, WIT parser, WAT assembler, Rust, C or LLVM process.

Scalar-only interfaces with at most 16 flat arguments retain direct world
functions and need no linear memory. Aggregate or indirect interfaces export
one named `api` interface containing the selected functions and their type
definitions. Manifest output symbols identify `api.function-name`.
Both are identified by pscv0-component-c4b-memory32/1; the explicit GC-only
core target is pscv0-wasm-c4-gc/1.

The automatic component interface admits Bool, Char, String, Nat, Int, arrays
and concrete nonrecursive ordinary records/variants, including concrete generic
data. Nat is `record nat { limbs: list<u32> }`; zero has no limbs. Int contains
a negative Boolean and a Nat magnitude. Input normalization removes redundant
high zero limbs and normalizes negative zero. These are explicit portable value
adapters, not narrowed machine integers.

Before erasure discards proof obligations, foreignData records a conservative
source classification: no indices, no value parameters, and no erased
constructor fields. Named data without this evidence requires a validating
adapter. This prevents a foreign caller from manufacturing proof-bearing source
values from their erased storage. Unit is omitted only as a result.

Generic function exports, closures/callbacks, recursive data, dependent or
proof-bearing aggregates, uninhabited types, nested Unit and empty records
require an explicit concrete view/resource/validating API and are refused.
This profile exposes no owned or borrowed WIT resources: there are no implicit
numeric handles, GC root tables or resource lifetime claims. Resource APIs,
callbacks, imports, effects/WASI, async, threads, memory64 and GC-native canonical
conversion remain separate versioned capabilities. These foreign restrictions
do not remove internal source data/closure capability.

## One Canonical ABI plan

AbiPlan computes concrete type identity, readable labels, layouts, alignment,
variant payload offsets, flattening, indirect arguments (>16 flat values) and
indirect results (>1 flat value). AbiSchema uses that graph for WIT and component
types. AbiMarshal generates one load/store pair per concrete value type; flat
arguments reuse the checked memory decoder. AbiComponent connects core exports,
memory, realloc and post-return through typed canonical lifts and an interface
instance. Public name collisions are errors, never silently renamed contracts.

Only the explicit ABI adapters use linear memory. They copy incoming values into
GC and outgoing values into a memory32 arena. No general language heap, shadow
collector, semantic JS imports or fallback backend is introduced. The standalone
core emitted alongside a component includes its explicit adapters; the separate
--emit-wasm-core target contains no ABI memory.

The pure synchronous arena begins at byte 16 and grows to a reusable high-water
mark (maximum 32768 pages). Realloc checks alignment, overflow and source ranges,
and preserves the required old prefix. Entry establishes an active call.
Results and nested buffers remain live until canonical post-return resets the
arena and closes the call. A second entry before post-return traps. Since the
profile has no callbacks/imports/reentry, whole-call cleanup covers all nested
allocations. A trapped instance must be discarded; recovery/reentry is not
promised. Linear memory retains capacity between calls, but allocations are not
retained for the instance lifetime.

Adapters validate ranges, alignment, checked size products, Unicode scalars,
UTF-8, Boolean values before narrowing, variant tags and representation bounds.
Malformed inputs and allocation failure trap; source domain errors retain
their source representation. Internal helpers alone may access ABI memory and
allocator globals; target validation enforces the reserved ABI namespace.

## Readable and independently checked artifacts

WAT retains named functions, locals, types and fields, structured instruction
blocks and visible ABI helpers. Embedded modules are text, never escaped byte
blobs. Binary name metadata retains the same identities. WIT describes the
selected public contract with readable concrete type labels such as array-nat.
No source comments or high-level source reconstruction are invented.

Qualification uses the existing 142 observations through Node/V8 and Wasmtime
core execution and through direct and reassembled component exports. A small
limb probe covers large carries/borrows, arithmetic and division by zero. One
aggregate fixture covers normalization, strings, lists, records, variants,
concrete generic data, flat/indirect arguments and results, and void cleanup.
Repeated Unicode calls verify output lifetime, post-return and stable arena
capacity. Compact malformed-input cases exercise the ABI admission boundary.

wasm-tools independently parses WIT, validates binaries, extracts the complete
interface and assembles both WAT forms. Direct and reassembled binaries must be
byte-identical after removing only standard name/component-name metadata.
Extracted WIT must preserve the full interface/type graph; only package/world
labels, absent from component identity, and formatting are normalized.

Qualification pins Node 22.23.3 (V8 recorded in logs), Wasmtime 49.0.2, wasm-tools
1.261.0 and Rust 1.98.1 for the development-only embedding harness. Release tool
archives are SHA-256 checked; the host harness uses a committed Cargo.lock.
The native compiler has no dependency on that harness. Existing JS/TS/Rust,
parser, kernel, IR, declaration and source-map gates remain in place.

Backend observations and target typing are evidence, not a semantic preservation
proof. The native prelude signature/model audit and assumption ledger remain
separate. C5 readable Lean/ProofScript reconstruction, measured performance
work and remaining v7 language features follow this milestone. No pskernel-core,
compiler-source .ps migration, self-hosting, main merge or release is performed.

## References and entry points

- Core spec: WebAssembly/spec 7e9fb78c63d65018cc111422f657947b3df80d7b.
- [Pinned Canonical ABI](https://github.com/WebAssembly/component-model/blob/6c48079bbc808bb3bdeb9554f338ab3a5b187388/design/mvp/CanonicalABI.md).
- [WIT interface/world model](https://component-model.bytecodealliance.org/design/wit.html).
- [Pinned component instance encoder reference](https://github.com/bytecodealliance/wasm-tools/blob/v1.261.0/crates/wasm-encoder/src/component/instances.rs).
- Architecture: PSCV0_DIRECT_JS_WASM_ARCHITECTURE.md.

```text
pscv0_native --emit-wasm-core application.ps output-stem
pscv0_native --emit-wasm application.ps output-stem exports.json
```
