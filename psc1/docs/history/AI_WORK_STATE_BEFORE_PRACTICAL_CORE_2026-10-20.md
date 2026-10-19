# PSC1 current work state — scoped repair qualified

Updated 2026-10-20. Branch: `fix/psc1-scoped-correctness-20261020`.

## Exact completed checkpoint

**Implementation `f933691a1d6fa578c59623636afbb02119909837` is GREEN** in GitHub
Linux Actions **run39332460452**, job118333724117. All workflow steps completed
successfully. The evidence is exact-commit, not borrowed from a prior baseline.

Observed results:

- Native compiler/focused executables: 233 Lake build jobs, success.
- Corrected PSKernel-Core: 163 native build jobs and 15 regressions, success.
- Host formatting/maps/WIT/transaction tests: 14 passed.
- Scoped native assertions: 23 passed.
- Existing IR specialization, native map and independent Lean provider suites pass.
- Source-to-backend integration groups: 24 passed, including 10 unqualified scalar
  refusals. Additional source edge groups: 4 passed.
- The edge suite actually executes imported generic specialization, distinct
  mangled symbol identities, empty public modules, and non-tail Nat recursion at
  depth 100,000 in emitted JavaScript.

Archive12224164905 contains 35 readable example/evidence files; SHA-256:
`981902c3e3bbba31043e895042806b09e56ea92545bac883f5f8926837851b48`.
See `docs/PSC1_SCOPED_QUALIFICATION_2026-10-20.json` and
`docs/PSC1_SCOPED_CORRECTNESS_2026-10-20.md` for durable details and links.
A later documentation-only commit preserves these implementation bytes; do not
mistake a later pending documentation/PR workflow for this tested implementation.

## User goal and boundaries

Repair existing compiler/kernel integration and output correctness while keeping
readable JS, TS, Rust, WIT and WAT. Do not add substantial language features,
upgrade Lean, weaken kernel/IR checks, increase fuel, run full self-host suites,
publish npm packages, force-push or mutate unrelated PSC0/main work.
Use GitHub + Linux cloud CI. Fetch actual HEAD before writes. No local checkout,
compiler/kernel build or test execution is authorized in this workstream.

## Current architecture

- Captured dependency-ordered source bytes/ASTs, canonical paths and cycle checks.
  No source reread after admission for target emission or provenance.
- The same immutable canonical declaration graph is independently admitted by
  official Lean before erasure; raw typed IR and specialization input/output are
  checked. Normal host emission goes through a private-constructor session.
- Entry public identities and origins reuse erasure's collision-aware Core-name
  map. Imported helpers remain linked but private. JS declarations and code use
  the same closed checked target plan; internal generic helpers specialize.
- Rust retains its checked generic IR and required public named-type closure;
  the JS scalar public ABI does not accidentally narrow Rust/core Wasm.
- Readable JS/TS use committed locked formatting dependencies and parsed-tree
  stability checks. Maps observe final formatted layout, all captured sources,
  UTF-16 columns, unmapped boundaries and correct negative VLQ encoding.
- DirectJS uses the stack-safe printer. Rust uses rustfmt and ships a usable
  exact-direct-pin, locked Cargo library. WAT is printed from actual final bytes.
- WIT complete bounded signatures are compared structurally to the component.
  WIT capability selection uses the unchanged IR capability contract.
- Each complete target bundle publishes via one atomic current-pointer switch
  to a checksummed immutable generation. Failure retains previous accepted bytes.
- Both npm launcher paths route to the same identity-checked native executable,
  without archived PSC0 compiler/kernel fallback. Duplicate stdlib workspace
  identity is fixed. Formatter dependencies have a committed actual cloud lock.

## Important capability and authority distinctions

The **official Lean 4.34.0 kernel** is the independent current direct-output
admission provider. **Corrected PSKernel-Core source** is integrated and separately
native-regression-tested, not claimed to be that default provider.
Source admission and IR/runtime tests do not prove backend semantic preservation.

Current WIT component scalar is **Bool only**. Previous copied code advertised
integer/float WIT representations that the active IR checker intentionally refuses.
The repair keeps that guard and now refuses those exports explicitly in both
policy and tests. This is not a scalar-feature activation or hidden gate relaxation.

## Remaining work — not blockers silently renamed complete

Separate/incremental module compilation, runtime extraction/tree-shaking, source
expression-level maps, fully structured target diagnostics, formal preservation,
full-language conformance, native platform/npm distribution, making owned Core the
default direct-output provider, optional scalar activation and full self-hosting
remain separate work. Do not expand into these without an explicit workstream.

Publication is per-target and Linux-qualified. A consistent multi-file reader
pins an immutable generation once. Existing ordinary/foreign output paths are
refused; use fresh paths for legacy output migration. JS and TS with the same
stem need separate directories because both own a `.d.ts` path. Old generations
remain available; automatic collection and power-failure proof are not implemented.

`build --target ts` is the qualified formatted TS path. The `typescript` stdout
convenience path still uses the native printer directly. No statement that every
printer path is normalized by Prettier is justified.

The work is prepared for integration review against `psc1/direct-multibackend-v1`.
Do not merge/promote on an uninspected moving HEAD. Preserve the exact tested
checkpoint and distinguish actual PR/integration CI from branch-push qualification.

## History

Baseline0fd7b9aa8bc2f51b21e0cd9477edde35063de0e4 already contained the corrected
kernel source from0a53836489c4e88f46df8f5b8b0c19cc41bafbbb, specialization
rechecks and Lean admission. Repair runs exposed and corrected duplicate npm
workspace identity, Lean record layout and false scalar advertisement before the
complete green checkpoint above. The historical full state remains byte-for-byte
in `docs/history/AI_WORK_STATE_BEFORE_SCOPED_2026-10-20.md`.
