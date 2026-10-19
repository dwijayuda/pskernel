# PSC0 v7.2 Core-first architecture

## Decision and current scope

Begin the Core compiler critical path now, beside the preserved Full work. The user authorized this change on 18 October 2026 UTC (19 October in Asia/Jakarta). Completing every advanced Full M3 exit is no longer a prerequisite for an independently qualified Core slice. No milestone is completed by changing its denominator.

The working branch is `psc0/core-first-environments-20261019`, created from qualified Stage0 `33676076bcda7b0de5ec1f9803f49b8b1d28a058`. The active qualified PSC0 branch, its draft PR #109, the unfinished Full preparation branch, PSKernel-Core/C0 and unrelated research lines retain their histories. All repository changes use GitHub expected-HEAD non-force updates and Linux CI.

The language authority is the unchanged [selected v7.2 reference](../PSCV0_LANGUAGE_REFERENCE_v7.2.md). The [original roadmap](PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md) and its historical acceptance are unchanged. The new [Core roadmap](PSC0_CORE_FIRST_ROADMAP.md) explicitly maps the narrower compiler workload and deferred Full obligations.

## Initial deliverables

| Deliverable | Recorded contract |
| --- | --- |
| [Capability inventory](PSC0_CORE_CAPABILITY_INVENTORY.md) | Actual compiler roots, implementation features and selected-source conversion blockers |
| [Environment audit](PSC0_CORE_STANDARD_MANIFEST.md) and [machine-readable ledger](PSC0_CORE_STANDARD_MANIFEST.json) | Measured import/assets evidence, candidate declaration closure, profile identity and inclusion gates |
| [Core roadmap](PSC0_CORE_FIRST_ROADMAP.md) | M1–M5 and A–E exits, historical acceptance and explicit Full deferrals |
| [Optional module/package plan](PSC0_OPTIONAL_MODULES_PLAN.md) | Concrete owners, real installation boundaries and migration order |
| [Selfhost plan](PSC0_CORE_SELFHOST_PLAN.md) | Authoritative compiler source, Stage0–3 and fixed-point/runtime requirements |
| [Qualification ledger](PSC0_CORE_QUALIFICATION_LEDGER.md) | Exact receipts, failures, metrics, open risks and next gates |

## Shared architecture and profile ownership

Preserve the existing sequence: owned source reader, resolution, elaboration, prepared declarations, independent checking, typed erasure, validated IR, target emission. Both selected `.lean` and `.ps` inputs converge on shared checked semantics. Compiling implementation files with native Lean is a separate observation.

The intended profiles are Bootstrap, Core and Full. Bootstrap must be the smallest measured dependency-complete environment that compiles the entire authoritative compiler workload. Core adds the explicitly selected general-purpose programming contract and becomes the application default only after qualification. Full adds checked optional compositions. The 76-declaration Bootstrap root implemented here is a seed component toward that target, not a compiler-sufficient Bootstrap profile. Their required inclusion is a statement about compatible checked declarations, types, bodies, family/rule metadata, instances and runtime contracts. A set of seed names, a runtime-filtered Full environment, or a function with “Core” in its name is insufficient. The current independently authored candidates have not established Bootstrap ⊆ Core ⊆ the existing Full environment.

The extraction sequence is:

1. Move canonical environment serialization/hashing into `Ps.Environment.Fingerprint`; keep existing Full pins and mandatory Full audits in `StandardSnapshot`.
2. Move generic host replay into `PsKernelLean.Replay`; retain the existing Full `Prelude` wrapper and exactly its reviewed import policy. Generic replay begins at `Lean.mkEmptyEnvironment 0` and uses existing finite admission defaults.
3. Move shared compilation operations into `Ps.Compiler.Engine` with explicit actual environment and runtime inputs. Keep existing `Compiler.Api` signatures as the Full compatibility composition.
4. Separate deriving expression constructors from Standard environment assembly. Then thread the same checked profile through the actual selected `Pscv0`, project/module, host admission and emission route.
5. Admit actual Bootstrap/Core assets from measured native declaration closure, establish inclusion/registration/runtime identities, and expose independently buildable compositions. Only then change a release default or distribute a Core package.

The compiled profile context selects actual inputs; it is not an admission token. An external loader must authenticate the authorized canonical environment and runtime contract, check their actual closure, and bind every prepared/module/cache artifact to that same identity. A claimed digest, profile label or an in-process record cannot establish this authority.

The complete identity must cover the selected reference and capability manifest; declarations and their exact kinds/types/values; aliases/reducibility; classes/ordinary/default instance priorities; constructors and recursor rules; assumptions; compiler/module interface versions; runtime primitive models; checker identity and resource policy; target ABI, platform word size and backend contract. Portable logical serialization alone does not authenticate all of these inputs.

## Trust and compatibility

Pinned Lean 4.35.0 commit: `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. The maximum approved logical assumptions remain `propext`, `Quot.sound`, and `Classical.choice`; each new profile records its actual smaller closure. No new source axioms, proof holes, runtime choice, kernel bypass, larger admission budget or relaxed negative gate is authorized.

Ordinary checked, partial, unsafe, verified, model and refinement identities stay distinct. Core describes language/library workload; it is not a new assurance grade. Wasm uses GC internally and linear memory only at the explicit ABI.

The independent kernel is allowed to remain external to compiler selfhost. Native authoring tools may inspect the pinned library and generate candidate data, but neither that host dependency nor a successful native build can be hidden inside the portable compiler or counted as Stage1.

## First independently tested slice

The fingerprint and replay extraction preserves old public helper names, serializer bodies, Full expected hashes, diagnostic text and replay algorithms. The independent probe checks SHA-256 vectors, actual dependency deferral, absence of an implicitly loaded Nat prelude, and rejection of an ill-typed definition. Its Linux receipt is in the qualification ledger. Bootstrap and byte/word exports are separate candidate authoring probes, with an empty base and explicit assumption policy.

The shared Engine and selected Pscv0Engine now accept the same retained in-process environment/runtime context. Existing Api/Pscv0 wrappers preserve the Full defaults and public signatures. Twenty-four deriving expression builders moved unchanged into InhabitedExpr/ReprExpr; their source import graphs no longer pull Standard or SelfHostProd. The actual existing project loader remains Full-bound and is not hidden from the compiler-source denominator.

At exact `93107eab14b7347f9605b1396c7a79f2b628ba61`, the [focused Linux run](https://github.com/dwijayuda/pskernel/actions/runs/39181815014) passed all four jobs: source inventory, native seams (including Engine and paired selected readers), Bootstrap replay and candidate authoring. The paired selected test retains both source applications, compares actual canonical output and admits the decoded declarations with the independent official kernel over one previously checked base declaration. Runtime selector tests cover context propagation and the none/32/64 declaration roster; emitted backend execution is a separate gate.

The committed BootstrapData asset is exactly the independently authored 118,573-byte source, with 76 declarations, no axioms and eleven reducibility entries. Bootstrap replay starts from an empty trust-zero kernel with finite per-declaration limits, regenerates family metadata/rules and records its logical payload identity. Native authoring reproduction and literal candidate-versus-Full comparison remain separate from that minimal import graph.

The final [run 39183454255](https://github.com/dwijayuda/pskernel/actions/runs/39183454255) requalified all four jobs at `e059098683d3388fc9f893ec12027b4998eafd52`. Correctly loaded native class metadata adds the measured Decidable/Nonempty rows; every declaration comparison and the raw Bootstrap replay manifest remain unchanged.

This slice establishes reusable checked infrastructure and bounded selected-source behavior. Compiler-sufficient Bootstrap, general-purpose Core, authenticated project/module/cache selection, runtime/backend correspondence, package isolation and Stage1–3 remain open.
