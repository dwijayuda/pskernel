# Target-toolchain validation ledger

## Final qualified checkpoint

Source: `494a0a715ebd1e29eba2d146903bb6a3a722be06`.
Production code was introduced at `011dac43b802b1a092119d21f884e3388f6b300b` and remained unchanged in the two test/documentation refinements.
Successful fast workflow: [38086137673](https://github.com/dwijayuda/pskernel/actions/runs/38086137673).

| Platform | Job | Unit tests | Installed source editions | Result |
| --- | --- | ---: | --- | --- |
| Linux / Node22.23.3 | `114312964660` | 66/66 | PS and Lean | success |
| Windows / Node26.7.0 | `114312964479` | 66/66 | PS and Lean | success |

Each job passed the unchanged source-preservation guard,23-workspace check, exact retained-runtime verification and ordinary offline npm installation. The existing full64-module installed compiler closure, source-library build and frontend correspondence tests still pass. The new target tests use already generated checked TS as their input, not a compiler/kernel rebuild.

The new installed target gate establishes, on its bounded fixture:
- The new native invocation produces all four `.ts/.js/.d.ts/.js.map` outputs byte-identical to the retained original TypeScript7.0.2 launcher.
- The target plan digest is bound to the frontend checked handle and receipt.
- The TypeScript7 default ignores unrelated ambient types; explicitly requesting the malformed fixture yields its actual type-declaration syntax error.
- Surrounding tsconfig types/noEmit settings cannot replace the fixed target plan. All comparison outputs must be absent before the owned target produces them, so stale reference files cannot satisfy this test.
- Actual isolated installed native-binary drift is refused at publication and preserves the prior executable; actual declaration-library drift is also refused. Modified test-installation bytes are restored in `finally`.

Evidence: Linux artifact `11682836528`, SHA256 `b62f43ee904aee65460ca84ddc8dcb4a40ff7f3b501c0bd929a6929d1d5b8db9`; Windows artifact `11682667446`, SHA256 `a73fa912382176ec6dc5abc02699181ebecb0b4760f6f4ba7467c605d74611ba`. Each has nine source/runtime/installed/frontend/target reports.

## Initial failed comparison premise

Initial implementation `011dac43b802b1a092119d21f884e3388f6b300b`, [run38085378252](https://github.com/dwijayuda/pskernel/actions/runs/38085378252): both OS jobs passed exact compiler/kernel source preservation,23-workspace validation and66 unit tests. The installed target fixture then wrongly asserted that merely placing a malformed declaration under surrounding `node_modules/@types` must make the original TypeScript invocation fail. Complete qualification was not established; the failed checkpoint remains recorded.

The premise was wrong because TypeScript6 changed the `types` default to an empty array, retained by the tested TypeScript7.0.2. The official [TypeScript6 release notes](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html) describe the change. Earlier generic typeRoots documentation alone was insufficient evidence of this pinned version's default.

Commit `17e2964030fa2ac795345ca49cd78e9862df82b4` introduced explicit controls and corrected that claim; its run38085900920 was superseded/cancelled. Commit `494a0a715ebd1e29eba2d146903bb6a3a722be06` additionally made controls use `--noEmit` and required fresh target outputs. Existing unit tests, source-preservation baselines, production target code and drift refusal assertions were not weakened. The complete final matrix then passed.

## Scope

No compiler/kernel regeneration, source retranslation, full C2/C3, public npm publication or manual complete release build occurred. Installed-byte identity is not registry authentication, proof of native compiler correctness, complete race prevention or a hostile-native-code sandbox. See [the contract](PSC0_TARGET_TOOLCHAIN_BOUNDARY.md), [machine-readable qualification](PSC0_TARGET_TOOLCHAIN_QUALIFICATION.json), and [AI work state](../AI_WORK_STATE.md) for exact continuation boundaries.
