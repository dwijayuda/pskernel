# PSC1 npm package work state

Updated 2026-10-25 Asia/Jakarta. Packages remain unpublished; draft PR178 is unmerged.

## Current installable candidate

[40144094413](https://github.com/dwijayuda/pskernel/actions/runs/40144094413)/
job121021665068 passes actual offline installed generated CLI:
26 host-boundary checks,10 compiler cases,12 application builds/44 observations,
14 refusal/tamper checks, both source grammars and both TS/Wasm engines.
The native compiler executable is unavailable throughout generated compilation.

[Artifact12579329783](https://github.com/dwijayuda/pskernel/actions/runs/40144094413/artifacts/12579329783)
contains proofscript@0.1.0-psc1.3 and matching optional
@proofscript/backend-python/@proofscript/backend-php tarballs. ZIP SHA256:
fa1321d92b4a3bece88e726a60ffbda77343116d04c28fb476770e2793b76322.

| Package | Tarball SHA256 |
| --- | --- |
| proofscript | 203c7b58ec8e1b3c6aaa0cdaa5ead0aff942a9b4beb7ed1e865f83779ae5e3f0 |
| @proofscript/backend-python | 31908f41d567569d35d8f8cd8c8fffab4cbfbff8ae2847bc555f7768d740c34d |
| @proofscript/backend-php | 497c78c2f47b599dc1bf3f4b48cb6a7144e718889d1fbfae021dba0c2b1a7d1a |

Packaging control9b9b0f7b checks out exact implementationdaa73501.
Native sourceec90dc12 is the tested merge with identical tree to reviewdaa73501.
Full40141923929 passes37/37 Practical Core criteria, all seven targets/both
grammars/apps/native and optional-provider execution. Source/build pins remain
strict: use these matching add-ons, not older same-version tarballs.

The core includes native JS/TS/Rust/Wasm core/component emitters, independent
checking integration, locked host dependencies and qualified historical TS/Wasm
G3 engines on closure92654df5. Use `psc generated build` for explicit generated
execution and `psc build` for native compilation. Initial generated publication
is JS. Both paths retain official Lean4.35 admission/strict IR and refusals.
Generated source/asset/adapters/checker/host dependencies are pinned and output
publication is transactional. Invalid UTF8 and changed adapter bytes refuse.

Current-root Rust G2/G3 is running separately in40141718481; no outcome is
inherited by the package. A shared-root/all-four-engine generated release,
other generated publication targets/components, Rust asset integration, clean
reproduction and final release qualification remain pending.
No registry `npm install proofscript` release is claimed. Linux x64/glibc;
generated execution requires Node22.23.3. See the
[install guide](docs/PSC1_GENERATED_PACKAGE.md), [roadmap](docs/PSC1_DEVELOPMENT_ROADMAP.md)
and [runtime receipt](docs/PSC1_RUST_NAT_RUNTIME_QUALIFICATION_2026-10-25.json).

Earlier package checkpoints and their exact receipts remain in Git history.
The [provider guide](docs/PSC1_BACKEND_PROVIDERS.md) retains the unchanged
native protocol, source-only package authority boundary and installation model.
