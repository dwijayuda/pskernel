# ProofScript Self-Host Source Standard

Profile: `PSC1-selfhost-stable/1`

Canonical generated `.ps` syntax is `ps-0.9-r3` under the closed
`ps-standard-0.9-r3` source profile. `PSC1-selfhost-stable/1` is a deliberately
smaller coding discipline for the compiler implementation; it does not redefine or
preserve the retired pre-r3 `.ps` grammar.

This document is normative for code that is reachable from
`packages/bootstrap/src/Ps/Bootstrap/SelfHost.lean`.

The goal is to keep self-hostability as a development invariant instead of rediscovering
unsupported source patterns late in the bootstrap/fixed-point cycle.

## Rule of authority

A change is bootstrap-safe only when all three layers pass:

1. `npm run check:selfhost-profile`
2. `npm run selfhost:guard`
3. `npm run fixed-point`

A source file compiling in Lean is **not** enough. Code in the compiler closure must
also translate canonically to ProofScript, check as ProofScript, preserve canonical
admissions and TypeScript emission, and keep the generated-compiler fixed point.

`selfhost-profile.json` is the machine-readable definition of the source profile.

## What is standardized

The current successful compiler closure is the reference pattern. New compiler code
should use the same small, explicit semantic forms instead of arbitrary Lean
conveniences.

### 1. Explicit structural recursion

Prefer explicit arguments and an ordinary single-scrutinee match.

```lean
def psListLength (values : List α) : Nat :=
  match values with
  | [] => 0
  | _ :: rest => Nat.succ (psListLength rest)
```

Do not hide the recursive subject behind higher-order convenience functions merely
because Lean accepts them. A library combinator belongs in the bootstrap closure only
after the self-host profile can translate and replay it.

### 2. Stable fuel-worker form

For bounded recursive algorithms, use an explicit fuel parameter and bind the recursive
worker once from `remaining`.

```lean
def workWithFuel
    (fuel : Nat) : Input -> Output :=
  match fuel with
  | 0 =>
      fun (_input : Input) => fallback
  | remaining + 1 =>
      let smaller : Input -> Output :=
        workWithFuel remaining;
      fun (input : Input) =>
        match input with
        | ... => smaller next
```

Important invariants:

- recursive calls consume `remaining`;
- nested work does not silently create a fresh independent fuel budget;
- recursion parameters are explicit in the declaration;
- the public wrapper chooses the initial fuel once.

This is the pattern already proven across lexer, parser, elaborator, reduction,
unification, erasure and bridge code.

### 3. Prefer local list walkers in bootstrap-critical code

If a list traversal is semantically important to the compiler bootstrap, prefer a
small explicit recursive helper over introducing a new dependency on a convenience
combinator.

Use the already-proven operations when available. If a new combinator is desirable,
add it deliberately to the self-host profile and prove the whole closure with the
generic contract; do not patch one call site and add another one-off self-host test.

### 4. Keep pattern matching simple and explicit

Prefer:

- one scrutinee per `match`;
- nested matches when two values must be inspected;
- explicit constructor alternatives;
- explicit wildcard fallbacks.

Avoid introducing multi-scrutinee/equation sugar into the bootstrap closure until that
syntax is intentionally added to the profile and survives the full fixed point.

### 5. Prefer explicit core equality/boolean operations in fragile bootstrap paths

Where previous self-host failures came from overloaded/convenience syntax, keep using
the proven explicit operations such as `Nat.beq`, `psNameEq`, and ordinary nested
`if` expressions.

This does not mean every `==`, `&&`, or projection is globally forbidden. Existing
forms already proven by the fixed-point corpus may remain. The rule is: do not
introduce a new semantic dependency merely for convenience when an explicit proven
form exists.

### 6. Keep recursive data construction canonical

For bootstrap-critical recursive structures, prefer explicit constructors and typed
intermediate `let` bindings when that is the already-proven form. This makes
translation, erasure and generated-source canonicalization predictable.

Record syntax and projections are allowed where they are already part of the stable
profile, but new lowering-sensitive idioms must pass the generic executable contract
before becoming normal style.

### 7. Do not use Lean-only language machinery in the compiler closure

The machine profile currently rejects these forms before the expensive bootstrap:

- `unsafe def` / unsafe theorems;
- `noncomputable`;
- `mutual`;
- `termination_by` / `decreasing_by`;
- `opaque`;
- `abbrev`;
- Lean `syntax`, `macro`, `elab_rules`, `command_elab`;
- `deriving`;
- tactic proofs introduced with `by`;
- `let mut`, `for`, and `while`.

These can exist outside the bootstrap closure if appropriate. They are not standard
self-host source forms.

### 8. Keep host/kernel/backend facilities outside the compiler semantic core

The 55-module compiler closure may depend only on the packages allowed by
`bootstrap-closure-contract.mjs`.

Kernels, native host orchestration, Rust/Wasm extensions, project tooling and other
post-bootstrap facilities stay outside the compiler source closure.

A new bootstrap package is an intentional profile change, not an incidental import.

## Generic executable contract

`scripts/selfhost-contract.mjs` replaces the old pattern of waiting for a late
self-host failure and then writing another source-specific repair test.

For the entire compiler closure it performs:

1. authoritative Lean-compatible closure check;
2. every module Lean -> canonical `.ps` translation;
3. every generated `.ps` -> canonical `.ps` reprint is byte-idempotent;
4. complete generated `.ps` closure check;
5. exact Lean-source vs PSC-source canonical admissions parity;
6. exact Lean-source vs PSC-source TypeScript emission parity.

The contract prints stable admissions and TypeScript SHA-256 identities on success.

This catches unsupported source patterns before the generated JavaScript compiler is
involved.

## Generated compiler fixed point

The generic contract is necessary but not the final authority.

`npm run fixed-point` still proves:

```text
authoritative source closure
        -> canonical PSC workspace
        -> generated compiler
        -> re-emitted PSC workspace
        -> regenerated compiler
        -> exact source and TypeScript parity
```

The fixed point is the final self-hostability gate.

## Development commands

Fast edit-time grammar/profile check:

```text
npm run check:fast
```

This checks the frozen self-host source profile, the root r3 language-authority hash,
and the focused r3 parser/printer/translation suite. It does not rebuild Lean or the
whole compiler.

Fast JS source-selfhost guard:

```text
npm run selfhost:guard
```

This uses the existing generated JavaScript compiler to re-emit the complete canonical
`.ps` closure and requires exact 55-module source parity. It is the normal pre-commit
gate for compiler-source edits.

JS compiler fixed point without reseeding Lean:

```text
npm run fixed-point:js
```

This uses the existing bootstrap JavaScript compiler, regenerates the next compiler,
and requires exact source and generated-TypeScript parity.

Stronger native/reference source contract:

```text
npm run selfhost:guard:native
```

This builds native `psc` and runs the whole-closure Lean↔PSC admissions/TypeScript
parity contract. Use it for release evidence, bootstrap-boundary changes, and changes
to translation/elaboration semantics rather than on every edit.

Full seed-to-selfhost compiler gate:

```text
npm run fixed-point
```

Optional 55-module Lean replay is likewise separated from the normal fast selfhost path:

```text
npm run selfhost:lean-replay
```

Checked-kernel fixed-point/release gates remain separate assurance layers.

## No more one-off repair-test growth

The repository currently contains historical file-specific
`check-*-selfhost-source-syntax.mjs` repair guards accumulated while self-hosting was
being brought up.

`PSC1-selfhost-stable/1` freezes the exact historical allowlist of **75** repair
guards. The set may shrink as generic rules replace old guards, but a new one-off
repair-guard filename is rejected even if an old guard was removed first.

For future failures:

1. identify the general source/lowering invariant;
2. encode it in `selfhost-profile.json`, `selfhost-profile.mjs`, or
   `selfhost-contract.mjs`;
3. add/update the single generic profile test if needed;
4. make the whole closure pass;
5. make the full fixed point pass.

A legacy guard may be removed once its invariant is fully subsumed by the generic
contract.

## Adding a new language feature

Do not silently broaden the bootstrap language.

A new source feature becomes standard only after:

1. parser/AST/elaborator/backend support exists;
2. the feature is representable canonically in `.ps`;
3. the source contract passes for the whole compiler closure;
4. canonical admissions remain stable for equivalent Lean/PSC sources;
5. the generated compiler fixed point passes;
6. `selfhost-profile.json` is deliberately updated if the profile boundary changes.

If the new feature changes the meaning of `PSC1-selfhost-stable/1`, introduce a new
profile version instead of weakening the old profile in place.

## What “guaranteed self-hostable” means here

This is an executable repository invariant, not a mathematical theorem about the
compiler implementation.

If branch protection requires the profile, executable contract, and fixed-point gates
to pass before merge, then every merged change to the bootstrap closure has direct
evidence that:

- it stays inside the standardized source profile;
- its canonical PSC form is stable;
- Lean-compatible and PSC forms produce the same kernel admissions;
- both forms produce the same TypeScript;
- the generated compiler reproduces its own source/compiler fixed point.

That is the intended replacement for hunting self-host failures after several days of
feature development.
