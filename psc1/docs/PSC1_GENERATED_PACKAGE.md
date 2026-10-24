# Installed generated compiler candidate

The unpublished `proofscript@0.1.0-psc1.3` qualification tarball adds explicit
generated TypeScript and Wasm execution engines alongside the native compiler.
These engines are genuine G3 outputs, independently qualified through G1/G2/G3
and exact fixed points on source closure
`92654df5c0a58fafd3ec9b9b045304706c5992c3eaa34de6b4aadab39a7e00c2`.
Their historical source is recorded separately from the native package build.
Current-root Rust and unified JS qualification remain separate blockers.

Use Linux x64/glibc and Node22.23.3. Download the exact tarball and qualification
receipt from the linked CI artifact in AI_WORK_STATE.md; verify its SHA256.
Packages remain unpublished. No `npm install proofscript` registry release is
claimed. Install the artifact into an application:

```sh
npm install --ignore-scripts ./proofscript-0.1.0-psc1.3.tgz
npx psc --identity
npx psc generated --identity
npx psc generated build Main.ps --engine ts --out dist/generated
npx psc generated build Main.lean --engine wasm-core --out dist/generated-wasm
node --input-type=module -e 'import("./dist/generated/current/target.mjs").then(console.log)'
```

A single file must have a valid identifier filename and supported `.lean` or
`.ps` grammar. Source is decoded as exact UTF8; invalid UTF8 is refused.
For imports, capture dependency modules in dependency order in a project file:

```json
{
  "entryModule": "Main",
  "assurance": "checked",
  "sources": [
    {"module": "Library", "kind": "ps", "text": "def answer : Nat := 42\n"},
    {"module": "Main", "kind": "ps", "text": "import Library\ndef result : Nat := answer\n"}
  ]
}
```

```sh
npx psc generated build --project project.json --engine ts --out dist/generated
```

Use explicit `ordinary-checked` assurance only for the supported ordinary slice.
All captured modules use one grammar. Generated-engine execution publishes JS
in this initial installed path. Other generated targets are explicitly refused.
The normal `psc build` path retains native JS/TS/Rust/Wasm core/component outputs;
matching Python/PHP provider tarballs remain optional. Consult the
[provider guide](PSC1_BACKEND_PROVIDERS.md) for matching-build add-on installation.

Every accepted generated build requires the pinned independent official
Lean4.35.0 checker, strict original/transformed IR validation in the pinned
generated pipeline, exact captured sources, target syntax/public-API checks and
atomic publication. Imported engine/adapter/checker/host files are pinned before
and after execution and admission. Refusals retain an existing accepted output.
No native compiler fallback is used by `psc generated`; the independent native
checker is retained. Installed qualification removes the native compiler binary.

The installed tests execute JSON-record and CLI-argument applications through
both engines and both grammars, with Unicode, surrogate, duplicate-field, shape,
help and arity observations. Standard-library `.ps` capture uses the existing
owned source translator. This is finite installed-application evidence, not
arbitrary-language conformance, formal compiler preservation, or qualification
of an engine against a newer compiler source. The package receipt preserves
these evidence boundaries.
