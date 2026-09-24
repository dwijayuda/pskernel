# Formal soundness v1 — verified co-signer

Status: research implementation, intentionally cheaper than TypeScript/C++
formal equivalence.

## Goal

Provide a machine-checkable **formal soundness mode** for ProofScript/pskernel
without proving the TypeScript implementation or V8 equivalent to Lean's C++
kernel.

The rule is:

```text
formalAccept(stream) :=
  pskernel.accept(stream)
  AND
  pinned ConLeche --verified accepts(stream)
```

The second conjunct carries the formal theorem. At the pinned ConLeche revision,
`ConLeche.model_exists` proves that every environment returned by the verified
checker has a model under its stated `SetTheory` assumptions. Its
`no_False_declaration` theorem gives the corresponding no-`False` corollary
for the binary's verified acceptance path.

This is deliberately **one-way soundness**, not behavioral equivalence.

## Why this is the best value/cost point

We already have strong behavioral evidence for pskernel:

- direct kernel regressions;
- pinned Lean 4.34 differential/adversarial checks;
- bounded real corpora;
- Std release assurance;
- Lean Kernel Arena correctness.

Re-proving the hand-written TypeScript checker would additionally require a
formal semantics for mutable JavaScript/TypeScript implementation details or a
large source-to-model correspondence proof.

The co-signer avoids that entire layer. pskernel remains the fast compatibility
checker. ConLeche is invoked only by explicit certification workflows.

## Command

Build pskernel and provide the pinned `con-leche` binary:

```bash
CONLECHE_BIN=/path/to/con-leche npm run formal:smoke
npm run formal:cosign -- path/to/export.ndjson --con-leche-bin /path/to/con-leche
```

Exit codes:

- 0: both checkers accepted; formal co-signing succeeded;
- 1: either checker rejected;
- 2: ConLeche explicitly declined an unsupported feature;
- 3: tooling/binary failure.

A ConLeche decline is **not** a rejection and is **not** a certification.

## Trust / claim boundary

A successful co-sign says only:

> pskernel accepted the exact stream, and the pinned ConLeche verified checker
> accepted the same stream. Subject to ConLeche's stated set-theory assumptions,
> its accepted environment has a model.

It does not say:

- pskernel is formally equivalent to Lean C++;
- ConLeche is complete for Lean 4.34;
- all pskernel inputs are certifiable;
- Node/V8/TypeScript execution is formally verified.

## Version strategy

ConLeche currently uses Lean 4.33.0 internally, but it reads lean4export NDJSON
streams and deliberately supports several toolchain shapes through checked pins.
Therefore certification is empirical per stream: a Lean 4.34-target stream is
certified only when the pinned verified checker actually returns exit 0.

No adapter is allowed to rewrite a rejected/declined stream into an accepted one
while preserving the certification claim. If format translation is ever needed,
that translation becomes a separately specified/proved boundary.

## Next cheapest milestones

1. Green co-sign smoke on a small real Lean 4.34 export.
2. Measure how much of the existing pskernel corpus ConLeche accepts.
3. Define the **ProofScript Formal Core** as the intersection that both accept.
4. Add `psc certify` around this protocol.
5. Only if valuable later, replace repeated co-checking with proof-producing
   pskernel certificates checked by a smaller verified verifier.

Exact TypeScript↔C++ formal equivalence remains an optional research moonshot.
