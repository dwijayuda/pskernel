# Effects and `do`

PSC1 keeps ordinary portable functions pure and makes effects explicit.

This separation is important for proofs, optimizations, reproducibility, and
cross-backend behavior.

## Pure functions first

A function such as:

```proofscript
function add(x : Nat, y : Nat) : Nat :=
  x + y;
```

has no hidden dependency on filesystem state, wall-clock time, process
environment, or a mutable JavaScript global.

That makes its meaning portable.

## Why hidden effects are dangerous

Suppose a function looks pure but secretly reads the current time.

A compiler transformation that duplicates or reorders the call could change
observable behavior.

A proof that rewrites equal pure expressions could also become unsound with
respect to that hidden runtime effect.

Therefore host effects must stay explicit.

## The first compiler effect

PSC1 self-hosting requires a concrete compiler-oriented reader/state/error
effect.

Conceptually it combines:

- immutable context;
- compiler state;
- typed failure;
- deterministic sequencing.

Think of it as a `CompilerM α`-style abstraction.

The exact runtime representation is not the language semantics.

## `pure` and `bind`

Effectful sequencing is built from the ordinary monadic ideas:

- `pure` injects a value;
- `bind` sequences a computation and gives its result to the next step.

The first self-host profile needs these capabilities whether or not every
generic monad-transformer convenience is supported.

## `do`

`do` provides readable sequencing syntax for effectful code.

PSC1 keeps the semantics attached to the effect abstraction.

It does **not** mean:

- JavaScript Promise semantics;
- implicit async;
- Rust statement semantics;
- Wasm instruction ordering as the source definition.

## `return`

Where the supported `do` syntax uses `return`, it means the operation of the
effect notation.

It is not a universal imperative early return from arbitrary PSC1 function
bodies.

## Reader behavior

Compiler code often needs shared immutable context such as:

- configuration;
- current module information;
- resolver context;
- environment options.

Reader-style access keeps that dependency explicit in the compiler effect.

## State behavior

Compiler code also needs evolving state such as:

- fresh IDs;
- name environments;
- metavariable state;
- parser/elaborator state.

Explicit state semantics make updates auditable and portable.

## Error behavior

Recoverable compiler failures use a typed error channel.

That is preferable to letting a Node exception become the semantic definition
of a parse or elaboration error.

## Transactional rollback

Speculative parsers/elaborators often need to:

1. save state;
2. try an alternative;
3. restore state if it fails.

The PSC1 self-host foundation explicitly requires transactional rollback for
the compiler effect where needed.

A failed speculative branch must not leak assignments or state changes.

## Host exceptions

A host adapter may call an API that reports ordinary failure with exceptions.

The adapter should translate those failures into the declared PSC1
error/effect channel when they are recoverable.

The host exception mechanism itself is not portable language semantics.

## Filesystem, network, time, randomness

These are effectful capabilities.

They must not masquerade as ordinary pure functions.

Each capability should record:

- signature;
- failure model;
- effect classification;
- target availability;
- trust status.

## Generic transformer stacks

Lean uses sophisticated abstractions such as ReaderT/StateT/ExceptT/EStateM.

PSC1 studies them because they show what real compiler infrastructure needs.

But the first freeze deliberately does **not** require generic transformer-stack
parity when one concrete compiler effect is enough.

This is the small-language/library-first policy in action.

## Future async/task semantics

A backend-neutral structured async/task model is a plausible post-PSC1
direction.

PSC1 should specify its semantics first.

It should not simply import JavaScript Promise behavior or Rust async behavior
and hope they are equivalent.

## Effects and VerifiedIR

Target-neutral effect semantics must remain expressible before backend
lowering.

Backend details such as:

- JS Promise scheduling;
- native threads;
- WASI handles;

belong below the shared semantic boundary or behind explicit capabilities.

## Next

Continue to [Modules and Projects](./10-modules-and-projects.md).
