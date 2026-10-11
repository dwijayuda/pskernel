# PSCV0 source bridge — validation ledger

This ledger separates implementation, native source checking, generated bridge behavior and formal fixture correspondence. A cancelled/failed run is never reclassified as success.

## Current checkpoint before generated-bridge qualification

Portable source: `960692ed256f88e24cc03e7c5cd2b15e8ca67362`.
Native run [38097055425](https://github.com/dwijayuda/pskernel/actions/runs/38097055425), job `114345006285`: **success**.
All four new portable modules type-checked using Lean 4.34.0. Native execution passed five PS/readable-Lean/PS round trips, four refusal cases, exact original comment replay and explicit refusal to canonically discard comments. Actual readable `do` output is retained in the logs.
Native evidence artifact: `11685979857`, nine files, ZIP SHA-256 `6822d5d919d0a2024901474d209fff52f63adef54bca68ab5cfb8f563b0edd5e`.

Generated-bridge run [38097055403](https://github.com/dwijayuda/pskernel/actions/runs/38097055403) was still executing at this documentation checkpoint. Its native precondition and retained-runtime installation passed. No generated-bridge, Windows, RC4 or new self-host success is claimed until those jobs actually pass.

## Recorded failed attempts and corrections

| Source/run | Observed failure | Coherent correction |
| --- | --- | --- |
| `7b0b3803062d` / `38094720290` | Workflow validation rejected runner.temp at job-level env; no code executed | Set the prefix through GITHUB_ENV in a runner step |
| `7092ba81c304` / `38095004877` | C0 raw parser rejected expression `::`; no bridge JS produced | Use seed-supported List.cons expressions throughout new source, while retaining admitted cons patterns; add raw-source preflight before expensive prefix preparation |
| `a5932fb84e74` / `38095258615` | Native lane lacked Foundation.List.olean | Build the actual PsFoundation prerequisite as well as PsSyntax |
| `1f62effe6e86` / `38095425532` | Native Module.lean used reserved local names syntax/prefix | Rename sourceModule/importPrefix; Surface/Read had already passed native checking |
| `6eb1cb5f6e42` / `38095954154` | C0 preflight passed but elaboration rejected unqualified Option.none value name | Qualify Option constructor expressions systematically; no old compiler or test change |
| `7f41b6367f40` / `38096114909` | Native first PS round trip stopped at the last Except result-type argument before := | Introduce declaration-owned type-token slicing before the common expression parser, not fixture rewriting |

Native run `38095954144` at `6eb1cb5f6e42` passed type checking of the initial three modules, before behavioral smoke was added. This narrower pass did not establish readable source behavior.

The retained compiler preparation originally spent several minutes reaching new files. The current workflow runs native source/round-trip checks and then raw-C0 parsing of all new modules first. Expensive preparation is limited to the existing syntax/foundation prefix plus the new bridge, not the full compiler or kernel.
