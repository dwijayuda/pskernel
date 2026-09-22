# pskernel-cli

Private support-package scaffold for the pskernel repository.

This package is deliberately outside the trusted kernel. It exposes a small
streaming command-line wrapper around the root package's public
`lean4export` entry point.

## Development usage

Build the root package first:

```bash
npm run build
cd packages/cli
npm install
node bin/pskernel.mjs replay ../../oracle/fixtures/lean434-init-prelude.ndjson
```

The package stays private until the root kernel package name/version/public API
is frozen. It must not import implementation files from `src/kernel/**`
directly.
