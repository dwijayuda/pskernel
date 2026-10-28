# Architecture navigation

[Architecture](../../ARCHITECTURE.md) owns responsibility/trust boundaries.
[Pass contracts](../reference/pass-contracts.md) describe invariants, refusal and resources.
[Repository map](../reference/repository-map.md) derives paths/imports from source.
[Host tools](../../host-tools/README.md) own tools, admission and publication.

[Fully modular executable compiler plan](executable-package-modularity.md) is the
current production-modularity direction: proofscript is the installation umbrella,
psc stays a thin CLI, and generated packages gradually follow source responsibilities.
It is a plan, not implemented or qualified functionality. Pilot expansion is deferred.

[Earlier modular distribution research](modular-compiler-distribution.md) retains
the archive findings and historical pilot criteria. Qualified pilot evidence is
preserved; the experimental pilot is not the production release architecture.
