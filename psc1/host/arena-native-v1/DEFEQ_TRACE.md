# Native Church DefEq failure trace

Status: **NOT RUN** at this source checkpoint. This host diagnostic must pass its
five equivalence proofs, original native controls and actual authenticated-input
execution before its trace can be used as evidence.

## Source and input

The production checkout remains `369bee5801bd5e4476837684fad3f7e1ca8c422c`,
Lean 4.35.0 upstream `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
The frozen declaration is exactly `psKernelIsDefEqWithFuel` from
`Checker/Knot.lean`, Git blob `575f65afd2c9f6ffa02b65f2a359fb4d43218268`,
with only its recursive identifier renamed. The driver compares it against
the pinned checkout before execution and records SHA-256 source digests.

The original197-node, four-request Church body SHA-256 is
`85526c244d94e9710a6be432164c054c742d8f7c1d3ca0d8580d0874f7815a47`;
the header-adapted input is
`443428491e773dc131b1655bf72312517ddc29010112bb8bb241a48ab55c51c1`.
The generated native fixture remains
`d15790e77d82af4b55e21428ebfbe3443c1735a04585359f35d425a9fe86da8a`.
No exported recursor body, prebuilt environment or fabricated proof is imported.

The prior [stage diagnostic39638208348](https://github.com/dwijayuda/pskernel/actions/runs/39638208348)
at source `f2e6c44a506a53dc294ae6569f8371e81ed6bdd5` independently located the
original API's first failing theorem stage at type DefEq. That passing
collection does not qualify this new observer. The new diagnostic checks the
actual inferred proof type against `Eq.{2} CNat lhs lhs`, and the declared
type against `Eq.{2} CNat lhs rhs`, built from original decoded input
IDs58,48,189,192,193,196. The real kernel still checks the declarations and
theorem stages; these assertions authenticate observation inputs.

## Observation and proof boundary

`NativeChurchDefEqTrace.lean` is outside the portable kernel. It adds no axiom,
unsafe declaration, extern, compiler override, cache entry or acceptance rule.
Lean's existing `dbgTrace` prints only after an original stage returns an error;
its logical definition is identity. The runtime emits the event to stderr.

The cloned worker retains all original guards, predecessor callbacks, argument
order, checker state, cache behavior and success publication. Its18 error sites
label the failed stage. The selected fuel levels are0–16,4080–4096 and the
intervening multiples of256: at most49 distinct selected levels at fuel4096.
The parser requires strictly increasing unwind levels and at most49 events.
Both output streams are bounded to1MiB for collection.

Each term snapshot visits at most24 nodes globally. Names expose at most8
segments; text scanning starts only after a256-byte bound and includes at most64
characters. Numerals above UInt64 are summarized by a marker. Universe lists
show at most4 heads. Zero/depth guard errors inspect no term, context or cache.
Snapshots report shapes, not normalized expressions or semantic hashes.

The module proves observer identity, frozen equality to the original, traced
equality to frozen and original, and session-wrapper equality. The driver
compiles all five statements and checks every printed axiom dependency against
the existing permitted proof set: propext, Classical.choice and Quot.sound.
These are local exact equations, not a global kernel soundness theorem.

## Execution

All138 original replay controls, three baseline admission controls, three staged
theorem controls and nine staged parser controls remain mandatory.
Additional positive, invalid and preflight-resource theorem controls compare
the observer with the original API. A zero-fuel equality control uses dangling
syntax and must return the original guard before inspecting it. Nine corrupted
DefEq receipts must be refused.

`--defeq-trace` uses the real body-check session and fixed original callbacks.
A separate unmodified `psKernelV1AdmitDeclaration` call begins from the same
immutable input and must return the same exact typed result. No result is
accepted from the observer alone. The actual Church error remains a resource
failure until a separately qualified production change resolves it.

Every native mode executes detached with empty PATH, a60-second deadline and
verified cgroupv2 limits: memory.max2147483648, swap.max0, oom.group1. Setup,
cleanup, host OOM/timeout, kernel resources and invalid declarations remain
separate outcomes. Exported metadata validation is outside this diagnostic.
Collection success is neither an Arena match nor release qualification.

## Tool interruption

An authorized six-file child create_tree call returned no receipt and was
aborted after1640.6seconds. A later small child write also returned no receipt
within its explicit30-second bound. Neither call created a commit or ref update;
an unreferenced object may exist without a returned receipt. Root successfully
created the source objects through bounded connected GitHub calls instead.
These are tool interruptions, not Lean proof or kernel test failures.
