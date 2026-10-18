# M3 deriving motive application — capture-avoiding correction

16 October 2026. Implementation correction; exact combined qualification pending. M3+B remains OPEN.

## Observed failure, not an inferred fixture change

Compiler7998bdc7b654dccf46ddfc0b09d16cf8143b33d0 passed focused recursive Hashable workflow38886292808/job116924732831: generic Nat/Bool instances, checked defining law, three intended-rule refusals and JS/TS/Rust/V8-GC/Wasmtime execution. Artifact12033787117, digest sha256:0b2a21ba6e04aec3f6a742eb459f161f719ca2381f3b695c45ee0be5c4c84ad5. This is focused evidence, not full native-suite qualification.

Native38886292555/job116924732052 failed at source qualification: `case 0: wrong acceptance outcome`. That is the large positive application, not a recursive Hashable refusal. An initial connector log response incorrectly described a nonexistent Python fixture; direct cloud retrieval of the original job disproved that description. No source test was changed on that basis.

Read-only diagnostic38889201213/job116934302815 checked out exact7998, verified native-test blob1496891ff3e665ff5e06fb367b4175c845552b35, and changed only a runner-local entry point to expose the unchanged application's result. Compiler and fixture definitions were unchanged. It reported:

```
APPLICATION_ERROR: elaborate: PSCV0-DATA: deriving recursor minor conclusion mismatch (in DerivingEquality.Pair.deriving DecidableEq)
```

Artifact12040069226, digest sha256:139ac9c2037feaf50fbf366884615eeaf36c4408430dc8f6243a23d9d45a9db6, retains exact source, diagnostic and entrypoint-only diff. Diagnostic success is evidence extraction, not qualification. Earlier diagnostic attempts and receipts remain in Git history; their temporary workflow is removed after its purpose is complete.

## Root cause and correction

The new shared deriving builder first abstracted the result callback into a Core motive, but later invoked the callback again with constructor/field expressions in a fresh branch telescope. DecidableEq's callback creates a Pi binder using a synthetic local ID chosen before branch fields exist. A later field can receive that same ID. Rebuilding the callback then abstracts that field unintentionally, producing a different expected result type. The actual recursor motive had already been abstracted correctly and did not have that collision.

Use ordinary `PsExpr.app motive value` for minor conclusions and induction-hypothesis types instead. Its binder body is already locally nameless; the existing Core application/instantiation machinery performs capture-avoiding substitution. Both type checks remain, as do recursive field metadata checks, scope checks, official kernel validation, erasure and target gates. No special case for Pair/DecidableEq, no weaker assertion and no new budget.

Studied owners: Ps.Elab.DerivingDecEq (rightId/result callback), Ps.Elab.DerivingContext, Ps.Environment.Logic (psLogicPi/psLogicLam), Ps.Core.Abstract/Subst, and pinned Lean4.35.0 Expr free-variable versus bound-variable representation at eb6cafb7290e8bd5f2937522d8d804f58f02bafc. Existing dependent equality and proof-field cases are the regression coverage; no extra duplicated fixture is needed.

The next qualification must pass the unchanged native suite, independent logical replays and focused recursive Hashable workflow on this correction's exact SHA. The parent partial-logical-checking cases also need to run at the measurement stage before any partial semantic qualification claim. No ordinary partial execution or full M3+B closure is claimed here.
