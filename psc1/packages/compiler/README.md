# @proofscript/compiler

PSC1 .13 shared implementation owner for the existing checked compiler API.
This package reuses the exact qualified JS/TS compiler executors and host bodies;
it does not introduce a parser, compiler pipeline or new self-hosting claim.

proofscript depends on this package and bundles the core set. Core adapters depend
here, never on proofscript. This package requires the matching genuine Wasm Lean
provider; native checking, engines, provider executables and target SDKs remain
explicit optional tools discovered by the existing pinned resolver.

The existing public checked API is exported from "." and "./compiler". Source
snapshots remain available through readSources/sourcePackage. Accurate declarations,
typed IO and metadata exports are preserved. The sealed internal service retains
its original proofscript logical identity while its physical npm owner is compiler.

    npm run build
    npm run clean
    npm pack

No source/compiler/kernel implementation is changed for packaging. Source-only
interfaces and independent compiler-internal modularity retain their prior bounds.
Owned code is Apache-2.0; all qualified input/upstream notices are retained.
