# 29 October 2026 goal-revision evidence

Review date: 29 October 2026, Asia/Jakarta. This is a read-only implementation/source/literature audit followed by a documentation revision. No compiler/kernel execution, benchmark, proof compilation, package generation, workload mutation or production adoption was performed by this revision.

## Repository identity read live before revision

- Primary `work/psc1-pskernel-t01f-string-20261022`: `a1a041b63ca4f2e34f5223240a7761e086f72f25`.
- Primary root tree: `a491a0b91505c23c88bd1a36657e48387cf2db34`.
- Production source tree: `bbe353e649feed5b796adb164dcec36eaca915ab`.
- Integration `integration/psc1-pskernel-expr-v2-lean435-20261021`: `d746fb8cdcb47f2031ac6db483cf63b7debbcbef`.
- Lean identity remains 4.35.0 / `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
- Root and kernel `AGENTS.md` at the reviewed primary returned 404; previously applicable task constraints remain in force.

All six requested work-state/continuation/completion/progress/remaining-execution/research documents were reread at that immutable primary. Earlier dated entries are preserved verbatim behind a superseding roadmap entry. The current source resource, API, provider/session, declaration and stream-adapter boundaries were inspected directly.

## Actual source bindings inspected

All paths in this table are under `psc1/packages/pskernel-core/src/Ps/` at the immutable primary above. Git blob IDs came from the production subtree listing, and corresponding raw contents were read.

| Path | Git blob | Relevant finding |
|---|---|---|
| KernelCore/API/Outcome.lean | `764c3affe4a884903267722114b3bf1c91444b0c` | Five kernel outcomes already exist; unknown diagnostic suffixes remain internal errors |
| KernelCore/API/KernelContractV1.lean | `33e90b631d86d4b21ce1f4158212ed56d2fa0173` | Declaration request includes axioms; receipts are explicitly process-local observations, not authority tokens |
| KernelCore/API/Provider.lean | `7946d76e56bc06bb1386fdc43d4fd0fe4f2c060b` | Default provider has no native evaluator; exact contract/Lean identity checked |
| KernelCore/API/Session.lean | `b8fcb03d9538cb8d19ff6d68d9bf602577208e34` | Empty-session constructor establishes the public start boundary; caller-created environments remain trusted integration |
| KernelCore/API/Kernel.lean | `955ffc0fcf8b11800aefe13c32e0ef28b767f8e2` | Public full checks and axiom dispatch; AdmitChecked rechecks the request |
| KernelCore/Checker/ResourcePolicy.lean | `22b9fc51823c4ba291d67fa4185d696318054d4f` | Fuel is recursive depth rather than global work; pure calls cannot be interrupted; defaults retain fuel 4096 |
| KernelCore/API/DagAdmission.lean | `65038689074c6340513315baa9b5be4b61c40545` | Owning direct checks and whole-original restart protocol; input axiom headers are handled as declarations |

Also inspected at the same primary: `Admission/Declaration/Admission.lean`, `Admission/Declaration/Validation.lean`, `psc1/scripts/pskernel-arena-replay.mjs`, `psc1/scripts/pskernel-arena435-compare.py`, `psc1/scripts/pskernel-cohort-qualification.py`, `.github/workflows/psc1-pskernel-qualified-cohorts.yml`, and the existing runtime API documentation. The comparator's exact strict completion formula requires all 193 classifications to start with `matched_`, and returns failure otherwise. That file and its criteria remain unchanged.

The strict three-axiom audit of PSKernel's own proof dependencies is distinct from a policy for axiom declarations in checked input streams. The revision requires the latter at the new product boundary and does not claim it already exists.

## Workflow state rechecked

| Run | Head | Live terminal state | Evidence boundary |
|---|---|---|---|
| [40441811683](https://github.com/dwijayuda/pskernel/actions/runs/40441811683) | `619d865cde228ad479c63c97ccbaf8b3e5b77c83` | SUCCESS | Native adoption cohort; old audited receipt supplies statement/count detail |
| [40440807903](https://github.com/dwijayuda/pskernel/actions/runs/40440807903) | `c3e9e35322018373a7855643f6155865fb02d768` | SUCCESS | Earlier detached library package delivery |
| [40436829581](https://github.com/dwijayuda/pskernel/actions/runs/40436829581) | `7e69c90895acf3b0a83ade94d594a368f788a3c5` | FAILURE | Retained aggregate full-workload gates; not converted to preview/full-release SUCCESS |
| [40438887095](https://github.com/dwijayuda/pskernel/actions/runs/40438887095) | `0da4f5be72ac3d84fbddeb8963adb2f9aa1dc10c` | SUCCESS | Isolated finite emitter pair, no original whole-workload qualification |
| [40440382483](https://github.com/dwijayuda/pskernel/actions/runs/40440382483) | `9b5475a1c1c1d6e5508037ca73c0dcb4c2730956` | SUCCESS as diagnostic | Actual export plus rejection on missing `Nat`, no compiler-acceptance claim |

The [27 October evidence](https://github.com/dwijayuda/pskernel/blob/a1a041b63ca4f2e34f5223240a7761e086f72f25/psc1/packages/pskernel-core/docs/evidence/2026-10-27-nested-adoption-and-qualification.md) supplies previously inspected archive hashes, counts, raw comparisons and runtime limitations. No artifact from those runs was downloaded or executed again for this research revision. The distinction between rechecked GitHub terminal states and earlier raw-artifact audits is intentional.

## Primary literature/source pins

- [Lean4Lean, v3](https://arxiv.org/html/2403.14064v3), published paper revision dated 14 September 2025: depth-fueled partial operation, executable/logical expression relation, and the infer-only well-typed-input boundary. Read as this paper's results, not a live statement that its entire repository still has the same proof status.
- con-leche live master was pinned through the GitHub ref API to [`e3fd221f1e43826653e210ff725fb2cc3e0d93f0`](https://github.com/leanprover/con-leche/tree/e3fd221f1e43826653e210ff725fb2cc3e0d93f0). Read `README.md`, `OVERVIEW.md`, `ConLeche/MainTheorem.lean`. The current positivity-based inductive design supersedes older architecture descriptions; its conditional model theorem belongs to its own verified fold.
- Lean Kernel Arena live master was pinned to [`1a1d74fadefaf947e7b1bbcb0f8374892cb9942e`](https://github.com/leanprover/lean-kernel-arena/tree/1a1d74fadefaf947e7b1bbcb0f8374892cb9942e). Read its README on case outcomes, rounds, timeouts, compatibility and prelude assumptions. Its external scoring does not change PSKernel's strict 193-case policy.
- [Lean proof-validation guidance](https://lean-lang.org/doc/reference/latest/ValidatingProofs/): statement interpretation, proof dependencies and independent replay. The live manual is contextual guidance, not a change to the pinned implementation target.
- [The Verified CakeML Compiler Backend](https://cakeml.org/jfp19.pdf), sections 10/11: compiler/runtime proof composition, bootstrapping and interface assumptions.
- [The Trusted Computing Base of the CompCert Verified Compiler](https://arxiv.org/abs/2201.10280), v2: source/target modelling and external-tool trust boundaries.
- [Node 22.23.3 child-process API](https://nodejs.org/download/release/v22.23.3/docs/api/child_process.html): timeout signalling, process lifetime and output behavior. Context for the proposed Linux supervisor, not proof of hard real-time termination or host isolation.

The normative preview contract and research report distinguish each source's established statement from the proposed PSKernel engineering inference.

## Required readback and non-mutation checks

The goal revision changes only Markdown documents. Validate all changed document contents after the commit, compare the actual production subtree with `bbe353e649feed5b796adb164dcec36eaca915ab`, inspect the complete changed-path list, and read back both working refs. Use the live primary as the non-force expected-SHA parent; preserve any concurrent history rather than overwriting it. Leave integration, source, proof modules, compiler/toolchain, workflow/harness bodies, workload inputs, expected outcomes, original budgets and strict comparator semantics unchanged.

Completion of this documentation revision is not completion of Preview 1. The latter remains OPEN against P1–P8; original global status remains **B OPEN / C FAIL / D OPEN**.
