# PSC0 / PSCV0 v7 — Closed Cross-Runtime Source-AST ABI

**Checkpoint:** 11 October 2026. **Sole future language reference:** [PSCV0 v7](../PSCV0_LANGUAGE_REFERENCE.md) (SHA-256 `843940bd7f6a9b286e80b01d8c891a7e01b8868a9de7b05833fce32d49be6cd5`). **Implementation branch:** `psc0/pscv0-v7-abi-v1`, branched from `psc0/pscv0-v7-app-model-v1`. Does not implement or claim full PSCV0 v7 conformance, verified executable assurance or a full compiler fixed point.

## Architectural reason

The generated PSCV0 frontend and the retained PSC0 compiler are **separately emitted JavaScript modules**. Their algebraic data type constructors use *private* `Symbol("ProofScript.<Type>.tag")` identities, and even their nominal source-record brands differ. Directly supplying a frontend AST to the retained compiler causes `invalid ProofScript constructor tag`, observed in [run 38125532982](https://github.com/dwijayuda/pskernel/actions/runs/38125532982), after 20-module source generation and eight source-equivalence proofs had passed. The failure is due to crossing module ABI ownership; it does **not** imply a malformed v7 source or a kernel soundness defect.

Avoid all of these non-solutions: global `Symbol.for` tags, forged runtime-tag properties on unchecked objects, silent acceptance of arbitrary duck-typed constructor values, re-parsing compiler input through the old Lean source grammar, rewriting the immutable old compiler to pretend the bundles share symbol identity, or weakening the independent checker. The user explicitly requires **no backward-compatible old `.ps` language mode**.

## Actual closed ABI contract

The [versioned source-AST transport](../tools/abi/transport.mjs) uses schema `psc0-pscv0-source-ast-transport/1`, keyed to the exact v7 reference SHA. Its source type owner is [the PSC0 syntax AST](../packages/syntax/src/Ps/Syntax/Ast.lean); this is an interchange *schema*, not a second language grammar or kernel IR.

- Source union families: `List`, `Option`, `PsSyntaxBinderKind`, `PsSyntaxPattern`, `PsSyntaxTerm`, `PsSyntaxDeclaration`.
- Source records: `PsSourcePos`, `PsSourceSpan`, `PsSyntaxName`, `PsSyntaxBinderHead`, `PsSyntaxInductiveConstructor`, `PsSyntaxImport`, `PsSyntaxModule`, and `Prod`.
- Accept only complete known source constructor/field sets from **that runtime's actual private Symbol identity**. Compare both runtime's emitted constructor sets against the pinned closed schema before any user AST is transferred.
- Check source structure brands and exact own data properties (no getters, unexpected keys, wrong-symbol constructors or prototype-based values). Reconstruct every inductive using the **recipient's own constructors**, preserving nested application grouping, constructor branch, field order, source names and position values. Copy validated structural data as inert records without borrowing its original runtime's private brand.
- Reject user-written `partialDefinition` and unknown AST constructors, oversized source, missing/out-of-bounds source locations, reversed spans, cyclic linked lists, excessive list length, recursion depth and total node budget.
- The host transport receipt contains its schema edition, authoritative v7 source hash, exact selected `.ps` SHA-256, normalized-node count and explicit `trustedByKernel:false` / `elaborationRequired:true`. It is an **audit record, not an admission token**.

The generated PSCV0 source parser/lowerer creates an *untrusted* `PsSyntaxModule`; the closed schema reconstitutes it into the compiler's legitimate constructors. The existing pure `psCompilerPreparationStepParsedWithOrigins` then performs actual elaboration under the selected environment. Source origins still require complete future mapping, but there is no text-as-proof, parser fallback or novel kernel constructor. The usual `psCompilerPreparationFinish`, canonical admission encoding, independent `pskernel-core` check and TypeScript/JS tests remain mandatory. Any failure rejects the changed candidate.

## Completed cloud observations (prior to full bridge integration)

[Cloud ABI probe 38127436381](https://github.com/dwijayuda/pskernel/actions/runs/38127436381) inspected the exact generated 20-module surface artifact and retained npm compiler module. Both export the same *names* for source syntax constructors, but their symbols differ; even source structs carry distinct nominal brands. The emitter itself, [`Ps.BackendTs.Module`](../packages/backend-ts/src/Ps/BackendTs/Module.lean), uses fresh unique `Symbol` values per generated bundle.

[ABI runtime gate 38127922986](https://github.com/dwijayuda/pskernel/actions/runs/38127922986) **passed**: it reconstructed **257** source nodes from a well-typed `(add(1))(2)` fixture, elaborated in the retained compiler without the old Lean text parser, produced canonical admissions **accepted by the independent generated-JS-core kernel**, emitted checked TypeScript, and refused wrong-symbol tags / unexpected fields / cross-runtime `List` substitution.

[Actual selected-source gate 38128089427](https://github.com/dwijayuda/pskernel/actions/runs/38128089427) **passed** the same schema against all **2,440** nodes of the exact `packages/syntax/src-ps/Ps/Syntax/Translate.ps` source (SHA-256 `938288af9c8476d592fc69c4e6f2c01ecb8e1f371fdd5bac1f789a3097710428`). This is an ABI/source-coverage check **only**; its separate runtime probe does not elaborate the imported full `Translate` module in isolation without its prepared syntax prefix.

## Full candidate acceptance (pending)

The changed 20-module bridge must independently use the **generated PSCV0 runtime**, validate/reconstruct `Translate.ps` into recipient-owned AST, and resume the same pure compiler prefix. It must preserve source/admission/TS/JS identity and **all previous 43 bridge tests and 12 authoring/arrow tests**, add the real direct-AST -> checked kernel -> TypeScript 7 -> JavaScript `grouped=3` test, and pass Linux, Windows and the independent Lean 4.35.0-rc4 eight-equation/proof job. Do not substitute cheap ABI probe success for this later qualification.

The preexisting primary branch at `2394fc7e` **already passed** bounded generated Linux/Windows/RC4 [38122341583](https://github.com/dwijayuda/pskernel/actions/runs/38122341583). The new ABI change has a different source identity and cannot inherit that receipt. The current primary branch has concurrent design work; do not force-update or delete any branch.

## Further proof obligations

The current schema is a manually audited implementation contract derived from the precise PSC0 syntax declarations. It is not a mechanically verified schema compiler or an end-to-end proof of source parsing/printing/lowering correctness. Subsequent sound migration requires a formally stated `decode(encode(t))` correspondence theorem for the chosen source-AST representation, generated type/constructor catalogs, preserved source spans/diagnostics, precise RC4 standard environment/instance identities, generalized v7 language support, and separate complete-compiler source/fixed-point qualifications.

**Architectural principle:** Make data crossing trust domains explicit, typed, versioned, fail-closed and auditable. Reuse all existing proof/elaboration/kernel infrastructure. Do not turn test cases into compiler special cases.
