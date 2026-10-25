# Installed unified generated compiler candidate

The unpublished `proofscript@0.1.0-psc1.3` tarball includes genuine qualified
JS, TypeScript, Rust and Wasm G3 execution engines, the retained native compiler,
and official Lean4.35.0 independent checking. Python/PHP output providers are
separate explicitly installed packages. All four engines pass G1/G2/G3 and exact
fixed points on the same frozen120-module compiler source:
`07eedac1888aad3d4192664cea8d21a515d23985f3befd6cb365d0194fee53af`.
Engine source/admission/IR/executable identities and limits are recorded in the
[four-engine receipt](PSC1_UNIFIED_FOUR_ENGINE_QUALIFICATION_2026-10-25.json).
The identity command reports these pins; qualifications never transfer silently
across changed sources. Self-host correctness is separate from final release,
the240s performance target and generated output-target coverage.

Use Linux x64/glibc and Node 22.23.3. Generated JS compilation requires no
repository checkout, Lean/Rust SDK, or Python interpreter. The bundled native
independent checker remains mandatory.

[Production package run 40152769340](https://github.com/dwijayuda/pskernel/actions/runs/40152769340)
passed20 compiler cases,24 application builds with88 observations, and
26 refusal/tamper checks across all four engines and both source grammars.
The native compiler executable was unavailable during generated compilation.
[Artifact 12582649787](https://github.com/dwijayuda/pskernel/actions/runs/40152769340/artifacts/12582649787)
contains the core and matching optional-provider tarballs.

| File | SHA256 |
| --- | --- |
| Artifact ZIP | da6a88220337c601fcf401ea7e06a55c45988f96c0a5692d28e958ed07c61916 |
| proofscript-0.1.0-psc1.3.tgz | 29a837faedaabb8c7e6ae30cec19ac53680084b5188de0eef2b7eabbd4f09198 |
| proofscript-backend-python-0.1.0-psc1.3.tgz | a9e26065a916ba53405897a29bdcb6b0cb4b750fef516e2948ad0c30a1a3e1bd |
| proofscript-backend-php-0.1.0-psc1.3.tgz | 7eaaa1f667e9783803e2402ce5d1adb6bd0d867faf665dbb8c5e406a260afaec |

Verify these hashes after extracting the artifact. Install its matching files;
earlier candidates use the same development version with different bytes.
No npm registry release or merge has been performed.

```sh
npm install --ignore-scripts ./proofscript-0.1.0-psc1.3.tgz
npx psc --identity
npx psc generated --identity
npx psc generated build Main.ps --engine rust --out dist/generated
npx psc generated build Main.lean --engine js --out dist/generated-js
npx psc generated build Main.lean --engine ts --out dist/generated-ts
npx psc generated build Main.ps --engine wasm-core --out dist/generated-wasm
node --input-type=module -e 'import("./dist/generated/current/target.mjs").then(console.log)'
```

A single file must have a valid identifier filename and supported `.lean` or
`.ps` grammar. Source is decoded as exact UTF8; invalid UTF8 is refused.
For imports, capture modules in dependency order in a project file:

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
npx psc generated build --project project.json --engine rust --out dist/generated
```

Use explicit `ordinary-checked` assurance only for the supported ordinary slice.
All captured modules use one grammar. This installed generated path currently
publishes JS; other generated publication targets are explicitly refused.
Normal `psc build` retains native JS/TS/Rust/Wasm core/component output.
Install either matching optional provider explicitly:

```sh
npm install --ignore-scripts ./proofscript-backend-python-0.1.0-psc1.3.tgz
npm install --ignore-scripts ./proofscript-backend-php-0.1.0-psc1.3.tgz
```

Local and global offline provider installation is tested. Optional peer metadata
prevents an implicit second compiler install; exact source/native/resource
identity checks still control provider execution. See the
[provider guide](PSC1_BACKEND_PROVIDERS.md).

Every generated build requires official independent Lean 4.35.0 admission,
strict original/transformed IR in the pinned generated pipeline, exact source
capture, target syntax/public-API checks and transactional publication.
Engine, adapter, checker and imported host files are pinned before and after
execution/admission. Refusals preserve existing accepted output. No native
compiler fallback is used. The Rust host guard enforces a 240-second ordinary
request deadline, bounded request/response/streams, process-group cleanup and
caller-death cleanup. Its ten actual process/integrity regressions are required
in normal CI.

[Clean installed run 40152578991](https://github.com/dwijayuda/pskernel/actions/runs/40152578991)
passed16 local/global builds across four engines and both grammars with no
checkout/build tree and no compiler SDK or Python on the execution PATH.
It uses the byte-pinned candidate artifact 12583067653; production package
40152769340 separately repeats installed corpus/application/refusal qualification.

JSON-record and CLI-argument applications exercise real multi-module sources,
Unicode, surrogate, duplicate-field, shape, help and arity cases in both
grammars. Standard-library `.ps` capture uses the existing owned translator.
Recorded compiler execution includes cold engine startup and host supervision.
The package receipt records exact times for every real application/engine pair.
These single-run observations do not qualify the separate240-second whole-compiler
performance target or constitute a controlled cross-run benchmark.

The [package receipt](PSC1_GENERATED_PACKAGE_QUALIFICATION_2026-10-25.json),
[Rust receipt](PSC1_RUST_INSTALLED_QUALIFICATION_2026-10-25.json), and
[current work state](../AI_WORK_STATE.md) distinguish installed qualification,
same-source generation qualification, clean reproduction and release work.
All four installed execution engines are self-host qualified; other generated
publication targets, clean full-generation replay and final release are unfinished.
No unrestricted-language, formal compiler-preservation/DDC or cross-platform
claim is made. allFourEngineSelfHostQualified=true and
allFourEngineReleaseQualified=false record this distinction.
