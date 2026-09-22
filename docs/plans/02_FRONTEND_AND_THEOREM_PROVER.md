# Frontend and theorem-prover plan

Status: post-module/conformance foundation.

Lean 4.34 analogues:
- `Lean.Parser`
- foundational `Lean.Meta`
- `Lean.Elab`
- selected tactic layers
- `Lean.PrettyPrinter`

## Package sequence

### @proofscript/syntax

MVP:
- UTF-8/source positions
- tokens
- syntax nodes
- parser combinators
- term/command grammar
- recovery + diagnostics

Non-goal: replicate Lean's full macro/notation extension machinery.

### @proofscript/pretty

MVP:
- precedence-aware pretty printing
- Expr/declaration formatting
- goal/diagnostic presentation
- source-like output where possible

### @proofscript/meta

MVP:
- metavariable context
- assignments
- local/meta contexts
- metavariable-aware infer/WHNF
- unification modulo kernel defeq
- transparency modes
- expected type propagation
- implicit argument insertion
- basic instance synthesis
- telescope/goal helpers

Non-goal: port all Lean.Meta before ProofScript can elaborate useful programs.

### @proofscript/elab

MVP:
- names/scopes/imports
- binders
- application/lambda/Pi/let
- def/theorem
- inductive declarations
- holes
- expected types
- implicit args
- source diagnostics
- submit resulting declarations to pskernel

### @proofscript/tactic

Start small:
- exact
- intro
- apply
- assumption
- constructor
- cases
- induction
- rewrite

Add simp later as its own milestone.

## Trust model

All frontend packages are outside the TCB. Their output is accepted only after pskernel checks it.

## Acceptance gate for Phase B

A small multi-file ProofScript project must:
1. parse,
2. elaborate dependent declarations and proofs,
3. expose useful holes/goals,
4. produce checked module artifacts,
5. re-open those artifacts in a fresh kernel environment.
