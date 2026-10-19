# New-only ProofScript grammar transition

Initial F application: [`9ee0b1fd38dd1456a187d4675f9027440a989f2d`](https://github.com/dwijayuda/pskernel/commit/9ee0b1fd38dd1456a187d4675f9027440a989f2d). This is the initial attempt identity; any qualifying revision and its evidence are recorded separately below.

Status: the bounded new-only grammar and projection implementation passed full R2 compiler qualification, independent provider acceptance and verified cold recovery. [selection commit e65606397fb679d7cb96f4f0e92700a6cf0944a6](https://github.com/dwijayuda/pskernel/commit/e65606397fb679d7cb96f4f0e92700a6cf0944a6) explicitly selects the exact R successor. F at `fcd875c8f38db4b0524090bd10c7c2fd5024053d` subsequently earned its own source/runtime and provider qualification in [F run 37947341800](https://github.com/dwijayuda/pskernel/actions/runs/37947341800). The bounded source grammar remains the R2 edition.

- Decision date: 2026-10-09.
- User decision: use the new `.ps` syntax only; do not maintain a current backward-compatible `.ps` parser.
- Audited implementation baseline: `5e3a991088aaa735c8f324c4e70a7a3dee4cd69a`.
- Supplied reference: `ProofScript_PSCV_Language_Reference_NORMATIVE_RC_v2_Lean4.35rc3 (1)(6).md`.
- Reference SHA-256: `4c02626fd0b991e8526c64b65f4ffb66b9ce7b688298e82fb0309802a263db71`.
- Reference size: 401,569 bytes; 8,546 lines.
- Scope: current `psc0` source parsing, canonical printing, owned fixtures/tooling, and self-host source consumption. Provider/kernel implementation, metatheory and the PSCV verification implementation are separate work.

## Decision and exact claim

Replace the current `.ps` parser/printer format with a bounded subset of the supplied reference's new base syntax. Migrate its owned fixtures and tooling together. Do not keep a current legacy `.ps` parser, compatibility mode, silent fallback, or old canonical-output option.

Historical S0/A recovery remains reconstruction of immutable **old repository revisions** under their original identities. Those old revisions are not current grammar modes. The separate `.lean` frontend remains the supported native-source frontend because the compiler's handwritten portable implementation is still authoritative `.lean`.[SH1]

The resulting claim is a bounded new-syntax implementation. It is not full `ps-standard-0.9-r3`, `psc2-standard-language-v1`, `pscv-v1`, or Lean 4.35.0-rc3 conformance.

The attachment itself is a normative design release candidate. Its header leaves Standard/verification manifest regeneration and implementation conformance pending; Appendix K.4 requires the regenerated manifest, final digest and conformance evidence before final PSCV compiler claims (reference 3–28, 8117–8148). A new parser cannot supply those semantic and verification obligations.

The current lane retains Lean 4.34.0, Node 22.23.3 and TypeScript 7.0.2 for both current compilation and the proven native selected-R recovery route. S0/A's original TypeScript 5.8.3 producer metadata and recovery recipes remain archived evidence; current tooling does not execute them. A remains the immutable historical parent; [selection commit e65606397fb679d7cb96f4f0e92700a6cf0944a6](https://github.com/dwijayuda/pskernel/commit/e65606397fb679d7cb96f4f0e92700a6cf0944a6) explicitly selects R. Strict SH/1 and PSCV remain inactive.[SH1][TS7] Source grammar identity and its qualification evidence must be recorded separately from those semantic/toolchain identities.

## Evidence and implementation ownership

The initial audit directly inspected the supplied reference and immutable GitHub source. A read-only EBNF-name scan identified the reference-integrity issues below. Drafts were prepared through Git data without local repository checkout, build or tests. Subsequent qualification ran in GitHub Actions against the exact committed implementation.

R2 source `fe2560aba0f347b1caf8d000d371464642d44f23` passed [run 37925722635](https://github.com/dwijayuda/pskernel/actions/runs/37925722635), compiler job `113804052074`, and provider job `113827136830`. N1 round-tripped all 61 modules through the new PS grammar; C2/C3 matched on all four required products. Native original-IR checking accepted 56,391 expressions with zero findings. The provider accepted four distinct admission streams covering eight C2/C3 artifact roles. The [qualification index](qualification-evidence.json) and [complete compiler/provider logged evidence](grammar-migration-compiler-evidence.json) preserve the exact scope and identities. The separate [cold-recovery receipt](grammar-migration-cold-recovery.json), SHA-256 `2aa93517b848da1493386ab9be50527275fe1a7a1c7e12f422d8d8431d8d9f1d`, and [selection commit e65606397fb679d7cb96f4f0e92700a6cf0944a6](https://github.com/dwijayuda/pskernel/commit/e65606397fb679d7cb96f4f0e92700a6cf0944a6) now satisfy R's recovery/selection requirements. F qualification has its own separate evidence in [IMPLEMENTATION.md](IMPLEMENTATION.md#f-checkpoint-ordinary-worker-parameters); it is not inherited from those R records.

The coordinated implementation owns:

| File or area | Responsibility |
|---|---|
| `packages/syntax/src/Ps/Syntax/Lexer.lean` | Strict current PS input/trivia path and diagnostic variant; the separate Lean scanner entry retains its native-source behavior. |
| `packages/syntax/src/Ps/Syntax/ParseProofScript.lean` | New-only PS sequences/headers, grouped and native application, strict record commas, declaration aliases/body ownership, explicit unsupported forms. |
| `packages/syntax/src/Ps/Syntax/PrintProofScript.lean` | New-only canonical output; comma declaration groups, newline/bar sequences, grouping and explicit Unit spelling. |
| Elaboration and error rendering | Preserve empty-argument origin and refuse unsupported completion; render newly explicit lexical/source-print errors. |
| Owned tests, scripts and workflow corpus | Migrate source strings and exact expectations atomically; validate raw new-syntax input through native and generated compilers. |
| Configuration, receipts and source snapshots | Record the grammar/reference identity in current artifacts and qualification, preserving immutable historical recovery identities. |

The shared `ParseCommon` record parser must not be globally changed: it is also used by the separate Lean frontend. The new PS parser owns mandatory-comma record behavior explicitly.

## Finite syntax scope

The first slice deliberately reuses the existing supported semantic AST and normalization/erasure core. It changes current PS source spellings and necessary source ownership, while refusing unsupported broader features.

| Family | New-only bounded behavior | Reference and baseline reason |
|---|---|---|
| Complete files/imports | Ordinary import prefix, then supported declarations; normalized newline/EOF command boundaries and complete consumption. No public import, namespace/section or source-extension fallback. | A.1/A.2, 5991–6210. Baseline `ParseProofScript` 36–54, 1325–1445 and `Ast` 66–104 provide the smaller module model.[PS][AST] |
| Structural whitespace | One leading BOM allowed; ASCII SPACE/LF and CRLF outside literals/comments; TAB, lone CR and a later/repeated BOM rejected explicitly. Token offsets remain offsets into the original source. | Chapter 5, 741–816. Baseline `Lexer` 49–57 accepts TAB/CR generally, so new PS validation has its own entry path.[LEX][CURSOR] |
| Literal/comment boundary | Retain the supported literal scanner and Lean-style line/nested-block comments. Structural-whitespace restrictions do not apply inside literals/comments. Full raw UTF-8 byte validation belongs at the host input boundary; a String-only scanner cannot independently establish it. | Chapter 5. The bounded implementation must not overclaim complete external Lean lexical conformance. |
| Explicit declaration groups | Non-explicit prefix, followed by at most one nonempty comma-oriented explicit parameter group. Preserve binder order; reject old repeated explicit groups and interleaving after the explicit group. | A.2/A.7, 6101–6194 and 6498–6526. Baseline accepts repeated one-name groups.[PS] |
| Value declarations | Typed `def`, existing base `partial def`, typed theorem declarations, annotated parameterless `const`, and `function` with a nonempty typed explicit group. Aliases lower to existing definition AST. | Chapter 8, 1123–1418. Full PSCV is inactive: its partial rejection is not imported into this bounded base-syntax change. |
| Result/default inference | Require existing explicit declaration/lambda typing. Reject omitted result types, default parameters, named call arguments and empty function headers until their semantics are separately implemented. | A.2/A.7/A.9 permits more than the supported AST/elaborator; `Ast` stores a type for every lambda binder.[AST] |
| Declaration-body braces | Exactly one supported term; direct record ownership wins when the opening brace begins a record. A wrapper around a record is a nested brace pair. | Chapter 8, 1269–1294; A.8, 6528–6539. Braces do not introduce statement execution. |
| Calls and grouping | Typed primary/group parsing, repeated adjacent call suffixes, then native whitespace application with a source gap and deeper indentation on continuation lines. Preserve outer grouping spans for adjacency. | Chapter 5.7; A.5/A.6, 6282–6495. Baseline supports one adjacent call on a simple head only.[PS] |
| Empty calls | Parse `f()` with zero source arguments and `f(())` with one Unit argument. Refuse unsupported default/automatic completion during elaboration. Printer never compresses explicit Unit into empty invocation. | Chapter 10, 1806–1854. Baseline parser 162–169 and printer 194–195 intentionally collapse these forms; that old meaning is removed from current PS.[PS][PRINT] |
| Tuples and arbitrary result projection | Tuple terms/patterns and a suffix such as `f(x).field` remain outside this slice. In particular, `f (x, y)` must not be reinterpreted as the two-argument call `f(x, y)`. Existing dotted-name projections remain supported. | A.6 distinguishes tuple/native-application/call ownership. A dedicated expression projection/tuple path is additional work. |
| Let | A complete initializer followed by a required newline and the body. Parenthesize nontrivial initializers in canonical output to make nested ownership clear. No semicolon separator. | A.6 `TermBodySep`, 6442–6471. Baseline let requires a semicolon.[PS] |
| Records | Commas between field/value entries are mandatory, one trailing comma allowed. No PS fallback to the shared Lean parser's adjacent-assignment rule. | A.6/A.10 and B.1. Baseline `ParseCommon` 215–291 accepts adjacent named assignments.[COMMON] |
| Structure fields | Existing supported fields, separated by newlines inside braces. No comma or semicolon declaration-field separator. | A.10/A.12/B.3. Baseline `ParseProofScript` 1000–1043 and printer 405–422 require/emit semicolons.[PS][PRINT] |
| Inductives/flat match | Existing supported regular constructor and flat-pattern semantics; comma-oriented constructor parameter headers; bar-separated constructors/alternatives without semicolons. Empty unsupported layouts, nested/tuple patterns and richer indexed constructor forms remain outside the declared slice. | Chapters 13–15; A.11. The reference's constructor-header ownership issue is called out below. |
| Typed callbacks and arrows | Typed native lambda-binder sequences, grouped callbacks/callees and the existing dependent/nondependent arrow path. No implicit switch to omitted-domain inference or a general overloaded-operator environment. | A.6; baseline PS handles typed lambdas in term/call-argument contexts, while the separate Lean application path is narrower.[PS][LEAN] |
| Conditional | Existing braced Boolean conditional and exactly one term per branch. No host truthiness or new proposition/Decidable mode. | Chapter 10/A.6. Broader conditional elaboration is a separate capability. |
| Do | Reject PS `do` explicitly in this subset. Migrate the old modeled compiler-effect examples to explicit `compilerBind`/`compilerPure` calls where their previous semantics remain intended. | Baseline do lowers only to those names, not general Monad/Except or verified effects (`ParseCommon` 69–95). Reusing that ad hoc lowering for new r3 do would misstate its semantics.[COMMON] |
| Broader Standard/PSCV | Classes, instance synthesis, coercion/default registries, opaque/axiom/abbrev/scope commands, scientific runtime forms, contracts, tactics, verified mutation/loops/ghost state and certificate gates remain explicit unsupported capabilities. | Appendix A/C and Chapters 2, 21, 30, 32. Parsing a keyword cannot establish these semantics. |

### The empty-call change is semantic, not cosmetic

Under the old current parser, the AST for an empty call contains a Unit argument. Under the new rules it must contain an empty source argument list until completion semantics are applied.

A parser-only change would still be wrong if the printer printed a real Unit argument as empty invocation, or if elaboration silently inserted Unit for a required argument. Parser, printer, elaboration refusal and the corpus must agree on this boundary. Explicit Unit calls remain the supported way to call a required Unit parameter in the first slice.

### Current source grammar is replaced atomically

The compiler exports the current edition, new-only mode and exact reference digest as ordinary String constants. Current host PS readers and producers verify those declarations before using a supplied generated compiler; an old A compiler cannot emit an old-format project while the host labels it as the new edition. Immutable A recovery continues through its explicit raw-Lean path.

New reader, new printer, source fixtures, canonical-output expectations and current workflow/source metadata form one change set. There is no intermediate release that emits one grammar while consuming the other.

The old selected seed can compile the new implementation because the implementation remains written in the seed's accepted `.lean` authoring forms. That fact does not establish that an old canonical `.ps` stream can be read by the new compiler. Qualification and recovery must distinguish raw Lean implementation consumption, current new-format canonical source and historical old-revision recovery.

## Reference issues and adoption boundary

These are findings about the supplied attachment, not edits to it:

1. `ContractClause` is defined at both 3398 and 6735; `PSCVEffectClause` at 3402 and 6779. This violates the single-definition/authority rules at 404–408 and 6007–6009. The effect variants additionally differ between `Identifier` and `BinderIdent` for the error binder.
2. `DefinitionBody` at 6532–6533 appends `WhereBody?`, but `WhereBody` at 6626–6627 supplies no leading `where` token. The intended `where { ... }` spelling needs an explicit grammar path.
3. Chapter 9's owned comma-group rule at 1427–1439 includes constructor headers. A.11 instead refers to `ConstructorBody` through the native Lean constructor mapping (6030; 6578–6580). This slice follows the explicit owned comma-group rule for its supported regular constructors; a corrected reference should spell that path out before claiming complete grammar closure.
4. The historical base-edition nonretroactivity statements at 116 and 245 need clear scope beside the broad semantic-pin wording at 414. Header/K.4 use the manifest name ending `RC1`, while defaulting text at 3964 still names an `RC1-v6` variant. The final manifest digest is pending.
5. Chapter 20.5's reference-integrity claim and Appendix J.2's implementation-conformance deferral are different claims. The duplicate productions need correction in the former; neither establishes current compiler support.

A limited EBNF-name scan found 197 distinct definition names and the two duplicate names above. Apart from aliases declared by A.1, no additional identifier-shaped unresolved nonterminal was found. This is not a proof of grammar unambiguity, reachability, external-locator correctness or semantic completeness.

Local-where declarations and contracts are not enabled by this change, so their unresolved grammar paths do not block the bounded current-source transition. The supplied file remains identified by its original hash; it has not been silently rewritten to match an implementation.

## Qualification and efficient migration plan

1. **Freeze the new-only scope.** Record the supported rows above and nearest refusals. Keep full Standard, strict SH/1, PSCV and Lean4.35 migration claims separate.
2. **Integrate parser, printer and owned callers together.** Remove current old-format expectations rather than add compatibility switches. Keep the portable implementation A-consumable in Lean syntax.
3. **Review ownership before execution.** Check empty-call/Unit distinction, contextual declaration names, comma groups and binder order, body-record ambiguity, nested let values, adjacency across comments/whitespace and command/field boundaries. Preserve explicit resource exhaustion.
4. **Run one planned focused corpus.** Include successful new forms and nearest malformed/unsupported cases, plus the actual 61-module Lean-to-new-PS-to-Lean canonical correspondence. Source examples must be consumed as raw authored input, not rewritten by a host preprocessor.
5. **Qualify the coherent checkpoint.** N1 and C1/C2/C3 must consume the new syntax, agree on the declared current deterministic products and pass the bounded runtime/IR evidence. Exact-stream provider acceptance is separate and does not activate PSCV.
6. **Record identities and migrate the finite remaining families.** Include reference digest, source grammar/capabilities, parser/printer/normalizer and source closure in current evidence/cache identities. Preserve original producer/recovery identities for immutable S0/A. Select a replacement authoring seed only through an explicit recoverable-seed decision.

A successful transition means the current printer emits only the current bounded new grammar, generated compilers consume that grammar, the old current PS spellings are rejected, checked semantics and runtime behavior agree for the supported families, and the evidence accurately reports its scope.

The practical helper migration can then use this qualified language subset without requiring all Standard or PSCV features. Moving all handwritten compiler authority to `.ps` remains a separate source-authority decision. PSCV's own M0–M7 sequence in Appendix M.7 (8497–8546) is not the same milestone numbering as this repository's SH/1 migration.

## Immutable audit references

[PS]: https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/syntax/src/Ps/Syntax/ParseProofScript.lean
[COMMON]: https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/syntax/src/Ps/Syntax/ParseCommon.lean
[LEX]: https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/syntax/src/Ps/Syntax/Lexer.lean
[CURSOR]: https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/syntax/src/Ps/Syntax/Cursor.lean
[AST]: https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/syntax/src/Ps/Syntax/Ast.lean
[PRINT]: https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/syntax/src/Ps/Syntax/PrintProofScript.lean
[LEAN]: https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/syntax/src/Ps/Syntax/ParseLean.lean
[SH1]: https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/docs/selfhost-language/SPEC.md
[TS7]: https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/docs/selfhost-language/TYPESCRIPT7.md
