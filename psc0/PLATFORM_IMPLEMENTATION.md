# PSC0 platform implementation

## PSC0 PSCV P0 modular ownership and verification preflight — qualified

**Date:** 10 October 2026 (UTC). **Exact qualified source and metadata HEAD:**
`c6e65c7b2333cb1ff634bdcf2f867a1c62510832`. **Cloud evidence:**
[PSC0 PSCV P0 run 38036616386](https://github.com/dwijayuda/pskernel/actions/runs/38036616386)
(attempt 1, all four jobs successful), plus
[pscv-p0-qualification-2026-10-10.json](docs/platform/pscv-p0-qualification-2026-10-10.json).
**Branch:** `psc0/platform-pscv-foundation-v1`, stacked on the T3 platform
branch `psc0/platform-t3-lsp-v1`. Draft [PR #95](https://github.com/dwijayuda/pskernel/pull/95).
No main merge, npm registry publication or changes to compiler/kernel logic.

## Decision and implemented P0 scope

- **Keep all existing source folders.** `core/`, `syntax/`, `environment/`, `meta/`,
  `elab/`, `compiler-ir/`, `erasure/`, `backend-ts/`, `pskernel-core/` etc remain
  canonical maintained paths. `pscore`, `psfrontend`, `psc`, `psbackend-ts`
  remain *logical* ownership/distribution design names. No bulk rename,
  bootstrap closure churn or forced npm package consolidation.
- [Complete feature-owner and authority map](docs/platform/PSCV_PROFILE_AND_PACKAGE_BOUNDARIES.md):
  general type theory and language forms stay in base compiler/kernel,
  proof goals/tactics belong to reusable prover/tactic components when needed,
  VC/WP and termination/effect semantics to reusable verification services,
  approved specification tooling separately, `@proofscript/pscv` as the optional
  **official closed profile composition**, and final certificate/evidence/
  executable authorization solely in the release supervisor.
- **New `psc0/packages/verification/`:** private `@proofscript/verification-internal`
  non-authoritative `psc-required-obligations/0`, proof-proposal and preflight
  contracts. Rejects duplicate/mismatched/unknown goals, fake authority fields
  and malformed/empty obligations. Even all supplied proof candidate SHA hashes
  matching a caller-provided obligation set yield **uncertified** because list
  completeness, kernel replay, approved specifications, imported/effect trust
  closure and compiler preservation have not been validated.
- **New `psc0/packages/pscv/`:** `@proofscript/pscv@0.0.0-experimental.1`
  private, data-only candidate; npm `pack --dry-run` verified only
  `README.md`, `package.json`, `profile.json` are included. `private:true`,
  no JavaScript executable/entry/install scripts. `profile.json` binds the
  existing PSCV RC-v2/reference hash and Lean4.35.0-rc3 source pin; freezes
  **no** fictitious Standard registry digest; lists no verified features and
  `allowedToEmitVerifiedExecutable:false`. Installation cannot activate
  language syntax or claim PSCV.
- **New supervisor-owned `scripts/pscv-certification-gate.mjs`:** policy
  state `unqualified`; `authorizePSCVExecutable()` **always rejects**.
  Current production `scripts/checked-build.mjs` separately still refuses
  `profile !== 'checked'`. No issued `PSCV-CERT-v1`, private
  `VerifiedExecutableModule`, proof handoff or verified executable artifacts.

## Qualified executed evidence

Cloud workflow [`psc0-pscv-foundation.yml`](../.github/workflows/psc0-pscv-foundation.yml)
(at runtime commit c6e65c7) passed all 4 jobs:
1. Linux/Node22.23.3: 10 proposal/gate unit tests passed, no failures;
   inspected private npm tarball inclusion and unchanged compiler/kernel pins.
2. Linux/Node26.7.0: same 10 passed; all invariant/packaging checks succeeded.
3. Windows/Node26.7.0: same 10 passed; all invariant/packaging checks succeeded.
4. Pinned Lean4.35.0-rc3 `PSCVL/`: `check-preview`
   `examples/pass_contract.ps` admitted real intrinsic/WP contract preflight
   (still UNCERTIFIED); `fail_unproved_contract.ps` rejected with
   **unproved verification conditions** and **disallowed axiom sorryAx**;
   strict bounded `check examples/normative/pass_minimal.ps` succeeded
   while reporting UNCERTIFIED. No generated PSCV executable/certificate.

**This is P0 only.** Prototype `check-preview` includes some source syntax
not conforming to the PSCV closed Standard grammar. Three passing examples
and 30 JavaScript tests do not establish complete VCG correctness,
specification coverage, PSCV v1 conformance, executable semantics or
logical consistency. Refuse publication rather than infer any of these.

Existing T3 (preview5) qualified compiler fixed point **62 modules**,
source closure `3932952ddb743692ceab3fe2d48e5c3d5f61aa04d2da47e562f5fa4e3aa689ea`,
selected JS `6ab7d603cb612aaaa710a9dd0367ff8fdc4edadb893b3f6f217873444c167617`,
selected native Core source `963030dc2d154008fccc82e7c8ed29331f138799`,
TS7.0.2 and authoring seed remain exactly unchanged. PSCVL reference is
Lean4.35rc3 but the separately evolving Core work targets rc4; **never
silently switch** pin/kernel/environment.

## Next milestones

**P1:** explicit rc3 versus rc4 semantic/version decision, generate/freeze
ordered Standard environment and verification registry manifests, qualify
source/profile/goal interfaces and official package activation without
letting arbitrary npm modules execute as compiler code.

**P2:** one actually **certified** pure contract, with approved formal spec,
independently justified complete VC set, kernel admitted proof, exact
axiom/effect/import/erasure closures, protected token and verified artifact
handoff. Both wrong and omitted proofs MUST block output. Do not implement
P2 by changing the Boolean in `profile.json` or by adding an unvalidated
`accept` branch to the current preflight.

**P3+** full PSCV-RC-v2 normative Appendix A grammar, complete Standard
tactics, pure/mutable control flow, effects, invariants/ghost/termination,
certified imports, general proof-service integrations, backend preservation
and conformance/proof replay. Create new folders only for concrete reusable
algorithms, not empty package placeholders.

**Workflow:** GitHub remains source of truth; use GitHub connector/MCP only
for repository mutations and Actions cloud tests. Always re-fetch HEAD,
lease writes, preserve remote history and concurrent kernel metatheory lanes.
Do not use Desktop Commander or local source checkouts/build/tests. Keep
this AI_WORK_STATE current on each checkpoint.

---



## T3 qualified editor queries and optional pslsp

**Checkpoint:** 10 October 2026, 06:39:22 UTC. Runtime/source commit `fe62c189aac09cdfe1c156864a329b4db5a0a9e5` passed [all six jobs in run 38031535192](https://github.com/dwijayuda/pskernel/actions/runs/38031535192), attempt 1. T3 branch `psc0/platform-t3-lsp-v1`, stacked on completed T2 in [draft PR #94](https://github.com/dwijayuda/pskernel/pull/94). T3 changes maintained host/editor JavaScript only; 62 portable compiler modules, selected R seed, TypeScript 7.0.2, and pinned native Core source `963030dc2d154008fccc82e7c8ed29331f138799` remain unchanged. No npm publication or main merge.

**Delivered:** `psc query entry.ps --stdin --json` accepts a bounded in-memory unsaved `.ps` buffer and checks declaration admission with the qualified generated compiler and PSKernel Core over its saved-import closure. It returns `psc-source-query/1` structured accepted/rejected/unavailable status and diagnostics; parser spans become UTF-16 when provided, and other failures are explicitly source-unlocated. It neither performs erasure nor target, ABI, PSCV or compiler semantic-preservation checking, and never writes output or a publication receipt. An optional separately installed `pslsp@0.1.0-preview.5` provides LSP 3.17 stdio initialize/shutdown/exit, full-document open/change/save/close and versioned diagnostics through cancellable child queries. Hover, definition, completion, project semantic indexing and VS Code integration are NOT yet implemented.

**Watch follow-up:** An inherited T2 Linux `fs.watch` race observed transient `.psc-output-lock` retirement. The fixed T3 host uses bounded 110ms content polling on both Linux and Windows, excluding compiler-owned temporary directories; source and publisher checks remain unchanged. Polling is only an advisory scheduling signal, not a guarantee of instantaneous filesystem observation or atomic multi-file visibility to other watchers.

**Executed cloud qualification:** [run 38031535192](https://github.com/dwijayuda/pskernel/actions/runs/38031535192): Linux source 143 host +18 native/integration passed; Windows source 147 host +15 native/integration passed with four inherited POSIX-only fixture skips; no failures. Four clean-install jobs: Linux Node22/26 each 48 existing +5 watch +5 LSP observations; Windows Node22/26 each 46 existing +5 watch +5 LSP. Totals **323 source/integration passes** and **228 installed observations**. The Windows Node26 job used Node 26.7.0 and npm 12.0.2. Installed tests include real in-memory valid kernel admission, syntax failure diagnostics, unsaved correction, versioning, document-close diagnostic clearing, zero TS output from query, and watch checked generations.

**Candidate archive:** [artifact 11661484886](https://github.com/dwijayuda/pskernel/actions/runs/38031535192/artifacts/11661484886), ZIP 3,908,781 bytes, SHA256 `b5849bf805567f012768d9b0967e00019bcf21fa891beeaa1e0aac108b054e1d`, expires 2026-11-09 06:37:44 UTC. Contents: `proofscript-0.1.0-preview.5.tgz` (3,665,055 bytes, SHA256 `3c59c56eaa3f23bda83708b796af520db5c7042692c27bd555d9d7c427fbb440`); `psdev-0.1.0-preview.5.tgz` (1,996 bytes, SHA256 `4d0e619661de46dc8c6e53d534a8757b4185bf482f16d961d773c7a1f96262cc`); `psc-demo-pshello-0.1.0-preview.5.tgz` (1,934 bytes, SHA256 `815ad4e1624373a90fe506581cb2c51ffeafeaaf161bd01c8104635cff0736a3`); and the optional `pslsp-0.1.0-preview.5.tgz` (its exact tarball SHA is retained in installed job LSP evidence rather than invented here). Evidence: [machine-readable T3 record](docs/platform/t3-editor-query-qualification-2026-10-10.json). Downloadable Actions artifacts expire; committed hashes are not durable executable storage.

**Usage:** Extract the candidate, install exact `proofscript` and `pslsp` tarballs locally with `npm install --save-dev --save-exact --ignore-scripts`, and launch `node ./node_modules/pslsp/bin/pslsp.mjs --stdio` from the intended project root through an LSP client. The command speaks framed JSON-RPC, not an interactive terminal. [Editor query/LSP contract](docs/platform/editor-query-and-lsp.md) describes bounds, LSP messages, source-span accuracy, privilege isolation and limitations.

**Next work:** Qualified compiler semantic query endpoints/index for hover and declaration navigation, followed by a thin VS Code client; concurrently improve packaging/licensing and durable artifact retention. Full PSCV contracts and formal proofs in `psc0/proofs/**/*.proof.lean`, generic npm source/backend/tactic extension APIs, and qualified same-source Core-JS/Core-Wasm execution remain separate future milestones. Keep native admission default until explicitly qualified replacement. Preserve branch stack PR90 → PR91 → PR92 → PR94 and all remote history. GitHub connector/MCP only for repository edits; Actions/cloud CI only for source builds/tests; no Desktop Commander/local checkouts/tests. Re-fetch HEAD before updates and use leased non-force refs.

---


## PSC0 T2 checked watch — preview4 qualified

**Updated:** 10 October 2026, 05:14:26 UTC. T2 source commit **130e9501ccb39b11fe20bfe762718c9df896ebdd** passed all six jobs in [run 38026670864](https://github.com/dwijayuda/pskernel/actions/runs/38026670864), attempt 1: Linux source, Windows source, and four clean installed-package runs (Linux/Windows, Node 22.23.3 and 26.7.0). Integration branch **psc0/platform-t2-watch-v1**, stacked on qualified T1 in [draft PR92](https://github.com/dwijayuda/pskernel/pull/92). Main, selected seed R, 62-module compiler closure, native PSKernel algorithms and the TS7.0.2 pin are unchanged; no npm registry publication or merge.

### Packages and exact evidence

The [qualified preview4 candidate](https://github.com/dwijayuda/pskernel/actions/runs/38026670864/artifacts/11659064861) (ZIP 3,896,027 bytes, SHA256 0c066d5ceb6b3b0e81124a41d782b63f52f4bd78a54626e45d1fb96f575dbff6) contains:

| Archive | Bytes | SHA256 |
| --- | ---: | --- |
| proofscript-0.1.0-preview.4.tgz | 3,661,914 | 652aa526f71f1111ee4292b73c3c888840c8ece921a6aeff5e20718c71800ab2 |
| psdev-0.1.0-preview.4.tgz | 1,996 | d569a61af0f9161aa04bcc79650e903f38191c9fc69fe8d12d17f259cbf64d27 |
| psc-demo-pshello-0.1.0-preview.4.tgz | 1,934 | 66b773f77d2a2deaa968ff08617a90d7fe991fceb856d3f3c08190bef5d57b50 |

Artifact expires **9 November 2026 05:12:54 UTC**. JSON evidence is not durable executable storage. Source tests: Linux 136 host +18 native/integration passed; Windows 140 host +15 native/integration passed, with four inherited POSIX/permission-only skips. Installed jobs: Linux22 48 regular +5 watch observations, Linux26 48+5, Windows22 46+5, Windows26 46+5. Exact jobs and checks: [t2-watch-qualification-2026-10-10.json](docs/platform/t2-watch-qualification-2026-10-10.json).

### User workflow and implemented boundaries

With a private installed psdev package explicitly enabled for command:dev in project package.json, users run:

~~~sh
node ./node_modules/proofscript/bin/psc.mjs dev --watch --tsc --json
~~~

This uses the **same checked dev --once host** for each generation via bounded abortable Node child processes, and starts pinned TypeScript 7 project checking **only after** PSC admission and checked bundle/facade publication. Watch emits pending, checking, checked, ready, rejected and stopped generation states. It neither grants extension guests filesystem/proof/publication authority nor executes extension JavaScript entrypoints.

The qualified checked-library smoke created an initial generation (TS consumer 42), detected an imported-module edit (43), rejected malformed source while preserving all last accepted bundle/facade/receipt bytes, recovered after correction, and rejected a modified command.wasm while preserving prior output.

Linux uses recursive fs.watch plus periodic accepted-input freshness checks. Windows uses bounded 110 ms **content polling** for source/configuration/selected-extension inputs, because pinned Windows Node 22/26 libuv fs_event can fatally abort on alias paths. Poll caps: at most 16 nesting levels, 512 directories, 2,048 files, 2 MiB per file and 64 MiB total per snapshot. Exceeding those caps halts watch; it never weakens kernel admission. This is an initial small-project scheduling profile, not an instantaneous filesystem freshness guarantee. Source bytes and receipt eligibility are rechecked by the unchanged checked publisher.

An invalid revision leaves prior owned generated output intact; no **ready** state is emitted for that revision. A failing downstream --tsc run reports rejected, even though the preceding PSC generation was already successfully published. The supervisor coordinates its own downstream TS build; independent watchers are not promised atomically visible multi-file writes. If the entry or active extension identity changes, restart watch. Bare psc init projects do not include tsconfig.json; use --tsc in a TypeScript project or the checked-library example.

### Try on Windows PowerShell

Download/extract the candidate and from its extracted root:

~~~powershell
$candidate = (Resolve-Path .\platform).Path
npm install --global --ignore-scripts "$candidate\proofscript-0.1.0-preview.4.tgz"
psc.cmd examples --json
~~~

Copy the installed checked-library example to a writable project directory. Inside that copied project:

~~~powershell
npm install --save-dev --save-exact --ignore-scripts "$candidate\proofscript-0.1.0-preview.4.tgz" "$candidate\psdev-0.1.0-preview.4.tgz"
npm pkg set 'proofscript.extensions[0].package=psdev' 'proofscript.extensions[0].enable[0]=command:dev'
node .\node_modules\proofscript\bin\psc.mjs dev --watch --tsc --json
~~~

Save Quantity.ps or Main.ps to trigger new checked generations; stop using Ctrl-C. The optional extension remains inactive until explicitly enabled.

### Assurance and remaining work

Compiler portable closure is still 62 modules SHA256 **3932952ddb743692ceab3fe2d48e5c3d5f61aa04d2da47e562f5fa4e3aa689ea**, generated compiler JS SHA256 **6ab7d603cb612aaaa710a9dd0367ff8fdc4edadb893b3f6f217873444c167617**, selected native Core source **963030dc2d154008fccc82e7c8ed29331f138799**. The existing T1 fixed-point qualification remains valid; host-only watch did not require recompilation or seed promotion. New proofs were not established: full semantic preservation, PSCV and strict SH1 remain explicitly unproved.

Still outstanding: durable executable archive retention and public npm licensing/release; larger npm library/workspace resolution and package consolidation; generic plugin extensions; LSP/VS Code; independently qualified PSKernel Core JS then Wasm runtime candidates; later formal proof companions outside the self-host cycle. Do not silently switch the selected native provider, weaken admission, merge main, or publish npm.

---


## Current result: preview3 checked-library qualification

T1 adds checked library adoption for existing TypeScript projects: explicit public exports from pure acyclic `.ps` modules, one shared checked bundle, thin neighboring TypeScript facades and a handwritten TypeScript consumer. The installed product keeps `psc init`, the earlier examples, and separately installed `psdev` and `@psc-demo/pshello` command demonstrations.

**Qualification status:** **Passed: all six jobs**. Source: [b01281b46aa62cbb09ed47a24ebad08b72c6265f](https://github.com/dwijayuda/pskernel/commit/b01281b46aa62cbb09ed47a24ebad08b72c6265f), tree `d54208569a708fef53fab913ad3b11ac5a496f00`. [Platform run 38019471955](https://github.com/dwijayuda/pskernel/actions/runs/38019471955). The changed compiler has separate exact-source qualification described below; the old F artifact is not reused as evidence for new compiler source.

The work is on `psc0/platform-t1-v1`, based on platform-v1 commit 4265f1d614d15fc9e6ed133a923779ba7af16db8. It is reviewable in [draft PR91](https://github.com/dwijayuda/pskernel/pull/91), stacked on [PR90](https://github.com/dwijayuda/pskernel/pull/90). Main, the selected R authoring seed, and the native Core selection are unchanged. Nothing was published to npm. This completes the bounded T1 milestone; it does not finish full watch, general language/backend extensions, final package decomposition, LSP or the formal-assurance program.

## Download and install

Download the [preview3 candidate artifact](https://github.com/dwijayuda/pskernel/actions/runs/38019471955/artifacts/11657608168). It contains three tarballs:

| Tarball | Bytes | SHA256 |
| --- | ---: | --- |
| `proofscript-0.1.0-preview.3.tgz` | 3,656,980 | `0273e5f18a3cea66b0f4deaa44fbfe1214510fd59d146956355985e555c4db7e` |
| `psdev-0.1.0-preview.3.tgz` | 1,914 | `20e6270726247f559129fa496aa0ae51cd0a8bf4ad679bfc99d91cb9b136e34e` |
| `psc-demo-pshello-0.1.0-preview.3.tgz` | 1,933 | `65adbd54131fc69e4e73df08501e5f59f82fbee29b8965bde5f27f2b577c4ded` |

The product archive excludes its separately installed TypeScript dependency. The candidate ZIP has 3,887,650 bytes and SHA256 `0a202234723940b86b9370303a3ab0d952003f41a6970b332c30117afb222f04`; its ZIP identity differs from the inner tarball identities. Artifact expiry is 2026-11-09 03:08:56 UTC. Retain exact executable inputs if they are needed beyond that date; committed JSON is evidence, not archive retention. Durable release-input storage remains public-release work.

From the extracted candidate directory in Windows PowerShell:

```powershell
$candidate = (Resolve-Path .\platform).Path
npm install --global --ignore-scripts "$candidate\proofscript-0.1.0-preview.3.tgz"
psc.cmd version --json
psc.cmd init my-app
Set-Location my-app
npm install --save-dev --save-exact --ignore-scripts "$candidate\proofscript-0.1.0-preview.3.tgz"
npm run check
npm run build
```

The global install supplies the initial command; the local install pins the compiler used by generated project scripts. For this unpublished preview, the generated local dependency must be satisfied from the actual tarball. A global install alone does not satisfy it. Future `npm install -g proofscript` registry distribution still requires an intentional publication.

Linux uses `psc` and an absolute tarball path. Windows tests use npm's `psc.cmd` in PowerShell; bare `psc` may select `psc.ps1` and depends on the user's execution policy. Installing the prebuilt package requires no Lean installation or source checkout.

## What T1 changes

| Component | Implemented behavior |
| --- | --- |
| Project preparation | The compiler retains authored declaration ownership across the ordered local import closure. Explicit source/name selections cannot claim another module's declarations or generated elaboration workers. |
| Public ABI | The `psc-ts-library/1` emitter checks original RuntimeIR, agrees on Core/IR signatures and authored arity, and produces a bounded public descriptor. Unsupported public signatures are refused. |
| Shared runtime | One project bundle owns the runtime. Neighboring facades only re-export selected bindings; datatype handles retain one identity across modules. |
| Runtime names | Project declarations, locals, constructors and fields use one structural source namespace in the existing erasure name map. This avoids backend-name capture and special `__proto__`/discriminator behavior. The legacy empty-prefix route remains separately scoped. |
| Protected host | One immutable preparation, the pinned native admission provider, the same original checked IR, exact descriptor coverage, captured configuration and TS7 target validation precede publication. |
| Publication | The existing publisher owns the whole bundle/facade generation across directories. It checks prior owned bytes, prevents handwritten overwrite, retires only owned old facades, rolls back still-owned partial writes and commits the receipt last. |
| User example | `checked-library` contains two `.ps` modules and a handwritten strict TypeScript consumer. The installed catalog now has four examples. |
| Optional tooling | The existing `psc dev --once` command guest can request the same configured library build. No separate kernel or publication path is added. |

The implementation adds one portable compiler module, `Ps.BackendTs.Project`, to the 62-module closure. The other compiler changes extend existing preparation and erasure metadata. Installed host and tooling code stays outside the self-host source closure. The product still has only one required npm dependency, TypeScript7.0.2. These are implementation boundaries, not a measured formal trusted-computing-base size.

## Try the checked-library example

Run `psc examples --json` (or `psc.cmd`) to locate the installed examples. Copy `checked-library` to a working directory outside the package, then run:

```sh
npm install --ignore-scripts --save-dev --save-exact /absolute/path/to/proofscript-0.1.0-preview.3.tgz typescript@7.0.2
npm run build
npm start
```

Start the example in a fresh copied directory. When converting an already-built single-source starter, `src/Main.ts` belongs to `src/Main.checked.json`; the new library receipt does not automatically adopt it. Stop build/watch processes, confirm which files are generated and still match that receipt, and archive those old generated outputs together with the receipt before the first library build. Preserve handwritten or edited files.

The expected output is `ProofScript library answer: 42`. The build script runs PSC first and only starts TypeScript if PSC succeeds. The example's package.json contains:

```json
{
  "proofscript": {
    "profile": "checked",
    "entry": "src/Main.ps",
    "out": "src/generated/library.ts",
    "exports": {
      "src/Quantity.ps": ["Quantity", "makeQuantity"],
      "src/Main.ps": ["readQuantity", "sameQuantity"]
    },
    "extensions": []
  }
}
```

`Quantity.ps` owns the datatype and constructor function. `Main.ps` imports it and owns the reader and identity functions. A successful build publishes `src/generated/library.ts`, `src/Quantity.ts` and `src/Main.ts`. The handwritten `src/consumer.ts` imports both neighboring modules and shares one opaque Quantity identity. `internalValue` remains private.

A standalone TypeScript cast does not manufacture an accepted opaque value. The example and generated conformance checks exercise forged objects, proxies, handles from another loaded bundle, negative Nat values and wrong call arity. A failed subsequent ProofScript revision preserves the previous completed output; downstream tools must honor the failed build status rather than treating last-good output as proof that the new source revision is accepted.

### Public boundary and qualified TS settings

| Source type | Public representation |
| --- | --- |
| Nat | Nonnegative JavaScript bigint |
| Int | JavaScript bigint |
| Bool | JavaScript boolean |
| String | JavaScript string without isolated UTF-16 surrogates; astral Unicode is supported |
| Unit | undefined |
| Supported monomorphic datatype/structure | Frozen opaque handle from that same bundle, tracked by private maps |

Implicit, dependent, erased-proof, generic, callback/function and array public signatures are outside this profile. Internal compiler-supported representations do not automatically become public FFI types. Public nullary definitions remain constants. Pure acyclic local imports, explicit project-root export configuration, strict TS7/NodeNext/ES2022 and one shared bundle are the pilot's supported scope.

`psc check` performs admission without claiming a checked public ABI; its library receipt says `abiStatus: "not-requested"`. `psc build` validates the descriptor, ABI and staged TypeScript before a completed library receipt says `"checked-bounded"`. Admission, ABI acceptance, RuntimeIR typing, TS acceptance and semantic preservation are distinct claims.

## Initializer, examples and command packages

`psc init` remains a small initializer: it creates package.json, src/Main.ps and PROOFSCRIPT.md in a new project, or adds the absent source/guide to an existing npm project while preserving that project's existing package metadata and build scripts. It installs nothing and executes no project code. Init uses exclusive file creation; it is not the checked publisher's multi-file transaction.

The four examples are `checked-nat`, `existing-typescript`, `rejected-source` and `checked-library`. The earlier TypeScript example demonstrates a constant from one source bundle; use checked-library for selected functions and shared datatype identities across modules.

Install the optional matching psdev tarball locally and add `{ "package": "psdev", "enable": ["command:dev"] }` to the root `proofscript.extensions` array. Preserve entry, out and exports. Then `psc dev --once` requests the configured checked build. The independently named `@psc-demo/pshello` demonstrates the same protocol. Installing a package alone does not activate it; check/build do not load a guest. The demo names/scopes are not claimed as owned registry names.

The `psc-command/1` guest is a restricted prepared WebAssembly module with no imports, filesystem, network, process, terminal, kernel or publication authority. It supplies a bounded request, while the host owns execution status, disclosure and any checked action. It cannot replace admission, inject a successful receipt or execute the package's JavaScript entrypoint in the authority process. Third-party identities use the same validation rather than a publisher-name allowlist. See [the command SDK](docs/platform/command-extension-sdk.md) for the precise restricted profile.

Full live watch and arbitrary extension APIs remain future work. An approved generated JS kernel would be a separate trusted provider artifact, not permission to load arbitrary npm JavaScript into the authority process.

## Exact compiler qualification

[SH1 run 38013991001, attempt2](https://github.com/dwijayuda/pskernel/actions/runs/38013991001) passed at source `5fe0045dcb0bf30e1d2519f900458d1407822eed`, tree `23dfb56a84cdce585e5c4b1a5ccff3b2de92f0e5`. Its compiler job 114101357176 and separate native replay job 114114935728 both succeeded.

The authoritative portable closure has **62 modules**, SHA256 `3932952ddb743692ceab3fe2d48e5c3d5f61aa04d2da47e562f5fa4e3aa689ea`. C1 was generated by the selected authoring seed from current raw source; C1 generated C2 from the same source, and C2 generated C3. The qualification compared the C2/C3 products. All four recorded products also match across C1/C2/C3:

| Product | SHA256 |
| --- | --- |
| Canonical surface source | `e91f3bfaaedf755b0fb027a3c6ffe752784c2f19cd41641ba8b015a90e37fe3e` |
| Normalized canonical admissions | `403d7b83ab62150a6f059cd5ed9dcfe18fd68e18f1c54cd8527abf173e20e1d5` |
| Generated TypeScript | `8923672fbc4b78a8bc1e25ab172162356ae4ffae6179eddc930c7955c73c1b3d` |
| Generated JavaScript | `6ab7d603cb612aaaa710a9dd0367ff8fdc4edadb893b3f6f217873444c167617` |

The existing original RuntimeIR checker and all 12 complete public Core-type/IR ABI checks passed. The 87-case migration correspondence uses the explicit `empty-legacy-erasure-namespace/1` comparison: only two named current `runtimePrefix` fields are projected, after their presence and empty value and both raw report hashes are checked. Raw reports are preserved, and seven regression groups protect against other differences. This is a narrowly described cross-revision comparison, not blanket normalization.

The exact C3 compiler passed all 11 recorded T1 conformance observations. Its example admissions hash is `6920fe26543ce11c9454d92154f1ee347c791bcd55bdbfdadbbcdacb296255fc`; its emitted TS bundle hash is `c3829e8032a2c48a633607c66499105f234feff88ffbe877723c516021cc2a40`. That conformance receipt explicitly says kernel admission was not attempted. The separate SH1 native job accepts four deduplicated exact streams covering C2/C3 compiler source, Lean and ProofScript capability source, and recursive-generic fixtures. It is additional acceptance after compiler-only generation (`emissionWasGatedByThisCheck: false`), rather than retroactive admission-before-emission. Real T1 library admission is exercised by the source and installed platform gates below.

The release workflow selects successful compiler artifact **11657766675 by ID** from run 38013991001. Its uploaded ZIP is 5,567,845 bytes, SHA256 `8d6309b0a526b6987922ebb34cb4d5892ad48ca9e31f3bbb7dfb30ae7319754d`. The failed first attempt has another artifact with the same name, so name alone is insufficient. The successful native replay log explicitly selected this new artifact; release assembly independently authenticates the compiler payload and source-closure hashes.

Retained exact receipts: [fixed point](docs/platform/compiler-t1-qualification-38013991001.json), [C3 T1 conformance](docs/platform/compiler-t1-conformance-38013991001.json), and [native acceptance](docs/platform/kernel-t1-admissions-38013991001.json). Native receipt file SHA256 is `4f40bdaa0088fa95c5512b1d7347fa3e651c858dd9562f77cf384cfb0cb4eeec`, 3,530 bytes. Attempt 1 hit the existing native full-IR 180-second process limit; the unchanged-head rerun passed without raising budgets. The authenticated R reproduction receipt remains `cold:false`, not a new isolated cold-recovery qualification.

The preserved authoring seed is R `fe2560aba0f347b1caf8d000d371464642d44f23`. Bootstrap stays Node22.23.3, Lean4.34.0 and TypeScript7.0.2. Consumer Node26 installation checks do not establish a Node26 bootstrap fixed point. The original F compiler at fcd875c8f38db4b0524090bd10c7c2fd5024053d remains historical evidence for its exact 61-module closure.

C2/C3 equality concerns the exact compared artifacts. It is not a compiler semantic-preservation theorem, a logical-consistency theorem or proof that the compiler was jointly bootstrapped with a generated kernel. The protected native provider's full admission replay is a separate gate.

## Exact platform qualification

| Source job | Host/policy tests | Real native/integration tests |
| --- | --- | --- |
| Linux / Node22.23.3 | 130 passed, 0 skipped (130 discovered) | 18 passed, 0 skipped (18 discovered) |
| Windows / Node26.7.0 | 134 passed, 1 skipped (135 discovered) | 15 passed, 3 skipped (18 discovered) |

| Clean installed job | npm | Recorded observations | Result |
| --- | --- | ---: | --- |
| Linux / Node22.23.3 | 10.9.9 | 48 | Passed |
| Linux / Node26.7.0 | 12.0.2 | 48 | Passed |
| Windows / Node22.23.3 | 10.9.9 | 46 | Passed |
| Windows / Node26.7.0 | 12.0.2 | 46 | Passed |

The four installed jobs consume the same three tarballs without repository checkout or Lean. They test initialization, examples, actual native admission, checked builds, source refusal and last-good preservation, optional package installation/activation and compulsory disclosure. The new library observations exercise admission-only checks, one-bundle publication, the handwritten consumer, an imported-module change from 42 to 43, failed-source preservation and a handwritten facade collision. Linux also inspects ELF requirements; Windows checks the previously qualified native system DLL imports and the actual npm command shim.

The source suites include cross-directory publication, real partial-write rollback, retired facades, overlapping leases, parent links, Windows path spelling, staging/backup namespace collisions and exact descriptor coverage. Windows skips one Unix-permission cleanup fixture and three POSIX shebang transport fixtures; all new T1 cases and the actual packaged Windows native admission ran. These are execution observations on the stated environments, not a theorem for every filesystem, OS version or shell policy.

The [complete preview3 qualification record](docs/platform/t1-checked-library-preview-qualification-2026-10-10.json) retains source/tree/run identities, job counts, tarball and artifact hashes, preserved compiler/kernel inputs and the remaining assurance limits. Full installed records: [Linux Node22.23.3](docs/platform/installed-linux-node22.23.3-38019471955.json), [Linux Node26.7.0](docs/platform/installed-linux-node26.7.0-38019471955.json), [Windows Node22.23.3](docs/platform/installed-win32-node22.23.3-38019471955.json), [Windows Node26.7.0](docs/platform/installed-win32-node26.7.0-38019471955.json).

Two earlier runs exposed test-harness omissions: a missing module in the synthetic CLI fixture and a CRLF-sensitive source-shape assertion. Both corrections preserve runtime behavior and validation expectations. The final six-job run repeats every platform gate; its product tarball is identical to the preceding run's tarball that passed all four installed jobs.

## Kernel selection and the JavaScript-before-Wasm route

Native Core source stays `963030dc2d154008fccc82e7c8ed29331f138799`, repository tree 80927150cbd6a5518762b4cc56e51ea24df8f374 and psc0 subtree 38c8c55bd2b214753e56c58c15c4901c32c01b86. The selected binary SHA256 values stay:

- Linux x64: `88f2d20ea733742d48724ecbdc903271e18bcfcccc8682be596a676aef68e3ec`.
- Windows x64: `8264a5e8551a1040d81956fa5b2a7f429355b365df06b9b705e20df8640419e2`.

The current Windows recipe contains an ordinary PE link timestamp and does not promise byte-identical later rebuilds. Preserve the authenticated executable. The separate Lean4.35 Arena work is not substituted. No native evaluator or rejection fallback is enabled.

**The same Core can in principle be emitted through PSC → TS7 → JS.** Historical bounded work demonstrated that route for an older snapshot. The new [J0 probe](https://github.com/dwijayuda/pskernel/actions/runs/38007233891) used the previously qualified F compiler with unchanged currently selected Core sources and passed a seven-case native public-admission baseline, then stopped during preparation at `psKernelCheckerStateExitLocalScope` in Checker/State.lean: `Nat.max` is missing from the compiler's standard environment. No current JS kernel executable was produced, and no JS provider passed admission parity.

[KERNEL_JS_PLAN.md](KERNEL_JS_PLAN.md) records a concrete **proposed, unexecuted** next diagnostic: admit an explicit ordinary PSC Lean-syntax `Nat.max` definition using `Nat.add a (Nat.sub b a)` before each fresh batch, qualify its emitted behavior, and then retry all 79 unchanged Core modules. The source review indicates that this can use the current compiler and existing native provider without a new trusted primitive. The support fixture belongs outside the Core tree, compiler bootstrap closure and full-Lean targets; full Lean already has that name. Kernel acceptance of its type would not prove that it computes maximum, and no claim is made that it resolves subsequent Core gaps.

After whole-Core generation works, the provider still needs a qualified canonical adapter, native/JS decision parity, resource limits, artifact authentication and Windows/Linux installation. Only a separately qualified explicit `pskernel-core-js` artifact may become an interim default before Wasm work. The current provider remains native.

JavaScript memory management does not establish logical soundness or make a Node child an arbitrary-code sandbox. Source-level Core proofs may transfer only through a justified source-to-executable refinement chain. The planned Wasm provider remains another execution option over one semantic Core.

## Proof scope and next milestones

Full assurance companions belong in `psc0/proofs/**/*.proof.lean`, with ordinary Lean model/lemma modules and full Lean tactics outside bootstrap. Full PSCV authoring can follow when available. The [architecture plan](PSC0_ARCHITECTURE_PLAN.md) names T1 ownership, descriptor/admission correspondence, name hygiene, public ABI, bundle/facade, publication and executable-refinement obligations. They are later theorem scopes, not proofs claimed by these tests.

The receipt flags `semanticPreservationProved`, `pscvVerified` and `strictSh1Qualified` remain false. Kernel admission does not prove logical consistency. RuntimeIR typing and TS7 acceptance do not prove that the emitted executable preserves every source behavior or contract.

Next work:

1. Implement real psdev watch using the established checked transaction: dependency invalidation, cancellation, generation identity, ownership/recovery and downstream build sequencing.
2. Continue same-source Core-JS qualification before a default change; keep Core refinement work and its trusted assumptions explicitly versioned.
3. Preserve exact bootstrap/release inputs durably and establish clean recovery before public npm release.
4. Add broader library resolution, final ps-prefixed package boundaries, deliberate release-default extensions and concrete producer/validator protocols incrementally.
5. Build pslsp and the VS Code client outside bootstrap, with editor analysis snapshots distinct from publishable generations.
6. Develop the separated proof program without making full formal completion a closing gate for bounded implementation milestones.

Preview2 qualification remains in [its retained record](docs/platform/onboarding-command-preview-qualification-2026-10-09.json), [run 37998655835](https://github.com/dwijayuda/pskernel/actions/runs/37998655835) and Git history. This page records T1's separately qualified successor and preview3.
