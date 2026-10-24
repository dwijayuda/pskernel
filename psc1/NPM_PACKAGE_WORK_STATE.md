# PSC1 native npm package — verified provider/package checkpoint

## Unified compiler checkpoint — 2026-10-25

The package split remains the qualified native proofscript@0.1.0-psc1.3 core
(JS/TS/Rust/Wasm core+component) plus explicit matching Python/PHP add-ons.
Full 40117055147 passes offline default/optional execution and all retained
package/library/typed-IO checks. Artifact `12570094990` retains all three matching
unpublished tarballs; exact source/build pins intentionally reject mixed builds.
[Exact unified receipt](docs/PSC1_UNIFIED_SELFHOST_QUALIFICATION_2026-10-25.json)
records their digests and the native seven-backend qualification.

A separate generated composition root now passes all four G1 engines at
structured-v2 source `783cf8fc` (160 cross-target cases/36 refusals). Earlier
v1 source `b2ab4d34` passes genuine JS and TS G1/G2/G3 and exact fixed points.
Current-v2 full chains and generated-engine package/CLI/component/provider
integration remain pending. The npm metadata still correctly says native-lean
and noSelfHostQualification:true; no generated distribution or registry
publication is claimed. Continue through the [single roadmap](docs/PSC1_DEVELOPMENT_ROADMAP.md).


Updated2026-10-24 Asia/Jakarta. Draft [PR177](https://github.com/dwijayuda/pskernel/pull/177), stacked on preserved PR176/17cc49f. No merge or registry publication.

proofscript@0.1.0-psc1.3 includes the native checked compiler, JS/TypeScript/Rust/Wasm core/component emitters, host tooling, pinned official Lean checking integration and locked production npm dependencies. Python/PHP are separate explicit @proofscript/backend-python and @proofscript/backend-php provider tarballs. The core contains neither optional emitter nor its output-backend resources and pins each matching add-on's complete native/resource descriptor.

Full [40106542849](https://github.com/dwijayuda/pskernel/actions/runs/40106542849) PASSED: Linux `120912148533`/final gate120918578150;37/37 criteria,0 blocked,releaseReady=true; all seven backends/both grammars, applications, minimum-Python and installed package/IO/library checks. Review `70522c25ea3826c05ba2e80f7f1e9c7df0b58213` and tested merge `063d1da64db9beb69a8303af5a2a8788233dc7dd` have identical Git treeb2d2ad3e24a07218c081eb20bc85670fd64e29e4. Artifact `12566181617`,sha256:be0a4ed3850383345acfbf2127d34caa32154ed6c5f8ac10304edd3d54899957.

Focused40105565252 also PASS: exact retained emitters/IR, core/worker dependency inventories,16 protocol/IR and8 receipt refusals, actual optional execution in both grammars. Installed package qualification executes10 default and4 optional grammar/target cases and26 refusal/preservation cases. Existing offline local/global core, transitive source-library, installed typed IO and resource checks remain. Source-library metadata still carries no plugin/kernel/FFI authority.

The [provider receipt](docs/PSC1_BACKEND_PROVIDER_QUALIFICATION_2026-10-24.json) owns exact source/merge/artifact/tarball identities. [Provider guide](docs/PSC1_BACKEND_PROVIDERS.md) and [npm guide](docs/PSC1_NPM_ECOSYSTEM.md) describe installation and constraints. The [single roadmap](docs/PSC1_DEVELOPMENT_ROADMAP.md) owns remaining work.

Platform scope remains Linux x64/glibc,Node>=22. All packages are private/unpublished qualification tarballs. This milestone does not qualify a unified generated compiler or new G1/G2/G3 fixed point. Older PSC1 all-seven-built-in and PSC0 distributions remain preserved in Git history and [historical work state](docs/history/NPM_PACKAGE_WORK_STATE_BEFORE_NATIVE_2026-10-20.md).

Stop at this verified checkpoint. Further generated multi-backend composition, cross-version plugin ABI, non-Linux packages and publication require their respective implementation/qualification/authorization.
