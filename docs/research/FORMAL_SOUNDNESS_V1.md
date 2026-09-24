# Formal soundness v1 — verified co-signer

Status: **v1 executed and green**; intentionally cheaper than TypeScript/C++
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
npm run formal:cosign -- path/to/standard-export.ndjson --con-leche-bin /path/to/con-leche
```

Certification transport is pinned separately in `FORMAL_LOCK.json`: official
`lean4export` 3.1.0 at commit
`076e8e57707e813375e8f9da8bf989799ace9680`, run with final Lean 4.34.0
and its default metadata erasure. Official lean4export removes
`Expr.mdata` by default because it should not affect type checking.

pskernel's rich replay fixtures intentionally retain mdata to compare generated
kernel metadata and are therefore a different assurance transport. They are not
silently rewritten into formal inputs. The formal lane regenerates standard
lean4export bytes directly from the source/module being certified.

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

## Executed evidence

Pinned proof-backed co-signing is green in GitHub Actions run `36060889198`,
job `107839268830`.

### Minimal final-Lean-4.34 smoke

- source: `oracle/formal/Smoke.lean`;
- standard lean4export 3.1.0 stream SHA-256:
  `570c47cb02ea5e9e2cbc4767ec54741f7d638ba8ed9057c671777ff6cdf0ea02`;
- pskernel: **accept**;
- pinned ConLeche `--verified`: **accept**, 9 declarations.

### Final Lean 4.34 Init.Prelude

- standard lean4export 3.1.0 stream SHA-256:
  `722f07cb6dad191bcdd176eb17fe77db8635dc53b364b4ad174081f7d340848d`;
- stream: **64,110 lines**, **1,824 declarations**;
- pskernel: **accept**, resulting environment **2,106 constants**;
- pinned ConLeche `--verified`: **accept**, all **1,824 declarations**;
- ConLeche additionally reports one in-process modeled inductive block,
  `Lean.Syntax`, with 30 generated records checked by its declaration fold.

For those exact streams, ConLeche's `model_exists` theorem applies to the
verified checker's acceptance under its stated `SetTheory` assumptions. This
is a genuine machine-checked formal soundness result for the co-signed streams.

It is still not a theorem about the TypeScript implementation itself.

## Cost-based stopping point

This is the intended v1 stopping point. The next product-facing step is to put
this protocol behind `psc certify` once the ProofScript compiler has a stable
standard lean4export/certification artifact boundary.

We deliberately do **not** start a second formal kernel or attempt arbitrary
TypeScript↔C++ equivalence now. Additional corpus census work is optional and
should be done only when it changes the definition of the ProofScript Formal
Core.

Possible later milestones, in increasing cost:

1. define the **ProofScript Formal Core** as the features/artifacts routinely
   accepted by both pskernel and the pinned verified checker;
2. add `psc certify` around this protocol;
3. optionally make pskernel proof-producing so a smaller verifier checks
   certificates instead of rechecking full streams;
4. treat exact TypeScript↔C++ behavioral equivalence as an optional research
   moonshot.


## First transport experiment

The first attempted smoke used the existing rich
`lean434-primitive-closure.ndjson` replay fixture. pskernel accepted it, while
ConLeche stopped at the first `Expr.mdata` record with a parser error. This is
a transport mismatch, not a semantic reject/decline. The formal lane therefore
uses official lean4export's default no-mdata stream instead of adding an
unproved metadata-rewriting adapter.
