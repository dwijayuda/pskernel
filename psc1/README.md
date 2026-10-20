# PSC1 checked native compiler

PSC1 is a Lean-native compiler for the retained ProofScript subset and the qualified
slice of **PSC1 Practical Core — v7.2 subset**. The built-in backends emit JavaScript,
TypeScript, Rust, core WebAssembly, component WebAssembly, Python and PHP directly
from checked compiler IR. The independent admission provider is official
**Lean 4.35.0**, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.

This branch is the seven-backend integration stacked on Practical Core PR #163.
Consult [backend conformance](docs/PSC1_BACKEND_CONFORMANCE.md) for exact commits,
executed coverage, target tools and remaining limitations. The presence of an emitter
does not qualify every language feature.

## A small program

```lean
def invert (flag : Bool) : Bool := if flag then false else true
```

The equivalent supported `.ps` input is:

```text
def invert(flag : Bool) : Bool := if (flag) { false } else { true }
```

From this directory, with the pinned Lean toolchain and locked host dependencies installed:

```sh
lake build psc1
.lake/build/bin/psc1 check example.lean
.lake/build/bin/psc1 build example.lean --targets ts,js --out-dir out
.lake/build/bin/psc1 build example.lean --target python --out out/example.py
.lake/build/bin/psc1 build example.lean --target php --out out/example.php
.lake/build/bin/psc1 build example.lean --target rust --out out/example.rs
.lake/build/bin/psc1 build example.lean --target wasm-core --out out/example.wasm
.lake/build/bin/psc1 build example.lean --target wasm-component --export invert --out out/component.wasm
```

Host dependency installation is `npm --prefix host-tools --workspaces=false ci --ignore-scripts`.
Select the tools for the desired target; installing the compiler does not install
Python, PHP or Rust. The unpublished native npm distribution and installed source-library
workflow are described in [the npm guide](docs/PSC1_NPM_ECOSYSTEM.md).

## Outputs and tools

| Target | Main output and companions | Target validation and runtime |
| --- | --- | --- |
| `js` | `.js`, `.d.ts`, `.js.map` | Locked host parser/formatter; qualified Node runtime |
| `ts` | Direct `.ts`, `.d.ts`, `.ts.map` | Locked host parser/formatter; independent TypeScript consumer checking in CI |
| `rust` | `.rs`, Cargo crate and lockfile | Rustfmt and Cargo; numeric dependencies selected by the native runtime plan |
| `wasm-core` | Core `.wasm` and readable `.wat` | wasm-tools; qualified Wasm runtime |
| `wasm-component` | Component/core `.wasm`, both `.wat`, exact `.wit` | wasm-tools and Wasmtime; public ABI remains Bool-only |
| `python` | `.py`, `.pyi`, `.py.origins.json` | Python >=3.14; standard-library helpers selected as needed |
| `php` | `.php`, `.composer.json`, `.php.origins.json` | PHP >=8.5; ext-gmp required when exact Nat/Int values are used |

Every successful build publishes a checksummed `.bundle.json` with source closure,
logical admission, assurance, public names, target/runtime descriptors and artifact
hashes. The combined TS/JS request captures and admits source once, then independently
prints and validates both outputs before a single atomic publication.

JavaScript is emitted directly. TypeScript consumer compilation in CI tests the generated
TypeScript independently. It is outside the DirectJS implementation.

Python modules expose their declared API through `__all__`; `.pyi` describes those
same source-owned values and functions. A PHP module returns its public API map:

```php
$api = require 'out/example.php';
assert($api['invert'](true) === false);
```

Python/PHP declaration-origin files explicitly describe their coverage. JS/TS use
standard source maps produced from final formatted output and captured source text.
Backend helper code is identified separately from authored declarations.

## Admission and execution assurance

The compiler captures dependency source once, elaborates canonical Core, checks it
with the independent pinned Lean kernel, erases proofs, checks executable IR, creates
the target plan and emits the requested target. Raw IR wrappers and package manifests
are data. They cannot substitute for the admitted host session.

Default `checked` mode retains the existing logically checked program path.
Explicit `--assurance ordinary` admits the qualified partial-function slice and
preserves exact logical/executable body pairing. Recursive generated code has no
compiler-imposed execution fuel. Host resources and each qualified target's lowering
still bound execution.

`--assurance verified` currently fails because behavioral certificates are unavailable.
A successful logical admission or runtime test is not presented as a backend-preservation
proof. The owned PSKernel-Core remains separately compiled and tested; the official
Lean provider remains authoritative for direct builds.

## Current language boundaries

Both input syntaxes share the compiler pipeline. The retained slice includes typed
functions, internal generic specialization, structures/inductives and matching,
selected higher-order/array operations, immutable lets, qualified Id/Except do forms,
numeric/Boolean operators and explicit ordinary partial functions.

The fourteen Practical Core feature families remain a staged implementation target.
Full mutation/loop/early-return expansion, unrestricted Lean, full type-class syntax,
Int division/modulo and fixed-width/floating runtime scalars are outside the currently
qualified direct profile. Python/PHP initially expose scalar public signatures; aggregate
values can be internal. Rust retains its existing checked generic public path. Component
Wasm retains its bounded Bool ABI.

See [the selected language reference](PSC1_LANGUAGE_REFERENCE_v7.2.md),
[Practical Core status](docs/PSC1_PRACTICAL_CORE_STATUS.json),
[architecture](ARCHITECTURE.md), [runtime semantics](docs/PSC1_RUNTIME_SEMANTICS.md)
and [current work state](AI_WORK_STATE.md).

## Historical material and future self-hosting

The compiler continues to be authored in Lean and executed natively during development.
The semantic compiler plus one chosen backend is the eventual minimal self-host closure.
Adding built-in emitters to the native host does not put every backend, target runtime,
npm tool or kernel experiment into that portable closure.

Historical seeds, fixed-point receipts and old generated-compiler packages remain
preserved under their existing recovery rules. No new full self-host, compiler/kernel
fixed-point or joint-closure qualification is claimed here. The previous README is
preserved [verbatim](docs/history/README_BEFORE_SEVEN_BACKENDS_2026-10-20.md).
