# PSC1 current work state — seven direct backends and npm

Updated 2026-10-20. Branch: `feature/psc1-seven-backend-architecture-20261020`.
Stacked on PR #163 at verified HEAD `ea03ce125ad4d4902070d6fef92d92b51cb2e857`.
Parent Linux run [39349606554](https://github.com/dwijayuda/pskernel/actions/runs/39349606554)
is successful. The preserved Practical Core state is in
`docs/history/AI_WORK_STATE_BEFORE_SEVEN_BACKENDS_2026-10-20.md`.

## Scope and authorization

Implement the supplied seven-backend/npm brief through reviewable changes. GitHub and
Linux cloud CI only; no local repository execution, full self-host/census/fixed-point
runs, unrelated branch edits, force updates, merges, releases or npm publication.

Official Lean 4.35.0 commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc` remains the
independent admission provider. Preserve exact captured source, checked logical/runtime
pairing, typed IR and specialization validation, public ownership, artifacts and assurance.
The owned kernel remains separately tested. Verified execution remains unavailable.

## Audit and implementation in progress

- Audited the actual source architecture, active checkpoint and successful parent CI.
- Archived the stale architecture document and wrote current native architecture/decisions.
- Added the minimal backend-common target identity, capability and closed-plan module.
- DirectPython, DirectPHP and native npm packaging/source resolution proceed in isolated
  branches. Integration must inspect their actual trees and retain history.
- New targets are **not yet qualified**. Existing target qualification belongs to the parent.
- Text-based export selection and broad runtime inclusion are identified liabilities.
- Int division/modulo, unqualified machine/float scalars, broad public aggregate ABIs and
  missing Practical Core source forms remain unsupported unless separately implemented.

## Next execution

Integrate target printers and selective runtimes, native CLI/publication and source origins.
Build all relevant focused native tests in Linux Actions, execute actual generated
Python/PHP plus the preserved five-target suites, test TS/JS combined generation and native
npm installation with a real optional source library. Fix failures at the responsible layer.
Record exact source SHA, CI run, runtime versions, output sizes and limitations.
