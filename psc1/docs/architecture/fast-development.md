# Fast installed .ps development

The .5 Linux/Node host is [qualified by actual installed execution](../PSC1_DEVELOPMENT_QUALIFICATION_2026-10-29.json).
It reuses the unchanged qualified JS/TS modular compiler graph and the official
Lean 4.35.0 C++ kernel compiled to linear-memory WebAssembly.

## Use it

Install the matching artifact tarballs rather than mixing distribution versions.
Nothing is published to npm. With Node >=22.23.3:

```sh
npm install --offline --ignore-scripts ./proofscript-0.1.0-psc1-modular.5.tgz
npm exec -- psc check Main.ps
npm exec -- psc check Main.ps --watch
npm exec -- psc build Main.ps --target js --out out --watch
npm exec -- psc build Main.ps --target ts --out out-ts --watch
npm exec -- psc build Main.ps --target js --out audit --evidence full
```

Strict TS output additionally needs the matching TypeScript and Linux-x64 SDK
tarballs. The delivery ZIP includes these separately; its INSTALL.md records
the exact offline installation command.
Other backend consumers retain their existing explicit installation/refusal rules.
A check without target checks the language; use `check --target ts` when target
support and strict target compilation are also needed.

## Pass invariants and failures

| Stage | Invariant | Failure behavior / resources |
| --- | --- | --- |
| Capture | Exact declared source bytes, module order, grammar and entry | Superseded source refuses publication; no implicit discovery |
| Preparation | Existing generated capture/preparation/closure functions | Strict original IR validation still runs on every cache hit |
| Admission | Fresh official independent Lean admission on every request | Rejection fails closed; no acceptance cache |
| Emit and consume | Original generated build service, strict transformed IR and existing target consumers | Source-only check cannot publish; target refusals unchanged |
| Evidence | Compact receipt preserves request/source/tool identities and admission result | Full dumps opt in; validation is never optional |
| Publication | Existing transactional protocol and final source identity guard | Failed rebuild retains the committed generation |
| Warm watch | Private sequential Linux/Node worker, no network endpoint | 240s/request, 4096MiB heap, 8MiB stack, 64 attempts; owned group termination |

Check preparation reuses exact in-memory module prefixes. A changed source
invalidates the suffix; grammar/entry/source order and assurance bind the cache.
Errors clear reuse. No disk cache can seed acceptance. Both JS and TS generated
runtime representations have explicit host adapters. Compiler functions and
generated graph bytes are unchanged.

Resources are deduplicated within each capture/pass; fresh before/after comparisons
remain. Ordinary requests call the real kernel directly, avoiding a separate health
process. Explicit kernel metadata APIs still perform the health check.

Builds retain their original generated candidate service and emitter. Warm watch
keeps modules loaded, but does not reuse build preparation yet. Strict TS JS and
declaration sidecars are still generated. Other operating systems and Bun retain
the previous one-shot watch route; this new .5 host is only Linux/Node qualified.

## Measurements and next work

[Baseline40835944173](https://github.com/dwijayuda/pskernel/actions/runs/40835944173)
and [candidate40840703422](https://github.com/dwijayuda/pskernel/actions/runs/40840703422)
each sample two cold processes on a tiny .ps program.

| Operation | .4 mean | .5 mean |
| --- | ---: | ---: |
| check | 3824ms | 3403ms |
| js | 4844ms | 4568ms |
| ts | 5395ms | 5275ms |

A three-module leaf edit takes 2689ms and reuses two preparation modules. These
are small observational samples, not universal performance claims. The build
watch editMs field includes a subsequent negative test and is not a rebuild time.
Resource verification still takes 1.2–1.36s/session; cold build gains are small.

Next measure repeated hashing/startup by stage before changing their architecture.
A prepared build adapter or persistent independent kernel needs its own measured
benefit and precise identity/resource design. Neither is required for this slice.
Existing source/security regressions remain. New full installed qualification is
manual; exact source adoption reuses the tested tarball without a rebuild, broad
platform matrix or repeated G1/G2/G3.
