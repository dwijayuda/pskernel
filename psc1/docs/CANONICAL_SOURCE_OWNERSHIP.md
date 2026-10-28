# Canonical ProofScript source ownership

The editable compiler and ordinary standard-library sources are the `.ps` owners in [`CANONICAL_SOURCES.json`](../CANONICAL_SOURCES.json). That manifest identifies exactly one authored file for each portable module, its imports, and its paired checked bootstrap reference. [`compiler.project.json`](../compiler.project.json) selects the 125-module unified compiler from those owners.

The repository-wide [`SOURCE_OWNERSHIP.json`](../../SOURCE_OWNERSHIP.json) distinguishes PSC1 owners from independent projects, tests, retained generated kernels and historical material. Its inventory gate refuses an unclassified tracked `.ps` file. It does not infer ownership from a filename extension or make unrelated projects part of PSC1.

## Ownership boundaries

| Material | Authority and maintenance rule |
| --- | --- |
| 151 portable compiler-package `.ps` modules | Authored ProofScript; edit these files. |
| 13 ordinary standard-library `.ps` modules | Authored ProofScript; the existing `System/IO.ps` retains its original bytes at promotion. |
| Paired `.lean` files | Pinned bootstrap references. Changes require a checked refresh from the authored `.ps` owner. |
| Python/PHP native default-argument adapters | Retained native compatibility APIs that point to the corresponding canonical portable implementation. |
| Native byte-carrier adapters, process entries and unselected adapters | Explicitly classified native or retained material, outside portable canonical ownership. |
| Three standard-library compositions | Validation fixtures, outside the authored library module inventory. |
| Packaged standard-library source tree | An exact generated view of `stdlib/ProofScript`; never a second source of truth. |
| Independent kernels, host implementation, build tools and tests | Separate named ownership domains. |

The 164 portable owners have 164 paired references. The manifest separately classifies 18 remaining package/library files. These counts describe PSC1 portable ownership; the repository-wide inventory also records other projects and fixtures without rewriting their policies.

## Develop with the standalone compiler

The installed distribution includes the selected compiler, its private Node runtime, the precompiled official Lean checker, and an editable ProofScript compiler project. A separate language SDK is not required for ordinary builds or for changing that delivered compiler project.

From the extracted toolchain directory, build a compiler from the delivered sources, then select it to rebuild the same sources:

```sh
./bin/psc build compiler/project.json --profile correctness-3600s --out build/g1
./bin/psc build compiler/project.json --profile correctness-3600s --compiler build/g1 --out build/g2
```

Each build captures source bytes again, runs the selected compiler, checks original and transformed IR, and invokes the independent checker freshly. A previous manifest, fixed point or successful receipt does not admit a new build. A generated compiler is selected through its complete immutable build directory; its completion manifest and payload identities are checked.

The repository project uses the same canonical module bytes. Repository tooling can read them with `readCanonicalCompilerSources("Ps.CompilerUnified.Service")`. Native bootstrap consumers request the explicit `lean-bootstrap` grammar. Installed package source readers default to canonical ProofScript and label bootstrap references separately.

## Change a repository owner

1. Edit the canonical `.ps` file. Keep its paired `.lean` file and the existing ownership manifest unchanged.
2. Run the **PSC1 canonical bootstrap reference refresh** GitHub Actions workflow on the source-edit branch. Supply the exact ancestral commit containing the qualified manifest, or let the workflow select the last commit that changed that manifest. The script verifies this choice against the current manifest bytes.
3. Inspect the retained source, graph, conversion and any required native-build evidence. The workflow prepares content-addressed Git objects only. Review its exact prepared files and integrate them with an expected-head branch update.
4. Require the canonical ownership gate and the selected compiler, package and environment regression gates before treating the change as qualified.

The CI entry point is:

```sh
node scripts/refresh-canonical-sources.mjs --baseline EXACT_QUALIFIED_COMMIT
```

This is a repository-maintenance operation with native bootstrap tools available in CI. It is separate from ordinary installed compiler development. The refresh does not require callers of the installed compiler to install those tools.

The refresh captures each source again, parses actual imports, orders both ownership graphs, and refuses cycles or imports that cross their declared boundaries. It independently admits the canonical and reference graphs and requires identical admission bytes, strict original IR, partial names and member ownership.

Changed references must be the checked reverse projection, followed by the host adapter that restores native constructor shorthand at parser-identified pattern spans. That adapter preserves every other byte, reparses its result, verifies idempotence, and records input/output hashes and every inserted dot. Every adapted reference passes fresh graph correspondence.

When at least one compiler reference changes bytes, the refresh also builds the native bootstrap with the projected references and repeats compiler and library correspondence using the rebuilt helpers. Library-only edits, or edits that leave all compiler reference bytes unchanged, retain the fresh graph and projection checks but record `nativeBuild: false`. A failed required check prepares no reference tree.

Untouched reference bytes remain unchanged, even if a printer could render them differently. The transition gate compares with an exact ancestral manifest: changing a reference and merely updating its hash does not satisfy the rule. The initial promotion is pinned separately in `bootstrap/CANONICAL_BASELINE.json`; it is not a recurring permission to regenerate authored PS from Lean.

## What the gates establish

The static gate checks safe relative paths, regular files, exact UTF-8 bytes, unique owners, imports, package metadata, the generated standard-library view and exhaustive source classification. Ordinary source reads use files and hashes; Git history is consulted only by CI provenance checks.

The semantic gate freshly checks compiler and library graphs in both grammars. For changed owners it also checks the exact new projection. Changed compiler-reference bytes additionally require native compilation and correspondence through the rebuilt helpers, as described above. Recorded correspondence establishes byte-equal canonical admissions and original strict IR for those captured inputs. It is finite qualification evidence, not a formal proof that every compiler transformation preserves every program.

The all-151 compiler ownership graph produced 34,431,244 admission bytes and 10,029,216 original-IR bytes in the measured capacity probe. Only this synthetic repository index can explicitly request the bounded `canonical-repository-40m` graph-file profile. Ordinary helper calls retain the 32 MiB graph cap; request, index, stdout, source and process limits are unchanged. The initial preparation checks the ordinary-capacity refusal before proceeding with the larger audit profile. See the [capacity observation](PSC1_CANONICAL_GRAPH_CAPACITY_2026-10-28.json).

The initial native portability changes have a separate [native equivalence receipt](PSC1_NATIVE_PORT_QUALIFICATION_2026-10-28.json). It retains complete comparison reports, fresh independent admissions, default-argument checks, lossless tests, and modular package execution/publication evidence.

## Bootstrap and installation evidence

Bootstrap references preserve a native route for assembling the distribution and checking repository changes. They are not competing editable owners. The initial promotion retains the existing references and records a separate probe of whether a wholesale reverse-rendered replacement compiles natively. That probe is reported explicitly; an unsuccessful replacement probe never causes the retained references to be silently replaced.

Installation qualification is scoped to the exact environment receipts: operating-system version, kernel, architecture, private runtime, checker executable, resolved shared-library paths and hashes, filesystem, execution traces and publication outcomes. An ABI-only observation does not qualify compiler self-rebuilds or publication. A receipt from one environment does not qualify another.

The [measured rebuild profile](PSC1_REBUILD_PROFILE_2026-10-28.json) retains the workload and sampling evidence used to choose the first allocation change. Performance and platform support are claimed only by their completed qualification records.
