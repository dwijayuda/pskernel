# Maintainer exercise reference

Do not read this before the independent attempt.

The source-linked walkthrough locates the owners. Capture binds exact snapshots;
the shared parsers produce syntax; elaboration produces typed logical Core and
origins; official admission accepts exact canonical graph bytes; erasure and strict
IR validation handle executable forms; the backend lowers/prints candidates;
the host validates resources/API and commits an immutable generation.

For the focused test, after the workflow's build create:

~~~lean
import Ps.BackendWasm.Lower.RuntimeNeeds

example : psWasmIntrinsicUsesNat PsVerifiedIrIntrinsic.stringLength = true := rfl
example : psWasmIntrinsicUsesString PsVerifiedIrIntrinsic.stringLength = true := rfl
~~~

Run lake env lean test/RuntimeNeedsMaintainer.lean. These are exact leaf
regressions, not whole-compiler theorems. A wrong assertion with false must fail.
The owning module only computes bounded runtime-selection hints; exhausted fuel
returns false and must not be treated as an absence certificate.

The changed example returns flag directly. Its checked outputs on false/true
must be false/true. The actual rehearsal records those results independently
from the original invert example's true/false. A typed source refusal happens
before a new current pointer is committed; a postcommit durability error may
already have committed and must report that state explicitly.

Independent admission concerns the logical graph. Strict IR concerns typing and
structure. Consumer execution observes tested behavior. Inventory hashes bind
bytes. None by itself proves source-to-target preservation or grants a copied
receipt publication authority.
