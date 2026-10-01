# @proofscript/conformance

Status: **MVP / private**  
Trust: **test-only**

Reusable process-isolated conformance runner for pskernel.

The first adapter understands the Lean Kernel Arena directory convention:

```text
good/**/*.ndjson  -> expected accept
bad/**/*.ndjson   -> expected reject
**/perf/**        -> excluded by default
```

Each case runs in its own Node process with an enlarged JS stack and a timeout, so a pathological case cannot poison the rest of the suite.

## API

- `discoverArenaCases(root, options)`
- `runConformanceCase(case, options)`
- `runArenaSuite(root, options)`

## CLI

```bash
pskernel-conformance arena /path/to/arena-tests
pskernel-conformance arena /path/to/arena-tests --include-perf
```

## Trust

This package is never part of proof acceptance. It orchestrates tests against the kernel public replay API.
