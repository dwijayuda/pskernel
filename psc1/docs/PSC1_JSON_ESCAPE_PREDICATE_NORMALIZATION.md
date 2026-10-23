# JSON escape predicate normalization

Current shared-codec TypeScript replay 39912539573 samples the final 30 seconds
of an exact 220-second actual G2 request. It retains generator/thunk-heavy
psJsonCharNeedsEscape paths. Replace its lazy Boolean disjunction with explicit
branches to avoid constructing the lazy right-operand closures on each character.
The source helper retains its type and every result. A quantified official Lean
equality theorem against the retained original predicate and 1114112 native
code-point inputs must pass before quotation regressions, source audits or
actual generated compiler qualification. Preserve all quote bytes, order,
Unicode, errors, fuel, cache capacity, IR validation and independent checking.
This is a shared source optimization; no backend-specific compiler or new ABI.
G1, G2/G3 and fixed points for this new source require fresh evidence.
