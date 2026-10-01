# psconfig.json Reference

Source authority: current `packages/cli/src/config.ts` and
`packages/project/src/node.ts` on the repository baseline studied for this
branch.

## Default shape

```json
{
  "languageVersion": "0.7",
  "entry": "src/main.ps",
  "sourceRoots": [],
  "runtimeDependencies": {},
  "compilerOptions": {
    "outDir": "dist",
    "emitTypeScript": true,
    "declaration": true,
    "sourceMap": true
  }
}
```

## `languageVersion`

Type:

```text
"0.7"
```

The current CLI milestone accepts language version `0.7`.

PSC1's exact freeze scope is further constrained by the active self-host
language profile documented in this branch.

## `entry`

Type:

```text
string
```

Default:

```text
src/main.ps
```

May identify native ProofScript or a supported bounded Lean entry.

## `sourceRoots`

Type:

```text
string[]
```

Default:

```json
[]
```

Every configured root must be:

- a string;
- non-empty;
- relative, not absolute.

Duplicate entries are normalized away by the project config helper.

### Empty source roots

If empty/unset, module imports resolve below the entry source directory.

### Configured source roots

Each logical module is searched under every root for:

```text
<Module/Path>.ps
<Module/Path>.lean
```

Exactly one candidate must exist.

Multiple candidates are an ambiguity error.

Root ordering is not precedence.

## `runtimeDependencies`

Type:

```text
object mapping npm package root -> exact version string
```

Example:

```json
{
  "runtimeDependencies": {
    "host-lib": "1.2.3",
    "@scope/tool": "4.0.0-beta.1"
  }
}
```

Keys must be npm package **roots**.

The first policy rejects config keys that are:

- relative paths;
- absolute paths;
- `node:` builtins;
- package subpaths.

Source FFI declarations may use bounded safe package subpaths, but configuration
is keyed by the root.

Versions must use exact `x.y.z`-style versions with the currently accepted
prerelease/build suffix syntax.

Semver ranges are not accepted by the first policy.

## `compilerOptions.outDir`

Type: `string`

Default:

```text
dist
```

Output directory.

## `compilerOptions.emitTypeScript`

Type: `boolean`

Default: `true`

Controls retained/emitted TypeScript according to the current backend workflow.

## `compilerOptions.declaration`

Type: `boolean`

Default: `true`

Controls TypeScript declaration output.

## `compilerOptions.sourceMap`

Type: `boolean`

Default: `true`

Controls source-map output.

## Config lookup

Without explicit `-p/--project`, the CLI searches parent directories for the
nearest `psconfig.json`.

With `-p`:

- a JSON path selects that file;
- a directory selects `<directory>/psconfig.json`.

## Configuration and proof semantics

Project configuration controls compilation/project behavior.

Host package versions and output directory options do not become theorem
premises unless explicitly represented as assumptions in the checked language
model.

In particular, runtime dependency lock integrity is separate from pskernel
project integrity.
