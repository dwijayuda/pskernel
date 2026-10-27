# PSC1 AI work state

Updated2026-10-27 Asia/Jakarta. Branch `feat/psc1-simple-npm-packages-20261027`, from qualified PR#196 HEAD `173ecdc9f7131366d376c80886a7843a402d363b`.
GitHub/Linux CI only; single-parent expected-HEAD/non-force updates. No merge or
registry publication. Previous state is preserved in [history](docs/history/AI_WORK_STATE_BEFORE_SIMPLE_NPM_2026-10-27.md).

## Active mission: simple existing npm packages

The user's new assignment explicitly defers complete compiler-internal IR linking
and modular G2/G3. Preserve existing package names, directories and canonical
source; reuse one qualified compiler owner rather than require a new compiler.

Inventory:25 existing directories,24 existing npm names. compiler-unified has no
npm name and remains internal source. Three existing distributions (proofscript
and both genuine Lean providers) already work as qualified tarballs; most source
manifests advertised absent dist exports and stale PSC0 metadata. Python/PHP also
have qualified external provider bundles. No public low-level compiler helpers
are exported by the frozen unified JS/TS executor; its only export is the service.

[40491338458](https://github.com/dwijayuda/pskernel/actions/runs/40491338458) verifies
the complete inventory and exact frozen inputs. [Build40492532684](https://github.com/dwijayuda/pskernel/actions/runs/40492532684)
at0bdef94ee5c5ac2b603bc41ab27f9edf61d0751b builds/packs all24 named packages.
Fresh installation/import/kernel/API/output/refusal qualification is pending.
The earlier40492161864 failed because canonical Emscripten build metadata differs
from the frozen qualified provider metadata. Keep canonical source untouched;
qualified provider payloads now live under their own dist/implementation.

Current cohort:proofscript/source adapters0.1.0-psc1.12; kernel npm wrappers
4.35.0-psc1.12, retaining official Lean semantic identity4.35.0/eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Versioned wrapper artifacts distinguish them from existing immutable4.35.0 tars.
Builds copy existing qualified executors/providers, not recompile or translate
compiler sources. Only proofscript owns the shared JS/TS executable implementation;
source packages expose verified source snapshots, compiler/CLI adapters re-export
existing checked APIs, and backend compile adapters select existing targets.
No private elaborator/Core API is fabricated. Python/PHP/native checking and
Rust/Wasm execution engines remain explicit optional packages.

Every package gets build/clean scripts, dist entry points where applicable,
correct exports/repository/licenses/version dependencies and installable tarballs.
Kernel canonical sources and implementations are unchanged. Their new npm entries
load the exact previously qualified C++ native or Emscripten linear-memory Wasm
provider. Root distribution pins are regenerated for explicit metadata/layout
changes; existing host/compiled execution code and safety limits remain.

Next: complete focused installed qualification, repair actual failures, publish
unpublished reproducible tarball artifacts/receipts and finish docs. Do not claim
installation alone proves compiler soundness or new G1/G2/G3/fixed points. Preserve
the exact old qualified source identities and existing normal regression gates.

## Deferred internal-modularity work retained separately

Branch feat/psc1-modular-partitions-20261027 retains the intermediate SCC/type-only
implementation atb9461a3c6cd556a2c73abdee5cd9156e745c7f5d. It is unqualified;
latest40489837660 failed. It is not part of this npm branch. Complete actual graph
measurement at177e41a3 passes40488488194:125 source modules,3154 original/3950
specialized/4520 fused values; no cross-source runtime SCC larger than one;
111938ms/maxRSS389420KiB. All original PR#195/#196 component qualifications remain
unchanged. No further internal compiler partition work is required for this npm
milestone. Platform-wide release and the arranged human maintainer trial remain
separate qualification tasks.
