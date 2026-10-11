# Native source operators

One precedence reader owns expression tails. A closed registry selects equality
(50, non-associative), conjunction (35, right), disjunction (30, right),
implication (25, right), equivalence (20, non-associative) and matches (50).
Negation reads an operand at precedence 40. ASCII aliases preserve the same tree.
Adjacent lexer tokens can form registered spellings; whitespace cannot join them.

Notation lowers to ordinary rooted calls; implication lowers to Pi. Application,
expected types, universes, scope resolution and kernel checking remain shared.
Generated calls are syntactically owned; original operand trees and spans remain
visible to the recursive APP-02 check. Grouping and all call/binder boundaries
continue through the existing readers. The old matches/arrow-only tail is removed.

Precedence follows Lean RC4 c29b6dda4f7c20e3eeaa717c4e565663c5cfa364:
src/Init/Notation.lean, src/Init/Core.lean, src/Init/NotationExtra.lean and
src/Lean/Parser/Term.lean. This closes the selected logical notation path;
arithmetic/order/operator classes, existential binders, and other selected
notations still require implementation. Source printers currently render the
equivalent rooted calls, not original operator spellings.

Validation extends the existing composite with precedence/associativity and
Unicode/ASCII equivalence, plus non-associative and operand APP-02 refusals.
Exact qualification is recorded after the cloud run in AI_WORK_STATE.md.
