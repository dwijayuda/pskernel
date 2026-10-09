# PSC0 current authoring guide

This is the developer entry point for the current bounded self-host language.
The implementation basis is R2,
`fe2560aba0f347b1caf8d000d371464642d44f23`; the finite F source migration is an
implemented candidate awaiting its own qualification. R2 has earned compiler
qualification, independent provider acceptance and verified cold source recovery.
[selection commit e65606397fb679d7cb96f4f0e92700a6cf0944a6](https://github.com/dwijayuda/pskernel/commit/e65606397fb679d7cb96f4f0e92700a6cf0944a6) explicitly selects its exact compiler. R2 evidence
does not qualify F.

| Evidence needed before promotion | Current entry |
|---|---|
| R compiler qualification | **Passed** — [retained qualification](seed-evidence/fe2560aba0f347b1caf8d000d371464642d44f23/qualification.json), SHA-256 `b3e9a277a7ce5ee9e0bccc449c9ca20a06766cd94cabd34fe4d722c6425e6fac`; job `113804052074` |
| R independent provider decision | **Passed** — [receipt](grammar-migration-provider.json), SHA-256 `1736aa0c1b3fdd5d59b4c2653c053261e3ada36ea82b68d6b88400e17fc1ab77`; four distinct streams covering eight roles |
| R cold source recovery | **Passed** — [receipt](grammar-migration-cold-recovery.json), SHA-256 `2aa93517b848da1493386ab9be50527275fe1a7a1c7e12f422d8d8431d8d9f1d` |
| Explicit selection of R | **Selected** — [selection commit e65606397fb679d7cb96f4f0e92700a6cf0944a6](https://github.com/dwijayuda/pskernel/commit/e65606397fb679d7cb96f4f0e92700a6cf0944a6); manifest SHA-256 `7a0c2cf950333aa680f2ae00e214f57b674dab2d783a1403b242b92e71c56694`; seed identity `47d88158e075f766f0d146ba3a13b28744c6e196d9844c71f4e52dc7351e2225` |
| F source revision, paired behavior, ABI and fixed-point evidence | **PENDING — insert immutable F receipts** |

## One current PS grammar; Lean source authority

Current `.ps` input and canonical output use **`ps-0.9-r3`, `new-only`,
`bounded-selfhost-subset`**. There is no current legacy PS parser or old-output
option. The supplied language reference is identified by SHA-256
`4c02626fd0b991e8526c64b65f4ffb66b9ce7b688298e82fb0309802a263db71`.
[PS_GRAMMAR_ADOPTION.md](PS_GRAMMAR_ADOPTION.md) gives the finite mapping and
reference errata. Current configuration records this identity in
[psconfig.json](../../psconfig.json).

The handwritten compiler remains authoritative **`.lean`**, consumed through
PSC0's own bounded Lean frontend. Generated PS is a canonical surface product;
the grammar change does not move compiler source authority. Immutable S0/A
recovery uses its old source revisions and producer identities. It does not add a
legacy mode to current PS.

Current tools require Lean **4.34.0**, Node **22.23.3** and TypeScript **7.0.2**.
Historical S0/A recovery retains TypeScript **5.8.3**. See
[TYPESCRIPT7.md](TYPESCRIPT7.md). Full Standard/PSCV conformance, Lean 4.35 and
strict SH/1 activation are separate work.

## Source forms to use

Use explicit declaration parameter/result types, typed lambdas, immutable
records, `Except`/`Option`, Boolean conditionals and flat constructor matches.
Supported structural recursion can carry ordinary changing parameters before or
after its decreasing Nat/List argument. Keep the supported structural match
shape and argument order. Returned functions and public partial applications
remain valid constructs; F removes selected handwritten adapters, not function
values as a language feature.

R repairs projections from original recursive parameters, including nested
dotted fields, while preserving binding identity and shadowing. Consumer source
that depends on that repair uses the now-qualified, cold-recovered selected R seed. A field
typing error does not authorize another name lookup.

This structure and definition are copied from the real
[raw PS capability fixture](../../test/fixtures/selfhost-sh1-accumulators.ps):

```text
structure Sh1ProjectionState where {
  count : Nat
  step : Nat
}

def sh1ProjectionAcc(fuel : Nat, state : Sh1ProjectionState) : Nat :=
  match fuel with {
  | Nat.zero => state.count
  | Nat.succ remaining =>
      sh1ProjectionAcc(remaining,
        Sh1ProjectionState.mk(Nat.add(state.count, state.step), state.step))
  }
```

PS declaration/constructor headers use a non-explicit prefix followed by at most
one nonempty typed comma group. Structure fields, commands and local lets use
newlines. Record values and adjacent call arguments use commas. Typed lambdas
retain native binder sequences; grouped callbacks such as
`use((fun (x : Nat) => x))` are supported. Annotated `const` and positive-arity
`function` canonicalize to `def`.

Call ownership matters: `f a b` is one native application group; `f(a) b` keeps
the inner call. `f(())` supplies Unit. `f()` preserves zero source arguments
and currently fails elaboration with `emptyCallUnsupported`; it never inserts
Unit. Parenthesize compound terms when needed for ownership and use the canonical
printer for generated output.

In authored `.lean`, bind a callback to a typed local before passing it where
the narrower argument parser requires that form. Give match-valued local lets an
explicit result type when no expected type is available. New PS grouping does
not expand the Lean frontend's inference or grammar.

## The finite F migration

F changes **twelve workers and three projection aliases**:

| Family | Exact scope |
|---|---|
| F1, four fresh-name workers | Erasure `Basic`/`Expr`; TypeScript backend `Expr`/`Module` |
| F2, eight state workers | Compiler preparation; two elaboration workers; erasure declaration names and definition loop; structure/inductive preparation; TypeScript symbol-map construction |
| Projection cleanup | Three typed aliases in `CompilerIr/Check.lean` |

The exact names, original snippets and exclusions are in
[migration-backlog.json](migration-backlog.json). Seven associated source guards
move with these changes. Complete public curried types, parameter order,
structural arguments, zero-fuel policies, accumulator order and first errors must
remain unchanged. This is a bounded readability migration; it claims no measured
compiler speedup.

The candidate adds **87 behavior cases** and a separate ABI hook. The hook reads
the already prepared Core declarations and exact existing IR, then prepares only
a small isolated signature/typed-partial module. It does not prepare the entire
baseline closure again or inject probes into compiler source. Runtime partial
application retains its separate gate. R's authoring prerequisite is now complete;
F's own promotion evidence remains pending.

## Daily iteration

Run commands from `psc0/`. For a coherent source edit, start with the existing
native development route:

```sh
npm run dev:sh1
```

It incrementally builds the native tools, produces N1 in `dist/sh1/N1`, and
exercises the current generated compiler's bounded corpus. This is development
evidence, not selected-seed reproduction, a fixed point or provider acceptance.

For repeated unchanged or late-module edits, retain one authenticated compiler
instance:

```sh
PSC0_ITERATION_SHA256="$(node -p "require('./dist/sh1/N1/receipt.json').artifacts.javascriptSha256")"
npm run iterate:sh1 -- --compiler dist/sh1/N1/index.js --compiler-sha256 "$PSC0_ITERATION_SHA256" --loop
```

The first request prepares the full current raw Lean closure. Later requests
reuse unchanged preparation prefixes. Enter or `prepare` prepares; `emit`
writes admission-ready products; `reset` clears retained state; `quit` exits.
Use `--once` for one request and `--emit` for initial emission. Restart with a
new explicit digest when changing the compiler. Emission and provider checking
remain separate; warm preparation reuse is not an end-to-end speed guarantee.

These commands are defined by [package.json](../../package.json) and
[sh1-iterate.mjs](../../scripts/sh1-iterate.mjs). Current PS command-line
readers/producers check grammar exports. The reusable preparation session also
requires the exact grammar before any PS preparation or cache hit, and binds it
in PS closure hashes and receipts. Callers still authenticate the actual compiler
bytes against the supplied compiler digest.

## Qualification and remaining limits

Use the native gate to check the coherent change before the expensive
selected-seed sequence. Promote once the exact source passes C1/C2/C3, required
current product equality, original-IR checking, bounded runtime/grammar gates and
separate exact-stream provider decisions. R's verified source recovery and explicit
selection are recorded above; F must earn its own exact-source results. See [IMPLEMENTATION.md](IMPLEMENTATION.md)
and [MIGRATION.md](MIGRATION.md); receipts determine completion.

Unsupported capabilities include general `do`, omitted required types,
default/named arguments, automatic empty-call completion, tuple terms/patterns,
arbitrary result projection such as `f(x).field`, nested patterns, general
equation normalization, class/instance synthesis and broader verified effects.
Legacy semicolon sequences and repeated explicit PS declaration groups are
rejected. Full PSC1/Standard/PSCV, strict SH/1 and authoritative PS implementation
source are not established by this checkpoint. [SPEC.md](SPEC.md) separates the
implemented subset from the complete contract.
