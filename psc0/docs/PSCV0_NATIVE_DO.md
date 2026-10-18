# Native typed do control

Implementation boundary, 12 October 2026. The selected Id/Option/Except typed-do
profile passed Linux run 38215524481 (native profile 36); it remains qualified
in profile 41, run 38223957480. Full v7 base-do, verified state and effect
families are not implied.

The native program parser retains do items in the shared source AST. It no
longer substitutes tokens with Except-specific declaration placeholders.
The legacy flat translation API retains its explicitly limited contract.

Scope resolution follows each binding once: annotations and actions see the
preceding scope; patterns bind only their continuation. Conditional proof names
are local to their branches; if-let patterns bind only the success branch.
Nested do establishes its own return target.

Elab.Do separates typed effect operations from control. The current registered
families are Id (including plain expected value types), Option and Except.
Aliases are unfolded only until their effect head is visible, preserving the
distinction between Id (Option A) and Option A. Id is an ordinary checked,
universe-polymorphic reducible definition; no axiom is added.

Bindings, patterns, named-proof conditions and branch refinement reuse existing
local abstraction, conditional and pattern-matrix elaborators. Return closes
the current do. Non-final actions require Unit results. Following code at a
conditional becomes one checked local continuation, elaborated once outside
branch scopes and called only by paths that fall through. Syntax and Core are
not copied per branch.

The result remains ordinary prepared Core, checked by official Lean and passed
through the existing erasure/IR gates and all backends. No runtime target or
host elaborator appears in control elaboration.

This implements a selected typed-control profile, not complete base-do or v7
conformance. Class-based Pure/Bind and registered Reader/State effects still
need their Standard environment and higher-kinded dictionary capability.
Overloaded pure, mutable state/loops, VC/spec effects and P1 exceptions are
not newly claimed. Top-level do needs a determined expected type. Legacy
translation printing is not qualification of native-language reconstruction.

Reference: Lean v4.35.0-rc4 src/Lean/Elab/Do/Basic.lean (DoOps, continuations),
src/Init/Prelude.lean (Pure/Bind), src/Init/Control/Id.lean. Canonical PSCV0
§0B/§3 own the selected braced, newline-separated grammar; if-let selects :=.
