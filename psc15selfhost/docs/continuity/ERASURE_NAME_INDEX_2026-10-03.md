# Erasure lookup checkpoint

Base: `c727b50e298d5dd85acb90a84982dc09b15cf203`.
Two CPU samples of the preserved generated replay showed repeated scans of
constructor/name tables and all declaration output names. The replay eventually
completed in 77 minutes; its result is documented separately in
[REFERENCE_REPLAY_2026-10-03.md](REFERENCE_REPLAY_2026-10-03.md).

Erasure now indexes declaration names, constructor/recursor metadata and
structure metadata with persistent 16-bit collision buckets. Buckets retain
full structured-name comparisons and the old first-entry precedence. A separate
index reserves every declaration output name, including shadowed entries; a
stored count preserves the local-renaming fuel bound. Ordered declaration
enumeration and checked module admission remain unchanged.

Validation executed:

- Native compiler, replay auditor, minimal self-host tests and product-match
  tests build; both test executables and the native erasure behavior audit pass.
- Source guards, including mutation checks for collision equality, first-entry
  precedence, output-name lookup and the Nat recursor registration, pass.
- A PSC-generated JavaScript regression checks deliberate hash collisions,
  hierarchical versus dotted names, replacement and list precedence, 1,500
  entries and reserved output names. A real emitted function with a local
  `A_value` and global `A.value` returns 16, proving the local does not capture
  the global's emitted name.
- The 74-module source closure passes the real native checked preparation and
  explicit WASM reference admission, emits TypeScript, and passes strict tsc.

That fresh reference build has source closure
`5c14a12694db4f54a1135ea6f9b7bc33879ac6aa5c0b604070d5438aced0d1d4`,
admissions `58759b2687f16ae2984648ed80a046cb361b83429a45e8d8cd685c21470692e1`,
and generated JavaScript
`b5b040957aef816c35002fb7c310364057ed701e44613ae14f59134524453e2a`.
It is preserved in `work/erasure-index-reference-c727b50e`. This native build
does not establish the new generated compiler's fixed point or a measured
full-replay speedup. Those require subsequent generated replay.

CI run 37050227926 for the base commit passed provider, native, checked-host,
source-guard and parser/erasure steps. The owned full-input check rejected
`unsupported-expression:nat`; the separate compiler-only diagnostic was
cancelled at the 25-minute job limit. No green full self-host CI is claimed.

The owned kernel remains the default. No provider, legacy routing or KernelOne
code is changed by this compiler lookup fix.
