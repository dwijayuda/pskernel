# Two ProofScript modules in a TypeScript project

This example imports two generated neighbors from an ordinary TypeScript
consumer. The compiler publishes one project bundle and thin re-export files:

- `src/Quantity.ps` owns the opaque `Quantity` type and `makeQuantity`.
- `src/Main.ps` imports `Quantity` and exports `readQuantity` and `sameQuantity`.
- `src/Quantity.ts` and `src/Main.ts` expose only the selected public API.
- `src/generated/library.ts` contains the shared runtime and implementation.
- `src/consumer.ts` is handwritten and remains unchanged by the compiler.

The root `proofscript.exports` map selects the public declarations.
`internalValue` is deliberately omitted. Source ownership comes from compiler
preparation, and the two facades use the same opaque runtime identity.

## Run the preview

Copy this directory outside the installed package. The current preview is
distributed as a candidate tarball; install that exact tarball locally:

```sh
npm install --ignore-scripts --save-dev --save-exact /absolute/path/to/proofscript-0.1.0-preview.3.tgz typescript@7.0.2
npm run build
npm start
```

On PowerShell, replace the tarball path with its Windows path. The example's
scripts invoke the installed JavaScript launchers through Node. No Lean
installation or package lifecycle script is required.

The build first runs the checked ProofScript transaction, then runs TypeScript
7.0.2 with the supplied strict NodeNext / ES2022 configuration. The expected
output is:

```text
ProofScript library answer: 42
```

## Checked boundaries

`Nat` uses `bigint` at this interface. A negative `bigint` is rejected at
runtime. `Quantity` values are frozen opaque handles produced by checked
ProofScript functions; a cast, lookalike object or proxy cannot create an
accepted handle. Passing a valid handle between the two facades retains its
identity.

This pilot covers a pure acyclic module graph and a bounded first-order ABI.
It does not enable dependent, generic, callback, array or erased-proof
parameters at the public boundary. Kernel admission and checked RuntimeIR
emission remain mandatory; full compiler semantic-preservation and PSCV proofs
are separate work.

Use one-shot build ordering as shown above. Full `psdev --watch` and
coordination with an independent TypeScript watcher remain later milestones.
