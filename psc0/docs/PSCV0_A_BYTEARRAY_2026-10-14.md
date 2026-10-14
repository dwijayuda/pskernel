# PSC0 Phase A — Lean 4.35.0 ByteArray logical baseline

## 15 October 2026 — accepted indexed API, next toList candidate

The verified indexed ByteArray source, dictionaries, erasure and target
executions passed at `05d4c1cec39bf7cb93089041982e60f802563c5d`,
[Linux 38607736899](https://github.com/dwijayuda/pskernel/actions/runs/38607736899)
(all 27 steps). The previous strict snapshot was intentionally updated
to the CI-measured FNV and SHA-256 values. Nat indexing and its
lawfulness evidence are qualified; USize indexing is not.

The next candidate adds `ByteArray.toList : ByteArray → List UInt8`,
implemented through checked `Array.toList` of the logical `data`
field. It conserves index order. The corresponding pinned Lean function
iterates and reverses its accumulator; general equivalence still
requires a separate theorem, and native/cross-target tests are bounded
observations. Do not claim native packed-buffer optimization.
This new extension is pending full independent CI qualification.

## 15 October 2026 — checked indexed ByteArray candidate

The **fully qualified** existing logical collection baseline is commit
`4ae7631c18ef9062f8a552015624b6af2d2a341d`,
[Linux 38606086921](https://github.com/dwijayuda/pskernel/actions/runs/38606086921).

The next candidate adds the pinned native `ByteArray.get` and
`ByteArray.set` checked signatures. Their `i < bytes.size` proof
is passed to the same checked underlying Array getter/setter, with
definitional equality to `i < bytes.data.size`. The proof is
kernel-admitted and disappears only through typed erasure. The true
`GetElem ByteArray Nat UInt8 (...)` dictionary, selected `GetElem?`
and `LawfulGetElem` dictionaries use the same generic class and
decision-law implementation as Array and List. Instance registration,
reducibility metadata and panic semantics are explicit.

Qualification requires source/kernel replay, exact pinned signatures,
strict independently observed FNV/SHA fingerprints, successful and
out-of-range optional indexing, proof-directed access and update,
JS/TS/Rust runtime observations, Wasm GC/components/Wasmtime and
the ordinary resource gates. This is a **candidate**, not a claim
of acceptance until all gates pass.

## Official reference

Pinned `leanprover/lean4` release `v4.35.0`, source commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
Study `src/Init/Prelude.lean` (ByteArray structure, empty, push, size)
and `src/Init/Data/ByteArray/Basic.lean` (array API and typed bounds).
Original Microsoft/Lean contributor Apache-2.0 notices remain in
`psc0/THIRD_PARTY_NOTICES.md`.

## Selected architecture and invariant

Lean's **logical** `ByteArray` is a distinct one-field structure:
`data : Array UInt8`. Native Lean provides an optimized packed-byte
representation via extern functions. Those externs do not create a
different type theory, but they are an implementation optimization
whose correspondence to the logical model must be validated.

PSC0 adds the checked type, constructor, dependent recursor and field
projection in native portable `.lean`. Selected `emptyWithCapacity`,
`empty`, `push` and `size` are ordinary checked definitions using
the existing generic Array operations. The capacity argument is an
allocation hint only; logical contents and size are independent of it.
Preserve the pinned `implicit_reducible` statuses for the four
programming methods. Never add axioms or special-case parsing.

Initially erase ByteArray as its actual one-field logical structure,
not as an unchecked cast of Array UInt8. Backend-specific packed-buffer
optimizations are a separate future choice and are **not** claimed by
this milestone. The existing type/structure lowering must work in
JavaScript, TypeScript, Rust and Wasm GC without a new runtime opcode.

## Minimal qualification

Test empty length, two pushes and one retrieved byte against independent
pinned native Lean and common-source executable JS/TS/Rust/Wasm.
Require regenerated constructor/recursor/iota checks by the official
kernel, strict Standard FNV/SHA, typed ABI validation and all Linux CI.
Failures must keep the last fully green executable as the qualified
baseline.

This is a **candidate**, not a completed release capability, until
those gates pass. More extensive ByteArray APIs, alternative packed
representation and performance remain separate M2+A/Phase A work.
No `pskernel-core`, self-hosting or C5 development.
