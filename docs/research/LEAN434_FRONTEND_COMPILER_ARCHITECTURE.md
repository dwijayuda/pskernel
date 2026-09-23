# Lean 4.34 frontend/compiler architecture study

Status: architecture guidance for ProofScript implementation.
Lean source studied: `leanprover/lean4` tag `v4.34.0`.
ProofScript semantic target remains Lean 4.34.0.

## Why this study exists

ProofScript should reuse Lean's semantic boundaries without copying Lean's full extensible syntax system or native compiler architecture. The goal is a small fixed language with a maintainable TypeScript implementation.

## Lean boundaries observed

### Parser is not the elaborator

Lean keeps term parsing in modules such as:

- `src/Lean/Parser/Term.lean`
- `src/Lean/Parser/Command.lean`

Term parsing has separate productions for application, lambdas, lets, matches, type ascription, tuples, and other terms. Declaration parsing separately dispatches definitions, theorems, structures, inductives, and related command forms.

ProofScript rule:

> Syntax packages create source AST plus feature ownership. They do not decide types, kernel validity, runtime representation, or target code.

### Elaboration is a distinct semantic layer

Lean elaborates terms and declarations in specialized modules, including:

- `src/Lean/Elab/Term.lean`
- `src/Lean/Elab/Match.lean`
- `src/Lean/Elab/Structure.lean`
- `src/Lean/Elab/Inductive.lean`

Match elaboration has dedicated discriminant/motive/alternative handling. Structure elaboration ultimately participates in inductive elaboration. Inductive elaboration checks constructor shape and parameters while relying on the kernel for trusted validity such as positivity/universe correctness.

ProofScript rule:

> Do not grow one universal checker switch for structures, inductives, matches, tactics, contracts, and ordinary terms. Each semantic family gets a focused elaboration/checking module.

### Surface functions lower to smaller core constructs

Lean source supports multi-binder `fun`, applications, lets, and rich matching syntax, while the logical core is much smaller.

ProofScript rule:

> Preserve the reference surface in the AST, then elaborate/lower into a smaller semantic representation. Do not encode source text directly into backend-specific strings.

### Compiler IR is not kernel Expr

Lean has a separate compiler pipeline under `src/Lean/Compiler`. `Lean.Compiler.IR.Basic` defines runtime-oriented expressions/declarations and `FnBody.vdecl` for lexical let-like bindings. `Lean.Compiler.IR.ToIR` lowers from an earlier compiler representation into IR.

ProofScript rule:

```text
source AST
  -> checked HIR / elaborated logical form
  -> executable compiler IR
  -> TypeScript backend
  -> TypeScript compiler
  -> JavaScript
```

The TypeScript backend must consume compiler IR only. It must not consume raw `.ps` source or become a second type checker.

### Kernel and compiler correctness are separate claims

Lean's elaboration/compiler layers may be large; trusted logical acceptance is still based on kernel checking.

ProofScript rule:

- parser success is not proof verification;
- software-profile type checking is not proof verification;
- generated TypeScript type checking is not proof verification;
- pskernel admission is the trusted proof/declaration check;
- compiler semantic preservation is a separate future assurance problem.

## ProofScript package mapping

```text
@proofscript/syntax
  source ownership + fixed v0.6.1/v0.7 grammar + AST

@proofscript/meta / @proofscript/elab
  expected types + metavariables + dependent elaboration + proof-term construction

@proofscript/language
  software-facing checked HIR and incremental language service

pskernel
  trusted declaration/proof checking

@proofscript/compiler-ir
  executable, proof-erased/runtime-oriented representation

@proofscript/backend-ts
  compiler IR -> TypeScript only

TypeScript compiler
  TypeScript -> JavaScript + .d.ts + source maps
```

## Anti-spaghetti invariants

1. Parser modules do not import language checker, compiler IR, backend, CLI, or kernel internals.
2. Checked HIR modules do not format TypeScript/JavaScript.
3. Backend modules accept compiler IR, never raw ProofScript source.
4. CLI routes commands and orchestration; language semantics live in packages.
5. Match, structure, inductive, theorem/tactic, contracts, and effects get dedicated modules when introduced.
6. No feature is accepted only because a regex/string emitter happens to understand it.
7. Every added language feature must have:
   - reference/source authority;
   - AST representation;
   - positive and negative parser tests;
   - semantic/type-checking behavior;
   - canonical Lean lowering where applicable;
   - executable IR lowering if executable;
   - backend/runtime test if executable;
   - an explicit trust/verification claim ceiling.
8. New syntax fails closed when the reference does not define it.
9. The compiler never turns host JavaScript behavior into proof evidence.
10. Keep source files focused; split modules by semantic responsibility before they become large mixed-purpose files.

## Immediate implementation sequence

The next low-risk vertical features should be:

1. first-class type AST with function arrows;
2. `fun` lambda terms with expected-type checking;
3. expression blocks as nested lexical lets;
4. braced `match`;
5. structures;
6. inductives;
7. theorem/proof elaboration into pskernel.

Structures and inductives are intentionally after ordinary functional terms because Lean's own implementation shows they require substantially richer elaboration and kernel interaction.
