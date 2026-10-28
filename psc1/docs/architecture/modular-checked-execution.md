# Checked execution of the modular compiler

The complete source-owned compiler graph has the same candidate-only interface as
the existing unified compiler service. The host adds resource verification and
reuses the existing checked execution/publication session. It does not implement
a second parser, elaborator, transform, backend or kernel.

## Request path

1. The trusted host selects an absolute graph root, manifest, expected manifest
   hash, JS or TS engine, checker and target consumers. Project source does not
   select these tools. [loader.mjs](../../host-tools/executable/loader.mjs) verifies
   the manifest and complete file inventory before importing the generated entry.
2. [session.mjs](../../host-tools/executable/session.mjs) creates a private,
   exclusive adapter outside that immutable graph. It pins the manifest, every
   graph file and loader helpers as dependencies of the existing
   [generated checked session](../../host-tools/generated-compiler-session.mjs).
3. The existing bounded child runner invokes the genuine generated compiler.
   Graph verification brackets each request. The returned source, canonical
   admissions and original/transformed IR remain candidate data.
4. The checked session checks request/source identity, declaration/body counts
   and exact candidate fields. It submits the identical canonical admission bytes
   to the independently pinned official Lean 4.35.0 checker. The pinned compiler
   retains strict original/transformed IR validation.
5. The existing [target adapters](../../host-tools/checked-targets.mjs) validate
   syntax, types and public ABI using host-selected consumers. An unavailable
   consumer or unsupported ABI refuses.
6. Only that same admitted session can publish its sealed output through
   [transactional publication](../../host-tools/transactional-publication.mjs).
   It rechecks all tool and staged artifact bytes before publication. Copied
   receipts and generated JSON cannot authorize publication.

The graph manifest is trusted build input. Hash checks and exports do not sandbox
arbitrary executable code, prove backend preservation or resolve concurrent
hostile filesystem mutation. Hosts must retain the established trusted-bootstrap
and stable-resource assumptions.

## Invariants and bounds

[verify.mjs](../../host-tools/executable/verify.mjs) rejects path escapes, symlinks,
extra directories/files, wrong cohorts, dependency cycles and ownership mismatch.
It checks expected file size before reading content. Existing bounds remain:
32 MiB per graph file/manifest, 128 MiB aggregate graph, 8,192 files, 257 units
and 257 package records. Graph paths are at most 1,024 UTF-8 bytes and 16 segments.
Compiler input/output remain bounded to 128 MiB; existing 240-second compiler/tool
and 120-second checker requests are unchanged.

Logical admission concerns the exact canonical Core. Ordinary-checked partial
body pairing, strict IR and finite behavior tests remain separate claims; neither
this adapter nor a passing application corpus supplies a preservation proof.

## Reproduce the focused Linux application lane

The [workflow](https://github.com/dwijayuda/pskernel/blob/0489dc6832daf1e4991322c01fb65cbafab8ae2a/.github/workflows/psc1-modular-checked.yml) installs locked
resources, checks syntax/layout, builds the real reference compiler and independent
checker, then runs:

```sh
node scripts/output-abi-native-tests.mjs
node scripts/output-abi-host-tests.mjs
node scripts/typed-io-policy-tests.mjs
node scripts/modular-checked-prepare.mjs
node scripts/modular-checked-applications.mjs
# The second Linux lane runs the final command with bun.
```

Preparation verifies the exact successful PR #205 graph artifact pinned in
[modular-checked-input.json](../../scripts/modular-checked-input.json). It checks
the current compiler source closure, retains native reference candidates for both
output targets, and independently checks them. Execution removes every native
compiler executable before using either generated JS/TS engine. The independent
checker and locked target SDK remain available.

The unchanged CLI/JSON and compiler-like contracts supply four applications:
both .lean and .ps, with 66 behavior cases across those four fixtures. Each engine
compiles them to JS and strict TS: 16 checked sessions and 264 case executions per
host runtime. Tests compare exact candidate, admission, IR and source hashes,
then execute the published output and compare all retained observations.
Direct loader/session negatives also reject wrong manifests, unsupported engines,
reserved tool overrides and an adapter placed inside the immutable graph.
Failures must preserve prior published generations. Changed graph bytes must
prevent publication. Oversized resources and unexpected directories must refuse.

The workflow archives partial evidence even on failure. Its JSON report records
the tested commit and exact graph source identity. Only a successful terminal run
qualifies these obligations; preparation or source inspection does not.

## Remaining scope

This adapter does not switch the .13 default distribution or public API, install
a kernel, expand the deferred pilot, or claim new modular G2/G3/fixed points.
The remaining M3 queue includes the full retained language/library corpus and
seven-backend execution/refusals through the same modular engines. M4 then wires
the checked host into the existing proofscript umbrella and thin psc CLI, with
default independent Wasm checking, root-only installs and watch qualification.
