# M2+A: live selected-surface registries

Status: draft, awaiting qualification and an independently observed surface digest.

Pinned Lean 4.35.0 source study: `Lean/Parser/Extension.lean` owns scoped parser entries, `Lean/Elab/Tactic/Basic.lean` owns keyed tactic dispatch, `Lean/Elab/Deriving/Basic.lean` owns selected deriving handlers, and `Lean/Environment.lean` distinguishes import identity from imported extension state. PSCV0's closed profile needs immutable dispatch tables rather than dynamic host extensions.

The tactic reader now dispatches through its enumerated closed table. The strict independent manifest checks names, order and handler identity. It also checks the actual deriving parser vocabulary against the selected elaborator handlers. Typed do's Id/Option/Except family selection shares one table with the manifest audit; source effects now accurately report all three already implemented families instead of a stale Except-only rewrite description.

Existing declaration, class-parameter, instance/default priorities, aliases and reducibility hashes remain mandatory. Operator notation already uses its live enumerated registry. No new tactic, deriving handler or effect is admitted by this refactor; unsupported forms remain errors.

A complete release environment manifest additionally needs its actual per-project public/private import graph, exposure policy, runtime/effect/assumption closure and proof-extension availability. Future Phase C/D capabilities must be explicit pending/unavailable entries, not represented as implemented by this selected table audit. C5/source-info retention remains metadata outside all semantic hashes. Existing positive/negative parser, proof, deriving, effect and module integration gates provide regression evidence; this change does not add a redundant test suite.
