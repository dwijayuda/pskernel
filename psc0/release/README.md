# ProofScript compiler preview

This package provides the `psc` command with the required TypeScript 7.0.2
backend and protected PSKernel Core admission. It is assembled with a pinned
generated compiler and a pinned native kernel provider. Installation does not
build the compiler, invoke Lean, run package lifecycle hooks, or fetch a kernel.

Preview 1 contains both Linux x64 and Windows x64 native providers and selects
the matching artifact from the actual Node host platform. The compiler bytes
are shared by both platforms. Every required non-system native runtime file
must be bundled and authenticated; no Lean toolchain is required on the user's
machine.

Consumer Node versions are `>=22.23.3 <23 || >=26.7.0 <27`. Qualification targets
Ubuntu 24.04 x64 and Windows Server 2022 x64, each with Node 22.23.3/npm 10.9.9
and Node 26.7.0/npm 12.0.2. The exact images, native dependency evidence, and
results are retained by the
[platform qualification workflow](https://github.com/dwijayuda/pskernel/actions/workflows/psc0-platform.yml).
Other OS/CPU targets are not included. The compiler bootstrap recipe remains
pinned to Node 22.23.3, Lean 4.34.0, and TypeScript 7.0.2; accepting a newer
consumer Node runtime does not change the self-host seed or compiler toolchain.

## Install and use

After extracting the candidate archive produced by the qualification workflow,
run these commands from the extracted directory on Windows PowerShell:

```powershell
npm install --global --ignore-scripts ".\platform\proofscript-0.1.0-preview.1.tgz"
psc.cmd version --json
```

Then, from the intended project directory:

```powershell
psc.cmd check .\src\Main.ps
psc.cmd build .\src\Main.ps --out .\src\Main.ts
psc.cmd extensions --json
```

`psc.cmd` is npm's Windows command shim. The command can also be invoked as
`psc` where the shell permits its PowerShell shim. On Linux:

```sh
npm install --global --ignore-scripts ./platform/proofscript-0.1.0-preview.1.tgz
psc version --json
# From the intended project directory:
psc check src/Main.ps
psc build src/Main.ps --out src/Main.ts
psc extensions --json
```

Preview 0 was Linux-only and cannot be converted into a Windows release by
overriding npm's platform check. Use the new preview-1 tarball.

The npm name is `proofscript`; the executable is `psc`. This repository change
does not publish the package to npm. After a release is published, the ordinary
installation command is `npm install --global --ignore-scripts proofscript`.
A project can instead install an exact release as a development dependency and
invoke `psc` through its npm scripts.

A `.ts` output writes only the generated TypeScript and its checked receipt.
A `.js` output writes the compiled JavaScript bundle and its sidecars.
Existing generated outputs are replaced only when their prior receipt and
contents match; unowned or manually edited files are preserved by refusal.
Windows device names, alternate data streams, and ambiguous trailing-dot or
trailing-space output components are rejected before staging.

The source argument may be a supported `.ps` file or a file in PSC0's bounded
`.lean` subset. Full Lean syntax, full Lean tactics, and PSCV proof authoring
are separate capabilities and are not claimed here. Paths resolve from the
caller's working directory. The nearest `package.json` above that directory
selects the project; an entry outside that project is rejected. Run the command
from the intended project directory. If there is no caller project, an
entry-owned project is selected when one exists.

The only accepted `package.json` ProofScript configuration in this preview is:

```json
{
  "proofscript": {
    "profile": "checked",
    "extensions": []
  }
}
```

Both fields are optional. An unsupported profile, verification option, or
requested extension fails before compilation. A nested source package cannot
replace the selected caller project's policy.

Each invocation reports its loaded external extensions on stderr. There are
none in this preview. `--json` on `check` or `build` returns the detailed
checked-build receipt on stdout. The public command accepts no compiler,
kernel, or TypeScript override; development override environment variables
must be unset.

## Scope of checking

`psc check` admits the canonical declarations through the pinned PSKernel
Core provider; its receipt explicitly reports RuntimeIR as not requested.
`psc build` additionally checks the prepared RuntimeIR before emission.
TypeScript emission and its TS7 compilation must succeed before a build is published.
The receipt identifies the source, compiler, provider, admissions, and emitted
artifacts and states the checks actually performed.

These checks do not establish compiler semantic preservation, PSCV contract
correctness, logical consistency, or a theorem about the emitted JavaScript.
A receipt is an audit record, not a transferable proof capability.

The compiler payload comes from the existing qualified self-host fixed point
at source revision `fcd875c8f38db4b0524090bd10c7c2fd5024053d`. The assembler
requires the maintained compiler source closure to match that evidence.
Packaging the host does not re-prove the compiler or put the Node supervisor,
TypeScript implementation, or native kernel toolchain into the compiler's
self-host cycle. Compiler source and reproduction recipes remain in
[the repository](https://github.com/dwijayuda/pskernel/tree/fcd875c8f38db4b0524090bd10c7c2fd5024053d/psc0).

## Extension and module work still to come

External npm extensions are not executed or automatically discovered. This
preview does not implement a Wasm extension host, `watch`, `lsp`, a VS Code
client, or PSCV profiles. It does not emit neighboring module facades: a build
currently emits one project bundle. These capabilities will be added with
explicit source/module ownership and supervisor-controlled activation.

The required compiler modules remain bundled in this first distribution.
Their architectural boundaries do not require five separately published npm
packages.

## Attribution and release status

The preview package is marked `UNLICENSED` because the repository does not yet
supply a project-wide distribution license. This metadata does not relicense
the existing source. The bundled provider uses Lean; its existing license is
included as `LEAN_LICENSE`. Runtime dependency and license review must follow
the exact linked-library evidence before a public release.
