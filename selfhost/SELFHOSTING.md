# PSC1 Self-Host Pipeline

The self-host target is:

```text
portable compiler sources (.lean)
    |
    | one-time Lean 4.34/Lake bootstrap
    v
generated canonical ProofScript workspace (.ps)
    |
    | Lean-hosted PSC1 bootstrap compiler
    v
bootstrap compiler.ts -> tsc -> compiler.js
    |
    | compiler.js + thin Node filesystem host
    v
same generated .ps workspace
    |
    v
next compiler.ts -> tsc -> next compiler.js
    |
    v
fixed-point comparison
```

Lean/Lake is a bootstrap tool, not a runtime dependency of the final compiler.
The Node host is intentionally outside the semantic compiler. It performs
filesystem/import traversal, writes generated TypeScript, and invokes `tsc`.
Parsing, elaboration, checking, erasure, and TypeScript emission in the second
compile are executed by the generated `compiler.js`.

## Source layout

Handwritten portable compiler sources stay in the existing package topology:

```text
selfhost/
  SELFHOST-COMPILER.lean
  packages/*/src/**/*.lean
  stdlib/**/*.lean
  host/                    # Lean bootstrap host only
  scripts/                 # host/orchestration only
```

Do not create a second handwritten compiler tree. During bootstrap, `.lean`
remains the handwritten source. Canonical `.ps` files are generated.

## Generated layout

All generated self-host artifacts live under the ignored `selfhost/dist/`
directory:

```text
selfhost/dist/
  bootstrap/
    workspace/
      SELFHOST-COMPILER.ps
      packages/*/src/**/*.ps
      stdlib/**/*.ps
      .proofscript-bootstrap.json
    compiler.ts
    compiler.js
    compiler.d.ts
    compiler.js.map

  next/
    compiler.ts
    compiler.js
    compiler.d.ts
    compiler.js.map
```

The generated workspace mirrors the source package layout so normal module names
continue to resolve without special self-host-only import rules.

## Commands

From `selfhost/`:

```bash
# One-time Lean/Lake bootstrap:
npm run bootstrap

# Use generated compiler.js to compile the same .ps workspace again:
npm run selfhost

# Verify deterministic fixed point:
npm run verify:selfhost

# Entire chain:
npm run fixed-point

# Stable front door (same operations):
npm run psc -- bootstrap
npm run psc -- selfhost
npm run psc -- verify-selfhost
npm run psc -- fixed-point

# Compile any generated ProofScript project with compiler.js:
npm run psc -- build dist/bootstrap/workspace/SELFHOST-COMPILER.ps --out dist/next/compiler.ts
```

The low-level CLI also supports explicit translation artifacts:

```bash
lake exe psc1 emit-ps input.lean --out output.ps
lake exe psc1 translate input.lean --to ps --out output.ps
lake exe psc1 build input.ps --out compiler.ts
```

`psc1 build` writes the requested TypeScript file and invokes `tsc`, producing
the adjacent `.js`, `.d.ts`, and `.js.map` files.

## Stage meanings

### Bootstrap source closure

`lake exe psc1 check SELFHOST-COMPILER.lean` must pass. This proves that the
whole portable compiler project is inside the PSC1 source subset.

### Canonical ProofScript workspace

`bootstrap:emit` walks the import graph from `SELFHOST-COMPILER.lean` and
translates every reachable portable source to a mirrored `.ps` workspace.
No generated `.ps` file should be edited manually.

### Bootstrap JavaScript compiler

`bootstrap:compiler` loads the generated `.ps` project and produces
`dist/bootstrap/compiler.js`. Lean/Lake is still present only because the
bootstrap executable itself is Lean-hosted.

### JavaScript self-host

`selfhost` dynamically loads `dist/bootstrap/compiler.js`. The Node host
flattens the generated module graph in dependency order, then calls exports from
the generated compiler:

- `psParseProofScriptSource`
- `psElabModule`
- `psBootstrapPreludeEnvironment`
- `psEraseCoreModule`
- `psTsEmitModule`

The resulting TypeScript is compiled by `tsc` to
`dist/next/compiler.js`. Lean/Lake is not used in this stage.

### Fixed point

`verify:selfhost` requires `dist/bootstrap/compiler.ts` and
`dist/next/compiler.ts` to be byte-for-byte identical and reports their SHA-256.
Later we can strengthen this with checked-core and IR fingerprints as separate
artifacts, but TypeScript fixed-point equality is the first executable closure
gate.

## Current blocker

The architecture and commands above are in place, but the full pipeline is not
yet expected to pass until `SELFHOST-COMPILER.lean` itself passes the early
PSC1 compiler-source readiness gate. Work should continue by fixing the first
real source-subset incompatibility reported by that gate, without weakening or
moving it later.
