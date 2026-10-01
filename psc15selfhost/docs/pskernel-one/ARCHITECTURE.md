# pskernel-one architecture and trust boundary

## Baseline and ownership

The isolated branch is `psc2/pskernel-one`, based on compiler-only head
`90d02086146fce06df6d0a720e50f340adcbf52a`. It preserves the current generated-source
isolation fixes and compiler regressions. No provider, compiler-only bootstrap
manifest, protected branch or adjacent work checkout was replaced.

The initial selectively ported closure is Data, Name and Level from accepted
KernelCore Phase-12 head `b33e63ed6df2ad10a4a350b19af504fca45655f2`, under new
`Ps.KernelOne` / `PsKernelOne` / `psKernelOne` identifiers. KernelCore remains a
reference package. There is one implementation per rule inside KernelOne; it does
not call another checker as authority. The remaining Phase-12 modules have not
been copied or claimed as implemented.

## Current versus required boundaries

| Boundary | Current status | Required completion |
| --- | --- | --- |
| Portable semantics | Four modules, no external explicit imports | Full owned checker and admission |
| Runtime primitives | Nat, Bool, String, Char and raw string positions | Native/generated operation agreement, budgets and hostile-input tests |
| Transport | Absent | Versioned complete canonical codec, no dropped declarations |
| Prelude | Absent | Derived declarations checked; explicit assumptions and dependencies |
| Provider | Absent | Five outcomes; only Accepted authorizes emission |
| CheckedModule | Absent | Runtime-enforced provenance and exact immutable prepared payload |
| Bootstrap | Existing compiler-only contract unchanged | Separately pinned compiler-plus-one source closure |
| Generation | Kernel source and TS emission exercised; real tsc blocks execution | tsc, generated checking, C1/K1 through C3/K3 comparisons |
| Default | No cutover | Full-profile release gates and review |

The five required provider outcomes are Accepted, Rejected, UnsupportedFeature,
ResourceExhausted and InternalFailure. A Boolean internal level helper is not that
API. Failure of incomplete comparison must not later be presented as full-profile
semantic rejection. No public checked-module factory or unchecked environment
insertion API is introduced in this slice.

The eventual pipeline is immutable source snapshot → PSC preparation →
AdmissionReady → selected provider → sealed CheckedModule → erasure → VerifiedIR.
The checked payload, dependencies/prelude, semantic profile and provider identity
must remain bound together. The current compiler's AdmissionReady canonical
integrity check is not independent kernel admission.

## End-to-end trust

Native evidence trusts the exact official Lean toolchain, C compilation/linking,
hardware and the test adapter. The differential harness calls the original C++
kernel through `Lean.Kernel.isDefEq` on converted Sort expressions in an empty
environment; it does not invoke the elaborator as oracle.

Generated evidence additionally trusts PSC parsing, elaboration, canonical
encoding, erasure, VerifiedIR, backend, TypeScript and JavaScript execution. Any
future decoder or adapter influencing admission belongs in the end-to-end trust
analysis even if outside the portable semantic closure. File hashes identify
bytes; they cannot prove acceptance or protect a compromised host process.

Original native/Wasm Lean packages are external differential tools, with the same
underlying logical implementation. They are not independent votes. No default or
provider selector is implemented here, and no provider fallback is introduced.

## Smallness and resources

`SIZE.json` measures this initial closure, not a comparison of full kernels. Data
provides tiny explicit option/list representations (the unused generic result was removed); Name preserves
structured identity; Level holds universe syntax and the reviewed operations;
the root file declares the closure. No global-minimum claim is made.

There is no bounded/resumable checker API yet. Deep recursive names/levels may
exhaust a host stack; string comparison currently revisits positions and is
quadratic in character count. Generated Nat must use bigint, not JS number.
Large literal handling in the compiler is a separate known operational risk.

## Proof obligations still open

- Soundness of level simplification and max-leaf inclusion against pinned normalization.
- Complete pinned level comparison, including offsets and imax cases.
- Scope/typing preservation for future substitution, reduction and caches.
- Positivity and independently derived recursor metadata.
- Transactional admission and checked-module integrity.
- Runtime representation agreement and emitted-code correctness.

Finite differential tests do not discharge these universal obligations. Official
Lean compiling the implementation is not a soundness proof of the implementation.
