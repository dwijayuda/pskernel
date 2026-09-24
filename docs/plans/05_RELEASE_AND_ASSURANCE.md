# Release and assurance plan

Status: living release policy.

## Kernel release evidence

A normal pskernel 1.x compatibility release should require:

- direct kernel regression suite green
- Lean-version-pinned differential oracle green
- adversarial regression suite green
- Arena correctness suite green
- Init.Prelude replay green
- selected large real corpora green
- canonical full Std replay green
- no known semantic mismatch hidden as a skip

Full Lean environment and formal equivalence remain higher assurance targets, not ordinary release blockers unless policy changes.

## Package trust labels

Every package README should include one of:

- **TCB**
- **optional TCB extension**
- **untrusted support**
- **test-only**

## Compatibility identifiers

Package/module artifacts should distinguish:
- ProofScript package API version
- module format version
- pskernel API version
- target Lean semantic compatibility version

Do not collapse all four into a single semver.

## Versioning

Before public npm publication:
- freeze package names/scope
- choose licenses
- define compatibility policy
- define experimental/stable channels
- publish provenance/release evidence

## Assurance artifacts

Prefer machine-readable release evidence:
- exact git commit
- Node version
- Lean version/hash
- test counts
- Arena counts
- corpus fingerprints
- Full Std summary, including canonical protocol, root-order provenance, total/replayable constants, and unsafe/partial skip counts
- known optional gates
- prohibited claims

## Anti-drift

Supporting package success must never justify weakening a kernel/corpus test. On mismatch:
1. isolate declaration/case,
2. compare official Lean behavior,
3. fix the responsible semantic layer,
4. add a focused regression,
5. rerun broader gates.
