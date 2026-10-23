# Portable compiler implementation ownership

Compiler implementation helpers use stable fully qualified names beneath the
reserved Ps.Internal namespace. Original file-private helpers keep their local
leaf names in an explicit owner namespace; all their calls use the complete
identity. They cannot be found under the old unqualified names from another
scope. This is an implementation ownership convention, not general private syntax.

The active direct host publication path excludes Ps.Internal declarations and
types from authored entry API roots. They remain in the exact captured source,
Core graph, independent admission and executable dependency closure. Importing
the compiler module does not turn these implementation dependencies into public
foreign exports. Explicitly constructing a raw target wrapper grants no authority.

Migrations:
- packages/elab/src/Ps/Elab/Data.lean: psDataApply, psDataOptionIf,
  psBindingNameSeen, psElabCheckBindingNames, psElabPatternWithLocal,
  psElabBindingPatternFields -> Ps.Internal.ElabData.<same leaf>.
- packages/backend-rust/src/Ps/BackendRust/RuntimePlan.lean: intrinsicHelpers,
  typeRequirements, exprRequirements, moduleRequirements ->
  Ps.Internal.RustRuntimePlan.<same leaf>.

The earlier Data source normalization made the original private leaf names
global. This migration corrects that visibility change. Prior qualification
receipts stay immutable and apply to their original graph identities.

Both source parsers now stop application parsing at unsupported private tokens,
so a modifier after a preceding definition refuses as a declaration rather than
becoming a spurious application argument. General private modifiers remain
unsupported. Both grammar tests cover start/middle/partial modifier refusals;
actual captured entry files exercise admission and API hiding in both grammars.
