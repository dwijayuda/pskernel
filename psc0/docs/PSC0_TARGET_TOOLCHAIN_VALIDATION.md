# Target toolchain validation ledger

## Initial coherent implementation

Implementation: `011dac43b802b1a092119d21f884e3388f6b300b`.
Fast workflow: [38085378252](https://github.com/dwijayuda/pskernel/actions/runs/38085378252).

Both OS jobs passed exact compiler/kernel source preservation, the 23-workspace schema and the full 66-test host suite. The Linux job `114310668262` also passed the installed PS source/library application and frontend direct/worker correspondence. It then failed the new target comparison fixture's assertion that merely placing an invalid declaration under surrounding `node_modules/@types` must make the original TypeScript invocation fail. The workflow is a failed checkpoint, not complete qualification. Neither the new target correspondence nor the full two-edition result was established by that run.

## Research-backed fixture correction

The premise was wrong: TypeScript6 changed the `types` default to an empty array, retained by the tested TypeScript7.0.2. The official release notes document the change and require an explicit types entry or `*` to request external declarations: https://www.typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html#types-now-defaults-to- . The old generic typeRoots documentation was insufficient evidence of the pinned compiler's default.

The comparison now has separate controls: (1) the pinned default must succeed even when nearby malformed typings exist, (2) explicitly requesting those typings with `--types psc-target-noise` must report the actual declaration syntax error, and (3) the fixed checked-target plan must emit the same four products as the clean retained launcher despite that external package and a surrounding tsconfig requesting it and noEmit. This corrects the tested proposition; it does not claim an ambient-type vulnerability in the original TypeScript7 default.

All production code, fixed target options, identity/refusal rules, the 66 existing host tests and compiler/source baselines remain unchanged. Native/library drift and old-output-preservation assertions are retained. The full fast Linux/Windows matrix must succeed before target-toolchain qualification is claimed.
