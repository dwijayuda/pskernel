# Bootstrap, source authority and fixed points

Status: required staged process; stages below are not completed by this document.

## Name generations independently from language profiles

`PSC1` and `PSC2` name language profiles. `G0` is the external Lean-built seed;
`G1`, `G2`, `G3` are generated compiler executables. Each generation records
both the subset used to implement it and the language it accepts. The old
TypeScript compiler may remain an oracle/bootstrap option where proven capable;
it is not mandatory when official Lean can build the seed directly.

## Source-authority rule

Handwritten `.lean` is authoritative during bootstrap. Generated `.ps`, `.ts`,
`.js`, Rust and Wasm are outputs. Fix generators or authoritative source rather
than editing outputs. Promote `.ps` only after canonical round trips,
independent checking and the declared fixed-point gates close. Record the
promotion revision; thereafter `.lean` is a supported generated representation.
Compiler and kernel transitions may have different dates and must be labeled.

## Dependency closure manifest

Before generation, enumerate every semantic module reachable from compiler
entry points, all required stdlib code, backend modules and kernel/provider
dependencies. Record excluded host modules and why each is nonportable.
An imported Rust module cannot be omitted because the selected output is TS.
If a deliberately smaller compiler profile excludes a backend, change the
explicit entry/manifest and preserve the full distribution separately.

Classify every required source feature as supported PSC1, supported documented
PSC2 bootstrap extension, host-only, or unsupported. Official Lean acceptance
does not prove PSC source compatibility. A compiler that needs a new feature
before it can implement that feature must name its external bootstrap host.

## Stages

| Stage | Action | Required evidence |
| --- | --- | --- |
| B0 | Repair workspace, package resolution and source census | Every required module accounted for; no silent skips |
| B1 | Build G0 with pinned Lean/Lake | Clean build and relevant tests; recorded tool/profile identity |
| B2 | G0 parses/elaborates/checks the actual compiler closure | Independent admission, not only an encoded request |
| B3 | G0 emits canonical compiler `.ps` | All imports/declarations preserved; generated tree rechecks |
| B4 | Compare `.lean`/`.ps` and reverse translation | Admitted Core and IR parity; printer idempotence |
| B5 | Compile generated `.ps` to TS, then pinned `tsc` to G1 JS | Clean generated build and representative CLI/compiler execution |
| B6 | G1 compiles the same authoritative generated `.ps` tree into G2 | Source/core/IR/output parity and independent re-admission |
| B7 | G2 compiles that same tree into G3 | G2/G3 fixed point, clean regeneration and conformance |
| B8 | Promote source authority explicitly | Reviewed evidence bundle; reproducible rollback source retained |

Evaluate G0/G1 disagreement before running further generations. Source input
must be fixed for compiler comparisons: if source regenerates too, compare its
manifest and canonical content independently so source drift cannot hide a
compiler difference.

## Comparison contract

Record raw artifact hashes and semantic fingerprints separately. Define and
version the canonical serializer before calling its digest semantic evidence.
Preserve declaration kinds/order where meaningful, universe structure,
assumptions, safety/opacity, dependency identity, executable operations and
effects. Normalize only documented irrelevant fields such as source spans.
Do not erase proof differences, operations or types merely to obtain equality.

Within the same pinned host/toolchain, canonical TS text equality is a useful
additional gate. Existing text comparison scripts must be retained but extended
with admitted-Core/IR evidence. Equivalent runtime results alone are weaker.
Native binary byte identity is not required across toolchains/platforms.

## Compiler + kernel closure

First compiler self-host may use an explicitly named external checker. The full
workspace target additionally requires translating, checking, compiling and
repeating generations of the kernel closure. Run the generated kernel against
the actual compiler admission stream and malformed variants, compare with the
independent TS/pinned Lean oracle, then repeat with the next generation.
Never use only the newly generated kernel to certify its own replacement.

Preserve separate identities for compiler implementation profile, accepted
language profile, kernel profile and host runtime. A kernel can accept Core
whose producing source syntax the compiler does not yet support.

## Host transitions

JavaScript is the first fixed-point host. Keep TypeScript 5.8.3 as the current
repository emission-tool pin until a reviewed upgrade; record the Node version
actually used. Lean 4.34.0 is the current semantic/bootstrap pin.

Rust self-host follows JS stabilization: JS emits Rust, rustc builds a native
compiler, the native compiler emits the next Rust generation and regenerates
TS. Compare Core/IR and target source across hosts. The current Rust toolchain
file pins 1.98.1; this documentation does not independently certify availability.

Wasm backend conformance requires actual validation/execution on the declared
runtime/profile. Wasm-hosted compiler self-compilation is a separate milestone.
Keeping Wasm non-blocking for JS does not excuse regressions in its existing
supported behavior.

## Planned generation evidence

Every future generation artifact records: repository/source commit; dirty-tree
digest or clean status; complete source manifest; parent compiler digest; actual
executed compiler/provider paths and hashes; tool versions; language/Core/IR/
protocol profiles; foundation/environment digest; host/FFI/native assumptions;
resource limits; commands; Core/IR/source/output hashes; positive and negative
test results; UTC timestamp. Missing evidence prevents stage closure.

Proof terms and logical assumptions must be available for independent replay.
Reproducibility checks run without unrecorded prior `dist` outputs, hidden
fallback executables, network-fetched semantic dependencies or ambient cache
trust. Retain earlier valid artifacts for rollback; never use them silently to
make a failed generation appear successful.
