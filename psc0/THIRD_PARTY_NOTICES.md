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
