# Lean-derived selected Standard definitions

Lean 4 is licensed under the Apache License 2.0; a copy is included in
[licenses/LEAN-APACHE-2.0.txt](licenses/LEAN-APACHE-2.0.txt).

The selected character/string quoting algorithms in
packages/environment/src/Ps/Environment/StandardString.lean adapt
src/Init/Data/Repr.lean at the project pin:
Copyright (c) 2016 Microsoft Corporation. All rights reserved.
Author: Leonardo de Moura.

Modifications: represent the algorithms as portable PsExpr declarations;
replace native String.Internal.foldl with a total Nat.rec worker whose traversal
bound is derived from the input UTF-8 byte size; retain exact quoting behavior.
This is an adaptation, not unmodified upstream source.

The Int.toNat logical model in
packages/environment/src/Ps/Environment/StandardInt.lean follows
src/Init/Data/Int/Basic.lean:
Copyright (c) 2016 Jeremy Avigad. All rights reserved.
Authors: Jeremy Avigad, Leonardo de Moura.
Modifications: construct the inductive, constructors, recursor and definition
as portable Core terms; keep the checked logical model separate from typed
backend runtime implementations.

The Std.Format algebra and pure layout implementation in StandardFormat*.lean
adapt src/Init/Data/Format/Basic.lean at the same pinned version:
Copyright (c) 2018 Microsoft Corporation. All rights reserved.
Author: Leonardo de Moura.
Modifications: checked Core declaration builders, explicit Unicode prefix scan,
pure work-state records, and total input-weight-bounded transitions in place of
private partial worklists. Pure rendering ignores tags as upstream does; this
does not implement or substitute for effectful MonadPrettyFormat callbacks.

ToFormat/Repr classes, combinators and formatting rules in StandardFormatClass,
StandardToFormat, StandardRepr and Elab/DerivingRepr adapt Lean 4.35.0
Init/Data/Format/{Basic,Instances}.lean, Init/Data/Repr.lean,
Init/Data/Int/Repr.lean and Lean/Elab/Deriving/Repr.lean.
Copyright (c) Microsoft Corporation; author Leonardo de Moura. Apache-2.0.
Modifications: portable checked Core definitions, shared dictionary registration,
parameter/universe-aware deriving without host elaboration, and direct projections
for structures. Recursive/indexed deriving remains in M3+B.
List declarations and recursor-based algorithms follow Init/Prelude.lean and
Init/Data/List/Basic.lean, with explicit independent element/result universes.

StandardFormatString and StandardReprCollections adapt the same Format/Repr
sources and Init/Data/Array/Basic.lean. Modifications: single total UTF-8 scan,
checked collection projections and existing Array conversion adapters.

The host-only StandardClosure dependency audit follows the traversal invariant
of Lean/Util/CollectAxioms.lean (Copyright (c) 2020 Microsoft Corporation;
author Leonardo de Moura; Apache-2.0). Modifications: explicit native worklist,
recursor-rule/mutual-family closure and portable-name collision reporting.
It exports no declarations and changes no compiler trust boundary.

The Nat.add/sub/mul/beq logical models in StandardNatOrder follow the constructor
equations in Lean 4.35.0 Init/Prelude.lean (Copyright (c) Microsoft Corporation,
Apache-2.0). Modifications: compact portable Core recursor construction using
existing logical builders, while retaining separate native runtime intrinsics.

The checked `ite` Core model in `Ps.Environment.Decision` adapts the
nondependent conditional wrapper from Lean 4.35.0 `src/Init/Prelude.lean`
(commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`), copyright 2020 Microsoft
Corporation, authors Leonardo de Moura and Mario Carneiro, Apache-2.0.

`Ps.Environment.StandardScalarArithmeticData` contains modified, converted
closed declaration data from Lean 4.35.0 `src/Init/Prelude.lean` at the same
commit. Copyright (c) 2020 Microsoft Corporation; authors Leonardo de Moura and
Mario Carneiro; Apache-2.0. `Ps.Host.StandardExport` removes expression metadata,
records the dependency cut and converts the checked declarations to portable
Core; proof bodies and universe/binder semantics are retained. The existing
Apache-2.0 license and attribution apply to this asset.

### Checked unsigned Standard Core data

StandardUnsignedFoundationData.lean is generated from Lean 4.35.0 commit
eb6cafb7290e8bd5f2937522d8d804f58f02bafc, Init/Prelude.lean and
Init/Data/UInt/BasicAux.lean. Copyright (c) 2018, 2020 Microsoft Corporation;
authors Leonardo de Moura and Mario Carneiro; Apache-2.0. Conversion removes
expression metadata and records the dependency boundary; kernel checking
retains the original definitions, proof bodies and universe/binder semantics.

### Hashable and runtime hashing

StandardHashFoundationData is converted closed Core from Lean 4.35.0
Init/Prelude.lean (2020 Microsoft Corporation; Leonardo de Moura and Mario
Carneiro; Apache-2.0), preserving opaque values as opaque. StandardHashable
adapts Init/Data/Hashable.lean (2016 Microsoft; Leonardo de Moura).
DerivingHashable adapts Lean/Elab/Deriving/Hashable.lean (2021 Microsoft;
Dany Fabian), using the shared Core telescope/eliminator infrastructure.

BackendEcma/Hash, BackendWasm/Hash and the Rust runtime hashing routines adapt
src/runtime/hash.h and hash.cpp (2013 Microsoft; Leonardo de Moura;
Apache-2.0), whose string algorithm credits MurmurHash2 by Austin Appleby.
Modifications: explicit fixed-width arithmetic and little-endian UTF-8 byte
decoding, GC byte arrays in Wasm and target-native loops. The original
runtime's host-endian memcpy is deliberately replaced with canonical little
endian; conformance is qualified against the pinned little-endian Linux host.

### Logical recursion and quotient foundation

Meta/Iota's recursive-field telescope and quotient reduction adapt the
algorithms in Lean 4.35.0 `src/kernel/inductive.cpp`, `src/kernel/quot.cpp`
and `src/Lean/Meta/WHNF.lean` at commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
Copyright (c) 2018, 2019 Microsoft Corporation; author Leonardo de Moura;
Apache-2.0. Modifications: portable Core, capture-avoiding bound-variable
construction, explicit registered quotient descriptors and bounded reduction.
The official Lean provider regenerates quotient metadata and checks signatures.

### Product, collection, scalar-display and source-sharing updates

StandardProduct follows the two-universe Prod foundation in Init/Prelude.lean
(2020 Microsoft Corporation; Leonardo de Moura, Mario Carneiro). StandardList
follows the native foldl telescope and reverseAux/reverse equations from
Init/Prelude.lean and Init/Data/List/Basic.lean (2020 and 2016 Microsoft
Corporation respectively; Leonardo de Moura, with Mario Carneiro for Prelude). StandardEquality preserves the Prelude
Bool.beq reduction orientation. Modified: portable Core declarations, checked
recursors and explicit dictionary construction.

Unsigned Inhabited/ToString/Repr/ReprAtom dictionaries adapt Init/Prelude.lean,
Init/Data/ToString/Basic.lean and Init/Data/Repr.lean; copyright Microsoft
Corporation, authors Leonardo de Moura and Mario Carneiro, Apache-2.0.
Modified: explicit portable dictionary registration over the checked model.

The host-only StandardSource design follows the interning architecture of
Lean/Util/ShareCommon.lean and Init/ShareCommon.lean (2020 Microsoft Corporation;
Leonardo de Moura, Mario Carneiro). Its safe exact structural-key implementation
does not copy the unsafe object/pointer primitives. It emits shared ordinary
Lean constants without changing portable declaration semantics.

### Checked unsigned operation proof closure

StandardUnsignedOperationsData is converted from pinned Lean 4.35.0 commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Sources include Init/Prelude
(2020), Init/Core (2014), Init/Data/UInt/Basic and BasicAux (2018),
Init/Data/Nat/Div/Basic (2016), Init/Data/Nat/Bitwise/Basic (2019),
Init/Data/Nat/Internal/Linear (2022), and Init/Data/List/Basic (2016):
Microsoft Corporation; Leonardo de Moura, with Mario Carneiro for Prelude.
Init/Data/BitVec/Basic and BasicAux: 2024 Lean FRO, LLC; Joe Hendrix,
Wojciech Nawrocki, Leonardo de Moura, Mario Carneiro, Alex Keizer, Harun Khan,
Abdalrhman M. Mohamed, and (Basic) Siddharth Bhat. Apache-2.0 applies throughout.
The existing LEAN-APACHE-2.0.txt supplies the license.
Modifications: remove expression metadata, preserve exact closed proof bodies,
record the dependency cut, and emit structurally shared portable Core constants.
The explicitly approved propext and Quot.sound remain audited assumptions;
quotient descriptors are regenerated by the official kernel.

### F0 native Float/Float32 identity candidate

Native-only logical identity export of the Float/Float32 wrapper and model closure follows pinned Lean 4.35.0 commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, especially `src/Init/Data/Float/{Float,Float32,Model/Float,Model/Float32}.lean`, `src/Init/Data/Float/Model/Format/{Basic,Valid}.lean`, `src/Lean/Expr.lean`, and `src/Lean/Elab/Structure.lean`. Copyright (c) Microsoft Corporation and Lean FRO, LLC; Apache-2.0. Relevant Format model upstream author: Julia M. Himmel (2026). Modifications: a selected dependency cut, metadata removal and standard Core conversion with exact checked proof/constructor/recursor contents, plus fully-applied elaborator `autoParam` normalization with original-kernel definitional-equality certificates. The exported candidate is **not** a runtime implementation and is **not** yet a selected Standard asset.

### Signed machine-integer logical identities — reviewed candidate

StandardSignedIdentityData is generated from the pinned Lean 4.35.0
`src/Init/Data/SInt/Basic.lean`, copyright (c) Lean FRO, LLC;
author Henrik Böving; Apache-2.0. The native-only checked exporter preserves
complete constructor/recursor metadata for `Int8/Int16/Int32/Int64/ISize`,
replaces exactly five prior type axioms without inventing assumptions,
and compares each iota rule to the kernel-generated reference. It is a
logical Standard asset, NOT an executable signed runtime or ABI guarantee.

### Signed arithmetic and Float bit-read checked Core assets

`StandardSignedOperationsData.lean` reifies the 62 kernel-checked
closed BitVec/signed operations from pinned Lean 4.35.0
`Init/Data/SInt/Basic.lean`, Henrik Böving, and
`Init/Data/BitVec/Basic.lean`, Lean FRO, LLC, Apache-2.0.
`StandardFloatToBitsData.lean` reifies six checked Float/Float32
bit projections from pinned `Init/Data/Float/{Float,Float32,Model/Float,Model/Float32}.lean`,
copyright Microsoft Corporation and Lean FRO, LLC, Apache-2.0.
The exports retain original checked definition/proof bodies, exact
reducibility and immutable dependency cuts; each is independently
admitted through official kernel replay. Neither confers runtime IR/ABI
capabilities or semantic-preservation proof.

### Fixed-width signed class dictionaries

The selected `StandardSignedScalar.lean` module creates generic
OfNat/Neg/HAdd/HSub/HMul/HDiv/HMod/BEq/Inhabited dictionaries using
pinned Lean 4.35.0 `Init/Prelude.lean` and `Init/Data/SInt/Basic.lean`
(Henrik Böving), copyright Lean FRO, LLC, Apache-2.0. Implemented as
portable checked Core over previously admitted signed methods; no
upstream proof text is replaced and no new foundation axiom is added.

### Signed-to-Int constructive conversion

`StandardSignedToInt.lean` uses pinned Lean 4.35.0
`Init/Data/SInt/Basic.lean` and `Init/Data/BitVec/Basic.lean`
(copyright Lean FRO, LLC; Apache-2.0). Four independent native Lean
`rfl` certificates establish exact model equivalence. The new
source module reifies the same constructive formula in checked Core.
No proprietary code, axiom, unknown term or unverified semantic
assumption is introduced.


## Selected partial fixpoints and monotonicity (Lean 4.35.0)

The portable proof-producing algorithms in `Ps.Elab.PartialFixpoint` and
`Ps.Elab.Monotonicity` adapt Lean's
`src/Lean/Elab/PreDefinition/PartialFixpoint/{Main,Eqns}.lean` and
`src/Lean/Elab/Tactic/Monotonicity.lean` at commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
Copyright (c) 2024 Lean FRO, LLC. All rights reserved. Author: Joachim Breitner.
Released under Apache License 2.0, subject to the upstream notice above.
The retained `StandardPartialFixpointData.lean` asset carries the pinned
`Init.Internal.Order.Basic` declaration bodies and its own attribution.


### N-ary dependent argument packing

The portable arity-directed packing, currying and dependent elimination algorithms
in Ps.Meta.WellFounded adapt src/Lean/Meta/ArgsPacker.lean at pinned Lean4.35.0
commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Copyright (c) 2024 Lean FRO, LLC. All rights reserved. Author: Joachim Breitner.
Released under Apache License2.0; see the retained LEAN-APACHE-2.0.txt.
Modifications: explicit portable Core/local-context operations, structural list
recursion, checked construction and source-entry validation, selected nonempty
WF telescopes, and explicit kernel-checked callback extensionality.
