# pskernel-min usability and full-compiler completion contract

User target: a usable checker first, then full compiler support.
Start: R6 reporting source 4262332ed5a0a623c82da4d9d9d969f43928cba5.
All project execution stays on GitHub Actions Linux. Continue with the user's
GPT-6.1 Sol / High setting. Protected base 94e0c13f6a4b434f73c859cc0c716cb6fb8d1340
is unchanged. Preserve the [R6 guideline](PSC1_MIN_KERNEL_R6_GUIDELINE.md).

U1 is qualified at eea9306384ab68c220bece18e769fd16d7903f3a; see the [usage guide](PSC1_MIN_KERNEL_USABLE_GUIDE.md)
and [dated receipt](PSC1_MIN_KERNEL_USABILITY_QUALIFICATION_2026-10-28.json).
C1/C2/C3 remain open; the overall full-compiler goal is not complete.

## U1: usable bounded checker

Completion requires an immutable, privately packed standalone Node tarball,
compiled from all ten actual R4B runtime modules without test vectors. The
installed API and file/stdin CLI must check exact bytes through the existing
public R4B entry, return JSON-safe acceptance/refusal summaries, and never invoke
another provider. A documented opt-in removes exactly one final transport LF
and reports both original/checked byte identities. The CLI runs its checker in a
256 MiB old-generation worker with a 120-second deadline; all structural/input
limits remain unchanged.

The exact tarball must pass offline local/global installation, manifest/hash
parity, the native/official-positive 52-case corpus through the installed API,
hostile inputs and forged acceptance/provider flags, strict TypeScript consumer,
file/stdin/framing/exit/IO/FIFO cases, execution without external tool PATH and
complete connected-runtime checking through both installed API and CLI. Retain
source/admission/output hashes and tarball qualification in GitHub artifacts.
Keep all R0–R6 proof guards and existing time/memory ceilings. This milestone
is usable at the stated fragment/runtime boundary, not full compiler support.

## C1: complete compiler admission

Fresh source graph: Ps.CompilerUnified.Service, currently 124 modules,
4743 source Core / 4748 logical members, 3466 records, 29889352 canonical
transport bytes. The complete current graph, its 115-member prelude, 60
foundational axioms/contracts and five exact partial-body obligations must be
handled by a proved checker profile with exact source identity, fresh names,
universes, dependent binder/recursor/projection cases and source-body semantics.
No fixture/origin/hash whitelist, arbitrary axiom admission or trusted producer
accepted flag may grant admission.

The current R4B packet limit is 2 MiB and 512 declarations. Its linked byte-list
representation already observes about 300 MiB RSS for the 1.8 MiB checker packet.
Simply raising limits cannot establish safe/usable checking of the 29.9 MiB
compiler packet. A scalable byte/parser/state representation and its refinement
proof are part of this obligation. R4B stays stable; new grammars need an explicit
profile, independent model and actual implementation-to-model theorem.

## C2: actual compiler preservation

Discharge R5's actual recursive caller premises using independent Core source
semantics. Begin from psEraseRuntimeExprWithFuelWorker, then telescope
type/proof omission with actual substitution, scope transitions and capture/name
freshness. Extend closures/calls, nominal regular carriers, constructor/projection/
match output and continuation/tail scheduling through actual producer functions.
Bind target syntax to exact emitted bytes and state/check the external
TypeScript/ECMAScript implementation assumptions. R6's UTF-8 join equations
remain a byte boundary, not a general compiler theorem.

## C3: actual complete compiler generations and user path

Run the real full compiler admission through its public byte API with no fallback,
then actual min-checked G1/G2/G3 against the exact final source and payloads.
Qualify practical compiler use and installable CLI/library flows on Linux with
bounded failures, resources and retained evidence. Default-provider promotion
requires a separate explicit decision after these obligations; production min/
dual continue PSC1_MIN_CANONICAL_BRIDGE_UNPROVED until qualification.

## Work order and evidence rule

Complete U1, then continue C1/C2 as explicit proof/implementation batches,
measuring the entire newly connected graph each time. Every new theorem needs
an explicit root and fresh dependency report (axiom-free or exactly propext-only).
Keep failed/superseded and source-qualified/report-qualified evidence separate.
Full compiler support is complete only after C1, C2 and C3 are all satisfied;
shipping U1 or adding base-case lemmas never marks that overall goal complete.
