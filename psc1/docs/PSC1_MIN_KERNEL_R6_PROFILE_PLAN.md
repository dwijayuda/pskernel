# PSC1 MinKernel R6: constructive text composition

Status: planned decision experiment, not qualified. Base: R5 reporting head `8d156294cb4632f50abd09d19a9d1e701194cbde`.
Protected base `94e0c13f6a4b434f73c859cc0c716cb6fb8d1340` remains immutable.
Follow [R5 guideline](PSC1_MIN_KERNEL_R5_GUIDELINE.md).

## Selected boundary and decision gate

The actual TypeScript emitter joins fragments with `psTsJoin`, whose two
append calls currently use opaque `String.Internal.append`. Pinned Lean
4.35.0 (`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`) exposes constructive
`String.append` through UTF-8 ByteArray concatenation; the logical ByteArray
append is list append. PSC1 already declares both append names in its prelude
and erases both to the same string-append intrinsic.

First run an Actions Linux experiment without changing `psTsJoin`:
print dependencies for the exact constructive UTF-8 equation; compare native
modern/legacy append and actual generated append/join on Unicode, combining,
control, empty and long inputs; independently check exact source admissions.
Proceed with the two-call migration only after compatibility and the existing
axiom policy pass. No laws for opaque append are assumed.

## Planned implementation and evidence

After the gate, replace the two actual join append calls with constructive
`String.append`. Prove general UTF-8 byte-list composition of the actual
recursive join, then selected actual binary-emitter fragment templates using
R5's expression-template theorem. These are byte equations, not ECMAScript
parser semantics or numeral-rendering theorems.

Register proof and fixture roots explicitly. Proof-only imports stay outside
all compiler/runtime source graphs. Test fixture scope is separate from the
connected checker. Preserve every R0–R5 theorem report guard, 10/10/20 minute
job budgets and the 256 MiB generated-runtime old-space limit. All proofs,
builds, compiler execution and tests run only on GitHub Actions Linux.

Run native and strict emitted-module byte comparisons; independently validate
the exact source packets with the pinned official checker; require public
R4B to refuse the String-bearing fixture with delegated=false. Run the full
connected R4 checker self-admission, hostile-input/resource cases, fresh compiler
census and ordinary Linux/installed regression workflows. Retain receipts,
identities and logs. Require terminal source CI before a docs-only reporting
commit and a dated R6 guideline/evidence handoff.

## Claim boundary

No min-profile expansion, fixture whitelist, new foundation law, axiom,
`sorryAx`, choice or quotient dependency is authorized. New proof reports must
be axiom-free or exactly propext-only. Official Lean Wasm remains the default;
min/dual production refusal remains `PSC1_MIN_CANONICAL_BRIDGE_UNPROVED`.
Compiler preservation stays partial; no complete recursive erasure, source
freshness/name semantics, closures/scheduling, ECMAScript semantics, full
compiler admission, self-hosting, G1/G2/G3 or release claim follows.
Native constructive String semantics and PSC1's primitive prelude declaration
remain distinct evidence layers. No merge, protected-base write or package
publication is part of R6.
