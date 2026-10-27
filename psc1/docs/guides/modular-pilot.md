# Modular JS/TS compiler-component package pilot

This experimental, unpublished cohort contains real generated compiler code:
the existing [Foundation.Name](../../packages/foundation/src/Ps/Foundation/Name.lean)
module and a [dependent consumer](../../test/modular/Consumer.lean). It does not
replace the qualified proofscript compiler or claim a complete modular compiler.

## What is generated

| Package | Responsibility |
| --- | --- |
| @proofscript/modular-pilot-runtime | One implementation WeakMap, string runtime/cache, and nominal type/constructor owner per JS or TS variant |
| @proofscript/modular-pilot-names | Actual generated Foundation.Name function bodies |
| @proofscript/modular-pilot-consumer | Actual generated dependent function bodies, importing the names package |
| @proofscript/modular-compiler-pilot | Small integrity loader and exact cohort metadata |

Each child provides ordinary ESM at its default export and at /ts. The default
contains DirectJS structural-tag output; /ts contains compiled TypeScript with
shared unique-symbol tags. Their data ABIs intentionally differ. Each has matching
.d.mts declarations. Readable generated .mts, genuine TypeScript source/declaration
maps, and the owned .lean/.ps source snapshots accompany the packages. The maps
point to generated TypeScript; original Lean/PS provenance is declaration-level.
No fabricated original-source line mapping is claimed. All owned packages contain
Apache-2.0 LICENSE and NOTICE.

## Reproduce and install

Use the pinned Linux CI development environment. From psc1:

    lake build psc1_modular_pilot psc1_independent_checker
    lake env lean --run test/modular/Plan.lean
    node test/modular/native-probe.mjs
    node test/modular/packages.test.mjs

The workflow installs the locked TypeScript SDK and host AST parser first.
The package test produces separate admitted Lean-input and PS-input cohorts,
offline-installs all four tarballs without lifecycle scripts or registry access,
strict-checks NodeNext and bundler consumers, and executes both variants with Node
and Bun against bundled output from the same IR. Qualification JSON and tarballs
are retained in the workflow artifact. The installable-lean and installable-ps
directories contain the four mutually compatible tarballs; install all four paths
together with npm install --offline --ignore-scripts. These are pilot packages,
not registry releases or replacements for npm install proofscript.

    import {loadPilot} from '@proofscript/modular-compiler-pilot';
    const {names, consumer} = await loadPilot({variant: 'ts'});
    const name = names.psNameAppendStr(consumer.pilotSeed, 'hello');
    console.log(consumer.pilotDescribe(name)); // hello!

Select js or ts for the entire graph. Do not interchange their values or mix
same-version packages from different source cohorts.

## Trace the implementation

1. [Native coordinator](../../host/src/Ps/Host/ModularPilot.lean) calls the production
   captured elaborator once. Exact tagged declaration origins and the erasure name
   map establish value ownership; ambiguous/unknown origins refuse.
2. Existing original strict IR validation and closed specialization run.
   Surviving transformed value names must retain exact known owners. Unknown
   synthesized names refuse. Worker fusion is outside this first profile.
3. [Pure graph planner](../../packages/backend-common/src/Ps/BackendCommon/Modules.lean)
   revalidates strict IR, checks ownership and lexical global references, and
   accepts only a bounded ordered DAG. Each source unit must be nonempty.
4. [JS emitter](../../packages/backend-js/src/Ps/BackendJs/Modules.lean) prints
   structured JsIR declarations using the existing printer.
   [TS emitter](../../packages/backend-ts/src/Ps/BackendTs/Modules.lean) builds one
   complete brand/tag plan and uses the existing declaration printer. Neither
   splits emitted text or re-exports a monolithic compiler facade.
5. [Host compiler session](../../host-tools/modular/compiler.mjs) treats native
   output as candidate data and invokes the genuine external official Lean checker
   with the existing host protocol. One canonical Core graph is admitted; the
   current JS request identity is shared for both artifact variants. This is not
   a backend-preservation proof.
6. [Assembler](../../host-tools/modular/build.mjs) validates printed imports/exports,
   compiles TS/declarations with the pinned SDK, records every file/hash and exact
   dependency, and creates four tarballs. The existing portable-file transaction
   publishes those flat tarballs and evidence as one whole generation.
7. [Installed loader](../../host-tools/modular/loader.mjs) verifies the complete
   stable installed inventory, cohort pin, sibling package locations and hashes
   before target import, then rechecks after loading. The qualified bootstrap/pin
   is its trust anchor. Package metadata grants no checker, SDK or publication
   authority. Package exports and direct child imports are ordinary npm APIs,
   not a sandbox or independent proof checker.

The flat atomic npm-cohort transaction does not qualify arbitrary nested service
publication. Pre-commit failure retains the previous pointer; a post-commit
failure reports committed-durability-uncertain, never a false rollback. Linux is
the only qualified publication platform. Installed verification assumes the
trusted bootstrap and stable package files; it is not protection against a hostile
writer racing ESM execution or replacing the verifier itself.

## Invariants, refusals and bounds

The [finite machine-readable pilot contract](../../test/modular/contract.json)
defines the exact cases and limits. Requests contain two source modules of one
grammar; there are three units, at most 256 surviving values and 64 nominal types.
Input is bounded to 1 MiB, native response and published cohort to 32 MiB.
Producer requests retain 240 seconds, 4 GiB address space and 8 MiB stack;
independent checking retains 120 seconds. Reference traversal retains fuel 4096.

The planner refuses external imports, missing/duplicate/unknown owners, open
generic surviving values, backward/cyclic unit dependencies and eager
initializers. Global synthetic runtime names and dynamic-authority identifiers
are reserved. Lexical bindings are excluded from global imports. Nominal types
and symbols are centralized once per variant; source units cannot create their
own Symbol or WeakMap instances.

Host checks reject facade/dynamic imports, missing/extra/tampered files, symlinks,
nested runtime copies and version/source-cohort mismatches. Ill-typed source and
missing source imports refuse. Negative tests retain the real validator/checker;
no fake acceptance token, mock checker or relaxed IR policy is used.

## Boundary before promotion

This is a real compiler-component graph emitted from two sources through one
production frontend, not independently compiled whole-compiler packages. Its new
planner/emitters are additive native Lean modules; their own portable self-host
qualification remains pending. No whole-compiler modular G1/G2/G3 or fixed point,
seven-backend modular application qualification, macOS/Windows execution,
performance improvement or human-comprehension result is claimed. Existing
qualified bundled executors, Practical Core contract, providers and kernel
implementations remain separate and unchanged.

Next: carry explicit synthetic declaration provenance through transforms, measure
the complete compiler dependency graph, then extend the bounded unit/cohort plan
without duplicating shared runtime state. Only promote after actual complete
modular compiler and self-host qualifications. See the [roadmap](../PSC1_DEVELOPMENT_ROADMAP.md).
