# @proofscript/stdlib

Verified source snapshots of the existing canonical
`psc1/stdlib/ProofScript` modules. The package build copies those files into
`src/ProofScript` without translating or rewriting them.

    import {sourcePackage, readSources} from '@proofscript/stdlib';
    const sources = readSources(); // existing Lean snapshots

The default API exposes source data, not a separately compiled JavaScript
standard library. The ./compiler subpath transparently exposes the existing
checked ProofScript API. Callers supply an explicit, complete source closure.
A listed source variant means that files of that kind exist; it does not claim
that every module has a .ps counterpart.

This package does not automatically register a portable external library.
Existing reserved namespace, independent admission, strict IR and ABI refusal
policies remain. Stable standalone compiled-library conformance is not claimed.

From the repository checkout:

    npm run build
    npm run clean
    npm pack

Installation uses prebuilt npm artifacts and has no build/download hooks.
Source-only interfaces and private compiler runtime APIs are distinct.
See [the package guide](../../docs/guides/npm-packages.md).
Apache-2.0; retained upstream notices accompany the distribution.
