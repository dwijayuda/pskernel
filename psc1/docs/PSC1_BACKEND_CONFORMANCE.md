# PSC1 backend conformance

The seven-backend integration is in progress. No new runtime qualification is claimed
until its exact implementation commit passes Linux Actions.

The preserved five-target checkpoint is
`ea03ce125ad4d4902070d6fef92d92b51cb2e857`,
[run 39349606554](https://github.com/dwijayuda/pskernel/actions/runs/39349606554).
Its bounded coverage is recorded in `PSC1_PRACTICAL_CORE_SLICE_1_QUALIFICATION.json`.

Current exclusions: Int division/modulo; fixed-width/floating scalars; full Practical Core
families; unrestricted Lean; formal backend preservation; full self-host qualification.
Public Wasm Component ABI remains Bool-only. New target runtime tests must report actual
executed programs and exact limitations, never substitute expected failure for an existing
positive acceptance requirement.
