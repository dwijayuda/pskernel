# ProofScript inside a TypeScript project

This example has one ProofScript source beside a handwritten TypeScript consumer. The source exports `answer : Nat`; the consumer imports the generated `bigint` value from `./Main.js` under ES2022/NodeNext settings.

Copy this directory from the compiler's examples/platform location into your own workspace. Install the exact candidate tarball from its actual path:

```sh
npm install --save-dev --save-exact --ignore-scripts "/absolute/path/proofscript-0.1.0-preview.3.tgz"
npm run build
npm run start
```

On Windows, use your actual drive path to the extracted tarball. This preview is not published to npm. The project also pins TypeScript 7.0.2; npm installs it with the project dependencies. Keep the resulting lockfile.

The build script first invokes the installed proofscript launcher to check src/Main.ps and publish src/Main.ts plus its receipt. Only after that command succeeds does the script run the TypeScript project build. The start command executes dist/consumer.js, which checks the bigint value and prints:

```text
ProofScript answer: 42
```

For admission-only checking, run `npm run ps:check`. For the checked ProofScript stage without the downstream TypeScript build, run `npm run ps:build`.

When adopting this approach in your own project, preserve its package metadata and TypeScript configuration. Add a .ps source and run the checked ProofScript stage before the existing TypeScript build. `psc init` can add the starter source and guide without rewriting existing package.json or tsconfig.json.

This example covers a single source module and a bigint boundary. For a bounded two-module interface with shared opaque datatype identity, see the sibling checked-library example. Arbitrary framework integration, unrestricted FFI and full PSCV verification remain outside these examples. Do not manually edit generated files or their receipt.
