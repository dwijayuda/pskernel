# Optional module and npm package plan

## Existing package boundary

The current [compiler manifest](../packages/compiler/package.json) declares `psc0-monolithic-runtime-with-scoped-source-packages/1`. The [environment package](../packages/environment/package.json) depends on `@proofscript/compiler`, and its files roster includes all src and dist content. Scoped source/runtime facades therefore do not establish independent compiler or Standard loading.

The [historical npm plan](NPM_PACKAGING_ARCHITECTURE.md) includes the old selfhost closure, TypeScript toolchain and generated PSKernel-Core checker. Those historical receipts and scripts must retain their identities; they are not the current v7.2 Lean-backed Core release and must not be repurposed by renaming. PSKernel-Core/C0 is outside this refactor.

No new package is published, no existing dependency is removed, and no default install is switched by the first seam extraction.

## Concrete source and distribution owners

Proposed package names below are implementation targets, not published registry claims. Existing source owners and compatibility exports remain until each boundary is qualified.

| Composition / proposed package | Source owners | Required payload and boundary |
| --- | --- | --- |
| Generic environment support | Environment.Basic, Fingerprint, Logic/Decision and extracted expression builders | Portable declaration/metadata utilities; no selected Standard or Full asset import |
| Bootstrap seed / @proofscript/bootstrap-standard | New Environment.BootstrapData and Bootstrap composition after admission | Exact checked seed, registration/assumption manifest, provenance; no placeholder primitive base |
| Core Standard / @proofscript/core-standard | New Environment.CoreData and Core composition after measured closure | Entire required library proof/type/runtime/instance closure; no default Full optional payload |
| Core compiler / @proofscript/compiler-core | Engine plus explicit-context selected frontend/project and chosen bootstrap emitter | A real executable compiler module built from the authoritative source manifest; no re-export of old monolithic compiler |
| Full Standard / @proofscript/standard-full | Existing SelfHostProd/StandardSnapshot compatibility plus reviewed compatible optional owners | Explicit Full composition and identity; existing Full receipts retained separately |
| Float arithmetic / @proofscript/standard-float | StandardFloatOperationsData, FloatConstructors, FloatCanonical, FloatDisplay and exact dependencies | Checked logical/model/runtime assets and their F1/F2/F3 gates; no default Core import when closure permits |
| Float conversions | StandardFloatConversionsData and related conversion owners | Exact source/model/primitive contracts and target qualification |
| Platform words | StandardPlatformWordsData and platform/runtime owners | Explicit platform/word-size contract and host ABI; no inferred machine width |
| Word operations | StandardUnsignedOperationsData and associated proof/runtime owners | Partition only where the actual Core dependency graph permits; compiler hashing keeps needed word proofs |
| Advanced recursion | StandardPartialFixpointData, StandardPartialFixpoint, StandardClassical and dependent owners | P1/choice proof and runtime ownership remain separately checked; required WF proof dependencies stay in Core |
| Optional backends | Existing backend-rust, backend-wasm and other target module roots | Genuine independently built target runtime/emitter exports with checked IR/ABI interfaces; no compiler facade |
| Optional verification capabilities | Existing selected elaboration/proof/model owners and explicit capability manifests | Installing source/data does not install trusted proof authority or silently extend the selected grammar |

## Build and loading contract

Each package has an explicit public module prefix, allowed source root, authoritative source kind, exact compiler/environment/interface identity, transitive package/content hashes, assumptions, runtime/ABI requirements and provenance. The compiler resolves only declared imports inside the package boundary and checks actual declarations/metadata with the receiving environment. Reject missing modules, namespace collisions, path escapes, undeclared dependencies, alternate-extension fallback and stale artifacts.

A library package supplies checked source/data. It cannot execute npm JavaScript to grant axioms, replace admission, insert instances unchecked or redefine kernel rules. Parser/elaborator/backend capabilities are explicit compiler integration points with their own qualification; shipping a source package does not automatically add those capabilities.

Default Core manifests must omit unwanted payloads from both dependencies and optionalDependencies. npm optionalDependencies are still installed by default in ordinary installations. Use explicit user-selected packages and an explicit checked composition manifest. Peer or optional metadata alone is not evidence of a physical size boundary.

Generate each tarball from a reviewed file/closure manifest. Repository source preservation does not require including every generated Full asset in a Core tarball. The installed dist graph must also avoid imports/re-exports that pull the monolith back in. A smaller entry point with an unchanged archive is not package isolation.

## Migration sequence and acceptance

1. Preserve compatibility APIs; isolate generic helpers, replay and Engine.
2. Establish real Bootstrap/Core declaration and runtime identities, exact profile threading and checked optional composition.
3. Generate independent executable Core and backend modules using the existing checked IR/codegen contract.
4. Stage new packages from exact manifests, retain notices/source authority and reject undeclared Full files.
5. Use Linux to measure npm pack archive bytes, unpacked bytes and a clean installed dependency tree. Record pinned Node/npm/platform, lockfile, install flags and content lists; measure defaults and each explicit optional addition.
6. Run installed compiler source/refusal/kernel/runtime fixtures outside the repository, with no parent source or global compiler fallback. Verify Core lacks optional names and explicit checked installation adds precisely the expected capability.
7. Only after all gates pass, select a Core release default with an explicit compatibility/version migration. Publishing remains a separate reviewable release action.

## Metrics and risks

The source audit records package manifests and exact repository source bytes. It does not measure packed or installed npm bytes, generated JS size, startup time or a speedup. These remain open until actual independent payloads exist and are measured under the same recipe.

The first measured empty-boundary byte/word candidate has 1,945 checked declarations and 16,111,994 generated source bytes. It demonstrates why removing a named Float import is insufficient to promise a tiny Core; exact proof closure and actual package measurements control that claim.

The largest initial source opportunity is removing unnecessary Full composition roots, particularly Float assets. Word proofs and some well-founded logic are real compiler dependencies and cannot be discarded for size. A release claiming a smaller compiler must report actual source, generated artifact, archive, installed dependency and runtime measurements separately.
