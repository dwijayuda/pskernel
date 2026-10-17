# Checked Int conversion for selected Standard

## Pinned reference and comparison

Before implementation, inspected stable Lean 4.35.0
[Init/Data/Int/Basic.lean](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/Int/Basic.lean)
and [int_to_nat_bug.lean](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/tests/elab/int_to_nat_bug.lean).
The complete RC4-to-stable comparison confirms these files are unchanged.
Lean defines Int with ofNat/negSucc; toNat returns n for ofNat n and zero
for negSucc, and has implicit_reducible status. The upstream regression
preserves a positive value at the 32-bit unsigned boundary.

PSC0 already has arbitrary-precision signed runtime values and arithmetic.
Its selected logical environment still declared Int and its constructors as
assumptions, and had no checked toNat. Std.Format's signed indentation needs
this conversion; machine-word truncation would be incorrect.

## Design and invariants

Replace three assumptions with the actual inductive and constructors.
Add the real recursor and checked toNat definition, preserving its native
reducibility status. The official kernel independently reconstructs and checks
the inductive/recursor and admits the conversion. No new axiom is introduced.

Keep the logical model outside the executable declaration catalogue, as already
done for Array. A typed intToNat intrinsic has signature Int -> Nat:
ECMAScript clamps one evaluated BigInt; Rust uses BigInt.to_biguint or zero;
GC Wasm returns zero for a negative sign and the existing magnitude otherwise.
No host-width narrowing, string conversion, linear memory, or unchecked cast.
All targets keep arbitrary precision. First-class application uses the existing
typed application completion machinery.

The primitive audit records both portable and native conversion signatures
and labels the runtime override separately from kernel admission.
This does not claim a formal backend equivalence theorem or arbitrary Int.rec
runtime elimination support.

## Qualification

Prepared four shared observations: negative and positive values beyond 64 bits,
zero and first-class conversion at 4294967295. The independent official Lean
oracle proves the corresponding structural equations. These run through the
existing compact native/kernel/IR and all-target gates. Full qualification and
the changed Standard digest remain pending.

At this draft boundary, the logical roster should grow from 313 to 315
declarations with classes/instances unchanged. Verify the observed inventory;
do not treat this expectation as evidence. Profile /54.

## Reviewed Standard change

Linux [38438411914](https://github.com/dwijayuda/pskernel/actions/runs/38438411914)
at `996635e5409956f2369ae5f0c5027a8dd3ffe736` compiled the full native closure
and independent structural equations, then passed signature/reducibility audit.
The intentional three-assumption replacement plus recursor/toNat addition reports
FNV `fnv1a64:5885345544530235680` and SHA-256
`sha256:739169c3254d48e26471fd8be9bda480341a21788dcf67d683c5982e996ac634`.
Both strict values are reviewed and pinned; official prelude admission and full
cross-target qualification follow in the next run.

## Qualification complete

Executable `80c73a473808434f2b945bf97ff751f1201e6f3a`;
[green Linux 38439035494](https://github.com/dwijayuda/pskernel/actions/runs/38439035494).
**302 shared runtime observations**, four panic contracts, **190 portable /
198 native modules**, profile `pscv0-v7-native-bounded/54`.
Official **Lean 4.35.0** at `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`;
independent oracle, semantic/refusal and graph gates, strict IR,
JS/TS/Rust, V8/Wasmtime GC, WIT/WAT/component/ABI, project and existing performance gates passed.
These measurements do not establish performance parity.

Standard: **315 declarations /18 classes /54 instances**, canonical v2:
FNV `fnv1a64:5885345544530235680`;
SHA `sha256:739169c3254d48e26471fd8be9bda480341a21788dcf67d683c5982e996ac634`.
Character and Unicode string quoting use checked definitions; native evaluation
provides independent comparison because upstream String.Internal.append is
kernel-opaque. Int/ofNat/negSucc now have actual checked datatype declarations,
with Int.rec and checked Int.toNat; the typed runtime override clamps negatives
without narrowing positive integers. Direct and first-class observations pass.
Historical RC4 receipts retain their original identities.

Full M2+A is **not complete**. Next: faithful Std.Format/Repr and remaining A/M2.
