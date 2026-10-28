# @proofscript/stdlib

Verified source snapshots of the existing canonical
`psc1/stdlib/ProofScript` modules. The package build copies those files into
`src/ProofScript` without translating or rewriting them.

    import {sourcePackage, readSources} from '@proofscript/stdlib';
    const sources = readSources(); // canonical ProofScript snapshots
    const bootstrap = readSources({kind:'lean'}); // checked bootstrap references

The default API exposes source data, not a separately compiled JavaScript
standard library. The ./compiler subpath transparently exposes the existing
checked ProofScript API. Callers supply an explicit, complete source closure.
All 13 modules have one canonical editable `.ps` owner and a paired, pinned
`.lean` bootstrap reference. The generated package view copies those exact
files; edit the owners under `psc1/stdlib/ProofScript`. See the
[canonical ownership guide](../../docs/CANONICAL_SOURCE_OWNERSHIP.md).

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
