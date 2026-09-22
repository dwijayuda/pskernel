# pskernel-cli

Status: **prototype / private**  
Trust: **untrusted support layer**

CLI wrapper around the pskernel public APIs and `@proofscript/module`.

## Development setup

Build the root kernel first, then install the private support packages:

```bash
npm run build
cd packages/cli
npm install
```

## Commands

Replay/check a Lean4export stream:

```bash
node bin/pskernel.mjs replay ../../oracle/fixtures/lean434-init-prelude.ndjson
node bin/pskernel.mjs check ../../oracle/fixtures/lean434-init-prelude.ndjson
```

Pack it into a deterministic checked-module artifact:

```bash
node bin/pskernel.mjs module pack Lean.Init.Prelude \
  ../../oracle/fixtures/lean434-init-prelude.ndjson \
  init-prelude.psmodule
```

Inspect or verify integrity without kernel replay:

```bash
node bin/pskernel.mjs module inspect init-prelude.psmodule
node bin/pskernel.mjs module verify init-prelude.psmodule
```

Replay the artifact through pskernel:

```bash
node bin/pskernel.mjs module check init-prelude.psmodule
```

Artifacts with declared dependencies currently require dependency-integrity context through the library API; CLI dependency resolution is a later milestone.

The CLI must not import implementation files from `src/kernel/**` directly.
