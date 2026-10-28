# Using pskernel-min, then completing full compiler support

## Qualified usable checker

U1 is complete at source `eea9306384ab68c220bece18e769fd16d7903f3a`: a standalone Node CLI and byte API
for the proved bounded R4B canonical Core fragment. It needs no Lean installation,
compiler service or runtime provider fallback. The private, unpublished local
tarball is 42237 bytes; version 0.1.0-r4b.1; SHA-256:

`42d7d524d903885f0f7d06b83fa21b9755759ff457d6d24b3df503196ed51929`

The [focused Linux workflow](https://github.com/dwijayuda/pskernel/actions/runs/40667728807),
[main Linux workflow](https://github.com/dwijayuda/pskernel/actions/runs/40667735933)
and [installed CLI workflow](https://github.com/dwijayuda/pskernel/actions/runs/40667728660)
are terminal-success at that source. Main CI succeeded on attempt 2 after the
source-trace installer timed out on attempt 1; no test body or time budget was
weakened. Exact evidence is in the [dated usability receipt](PSC1_MIN_KERNEL_USABILITY_QUALIFICATION_2026-10-28.json).

Download the pskernel-min-usable artifact from the focused run. It contains the
tarball, qualification.json, source report, canonical source packet and build
manifest receipt. Match the archive/tarball hashes before installation.
No npm registry publication or new license grant is part of this delivery.
GitHub artifact access follows authentication and retention; keep downloaded
tarballs with their exact matching qualification record.

## Install and check a packet

Node 22.23.3 on GitHub Actions Ubuntu 24.04 is the tested runtime. From the folder
containing the downloaded tarball:

```sh
npm install --offline --ignore-scripts ./proofscript-pskernel-min-0.1.0-r4b.1.tgz
npx --no-install pskernel-min info
npx --no-install pskernel-min examples
npx --no-install pskernel-min check node_modules/@proofscript/pskernel-min/examples/nat-definition.json
```

The examples command prints installed paths. The included regular-tree-fold
example accepts; negative-self refuses. Check emits one JSON summary:
exit 0 = accepted within R4B, exit 1 = refused including resource limits,
exit 2 = usage/IO failure. Refusal can mean unsupported or invalid input; it does
not assert that the official Lean checker would reject the packet.

Use exact canonical proofscript-checked-admissions v2 bytes. The current wire
profile is ASCII without backslash escapes or extra/duplicate fields and requires
complete input consumption. Pretty printing or a trailing line terminator can
make otherwise related JSON refuse. This tool checks bytes, not a reserialized
host object.

For a producer's one-LF NDJSON transport, explicitly add --transport-lf.
It removes at most one final LF. The JSON result separately records original and
checked byte lengths/hashes plus removedTerminalLF; acceptance refers to checked
bytes. Double line terminators still refuse. Linux stdin works with
`cat packet.json | npx --no-install pskernel-min check -`.

```js
import {readFile} from 'node:fs/promises';
import {checkBytes,metadata} from '@proofscript/pskernel-min';
const packet=new Uint8Array(await readFile('packet.json'));
const result=checkBytes(packet);
console.log(result.accepted,result.code,metadata.profile);
```

The API accepts genuine Uint8Array input; convert Node Buffer explicitly as above.
Proxies, subclasses and shared buffers refuse. It returns JSON-safe summaries,
not a transferable proof object. CLI checking is isolated in a worker with
256 MiB old-generation heap and 120-second deadline; these do not bound total RSS
or guarantee run time. The synchronous API has structural budgets but no wall
deadline.

## What was qualified

The exact tarball passed offline local/global installation in paths with spaces,
installed file/hash identity, a strict TypeScript consumer, all 52 corpus cases
against the already checked native/official-positive source corpus, hostile inputs
and forged acceptance/provider fields, file/stdin/LF/IO/exit-code behavior, FIFO
refusal without blocking, and runtime execution with no external tools on PATH.

Both installed API and CLI accepted the complete connected checker packet:
ten modules, 103181 source bytes, 307 origin members, 206 records and 1804358
packet bytes, hash 041d55f110471b91b69d134a38daeb94ee555a71e797b48a0c00cc6aa66ee516.
The shipped generated kernel is 502739 bytes of JavaScript; no test-vector module
ships. The packed archive is immutable during qualification.

The R4B source consistency theorem, compiler-stage/byte proofs and finite
JavaScript execution observations retain separate scopes. Generated-code/engine
preservation is not proved. Package metadata explicitly keeps
fullCompilerSupported=false and productionDefault=false. The production official
Lean Wasm default and min/dual canonical refusal remain unchanged.

## Continue to full compiler support

The user chose usable checker, then full compiler support. U1 is complete; the
overall workstream is not complete. Read the [completion contract](PSC1_MIN_KERNEL_USABILITY_PLAN.md)
and [R6 guideline](PSC1_MIN_KERNEL_R6_GUIDELINE.md).

C1 requires proved/scalable exact admission of the entire current compiler and
foundation. Its 29.9 MB packet cannot use this 2 MiB/512-declaration profile.
Raising limits alone does not solve representation, grammar, universe/dependent
type, primitive-model or partial-body obligations. Current coverage stays 0/124.

C2 requires actual compiler preservation, including recursive erasure, type/proof
telescope omission and freshness, closures/carriers and generator scheduling.
The next [R7 caller experiment](https://github.com/dwijayuda/pskernel/blob/aab8b66e6bfebfb43a481275ba15a6de5a08085e/psc1/docs/PSC1_MIN_KERNEL_R7_PROFILE_PLAN.md) is isolated
on `research/psc1-min-compiler-caller-20261028`; it is not adopted into the U1
package checkpoint. Its literal/zeta fragment and explicit eligibility do not
prove classifier/type soundness or independent substitution correctness.

C3 requires actual min-checked compiler generations and usable compiler flows,
with no fallback and exact final-source CI evidence. Full compiler support is
complete only when C1, C2 and C3 all pass. No installation, finite corpus count or
base-case theorem changes that completion definition.

Continue all project execution on GitHub Actions Linux with the user's GPT-6.1
Sol / High setting, preserved proof/resource guards, and nonforce expected-HEAD
updates. Keep the protected base 94e0c13f6a4b434f73c859cc0c716cb6fb8d1340 unchanged.
