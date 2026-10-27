# Transform provenance and the extended modular graph

The v2 pilot adds actual compiler collections, names, text building and JSON code
to the modular distribution. It keeps the original v1 package/negative tests.
The bundled proofscript compiler remains the release reference.

## Data flow and ownership

The production frontend captures each supplied source once, with exact tagged
Core declaration origins. Erasure names establish the original value owners.
Both source grammars use that same frontend and canonical admission protocol.

[CompilerIr.Provenance](../../packages/compiler-ir/src/Ps/CompilerIr/Provenance.lean)
defines backend-neutral diagnostic/link data:

| Field | Meaning |
| --- | --- |
| kind | Value declaration, structure or inductive |
| outputName | Exact name produced by this pass |
| inputName | Immediate parent in the input of this pass |
| arguments | Exact closed type arguments supplied to specialization |
| rule | Retained identity, specialization, or worker companion |

Retained identity means the name/parent remains, not that the body was untouched.
Transforms can rewrite a retained declaration's body. The record is not a
validation token or a semantic-preservation theorem.

[Specialization](../../packages/compiler-ir/src/Ps/CompilerIr/Specialize.lean)
returns provenance at its three actual structure/inductive/value creation sites.
It captures the same allocated output name and request arguments used to create
the declaration. [Worker fusion](../../packages/compiler-ir/src/Ps/CompilerIr/WorkerFusion.lean)
uses the existing plan's original/companion pair after fresh-name selection.
No owner is recovered by parsing $spec$, $worker or generated elaborator names.

Existing public transform APIs share the same implementation and leave full
origin-list tracing disabled. Explicit WithOrigins APIs enable it. This avoids
retaining unused provenance lists; no zero-overhead or performance-win claim is
made. Validation, scheduling, fuel, input/error order and raw target semantics
remain required.

[Ownership composition](../../packages/backend-common/src/Ps/BackendCommon/Modules.lean)
rechecks exact input/output IR, unique complete value/type origin coverage,
existing parents, argument arity/groundness and rule consistency. It looks up a
value's parent owner in the preceding pass. A specialized function's worker
therefore follows two explicit parent edges back to the captured original owner.
Types and constructor symbols remain in the shared runtime unit. Producer
provenance is diagnostic/link data; arbitrary user metadata cannot grant
checking or publication authority.

## Concrete graph

The [extended consumer](../../test/modular/Extended.lean) uses the four existing
compiler modules directly, including generic list operations, curried workers,
large naturals, Unicode name formatting and actual JSON parse/canonical encoding.

| Source unit | Generated package |
| --- | --- |
| Shared types and runtime | @proofscript/modular-pilot-runtime |
| Ps.Foundation.List | @proofscript/modular-pilot-ps-foundation-list |
| Ps.Foundation.Name | @proofscript/modular-pilot-names |
| Ps.Foundation.Text | @proofscript/modular-pilot-ps-foundation-text |
| Ps.Bridge.Json | @proofscript/modular-pilot-ps-bridge-json |
| Pilot.Consumer | @proofscript/modular-pilot-consumer |
| Integrity loader and exact cohort | @proofscript/modular-compiler-pilot |

Every source package contains its own generated function bodies, type declarations from checked IR, readable generated TS/maps, owned Lean/PS snapshots and provenance.
They are not facades over a monolithic compiler. Clone names remain internal,
experimental implementation details; parent records provide the readable origin.

The [shared assembler](../../host-tools/modular/build.mjs) and
[loader](../../host-tools/modular/loader.mjs) handle both profiles. v1 remains
version0.1.0-psc1-modular-pilot.0 with exactly two source units.
Explicit protocolpsc1-modular-pilot/2 uses version0.1.0-psc1-modular-pilot.1,
two to eight ordered sources, and at most nine units including shared runtime.
The measured fixture has five sources, six units and seven npm packages.

Package labels are derived deterministically from captured source module names.
Case/underscore/dot slug collisions refuse. Actual global references determine
value import edges; source imports alone are not a runtime graph. Backward edges,
cross-unit cycles, eager initializers, unknown owners and unsafe labels refuse.
Synthetic declarations remain in their parent's unit. Type-only source-unit
coalescing and arbitrary strongly connected package groups are outside this profile.

## Qualification and reproduction

Source7d7ada7ad7d5f5ca1504527342888d929e1b9959 passes
[full source40481560025](https://github.com/dwijayuda/pskernel/actions/runs/40481560025):
16 selected jobs,37/37 finite Practical Core criteria and scoped seven-backend
execution. Tested mergeaccd2875a6c09ab30f3b3fd02e4c07883d4dd675.
The [dated receipt](../PSC1_TRANSFORM_OWNERSHIP_QUALIFICATION_2026-10-27.json)
retains exact source/IR/admission/package/tool identities and all attempts.
The integrated artifact12722888572 includes both complete installable cohorts.

[Finite v2 contract](../../test/modular/extended-contract.json) defines29 named
package cases. Existing v1 has28 package cases/14 planner refusals; provenance
adds12 invariants/eight refusals and extended layout adds eight refusals.

The Linux workflow builds a native parity harness in a separate temporary Lake
package, requiring an immutable PR#195 checkout at
cc13ebfabf6763703ee1ec75a663002a9134bc74. It verifies the baseline's tracked source
tree remains clean and pins the harness source/binary. The harness calls only
the old frontend, validation, specialization, worker fusion and printer APIs.
For both grammars it compares every byte of canonical original/specialized/fused
IR, canonical admissions and bundled JS/TS. It does not implement another compiler.

A Lean interpreter attempt failed because a private standard-library artifact
was unavailable. Native compilation avoids that interpreter dependency; no Lean
checking, IR validation or resource boundary is bypassed.

Actual installed tests execute both JS/TS variants under Node22.23.3 and Bun1.4.4,
compare bundled same-IR observations, strict-check NodeNext/bundler declarations,
check shared runtime/tag identity across packages, and reject changed JSON code,
changed transform provenance and cross-profile package mixes before import.
Exact seven-tarball reproduction and both transaction failure outcomes are tested.

Workflow: .github/workflows/psc1-modular-pilot.yml. It prepares the immutable
baseline and runs:

    lake build psc1_modular_pilot psc1_independent_checker
    lake env lean --run test/modular/Provenance.lean
    lake env lean --run test/modular/ExtendedPlan.lean
    lake env lean --run test/modular/Plan.lean
    node test/modular/native-probe.mjs
    node test/modular/extended-native.mjs
    node test/modular/packages.test.mjs
    node test/modular/extended-packages.test.mjs

The extended test requires PSC1_TRANSFORM_BASELINE and the two native harness
paths supplied by CI; it refuses to skip baseline comparison. Installable-extended-
lean and installable-extended-ps artifact directories contain separate complete
seven-tarball cohorts and SHA256SUMS. Install all seven paths together using
npm install --offline --ignore-scripts. Select one JS/TS variant for the graph.

## Trust, resources and unfinished work

Official independent Lean4.35.0/eb6cafb7290e8bd5f2937522d8d804f58f02bafc remains.
Every transform input/output is strictly rechecked; both final emitters revalidate
the graph. Producer/baseline requests keep240 seconds, checking120 seconds,
4GiB address space,8MiB stack, reference fuel4096 and the existing pass fuels.
Input remains1MiB, native response/cohort32MiB, surviving IR values256 and nominal
types64. Neither output count nor package splitting multiplies those byte bounds.

Kernel admission of exact Core is separate from source/backend preservation.
Inventory verification assumes a trusted bootstrap and stable installed files;
package exports are not a sandbox. npm tarballs/evidence publish as one flat,
atomic generation. This is not arbitrary nested-service publication qualification.
Pre-commit faults retain the old pointer; post-commit faults explicitly report
committed durability uncertainty.

This is an executing compiler-component graph, not a complete modular compiler.
The source-import navigation receipt measures125 modules/2692524 source bytes
from Ps.CompilerUnified.Service. It is read-only navigation, not transformed
runtime ownership evidence. The separately generated89-module JS service passes
ten G1 selected-corpus cases; that is not modular self-hosting qualification. Complete compiler partitioning, explicit handling of
cross-package recursive groups, portable planner qualification, modular G1/G2/G3
and fixed points, other platforms and the arranged human maintainer trial remain
pending. Frozen qualified compilers, optional providers and genuine kernel
implementations are retained. No merge or registry publication is authorized.
