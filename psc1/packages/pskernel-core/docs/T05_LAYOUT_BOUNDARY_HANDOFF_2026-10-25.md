## Source and canonical physical-layout extension — native30 pending

This isolated candidate retains the two source-layout theorem bodies from `aa369d2e0341a45297e7e2bd341f3294573b203b`, whose native27 preflight passed in run40153182189. It adds three statements: actual ReplayNode success preserves Layout of a valid internal accumulator; actual ValidateFuel success preserves that Layout for arbitrary source and starting ID; actual public Validate success establishes Layout of the returned canonical arena from the production empty seed.

The preflight now requires all30 ordered unique reports (metadata8 + paged17 + boundary5), all three successful commands, standard axioms only, and ten source inputs including the actual Paged push implementation. The production tree and retained proofs remain unchanged from the original isolated80005 baseline. This is proof-only work; the held transform optimization is not being adopted.

Compilation of the new statements is pending in this candidate. Metadata correspondence, topological decoding, ArenaModel and full source qualification remain open. The main restored T05 qualification remains independently bound to `ae47fa0ca776980890c20c730d00a4f11c73b6c4` /run40153400857 and is not expanded or replaced by this preflight.

# External physical-layout boundary proof — 2026-10-25

This isolated native proof batch is based on `80005bb250a7324772db76d51684d23fbf0fe6ed`. It changes no production function, existing proof module, pinned dependency, fuel, resource policy or runtime control.

New file: `psc1/test/PsKernelExprV2LayoutBoundaryProofs.lean`.

- `shape_valid_establishes_layout` derives all four fields of the existing physical `Layout` invariant from the actual `psKernelExprV2PagedShapeValid source = true` result. The source is arbitrary; no desired Layout field is assumed. A local fuel induction establishes the actual full-page scanner's suffix guarantee.
- `validate_ok_establishes_source_layout` derives `Layout source` from an actual successful public `psKernelExprV2PagedValidate source = .ok canonical`, using its fail-closed shape branch.

The native-only preflight checks the unchanged metadata8 and paged-model17 reports plus these two new reports, for27 exact ordered unique reports across3 modules. It authenticates the pinned Lean commit, exact workflow/source inputs, unchanged production tree and unchanged retained proofs against80005, command statuses and allowed standard axioms. It archives actual source files, logs, source inventory and receipt. Compilation and qualification are pending at the creation of this checkpoint.

Scope is physical source layout only. These theorems do not prove returned canonical Layout, metadata correspondence, topological decoding, any ArenaModel field, or the full Replay-to-ArenaModel bridge. The next structural step is success-preserves-Layout for PagedReplayNode and an induction for PagedValidateFuel. The existing ArenaModel separately needs decode/node correspondence, depth metadata bounds and child resolvability.

Do not substitute this new source for the running exact80005 full492 qualification, archive audit or A/B comparison. Before incorporating these new proof obligations into a full milestone, extend the exact proof inventory and requalify the resulting source. A remains historically scoped T01F qualified; B OPEN, C FAIL, D OPEN.
