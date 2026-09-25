# PSC1 Self-Host Pipeline

The self-host target is package-oriented, not a pair of special
`compiler.ps` / `compiler.js` files.

```text
packages/*/src/**/*.lean
packages/compiler/src/Ps/Compiler.lean
        |
        | one-time Lean 4.34/Lake bootstrap
        v
dist/bootstrap/workspace/
  packages/*/src/**/*.ps
  packages/compiler/src/Ps/Compiler.ps
        |
        | Lean-hosted PSC1 bootstrap
        v
dist/bootstrap/packages/compiler/
  index.ts
  index.js
  index.d.ts
  index.js.map
        |
        | generated JS compiler re-emits its own .ps workspace
        v
dist/selfhost/workspace/
  packages/*/src/**/*.ps
  packages/compiler/src/Ps/Compiler.ps
        |
        | generated JS compiler
        v
dist/selfhost/packages/compiler/
  index.ts
  index.js
  index.d.ts
  index.js.map
        |
        +--> source fixed-point check
        +--> compiler fixed-point check
```

Lean/Lake is required only for the bootstrap generation. After
`dist/bootstrap/packages/compiler/index.js` exists, translation,
canonicalization and JavaScript compilation are performed by the generated
compiler plus thin Node filesystem/`tsc` adapters.

## Package boundaries

```text
selfhost/
  package.json
  psconfig.json
  lakefile.lean

  packages/
    foundation/
    syntax/
    core/
    environment/
    project/
    meta/
    elab/
    bridge/
    compiler-ir/
    erasure/
    backend-ts/

    compiler/
      package.json
      src/
        Ps/
          Compiler.lean
          Compiler/
            Api.lean
      test/
      dist/

    cli/
      package.json
      src/
        Main.lean          # thin Lean bootstrap CLI only
      bin/
        psc.mjs            # stable Node CLI
      test/
      dist/

  host/
    src/
      Ps/Host/
        ProjectCompiler.lean
        CompilerDriver.lean
        TypeScriptCompiler.lean
        KernelBridge.lean

  stdlib/
  scripts/
  dist/
```

`packages/compiler` is portable. It owns compiler composition APIs such as
source translation, parsing, elaboration, checked-admission production, erasure
and TypeScript emission. It must not own filesystem access or process spawning.

`packages/cli` is host-facing. Its Lean `Main.lean` is only the bootstrap
command dispatcher. The Node `psc` binary is the normal post-bootstrap CLI.

`host` owns filesystem/project loading, process execution and `tsc`
invocation. These are outside the semantic compiler and are not part of the
portable trust story.

## One compiler, two hosts

Both bootstrap and self-hosted execution use the same compiler API.

The Lake-hosted bootstrap path supports:

```bash
lake exe psc1 check input.lean
lake exe psc1 check input.ps

lake exe psc1 translate input.lean --to ps --out output.ps
lake exe psc1 translate input.ps --to lean --out output.lean

lake exe psc1 build input.lean --out output.js
lake exe psc1 build input.ps --out output.js
```

The generated JavaScript path supports the same source directions:

```bash
npm run psc -- translate input.lean --to ps --out output.ps
npm run psc -- translate input.ps --to lean --out output.lean
npm run psc -- emit-ps input.ps --out canonical.ps
npm run psc -- emit-lean input.ps --out output.lean

npm run psc -- build input.lean --out dist/index.js
npm run psc -- build input.ps --out dist/index.js
```

The JavaScript host uses
`dist/bootstrap/packages/compiler/index.js` by default.

## Workspace commands

From `selfhost/`:

```bash
npm run check:workspace
npm run check:source
npm run build:lean
npm test

# one-time Lean bootstrap
npm run bootstrap

# generated JS re-emits the .ps workspace and compiles it again
npm run selfhost

# compare source and compiler fixed points
npm run verify:selfhost

# complete chain
npm run fixed-point
```

The stable CLI exposes the same lifecycle:

```bash
npm run psc -- bootstrap
npm run psc -- selfhost
npm run psc -- verify-selfhost
npm run psc -- fixed-point
```

## Stage meanings

### 1. Portable source closure

The authoritative project entry is:

```text
packages/compiler/src/Ps/Compiler.lean
```

`lake exe psc1 check packages/compiler/src/Ps/Compiler.lean` must pass.
This proves the reachable portable compiler workspace fits the frozen PSC1
source subset.

### 2. Lean -> canonical ProofScript workspace

`bootstrap:emit` reads `psconfig.json`, walks the package import graph and
mirrors every reachable portable `.lean` source into
`dist/bootstrap/workspace/**/*.ps`.

No generated `.ps` source is handwritten.

### 3. Bootstrap compiler package

`bootstrap:compiler` compiles the generated package entry:

```text
dist/bootstrap/workspace/packages/compiler/src/Ps/Compiler.ps
```

into:

```text
dist/bootstrap/packages/compiler/index.js
```

with adjacent `.ts`, `.d.ts` and source-map artifacts.

### 4. JavaScript source self-host

`selfhost:emit-source` loads the generated compiler package and canonicalizes
the entire bootstrap `.ps` workspace again into
`dist/selfhost/workspace`.

No Lean/Lake process is involved.

### 5. JavaScript compiler self-host

`selfhost:compiler` compiles the second-generation package entry with
`dist/bootstrap/packages/compiler/index.js`, producing
`dist/selfhost/packages/compiler/index.js`.

### 6. Fixed points

`verify:source` requires the bootstrap and self-hosted canonical `.ps`
workspaces to be byte-for-byte identical.

`verify:compiler` requires bootstrap and self-hosted generated TypeScript to
be byte-for-byte identical.

Later assurance can add checked-core and IR fingerprints without changing the
package/build structure.

## Source transition

During bootstrap development, handwritten `.lean` remains authoritative and
canonical `.ps` is generated.

After the fixed point is stable, the source authority can switch naturally:

```text
packages/*/src/**/*.ps
        |
        +--> psc build -> package dist/*.js
        |
        +--> psc translate --to lean
                -> Lean verification/reference artifacts
```

At that point Lake becomes a reference/bootstrap/verification build rather than
the normal development build.

## Current blocker

The workspace/package architecture is in place. The remaining blocker is source
closure of the existing compiler implementation, currently advancing through
`Ps.Syntax.ParseLean`. The rule remains: fix the first real unsupported source
construct without weakening semantic or regression gates.


## Dual Lake + npm project model

The self-host tree is intentionally both a Lake project and an npm/ProofScript
project.

The same handwritten portable compiler sources can be exercised through two
independent build hosts:

```text
packages/*/src/**/*.lean
        |
        +---- lake build
        |       |
        |       +--> Lean-native bootstrap compiler / reference build
        |
        +---- generated compiler.js + psc
                |
                +--> canonical .ps project
                +--> emitted .lean project
                +--> generated .ts
                +--> tsc -> executable .js
```

The build systems have different jobs:

- **Lake** is the bootstrap/reference build. It validates the current Lean
  source project and produces the initial `psc1` executable.
- **npm** is the normal orchestration/build system. On the first
  `npm run build`, it bootstraps with Lake only if the generated JavaScript
  compiler is missing. Subsequent builds use the generated compiler.
- **psc** is the language build frontend. It accepts either supported
  `.lean` or `.ps` source and can emit canonical `.ps`, Lean source,
  TypeScript and executable JavaScript.

Explicit build modes:

```bash
# Lean/Lake path only
npm run build:lake

# Generated ProofScript/JS compiler path only
npm run build:psc

# Exercise both paths deliberately
npm run build:dual

# Seamless default:
# first run -> bootstrap once with Lake, then PSC build
# later runs -> PSC/JS build only
npm run build
```

The normal PSC build writes a dual-source snapshot:

```text
dist/current/
  ps/
    psconfig.json
    packages/**/*.ps
    stdlib/**/*.ps

  lean/
    lakefile.lean
    lean-toolchain
    packages/**/*.lean
    stdlib/**/*.lean

  packages/
    compiler/
      index.ts
      index.js
      index.d.ts
      index.js.map
```

Therefore the compiler source in `dist/current/ps` can be treated as a
ProofScript project, translated to the sibling Lean project, or compiled again
to TypeScript/JavaScript.

Whole-project translation is exposed directly:

```bash
psc project emit packages/compiler/src/Ps/Compiler.lean \
  --to ps \
  --out dist/manual/ps

psc project emit dist/manual/ps/packages/compiler/src/Ps/Compiler.ps \
  --to lean \
  --out dist/manual/lean
```

The emitted ProofScript project contains `psconfig.json`. The emitted Lean
project contains a generated `lakefile.lean` and a Lean 4.34 toolchain pin, so
its source lane can be opened and built as a Lake project independently of the
original handwritten directory structure.

### Repeatable generations

Self-hosting is no longer limited to one hard-coded next generation.

```bash
# bootstrap -> generation 1
psc selfhost \
  --compiler dist/bootstrap/packages/compiler/index.js \
  --workspace dist/bootstrap/workspace \
  --out dist/gen1

# generation 1 -> generation 2
psc selfhost \
  --compiler dist/gen1/packages/compiler/index.js \
  --workspace dist/gen1/workspace \
  --out dist/gen2

# generation 2 -> generation 3
psc selfhost \
  --compiler dist/gen2/packages/compiler/index.js \
  --workspace dist/gen2/workspace \
  --out dist/gen3
```

Each generation contains:

```text
dist/genN/
  workspace/                 # canonical ProofScript compiler project
  lean/                      # Lean-equivalent generated project
  packages/compiler/
    index.ts
    index.js
    index.d.ts
    index.js.map
  .proofscript-generation.json
```

This makes fixed-point testing naturally extensible beyond two generations.

## stdlib and host workspace direction

`stdlib` and `host` are already npm workspaces today.

Their roles are now explicit:

- `@proofscript/stdlib-next` is **portable** and is part of the compiler source
  closure.
- `@proofscript/bootstrap-host-lean` is **non-portable** and exists only to
  connect the portable compiler to Lean IO/filesystem/process APIs during
  bootstrap.

The final physical layout should converge to:

```text
packages/
  stdlib/
  compiler/
  ...
  bootstrap-host-lean/
  host-node/
  cli/
```

`host-node` should own the current generated-JS filesystem/project/`tsc`
adapters that still live under `scripts/`. The physical moves of
`stdlib/` and `host/` are intentionally deferred until first self-host
closure because changing import roots during the current parser-closure work
adds risk without changing semantics.
