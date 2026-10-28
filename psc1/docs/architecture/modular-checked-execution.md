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

## Reproduce the retained semantic and seven-target lane

[Linux run 40695323668](https://github.com/dwijayuda/pskernel/actions/runs/40695323668)
qualifies the following finite matrix at `308f2fd988428d30be7c5fd9cfe0c8ace9242447`.
The [workflow](https://github.com/dwijayuda/pskernel/blob/308f2fd988428d30be7c5fd9cfe0c8ace9242447/.github/workflows/psc1-modular-corpus.yml)
uses the same graph and checked session described above.

| Batch | Existing source families | Checked builds per host | Refusals per host | Published function calls per host |
| --- | --- | ---: | ---: | ---: |
| effects | CompilerM, checked Nat/Int order, multi-module library | 84 | 84 | 1,176 |
| data | collections, JSON records | 56 | 40 | 784 |
| control | bounded inference/control | 28 | 116 | 1,064 |
| io | typed IO protocol and sequencing | 56 | 36 | 448 |

Each host runs both complete JS/TS compiler engines, both source grammars and all
seven targets: JS, TS, Rust, Wasm-core, Wasm-component, optional Python and PHP.
Across Node/Bun this is 448 checked builds, 552 refusal checks and 6,944 public
function calls. Of those calls, 6,048 check individual authored case/flag pairs;
the rest invoke each fixture's aggregate semantic check. The 54 retained authored
case IDs are finite behavioral evidence.

[Preparation](../../scripts/modular-corpus-prepare.mjs) runs the existing native
conformance oracles, then retains their sealed pre-admission source snapshots.
Native PS fixtures import Lean standard-library sources. The homogeneous generated
request protocol is preserved: the existing independently checked source converter
converts only those library sources to PS. Authored PS fixture bodies stay intact.
For all 16 fixtures and all four compiler output targets, native transport
preparation independently checks the resulting admission and requires its exact
bytes to match the original native fixture's admission.

[Resource selection](../../scripts/modular-corpus-resources.mjs) verifies the pinned
graph and target archives in [the input record](../../scripts/modular-corpus-input.json).
The retained .11 archive supplies target SDKs/providers only. Its frozen compiler
executors and all native frontends are moved aside before generated compilation.
The independently pinned checker remains. The test asserts these boundaries
throughout execution, so SDK reuse cannot silently substitute the older compiler.

[Execution](../../scripts/modular-corpus-execute.mjs) admits every generated
candidate, compares normalized candidate JSON, canonical admission, serialized IR
and decoded source against the native reference, then publishes and runs the
checked output. Rust consumers link the checked rlib. SHA-pinned Wasmtime executes
the actual component exports. Wasm-core uses its checked host transport; optional
providers emit and execute their own output. Existing semantic wrappers compare
actual results with native Lean oracle observations.

Every source refusal, unavailable consumer, unsupported component ABI and
unsupported verified-assurance request must retain the prior generation. Failure
to execute or admit prevents publication. The current public component ABI is Bool;
String/Nat/IO component exports are not inferred from Wasm-core transport success.

The CI-only [public-value diagnostic](https://github.com/dwijayuda/pskernel/blob/85f61b4b41546070f5605df884f0c63bfc1a9306/.github/scripts/psc1-modular-public-abi.mjs)
additionally reuses the retained generated-target corpus to expose actual Nat/Int,
Unicode String, list-result, handler and ordinary-loop values. Its receipt records
the independent run, code identity and all six applicable target consumers.
These checks complement the Bool semantic wrappers; they do not broaden the
component ABI.

The [dated semantic receipt](../PSC1_MODULAR_SEMANTIC_QUALIFICATION_2026-10-28.json)
pins the complete matrix, artifact digests, measured timings and regression evidence.
Reproduction commands inside the workflow are:

```sh
node scripts/modular-corpus-prepare.mjs
node scripts/modular-corpus-resources.mjs all
node scripts/modular-corpus-execute.mjs effects
node scripts/modular-corpus-execute.mjs data
node scripts/modular-corpus-execute.mjs control
node scripts/modular-corpus-execute.mjs io
# CI gives each batch an independent job/resources; repeat execution with bun.
```

Run preparation before disabling native frontends. Graph acquisition needs the
workflow's read-only GitHub artifact access and exact SDK provisioning. These are
CI reproduction commands, not an installed-package user interface.

## Remaining scope

The finite retained application and semantic/backend scopes above are qualified.
This adapter does not switch the .13 default distribution or public API, install
a kernel, expand the deferred pilot, or claim new modular G2/G3/fixed points.
M4 wires the checked host into the existing proofscript umbrella and thin psc CLI,
with the default independent linear-memory Wasm kernel, root-only local/global
installs and watch qualification. Real non-JS host-IO applications and additional
platform durability remain their own acceptance tasks. M5 first needs portable
module planning/emission in the canonical compiler, followed by reproduction and
new generation/fixed-point evidence for the complete modular source identity.
