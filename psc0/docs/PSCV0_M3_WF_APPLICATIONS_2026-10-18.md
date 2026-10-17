# Shared ordinary application ownership for WF calls

Candidate; qualification pending. Lean 4.35.0, eb6cafb7290e8bd5f2937522d8d804f58f02bafc.

## Reference and design

Pinned [Elab/App](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/App.lean) owns explicit/implicit/instance/named/default argument elaboration and expected-result propagation. [WF/PackMutual](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/PreDefinition/WF/PackMutual.lean) consumes fully elaborated applications when packing recursive arguments. Pinned tests/elab/optParam.lean and tests/elab_fail/invalidNamedArgs.lean supply application semantics controls; ArgsPacker.Unary and wfrecUnary.lean remain the packing reference.

The old WF call consumer elaborated a list of explicit syntax arguments itself, requiring written arity to equal the source telescope. This duplicated application semantics and prevented implicit types, instance dictionaries, named arguments and defaults. The replacement shares the ordinary ordered application engine, with an optional bounded argument capture. Ordinary applications and record consumers keep the same default path.

A capture knows the number of owned source binders. Every selected argument, whether written or synthesized, is retained in one typed local let; the normal synthetic constraint queue and expected-result propagation remain responsible for solving its contents. Names and domains come from the original declared Pi telescope. An omitted optParam default is instantiated after preceding arguments, never looked up in caller scope or replaced with an Inhabited fallback. The engine retains its established binder/elaboration order; this is not a new effect evaluation-order specification.

The recursive consumer supplies a genuine anonymous local with the original source type. This temporary head is neither a global declaration nor an axiom. After application completion, the consumer solves pending constraints, checks that the head escaped into no retained argument/type/let, removes it, and constructs the real typed callback call. Arguments are retained before measured/state permutation; no expression-based deduplication or duplicate runtime evaluation is used.

Completion stops at the source header rather than consuming a function-valued result. The existing chained result application path remains separate. Missing required source binders and escaping recursive function values still refuse in this selected slice. Pinned Lean can eta-expand recursive values in a broader setting; that capability is not claimed here.

Public declarations retain their original binder kinds. Internal unary/packed major and decrease-proof binders are explicit; dependent residual state retains its source telescope. Erasure validates the full original entry and the full callback type before replacing it with an ordinary executable call. No callback is assigned a forged source type.

## Coherent qualification

The existing WF fixture adds native/portable generic type and dictionary inference, reordered named recursion, a default depending on a preceding argument, and an implicit decreasing parameter with dependent Fin state. A public unfolding equation is checked. One combined observer adds ten required comparisons across direct JS, strict TypeScript, Rust, V8 GC and Wasmtime; retained incomplete-header, escaping-self, decrease/proof/entry controls remain. Unknown and duplicate named calls are rejected by the shared argument owner. The native cases use Lean's independent elaborator, not portable generated terms.

No Standard, assumption, admission budget, runtime ABI, assurance criterion, or self-hosting boundary changes. M3+B still requires compatible mutual WF and the final exact-SHA exit matrix.
