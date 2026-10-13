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
