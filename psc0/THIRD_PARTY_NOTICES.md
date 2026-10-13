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
