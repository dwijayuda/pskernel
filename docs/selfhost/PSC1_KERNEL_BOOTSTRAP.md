# PSC1 kernel Lean bootstrap

Branch: `selfhost/kernel-lean-bootstrap`

This branch intentionally starts the future ProofScript-authored kernel **before**
the PSC1 compiler is complete.

The development assumption is:

> Write kernel source now as if the frozen PSC1 source language already existed.
> Use official Lean 4.34 + Lake as the temporary host. When PSC1 can compile the
> same bounded source subset, compile these exact `.lean` modules to TypeScript
> and then use the pinned installed `tsc` to produce JavaScript.

This is source-first bootstrapping, not a claim that the current PSC1 compiler
already compiles the kernel.

## Non-negotiable boundaries

The new kernel:

- reuses the portable PSC1 `PsName`, `PsLevel`, `PsExpr`, and pure core
  substitution data where semantics match;
- owns separate `Ps.Kernel.*` checking algorithms;
- does **not** call `Ps.Meta.Infer`, `Ps.Meta.Reduce`, or
  `Ps.Meta.Unify` as kernel authority;
- does not copy JavaScript cache/identity implementation details into semantic
  source;
- stays inside the portable PSC1 source-profile audit;
- is checked by official final Lean 4.34 while PSC1 is catching up;
- remains differential-tested against the release-assurance-complete
  TypeScript kernel;
- fails closed for kernel features not yet ported.

## Target bootstrap

During construction:

```text
Ps.Kernel/*.lean
      |
      | official Lean 4.34 / Lake
      v
kernel bootstrap tests
```

After PSC1 can consume the frozen subset:

```text
Ps.Kernel/*.lean
      |
      | PSC1
      v
generated kernel.ts
      |
      | pinned tsc
      v
kernel.js
```

Then require a second generation:

```text
kernel.lean --PSC1--> kernel1.ts --> kernel1.js
kernel.lean --PSC2--> kernel2.ts --> kernel2.js
```

with equal checked-core/IR fingerprints and behavioral parity.

Only after that transition should canonical `.ps` be generated and considered
for source authority.

## Implementation milestones

### KSH0 — model and immutable environment

Status: implemented on this branch.

- reuse PSC1 Name/Level/Expr;
- define kernel-owned ConstantInfo metadata matching the finished TypeScript
  kernel shape;
- define a small persistent environment API;
- preserve the key distinction that only ordinary definitions expose a delta
  reduction value.

### KSH1 — fail-closed structural admission

Status: implemented on this branch.

The first executable gate rejects:

- duplicate constant names;
- duplicate universe parameters;
- undeclared universe parameters;
- level metavariables;
- expression metavariables;
- free variables;
- loose bound variables;
- constant kinds whose full admission logic has not yet been ported.

It accepts bound variables only beneath their actual binder depth.

This is deliberately called **structural admission**. It is not yet type
checking and must never be reported as full kernel admission.

### KSH2 — final-4.34 level semantics

Port the already-hardened final Lean 4.34 behavior from
`src/core/level.ts`:

- raw max/imax preservation;
- smart max/imax constructors;
- exact final-4.34 normalizer behavior;
- the target kernel's intentionally incomplete level equivalence/order.

Lock every existing universe regression against both implementations.

### KSH3 — local contexts, substitution and expression invariants

Port/check:

- local declarations and globally unique local IDs;
- lifting / instantiation / abstraction;
- exact expression structural equality needed by kernel state;
- closedness and universe-policy invariants.

### KSH4 — inference and WHNF

Port from the finished TypeScript kernel source, not from `Ps.Meta`:

- Sort/const/app/lambda/Pi/let;
- literal and projection typing;
- delta, beta, let and projection reduction;
- Nat/literal hooks;
- quotient and recursor hooks;
- explicit resource bounds.

Native compiler-IR evaluation remains an optional capability and fails closed
when absent.

### KSH5 — definitional equality

Port final Lean 4.34 order/behavior, including:

- proof irrelevance;
- lazy delta;
- eta;
- structure eta;
- Nat offset behavior;
- String literal expansion;
- positive/failure caches as optimization only.

Semantic behavior must not depend on JS object identity.

### KSH6 — declaration admission

Port:

- axioms;
- definitions;
- theorems;
- stored-value constants;
- transactional non-safe mutual blocks;
- primitive-name validation.

### KSH7 — inductives, recursors and quotient

Port the already-assured TS implementation and keep all unported forms
fail-closed until their differential gates are green.

### KSH8 — parity closure

Require the same evidence profile used by the finished TS kernel:

- direct regressions;
- Lean differential cases;
- adversarial cases;
- bounded real corpora;
- pinned Arena correctness;
- standard Init.Prelude replay.

The existing TS kernel remains the differential implementation during this
phase.

### KSH9 — PSC1 compilation

Once PSC1 catches up, compile the already-written `.lean` kernel without
redesign:

```text
kernel.lean -> PSC1 -> TypeScript -> tsc -> JavaScript
```

This is the point where the earlier "pretend PSC1 is finished" assumption is
discharged by an actual compiler run.

### KSH10 — generated ProofScript source

Use the completed compiler to generate canonical `.ps`, then require
`.lean <-> .ps` checked-core/IR parity before promoting `.ps` to maintained
source.

## Formal assurance relationship

The new kernel does not prove itself correct.

The preferred trust stack remains:

```text
self-hosted kernel implementation
        +
finished TypeScript kernel differential oracle
        +
pinned Lean Kernel Arena / Lean 4.34 evidence
        +
verified ConLeche co-signer for formal certification
```

That avoids circular trust while still allowing the implementation language of
the kernel itself to become ProofScript.
