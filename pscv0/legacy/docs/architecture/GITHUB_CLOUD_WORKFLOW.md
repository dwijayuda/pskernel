# GitHub-first cloud development workflow

**Status:** active repository workflow for ongoing PSC2 development.

## Canonical source of truth

Repository:

```text
dwijayuda/pskernel
```

Current integration branch:

```text
psc2/selfhost-lean-kernel
```

GitHub is the canonical source of truth for source, architecture documents, contracts,
issues, checkpoints, and branch history.

A local checkout may be used as an execution cache or emergency diagnostic environment,
but future work must not depend on unpushed local files, local-only state, or a particular
developer machine.

## Cloud-first operating rule

Every development task starts by reading the current GitHub branch head and relevant
repository files.

For nontrivial work:

1. read the latest integration-branch state from GitHub;
2. inspect relevant source/contracts/tests from GitHub;
3. make the smallest coherent change;
4. preserve ProofScript's self-host-safe source discipline;
5. run available cloud/CI checks, or explicitly record checks that still require a
   dedicated execution runner;
6. create a meaningful commit;
7. re-read the integration branch before updating it;
8. update refs only by fast-forward;
9. never force-push over newer remote work;
10. publish checkpoints regularly rather than accumulating a large hidden workspace.

If the integration branch advanced during work, reconcile from the newer GitHub state
instead of overwriting it.

## Branch policy

Preserve existing branches and history.

Do not:

- delete remote branches unless explicitly requested;
- rewrite published history;
- force-push the integration branch;
- replace a newer remote head with an older local/cloud head.

For larger experiments, create a topic branch from the exact current integration head.
Topic branches should have descriptive names such as:

```text
codex/runtime-semantics-v1
codex/direct-js-ir
codex/wasm-selfhost-normalization
codex/project-query-graph
```

Integrate only by an explicit reviewed merge/fast-forward path.

## Checkpoint policy

Push a coherent checkpoint when a meaningful invariant closes, for example:

- contract/version boundary frozen;
- validator slice becomes fail-closed;
- backend dependency layer is cleaned;
- runtime semantic slice is frozen;
- direct-JS differential slice passes;
- Wasm self-host normalization family is completed;
- incremental query invariant is established.

Avoid holding multiple completed architectural steps only in an ephemeral environment.

## Self-host-safe source rule

Lean/ProofScript source intended for the portable compiler/self-host closure must continue
to use the proven `PSC1-selfhost-stable/1` implementation discipline unless that profile
is deliberately revised.

Prefer:

- explicit constructors;
- explicit structural recursion;
- single-scrutinee matches;
- explicit list traversal;
- bounded fuel where required;
- generic invariants instead of one-off repair guards.

Do not reintroduce failure-hunting development as the primary migration strategy.
For large source normalizations use:

```text
static incompatibility inventory
  -> mechanical rewrite families
  -> whole-closure check
```

## Validation ladder

Keep fast and authoritative gates separate.

Typical progression:

```text
focused unit/invariant checks
  -> source-profile checks
  -> semantic-boundary checks
  -> changed-area compiler/backend tests
  -> current-source self-host/fixed-point gate
  -> cold/oracle validation for semantic checkpoints
  -> release/native/provider-specific gates when required
```

A cache or cloud build is an optimization; it never becomes semantic authority.

## Current architecture authority

The active checked-provider contract is:

```text
proofscript-kernel-contract/1
```

Current default provider:

```text
lean434-wasm
@proofscript/pskernel-lean-wasm
```

Long-term target provider:

```text
pskernel-core
```

The provider switch must remain a provider-contract migration rather than an erasure/backend
semantic rewrite.

The current executable-IR validation contract is:

```text
psc-verified-ir/1
```

Raw construction IR is not considered validated merely because the historical raw node
family is named `PsVerifiedIr*`.

## Noncanonical local artifacts

The following are local build/scratch state and must not be treated as source-of-truth
inputs:

```text
psc15selfhost/.lake/
psc15selfhost/lake-manifest.json
psc15selfhost/.continuation/
```

Existing files in those locations are not deleted by this workflow migration. They are
simply excluded from canonical repository state unless a specific artifact is deliberately
promoted into a reviewed source/document/test location.

The old `.continuation/` directory contains one-off r3 migration/debug helpers whose
effects are already represented by committed source/history; it is not an active compiler
dependency.

## Project-state handoff

Use GitHub issues, commits, branches, contract documents, and pull requests as persistent
handoff state.

A future cloud agent should be able to reconstruct the task from:

1. the current branch head;
2. the architecture/contract docs;
3. the current tracking issue or PR;
4. executable tests/gates;

without reading a developer workstation.

## Immediate roadmap after migration

Continue the production architecture in this order:

1. extend `ErasedIR -> VerifiedIR` well-formedness beyond unresolved runtime types;
2. clean backend package dependencies so backend cores consume validated IR only;
3. freeze `RuntimeSemantics-v1`;
4. introduce the smallest direct `JsIR` differential slice;
5. normalize backend-wasm source using static/mechanical self-host rewrites;
6. generalize red/green reuse into the project query graph;
7. proceed toward InterfaceIR/capabilities/hermetic artifacts after those semantic
   boundaries are stable.

The architecture documents in `docs/architecture/` remain the detailed design authority.
