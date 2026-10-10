# psdev

This private, unpublished npm example carries a prepared 44-byte WebAssembly command module. It demonstrates the same protected extension contract used for independently named packages. Neither the unscoped name nor the illustrated scope is claimed to be available or owned on npm.

Install the matching preview.3 candidate archive from its actual downloaded path:

```sh
npm install --save-dev --save-exact --ignore-scripts "/absolute/path/psdev-0.1.0-preview.3.tgz"
```

On Windows, use your actual drive path. Use the matching proofscript preview.3 compiler. Enable the package explicitly in the root project's existing `package.json`:

```json
{
  "proofscript": {
    "profile": "checked",
    "extensions": [
      { "package": "psdev", "enable": ["command:dev"] }
    ]
  }
}
```

Preserve the project's other configuration and commit its npm lockfile. Run `psc dev src/Main.ps --once --out src/Main.ts` (or `psc.cmd` in PowerShell). When `psc init` supplied the entry and output defaults, `psc dev --once` uses those defaults.

Installation alone does not activate the module. Ordinary `check` and `build` do not load it. The guest receives the integer event 0 and returns 1 to request the supervisor's already selected checked build. It receives no source paths, filesystem, network, process, terminal, kernel or publication access. Every actual attempt and result is disclosed by the host; the completed record is retained in the checked artifact receipt.

Only one `command:dev` package may be enabled. This is a one-shot command demonstration. In a checked-library project, preserve its `proofscript.entry`, `out` and `exports` settings and use `psc dev --once`; the protected host performs the same bundle-and-facade transaction as `psc build`. Live watch, LSP and additional command families remain separate milestones. The demo does not bypass failed checks or establish compiler semantic preservation.

The maintained `command.wat` states the guest algorithm. The prepared `command.wasm` has SHA256 `63b9c0f41bfc46a06b148a92b370c73f950d1b89b544b290cc7e83e15998e279`. The host hashes and validates those exact captured bytes before a trusted worker executes them with no imports. No installation or lifecycle script is needed.

Protocol and implementation boundaries are documented in `psc0/docs/platform/command-extension-sdk.md` in the repository. No external package callback is imported into the authority process. The examples intentionally use the same tiny module under independent package identities to demonstrate that no publisher allowlist or package-name special case grants execution.
