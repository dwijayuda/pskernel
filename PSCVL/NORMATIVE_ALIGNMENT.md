# PSCVL alignment with authoritative ProofScript PSCV Normative RC v2

**Canonical authority (verified byte-identical with user-supplied reference):**
`pscv0/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md`, Git blob
`208f128c13be2e07fde25ca413641a48df214324`,
SHA-256 `4c02626fd0b991e8526c64b65f4ffb66b9ce7b688298e82fb0309802a263db71`.

**Release:** `PSCV-RC-v2`, `pscv-v1`, `pscv-closed-v1`,
`PSCV-VERIFY-v1`; Lean 4.35.0-rc3 commit
`470d5ce1400764999581fd26d5d72b00d990b0f4`.

**Authority hierarchy:** Appendix A (owned grammar) + §20.2 (Standard proof grammar)
+ Appendix I (ONLY exact mapped Lean families). Lean parsing success alone
is **not** ProofScript grammar conformance. No source-level macro or arbitrary
Lean syntax may silently expand the Standard source language.

## Audit of discovered deviations

| Reference requirement | Prior behavior | Current disposition |
|---|---|---|
| A.14/A.18 `do { ... }` with newline-only elements | Accepted Lean indentation-only `do` | Strict `check` rejects `doSeqIndent`; preview retained separately |
| A.15/§20 `by { ... }` with newline-only StandardTactic | Accepted indentation-only Lean `by` | Strict `check` rejects unbraced tactic sequence; basic positive/negative fixture |
| A.8 single-term definition body | Accepted native Lean equation-style definitions | Strict `check` rejects `declValEqns`; named supported `function` braces retained |
| §9 + A.7 strict implicit ASCII `{{x: T}}` | Owned syntax used Unicode `⦃x⦄` | Replaced with canonical `{{x:T}}` syntax; pinned Lean receives equivalent strict binder |
| §9 instance binder `[C α]` | Owned syntax only supported `[name: C α]` | Added anonymous instance-implicit binder |
| §24.5 attributes `simp`, `instance`, `default_instance` | Also admitted `priority` as standalone name | Removed `priority` from allowed attributes. The two development-only `pscv_export`/`pscv_type_spec` annotations are NOT normative PSCV attributes or approved-spec evidence |
| A.6 braced conditionals and single-term bodies | Finite owned variants implemented | Bounded supported fragment only, full precedence/AST closure pending |
| A.11 braced single-scrutinee match | Native Lean match/equation syntax accepted | Strict rejects known native nonconforming source; owned canonical match translation remains missing |
| A.18 `for` / `while` braced bodies | Native Lean `for .. do`/`while .. do` preview | Full owned braced loop grammar/verified equivalence still missing; preview is never PSCV conformance |
| A.9 named calls / trailing commas | Only positional `f(a,b)`; no full suffix grammar | Missing, fail closed when parser cannot express it; full named elaboration must match Chapter 22 |
| A.2 modules/import header, §6/§7 | Source imports rejected | Missing until deterministic certified import graph and exact Standard environment are implemented |
| §5 lexical discipline, A.6 full nested terms | Depends on Lean lexer/parser with some exclusions | Not yet a complete closed grammar; must implement UTF-8/BOM/CRLF/tab rules and recursive whitelist |
| §20 complete Standard tactic variants | Broad Lean proof parsing in preview | Strict checks known nonconforming tactic forms; complete chapter-20 grammar and all PS-CONF cases pending |
| A.18 `verify`, `reads`, `modifies`, `old`, structure invariant | Partial `given`, `requires`, `ensures`, concrete `errors`, `ghost` | Unimplemented families remain unsatisfied; no fake semantic fallback |
| §24/Appendix K ordered Standard registries / PS-UNIFY-v1 | Official Lean elaboration | Exact registry manifest/hash is PENDING in normative RC; **cannot** claim complete Standard semantic conformance |
| §30 `PSCV-CERT-v1` compile gate | Prototype check emits nothing | Stays uncertified and no executable emission |

## Explicit implementation/product identities

- `check`: **strict RC-v2 source fragment**. Its success means pinned Lean
  elaboration plus prototype policy success, **not** final `pscv-v1` conformance.
- `check-preview`: **Lean-powered proof-of-concept**, admits additional
  explicitly non-normative Lean syntax, no PSCV Standard claim.
- `syntax-kinds`: development-only, enumerate parsed AST node kinds.

Source extension and proof policy are closed. Exact Appendix A `SourceFile`
closure is not yet complete: no final PSCV release status, `.olean`/
executable emission or `PSCV-CERT-v1` is authorized.

## Required release-quality acceptance

1. Grammar ownership: implement all Appendix A productions, only Appendix-I
   mapped external syntax, and every Chapter-20 tactic variant. Prohibit all
   unmapped AST forms before source elaboration; do not rely on a denylist
   alone. Include lexer, layout, comma/brace, call ownership and name resolution.
2. Grammar semantics: prove/test equivalence of each owned macro lowering
   to the normative meaning, rather than to whatever Lean happens to accept.
3. Conformance evidence: map every Section/Appendix-J `PS-CONF-*` and
   `PSCV-CONF-*` case to executable positive and negative evidence; negative
   tests must assert *why* they reject.
4. Environment: generate, provenance-validate and freeze
   `STD-ENV-PSCV-V1-L435RC3-RC1.json` and the verified-effect registry
   under pinned semantics; custom deterministic instance/unifier/coercion
   algorithms must not be replaced with unrestricted Lean ones.
5. Certification: integrate approved specification identities, proof/effect/
   assumption/import/erasure closure, replay, and codegen preservation.
   Until then **no verified executable emission**.

The existing `README.md` and `CONFORMANCE.md` are living implementation
status references, not substitutes for the uploaded normative specification.
