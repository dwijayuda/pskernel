# PSCV0 v7 APP-04 — source-application ownership model and parser architecture

**Status:** pinned-source architectural diagnosis and axiom-free *abstract* model; the production parser/printer is **not** yet proved correct. Date: 11 October 2026. **Only source-language design authority:** [PSCVO v7](../PSCV0_LANGUAGE_REFERENCE.md), SHA-256 `843940bd7f6a9b286e80b01d8c891a7e01b8868a9de7b05833fce32d49be6cd5`, Lean 4.35.0-rc4 source commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`. No source-language backward compatibility with older ProofScript editions.

## Concrete failure and invariant

The prototype parser already distinguishes `f x(y)`, `f(x(y))`, and `(f x)(y)` when reading certain `.ps` modules. But when the grouped candidate is rendered as a Lean source projection and re-read through `psPscv0TranslateReadable(false, true, ...)`, the parser rejects with a generic declaration-head error on the final numeric argument. This is **before** producing any ProofScript printing result. See [failed round-trip run 38122996299](https://github.com/dwijayuda/pskernel/actions/runs/38122996299) and [single-point diagnostic run 38124012051](https://github.com/dwijayuda/pskernel/actions/runs/38124012051). In contrast, a simpler source-tree comparison passed [38122847916](https://github.com/dwijayuda/pskernel/actions/runs/38122847916).

**Root in current source:** `psc0/packages/syntax/src/Ps/Syntax/ParseLean.lean`'s grouped *term* reader returns an inner term without consuming the following native-application suffix in that context. `psLeanApplicationWithArgument` also flattens a current `.app` node into its existing argument list. Once it has flattened `(f x) y` into `f x y`, neither a formatter nor a metadata-only span rewrite can reconstruct an intentionally grouped head. The APP-04 restriction is therefore **a parse-tree/ownership issue, not a failing-test expectation**. (Direct code inspection; a complete causality proof against every parser path is pending.)

The historical compiler's 69-source-file input is frozen by `pscv0-build-bridge.mjs`; silently altering the predecessor `ParseLean.lean` would break the qualified seed and source closure. A PSCV0-owned term reader is needed instead of weakening the immutable-bundle check or adding a JS-only translation fallback.

## Proposed source-term model

Source term syntax retains four separate concepts: **atom**, **group**, **native whitespace application**, and **adjacent postfix call**. The group is a *surface-only* construct: Lean core/Pi/function application remains unary. The abstract Lean model in [ApplicationOwnershipModel.lean](../test/pscv0/reference/ApplicationOwnershipModel.lean) formalizes these ideas, and checks the expected application trees without importing untrusted parsing/printing or kernel implementation.

| v7 source | Source-application ownership | Abstract core before type-directed elaboration |
|---|---|---|
| `f x(y)` | native `f` applied to postfix `x(y)` | `app f (app x y)` |
| `f(x(y))` | postfix `f` applied to postfix `x(y)` | `app f (app x y)` |
| `(f x)(y)` | postfix applied to grouped native `(f x)` | `app (app f x) y` |
| `f(x) y` | native applied to preceding postfix `f(x)` | `app (app f x) y` |

Groups affect **source argument partition, editing, named/default/implicit elaboration context, source spans, and canonical formatting** even though an explicitly typed and fully elaborated Lean function application is curried. Do not add a `group` term to kernel Core or treat parentheses as runtime arity. The two abstract trees in the third and fourth rows have the same core but remain distinct source trees; a normalized source printer must document when it preserves versus canonicalizes redundant grouping.

## Correct parser/formatter architecture

1. **Context-sensitive v7 lexer and grammar ownership.** Distinguish declaration binders and command/tactic fresh-term positions from an already-completed expression's continuation. Only the latter triggers `PSCV0-APP-02` on a trivia-separated `(`. Native Lean `.lean` projection has a separately selected token spelling, not an older `.ps` compatibility profile.
2. **Parse at two precedence levels.** `parseAtom` recognizes a grouped expression without discarding its grouping boundary; `parsePostfix` consumes adjacent calls before `parseNativeApplication` consumes whitespace operands. The parser returns a selected source-term tree with *source-group and application-kind* ownership, not a flat application list as its sole representation.
3. **Keep exact source spans and token identities.** Parentheses must carry the span from opening `(` to closing `)`; the source AST must retain the group before lowering. Comments/trivia and line breaks must survive or cause a declared fail-closed formatting limitation. No position-comparison heuristic may serve as a hidden semantic group tag.
4. **Lower only after source grouping and overload context are resolved.** Convert selected source APP nodes into normal `PsSyntaxTerm.app` with the intended nesting/arity partition and ultimately Lean unary applications; record the deterministic RC4 name/typeclass/default environment identity. Do not normalize grouped heads into a flat syntax argument list before elaboration.
5. **Print with parent-category information, not ad hoc recovery on `unsupportedApplication`.** A compound **callee** is parenthesized explicitly; a comma-call argument is one term, and tuple and Unit use their single-argument notation. A Lean projection of a grouped callee is `(f x) y`; a ProofScript projection can be `(f(x))(y)`. Both must re-read to the intended source tree modulo documented canonicalization, never silently reinterpret two arguments as one tuple.
6. **Owned PSCV0 implementation, not a forked kernel or seed bypass.** Put the source/group-aware parser/printer in `packages/syntax/src/Ps/Syntax/Pscv0/` (and the type-directed elaboration boundary where required). Retain old bootstrap parser files **unchanged** during this milestone; explicit `.lean` source projection is a different selected grammar category and cannot rescue invalid v7 `.ps` input.

## Required executable and formal acceptance

**Parser/serializer property:** for admitted source trees `t`, `parsePS(printPS(t))` and `parseLean(printLean(t))` must preserve the defined *application partition and selected source grouping*, modulo exact documented redundant-brace canonicalization and ignoring only regenerated source positions. The same law must hold in nested applications, operator operands, dependent types, theorem/tactic argument terms, interpolated strings and the existing do subset. A lexical error does not satisfy an APP-02 rejection requirement.

**Semantic/property evidence:** separately compare elaborated Lean core/admission streams where source is well-typed; distinguish source grouping tests from kernel checking. Use generated rather than native-only PSCV0 reader, original error/refusal behavior, Linux/Windows checks, RC4 reference and retained source hashes. The eight abstract theorems in `ApplicationOwnershipModel.lean` establish only constructor/curry/group laws, **not** a production parser correctness theorem or proof of generated backend semantics. No proof holes or new axioms are allowed in the model.

**Resource behavior:** group/postfix/native parsing should consume input monotonically with bounded delimiter nesting and deterministic O(number of tokens) traversal/linear printer output where practicable. Do not copy the entire historical Lean parser or introduce another full scanner for each nested group. A nonterminating/ambiguous parse must refuse within budget instead of selecting another grammar.

## Milestone disposition

- **M1 completed at source 8603f7dc** ([38120695522](https://github.com/dwijayuda/pskernel/actions/runs/38120695522)) and v7-only integrated **completed at 2394fc7d** ([38122341583](https://github.com/dwijayuda/pskernel/actions/runs/38122341583)); both bounded Linux/Windows/generated-reference qualifications passed. Neither is full v7 conformance or full compiler self-host.
- **APP-04 model stage:** abstract surface/core separation and source-view obligations defined here; independent pinned Lean RC4 proof result must be recorded from its actual CI run before claiming even model qualification.
- **Production parser stage:** not completed; the old grouped-head Lean-read limitation is *not* fixed by this document. Remove experimental ad hoc nested-application printer recovery only after a general source-tree printer/parser is independently qualified. Preserve its branch/history while designing replacement.
- **Next full compiler migration:** only after executable v7 APP-04 reader/property evidence and comment/source-origin handling is built. No kernel-admission authority change or old language compatibility.

