# Mandatory M3 preparation jobs

The recursor authorer's exact existing build/control/replay/export check now runs
in its own mandatory job in the SAME preparation workflow and at the SAME SHA.
The longer foundation/source/runtime job retains every other command, expected
output and refusal. It still builds the native authorer as part of its original
build target roster. No check was removed or downgraded to continue-on-error;
both jobs must succeed for the workflow to pass. No checker or elaborator budget,
toolchain pin, source rule, selected asset or main branch changed.

This makes the recursor job's completed logs and candidate artifact available
before the slower source/runtime job finishes. Do not cancel the latter or
consider an isolated successful job a qualified preparation. Existing workflow
concurrency still permits one running and one pending preparation, with
cancel-in-progress:false. Only foundation writes the shared dependency cache;
recursor authoring restores it and rebuilds exact source without saving it.

The source/runtime artifact keeps its original pscv0-m3-foundation-preparation-SHA
identity. Candidate source, its authoring log, build log, source-sha and toolchain
receipt are under pscv0-m3-recursor-authoring-SHA. Read both when qualifying this
or later commits; old one-job artifacts retain their historical layout.
