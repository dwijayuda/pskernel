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
