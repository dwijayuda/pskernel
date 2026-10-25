# Generated compiler IO applications

Status: new-source G1, checked host-session applications and supported IO target
mappings pass. All four new-source G2/G3 and exact fixed points pass.
Installed npm qualification also passes 40230101814. This is a Linux-qualified development milestone; final
universal platform/publication qualification remains separate. Read the dated receipt and
[work state](../AI_WORK_STATE.md) for exact source and CI identities.

## Select the output ABI explicitly

The default remains scalar output. A program with a final String dispatcher
requires `outputAbi: 'io-dispatcher'` in the host API or the CLI option
`--output-abi io-dispatcher`. The request reaches the existing compiler frontend,
elaborator, strict IR pipeline and backend IO signature check. It does not install
a second compiler or grant host capabilities.

```sh
psc build --project project.json --output-abi io-dispatcher --out dist/app
psc build --project project.json --output-abi io-dispatcher --engine wasm-core --out dist/app-wasm-engine
```

The engine selects which generated compiler executes. Checked output is still JS.

| Engine | Execution | Installation |
| --- | --- | --- |
| js | Generated JS | Included |
| ts | Generated TS, precompiled to JS | Included |
| rust | Genuine compiled Rust compiler | Explicit optional Linux x64/glibc package |
| wasm-core | Genuine compiler Wasm GC artifact | Explicit optional package |

The default independent checker is the official Lean 4.35 C++ kernel compiled
through Emscripten to linear-memory Wasm. It is distinct from compiler Wasm GC.
Optional native checking remains explicit, including `--kernel both`.
No checker or executor fallback occurs on absence, corruption, refusal or timeout.

Project JSON still contains only `entryModule`, dependency-ordered
`sources: [{module, kind, text}]` and optional `assurance`. It cannot select
the ABI, compiler/checker tools, output directory, filesystem root or capabilities.
Imports require their complete captured source closure. Automatic npm source
resolution is a separate capability; installing a source package does not execute
its JavaScript or confer checker/host authority.

## Supply host-owned IO capabilities

The explicit `proofscript/io` entry reuses the existing bounded Linux String
dispatcher. This example reads one UTF-8 file through a separately checked program:

```js
import path from 'node:path';
import {pathToFileURL} from 'node:url';
import {build} from 'proofscript';
import {withTypedIo} from 'proofscript/io';

const built = build({
  entryModule: 'Entry',
  sources: [{
    module: 'Entry',
    kind: 'lean',
    text: 'def run (request : String) (dispatch : String -> String) : String := dispatch request\n',
  }],
  outputAbi: 'io-dispatcher',
  out: 'dist/read-file',
});

const config = {
  abi: 'psc1-node-linux-string-io/1',
  capabilities: ['readUtf8'],
  required: ['readUtf8'],
  root: path.resolve('data'),
  maxFileBytes: 1048576,
  maxLineBytes: 4096,
  inputFd: 0,
  outputFd: 1,
};
const reply = await withTypedIo(
  config,
  () => import(pathToFileURL(built.artifact).href),
  (program, io) => program.run(
    JSON.stringify({op: 'readUtf8', path: 'input.txt'}),
    request => io.execute(request),
  ),
);
console.log(JSON.parse(reply));
```

The host chooses the existing root directory, byte limits, descriptors and allowed
operations: `readLine`, `writeLine`, `readUtf8`, `writeUtf8`.
Required-capability preflight runs before loading the program. The adapter enforces
its existing exact configuration, UTF-8, size, path, symlink and file-type policies.
Typed IO errors remain replies; unexpected host traps escape. The adapter does
not admit or select programs. It refuses unsupported operating-system ABIs.

`compile()` returns checked JS bytes and a receipt without publishing a generation.
`build()` retains complete immutable generations, integrity checks, Linux fsync
and the atomic current pointer. Other-platform publication remains refused until
equivalent semantics and actual platform tests are qualified.

## Wire compatibility and output mappings

Legacy scalar requests remain exactly seven-cell `psc1-compiler-service/1`.
The explicit IO request is eight-cell `psc1-compiler-service/2`, ending in the
literal `io-dispatcher`. Request type and assurance are still validated. The
successful candidate must match its selected protocol, exact field set, request/source
identity, target and ABI. An IO candidate cannot enter a scalar session. Refusals retain the existing
candidate-only refusal envelope and expose no output source or admission verdict.

The checked host session independently checks the actual canonical logical graph,
retains strict original/transformed IR checks from the pinned compiler, checks JS
syntax and exports, and seals exact output identities before publication.
Its receipt does not assert a source-to-Core or backend-preservation theorem.

The candidate API can emit existing JS, TS and Rust IO mappings. It returns
`logicalAdmission: 'not-run'` and `publicationAuthority: false`; separate
independent checking/consumer tests do not turn that API into checked non-JS
publication. Callback IO output to Wasm-core/component refuses this ABI explicitly.
The preserved native distribution's Wasm String/IO path remains available with
its own ABI and qualification. All seven native mappings and optional Python/PHP
providers retain their regressions.

## Exact acceptance boundaries

- Four genuine G1 engines: existing 40 cross-target cases and nine envelope refusals
  per engine, plus 35 native/generated IO/scalar/refusal comparisons.
- Checked host sessions: 16 real 11-module applications and 264 actual cases,
  across both grammars and all four engines. Independent checking, Linux
  publication, JSON/file/CLI errors and the 100,000-statement workload execute.
- Supported target mappings: 24 actual JS/TS/Rust consumer runs and eight explicit
  Wasm callback-output refusals, with one canonical admission graph across
  grammars and targets.
- Installed adapter preflight: offline local/global regression suites, packed
  public types, real `proofscript/io` operations and preflight refusals. Its
  preserved G3 payloads use the old source and refuse the new compiler request.
- New compiler promotion: genuine G1/G2/G3 and exact fixed points for each engine
  are mandatory. G1 evidence is explicitly rejected as insufficient for G3.
- Installed new-source npm qualification passes 40230101814: 264 application cases,
  eight global cases, eight metadata authority refusals, 24 target consumers/eight
  explicit ABI refusals and packed public types. It checks both official kernels
  on the complete compiler graph. [Installation](PSC1_GENERATED_IO_INSTALL.md).
- Final platform release checks remain separate; npm metadata alone is not a pass.

Compiler/tools/G1/corpus remain 240 seconds; checker requests remain 120 seconds.
Long correctness profiles apply only to existing manual G2/G3 requests. Original
240-second selfcompile performance, formal compiler preservation and the final
cross-platform release remain separate qualifications. No npm publication is
authorized by these development artifacts.
