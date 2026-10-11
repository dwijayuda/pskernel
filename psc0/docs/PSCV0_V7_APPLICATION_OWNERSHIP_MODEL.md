# PSCV0 v7 APP-04 — source-application ownership model and parser architecture

**Status:** pinned-source architectural diagnosis and axiom-free *abstract* model; the production parser/printer is **not** yet proved correct. Date: 11 October 2026. **Only source-language design authority:** [PSCV0 v7](../PSCV0_LANGUAGE_REFERENCE.md), SHA-256 `843940bd7f6a9b286e80b01d8c891a7e01b8868a9de7b05833fce32d49be6cd5`, Lean 4.35.0-rc4 source commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`. No source-language backward compatibility with older ProofScript editions.

## Concrete failure and invariant

The prototype parser already distinguishes `f x(y)`, `f(x(y))`, and `(f x)(y)` when reading certain `.ps` modules. But when the grouped candidate is rendered as a Lean source projection and re-read through `psPscv0TranslateReadable(false, true, ...)`, the parser rejects with a generic declaration-head error on the final numeric argument. This is **before** producing any ProofScript printing result. See [failed round-trip run 38122996299](https://github.com/dwijayuda/pskernel/actions/runs/38122996299) and [single-point diagnostic run 38124012051](https://github.com/dwijayuda/pskernel/actions/runs/38124012051). In contrast, a simpler source-tree comparison passed [38122847916](https://github.com/dwijayuda/pskernel/actions/runs/38122847916).

**Root in current source:** `psc0/packages/syntax/src/Ps/Syntax/ParseLean.lean`'s grouped *term* reader returns an inner term without consuming the following native-application suffix in that context. `psLeanApplicationWithArgument` also flattens a current `.app` node into its existing argument list. Once it has flattened `(f x) y` into `f x y`, neither a formatter nor a metadata-only span rewrite can reconstruct an intentionally grouped head. The APP-04 restriction is therefore **a parse-tree/ownership issue, not a failing-test expectation**. (Direct code inspection; a complete causality proof against every parser path is pending.)

The historical compiler's 69-source-file input is frozen by `pscv0-build-bridge.mjs`; silently altering the predecessor `ParseLean.lean` would break the qualified seed and source closure. **For the real PSCV0 compile path, reuse the existing parsed-module elaboration API directly:** do not make the old Lean source reader (or a replacement of it) a compiler prerequisite. A separately developed PSCV0-owned `.lean` reader is justified only if bidirectional migration tooling becomes a product requirement.

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
6. **Owned PSCV0 implementation, not a forked kernel or seed bypass.** Put the `.ps` source/group-aware parser/printer in `packages/syntax/src/Ps/Syntax/Pscv0/` (and the type-directed elaboration boundary where required). **Directly pass the generated, lowered `PsSyntaxModule` into `psCompilerPreparationStepParsedWithOrigins`**, whose result still goes through full typing, preparation, canonical admissions and independent kernel checking. Retain old bootstrap parser files **unchanged**. The emitted `.lean` is an independently verified projection and cannot rescue invalid v7 `.ps` input.

## Scope refinement — faithful source-to-Lean compilation, not an unnecessary inverse compiler

PSC0 v7 has **one authoritative source kind: `.ps`**. Lean `.lean` output is a generated projection/target and is independently typechecked and kernel checked with the pinned RC4 toolchain. The v7 language reference does **not** require PSC0 to implement an unrestricted reverse Lean-to-PS compiler as part of its ordinary self-host execution path. Such a converter remains useful as **optional migration/development tooling**, but is not a correctness precondition of emitting valid, semantically faithful Lean from the current PSCV0 AST. Do not accidentally make preserving the historical Lean-reader implementation an old-language compatibility requirement.

The first `Translate.ps` candidate's explicitly selected *bounded* PS/readable-Lean/PS round trip remains qualified and must not be falsified. However, a generic `psPscv0TranslateReadable(false,true, arbitraryLean)` property is **not yet demonstrated**, and the grouped-head experiment correctly exposed that the old Lean reader lacks the necessary source ownership. Its failing test is retained on its isolated branch as an honest **optional reverse-tooling gap**, not deleted or relabeled as a passing production invariant.

**Production APP-04 route:** a compositional *PS source AST → Lean target syntax* printer must preserve grouped function heads. The generated Lean must be accepted and independently checked by exact Lean RC4; the `.ps` canonical source parser/formatter must preserve APP-04 argument partition. These are the actual language compiler obligations. Source mapping and comments still require proper source representation and fail-closed behavior. Only if a reverse converter is subsequently promised should its own separate `.lean` reader and source-partition inverse be qualified. This distinction avoids duplicating Lean's parser in the small PSC0 compiler simply to satisfy an invented reverse-migration requirement.

The native-qualified implementation replaces the historical application-printer's `compound function = unsupported` shortcut with a bounded compositional **application-spine traversal** in the *PSCV0-owned* source module. It recursively prints nested callee/arguments with explicit semantic grouping and delegates only the non-application source families to their unchanged existing printer. It does not modify the 69 frozen compiler sources, erasure, kernel or target backend. The new native smoke constructs a well-typed group `(add(1))(2)`, checks the source PS canonicalization law, emits the exact Lean text `(add 1) 2` and submits a generated value theorem to Lean 4.35 RC4; separate mixed `f x(y)` / `f(x(y))` / grouped negative comparisons remain syntactic, not invented kernel proofs. The **native Lean RC4 correspondence has passed**, while the generated compiler's direct-AST elaboration and cross-platform emission require their own CI.

## Required executable and formal acceptance

**Actual source compiler property:** for admitted v7 `.ps` source trees `t`, `parsePS(printPS(t))` must preserve the selected *application partition/source grouping*, modulo documented redundant-brace canonicalization and regenerated positions. The generated `PsSyntaxModule` must elaborate and pass canonical admissions/kernel checking under the pinned selected environment. `printLean(t)` must be accepted by the **actual Lean RC4 frontend** and have corresponding checked meaning; full `parseLean(printLean(t))` through PSC0's historical reader is **not a source-compiler release requirement**. If a reverse conversion tool is explicitly adopted, establish its own scoped inverse separately. Exercise nested applications, operator operands, dependent types, theorem/tactic arguments, interpolated strings and selected `do` as their actual source features become supported. A lexical error does not satisfy an APP-02 rejection requirement.

**Semantic/property evidence:** separately compare elaborated Lean core/admission streams where source is well-typed; distinguish source grouping tests from kernel checking. Use generated rather than native-only PSCV0 reader, original error/refusal behavior, Linux/Windows checks, RC4 reference and retained source hashes. The eight abstract theorems in `ApplicationOwnershipModel.lean` establish only constructor/curry/group laws, **not** a production parser correctness theorem or proof of generated backend semantics. No proof holes or new axioms are allowed in the model.

**Resource behavior:** group/postfix/native parsing should consume input monotonically with bounded delimiter nesting and deterministic O(number of tokens) traversal/linear printer output where practicable. Do not copy the entire historical Lean parser or introduce another full scanner for each nested group. A nonterminating/ambiguous parse must refuse within budget instead of selecting another grammar.

## Direct generated AST admission boundary (new executable milestone)

> **Executed source-to-Lean evidence:** [run 38124980640](https://github.com/dwijayuda/pskernel/actions/runs/38124980640) at source `0e664233f90895e6baa90d377b2821e5fd4d01ce` **passed**. Eight abstract grouping theorems and the **actual PSCV0-generated Lean theorem `grouped = 3`** were checked on exact Lean 4.35.0-rc4 with no axioms. The v7 PS parser/formatter retained nested grouping and the emitted `.lean` contained `(add 1) 2`. This is native source/Lean correspondence, **not** yet the generated JavaScript/Windows direct-AST handoff qualification. The latter is a separate subsequent milestone with untrusted AST entering the existing compiler's ordinary elaboration and admission/checker path.


Repository study found an existing **pure checked-preparation handoff** in `packages/compiler/src/Ps/Compiler/Api.lean`: `psCompilerPreparationStepParsedWithOrigins(state, sourceModule : PsSyntaxModule)` calls `psElabModuleWithOrigins` on the supplied module and current environment, yielding source-local origins and a new local preparation state. It does **not** mint checked-core authority. Subsequent `psCompilerPreparationFinish`, canonical checked-admission encoding and the independent host/kernel checker remain mandatory. The old `psCompilerPreparationStep(state, leanText)` wrapper merely parses the text first.

The generated PSCV0 portable bootstrap already exports `psPscv0ParseSource(true, psText)` and `psPscv0LowerModule(surface)`, yielding the needed `PsSyntaxModule`. The proposed complete dataflow is:

```text
authoritative v7 .ps source
  -> generated PSCV0 JS lexer/parser -> source AST
  -> portable v7 lowering -> PsSyntaxModule (untrusted, source-linked)
  -> existing pure psCompilerPreparationStepParsedWithOrigins
  -> full elaboration, typechecking, environment/origin audit
  -> canonical admissions -> independently checked session -> target emission
                     \
                      -> generated readable .lean projection
                         independently checked by pinned Lean 4.35.0-rc4
```

The source, AST and import closure are pinned; the generated readable Lean text is **not** deserialized into compiler authority or silently re-parsed using the old Lean source grammar. The existing 20-module surface bootstrap can pass this in-memory AST to the retained compiler without regenerating the kernel. Both runtimes' AST representations must be proven compatible by *real generated JavaScript* cross-boundary elaboration, admissions and TypeScript 7.0.2 runtime checks. A mismatched constructor or missing imported environment causes explicit refusal—not a textual Lean fallback.

**New tests are architectural acceptance, not test-output repairs:** one well-typed `(add(1))(2)` source must lower directly to the `PsSyntaxModule` object, be independently kernel admitted, then emit/run a JavaScript value `3`; meanwhile pinned Lean RC4 must check the text projection and `grouped = 3` theorem. All evidence must use the actual same generated compiler artifact and source identities. This capability is **in development** until its Linux/Windows generated CI succeeds.

## Milestone disposition

- **M1 completed at source 8603f7dc** ([38120695522](https://github.com/dwijayuda/pskernel/actions/runs/38120695522)) and v7-only integrated **completed at 2394fc7d** ([38122341583](https://github.com/dwijayuda/pskernel/actions/runs/38122341583)); both bounded Linux/Windows/generated-reference qualifications passed. Neither is full v7 conformance or full compiler self-host.
- **APP-04 model stage:** abstract surface/core separation and source-view obligations defined here; independent pinned Lean RC4 proof result must be recorded from its actual CI run before claiming even model qualification.
- **Production parser stage:** not completed; the old grouped-head Lean-read limitation is *not* fixed by this document. Remove experimental ad hoc nested-application printer recovery only after a general source-tree printer/parser is independently qualified. Preserve its branch/history while designing replacement.
- **Next full compiler migration:** only after executable v7 APP-04 reader/property evidence and comment/source-origin handling is built. No kernel-admission authority change or old language compatibility.

