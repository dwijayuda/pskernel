# M2+A: operator inference, power and shifts

Status: coherent implementation awaiting cloud qualification; not M2+A completion.

## Pinned implementation study

Lean 4.35.0, commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc:
- src/Lean/Elab/Extra.lean: toTree, light synthesis, read-only maximal-type analysis, homogeneous guards, heterogeneous-default protection, leaf coercions and right actions.
- src/Init/Notation.lean and Init/Prelude.lean: arithmetic/relation protocols, precedence, HPow/Pow/NatPow and homogeneous shift bridges.
- src/Init/Data/Nat/Bitwise/Basic.lean: shift recurrences and multiplication/division by powers of two.
- src/Init/Data/Int/Basic.lean: signed magnitude and exponent parity for Int.pow.
- src/Init/Data/{UInt,SInt}/Basic.lean: word shifts and Nat-exponent Pow dictionaries.
- src/runtime/object.cpp: lean_nat_shiftl/lean_nat_big_shiftr reject unallocatable positive left shifts, preserve zero, and return zero for oversized right counts.
- tests/elab/{binrel,binrelmacros,binrel_binop,postponeBinRelIssue,bitwise}.lean and tests/compile/nat_shiftr.lean; binop_binrel_perf_issue.lean motivates bounded read-only probes without a second unifier.

Upstream Apache-2.0 attribution is recorded in adapted modules and THIRD_PARTY_NOTICES.md. Selected PSCV0 uses direct Coe, a closed notation table and bounded deterministic search; it does not import Lean's complete macro/coercion host.

## Shared architecture

1. Syntax preserves unary/binary/right-action/relation intent, resolved operator name, original spelling and span. Scope, recursion analysis and both source printers retain it. Ordinary explicit calls retain ordinary application semantics.
2. Prepare typed leaves exactly once in one evolving context. A right-action exponent and nested relation infer independently. Light progress uses the existing scoped synthetic queue without default-instance fallback.
3. Compare known operand types plus the expected type (only for arithmetic), with read-only conversion and discarded direct-coercion probes. Incomparable types use ordinary heterogeneous application.
4. Insert coercions at leaves. Homogeneous instance availability guards binary promotion; selected heterogeneous defaults protect unknown operands. No speculative dictionary/context leaks into the accepted result.
5. Assemble with the existing ordered application/default/implicit engine. Conditions and Prop-to-Bool conversion now allocate ordinary checked Decidable constraints on the same queue. No alternate solver, conditional lookup or target-dependent elaboration.

The final Standard selection reuses existing checked HPow/Pow/NatPow/shift classes and bridges, adds checked one-field word dictionaries, and supplies a checked Nat-to-Int direct coercion. Target-dependent word dictionaries enter runtime only with explicit 32/64-bit profile; logical identity stays abstract. Frozen asset boundaries remain unchanged.

The longest registered adjacent spelling wins, including three-symbol shifts and <->. Whitespace cannot manufacture an operator. The independent exhaustive notation ledger now records the operator inference protocol along with precedence, associativity and target.

## Runtime

Three typed operations complete selected Nat shifts and Int power. JS/TS use exact BigInt operators; Rust uses safe BigUint/BigInt with checked narrowing after oversized-right guards. Wasm shifts immutable GC natural limbs with whole-limb displacement and one carry pass; no exponent-sized recursion or intermediate power allocation. Int power shares existing exponentiation by squaring over the magnitude, with the sign determined by parity. Existing word primitives retain wrap/shift semantics and explicit target widths. There is no new interior linear memory or trusted assumption.

## Focused qualification

Twenty shared observations extend the current JS/TS/Rust/GC Wasm/Wasmtime pipeline: nested/reversed/expected-type promotions, unary promotion, mixed comparison, proposition Boolean conversion, right-associative power, signed power, multi-limb shifts, huge right counts and zero-left counts, fixed words, heterogeneous result types and heterogeneous defaults. Native Lean guards and symbolic rfl checks establish the reference observations and leaf-coercion shape. Existing syntax-chain refusals and complete subsystem regressions remain required.

Strict declaration and surface hashes must be selected only after independent agreement at both CI boundaries. Tests do not establish a global semantics-preservation theorem. General coercion closure, Float transcendental power and C5 source reconstruction are not silently added by this slice.

Int equality additionally selects the pinned Int.instDecidableEq/Int.decEq definitions, exact-signature intEq lowering and three true/false signed observations. Strict dependency presence, checked closure and both registry hashes must be verified before this capability is qualified. Prior research native38810569497 passed source/solver gates but stopped at this missing decision before platform backend emission; independent replay38810569357 passed.
