# A checked Nat constant

This example defines `answer : Nat` as 42. The generated TypeScript exports it as a `bigint`.

Copy this directory from the compiler's examples/platform location into your own workspace. Install the exact candidate tarball from its actual path:

```sh
npm install --save-dev --save-exact --ignore-scripts "/absolute/path/proofscript-0.1.0-preview.2.tgz"
npm run check
npm run build
```

On Windows, use your actual drive path to the extracted tarball. This preview is not published to npm. Once the exact version is published, `npm install --ignore-scripts` can use the pinned dependency in package.json. Keep the resulting lockfile with this project.

The scripts invoke the local proofscript launcher directly. The root package.json also configures src/Main.ps and src/Main.ts, so an intentionally selected compatible global compiler can run `psc check` or `psc build` without entry/output arguments.

A successful build creates src/Main.ts and src/Main.checked.json. The checking boundary includes PSKernel Core admission, RuntimeIR checks, and the pinned TypeScript target check. It does not claim full PSCV verification or compiler semantic preservation.

Do not edit generated output or the receipt. Change the .ps source instead. An invalid source cannot replace the previous completed output; a manually changed generated file causes a refusal.

The sibling existing-typescript example demonstrates a handwritten TypeScript consumer.
