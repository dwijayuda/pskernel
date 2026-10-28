# PSC1 MinKernel R5 compiler-stage preservation profile

Status: **qualified scoped batch**, source `f58a1d8f98d1d438a9697371466e07d1416beec4`.
Continue with GPT-6.1 Sol / High. All project execution ran on GitHub Actions Linux.
Read the [current guideline](PSC1_MIN_KERNEL_R5_GUIDELINE.md) and
[dated receipt](PSC1_MIN_KERNEL_R5_QUALIFICATION_2026-10-28.json).

## Declared semantic domain

The independent scalar IR semantics covers Nat, Bool and Unit values, lexical
variables, lets, conditionals, selected binary intrinsics and Bool.not.
Unsupported IR has no evaluation derivation. The ten binary operations are
Nat add/sub/mul/div/mod/beq/ble/blt and Bool.and/or. This compiler IR domain includes
operations beyond R4's admitted source primitive grammar; no kernel rule widens.

The actual functions in Ps.Erasure.Expr and Ps.BackendTs.Expr are imported
directly into the proof-only library. The existing local binary lowering body
is now shared as psEraseBinaryIntrinsicApplication, and the real recognizer calls it.
The separate main-Lake roots CompilerPreservation and CompilerPreservationTrust
stay outside executable compiler/kernel import graphs. The registered
Ps.MinKernel.Tests.CompilerScalar fixture is test-only.

## Qualified theorem statements

The 21 new printed theorem reports are five axiom-free and sixteen propext-only.
The retained earlier suite has 204 reports, all within the unchanged axiom policy.

- wrap_preserves, wrap_reflects and wrap_iff connect actual capture-let wrapping
  with an independent chronological lexical capture history, for arbitrary lists.
- curry_iff connects actual parameter currying to sequential lexical binding for
  matching argument lists and scalar-result bodies.
- wrap_invocation_preserves and capture_curry_preservation compose the actual
  wrapping/currying expressions through CapturedInvoke.
- mapped_binary, erase_binary and primitive_stage_preserves prove the actual pure
  binary stage's local semantics under explicit recursive operand-erasure and
  value premises. Whole recursive erasure and source-name dispatch remain open.
- Exact selected token-composition and literal-construction equations, plus
  empty/three-operand refusal corollaries, target the actual emitter functions.

These semantic relations do not establish arbitrary closure/call effects,
upstream capture freshness, IR typing in general, or an ECMAScript engine theorem.
Four positive constructed IR declarations and four negative original-IR modules
exercise the separate actual checked-emission boundary.

## Opaque text and generated context

Pinned Lean's [String bootstrap declarations](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/String/Bootstrap.lean)
make String.Internal.append, length, get, next and atEnd opaque externs. Their
character laws are not definitional kernel equations. R5 adds no axiom,
native_decide substitute or arbitrary string-model assumption. Output statements
retain opaque token joining and psNatToString; character/decimal semantics remain open.

psTsEmitExpr can return yield* syntax requiring its surrounding generator context.
Structural probes therefore pass complete declarations through psTsEmitCheckedModule,
retaining the actual module/runtime. No generated-string repair or TSC relaxation
is used. Selected pure scalar/template expressions remain a separate test scope.
Known zero-runtime-parameter declarations export values; first-class functions
use the curried ABI and the actual module-local runtime.

## Terminal Linux qualification

[Focused run 40557438637](https://github.com/dwijayuda/pskernel/actions/runs/40557438637)
passes prior proof/native 122377152332, new preservation/ABI 122377151932 and
portability/census/public bytes 122378533905. It checks:

- 400 scalar results against native mathematical oracles; 294 native/generated
  calls from the exact same physical registered source; three literal probes.
- Four checked structural IR declarations, capture ordering/composition, currying,
  shadowing and twelve operand-evaluation/short-circuit traces.
- Thirty emitter, thirty pure-stage and thirty recognizer arity refusals;
  ten nominal recognizer checks; four invalid original-IR refusals.
- Independent pinned official admission and the generated public R4B byte API.
- All retained R0–R4 checks, a fresh compiler census and complete connected
  checker native/generated self-admission.

The source API's original 8834-byte transport line ends in LF. It is official-accepted
and refused by public R4B host ASCII preflight. The distinct 8833-byte canonical
packet removes exactly that final LF and preserves every preceding byte. It is
official-accepted and public-R4B-accepted without delegation. Canonical SHA-256:
`3c8bf2db9edd59bc84a43caa4e857504607a8a8a5ad2f680d24ede347d09bcb7`.
The original message/hash and both results are retained; the decoder is unchanged.

[Main run 40557451248](https://github.com/dwijayuda/pskernel/actions/runs/40557451248)
passes full Linux 122385846634, gate 122396946024 and every selected dependency;
the benchmark is deliberately unselected. Tested merge
85800efb9693944d8e3a32406ac3f8f0b90469eb shares the qualified source tree.
[Installed CLI run 40557438460](https://github.com/dwijayuda/pskernel/actions/runs/40557438460)
passes both jobs, preserving frozen compiler/kernel/provider payloads.
It does not promote the current development compiler or qualify a min generation.

## Retained runtime and remaining scope

The exact connected checker is still ten modules / 103181 source bytes /
307 origin members / 206 records. Its 1804358-byte packet, SHA-256
041d55f110471b91b69d134a38daeb94ee555a71e797b48a0c00cc6aa66ee516,
passes native and generated self-admission. The separate eleven-module source/test
bundle remains 591107 B TS / 703128 B JS, including vectors/shared runtime.

The fresh compiler graph is 124 modules / 4743 source Core members /
4748 logical members / 3466 records / 2685300 source bytes, with 115 prelude
declarations and 60 foundational axioms. Compiler min coverage stays 0/124,
Practical Core 0/37 and min G1/G2/G3 unqualified.

The 10/10/20-minute proof/new-proof/portability limits and 256 MiB old-space caps
remain unchanged. Observed RSS is not an old-space ceiling or complexity theorem.
Production official Lean Wasm stays default; min/dual continue to refuse
PSC1_MIN_CANONICAL_BRIDGE_UNPROVED. Next work must close actual text, recursive
erasure, freshness, representation and scheduler composition obligations described
in the guideline. No whole-compiler preservation, full Lean conformance, compiler
self-hosting or release assurance is claimed.
