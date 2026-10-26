# Repository map

The tracked paths and actual Lean/relative JavaScript imports are read by
[scripts/ci/repository-layout.mjs](../../scripts/ci/repository-layout.mjs).
Run it from psc1 in Linux CI. It writes exact-head machine-readable JSON and Markdown
to dist/readability/repository-map.json and repository-map.md, retained as Actions
artifacts. This guide is the stable entry; generated results are not hand maintained.

| Responsibility | Source |
| --- | --- |
| Portable compiler packages | [packages](../../packages/) and explicit [Lake roots](../../lakefile.lean) |
| Native host | [host/src](../../host/src/) |
| Installed CLI/API roles | [npm-cli](../../npm-cli/README.md) |
| Host authority/runtime | [host-tools](../../host-tools/README.md) |
| Development automation | [scripts](../../scripts/README.md) |
| CLI source behavior | [test/host](../../test/host/README.md) |
| Offline installed behavior | [test/installed](../../test/installed/README.md) |
| Current user guides | [guides](../guides/README.md) |
| Immutable qualification | [evidence](../evidence/README.md) |
| Actual remaining work | [roadmap](../PSC1_DEVELOPMENT_ROADMAP.md) |

The repository root also contains other compiler/kernel workstreams. Their sources,
pins and CI do not qualify PSC1. Existing paths remain; no history is deleted.
The generated map labels legacy, kernel research, tests, production, receipts and
automation separately. It reports imports rather than inventing a parallel semantic
registry. Import edges describe static source dependencies, not dynamic authority.
