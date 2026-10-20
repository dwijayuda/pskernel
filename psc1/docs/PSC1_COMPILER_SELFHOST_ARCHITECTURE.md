# PSC1 compiler-only self-host architecture

Decision date: 2026-10-21. This design concerns the compiler, not the owned kernel.
The source census baseline is immutable commit
da880d864ca5f9e35729255fd7e4f8a17953cd39. Live CI regenerates the inventory on
the integration checkout; baseline counts must not be substituted for that result.

## Selected boundary

Retain the existing pure compiler rather than reimplementing its semantics in a
Node or Rust host. Ps.Compiler.Api/Ordinary own parsing, elaboration, canonical
Core preparation and checked ordinary graph pairing. Ps.Erasure and
Ps.CompilerIr own executable construction/validation. BackendCommon and the
selected printer/lowerer own target planning and emission. Those modules do not
explicitly import Lean, IO or System at the inspected baseline.

The external host captures and resolves the ordered source closure, owns the
official independent checker, launches target tools and publishes artifacts.
Host source resolution is not compiler semantic elaboration. Passing an
untrusted candidate graph through the independent checker establishes logical
admission of that graph, not source-to-Core correctness or backend preservation.

| Selected phase | Baseline local modules | Lines | UTF-8 bytes |
| --- | ---: | ---: | ---: |
| Api + Ordinary semantic compiler | 66 | 31,122 | 1,227,616 |
| Semantic compiler + DirectJS plan/lower/validate/print | 78 | 39,289 | 1,547,280 |
| Semantic compiler + Rust plan/module emitter | 82 | 38,984 | 1,551,285 |
| Full native host closure | 131 | 61,513 | 2,476,295 |

These are explicit-import closures of production Lake roots, not a measured
runtime primitive census. The full host additionally imports native Lean.
Lean implicit Init/prelude operations remain runtime obligations even when
there is no explicit import. The committed baseline JSON has per-module paths,
Git blob identities, import edges and phase membership.

Do not include Main, host filesystem/process services, PsKernelLean or the
owned kernel in the generated compiler source closure. Historical
Ps.Bootstrap.SelfHost only imports the TS composition root; its outdated
4.34-Wasm comment is not qualification for current DirectJS/Rust self-hosting.

## Concrete current blockers

The source was inspected, but inspection is distinct from running the new probe.

* CompilerIr.Validate uses deriving Repr. BackendCommon.Plan uses deriving
  BEq/Repr. ParseLean's declaration dispatcher recognizes def, partial def,
  theorem, inductive and structure; deriving is outside that dispatcher.
* Elab.Data contains private declarations. Rust.RuntimePlan contains private
  def/private partial def. Private modifiers are outside the same parser.
* ProjectCompiler.psHostPackageDirectory historically only mapped BackendTs.
  BackendCommon/Js/Rust/Wasm/Python/Php need explicit workspace fallback
  mappings. This is source resolution, independent of parsing.
* DirectJS.Print's new recursive helper and Rust.RuntimePlan's traversal must
  pass the actual source parser, elaborator, ordinary-body admission, executable
  IR and target runtime. Native compilation of those files does not establish
  that PSC1 can compile them.

Fix source syntax deliberately. For tiny compiler enums, explicit supported
equality functions can replace deriving without introducing a generic deriving
framework. Debug-only Repr need not enter executable bootstrap source. Where
private helpers are migrated, assign collision-free qualified identities and
preserve the declared package/public surface; do not silently strip privacy
tokens or skip unsupported declarations.

The live census walks the selected import graph in dependency order. Each
module receives separate parse and elaboration status. A refused import blocks
dependent elaboration rather than creating cascaded fabricated failures.
Independent admission, IR, generation, generated execution and fixed points
remain explicit not-run stages until separately executed. A successful census
command means the inventory/probe completed, not that self-hosting passed.

## Versioned compiler/host protocol

Use psc1-compiler-host/1 and keep wire data separate from host authority.

1. Host captures exact bytes, source kind, stable module identity, entry module,
   import edges and dependency order. The ordered closure digest uses module,
   source kind and each file's UTF-8 hash. Absolute machine paths are diagnostic.
2. Portable core prepares the canonical candidate graph and its retained source
   work state. Ordinary compilation also retains the exact source/runtime graph
   and the separately admitted logical expansion.
3. Host pins the canonical bytes in a pending session. Generated code submits an
   admission envelope containing protocol/op, requestId, sourceClosureDigest,
   target and those exact admissions. Generated metadata cannot select a checker.
4. Host verifies exact field/identity/byte matches and invokes the separate
   official checker pinned to Lean 4.35.0 commit
   eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
5. Only the host's successful invocation creates its admitted session state.
   A wire receipt correlates request, source, graph, target and checker identity.
   The generated core can use that receipt to resume; constructing matching
   JSON cannot cause the host to publish.
6. Generated core emits validated executable IR/target artifacts from its
   retained work state. Host validates the staged target, exact public ABI and
   manifests and publishes only through its own admitted session. Hashes bind
   identity; they do not prove erasure or behavioral equivalence.

Rejected/malformed/stale/mismatched requests do not authorize output. Checker
failure consumes the checking attempt as rejected. Accepted sessions are
single use. No protocol field means behaviorally verified. External checking
cannot authorize arbitrary foreign contracts or unchecked axioms.

The implemented transport foundation consists of:

* Ps.Bridge.CompilerHost: pure request encoding and receipt correlation using
  existing portable JSON functions; no native services.
* host-tools/compiler-host-protocol.mjs: host-owned exact-byte session and
  independent checker invocation.
* compiler-host-protocol-tests.mjs: native stage 0 compiles the transport module
  into JS and Rust, then actual generated consumers exchange envelopes with
  the independent checker and exercise mismatch/refusal boundaries.

This is a protocol transport feasibility slice. Its small candidate graph comes
from native stage 0. It does not claim a generated parser, a generated compiler,
source closure self-compilation or a fixed point. The gateway does not yet
publish executable artifacts and is not the native CLI's publication path.

## Dependency-ordered implementation

1. **Inventory and source normalization.** Run the live stage census. Fix the
   first true unsupported source form in dependency order. Retain one source of
   compiler semantics; avoid a hand-maintained alternate bootstrap compiler.
   Acceptance: every selected JS closure file parses/elaborates in both selected
   input forms where claimed; no skipped declarations/imports. Record exact
   first refusal for remaining Rust-only files.
2. **Whole-closure preparation/admission/IR.** Run the complete prepared closure
   through official independent admission, exact ordinary graph pairing where
   needed, erasure and strict original/specialized IR checks. Add actual
   primitive requirements to the inventory from reached IR, not keyword guesses.
   Acceptance: no unresolved metas/unknown IR types/missing runtime intrinsics;
   fabricated wrappers, mismatched bodies and missing imports fail closed.
3. **Generated JS compiler service.** Add a supported scalar transport entrypoint
   around the real compiler preparation/emission functions. Generate JS using
   stage 0 once. Move filesystem/checker/tools/publication into the host session.
   Acceptance: generated JS compiles handwritten positive/negative language,
   scope, import, exact integer, Unicode and ordinary-control cases. Instrument
   the host's subprocess allowlist: no handwritten psc1 frontend/emitter call
   after stage 0; the independent checker remains allowed.
4. **JS self-compilation and repeat generation.** G1 compiles the same captured
   JS compiler closure into G2, and G2 into G3. Compare canonical admissions,
   validated IR and deterministic generated source/artifact identities under
   pinned tools; execute all generations on the same corpus. Do not infer a
   fixed point from compiling one unrelated fixture or from an unused wrapper.
5. **Rust compiler service and fixed point.** Reuse the same protocol and source
   preparation. Complete Rust-only closure, ownership/runtime/closure operations
   exposed by actual reached IR. Generate R1, execute its corpus, self-compile
   R2/R3 and compare canonical compiler artifacts plus runtime observations.
   Native executable byte identity is not required unless the locked build is
   demonstrated reproducible; canonical source/IR identity must be explicit.
6. **Portable host services and packages.** Package JS/Rust hosts, checker and
   runtime adapters with explicit dependency/tool pins. Add source IO/foreign
   adapters only as needed; broad foreign ecosystems and automatic refactoring
   are not prerequisites for first compiler-only self-host success.

Every milestone requires a named GitHub Linux run and actual logs/artifacts.
Failure categories remain source parse, elaboration, canonical admission,
erasure, IR validation, target emission, runtime, host protocol and fixed-point
comparison. Maintain the work state with the first actionable blocker, never a
percentage or a blanket “self-hostable” label.
