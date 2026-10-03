# npm package-shape prototype

This is hand-authored interoperability evidence, not PSC-generated output.

Observed workflow:

~~~text
cd prototypes/npm-codec
npm pack

cd consumer
npm install <path-to-the-generated-tarball>
tsc --noEmit
node runtime.mjs
~~~

The observed run used Node v26.7.0, TypeScript 7.0.2, and npm 12.0.2. All four steps passed.

The consumer manifest intentionally does not commit the temporary file dependency that npm wrote during the observed run. Install the newly generated tarball before running the checks.

This prototype validates only an ESM plus d.ts package shape and clean TypeScript consumption. It does not establish that PSC emits these files correctly.
