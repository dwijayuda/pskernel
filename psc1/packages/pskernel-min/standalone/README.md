# pskernel-min: standalone R4B checker

This package checks the proved bounded R4B fragment of canonical
proofscript-checked-admissions version 2. It has no npm dependencies and needs
no Lean installation, compiler service or provider fallback at runtime.
Node.js 22.23.3 on GitHub Actions Ubuntu 24.04 is the qualified runtime.

## Install and use

Download the exact tarball and qualification.json from the usability artifact
of the matching GitHub Actions run. Compare its SHA-256 with qualification.json,
then install the local tarball:

```sh
npm install --offline --ignore-scripts ./proofscript-pskernel-min-0.1.0-r4b.1.tgz
npx --no-install pskernel-min info
npx --no-install pskernel-min examples
npx --no-install pskernel-min check node_modules/@proofscript/pskernel-min/examples/nat-definition.json
cat node_modules/@proofscript/pskernel-min/examples/regular-tree-fold.json | npx --no-install pskernel-min check -
```

Check prints one JSON result. Exit 0 means accepted in this profile, 1 means
refused (including budgets), and 2 means command or IO failure. No refusal invokes
another checker. Acceptance refers to the exact checked bytes and declarations.

The input is canonical ASCII JSON at EOF: no whitespace outside the producer's
exact grammar, backslash escapes, trailing newline, duplicate/unknown fields or
unconsumed suffix. Source API NDJSON can use the explicit --transport-lf option
to remove exactly one final LF. Output retains separate input/checked hashes and
lengths and records removedTerminalLF; it never calls the original bytes accepted
when only their canonical derivative was checked.

```js
import {readFile} from 'node:fs/promises';
import {checkBytes,metadata} from '@proofscript/pskernel-min';
const result=checkBytes(new Uint8Array(await readFile('packet.json')));
console.log(result.accepted,result.code,metadata.profile);
```

The synchronous API accepts an exact genuine Uint8Array. Buffer, subclasses,
proxies and shared backing stores refuse. It returns only JSON-safe summary
fields, never an input-supplied acceptance flag or a transferable proof object.
Use the CLI for an isolated worker with a 256 MiB old-generation heap ceiling
and a 120-second deadline. These are not total RSS or speed guarantees. The
synchronous API keeps the R4B structural/input budgets but has no wall deadline.

## Supported scope

The existing R4B grammar supports closed safe definitions over Nat, Bool, Unit,
selected List/Option primitives, simply typed functions, ordered fresh names,
and its bounded regular unparameterized one-family data/record fragment with
nondependent recursors and projections. Types/terms outside the proved grammar
refuse. See the R4B and R6 guidelines and source proofs in the repository for the
exact grammar. Examples include a Nat definition, regular tree fold and refusal
of negative recursion.

The runtime is compiled from the ten actual checker modules; no test-vector
module ships. manifest.json records exact source/runtime identities. External
qualification.json records tests of this exact packed tarball, including offline
local/global installation, native corpus parity, independent official-positive
comparisons and complete connected-runtime admission.

## Trust and full compiler boundary

The R4B source consistency theorem, compiler-stage/byte proofs and finite
JavaScript observations have separate scopes. The whole generated compiler and
JavaScript engine are not formally verified. This package is usable within that
declared source fragment and implementation boundary; it is not a complete Lean
checker or the PSC1 production/default checker.

Current compiler minimal coverage remains 0/124; the full compiler's foundation,
dependent types, strings, projections, partial bodies and preservation obligations
are not discharged by installation. Production min/dual still refuse
PSC1_MIN_CANONICAL_BRIDGE_UNPROVED. Official Lean Wasm remains default.
This tarball is not published to npm by this workflow.
