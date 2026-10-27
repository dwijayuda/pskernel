# Source-bound PSKernel-Core runtime

This package executes the PSC1-produced PSKernel checker in Node 22. It needs no Lean executable or compiler at runtime. It is a usable experimental package; global logical soundness, full Arena parity, backend preservation, and genuine compiler self-hosting remain open.

## Run the examples

Download the `psc1-nested-runtime-generated` or `psc1-nested-runtime-canonical` artifact from the delivery workflow, unpack it, and change to the package directory:

```sh
node api-example.mjs
node example.mjs ./kernel.js
node nested-example.mjs ./kernel.js
```

The first example constructs a checked empty public session, checks a sort, and requires rejection of an ill-typed application. The second runs the retained independent checker smoke tests, including negative judgments. The third runs all 36 complete public nested controls against seven retained original environments. Delivery executes all three in separate Node processes with an empty PATH and the unchanged 2,048-MiB old-space limit.

## Public API

Import `* as kernel` from `./kernel.js`. `kernel.d.ts` contains the complete constructor and function signatures. Kernel naturals use JavaScript `bigint`. Generated lists use the exported `List.cons`/`List.nil` constructors. The runnable `api-example.mjs` shows these values directly.

| Entry | Contract |
|---|---|
| `psKernelKernelSessionEmpty(resources, provider)` | Establishes an empty checked session after target compatibility checks. Use the exported default resources and provider for the example. Arbitrary environment records are not checking certificates. |
| `psKernelV1CheckExpression(session, levelParams, safety, expression)` | Fully checks an expression and returns a checked result or a typed kernel error. |
| `psKernelV1Whnf(session, levelParams, safety, expression)` | Checks its input before computing weak-head normal form under the session's resource policy. |
| `psKernelV1IsDefEq(session, levelParams, safety, left, right)` | Checks both inputs before requesting definitional equality. A resource failure is not a proof of inequality. |
| `psKernelV1AdmitDeclaration(session, request)` | Checks the declaration and returns a new session only on success. Earlier immutable sessions remain usable. |
| `psKernelV1RunDag(session, levelParams, safety, arena, commands)` | Validates the public input arena and executes the command batch. External IDs remain bounded by the original input table. Failed batches publish no partial session. |

Successful `Except` results carry `value`; failures carry `error`. Preserve the error classification and resource policy. Infer-only helpers and caller-created metadata are not full-checking certificates. The default provider has no native-evaluator callback and never invokes official Lean to decide an input. Unsupported DAG suboperations may restart the existing PSKernel V1 operation from its original state.

The nested route retains transformed owning admission, pure restoration, independent restored checking, final ownership, error order, resources, atomic publication, and original-state restart on supported decline paths. This finite qualification is distinct from a global admission-soundness theorem.

## Reproduce the source build in GitHub Linux Actions

Use an Ubuntu GitHub Actions job with Node 22. Check out the exact producer source `e58ef33ad14b26dcc85231801b1322551cf34614` with full history. Run these commands from that checkout; the project assignment confines compiler/kernel builds and artifact generation to GitHub Linux Actions:

```sh
bash psc1/scripts/install-lean435-ci.sh
export PATH="$HOME/.elan/bin:$PATH"
cd psc1
test "$(lean --githash)" = eb6cafb7290e8bd5f2937522d8d804f58f02bafc
lake build psc1
lake exe psc1 check test/PsKernelNestedAdmissionSelfHost.lean
lake exe psc1 build test/PsKernelNestedAdmissionSelfHost.lean --out dist/nested/kernel.js
```

The checked reference compiler uses TypeScript 7.0.2. The pinned paired workflow `.github/workflows/psc1-pskernel-t06-nested-public-full.yml` also reconstructs and checks all canonical `.ps` modules, verifies the native axiom allowlist and source bindings, and executes every retained runtime control. Use that workflow's exact tool and dependency setup when reproducing the reference bytes. A new native compiler build can have a different executable hash; its provenance must be recorded independently.

The package includes readable TypeScript, declarations, source maps, the complete Lean source closure archive, and the producer provenance. The canonical artifact additionally contains the complete canonical source archive. `files.json` binds every packaged file. These hashes authenticate bytes, not logical truth.

## Acceptance boundary

The original paired producer is run `40337754189`: 807 named native proof reports, 1,795 native controls, 177 source modules, 1,188 native-equal compiled controls and 21 retained harnesses per route. Its two emitted programs are identical: 10,824,302 bytes, SHA-256 `1e6f22ae728c20306755c7be10118ccc40cd449e2c7e08872a153b5aa7a7f968`.

Run `40436829581` independently audited the raw archives and 1,210 actual Git bindings, then passed all 8,400 unchanged String assertions on each nested route. Both full 193-case Arena candidates retained 174 strict passes, 17 timeouts and two safety-contract differences. All 176 completed raw semantic envelopes exactly matched the retained baseline. The overall workflow is failed because it preserves these failing Arena gates and the separate flat candidate's canonical sample-5 timeout. This package does not turn that aggregate into a passing release gate.

Global status remains **B OPEN / C FAIL / D OPEN**. The compiler's 64-module portable declaration closure and replay diagnostics are separate evidence. Compiling a file named `SelfHost.lean`, executing the checker, exporting compiler declarations, accepting those declarations, obtaining a compiler fixed point, and proving backend preservation are distinct milestones.
