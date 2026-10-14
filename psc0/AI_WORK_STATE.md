# PSCV0 v7 — AI work state

## 15 October — checked ByteArray indexed API fully qualified

Commit `05d4c1cec39bf7cb93089041982e60f802563c5d` passed all 27
[Linux CI 38607736899](https://github.com/dwijayuda/pskernel/actions/runs/38607736899)
steps. The approved selected Standard fingerprint is FNV
`fnv1a64:18073559988743207974`, SHA-256
`sha256:bbf06e5a2091c8cb1af14a0b7c35177b9ce029aea402e853072cccc1d43abfac`.
Native Lean checked the proof-indexed `ByteArray.get`/`set`, genuine
`GetElem ByteArray Nat UInt8`/`GetElem?`/`LawfulGetElem` dictionaries,
registered instances and metadata. Independent native checks and shared
JS/TypeScript/Rust/Wasm executions (including Wasmtime) passed. It is the
last fully qualified executable checkpoint until a newer run succeeds.

**Next checked candidate:** the logical `ByteArray.toList` conversion
reuses the existing checked Array/List representation and has bounded
native / cross-target observations. It remains pending full kernel,
registry, erasure, runtime and performance qualification. The logical
construction alone is not a proof of general equivalence with Lean's
native optimized toList loop.

Outstanding M2+A: further pinned collection APIs; Float/Float32 F1–F4
without unapproved `Classical.choice`; explicit USize/ISize profiles;
selected deriving corner cases; remaining instance/search fidelity;
a reproducible complete Standard module/notation/effect/assumption
manifest. No pskernel-core, self-hosting or C5 has been started.

## 15 October — ByteArray cross-target green and indexed API next

**Last fully qualified executable:** `4ae7631c18ef9062f8a552015624b6af2d2a341d`;
[Linux CI 38606086921](https://github.com/dwijayuda/pskernel/actions/runs/38606086921)
passed all 27 steps, including official Lean 4.35.0 checking, both strict
Standard fingerprints, native ByteArray oracles, source and negative
conformance, JS/TS/Rust runtime, Wasm GC/components/Wasmtime and
resource measurements. The earlier Standard drift and JS top-level
initialization ordering were corrected without bypassing checks; the
shared Wasm trap oracle now preserves the checked UInt8 result type.

**New pending candidate:** native proof-indexed `ByteArray.get` and
`ByteArray.set` plus real checked `GetElem`, `GetElem?` and
`LawfulGetElem` instances and minimal independent source/runtime cases.
The existing checked Array and index-lawfulness machinery are reused.
This new slice is **not qualified** until its *own* strict registry
and full cross-target CI run succeed; new fingerprints must be measured,
not inferred from the previous green. Continue other M2+A tasks only
while retaining the green baseline and strict assumptions boundary.

## 14 October — ByteArray checked read/write, equality and defaults candidate

Pinned Lean 4.35.0 `Init/Data/ByteArray/Basic.lean` declares
`ByteArray.get!`, `set!`, `isEmpty`, `beq` and an
`Inhabited ByteArray` instance. A new portable native
`StandardByteArrayCollection.lean` maps these through the already
checked `Array.get!Internal`, `Array.setIfInBounds`,
`Array.toList`/`List.beq`, `Nat.beq` and the ordinary
Inhabited dictionary. The `BEq` instance compares canonical bytes,
not host object identity. Ordinary checked declarations and explicit
instance indexes preserve class ownership; there is no new primitive,
unchecked cast, duplicate array datatype, or kernel assumption.

Seven native oracle checks and eight common-source JS/TS/Rust/Wasm
observations cover successful byte reads and replacements, preserved
contents after out-of-bounds writes, empty/nonempty tests, defaults,
and equal/different byte sequences. A fifth negative runtime panic
contract checks `get!` out of bounds. **Candidate only:**
do not promote until the native source and kernel audits, independent
FNV/SHA drift measurements and every existing runtime/Wasm/Wasmtime
gate pass. Generalized `GetElem` proof and optional-index APIs,
packed-buffer optimization and remaining ByteArray methods are
separate Phase A obligations.

## 14 October — ByteArray baseline fully qualified

Commit `a92f5ad8a0670d0077ec47080d75446675ab90fc`
passed [native CI 38596014627](https://github.com/dwijayuda/pskernel/actions/runs/38596014627).
Selected Standard: 1,803 declarations, 25 classes, 221 instances,
629 JS/TypeScript/Rust common-source observations, 175 native
integer oracle values, seven strict IR refusals and a separate
ByteArray empty/push/size/data native oracle. Wasm GC and Wasmtime
component/host, source admission, recursor metadata, strict digest
and existing performance checks passed. FNV
`fnv1a64:3178543072286617803`, SHA-256
`sha256:6d0c19b50e0074b4cd59361c25a4d3c3630da49855c39e6615994b9da73ebe48`.
The packed-byte runtime optimization is not claimed; ByteArray is
still erased as a distinct checked one-field structure. M2+A,
Float F1-F4, platform words and full Phase A manifest remain open.


## 14 October — native ByteArray structure and basic APIs (candidate)

Pinned `Init/Prelude.lean` and `Init/Data/ByteArray/Basic.lean` in
Lean 4.35.0 `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`
define ByteArray as a separate one-field structure holding
`Array UInt8`, with an externally optimized packed byte buffer.
The new native portable `StandardByteArray.lean` models its real
inductive constructor/recursor, `data` projection, checked
`emptyWithCapacity`, `empty`, `push` and `size`. It reuses
the existing selected Array logic, including capacity being only an
allocation hint, rather than adding a second array primitive.
No axiom, unchecked cast, self-hosting or pskernel-core code.

Three source/target observations and a native three-case oracle
cover empty size, two pushes and retrieved byte; see
`docs/PSCV0_A_BYTEARRAY_2026-10-14.md`. **Not yet qualified.**
Keep native signature/reducibility, constructor/recursor metadata,
strict FNV/SHA, source erasure, JS/TS/Rust/Wasm GC/Wasmtime and
performance gates unchanged. Packed-byte backend optimization is
a separate runtime fidelity/performance qualification, not assumed.

## 14 October — Lean Sum two-constructor baseline qualified

Commit `e055b2e5340eab08d4acc569355e2e022b023e9e` passed
[Linux CI 38594035519](https://github.com/dwijayuda/pskernel/actions/runs/38594035519).
Selected Standard: **1,795 declarations / 25 classes / 221 instances**;
626 shared JS/TypeScript/Rust observations and 2 independent
native Sum constructor/match oracle cases. Wasm GC, Wasmtime
component/host and all mandatory native kernel and syntax checks
passed. Lean-compatible `Sum` preserves its independent `u/v`
and recursor `w` universes. FNV
`fnv1a64:14927995082305765806`, SHA
`sha256:f77eb6d54d68a9f3036d0d69213f5f45f5d0e1f688e93f347c97466f9226ae53`.
This is bounded evidence, not full M2+A/Phase A completion.


## 14 October — native Lean 4.35 Sum type/recursor candidate (not yet qualified)

Official Lean 4.35.0 `Init/Core.lean`, pinned
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, defines
`Sum (α : Type u) (β : Type v)` as a two-constructor disjoint union.
`StandardSum.lean` adds the actual kernel inductive, `Sum.inl`,
`Sum.inr` and dependent `Sum.rec`, retaining the independent
element universes, motive universe, exact constructor indices and
two one-field minor premises. Source uses the ordinary `match` and
typed erasure paths already qualified for Option/Except rather than
inventing a new syntax or target-specific union representation.
See `docs/PSCV0_A_SUM_CORE_2026-10-14.md`.

Two native Lean and shared JS/TS/Rust/Wasm source observations cover
both constructors and match branches. **Candidate only** until the
official-kernel constructor/recursor/iota replay, native signature
audit, independently measured strict registry fingerprints and full
target/component CI pass. No new axioms, pskernel-core, C5 or
self-hosting. Float F1-F4, platform-sized integers, ByteArray and the
complete Phase A manifest still remain outside this narrow slice.

## 14 October — unsigned Nat saturation qualified

Commit `893e323dda53a741f78c6de707b12ac05e42587b`, full
[Linux run 38592521197](https://github.com/dwijayuda/pskernel/actions/runs/38592521197),
passed kernel checks, source/asset audits, direct JS/TypeScript/Rust,
Wasm GC/Wasmtime and performance gates. Selected Standard:
1,791 declarations, 25 classes and 221 instances. The same 624
shared runtime observations passed across native targets and 175
native Lean scalar oracle cases plus seven IR negative checks passed.
`UInt8/16/32/64.ofNatClamp` saturate to the largest representable
value; deprecated `ofNatTruncate` is the same clamp, **not** a
wrapping alias. FNV `fnv1a64:10558131214179396941`;
SHA-256 `sha256:5385a2bab77090b84ce8c7483be0c88726ed8a9382b739078d741e07f7d6ac50`.
No trust expansion or change to the native .lean-only policy.


## 14 October — native unsigned saturating conversions candidate

Source study: pinned official Lean 4.35.0
`Init/Data/UInt/BasicAux.lean` and `Init/Data/BitVec/BasicAux.lean`,
commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
Unlike `UIntN.ofNat` (wrapping), `UIntN.ofNatClamp` saturates:
`n < 2^width ? n : (2^width - 1)`. In the same pinned version,
`UIntN.ofNatTruncate` is a deprecated synonym for the clamp,
not the ordinary wrapping conversion.

The selected candidate builds eight checked `.lean` definitions for
four fixed unsigned widths using existing `Nat.lt`/`Nat.decLt`,
`ite` and `UIntN.ofNat`. Sixteen pinned native Lean and
common-source JS/TypeScript/Rust/Wasm observations cover zero,
largest representable value, first overflowing Nat and the alias.
No new axiom, unchecked runtime operation, compiler backend or
platform-sized assumption. **Pending** fresh official kernel replay,
native metadata audit, independent strict FNV/SHA snapshot measurement
and all full Linux runtime gates before qualification.

## 14 October — unsigned power and wrapping-ofInt fully qualified

Commit `b28ccbe8ddf0fc6528bbae04e50a2f485373121b` passed
[Linux 38590570467](https://github.com/dwijayuda/pskernel/actions/runs/38590570467).
The selected Standard contains 1,783 declarations, 25 classes and
221 instances; 608 shared JS/TS/Rust runtime observations and
159 independent native fixed-width reference cases passed, alongside
seven strict IR refusals, Wasm GC and Wasmtime component gates.
Both checked power-recursion and Int-wrapping builders are shared
between the four signed and four unsigned widths. Frozen FNV
`fnv1a64:16486742924065107304` and SHA-256
`sha256:c991c6c6f80bc9575c0d1a9dcaf89816380469464fd9424b063aec7bbeeaf2ed`.
This does not complete M2+A, Float F1-F4, USize/ISize or the
comprehensive Phase A/standard manifest. No pskernel-core or self-hosting.


## 14 October — unsigned power and Int wrapping source candidate (not qualified)

Official Lean 4.35.0 `Init/Data/UInt/Basic.lean` defines
`UInt8/16/32/64.pow` by primitive recursion on Nat and
`UInt8/16/32/64.ofInt` by nonnegative remainder modulo `2^width`.
The native-only `.lean` closure adds the four UInt powers and four
unsigned `ofInt` constructors without a compiler primitive or
new foundation assumption. Reuse exactly the already checked Core
builders for the corresponding signed word methods:
`psStandardFixedWidthPower` and `psStandardWrappingOfIntDeclaration`.
The signed declarations retain identical ordered binder/recursor terms
and their original reducibility status.

Twenty-one independent native Lean reference values and twenty-one
common-source JS/TS/Rust/Wasm vectors cover exponent zero, modulo-width
overflow, negative Int wrapping and 64-bit boundaries. Structural
recursion uses the same typed erasure as the qualified signed methods.

**Candidate only:** no new Standard fingerprints are guessed. Independently
measure the strict FNV/SHA refusal, retain official kernel/source audits,
then pass the complete native, JS/TS/Rust and Wasmtime component workflow.
This does not complete Phase A, Float F1-F4, USize/ISize or the v7
assurance scope. No pskernel-core, self-hosting or C5.

## 14 October — unsigned fixed-width LT/LE qualified

Commit `2021d7cd673622aacaf528b1161654393403fa4d` passed
[Linux 38588137709](https://github.com/dwijayuda/pskernel/actions/runs/38588137709):
1,775 checked declarations, 25 classes, 221 registered instances,
587 shared target runtime observations, 138 pinned native word oracle
values and seven strict typed-IR refusals. Checked `UIntN.lt/le`,
`UIntN.decLt/decLe` and explicit LT/LE dictionary registrations
preserve the unsigned bit-carrier order at every fixed width, with
no additional axiom. FNV `fnv1a64:8114939059249220600`, SHA-256
`sha256:fd5b96380ccec059f57a3210374cad31778d93d720be913508ddfb4f1edb12f8`.
This is bounded runtime differential conformance, not compiler-wide
semantic preservation.


## 14 October — unsigned machine comparison source/decision candidate

Pinned official Lean 4.35.0 commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`:
`Init/Prelude.lean` defines `UInt8.lt/le/decLt/decLe`, and
`Init/Data/UInt/Basic.lean` defines the corresponding 16/32/64-bit
families over `BitVec`. The unsigned carrier `UIntN.toNat` preserves
their unsigned order; the existing checked Nat comparisons and
`Nat.decLt/decLe` provide their portable propositions/decisions.

`StandardUnsignedOrder.lean` stages 8 checked relation declarations,
8 checked deciders, 8 ordinary LT/LE dictionary definitions and explicit
class/Decidable registrations, with no new axiom, trust permission or
target-specific primitive. The native oracle and the common-source
JS/TypeScript/Rust/Wasm observations exercise 16 unsigned equal/extreme
and reversed-order boundaries, including the full UInt64 range.
This is a coherent native `.lean` feature family, not a new backend.

**Not qualified:** independently capture any actual strict FNV/SHA
registry drift, preserve signature/reducibility and native-kernel replay,
then require every Linux/source/target/Wasmtime gate to pass before
promotion. M2+A, F1-F4 Float, explicit platform-width ABI and full Phase A
manifest/library closure remain open. No pskernel-core, self-hosting or C5.

## 14 October — Bool-to-fixed-width stage fully qualified

Commit `aab53c217d244884c39a13436db7fef5ed1815eb` passed
[Linux 38586225475](https://github.com/dwijayuda/pskernel/actions/runs/38586225475):
1,751 declarations, 25 classes, 205 instances, 571 common-source
runtime observations across JS, TS7 and Rust, official kernel checks,
V8/Wasmtime GC component and linked-project qualification. The checked
Bool recursor supplies all eight fixed-width conversions with no new
assumptions; shared observation marshalling preserves unsigned scalars.
Native signed oracle: 122 reference cases and seven strict typed-IR
refusals. The result is bounded and does not imply M2+A completion.


## 14 October — signed M2+A order/numeric fully qualified

Executable commit `930e48d330d5d67da0911eba083a83aa730ef70d`,
[Linux run 38583446893](https://github.com/dwijayuda/pskernel/actions/runs/38583446893)
passed all native/kernel, strict-source, JSON/WIT/WAT/Wasm GC component,
V8/Wasmtime, TypeScript 7, direct JS, Rust, and performance CI steps.
**1,743 declarations, 25 classes, 205 instances; 555 shared runtime
observations; 106 native Lean signed oracle values and seven negative
typed-IR checks.** Snapshot FNV `fnv1a64:4732508156583495274`;
SHA-256 `sha256:4b7d09a378f650f9b5a3fc0ecf28553331380a3f7dfde07a6980d0fce2608222`.
Native Lean metadata audit requalified all signed order deciders as
`instance_reducible` and signed size/extrema abbreviations as
`reducible`. The changed root families and cross-target observations
passed without adding any axioms, pskernel-core or self-hosting.

## 14 October — native Bool-to-eight-fixed-word conversions (candidate only)

The new portable `.lean` module composes exactly the native Lean
4.35.0 `Bool.toUInt8/16/32/64` and `Bool.toInt8/16/32/64`
true/false equations using the already checked Bool.rec and word
constructors. Eight ordinary definitions enter selected Standard and
the shared executable prelude; sixteen native Lean/runtime observations
test both possible inputs for every target width. No new primitive,
axiom, backend-specific operator, source edition or target-size promise.

**Unqualified until:** first compile and official metadata/source audit,
independently observe strict FNV/SHA registry drift, pin unchanged guard
values, and pass the full existing multi-target Linux pipeline. Float
F1-F4, explicit USize/ISize profiles and full Phase A manifest/libraries
remain separate exit gates.


## 14 October — native signed numeric boundaries and power candidate

Study: Lean 4.35.0 pinned `Init/Data/SInt/Basic.lean`.
The existing checked `IntN.ofNat`, `IntN.mul` and `Nat.rec`
provide one ordinary portable Lean construction for four widths'
`size`, `minValue`, `maxValue` and `pow`. Power follows the
actual upstream recursion equations, and minimum and maximum are
two's-complement residues at the sign bit boundary. This adds sixteen
portable Core declarations in one new native `.lean` module rather
than backend-specific numeric operator cases. Runtime support reuses
the existing target-neutral IR, and twenty signed-boundary/power
vectors are independently specified by native Lean 4.35.0 and the
shared runtime observations.

**Candidate, not qualified:** preserve the strict FNV/SHA guards
until CI independently measures the new selected Standard, then
fully requalify JS/TS/Rust/Wasm GC/Wasmtime and official native
replay. If a structural Nat recursion cannot be lowered faithfully,
do not replace it with a guessed primitive or weaken source checks.
This does not activate platform-sized integers or float F1-F4, and
does not start pskernel-core, compiler self-hosting or C5.


## 14 October — signed < / ≤ / LT/LE and native deciders (qualification pending)

Pinned Lean 4.35.0 `SInt/Basic.lean` defines each fixed-width
`IntN.lt/le` using `BitVec.slt/sle`. `BitVec.slt/sle` compare the
two's-complement mathematical values. The native portable
`StandardSignedOrder.lean` implements their exact finite-width ordering
using sign-biased canonical Nat carriers and existing kernel-checked
`Nat.lt/le/decLt/decLe`. It adds per-width checked `lt/le` propositions,
`decLt/decLe` decisions and ordinary `LT/LE` dictionaries, with
explicit class and Decidable registration. No new axiom, runtime
primitive, parser-specific dispatch, pskernel-core, self-hosting or C5.
The 16 differential native Lean and shared-target observations cover
minimum/maximum, equal, negative/positive and reversed-order boundaries.

**Candidate only.** Confirm the exact checked native signatures, strict
independently observed Standard fingerprints, source/IR erasure and
full JS/TS/Rust/Wasm GC/Wasmtime CI before promoting this scope.
Native class relations and actual source operation semantics remain
subject to qualification; backend preservation remains bounded evidence.
F1–F4 Float, portable size, general Phase A manifest, other M2 work
remain incomplete.

## 14 October — signed abs stage qualified

Commit `f6d70dfbb256c1ca19a402eb75c8d28b9d568a74` passed
[Linux CI 38578021600](https://github.com/dwijayuda/pskernel/actions/runs/38578021600).
Qualified Standard: 1,703 declarations, 23 classes, 189 instances;
519 shared runtime observations in JS/strict TS/Rust, native 70 SInt
values plus seven typed IR refusals, Wasm GC and Wasmtime component,
all ordinary Linux steps. Measured FNV
`fnv1a64:8243444543599524808`, SHA-256
`sha256:bcd5911445946ad2960d1ac35861dbb009e577985e51679db83ec82c940361b3`.
The four checked `IntN.abs` definitions preserve minimum signed
wraparound; this is bounded, not whole-compiler proof evidence.


## 14 October — checked signed fixed-width abs candidate (qualification pending)

Pinned Lean 4.35.0 `BitVec.abs` is sign-conditional fixed-width
negation; `Int8/16/32/64.abs` preserve the minimum signed value.
The new native portable `.lean` module composes the existing checked
unsigned carriers, `Nat.lt`/`Nat.decLt`, `ite` and `IntN.neg`
and registers four ordinary definitions in the selected Standard and
runtime support. No new target primitive, axiom, `pskernel-core`,
self-hosting or C5 code. Twelve signed-extrema, -3, positive-boundary
values are checked against the independent pinned native Lean oracle
and by common-source JS/TypeScript/Rust/Wasm observations.

**Not yet qualified:** Require actual compiled drift values for the FNV/SHA
registry guards and complete green Linux CI before claiming this stage
as implemented and released. Native signed comparison classes and
deciders, Float F1-F4, platform size and the Phase A manifest remain open.

## 14 October — signed Nat clamps qualified

Commit `e0a86361b53b0b2688e26ab6aeae20f4a1a7c560`
passed [Linux CI 38576409867](https://github.com/dwijayuda/pskernel/actions/runs/38576409867):
1,699 declarations / 23 classes / 189 instances, 507 JS/direct-JS/TS/Rust
shared observations, native oracle 58 signed values plus seven strict
IR refusals, qualified Wasm GC/Wasmtime component and host. The independently
measured strict registry values were FNV
`fnv1a64:9945284948184117163` and SHA-256
`sha256:fb98de4265c1206139fd2859f317de035156391bc926c0ee3f8f3b01147b9056`.
This evidence qualifies the four signed `toNatClampNeg` methods within
the declared executable scope, not M2+A or full v7.


## 14 October — four checked signed Nat clamping methods (qualification pending)

An M2+A native portable `.lean` stage implements Lean 4.35.0
`Int8/16/32/64.toNatClampNeg`, using exactly the already selected
kernel-checked `IntN.toInt` and `Int.toNat` bodies. Twelve values
at the signed limits, zero and minus one are covered both in the
pinned native Lean oracle and in shared JS/TS/Rust/Wasm observations.
There is no new trusted assumption, extra runtime primitive, host-width
dependency, `pskernel-core`, self-hosting or C5 feature.

**Pending:** Native official-kernel qualification, independently observed
FNV/SHA Standard fingerprint drift and the complete Linux backend gates.
Do not claim this candidate qualified until the new exact digests are
measured and full CI passes. The preceding selected signed-shift stage
passed all Linux gates at `86faead` in
[Actions 38569444828](https://github.com/dwijayuda/pskernel/actions/runs/38569444828).
Signed comparisons, Float F1–F4, portable target-sized integer profiles and
comprehensive Phase A exit remain open.


## 14 October — signed shift candidate; ofInt now qualified

The four wrapping `Int8/16/32/64.ofInt` declarations are **fully green** at commit `75b8787584339f3ea54d5b673aa3211f37589329`, [Linux 38567308280](https://github.com/dwijayuda/pskernel/actions/runs/38567308280). Selected Standard 1,687 declarations, 23 classes, 189 instances; independently measured FNV `fnv1a64:18408272372580449619` and SHA-256 `sha256:52a6343fe02345259225f17386182d73cf452bb6df5b44987e79b80468aee543`; 479 JS/TS/Rust shared observations, Wasm GC and Wasmtime component host qualified. Pinned native Lean signed oracle 30 values, seven typed-IR negative checks.

**New candidate, NOT yet qualified:** Int8/16/32/64.shiftLeft/shiftRight via constructive fixed-width Nat arithmetic that implements the pinned signed shift count `b.toBitVec.smod width` using bit-pattern modulo (width divides 2^width), modulo-width left shift, and arithmetic right shift with high-bit sign fill. Generic typed signed machine shifts already exist in JS/Rust/Wasm and are enabled in signed erasure; 16 official native Lean reference cases and 16 source/executable all-target vectors were added. Any snapshot drift must be independently observed, the root causes of any failures resolved, and full CI green before claiming support. No new axioms, extra TCB, host-width assumption, pskernel-core, self-hosting or C5.

## 14 October — M2+A signed ofInt candidate (qualification pending)

Last fully green branch HEAD is `b4f52e25973d1c9e5623ed8f247757b739a9939d`, [Linux 38564371025](https://github.com/dwijayuda/pskernel/actions/runs/38564371025): strict selected Standard 1,683 declarations / 23 classes / 189 instances, independently checked FNV `fnv1a64:12853239104520417295` and SHA-256 `sha256:7b6a29baea2279dc88dd94de1635937a23befd79830330874daeb5fdad778c43`; 467 common-source runtime observations through JS/TS/Rust, Wasm GC and Wasmtime qualification passed. The preceding signed `toInt` semantic drift and source-newline failures have been resolved without relaxing any guard.

**New candidate pending strict native kernel and all-target qualification:** four explicit `Int8/16/32/64.ofInt` definitions using the existing checked `Int.rec` and modular `IntN.ofNat/neg` closure, with independently expected native Lean integer-boundary oracle cases and common-source runtime comparisons. This is a proposed constructive implementation of the pinned BitVec two's-complement wrapping semantics; its open-term semantic equivalence is not yet a separately verified theorem. Do not call it qualified until strict independent source/snapshot/kernel and JS/TS/Rust/Wasm/Wasmtime checks pass. No new axioms, target-size assumptions, full C5, pskernel-core, self-hosting or trust changes. Remaining signed shifts/comparisons, Float, explicit size profiles, and Phase A exit criteria remain open.

## M2+A selected signed-to-Int snapshot — independently observed (14 October 2026)

The native Lean 4.35.0 kernel compiled all four `IntN.toInt` implementations and the source-model equality certificates at `09965258ad0fb0c206fe7ea7a0386241b5078496`. The pinned semantic audit independently refused a missing `implicit_reducible` status at `6fe1a56`; commit `09965258` corrected it to the exact upstream metadata without relaxing any checks. [Linux 38563557310](https://github.com/dwijayuda/pskernel/actions/runs/38563557310) then correctly refused the previous Standard fingerprint and independently observed **FNV `fnv1a64:12853239104520417295`** and **SHA-256 `sha256:7b6a29baea2279dc88dd94de1635937a23befd79830330874daeb5fdad778c43`**. Both are now pinned unchanged in the strict registry guards. The projected selected Standard is **1,683 declarations, 23 classes, 189 ordered instances** (previously 1,679 declarations). The four definitions add no search instance or axiom and are generated from the identical native `BitVec.toInt` two's-complement formula. **Full execution qualification is still pending**: next Linux run must pass ten common-source conversion vectors and all other JS/TS/Rust/Wasm GC/Wasmtime checks. Last fully green is the earlier `fe88e7f` signed/bitvector model proof checkpoint (27 steps, 457 runtime observations). Signed shifts, comparisons, `IntN.ofInt`, Float, platform-width integers and comprehensive Phase A exit remain incomplete.



## M2+A native-checked signed toInt conversion stage — pending independent qualification

Pinned Lean 4.35.0 `BitVec.toInt` defines mathematical signed conversion
using exactly `if 2 * encodedBits < 2 ^ width then encodedBits else
encodedBits - 2 ^ width`. Four kernel-definitional-equality (`rfl`)
certificates are accepted at `fe88e7fcd388ef036f64dd03228574cf5c7efcf9`
([Linux run 38562328951](https://github.com/dwijayuda/pskernel/actions/runs/38562328951)).
`StandardSignedToInt.lean` now implements that precise formula over the
already checked unsigned `UIntN.toNat`, `Nat.mul/Nat.lt/Nat.decLt`
and `Int.ofNat/Int.sub` Core definitions using a single explicit
`ite` with native decision evidence. It adds four checked definitions,
with no external proof import, axiom, untrusted cast or new search instance,
and includes them in runtime support. Ten common-source JS/TS/Rust/Wasm
comparison vectors cover zero, sign transition, min and max for every
fixed width, including 64-bit extremes. **This integration still
requires the independently observed FNV/SHA registry update and full
Linux runtime and native-kernel requalification; it is not yet a
qualified release.** Platform-width Int and Float remain separate.


## M2+A signed dictionary candidate — independently measured strict registry (14 October 2026)

Linux [run 38556955048](https://github.com/dwijayuda/pskernel/actions/runs/38556955048)
at `a4fdce4089f544311487048c6d773e4754eff1d7` compiled
the complete new signed dictionary source, regenerated all prior
reviewed logical assets, and correctly refused the outdated Standard
hashes before source/runtime admission. The newly observed selected
Standard fingerprints are **FNV
`fnv1a64:11697716145196202262`** and **SHA-256
`sha256:47b1598e2faa1ccbe80d183aeeaaa9f1a5444d1fd2878ae40f4bbe21c3d25cc4`**.
These exact independent values are now pinned in both strict snapshot
guards; **the new stage is not yet fully qualified**. Its 36 checked
HAdd/HSub/HMul/HDiv/HMod/Neg/OfNat/BEq/Inhabited dictionary declarations
and 36 explicit registrations should extend the preceding
1,643-declaration /23-class /153-instance roster; do not assert
new counts or cross-target parity until the next full green Linux run.
The previous fully green accepted executable remains `514f537`,
[CI 38555495881](https://github.com/dwijayuda/pskernel/actions/runs/38555495881)
(448 shared observations, native Lean signed oracle, V8 GC and Wasmtime).
No new axioms, psKernel-core, self-hosting, or Float-ofBits approval.



## M2+A signed typeclasses: current authoring/qualification checkpoint (14 October 2026)

**Latest fully green native four-width signed runtime:** `514f53785b7c2aa1717d000efa5c64a08ccfe9a8`,
[Linux 38555495881](https://github.com/dwijayuda/pskernel/actions/runs/38555495881).
All 27 Linux steps passed, including the official Lean 4.35.0 oracle (22
signed bit-level vectors, seven strict IR negative checks), **448 shared
JS/strict TS/Rust runtime observations**, full signed GC Wasm/Wasmtime
component interop, WIT s8/s16/s32/s64 scalar flattening and round trips.
The selected Standard remains **1,643 declarations / 23 classes / 153
instances**, strict FNV `fnv1a64:2992617569121253333` and SHA-256
`sha256:4fc70a9fac595be03500185122459263e1a9e75141bc8fd39a680785d682e8a3`.
This is bounded differential evidence, not a formal backend-preservation proof.

**New checked generic signed typeclass stage (qualification pending):**
ordinary portable Lean dictionaries now provide HAdd/HSub/HMul/HDiv/HMod,
Neg, OfNat, BEq and Inhabited for all four pinned Int8/16/32/64 logical
wrappers, reusing precisely the general unsigned architecture and the
kernel-checked signed methods. BEq compares the canonical unsigned carrier
as Nat (sign-independent bit identity); Inhabited uses checked zero.
The stage adds **36 dictionary declarations and registrations** to the
selected environment and executable prelude, without extending the trusted
axiom set. Source fixture exercises generic operators, negative/literal
syntax, equality and defaults. **Do not mark the new selected stage qualified
until its strict fingerprint is independently observed and its full Linux
regression passes.** Signed shifts/lt/le/Int-valued conversions, ISize/USize,
Float ofBits/BEq/arithmetic/scientific and remaining Phase A manifest/library
closure remain open. No pskernel-core, self-hosting or C5.


## M2+A checked signed operations and Float bit reads — snapshot review (14 October 2026)

At commit `7bea16a0614be79e51c1ebbb99f926eda342b1fa`, [Linux CI 38549762258](https://github.com/dwijayuda/pskernel/actions/runs/38549762258) compiled and independently regenerated the two disjoint selected Core assets **byte-for-byte**: 62 checked Int8/Int16/Int32/Int64/BitVec method definitions and six Float/Float32 read-only bit-model definitions. The original frozen /61+signed identity prelude was preserved as the noncircular export boundary; no axiom, choice, source acceptance exception, instance or class was added. Official kernel replay and candidate checks passed before the selected Standard correctly refused the old digest. The observed next snapshot is **FNV `fnv1a64:2992617569121253333`** and **SHA-256 `sha256:4fc70a9fac595be03500185122459263e1a9e75141bc8fd39a680785d682e8a3`**. The expected 1,643 declarations (previously 1,575 plus 68, unchanged 23 classes and 153 instances) are subject to full regression confirmation; this edit pins only these independently measured hashes.

**Important remaining work:** These imported definitions are logical Core, not yet executable signed/Float operations. F1 `ofBits`, NaN canonicalization, arithmetic and scientific literals, signed Int-valued conversions, signed shifts and comparisons, typed signed/float IR and ABI, all-target runtime evidence, selected arrays/bytes/library and comprehensive environment manifest remain open. The latest fully green selected Standard before this digest edit remains `d112580` in CI 38546207955. Continue M2+A in native portable `.lean`; no pskernel-core, self-hosting or unsound foundation expansion.




## 14 October — signed proof closure diagnosis and coherent BitVec selection

CI [38547078451](https://github.com/dwijayuda/pskernel/actions/runs/38547078451) at `189b89b94d9d2f9bf705c6a7eda6ed30aca96d90` independently accepted six `Float.toBits`/`Float32.toBits` Core declarations, zero new axioms, but **refused** the larger signed root selection. The error is real: native `Int.add_zero`, `Int.neg_neg`, `Int.natCast_*` and similar proof bodies exhibit application/declaration type mismatches against PSCV0's selected Int model, leaving other recursive arithmetic dependencies blocked. It is not a reason to turn Int lemmas into axioms or to disable kernel validation.

The next isolated candidate selects the pure BitVec-backed signed width operations (`ofNat`, `toBitVec`, `ofBitVec`, add/sub/mul/div/mod, neg/complement and bitwise Boolean operators) for Int8/16/32/64. Int-valued conversion, signed shifts, comparisons and general `OfNat` registrations remain unselected until their exact native logical and checked-Int dependencies can be reconciled. A green candidate alone does not grant runtime execution. F1 read-only Float projections are captured as an independently reproducible native asset.


## M2+A logical-operation dependency qualification — 14 October 2026

**Latest green selected Standard:** `d1125803720ceb347a23acdd6f21f8140355fac5`, [Linux 38546207955](https://github.com/dwijayuda/pskernel/actions/runs/38546207955), full 25-step workflow passed. The selected environment includes checked native Float/Float32 models and `Int8/Int16/Int32/Int64/ISize` identity structures: **1,575 declarations, 23 classes, 153 instances** and unchanged 426 prior cross-target observations. FNV `fnv1a64:545524655185859287`, SHA-256 `sha256:2675059835d6278a4c7ac8871a3df937835d2ee57912dfd7b9b296576df30c1f`. Source/runtime Float and signed arithmetic remain disabled until qualified.

Next independent native Lean 4.35.0 reference slices, now under strict candidate review: (1) F1a logical `Float.toBits` and `Float32.toBits` projections, deliberately excluding `ofBits` whose full proof closure needs unapproved `Classical.choice`; and (2) a four-width coherent signed `ofNat/ofInt/toInt`, BitVec, arithmetic, division, modulus, bitwise, shift, comparison and `OfNat` root family. The 20 source methods per width are selected directly from pinned `src/Init/Data/SInt/Basic.lean` and checked against `tests/elab/test_extern_int.lean`. A green candidate would qualify source/Core authoring only; complete typed erasure, integer/Float IR validation, JS/TS/Rust/Wasm GC/ABI behavior and official native runtime observations are separate mandatory gates. No new trusted foundation assumptions, pskernel-core, self-hosting or release claim.



## Current signed selected Standard — independent digest review (14 October 2026)

At commit `8bee79d6c116ef102d0bc5bc4b4be7ae97f135e7`, [Linux 38545886718](https://github.com/dwijayuda/pskernel/actions/runs/38545886718) compiled the checked 15-entry SInt family asset, regenerated it **byte-for-byte** from the original pre-signed Standard, and rechecked all five recursor rule contracts. Its selected-Standard guard correctly refused the previous snapshot and independently reported **1,575 declarations, 23 classes and 153 instances** (net +10 actual declarations replacing five axioms); FNV `fnv1a64:545524655185859287`; SHA-256 `sha256:2675059835d6278a4c7ac8871a3df937835d2ee57912dfd7b9b296576df30c1f`. These precise observed values are now pinned without weakening the two strict registry guards. **This revision still needs its next complete green Linux regression.** No new trusted axioms, signed runtime arithmetic, portable USize/ISize execution or F1 Float bit interfaces are claimed. F1 awaits a sound resolution of the `Classical.choice` proof dependency; other M2+A exits remain open.



## Signed checked Standard integration — digest qualification required (14 October 2026)

The native candidate at `4c42b5b1ca4e7fccfc84d56dab20e2fb293ac976` passed [Linux 38544426724](https://github.com/dwijayuda/pskernel/actions/runs/38544426724) and source-transport run `7486f326f2f65da9d9ebff433ed24d83ff7ba5ce` passed [Linux 38545090626](https://github.com/dwijayuda/pskernel/actions/runs/38545090626), each with all 25 checks. The signed logical identity candidate has **15 checked declarations, five compared recursor rules, no new axioms, 93 shared nodes and 106,050 UTF-8 source bytes**, replacing the five old `Int8/Int16/Int32/Int64/ISize` type axioms. The signed stage is now imported after F0 Float logical identities using a separately frozen pre-signed export boundary, preserving byte-for-byte native regeneration. Prospective selected Standard count: 1,575 declarations (formerly 1,565); 23 classes and 153 instances unchanged. **This selected change is not yet qualified until independently observed new FNV/SHA hashes and full kernel/runtime regression pass.** F1 Float bits still cannot import unapproved `Classical.choice`; signed arithmetic and portable platform-width execution remain incomplete.



## M2+A next dependency: signed logical wrappers and F1 constructive Float blocker (14 October 2026)

The selected F0 Float/Float32 logical identity environment passed all 24 Linux gates at commit fbda73e1635fe35a5b7c31e2eda59a39f5e64b21, [CI 38534425757](https://github.com/dwijayuda/pskernel/actions/runs/38534425757). The F1 native bit/classification candidate at 5fc60b939efe0d509e9f98035bbee57a72369d2e failed its mandatory gate at [CI 38543575033](https://github.com/dwijayuda/pskernel/actions/runs/38543575033): its 1,075-declaration closure requires unapproved Classical.choice along Float.ofBits → Float.Model.ofBits → Float.Model.UnpackedFloat.unpack → Nat.pow_eq_zero. No source bit APIs or new trusted axioms were admitted. The native authoring command remains for constructive research; its unapproved candidate is not a mandatory regression gate.

Pinned Lean 4.35.0 src/Init/Data/SInt/Basic.lean provides an independent completion path: Int8/16/32/64 and ISize are genuine one-carrier checked inductives over their unsigned counterparts. A strict signed identity exporter is being qualified now, without runtime enabling, pskernel-core or self-hosting. Next: validate exported metadata and original-kernel replay, then sign-correct conversions and runtime operations. Remaining M2+A and F1–F4 are incomplete.



## F0 selected Standard digest — independently observed (14 October 2026)

Linux [run #38534047864](https://github.com/dwijayuda/pskernel/actions/runs/38534047864) at `bdfdb6b6402618908c1d52aa6494f37df7483713` compiled the newly selected 51-entry Float/Float32 Core model, independently regenerated its 254,044-byte source **byte-for-byte**, passed the F0 annotation and native-kernel negative probes, and correctly refused the previous /61 Standard digest. The run's independent candidate for the new selected Standard fingerprint was **FNV `fnv1a64:4585335486592655667`** and **SHA-256 `sha256:3bed7c1104a6209f6af124e932ce7c7ae6401f0f9483896e6730c51ffd35d0ca`**. These are now pinned in `StandardSnapshot.lean` without weakening either validation guard. The new selected environment is **pending full official kernel, source, runtime and CI qualification**; the last fully green regression remains `bb2dbbcc` on the unchanged /61 environment. F1–F4 executable Float, M2+A and later milestones remain open.



## F0 logical identity asset selected — kernel/registry qualification in progress (14 October 2026)

The pinned native F0 candidate passed all 24 Linux regression steps at `bb2dbbcc6432401fedf7f73f1b174d7ee765c3ab`, [CI #38532887281](https://github.com/dwijayuda/pskernel/actions/runs/38532887281), including rejection of a forged Format.mk signature. Exactly 51 logical entries were generated, with 8 independently compared recursor rules, no new axioms, and only pre-approved `propext` and `Quot.sound` in the existing foundation. Frozen candidate source: 254,044 UTF-8 bytes / SHA-256 `47e9e2ac59dc256d108e801e38c57a238c7cdfa1d1f06c16df2fd3390cf50501`. New pre-F0 exporter stage keeps the original /61 boundary. Integrating the selected source replaces exactly 2 legacy type axioms, so the prospective Standard declaration count is 1,565 (previously 1,516); classes and instances are not modified. **Selection is not qualified until a new independently observed FNV/SHA registry snapshot, official kernel replay, negative conformance and broad Linux workflow pass.** Float ofBits/equality/arithmetic/scientific/runtime/ABI (F1–F4), M2+A and later milestones are still incomplete.



## F0 Float identity — checked candidate qualification (14 October 2026)

Commit [`9b5f04e`](https://github.com/dwijayuda/pskernel/commit/9b5f04ed5b87707410dd859a247e0d724f326cc8) completed all 24 Linux gates in [Actions run 38531327231](https://github.com/dwijayuda/pskernel/actions/runs/38531327231). Native authoring exported **51 dependency-closed Float/Float32 logical identity declarations**, replaced exactly the legacy `Float`/`Float32` type axioms inside a discarded candidate, compared **8 recursor computation rules**, and independently replayed the candidate through the official pinned Lean 4.35.0 kernel. Imported candidate axioms: **none**; approved pre-existing foundation: exactly `propext` and `Quot.sound`. Source: 254,044 bytes / 1,444 shared source nodes. The **/61 selected Standard remains unchanged**, with 1,516 declarations / 23 classes / 153 instances, 426 cross-target observations and original frozen fingerprints. **F0 is not yet selected/published; runtime Float functionality, F1–F4 and M2+A remain incomplete.**

Root cause: pinned `Float.Model.Format.mk` constructor carries elaborator-generated `autoParam` tactic annotations. These transitively refer to `Lean.Syntax` but are definitionally equivalent to their annotated proof types. The native F0-only exporter removes only fully applied `autoParam` wrappers, proves each transformed signature in the original native environment with an ephemeral official-kernel typed alias, refuses altered term bodies, and separately replays the portable Core with exact regenerated metadata. Unrelated `optParam`/real Syntax dependencies remain untouched. The next authoring checkpoint adds negative policy probes and publishes the full verified candidate source through Linux Actions text logs for review; **no snapshot or release capability change is claimed until integration and requalification.**



## Current F0 implementation/audit slice — 14 October 2026

Verified last full-green executable: `34ff236b6fe9f936d7d44b8ace1c70612c7cc66e`, Linux [38515443060](https://github.com/dwijayuda/pskernel/actions/runs/38515443060), selected /61 1516 declarations / 23 classes / 153 instances and 426 shared runtime observations. Draft PR 109 remains open. Do not call F0 or M2+A complete.

New F0 design/inventory checkpoint: [Float logical/runtime boundary plan](docs/PSCV0_FLOAT_LOGICAL_RUNTIME_BOUNDARY_PLAN_2026-10-14.md), updated at `5675dafa`. Explicitly separates existing Float/Float32 name and IR scaffolding from the absent checked Standard logical families. Audits pinned Lean 4.35.0 Model/Float, Model/Float32, bits, IEEE-vs-structural equality, scientific literals and runtime/ABI proof obligations. No new source Float support is claimed.

New executable F0 *read-only closure discovery* at `64a79a738d279e973839c624468fbec222212eb5` expands the existing native `--audit-standard-closure` to both Float wrappers, bit transports, BEq and OfScientific. Linux [38521251051](https://github.com/dwijayuda/pskernel/actions/runs/38521251051) **completed successfully** at executable `64a79a738d279e973839c624468fbec222212eb5`. Its read-only F0 closure audit, official checker, parser/refusal suite, JS/TS/Rust, GC/Wasmtime component and existing performance gates passed. This certifies only audit tooling and unchanged /61 behavior; **Float and Float32 source/runtime are not yet implemented or qualified**. This does not import, assume, or emit floating declarations. Next, select a complete closed Lean logical model F0 candidate and replay it in the official kernel with strict assumptions/snapshot boundaries; then implement F1–F4 in dependency order. Preserve no C5/self-hosting/pskernel-core scope, no new assumptions, and existing cross-target baseline.

## Post-/61 research checkpoint — Float/Float32 semantic closure

Reviewed pinned Lean 4.35.0 `Init/Data/Float/{Float,Float32,Model/Float}.lean`, `Init/Data/OfScientific.lean` and the upstream floating conformance tests. The new [Float logical/runtime boundary plan](docs/PSCV0_FLOAT_LOGICAL_RUNTIME_BOUNDARY_PLAN_2026-10-14.md) pins canonical NaN bits, Boolean vs propositional equality, signed zero, f32 rounding, exact scientific literals, cross-target runtime/ABI responsibilities and negative conformance. **Research only: no Float implementation or new proof assurance is claimed.** Next dependency order is F0 selected Core closure, F1 bits/classification, F2 arithmetic/BEq, F3 conversion/literals, F4 all-target qualification. /61 remains last green executable at `34ff236b`, CI `38515443060`.


## New qualified /61 checkpoint — 14 October 2026

Executable commit `34ff236b6fe9f936d7d44b8ace1c70612c7cc66e` passed the full Linux workflow
[38515443060](https://github.com/dwijayuda/pskernel/actions/runs/38515443060).
Profile `pscv0-v7-native-bounded/61` is **green for its declared selected scope**; this
does NOT mean M2+A, all v7, C5, full compiler metatheory, or formal backend preservation
are complete. Standard selected 1516 declarations / 23 classes / 153 instances, FNV
`fnv1a64:6333670853941549394`; SHA candidate
`sha256:ebf02f5f8dfecf3769cbaeaa52e39dac3ba9c8dc034ea5284655da324bc75d60`.
426 shared cross-target runtime observations passed for TypeScript, JS and Rust;
Wasm GC/Wasmtime component, linked projects, parser/negative conformance, official kernel,
asset regeneration and performance gates passed. These are bounded runtime observations,
not a proof that every possible backend program preserves Lean semantics.

Resolution: the official Lean 4.35.0 `Init/Prelude.lean` defines
`Unit : Type := PUnit` and `Unit.unit := PUnit.unit`, but PSC0's APP-03
empty-call path rejected a fresh *universe metavariable* in the
`PUnit` argument domain before checked unification. The source check
now distinguishes unresolved term types (still refused) from the known
Unit/PUnit family, solves the universe using ordinary checked unification,
then rechecks definitional equality and inserts an ordinary typed Unit inhabitant.
All positive APP-03 cases (including `PUnit`) and the existing negatives passed.
No new axiom, untrusted cast, permissive fallback or relaxation of source/kernel
acceptance. Previous historical /61 failures and /60 baseline below remain for
audit but are superseded by this independently qualified executable checkpoint.

Further upstream sources studied for preceding /61 root fixes:
`src/runtime/interrupt.cpp` (thread-local heartbeats),
`src/kernel/environment.cpp` (checked `lean_add_decl`),
`src/Lean/Environment.lean` (`Kernel.Environment` checked replay),
`src/Lean/Declaration.lean` (kernel reducibility hints),
`src/Init/Data/UInt/Basic.lean`, `src/Init/Data/Hashable.lean`,
and `src/Init/Data/String/Defs.lean`.
Use pinned commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
Upstream licensing is acknowledged in the adapted source and
`psc0/THIRD_PARTY_NOTICES.md`.

Next: make `/61` the qualified baseline, update the latest frozen snapshot and
milestone status documentation consistently, audit hot-path performance/resource
telemetry, and continue the remaining M2+A language/standard exit criteria
without starting C5 or self-hosting.


Checkpoint: 14 October 2026. This file and [AI_CONTINUE_PROMPT.md](AI_CONTINUE_PROMPT.md)
are the active handoff. **Update both after every milestone slice**, as requested
by the user because usage is low. Record the exact code revision, CI evidence,
remaining work and next action before beginning another slice.

## Latest continuation: kernel-only replay, awaiting qualification

Run [38479812733](https://github.com/dwijayuda/pskernel/actions/runs/38479812733)
at `15cea236` passed build, quotient probes, frozen regeneration and GetElem
erasure. It failed later on a malformed new List.foldl fixture; it also exposed
AsyncConsts collisions between distinct imported private names.
The next code commit moves standalone checking/replay to official
`Lean.Kernel.Environment.addDeclCore` at trust zero, preserving full names and
all kernel checks. It fixes the fixture's APP-03 argument order and compiles the
provider Admission module to validate the changed API. No new assumptions.
The earlier quotient/Unit failure descriptions below are historical diagnoses.
Fetch the new run and inspect complete results; /60 remains the last full green.

## Active repair slice — implemented, awaiting CI

The next code commit after checkpoint `85b35cd` implements quotient group
admission once with per-descriptor validation, shared nullary literal handling
before definition lookup, normalized PUnit's unit carrier, and removal of the
temporary cache fallback. The existing quotient probe covers repeated/reversed
descriptors, forged existing signatures and provider collisions.
[Design and pinned source references](docs/PSCV0_M2_A_SCALAR_COMPLETION_2026-10-14.md).
These changes are **not yet qualified**. Fetch live HEAD and its native workflow;
record results in both handoff files. Historical failure details below identify
the causes addressed by this slice, not a new observed result.

## Current state: M2+A incomplete; /61 qualification pending

- Repository: `dwijayuda/pskernel`; branch: `psc0/pscv0-v7-native-lean-v1`.
- Existing draft [PR 109](https://github.com/dwijayuda/pskernel/pull/109).
- Latest code: **`1f54142c6225020c39265254a582860bd4169937`**.
  A documentation-only checkpoint follows this revision; fetch live HEAD.
- Latest [Linux run 38478159236](https://github.com/dwijayuda/pskernel/actions/runs/38478159236),
  job `115573914577`: **completed, failure**.
- Profile `pscv0-v7-native-bounded/61` is **under qualification**.
  Build, asset regeneration and strict registry digest checks passed; source
  checking failed in erasure. Native/backend integration was not reached.
- Failure: `PSCV0-ERASURE: unknown constant Unit.unit (in PsStandard.instInhabitedUnit)`.
- The same log contains repeated **PANIC: duplicate normalized declaration name
  Quot vs. Quot**, from official Lean environment admission. These panics are
  unresolved even though execution continued.
- No new full-green result, M2+A completion, formal runtime equivalence or
  performance parity is claimed.

The user **explicitly approved exactly Lean 4.35.0's `propext` and `Quot.sound`**
for the audited foundation. Approval is already published. **Do not ask again.**
All dependent proof declarations still require official Lean kernel checking.
No other additional assumptions were approved.

## Execution contract and source of truth

Use GitHub connector source reads/writes and Linux Actions only; no local
checkout, shell/build or Desktop Commander. Work natively in portable `.lean`.
No `pskernel-core`, self-hosting tests or compiler-source `.ps` migration yet.
Wasm GC internally; linear memory only at explicit ABI boundaries.

Fetch live remote HEAD and relevant CI before writes. Preserve concurrent work
with expected-HEAD, non-force updates. Keep PR 109; do not merge.
Do not weaken acceptance, fabricate axioms, add unchecked kernel fallbacks or
hide runtime representation errors with arbitrary casts.

Study corresponding official **Lean 4.35.0** source and tests before feature
design/implementation/redesign, at commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
Record semantics, algorithms, invariants, data structures and justified
simplifications. Preserve attribution/licensing when adapting code.
Prefer coherent shared mechanisms, then focused validation and existing
integration gates. Preserve required behavior, not obsolete internals.

Canonical references:

- [Language reference](PSCV0_LANGUAGE_REFERENCE.md)
- [M0–M5 architecture](docs/PSCV0_NATIVE_LEAN_GRADE_ARCHITECTURE_REDESIGN_V1.md)
- [Phase A–E exit gates](docs/PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md)
- [Readable-output audit](docs/PSCV0_READABLE_OUTPUT_AUDIT_2026-10-13.md)
- [Pinned Lean migration](docs/PSCV0_LEAN_435_PIN_2026-10-14.md)
- [Active scalar design and source study](docs/PSCV0_M2_A_SCALAR_COMPLETION_2026-10-14.md)
- [Format/Repr/Hashable design and qualification](docs/PSCV0_A_FORMAT_REPR_2026-10-14.md)

## Last fully qualified boundary: /60

Executable **`d72fc7779b2e8d130915dfe4ace339634ba0addd`**;
[green Linux 38466179341](https://github.com/dwijayuda/pskernel/actions/runs/38466179341),
job `115533442925`.

- 399 shared runtime observations and four panic contracts.
- 217 portable / 227 native modules.
- Standard: 672 declarations / 23 classes / 109 instances.
- FNV: `fnv1a64:10680386315174967875`.
- SHA: `sha256:9a54d5747d3047abff68e3bd872b791f3489f719cf83e8aba6776d342f045cc0`.

Official kernel, independent pinned native oracle, semantic/refusal/search,
strict IR, JS/TS/Rust, V8/Wasmtime GC, WIT/WAT/component/ABI, projects and
existing performance gates passed at that boundary.

Qualified: ToFormat/Repr and selected nonrecursive deriving; UInt/BitVec
construction/conversions; unsigned Canonical ABI widths; Hashable class,
17 checked instances and selected nonrecursive deriving; native-compatible pair
and UTF-8 string hashes. Hash runtime algorithms are audited implementations
of checked opaque declarations, not formally proved equivalent.

Shared Int.rec erasure evaluates its sign discriminator once. Generic calls
retain original declaration binder masks when Sort parameters specialize to
Prop; irrelevant carriers/proof slots use Unit. Complete-spine WHNF and
reflexivity-before-evaluation repairs remain. Frozen proof assets regenerate
exactly. The /60 qualification predates the newly approved two-axiom /61 closure.

## Implemented /61 slice, with limited qualification

### Checked unsigned operation asset and dictionaries

Commit `e9fde4e3ff88b1e83c8c59e7b531403f6eb5d154` admitted
`packages/environment/src/Ps/Environment/StandardUnsignedOperationsData.lean`:

- 803 declarations; 49,978 shared typed source nodes; 6,457,592 UTF-8 bytes.
- Source SHA256:
  `b33dc2e256f17da29a3236a24c2d8267bf04de4338d73c568cafc44ee686f2de`.
- Exactly the two approved axioms and four kernel-generated quotient descriptors.
- UInt8/16/32/64 add/sub/mul/div/mod/neg/complement/land/lor/xor/shiftLeft/shiftRight
  (48 operations), and the actual Nat.div logical model.
- Six former axiom declarations replaced by native checked definitions:
  Nat.decEq, Bool.decEq, Unit.unit, Unit, Nat.blt and Nat.div.
- `StandardUnsignedOperations.lean` adds 24 explicit HAdd/HSub/HMul/HDiv/HMod/Neg
  dictionaries. Logical proof dependencies do not enter runtime support.
- Frozen `psSelfHostProdHashPreludeEnvironment` feeds the operation stage.
  Export boundary is `psStandardUnsignedOperationsBoundary`; source sharing is
  enabled and definition-to-axiom replacement is disabled.
- Both new portable Lake roots are registered. Primitive audit covers all 48.
- Isolated quotient probes deliberately use the pre-admission Hash stage.
- Fifteen observations were added to the existing shared native/all-target
  harness: width vectors, higher-order shift, generic wrapping addition and
  exact UInt32 maximum-times-maximum multiplication. They are **not yet fully
  qualified**. Temporary artifact transport jobs were removed; regeneration
  compares admitted and fresh sources byte-for-byte.

Earlier /61 work also includes native two-universe Prod and product dictionaries;
alpha-renamed/normalized universe signature audit; right-discriminating Bool.beq;
native List.foldl telescope and List.reverseAux equations; 16 UInt default/display
dictionaries; general logical iota beneath recursive function telescopes; quotient
descriptors and lift/ind reduction. Product/display observations also await full
integration. Unsigned div/mod/shifts use shared IR plus ECMA/Rust/Wasm plans,
including exact UInt32 multiplication, UInt64 BigInt, zero guards and width-masked
shifts; this does not enable signed/platform/Float support.

[Run 38476108793](https://github.com/dwijayuda/pskernel/actions/runs/38476108793)
compiled 220 portable / 231 native modules; all four frozen assets regenerated
exactly; 803 candidate declarations were kernel checked and 33 recursor rules
compared. Its old /60 snapshot deliberately refused the changed registry.
Do not interpret the kernel receipt as proof that repeated quotient admission
is clean: the later production replay exposed the duplicate-registration panic.

### Reviewed strict digests and faster native validation

Commit `1f54142c6225020c39265254a582860bd4169937` pins the new payload values
independently reported by the previous Nat-arithmetic implementation:

- FNV: `fnv1a64:16613033526791726173`.
- SHA: `sha256:8aea3c6be714db09f4a5a442e9fab57a40bdf13c11d86e811c2574165d55b04d`.

The checksum implementation now uses UInt64 FNV, UInt32 SHA-256 and packed
ByteArray storage; joint validation serializes the canonical payload once.
Digest/padding semantics and strict drift refusal remain unchanged. No hash
FFI, new assumptions or automatic snapshot acceptance.

Latest run passed the full-payload strict checks. Existing four SHA known-answer
vectors remain, but their later `projectBoundaries` gate was not reached because
erasure failed first.

Bounded CI measurements: previous cold build 222,087 ms, warm 595 ms; latest
native rebuild 12,317 ms, warm 561 ms. Audit/export commands fell from roughly
73 seconds each to 2–5 seconds; unsigned regeneration was approximately 4.95
seconds including startup versus 75 seconds. This is evidence for this workload,
not a full parity claim.

Cache keys now use OS/architecture/toolchain hashes; Lake's traces track module
changes. The exact old-key fallback in
`.github/workflows/psc0-pscv0-native-v7.yml` was temporary migration scaffolding.
The latest run saved the new cache; remove that fallback in the next code slice.

## Next slice: fix two shared boundary invariants

### 1. Admit the quotient group once; validate every descriptor

Owner: `packages/pskernel-lean/provider/PsKernelLean/Prelude.lean`.

`toLeanPreludeDeclaration` converts each of Quot, Quot.mk, Quot.lift and Quot.ind
to the same generative Lean `.quotDecl`. `tryPreludeDeclaration` unconditionally
calls `env.addDeclCore 2000000 20000 converted none true`, then validates the
member's kind/type/universe metadata. Each descriptor and replay retry therefore
tries to generate all four constants again. Lean's AsyncConsts uniqueness
invariant panics on the repeated declaration.

Study pinned `src/kernel/quot.cpp`, `src/Lean/Environment.lean`,
`src/Lean/Declaration.lean`, `tests/elab/quotInd.lean` and locate the
`kernelQuotNameCollision.lean` test before editing.

Design direction: separate **ensure the kernel quotient group exists once**
from **validate this supplied member**. Inspect the checked environment for the
group; generate it once when absent, otherwise validate exact existing kernel
quotient kinds/types/level parameters without re-adding. Reject partial groups,
collisions and forged metadata. Share member validation across both paths.
Do not introduce general name-based duplicate skipping for other declarations.
Use this same mechanism for candidate authoring and production prelude replay.
Retain the isolated Hash-stage signature/collision refusal probes.

### 2. Resolve builtin runtime identities before ordinary definitions

Owner: `packages/erasure/src/Ps/Erasure/Expr.lean` and shared erasure helpers.

Unit.unit was formerly an axiom, so the late nullary-literal fallback handled it.
Its admitted native definition now resolves as an ordinary runtime entry first;
it is intentionally absent from runtime support, so lookup fails before reaching
the existing fallback. Adding its proof closure to runtime would fix the symptom,
not the invariant.

Inspect the complete constant/application/eta-completion paths, especially
`psErasureSpecialEntry`, `psEraseSpecialBoundary`, `psEraseGeneralApplication`
and `psErasureResolveEntry`. Centralize existing builtin literal/runtime identity
classification before ordinary definition lookup, consistently for constants and
applications. Check the related Bool.true/Bool.false/Nat.zero family; preserve
arity and overapplication refusal. Native Unit is an alias to PUnit.
Keep logical checked definitions separate from their audited runtime treatment.

After implementing both coherent fixes, run existing focused official-kernel/
erasure gates and the full native workflow. Check logs for panics explicitly,
not just process exit status. Re-run remaining checksum vectors and all-target
observations through that workflow. Do not call /61 qualified before the complete
matrix passes. Update both handoff files with exact evidence at this slice.

## Next unsigned-interface slice (design only, not published)

A prior session prepared parser buffers in memory only. They were **not applied,
compiled or published**; no future chat should depend on those transient stores.
The branch contains all other active code described above. Reconstruct the design
from pinned sources rather than assuming a missing working-tree patch exists.

After /61 qualification:

- Export a separate frozen native comparison/conversion interface stage against
  the unsigned-operation boundary, with no new assumptions.
- Study UInt decEq/decLt/decLe, native LT/LE instances, all twelve cross-width
  conversions, Nat.toUInt aliases, GE.ge/GT.gt and DecidableLT/LE.
- Register actual checked class/instance metadata separately from proof data.
  Existing LT/LE and Nat instances are present in scalar data but absent from the
  curated source class roster. HAnd/HOr/HXor/HShiftLeft/HShiftRight/Complement
  declarations already occur in the operation proof asset.
- Reuse the existing typed machine comparison plan; comparison proof fields erase.
  Evaluate width-conversion composition against an explicit typed cast for
  correctness and performance; this decision is not implemented yet.
- Study native priority-500 `instBEqOfDecidableEq` and generic Pi search/runtime
  support before reusing it.
- Parser plan: one bounded longest-adjacent-token reader shared by prefix/infix,
  at most three existing lexer tokens; preserve spans, reject gap fusion and
  never consume empty EOF. Ordinary class applications own semantics.
  Relations at precedence 50, nonassociative; bitwise OR 55, XOR 58, AND 60;
  shifts 75 left-associative; complement prefix 100.
- Relevant PSC0 owners:
  `packages/syntax/src/Ps/Syntax/Pscv0/Operators.lean`,
  `packages/syntax/src/Ps/Syntax/Pscv0/TermRead.lean`.
  Pinned references: Init/Prelude, UInt/Basic, UInt/BasicAux, Init/Notation,
  Lean/Parser/Basic tokenFnAux; tests bv_uint, uint_fold, uintMatch, fold_uint.
- Validate a compact set of boundaries, generic and partial applications through
  the existing conformance table. Keep proof closure out of runtime support.

Checksum source study also covered pinned
`src/Lean/Compiler/LCNF/ExtractClosed.lean`,
`src/Lean/Compiler/NeverExtractAttr.lean`,
`src/Init/Data/ByteArray/Basic.lean`, UInt Basic/BasicAux and
[NIST FIPS 180-4](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.180-4.pdf)
sections 4.1.2 and 6.2.

## Roadmap and preserved architecture

Interleave **M2+A → M3+B → M4+C/D → M5/E**. M1's selected checked
GetElem/Fin/List/Array/optional-lawfulness closure is complete.
Recursive/indexed/dependent deriving belongs with M3's data/transport/termination
mechanisms. Effects/specifications/VCs belong to M4/C-D.
Collect E evidence and measured M5 improvements throughout.

Remaining M2+A includes unsigned comparisons/conversions/dictionaries,
signed/platform words, Float/Float32/scientific, expanded BitVec/bytes/selected
library APIs, the comprehensive cryptographic module/public/import/notation/
handler/class/instance/tactic/effect/axiom manifest, broader scope/depth/resource
evidence and C5 semantic retention. A declaration snapshot is not the complete
manifest. Do not move incomplete gates merely to declare M2+A finished.

Shared instance search uses generator/consumer tables, exact checked keys,
fresh term/universe answer templates and independent budgets. Only an answer
owner adopts its speculative context; consumers instantiate/recheck in their own
contexts. Closed identical local signatures are required for sharing. Output
preferences reconcile after selection without lower-priority backtracking.
Limits remain 4096 generators/candidates/answers, 32768 transitions, height 64.

One transactional synthetic queue handles Core constraints, saved syntax,
tactics/defaults/numeral fallback and expected-term adaptation. Ordinary work
quiesces before defaults; declarations drain pending work. Defaults use checked
opaque holes, failed retries roll back lexical authority, and reducibility
policy remains explicit. Genuine OfNat and direct Coe/CoeFun/CoeSort use shared
typed application; no coercion chains/auto-lifting, and APP-03 stays strict.
The SynthInstance facade must not acquire another retry engine.

See [instance graph](docs/PSCV0_M2_INSTANCE_GRAPH_2026-10-13.md),
[generalized constraints](docs/PSCV0_M2_GENERALIZED_CONSTRAINTS_2026-10-13.md),
[postponed elaboration](docs/PSCV0_M2_POSTPONED_ELABORATION_2026-10-13.md),
[coercions](docs/PSCV0_M2_DIRECT_COERCIONS_2026-10-13.md),
[deriving](docs/PSCV0_M2_A_DERIVING_2026-10-13.md) and
[equality/defaults](docs/PSCV0_M2_A_EQUALITY_DEFAULTS_2026-10-13.md).

Parameter/universe-aware Inhabited/BEq/DecidableEq share family/field/recursor
mechanisms. Selected deriving handles non-indexed/nonrecursive families with
independent computational fields. Proof-only fields erase; dependent runtime
existentials and general higher-rank dictionaries remain explicit refusals.
Do not bypass unknown-type IR checks.

Readable JS/TS/Rust/WAT/WIT are implemented for the qualified subset; extend the
shared plans. Historical bounded Lean/PS printers are reusable, not complete C5.
Retain checked pre-erasure binder/resolution/implicit/default/occurrence semantics
during M2–M4; publish reconstruction/correspondence under M5/E. Coarse declaration
maps or source replay do not establish reconstruction, and two checked outputs
are not a proof of equivalence.
