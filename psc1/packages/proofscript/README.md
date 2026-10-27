# proofscript

PSC1 .13 installs the core package set automatically. This existing root package
declares and bundles all 20 required existing @proofscript packages, including
compiler, core, elab, syntax, erasure, foundation, JS/TS/Rust/Wasm adapters, and
the genuine official Lean 4.35.0 Emscripten linear-memory Wasm checker.

The existing @proofscript/compiler package owns the one qualified JS/TS compiler
implementation. Other adapters depend on compiler. No package depends back on
proofscript, and optional provider peer edges are also checked for cycles.
Source-only packages remain verified source interfaces, not new private runtime APIs.

Install the unpacked ZIP's root tarball, with Node >=22.23.3:

    npm install ./proofscript-0.1.0-psc1.13.tgz
    npx --no-install psc --help

No install hook, source build or network toolchain download is used. Every core
package is present under the installed root's node_modules. npm may retain bundled
dependencies there rather than hoist them into the project's top-level node_modules.
Use the guaranteed root exports without relying on hoisting:

    import {compile} from 'proofscript';
    import {readSources} from 'proofscript/foundation';
    import {compile as compileJs} from 'proofscript/backend-js';

All core packages also retain their original npm names for explicit direct installs.
Python/PHP providers, native checking, optional Rust/Wasm compiler engines and target
SDKs are separate explicit packages. No missing provider silently falls back.

Official independent Lean checking, strict original/transformed IR, exact qualified
compiler source identities and all existing execution/resource policies remain.
Public compilation accepts both .lean/.ps; source packages expose only variants
actually present. Full compiler-internal modular code generation remains deferred.
Linux CI qualifies this distribution; final non-Linux consumers remain separate.

Owned code is Apache-2.0. Qualified input and third-party notices are retained.
No registry publication or merge is included.
