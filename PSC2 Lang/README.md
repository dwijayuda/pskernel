# ProofScript PSC2

Status: **research-driven post-PSC1 profile draft**

Base profile: [`PSC1 Lang`](../PSC1%20Lang/README.md)

PSC2 extends PSC1. It does **not** reopen or invalidate the PSC1 freeze.
PSC1 remains the small bootstrap language and semantic foundation. PSC2 is the
first productivity/adoption profile intended to make day-to-day ProofScript
comfortable for:

- Lean 4 programmers and theorem-prover researchers;
- TypeScript/JavaScript developers moving into verified programming;
- formal-verification users who want contracts and verification conditions;
- ProofScript compiler, tactic, plugin and library authors.

## Design objective

PSC2 should make ProofScript substantially less painful without making its
trusted core substantially larger.

The default rule is:

```text
library
  -> source sugar / desugaring
  -> elaborator / Meta / tactic feature
  -> controlled plugin
  -> standardized semantic extension
  -> kernel change only when unavoidable
```

Most PSC2 features must lower to the existing PSC1 dependent core and remain
checkable by the same small kernel contract.

## Product principles

PSC2 preserves the ProofScript identity:

1. **Small** — PSC1 remains the bootstrap/core language. PSC2 mostly adds
   conveniences above it.
2. **Provable** — specifications, contracts and generated proofs are ordinary
   propositions/proof terms checked by the kernel.
3. **Verifiable** — parsers, elaborators, tactics, VC generators and backends
   never gain proof authority.
4. **Understandable** — every new feature must have a documented lowering or
   semantic rule.
5. **Easy to learn** — prefer one common mechanism and familiar syntax over
   many overlapping mechanisms.
6. **Easy to adopt** — support the common workflows Lean and TypeScript users
   already expect without importing unsound or backend-specific semantics.
7. **Extensible** — libraries and proof-producing plugins may grow large while
   the trusted semantic foundation stays small.

## Why PSC2 exists

PSC1 deliberately prioritizes self-hosting closure. That is the right scope for
PSC1, but several features that are optional/non-blocking there are used so
often in real Lean programming, mathlib proofs, or TypeScript application code
that their absence would create unnecessary migration pain.

PSC2 therefore focuses on three gaps:

```text
PROGRAMMING ERGONOMICS
  method/field notation, updates, patterns, loops, local mutation syntax,
  named/default arguments, namespace ergonomics, async/task programming

THEOREM-PROVING ERGONOMICS
  structured proof terms, mature simp infrastructure, common proof tactics,
  stronger typeclass/coercion support, controlled notation and attributes

FORMAL VERIFICATION
  requires/ensures, assert, loop invariants, decreasing measures, VC generation
```

## Lean 4.34 contract research changes the plan

Lean 4.34 (released 2026-09-14) includes experimental intrinsic verification
syntax for `def` contracts and imperative programs. Its release notes and
parser implementation include:

- `requires` preconditions;
- `ensures` postconditions;
- `assert` inside `do`;
- loop `invariant` clauses;
- `decreasing` clauses;
- verification-condition generation through the `vcgen`/`Std.Do` machinery;
- `where finally | spec => ...` for remaining proof obligations.

PSC2 should treat this as a strong interoperability signal. The recommended
PSC2 contract surface is intentionally close to Lean 4.34 so `.lean` and `.ps`
verification code can share concepts and, where supported, source structure.

Lean 4.34 still marks intrinsic verification as experimental. PSC2 must
therefore copy the useful semantic model, not blindly freeze every current Lean
implementation detail.

## PSC2 required profile

### A. Programming ergonomics

PSC2 SHOULD require the following source/elaboration capabilities:

- generalized field/method notation (`x.f(...)`) with deterministic resolution;
- structure update syntax;
- named arguments and default arguments;
- richer pattern matching:
  - nested constructor patterns;
  - tuple/product patterns;
  - multiple scrutinees;
  - let/do pattern bindings;
  - `if let`-style convenience;
  - equation-style function definitions;
- local recursive definitions and practical mutual recursion;
- well-founded recursion and explicit termination/decreasing evidence;
- `let mut`, reassignment, `for`, `while`, `break`, and `continue` as
  controlled `do`/effect syntax that lowers to existing semantics;
- practical namespace/scope ergonomics (`namespace`, `open`, `section`, shared
  variables, deterministic re-export/import conveniences);
- `abbrev`/transparent alias support where it reuses existing elaboration and
  transparency rules;
- standardized deriving for common generated code/proofs;
- a target-neutral `Task`/async model, with `async`/`await` only as sugar over
  that model if/when the syntax is standardized;
- typed `try`/recovery notation over `Except`/effect semantics rather than host
  exceptions.

### B. Theorem-proving ergonomics

PSC2 SHOULD require a standard prover layer containing at least:

- term proof structuring: `have`, `show`, `suffices`, `calc`;
- proof control: `by_cases`, `by_contra`, `exfalso`, `subst`, `generalize`,
  `change`, `unfold`, `dsimp`;
- richer destructuring/introduction such as `rcases`, `rintro`, `obtain`, and
  `use` or equivalent functionality;
- a mature deterministic simplifier:
  - `simp`;
  - `simpa`;
  - `simp only`;
  - local/hypothesis simplification;
  - a controlled simplification-lemma registry;
- stronger `cases`/`induction` support for indexed/dependent contexts;
- stronger instance synthesis, scoped/local instances, and practical coercion
  insertion;
- controlled theorem/library metadata analogous to the useful subset of Lean
  attributes such as simplification/extensionality registrations;
- controlled mathematical notation/infix/scoped notation;
- an extensible Meta/tactic API whose extensions construct ordinary proof terms
  and never bypass kernel checking.

Large automation (`omega`, `lia`/`linarith`, `ring`, `norm_num`, `aesop`/search,
SMT integrations, AI proof search) is strongly desirable in the PSC2 ecosystem
but may be shipped as standard libraries/plugins rather than being part of the
language grammar or trusted core.

### C. Formal verification

PSC2 SHOULD standardize:

```proofscript
def withdraw(balance: Nat, amount: Nat): Nat
  requires amount <= balance
  ensures result => result = balance - amount :=
  balance - amount;
```

and the imperative/effectful verification forms:

```proofscript
def sum(xs: List Nat): Nat
  ensures result => result = xs.sum := do {
  let mut acc := 0;
  for x in xs
    invariant consumed remaining acc =>
      acc = consumed.sum
  {
    acc := acc + x;
  }
  assert acc = xs.sum;
  return acc;
}
```

Exact syntax is draft, but the semantic contract is not:

- `requires`, `ensures`, `assert`, and `invariant` denote propositions/specs,
  not Boolean runtime checks masquerading as proofs;
- verification generates proof obligations;
- only kernel-admitted proof terms close verified obligations;
- proof/spec metadata has no authority by itself;
- proofs and contracts may erase from executable artifacts after verification;
- optional runtime contract checking is diagnostic/testing behavior only and
  must never be presented as formal proof.

See [CONTRACTS_AND_VERIFICATION.md](./CONTRACTS_AND_VERIFICATION.md).

## What PSC2 should *not* copy from TypeScript/JavaScript

Ease of migration does not mean semantic imitation. PSC2 should continue to
reject these as native portable semantics:

- `any` as an unchecked escape hatch;
- implicit `null`/`undefined` absence instead of `Option`;
- prototype inheritance and JavaScript `this` semantics;
- structural object identity/assignability as the foundational type system;
- implicit truthiness/coercion rules;
- host Promise semantics as the definition of async;
- host exceptions as the definition of recoverable errors;
- JavaScript number semantics for `Nat`/`Int`.

PSC2 should provide familiar ergonomics over ProofScript semantics instead.

## What PSC2 should *not* copy from Lean wholesale

Lean compatibility is a goal, but PSC2 need not make `.ps` inherit every Lean
implementation mechanism. In particular, PSC2 should avoid requiring:

- unrestricted runtime grammar mutation;
- arbitrary environment extensions as the primary library mechanism;
- every parser category and macro facility;
- every tactic name in core;
- Lean runtime/FFI details;
- exact `.olean` implementation representation;
- Lean-specific compiler intrinsics in portable programs.

`.lean` compatibility may expose a broader compatibility frontend while `.ps`
keeps the smaller native experience.

## Self-hosting rule

PSC2 must remain self-hostable even though its compiler/kernel foundation is
written in PSC1.

Preferred rule:

> A PSC2 feature SHOULD be implementable in the PSC1 bootstrap subset unless it
> introduces genuinely new foundational semantics.

Examples:

```text
method notation      -> PSC1-written elaborator -> ordinary application
rich patterns        -> PSC1-written pattern compiler -> primitive match
for/let mut          -> PSC1-written desugaring -> recursion/state/ForIn
calc/have            -> PSC1-written elaborator -> ordinary proof terms
simp                 -> PSC1-written Meta/tactic library -> proof terms
contracts            -> PSC1-written VC generator -> propositions/proofs
```

If implementing a future compiler naturally requires a post-PSC1 Lean feature,
official Lean may bootstrap that next compiler from a precisely documented
future subset. Self-host completion is claimed only after the generated `.ps`
compiler reaches its own fixed point.

See [SELF_HOSTING_AND_EXTENSION_MODEL.md](./SELF_HOSTING_AND_EXTENSION_MODEL.md).

## Document map

- [PSC2_LANGUAGE_PROFILE.md](./PSC2_LANGUAGE_PROFILE.md) — proposed PSC2
  language/prover/platform profile and lowering strategy.
- [FEATURE_RESEARCH_MATRIX.md](./FEATURE_RESEARCH_MATRIX.md) — evidence-driven
  comparison of Lean usage, TypeScript expectations, PSC1 status and PSC2
  priority.
- [CONTRACTS_AND_VERIFICATION.md](./CONTRACTS_AND_VERIFICATION.md) — PSC2
  contracts, verification conditions, invariants and trust model.
- [SELF_HOSTING_AND_EXTENSION_MODEL.md](./SELF_HOSTING_AND_EXTENSION_MODEL.md) —
  how PSC1/Lean bootstrap richer PSC2 features without circular dependency.
- [MIGRATION_GUIDE.md](./MIGRATION_GUIDE.md) — intended migration experience for
  Lean 4 and TypeScript developers.

## Research sources

Primary sources used for this draft include:

- ProofScript `PSC1 Lang` and the self-host architecture/plans in this repo;
- Lean 4.34 release notes and pinned Lean 4.34 sources;
- current Lean Language Reference;
- *Functional Programming in Lean* / Lean programming documentation;
- *Theorem Proving in Lean* and tactic reference;
- Lean `Std.Do` / `vcgen` verification documentation;
- representative current Lean 4 and mathlib source usage;
- the current TypeScript Handbook (Everyday Types, Functions, Narrowing,
  Object Types, Classes, Modules, Generics and related reference material).

Usage counts in the research matrix are **signals, not language statistics**:
GitHub code-search file matches can include comments/examples and fluctuate with
repository revisions. They are used only to distinguish pervasive idioms from
specialized features, never as the sole reason to add a feature.