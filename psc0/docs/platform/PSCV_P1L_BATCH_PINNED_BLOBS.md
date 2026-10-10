# PSC0 PSCV P1-L — selected-instance pinned Git blob evidence

**Qualified:** [run 38060694489](https://github.com/dwijayuda/pskernel/actions/runs/38060694489), all four jobs passed at implementation source `965cbc3c5b3809f4f63c4fd28a76233c1abe0ff5`. All **45** selected imported constants belong to **7** upstream modules, whose exact pinned Git source files/blobs were all found. Only **6** names have unique explicit `instance` lexical lines; 39 remain without exact explicit named lines. This is not a source-to-elaboration proof or normative mapping. Observation SHA256 `134bc8acdfdb6ea7e57cb5b4effc4f74ea928f39839cc7a0050e8281fa4c469a`. [Artifact 11672956734](https://github.com/dwijayuda/pskernel/actions/runs/38060694489/artifacts/11672956734) · [qualification receipt](pscv-p1l-qualification-2026-10-10.json).

P1-J generated **84** typed arithmetic class queries from the exact
PSCV-RC-v2 required surface, and P1-K checked the **45 distinct**
selected imported Lean constants and their type/module provenance.

P1-L extends the P1-K imported-module record to source files from
exact upstream Lean **4.35.0-rc3** commit
`470d5ce1400764999581fd26d5d72b00d990b0f4`.
The review computes a possible source path for each imported
`Init.*` or `Std.*` module, verifies the genuine Git blob SHA-1
against the original source bytes, and checks unique explicit
`instance SelectedName` lexical occurrences where available.

Module files that cannot be located are reported as unavailable, not
fabricated. A lexical match is explicitly labeled a *candidate*:
no proof connects that source span to Lean's elaborated constant or
to an approved PSCV Standard snapshot ID. Generated instance names
can have no literal source match.

The input selected-types observation must have the exact previously
qualified P1-K identity and its cryptographic content identity is
recomputed. It must keep every selected import type/module name
unchanged. P1-L never trusts a copied `verified` flag, plugin
manifest, emitted TypeScript code, or typeclass name alone.

**The 191 outstanding required Standard IDs remain unresolved.**
P1 closes only after approved source-to-declaration and generic-to-
concrete instance choice, scope/priority/import ordering, and frozen
coercion, simplification, prover and effect/WP law registries with
a normative digest. P2–P5 still follow
[P1–P5 sound gates](PSCV_P1_TO_P5_SOUND_GATES.md).

No compiler, PSKernel, source seed, TS7 toolchain, npm package or
PSCV certificate/publication gate has been changed.
