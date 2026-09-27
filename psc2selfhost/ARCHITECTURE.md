# PSC2 compiler architecture and trust boundaries

Status: target design; current integration gaps are in [STATUS.md](STATUS.md).

## Single semantic path

Supported `.lean` and native `.ps` parse to shared syntax, resolve names and
elaborate to candidate dependent Core. Tactics, deriving and verification
produce candidate declarations/proofs. A selected independent kernel provider
admits them. CheckedCore then passes through erasure and shared runtime IR to
TS, Rust or Wasm lowering. `tsc` remains the TS-to-JS compiler.

The host selects files, transports requests and invokes tools. It cannot turn
a provider rejection, malformed reply or timeout into success.

## Package ownership

| Package/directory | Owns | Must not own |
| --- | --- | --- |
| foundation | Names, source spans, diagnostics | Filesystem identity as logical names |
| syntax | Lexer, dual parsers, shared syntax, canonical printers | Type checking or kernel acceptance |
| project + host loader | Logical graph; host maps paths into it | Different module semantics per target |
| core | Candidate dependent terms, levels, declarations | A second semantic type theory |
| environment | Elaboration environment and metadata | Unchecked publication as admitted environment |
| meta | Metavariables, inference, reduction requests, rollback, instance search | Final admission authority |
| elab | Terms/declarations, desugaring, proof construction | Bypassing provider checking |
| bridge | Canonical codec and provider boundary | Treating serializable Core as checked |
| pskernel | Independent checking/admission implementation | Dependencies on Meta, parser, backend or host IO |
| erasure | Runtime relevance and executable lowering | Consuming forged/unadmitted verified inputs |
| compiler-ir | Target-neutral runtime meaning and shared specialization | Rust ownership, JS identity, Wasm layout |
| backend-ts/rust/wasm | Target IR, runtime representation and emission | Source-specific semantic shortcuts |
| compiler | Source-neutral public orchestration | Reimplementing frontend logic in CLI/LSP |
| stdlib | Portable collections/effects/spec libraries | Unrecorded host primitives |
| host, scripts, cli | IO, process, tool invocation and transport | Semantic implementation hidden in JS wrappers |

Keep current physical roots during closure. Moving `stdlib` or `host` into
`packages/*` is optional cleanup after stability, not a bootstrap prerequisite.

## Kernel-provider boundary: planned contract

Introduce a versioned provider abstraction behind `bridge`; the exact source
API is to be fixed by its bounded implementation design. Required operations
are capability/profile discovery, environment lookup, ground inference/defeq
when supported, and transactional declaration/block admission.

Every admission request binds protocol/Core versions, semantic profile,
provider identity, initial environment identity, ordered declarations, logical
assumptions and optional native-evaluation policy. The result distinguishes
accepted, rejected, unsupported and operational failure. Unsupported/resource
failure is not acceptance and is not proof of semantic invalidity.

Accepted results bind the request digest and resulting environment. A checked
module may only be created through this boundary. On deserialization/reuse,
re-admit it or validate through an explicitly trusted, integrity-bound cache
policy; a public constructor or caller-provided Boolean is insufficient.
Hashes provide integrity, not proof.

Transactions must roll back declarations and relevant caches on rejection.
Unresolved expression/universe metavariables, free/loose variables, malformed
recursors, illegal eliminations, collisions and invalid types must be rejected.

## Integrating the embedded Lean-authored kernel

`PsExpr` and `PSC1Kernel.Expr` are separate representations. Prefer a small,
total, fail-closed conversion/admission adapter over rewriting either system.
It must specify Name/Level mapping, binder metadata, local/metavariable IDs,
literal representation, let metadata, declaration safety and inductive blocks.
Never discard semantically relevant fields merely to make conversion succeed.

Three approaches were considered:

| Approach | Decision |
| --- | --- |
| Adapter around current embedded kernel with independent oracles | Preferred: preserves substantial tested checking code; exposes conversion and source-closure obligations. |
| Immediate replacement with the smaller PSC1 kernel port | Not selected: source portability alone does not establish checking completeness. Evaluate bounded components as donors. |
| Keep only an external TS kernel indefinitely | Useful explicit bootstrap provider, but does not meet the compiler-plus-kernel self-host target. |

Stage the migration: canonical requests and negative fixtures, real provider
admission, dual-check comparison, normal compiler-path use, generated kernel
execution, then promotion. Keep TS independently runnable; do not demote it
until the replacement's exact promised profile and bootstrap gates pass.

Official Lean can host the kernel while its portable source profile closes.
Label that `Lean-hosted kernel`, never `self-hosted kernel`. Namespace/abbrev,
recursion, runtime containers and other features used by the kernel require an
explicit closure census; the compiler's existing lexical guard skips it today.

## Verification and executable trust

A kernel can prove the wrong proposition correctly. Contract verification must
produce a theorem connecting the actual elaborated program and its specification
through defined semantics (for example a sound Hoare/WP framework), not merely
prove a bag of generated conditions. Bind the final theorem to the program,
specification, effect model and assumptions. A VC generator remains untrusted
only when its proof construction is checked against that intended theorem.

Similarly, theorem correctness does not prove erasure or backend preservation.
Maintain distinct logical, compilation and host/FFI assurance records. Partial
runtime recursion may be supported under an explicit profile, but cannot be
used as total kernel computation or silently exported as a proved total function.

## Runtime and extensibility contracts

Follow the existing [IR contract](packages/compiler-ir/CONTRACT.md). Shared
specialization is allowed when it preserves target-neutral meaning; target
monomorphization/layout remains downstream. Preserve exact integers, scalar
width/overflow, strings, persistent collections, closures and evaluation order.

The platform model from
[POST_PSC1_PLATFORM.md](../docs/selfhost/POST_PSC1_PLATFORM.md) remains the
direction: independently version Core/CheckedCore/IR/provider APIs; typed
capabilities; controlled Meta/plugins; separate InterfaceIR for foreign APIs;
Task/Resource semantics before syntax; one compiler-service API for tools.
These are later work unless an actual bootstrap dependency requires a slice.
