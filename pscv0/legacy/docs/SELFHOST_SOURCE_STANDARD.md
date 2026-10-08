# ProofScript Self-Host Source Standard

Profile: `PSC1-selfhost-stable/1` (implementation discipline)

The current self-host compiler still identifies its proven generated `.ps` closure as
`ps-0.9-r3` / `ps-standard-0.9-r3`. Those names describe the implementation profile
needed to bootstrap the current compiler; they are **not** a forward language-compatibility
promise. The PSCV language reference is the design authority for new language work, and
obsolete r3 syntax/grammar does not need to be preserved merely for backward compatibility.

`PSC1-selfhost-stable/1` remains a deliberately smaller coding discipline for compiler
implementation source so that the compiler can continue compiling and regenerating itself.

This document is normative for code that is reachable from
`packages/bootstrap/src/Ps/Bootstrap/SelfHost.lean`.

## Portable extension profile

Portable non-bootstrap implementations that must be consumed by PSC use the separate
`PSC1-portable-selfhost/1` implementation profile. This does **not** add those
packages to the compiler bootstrap closure and does not change the meaning of
`PSC1-selfhost-stable/1`.

A package opts in with:

```json
{
  "proofscript": {
    "portable": true,
    "implementationProfile": "PSC1-portable-selfhost/1"
  }
}
```

The portable profile reuses the stable profile's forbidden Lean machinery and adds
generic structural rules for source shapes that the proven self-host corpus has shown
to be fragile. These include structural-recursion declaration/call shape, general
infix arithmetic outside supported structural patterns, scalar-member capability
allowlisting, opaque primitive matching, explicit `Option` constructors, term list
append/cons shorthand, numeric tuple projection, tuple construction, grouped-dot
application, string-literal patterns, Boolean/conversion conveniences, leading-dot
term constructors, typed local lambda/match/numeric bindings, and explicit `let`
sequencing.

The static checker scans every opted-in package source root and its workspace import
closure. The executable contract then performs four linked gates:

1. every package source root must pass `psc1 check`, proving that the root plus its
   imports are parseable, elaboratable, and admission-ready;
2. the contract derives the package's top-level entry roots from the import graph and
   proves that those entry closures cover every package source file;
3. every entry root must pass `psc1 typescript`, exercising erasure, VerifiedIR
   validation, and bootstrap TypeScript emission;
4. every entry root must also emit canonical `.ps`; that emitted `.ps` is checked
   again, re-emitted to prove byte-idempotent `.ps` fixed-point form, and compiled to
   TypeScript with output exactly equal to the authoritative Lean-source emission.

This makes portable Direct JS/Direct Wasm implementation code demonstrably consumable as
ProofScript source rather than merely Lean source that happens to satisfy a static style
checker.

New failures must extend a general rule only when they identify a genuinely new
source-profile invariant; do not add backend/file-specific repair guards. A capability
missing from the portable semantic environment must be added coherently through the
prelude/IR/erasure/backend path or rejected explicitly; source-profile checks must not
paper over semantic gaps.

The goal is to keep self-hostability as a development invariant instead of rediscovering
unsupported source patterns late in the bootstrap/fixed-point cycle.

### Prelude extension parity

The historical joint-inventory prelude remains the frozen core parity oracle. Intentional
portable capabilities that extend that prelude must be declared separately in
`prelude-extension-contract.json`.

The parity gate therefore enforces two independent invariants:

1. after removing only contract-declared extensions, the frozen core declarations must
   remain exactly equal in type, metadata, body and order;
2. every declared extension must itself match its exact serialized declaration and
   pinned insertion point.

Unknown extra declarations are never hidden by the extension contract. Missing,
duplicated, moved or shape-changed extensions reject. Do not regenerate the frozen core
inventory merely because a portable capability is intentionally added.

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
the focused r3 parser/printer/translation suite, content-cache corruption/bypass
invariants, and a tiny resident-cache invalidation corpus. It does not rebuild Lean or
the whole compiler.

Fast JS source-selfhost guard:

```text
npm run selfhost:guard
```

This uses the existing generated JavaScript compiler to re-emit the complete canonical
`.ps` closure and requires exact 55-module source parity. It is the normal pre-commit
gate for compiler-source edits.

Current-source JS compiler fixed point without reseeding Lean:

```text
npm run fixed-point:js
```

This is the predictive development fixed point. It first uses the last-known-good
bootstrap JavaScript compiler to translate the **current handwritten compiler source** into
a canonical PSC workspace. If that workspace is byte-identical to the already-proven
bootstrap workspace, it reuses the existing exact bootstrap/selfhost fixed-point evidence
instead of recompiling an unchanged compiler. Otherwise it compiles the current workspace
into a candidate compiler, then uses that candidate compiler on the same canonical current
source to produce the next generation. The current and next canonical source workspaces
must be byte-identical, and `index.ts`, `index.js`, `index.d.ts`, and `index.js.map`
must all be byte-identical.

For regression against the already-generated bootstrap workspace only:

```text
npm run fixed-point:bootstrap-js
```

Do not use `fixed-point:bootstrap-js` as evidence for ungenerated current-source edits.

Both generated-JS paths require the incremental preparation API; missing incremental
exports reject instead of silently falling back to aggregate whole-closure preparation.

Resident hot development loop:

```text
npm run dev:selfhost
```

The resident process imports the exact parent compiler once and keeps compiler-hash-scoped
caches for parsed modules, semantic transition/environment snapshots, prepared modules,
and backend TypeScript text. A changed module is reparsed/re-elaborated once; its complete
runtime declaration value (including every own field and generated constructor symbol tag)
is structurally SHA-256 fingerprinted. If that semantic prefix matches a previously proven
state, downstream unchanged transitions remain green and are reused instead of being
invalidated merely because source bytes changed. The fingerprint is only a cache key, not
an admission authority; cold/oracle and fixed-point equality remain decisive.

Content-addressed disk caches separately cover source translation/canonicalization and
TypeScript artifacts. Cache keys use exact compiler/source bytes; the TypeScript artifact
key also fingerprints the launcher, package metadata, platform-native compiler executable,
Node/platform identity, and the pinned compiler flags.

Interactive resident commands are:

```text
build       # current source -> candidate compiler using hot caches
check       # candidate -> next generation, exact source/artifact fixed point
oracle      # hot current build == fully cold current build
cold-check  # full resident JS fixed point with all caches bypassed
stats
clear
quit
```

One-shot equivalents are:

```text
npm run dev:selfhost:once
npm run dev:selfhost:check
npm run dev:selfhost:oracle
npm run dev:selfhost:cold-check
```

`PSC_NO_CACHE=1` is the canonical cache bypass. A cache miss or corrupt cache entry
recomputes from source; no semantic fallback is permitted. Resident snapshots are never
serialized to disk because generated compiler objects contain runtime symbol tags. The
cold path remains the oracle, and optimized results become trusted only by exact
differential equality against cold execution and the normal fixed-point gates.

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
