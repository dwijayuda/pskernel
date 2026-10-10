# Checked-host validation ledger

## Initial coherent implementation

Source: `07f8760bdeaf642c98df3c59b460bf6faddb666d`.
Fast workflow: [38081492032](https://github.com/dwijayuda/pskernel/actions/runs/38081492032).

Both platforms passed the exact qualified-source preservation check: **69 compiler source files**, **64 bootstrap-closure modules**, source inventory SHA-256 `fc08090151979be64458352a030a2aaa11bc0df5aab6a3e8cc71b3c4213ad0de`. Kernel source and adapter, compiler language, seed and TypeScript pin remained unchanged.

Linux job `114299150420` passed workspace validation, all **30** host tests, retained-artifact verification, npm repacking/installing, both installed PS/Lean compiler-closure scans and checked application/library smoke tests.

Windows job `114299150647` passed source preservation, workspace validation and **29/30** host tests. The unchanged input-overwrite test caught a real path-representation defect: comparing the canonical output parent with a noncanonical input spelling did not reliably identify the same Windows file. It failed before runtime artifact retrieval and installed tests. This failure remains recorded and is not reclassified as success.

## General correction

The publication owner now canonicalizes both the requested output and every protected source using the filesystem before comparing them, with platform-appropriate path comparison. It checks at publication entry and again immediately before the single executable switch. The original failing test is retained unchanged. Cleanup failure after the executable switch is diagnostic-only; it cannot misreport a completed commit as a failed build.

The correction changes no compiler, kernel, language, seed, test expectation or self-host baseline. A new fast workflow must qualify the corrected host on Linux and Windows before completion is claimed.

No full compiler C2/C3 reproduction or kernel regeneration is executed in this host-validation loop.
