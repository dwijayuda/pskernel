# Checked-host validation ledger

## Initial coherent implementation

Source: `07f8760bdeaf642c98df3c59b460bf6faddb666d`.
Fast workflow: [38081492032](https://github.com/dwijayuda/pskernel/actions/runs/38081492032).

Both platforms passed exact qualified-source preservation: **69 compiler source files**, **64 bootstrap-closure modules**, source inventory SHA-256 `fc08090151979be64458352a030a2aaa11bc0df5aab6a3e8cc71b3c4213ad0de`. Kernel source and adapter, compiler language, seed and TypeScript pin remained unchanged.

Linux job `114299150420` passed workspace validation, all **30** host tests, retained-artifact verification, npm repacking/installing, both installed PS/Lean compiler-closure scans and checked application/library smoke tests.

Windows job `114299150647` passed source preservation, workspace validation and **29/30** host tests. The unchanged input-overwrite test caught a real path-representation defect: comparing the canonical output parent with a noncanonical input spelling did not reliably identify the same Windows file. It failed before runtime artifact retrieval and installed tests. This failure remains recorded and is not reclassified as success.

The separate workspace-contract workflow [38081491966](https://github.com/dwijayuda/pskernel/actions/runs/38081491966) passed at this source, correcting the pre-existing missing-sourceRoots regression while preserving source-directory validation.

## General publication correction

Source: `b97a66cfb06fdf746ab12004dc975b286d730b5c`.
Fast workflow: [38081879291](https://github.com/dwijayuda/pskernel/actions/runs/38081879291).

The publication owner canonicalizes both requested output and protected sources using the filesystem and compares platform-appropriate path identities. It checks at publication entry and immediately before the single executable switch. The original failing test remains unchanged. Cleanup failure after the switch is diagnostic-only; it cannot misreport a completed commit as a failed build.

Linux job `114300311933` passed the entire workflow again. Windows job `114300311778` passed **30/30 tests**, source preservation and workspace checks, then failed in the CI-only repacker: Git Bash's GNU tar interpreted the `D:` drive prefix in the archive filename as a remote host. No installed Windows host execution occurred in this failed job.

## Portable retained-artifact transport

The repacker now supplies the exact digest-verified archive bytes on stdin and sets the process working directory through Node, removing all archive path syntax from tar arguments. This fixes the transport boundary for GNU/BSD tar without choosing another runtime, modifying tests, or regenerating compiler/kernel binaries.

The correction changes no compiler, kernel, language, seed, host acceptance implementation, test expectation or self-host baseline. A new fast workflow must qualify the complete Windows installed-host path before completion is claimed.

No full compiler C2/C3 reproduction or kernel regeneration is executed in this host-validation loop.
