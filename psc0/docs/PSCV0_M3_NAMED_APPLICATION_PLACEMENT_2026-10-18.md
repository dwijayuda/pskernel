# M3+B named application placement in actual input languages

Lean 4.35.0 reference: eb6cafb7290e8bd5f2937522d8d804f58f02bafc,
src/Lean/Elab/App.lean, ElabAppArgs.main (named lookup before explicit argument
consumption), propagateExpectedType and elabAppArgs. A named actual occupies its
named binder; remaining positional actuals fill unnamed explicit binders,
irrespective of written interleaving. Duplicate and unknown names still reject.
The ProofScript selected invocation retains its positional-prefix contract.

## Root cause and design

Run39101822044 / compiler64ce8571 built successfully and passed deriving and
other preparation checks, but actual .lean input branchByRec failed the shared
ProofScript positional-prefix check. Moving the PS fixture's named motive last
had correctly preserved PS syntax but could not fix the native adapter's rule.

PsSyntaxTerm.call now carries PsSyntaxArgumentPlacement. Native whitespace
application selects namedPriority; PS invocation and compiler-generated calls
select positionalPrefix. Scope/capture/recursion traversals preserve this owned
source property. One typed ordered application engine partitions actuals,
selects each real binder, inserts defaults/implicits, advances dependent types,
and preserves checked context. The policy governs placement/explicit overlap
only, not type checking, dictionary solving, assurance or host elaboration.

WF argument capture and post-header continuation preserve the same placement;
no separate elaborator or source-text rewrite. Native output printing retains
written order. Untyped ProofScript printing refuses mixed native calls requiring
typed argument reconstruction instead of silently changing their binding.
C5 remains a later typed source-reconstruction milestone.

## Focused evidence required

Extend the existing actual-input parity fixture only. Keep the named motive
first in .lean explicit recursor source. Compare two mixed explicit-name native
calls against equivalent PS positional calls, including native kernel oracle
equalities. Route a named-interleaved mutual WF recursive call through capture
and returned-function suffix application. Preserve parsed PS placement/overlap
refusals and native duplicate/unknown-name refusals. Existing five-target paired
execution remains required. Foundation identities and budgets do not change.

Original PSC0 implementation guided by pinned upstream architecture; no native
implementation body copied. Preserve existing Apache-2.0 attribution.
