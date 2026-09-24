# Lean Kernel Arena release assurance

This repository pins a compact Lean Kernel Arena corpus as a blocking behavioral
correctness gate.

The source lock is `ARENA_LOCK.json`. It records the exact Arena repository
commit, workflow run/artifact, corpus counts, and content-derived SHA-256
fingerprints. The fingerprints are computed from each NDJSON file's normalized
path, byte length, and SHA-256, so regenerated tar/gzip metadata does not change
the corpus identity.

## Blocking gate

`npm run oracle:arena:pinned` checks all **170 non-performance** fixtures from
the pinned downloadable Arena bundle:

- 101 expected-accept cases;
- 69 expected-reject cases;
- tutorial coverage;
- all compact adversarial `bugs/` and `other/` cases;
- `init-prelude`.

The Arena bundle itself contains 193 fixtures: 122 good and 71 bad. The
remaining 23 `perf/` fixtures are intentionally non-blocking and can be run
with `npm run oracle:arena:pinned-perf`.

The Arena downloadable bundle intentionally omits tests larger than 10 MiB.
Those giant corpora remain useful soak/performance evidence but are not release
blockers.

## Completion policy

For the pskernel production release, the blocking behavioral evidence is:

1. direct kernel/anti-drift tests;
2. official Lean differential/adversarial checks;
3. bounded real Lean/Std corpora and Std release assurance;
4. this pinned Lean Kernel Arena 170-case correctness gate.

The following are **research/soak milestones, not release blockers**:

- monolithic canonical Full Std shared-process replay;
- monolithic Full Lean environment replay;
- an independent compiler-IR native provider;
- a formal equivalence proof.

This policy does not permit stronger claims. Passing the Arena gate means the
pinned Arena correctness corpus passes. It does not prove formal equivalence,
and it does not imply a monolithic Full Lean replay passed.

The native evaluator remains an optional TCB extension and fails closed when no
provider/result is configured, so lack of an independent provider is not a
soundness hole in the default checker.
