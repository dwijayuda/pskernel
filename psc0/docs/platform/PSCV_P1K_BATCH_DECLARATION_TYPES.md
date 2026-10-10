# PSC0 PSCV P1-K — imported arithmetic selected instance types

**Qualified:** [run 38060194301](https://github.com/dwijayuda/pskernel/actions/runs/38060194301) passed all four jobs at source `a18d46e2934c9bcdc2b908470e70687418141a86`: 42 normative rows, 84 actual Lean queries and **45 distinct selected constant declarations with imported types/modules**. Machine observation identity `abc06182e2875b15f150fabd567fa7a3c86ccb783030bf0ac04dc635fe41a372`. [Actual-Lean output artifact](https://github.com/dwijayuda/pskernel/actions/runs/38060194301/artifacts/11672643189); [qualification JSON](pscv-p1k-qualification-2026-10-10.json). No approved Standard instance mapping or certified artifact is implied.

**Purpose:** scale imported constant type/module observation from the 11
handpicked P1-H names to **every distinct instance name** selected by
the P1-J source-derived 84 typeclass queries.

The source/goal producer is P1-J's exact normative RC-v2 arithmetic
matrix (42 operator/type rows, 14 numeric basis types, 84 generic and
concrete typeclass goals). P1-K first re-executes the source in the
actual pinned Lean4.35.0-rc3 environment and rechecks the previous
qualified observation digest. It derives all distinct selected names
from that exact transcript, then runs
`PSCVL/ArithmeticInstanceTypes.lean`, which requests their
imported constant type expressions and actual imported module names
using Lean's environment APIs. No arbitrary package code or
predefined human-selected instance subset participates in the result.

The review rejects changed names, unrecognized Lean constants,
missing type declarations or imported-module provenance, malformed
source, incorrect normative bytes, changed typeclass responses, and
invented authority flags. Its result describes observed imports from
the much larger `PSCVL.Policy` environment; it does not claim
`psc-standard` typeclass priority/tie semantics.

An imported declaration *type* and module are not yet immutable
file/blobs/line provenance or proof of matching runtime operations.
The existing P1-I pinned source approach can be applied to these
names in a later stage. Nothing here proves generic-to-concrete
dictionary dependency, discharges a PSCV Standard snapshot ID or
creates a trusted verification certificate.

The normative requirements remain **230 rows/194 IDs**, with three
prior direct Boolean locations and **191 unresolved mappings**.
The [P1–P5 sound gates](PSCV_P1_TO_P5_SOUND_GATES.md) remain in
force. The normal compiler, selected native Core, self-host source,
TypeScript7 backend, release, seed and verified-executable refusal
are unchanged.
