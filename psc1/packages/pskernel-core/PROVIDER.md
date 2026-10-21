# Independently executing canonical batch provider

This provider is a limited-scope developer entry point for the current
PSKernel-Core. Both native and generated JavaScript execute
`psKernelV1AdmitDeclaration`, starting with an empty checked session.
They never invoke official Lean to decide an input, initialize an unchecked
environment, use a supplied receipt as authority, or call the legacy
prelude/fuel-expansion routine.

The selected semantic implementation is the preserved **V1 checked API**.
Expression V2 remains an experimental, partial representation migration in
the same source closure. Shipping this provider does not make V2 the default,
retire its V1 fallback, establish a global soundness theorem, or qualify the
full Lean Arena corpus.

## Supported transport and semantics

Input is the existing PSC1 `proofscript-checked-admissions` version 2 JSON
format emitted by `Ps.Bridge.CheckedAdmissions`. This is a batch format;
it is not Lean source or a serialized environment.

The provider accepts these existing wire variants:

- Safe definitions with regular reducibility hints.
- Theorem declarations, with the full proposition and proof checked.
- Inductive groups, through the existing checked nested-inductive dispatcher,
  which retains ordinary/mutual/nested kernel validation.

The expression transport includes bound variables, sorts, constants and
universe levels, applications, lambdas, forall, lets, natural/string
literals and projections. Names retain their structured string/number form.
Decimal strings preserve large natural values; numeric JSON values must be
nonnegative safe integers.

The canonical wire does not carry all low-level kernel features. This
provider explicitly declines axiom/opaque/unsafe/partial declaration
variants, free/metavariable expression variants, metadata variants and other
unsupported forms. Unknown fields (including unsafe flags, externally supplied recursors,
environments and caches) are explicitly declined; they cannot be silently
ignored while checking a different request. Missing fields and invalid
numeric encodings are malformed input. Invalid UTF-8 and unpaired JSON Unicode
surrogate escapes are also malformed; neither runtime may repair them into a
different declaration name or string. Valid paired escapes, literal backslash-u
text and actual U+FFFD remain supported. The library's typed checked APIs and experimental DAG API
have a broader input contract; no capability is inferred from this transport.

Every dependency must be declared earlier in the same batch. There is **no
implicit prelude**. A compiler integrating this provider must produce a
self-contained supported batch, or use an explicitly checked prelude
integration with its own qualification. The historical PSC0 npm provider is
not the deployment path for this checkpoint.

## Build on Linux with the pinned toolchain

Run these in GitHub Actions from `psc1/`:

```bash
test "$(cat lean-toolchain)" = "leanprover/lean4:v4.35.0"
test "$(lean --githash)" = "eb6cafb7290e8bd5f2937522d8d804f58f02bafc"
lake -f kernel-lakefile.lean build psc1_kernel_provider
lake build psc1
lake exe psc1 check packages/pskernel-core/src/Ps/KernelCore/SelfHost.lean
lake exe psc1 build packages/pskernel-core/src/Ps/KernelCore/SelfHost.lean \
  --out dist/kernel-provider/kernel.js
```

The JS build uses the existing PSC1 TypeScript route with TypeScript 7.0.2
and Node 22. Set `PSC0_TSC` to that pinned TypeScript installation as in the
integration workflow. DirectJS emission of the complete kernel is still
unsupported. The build must produce `kernel.js`, `kernel.d.ts`, and
`kernel.js.map`; keep the generated source-map source files when packaging.

Canonical ProofScript follows the existing full-closure bootstrap:
`scripts/bootstrap-project.mjs` reconstructs every imported source;
PSC1 separately checks and builds its `SelfHost.ps`. Run the same provider
tests on that independently generated JS bundle.

## Use

Native:

```bash
.lake/build/bin/psc1_kernel_provider < batch.json
```

Generated JavaScript:

```bash
node scripts/pskernel-canonical-provider.mjs dist/kernel-provider/kernel.js < batch.json
```

The complete runtime dependency closure for that script consists of the
generated bundle, `scripts/pskernel-canonical-provider.mjs`, and
`npm-runtime/canonical-admissions-wire.mjs` in their relative layout. The
last module supplies only the shared wire decoder; no historical prelude
checker or fuel-expansion routine is shipped in this dependency closure.
For embedding, the adapter exports `checkCanonicalBatch(kernel, text)` and
`checkCanonicalBytes(kernel, bytes)`, both returning the same outcome protocol.
Its remaining imports are Node builtins. Neither Lean nor TypeScript is needed at runtime.

To execute in a detached directory, copy those files, keep the relative
`scripts/` and `npm-runtime/` paths, and invoke Node by absolute path
with `PATH=""`. Keep ESM mode with a `package.json` containing
`{"type":"module"}`, or use the generated bundle's `.mjs` extension.
Copy native executables only to compatible Linux systems.

### Real dependent batch

```json
{
  "format": "proofscript-checked-admissions",
  "version": 2,
  "admissions": [
    {
      "kind": "constant",
      "declaration": {
        "k": "definition",
        "n": {"k": "s", "p": {"k": "a"}, "v": "SortAlias"},
        "lp": [],
        "t": {"k": "sort", "l": {"k": "s", "o": {"k": "z"}}},
        "v": {"k": "sort", "l": {"k": "z"}},
        "s": "safe",
        "h": {"k": "regular", "h": "0"}
      }
    },
    {
      "kind": "constant",
      "declaration": {
        "k": "definition",
        "n": {"k": "s", "p": {"k": "a"}, "v": "AliasAgain"},
        "lp": [],
        "t": {"k": "sort", "l": {"k": "s", "o": {"k": "z"}}},
        "v": {"k": "const", "n": {"k": "s", "p": {"k": "a"}, "v": "SortAlias"}, "ls": []},
        "s": "safe",
        "h": {"k": "regular", "h": "0"}
      }
    }
  ]
}
```

Both declarations are checked in order. Changing the first declaration's
type to `{"k":"sort","l":{"k":"z"}}` produces a genuine kernel type
rejection. Reversing the declarations produces an unknown-constant rejection.
A failed later declaration returns no environment or partial admission
authority, and another invocation always starts empty.

## Result protocol

Each process prints one JSON object with
`protocol:"pskernel-canonical-provider/1"`,
`provider:"pskernel-core-v1"`, the exact Lean version/commit, fuel and
`scope:"canonical-v2-empty-environment"`.

| Outcome | Meaning |
| --- | --- |
| `accepted` | Every requested declaration was admitted; includes declaration and environment counts |
| `rejectedInvalid` | A checked semantic validation failed |
| `declinedUnsupported` | The transport or provider cannot support this request |
| `resourceExhausted` | Kernel or host/transport resources prevented completion |
| `malformedInput` | Invalid JSON or request encoding |
| `internalError` | Provider/checker invariant or unrecognized execution failure |

The `accepted` Boolean is true only for `accepted`. `stage` identifies
transport, kernel, provider or complete execution. Failures during a batch
include the zero-based `declarationIndex`; kernel resource failures retain
their category. Receipt counts and digests are observations, never proof
authority.

A completed refusal uses process status 0 with a nonaccepted JSON outcome.
Invocation/load failure uses a nonzero status. A killed process, timeout,
missing output or invalid JSON is **incomplete execution**, never an
accepted input or a semantic rejection. Hosts must enforce their own process
wall-time, memory and output bounds. The regression harness uses 60 seconds
per process and checks status/signal/output before interpreting the protocol.

The kernel default stays 4096. `--fuel 0..4096` exists for deliberate lower
resource limits and sentinels; it cannot increase the default. The native
and generated wrapper both preflight empty batches, so zero fuel cannot
produce an acceptance. Other kernel resource defaults remain unchanged.
Transport limits are 16 MiB input, 20,000 requested declarations and 4096
levels of decoding; they cannot turn failure into acceptance.

## Reproducible qualification and artifacts

```bash
node scripts/pskernel-provider-smoke.mjs native .lake/build/bin/psc1_kernel_provider
node scripts/pskernel-provider-smoke.mjs js dist/kernel-provider/kernel.js
node scripts/pskernel-provider-smoke.mjs js dist/pskernel-selfhost/pskernel-core.js
```

These tests start detached child processes with an empty PATH. They check a
real dependent definition/proof/inductive batch, wrong definition/proof
bodies, duplicate publication, unknown dependencies, unsupported transport,
malformed input, zero fuel, and fresh-session isolation after failure.
`test/PsKernelProviderOfficial.lean` independently checks the exact four-declaration
batch and its four semantic negative cases through official Lean 4.35 with
`doCheck=true`; this oracle is never imported by the provider.

Publish qualification only for the exact tested source revision. Attach the
native executable, generated JS/declarations/maps and map sources, complete
canonical source closure, adapter files and protocol test logs to that
immutable Actions run. A manifest must record the source commit, exact
Lean/TypeScript versions, and SHA-256 of each artifact; verify those hashes
after copying the bundle. These hashes authenticate artifact identity, not
semantic truth. No npm publication or default-provider promotion is implied.

The existing `pskernel-arena-replay.mjs` remains the separately documented
experimental DAG transport. It uses `psKernelV1RunDag`, preserves the
4096-fuel policy, and may exercise original-operation fallback. Its full
Arena gate must be assessed independently of this limited canonical provider.
