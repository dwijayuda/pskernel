# ProofScript compiler preview

This package provides the `psc` command with the required TypeScript 7.0.2
backend and protected PSKernel Core admission. It is assembled with a pinned
generated compiler and a pinned native kernel provider. Installation does not
build the compiler, invoke Lean, run package lifecycle hooks, or fetch a kernel.

This first preview targets Linux x64. Its qualified operating-system baseline
is the exact runner image, ELF interpreter, C library, and shared-library set
recorded in the package's GitHub Actions qualification run. Other Linux
distributions and other operating systems have not been qualified by this
preview. The package does not include a Lean toolchain.

## Install and use

For a preview tarball produced by the qualification workflow:

```sh
npm install --global --ignore-scripts ./proofscript-0.1.0-preview.0.tgz
psc --version
psc check src/Main.ps
psc build src/Main.ps --out dist/Main.js
psc extensions --json
```

The npm name is `proofscript`; the executable is `psc`. This repository change
does not publish the package to npm. After a release is published, the ordinary
installation command is `npm install --global --ignore-scripts proofscript`.
A project can instead install an exact release as a development dependency and
invoke `psc` through its npm scripts.

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
