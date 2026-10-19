# PSC0 v7.2 Core-first architecture

## Decision and current scope

Current priority, authorized 19 October 2026 at 10:21 Asia/Jakarta: **complete Core language/compiler M1–M5 first; selfhost follows their acceptance**. This supersedes the earlier compiler-source-first execution priority. Preserve its measured source manifest, completed components and final Stage1–3 obligations. [The completion register](PSC0_CORE_LANGUAGE_COMPLETION_PLAN.md) owns the immediate queue.

Begin the Core compiler critical path now, beside the preserved Full work. The user authorized this change on 18 October 2026 UTC (19 October in Asia/Jakarta). Completing every advanced Full M3 exit is no longer a prerequisite for an independently qualified Core slice. No milestone is completed by changing its denominator.

The working branch is `psc0/core-first-environments-20261019`, created from qualified Stage0 `33676076bcda7b0de5ec1f9803f49b8b1d28a058`. The active qualified PSC0 branch, its draft PR #109, the unfinished Full preparation branch, PSKernel-Core/C0 and unrelated research lines retain their histories. All repository changes use GitHub expected-HEAD non-force updates and Linux CI.

The language authority is the unchanged [selected v7.2 reference](../PSCV0_LANGUAGE_REFERENCE_v7.2.md). The [original roadmap](PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md) and its historical acceptance are unchanged. The revised [Core roadmap](PSC0_CORE_FIRST_ROADMAP.md) maps Core language/compiler acceptance, retained Full obligations and the separate final selfhost phase.

## Initial deliverables

| Deliverable | Recorded contract |
| --- | --- |
| [Language completion register](PSC0_CORE_LANGUAGE_COMPLETION_PLAN.md) | Core feature/conformance mapping, immediate shared owners and M1–M5 execution order |
| [Implementation inventory](PSC0_CORE_CAPABILITY_INVENTORY.md) | Retained actual compiler roots and final selfhost conversion blockers |
| [Environment audit](PSC0_CORE_STANDARD_MANIFEST.md) and [machine-readable ledger](PSC0_CORE_STANDARD_MANIFEST.json) | Measured import/assets evidence, candidate declaration closure, profile identity and inclusion gates |
| [Core roadmap](PSC0_CORE_FIRST_ROADMAP.md) | M1–M5 and A–E exits, historical acceptance and explicit Full deferrals |
| [Optional module/package plan](PSC0_OPTIONAL_MODULES_PLAN.md) | Concrete owners, real installation boundaries and migration order |
| [Selfhost plan](PSC0_CORE_SELFHOST_PLAN.md) | Authoritative compiler source, Stage0–3 and fixed-point/runtime requirements |
| [Qualification ledger](PSC0_CORE_QUALIFICATION_LEDGER.md) | Exact receipts, failures, metrics, open risks and next gates |

## Shared architecture and profile ownership

Preserve the existing sequence: owned source reader, resolution, elaboration, prepared declarations, independent checking, typed erasure, validated IR, target emission. Both selected `.lean` and `.ps` inputs converge on shared checked semantics. Compiling implementation files with native Lean is a separate observation.

Core is the dependency-complete checked declaration, source-registration and runtime composition required by the selected Core language/application contract. Its M1–M5 qualification does not depend on converting compiler implementation sources. Bootstrap retains its target of the smallest measured composition sufficient for the complete authoritative compiler, to be established during final selfhost preparation. Full retains separately checked optional composition. The existing 76-declaration seed and 92-declaration Foundation component are qualified only at their recorded scopes. Compatible Bootstrap/Core/Full nesting remains an explicit, unproved goal; the current seed/Full mismatch is unchanged. Inclusion requires compatible checked types, values, family/rule metadata, instances and runtime contracts. Neither root-list inclusion nor filtering a Full runtime establishes a qualified composition. Core becomes an application default only after the applicable language/profile/runtime/package gates pass.

The implemented boundaries and remaining composition work are:

1. `Ps.Environment.Fingerprint` owns canonical environment serialization/hashing; existing Full pins and mandatory Full audits remain in `StandardSnapshot`.
2. `PsKernelLean.Replay` owns generic host replay; the existing Full `Prelude` wrapper retains its reviewed import policy. Generic replay begins at `Lean.mkEmptyEnvironment 0` and uses existing finite admission defaults.
3. `Ps.Compiler.Engine` owns shared compilation with explicit actual environment and runtime inputs. Existing `Compiler.Api` signatures remain the Full compatibility composition.
4. Preserve the completed deriving-helper separation and explicit-context selected single-source and fresh project owners. Carry the same actual environment/runtime inputs through consuming host, admission and emission boundaries, and qualify each workload and runtime contract.
5. Admit actual Core assets and qualify their complete declaration/registration/runtime identities for M1–M5. Measure compiler-sufficient Bootstrap during final selfhost preparation. Independently buildable packages, compatible Full composition and release-default selection retain their own gates.

The compiled profile context selects actual inputs; it is not an admission token. An external loader must authenticate the authorized canonical environment and runtime contract, check their actual closure, and bind consumed artifacts to that identity. Fresh project interfaces and receipts are descriptive in-process results. No selected persistent-cache loader currently exists. A future artifact consumer must obtain its expected binding from independently authorized inputs or recompute it from those inputs; comparing two claimant-supplied digests cannot authenticate reuse.

The complete identity must cover the selected reference and capability manifest; declarations and their exact kinds/types/values; aliases/reducibility; classes/ordinary/default instance priorities; constructors and recursor rules; assumptions; compiler/module interface versions; runtime primitive models; checker identity and resource policy; target ABI, platform word size and backend contract. Portable logical serialization alone does not authenticate all of these inputs.

## Trust and compatibility

Pinned Lean 4.35.0 commit: `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. The maximum approved logical assumptions remain `propext`, `Quot.sound`, and `Classical.choice`; each new profile records its actual smaller closure. No new source axioms, proof holes, runtime choice, kernel bypass, larger admission budget or relaxed negative gate is authorized.

Ordinary checked, partial, unsafe, verified, model and refinement identities stay distinct. Core describes language/library workload; it is not a new assurance grade. Wasm uses GC internally and linear memory only at the explicit ABI.

The independent kernel is allowed to remain external to compiler selfhost. Native authoring tools may inspect the pinned library and generate candidate data, but neither that host dependency nor a successful native build can be hidden inside the portable compiler or counted as Stage1.

## Current language implementation

Qualified executable commit: `da1116dc28b282dfcf0c8e178c52a69f11477708`, tree `031cd3cd7e4917ca29ce7c7296c24051aa07a82e`. [Core Linux run 39255930001](https://github.com/dwijayuda/pskernel/actions/runs/39255930001) completed successfully at 2026-10-19T13:05:10Z: all four jobs passed.

Named namespaces and sections now introduce one frame per component. Named ends close the matching innermost components; unnamed-section barriers, bare-end restrictions, variable restoration and sequential public-section defaults are checked. Literal `_root_` components in scope headers retain their canonical identity. The paired rooted fixtures cover direct, registered, inferred, where, ordinary mutual and structure-family names. Lean exercises its absolute declaration-head syntax; ProofScript uses its selected unqualified declaration head after closing the namespace. Both readers exercise absolute term references.

Headerless legacy clients receive original elaboration declarations and metadata through every transitive import edge, before preparation or runtime lowering. Ordinary checked definition bodies and their private implementation dependencies remain available; genuine source opaque declarations remain opaque. Module clients keep the separate public interface and signature/exposed-body visibility checks. Legacy local-private signatures and exposed bodies are checked separately.

Ordinary module where helpers now have private checked identities. Provider-local aliases allow later commands in that provider to use the source helper name; importers cannot resolve that spelling. Headerless providers retain public helper names. The fixtures check the real helper dependencies, generated equation ownership and source provenance.

The new selected fixture groups total 36 independently admitted projects and 38 owned refusals. Separate pinned-native oracles pass 50 compilations (28 successes/22 refusals), 25 ordinary visibility observations, 15 rooted-name/privacy observations and three unsupported scope forms. The same finite Eq-only checking base and all trust/assumption/resource policies are retained.

Legacy default-instance entries are inspected; ordinary synthesis is the executed metadata behavior. Registered abbreviation-with-where keeps its selected registration refusal. Rooted ordinary mutual admission does not extend partial-mutual qualification.

The complete Foundation.Source/List regression still retains 25 prepared declarations and the exact 53,310-byte canonical payload, SHA-256 `6c7603e8cd49e830a61fca136153117630097052cd8e93bfd3f87f248d2b27a1`. The original source files, their ProofScript counterparts, 92-declaration Foundation candidate, 76-declaration Bootstrap seed and Full logical identity are unchanged.

The retained `pscv0-v7-native-bounded/73` Full compatibility application passes 1,069 observations on each of TypeScript 7.0.2, direct JavaScript and Rust 1.98.1. These application results remain separately attributed from the new scope/import preparation, admission and native controls. Complete Core runtime/profile and formal target refinement remain open.

The requested component/end/root and legacy-body/private/metadata/where obligations are closed at this recorded scope. Complete CL04/CL05 and M2 remain open: the complete selected rule/form/interaction-to-fixture mapping, native proof abstraction inside exposed definitions, full native elaboration/module correspondence and complete Core profile obligations need their own evidence. Core M1–M5 remain the priority; selfhost follows their acceptance.

[The scope and legacy receipt](core-first-evidence/core-language-scope-legacy-qualification.json) retains exact attribution and the earlier failed fixture attempts. [The prior import-visibility receipt](core-first-evidence/core-language-import-visibility-qualification.json) remains historical.

## First independently tested slice

The fingerprint and replay extraction preserves old public helper names, serializer bodies, Full expected hashes, diagnostic text and replay algorithms. The independent probe checks SHA-256 vectors, actual dependency deferral, absence of an implicitly loaded Nat prelude, and rejection of an ill-typed definition. Its Linux receipt is in the qualification ledger. Bootstrap and byte/word exports are separate candidate authoring probes, with an empty base and explicit assumption policy.

The shared Engine and selected Pscv0Engine accept the same retained in-process environment/runtime context. Existing Api/Pscv0 wrappers preserve Full defaults and public signatures. Twenty-four deriving expression builders moved unchanged into InhabitedExpr/ReprExpr. Pscv0ModuleEngine now owns fresh portable project preparation: each module receives the actual base extended by its imported interfaces, and the final prepared project retains the original caller profile. Pscv0Modules preserves the Full compatibility entry.

At exact `93107eab14b7347f9605b1396c7a79f2b628ba61`, the [focused Linux run](https://github.com/dwijayuda/pskernel/actions/runs/39181815014) passed all four jobs: source inventory, native seams (including Engine and paired selected readers), Bootstrap replay and candidate authoring. The paired selected test retains both source applications, compares actual canonical output and admits the decoded declarations with the independent official kernel over one previously checked base declaration. Runtime selector tests cover context propagation and the none/32/64 declaration roster; emitted backend execution is a separate gate.

The committed BootstrapData asset is exactly the independently authored 118,573-byte source, with 76 declarations, no axioms and eleven reducibility entries. Bootstrap replay starts from an empty trust-zero kernel with finite per-declaration limits, regenerates family metadata/rules and records its logical payload identity. Native authoring reproduction and literal candidate-versus-Full comparison remain separate from that minimal import graph.

The earlier [run 39183454255](https://github.com/dwijayuda/pskernel/actions/runs/39183454255) requalified all four jobs at `e059098683d3388fc9f893ec12027b4998eafd52`. Correctly loaded native class metadata adds the measured Decidable/Nonempty rows; every declaration comparison and the raw Bootstrap replay manifest remain unchanged.

[Run 39189228561](https://github.com/dwijayuda/pskernel/actions/runs/39189228561) passed all four jobs at `d444e33d4f076d56ce141745c7ac0c7787dbd9f3`, adding the paired two-module project probe. It qualifies actual dependency invocation, retained profile/import receipts, canonical equality, finite kernel admission, graph/scope/metadata refusals and None/32/64 selection with typed IR validation. The public-import positive belongs to the selected `.ps` grammar. It does not establish full native module grammar, persisted artifact authentication or emitted backend execution.

These slices establish reusable checked infrastructure, bounded selected-source behavior and fresh selected project context propagation. Compiler-sufficient Bootstrap, general-purpose Core, external artifact authentication, runtime/backend correspondence, package isolation and Stage1–3 remain open.

## Complete Foundation source qualification

At `1995a478af7aeb83032749fbdb9a2cfa96d28a88`, [run 39191534560](https://github.com/dwijayuda/pskernel/actions/runs/39191534560) passed all four Core-first Linux jobs. PSC0 accepted both complete original Foundation.Source and Foundation.List files and their ProofScript counterparts through the explicit-context project engine, produced identical canonical admissions, and independently admitted both results over the measured 92-declaration candidate. It retained every original seed declaration/effective reducibility and the measured source metadata. Native elaboration parity, emitted backend execution and whole-compiler selfhost remain unqualified.

The [source receipt](core-first-evidence/compiler-source-qualification.json) records two actual files / twelve source declaration headers per syntax, with an importing driver. The complete originals total 2,534 bytes; their faithful ProofScript counterparts total 2,689. Preparation yields 25 declarations, including three structural helpers, record support and the driver. Canonical output is 53,310 bytes with strict paired equality and finite trust-zero kernel admission.

The 92-declaration candidate adds the actual OfNat and Bool.decEq dependencies and the required measured source registrations. It selects only OfNat, ordinary instOfNatNat at 1000 and its separate default entry at 100; it retains native Bool.not noncomputability. Its logical payload hash does not cover that index, which is checked separately. This component is not the complete compiler-sufficient Bootstrap or general-purpose Core profile.
