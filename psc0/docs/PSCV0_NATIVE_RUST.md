# Native Rust backend

Rust is a peer of TS behind official Lean admission, typed erasure and the
complete shared IR checker. Compiler authoring and execution remain native Lean.
The pure single-module profile has no pskernel-core or self-host dependency.

## Representation

The current typed IR is the shared semantic contract. Target naming produces a
separate view with semantic/output identities; Rust keywords/runtime names are
reserved. Ps.BackendRust.Layout detects recursive nominal type dependencies.
Recursive data uses Rc node aliases; nonrecursive records/enums store fields by
value. Generic marker fields preserve Rust well-formedness without runtime data.
Empty generic families use an Infallible marker, never a fabricated inhabitant.

Function values uniformly use Rc<dyn Fn(...) -> ...>, including nested results,
stored captures and class dictionary fields. Direct calls stay direct. Capture
analysis is lexical, and captured values remain available for repeated calls.
A backwards liveness set chooses move versus clone for owned local uses.
Intrinsic read operands borrow directly; array/string updates consume owned
inputs. Arrays use Rc<Vec<T>> and Rc::make_mut, preserving aliases and reusing
unique buffers. Rust-only decisions never enter Core or semantic IR.

The existing direct/eta-alias tail analysis feeds the shared structured expression
emitter: tail transfers update a tuple before continuing the loop. Lambda bodies
and non-tail operands cannot inherit that continuation. Proof parameter Unit
slots remain intact. Impossible cases trap safely if reached.

Closed pure top-level values use per-thread LazyCell accessors. This permits Rc
values without inventing Sync bounds, and avoids recomputing a closed value on
each reference. Values/functions and source/output names remain in the manifest.
This policy is only qualified for pure values; effects require another contract.

## Output and host

Rust expressions, statements, records, matches and declarations are composed with
Ps.Codegen.Doc. A separate pscv0_runtime.rs carries explicit arithmetic, Unicode
and array support. The CLI accepts --emit input.ps output.rs, or --emit-both
input.ps output-stem to check/erase/validate once for TS and Rust. The origin
manifest records generated UTF-8 declaration ranges and symbol identities.
Original source coordinates and complete TS expression layout remain later work.

The runtime requires num-bigint 0.4.6 and num-traits 0.2.19. Native qualification
uses Rust 1.98.1, edition 2021 and an exact Cargo.lock, including transitive registry
checksums. Generated/runtime code forbids unsafe; this does not certify transitive
dependencies. The current generated API is a source interface, not a stable ABI.

## Qualification and bounds

Source ff83ff5e927bdc4bf5d31f57bef688f4b146537b passed
[Linux run 38176124905](https://github.com/dwijayuda/pskernel/actions/runs/38176124905):
285 officially checked declarations and the same 102 scalar/call observations
for TS and Rust, with the existing parser/semantic/refusal batch retained. The existing composite
also retains dependent data, impossible cases, proof fields, recursive functions
and instance dictionaries. Eleven observations cover stored/repeated captured
callbacks, returned branch closures, persistent array aliasing/building,
borrowed operands across later moves, large Nat, saturating subtraction, zero division and Unicode length/byte distinction.

External imports/effects, concurrency, unqualified machine scalars/floats and
higher-rank runtime polymorphism remain explicit capability boundaries. Type
checking generated Rust is not a semantics-preservation proof. Tail loops do
not imply stack-safe final-owner destruction of recursive data: iterative release
and broader scaling qualification remain a separate performance milestone.
Compiler-source translation to ProofScript remains deferred.
