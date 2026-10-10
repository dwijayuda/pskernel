# PSCV P1-F — qualified concrete instance witnesses, not a class dependency proof

**Qualified P1-F source:** `d8a8e2a9b5d4ab2294316af74671a02af1815ce0`. [Run 38056463990](https://github.com/dwijayuda/pskernel/actions/runs/38056463990), attempt 1, all four jobs passed: Linux Node22/Node26, Windows Node26 unit and negative review, plus real pinned Lean 4.35.0-rc3 synthesis/typechecking. Seven selected terms: `instAddNat`, `instMulNat`, `instSubNat`, `Int.instAdd`, `instDecidableEqNat`, `instDecidableEqBool`, `instAppendString`. Non-authoritative evidence SHA256 `215f6e60a0319320690035dbbfa34deb812c53466f53f6dd8892daa99757cc29`; [artifact 11670981656](https://github.com/dwijayuda/pskernel/actions/runs/38056463990/artifacts/11670981656), ZIP SHA256 `fb38e67c7eb9cdf9dd26ba17eb0b7f910f35c42c4641aed25e4d3e47e777237a`.

No generic→concrete dependency graph, class/basis/source-line proof, scoped tie resolution, backend equivalence or closed normative PSCV registry is claimed. The 191 remaining required snapshot IDs are **still unresolved**. Compiler/kernel/seed and production PSCV refusal are unchanged.



The P1-E Lean 4.35.0-rc3 `#synth` results were generic for `HAdd`,
`HMul`, `HSub` and `BEq`. A generic implementation name does not show
which concrete `Add Nat`, `Mul Nat`, `Sub Nat`, `DecidableEq Nat`
or `DecidableEq Bool` declaration Lean selected.

This follow-up checks exactly those concrete typeclasses, as well as
`Add Int` and `Append String`, under the actual pinned ambient
`PSCVL.Policy` imported environment. The source is a fixed suite of
`#synth` and `inferInstance` examples, with no additional imports or
registrations allowed by the review validator.

The output is a *candidate layer*: observed concrete terms for typeclass
goals suggested by the previous generic terms. Actual dependency edges,
kernel-level replay, the typed source instance declarations, scope,
priority and equal-tie selection, and precise source blob/line locators
must still be verified before any normative `std.*` ID can be approved.
A source row appearing in these samples is not counted as a resolved ID.

P1 still has **191 unresolved** of 194 required snapshot IDs, the
complete ordered allowed Standard/verification effect registry is absent,
and the protected PSCV-CERT-v1 gate stays closed. P2–P5 remain stagewise
under `docs/platform/PSCV_P1_TO_P5_SOUND_GATES.md`. No kernel, compiler,
bootstrap source, npm runtime, chosen native provider or seed change.
