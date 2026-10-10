# Checked-host validation ledger

## Final qualified host milestone

**Source:** `2c48a6cca20f081c9d1785d56d3c67d637651a78`.
**Fast workflow:** [38082117579](https://github.com/dwijayuda/pskernel/actions/runs/38082117579), both jobs completed successfully.

| Platform | Job | Host tests | Installed editions | Result |
| --- | --- | ---: | --- | --- |
| Linux / Node22.23.3 | `114301005999` | 30/30 | PS and Lean | success |
| Windows / Node26.7.0 | `114301006107` | 30/30 | PS and Lean | success |

Each job also passed the 23-workspace schema check, exact compiler/kernel source preservation and pinned runtime digest verification. It installed the current host through ordinary offline npm packaging, parsed the full **64-module installed compiler closure**, checked and emitted a two-source library application yielding `42n`, rejected invalid source without replacing its earlier output and refused an unknown unchecked flag. These checks ran for both source editions.

**69 compiler source files** remain identical to qualified source `1fa5559a72b293defc56ef7e7020cf82d4b44b79` and retained runtime source `2f42a52814f3785ff2d92bd826f6e7fb3eb9bc8a`. Inventory SHA-256: `fc08090151979be64458352a030a2aaa11bc0df5aab6a3e8cc71b3c4213ad0de`. Kernel source/adapter, compiler grammar, seed and toolchain pins are unchanged.

Evidence artifacts:
- Linux `11680682736`, SHA-256 `ababa0b4e0ac0e867d1fcdceaee80ec043b11c8e38addbbeb6fa558db0f8e0b3`.
- Windows `11680573015`, SHA-256 `64b825cd10bd183d36e9c5618389d5bbc22033bcdff1c87bf93b27d7f2f30181`.

The runtime came from run `38075437516`, artifact `11678641329`, not from new generation. **No full compiler C2/C3 reproduction or kernel regeneration was executed.** This is inherited source-specific compiler qualification plus current host behavior—not a new full installed self-host fixed point or a kernel soundness proof.

## Initial coherent implementation and retained failures

Source `07f8760bdeaf642c98df3c59b460bf6faddb666d`, [run 38081492032](https://github.com/dwijayuda/pskernel/actions/runs/38081492032): both platforms passed source preservation. Linux job `114299150420` passed all stages. Windows job `114299150647` passed 29/30 tests; the unchanged input-overwrite test exposed a canonical-path comparison defect. It failed before runtime artifact retrieval and installed tests. The failure was not reclassified as success.

The separate workspace-contract workflow [38081491966](https://github.com/dwijayuda/pskernel/actions/runs/38081491966) passed at that source, correcting the missing-sourceRoots regression by validating authoring, publishing and staged-package schemas separately—not by exempting all packages from source checks.

Source `b97a66cfb06fdf746ab12004dc975b286d730b5c`, [run 38081879291](https://github.com/dwijayuda/pskernel/actions/runs/38081879291): publication canonicalized both requested output and protected inputs and repeated ownership checks before the single executable switch. Cleanup no longer misreports a committed build as failed. Linux job `114300311933` passed fully; Windows job `114300311778` passed all30 tests, then the CI repacker's GNU tar treated the `D:` archive prefix as a remote host. No installed Windows host execution occurred in that failed job.

Final source `2c48a6cca20f081c9d1785d56d3c67d637651a78` changes only CI transport: exact digest-verified archive bytes are supplied on stdin while Node sets the process working directory. No runtime, host checking policy, test expectation or self-host baseline changed in this correction. The complete Linux/Windows gate then passed.

## Scope of confidence

The test suite establishes bounded source/authority/publication invariants on the tested platforms. It is not exhaustive protection from hostile in-process JavaScript or a malicious OS. The complete manual release rebuild was not invoked. The old runtime source's grammar and self-host evidence keep their original scope. See [AI_WORK_STATE.md](../AI_WORK_STATE.md) for precise continuation instructions and deferred work.
