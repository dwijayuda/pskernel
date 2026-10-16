# v7.2 partial source strategy — bounded M3 slice

16 October 2026. Stage-entry instruction was reapplied against active v7.2 blob694115223777599ba28ee175e14bb642b7b6aa4b, existing adoption521a4a66, qualified runtime133af061 and current source owners. **This slice implements source-strategy parsing/retention, not full partial P0 runtime admission or full M3+B.** Qualification is pending until this exact compiler's CI passes.

## Pinned source study

Official Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc:

- `src/Lean/Parser/Command.lean`, declModifiers and declValSimple: modifiers belong to a declaration; its body owns a termination suffix followed by optional where declarations. Native Lean's modifier grammar is broader than PSCV0's selected v7.2 matrix.
- `src/Lean/Elab/PreDefinition/Main.lean`, addAndCompilePartial: constructs an opaque logical definition using mkInhabitantFor, then separately compiles partial recursion. Its recovery/sorry route is not adopted. checkTerminationByHints rejects conflicting total/fixpoint strategies and incompatible mutual groups.
- `tests/elab/1337.lean`: partial function-like definition with a typed loop, studied as upstream source evidence, not counted as an executed PSC0 test or a new admitted loop feature.

The implementation therefore never drops a partial modifier to reuse an ordinary total definition. Inhabited-result checking, opaque logical body construction and executable identity remain a future coherent semantic slice. Fixedpoint monotonicity, equations, transitive assumptions and target adequacy remain separate; no new axiom or unsafe proof authority is introduced here.

## Implemented source behavior

`Syntax/Pscv0/Commands.lean` adds one shared special-modifier reader. It validates the v7.2 function-like head and rejects duplicate/mixed special modifiers. `partial def` and `partial function`, including nullary function sugar, retain the existing partialDefinition AST constructor and a source span starting at the modifier. `ProgramRead.lean` keeps private ownership around that same declaration. Total/fixedpoint suffixes after a partial-modified body reject with the recursion-strategy rule. A partial_fixpoint prefix rejects because the construct is a post-body suffix.

`Module.lean` no longer applies a historical blanket partial parse ban after the owned parser. It validates all body/type/binder terms and retains the strategy through lowering. Its separate bounded flat translation API does not route partial do through the older Except-only adapter; that translation case remains explicitly unavailable. This is not a v7 compatibility mode or native frontend fallback.

Selected unsafe/noncomputable semantic admission, partial where declarations and ordinary partial runtime execution remain unavailable. Invalid modifier/head combinations are distinguished from unavailable semantic features. The existing central elaborator refuses partialDefinition before producing Core admissions, so no executable artifact can result from the newly parsed partial body. The staged error remains the elaboration-phase unsupported-source diagnostic; a more feature-specific semantic error belongs with the future partial implementation.

## Focused qualification

The existing native measurement executable adds a compact pre-measurement source suite: valid def/function/nullary/private AST ownership and span, invalid const/theorem heads, duplicate/mixed modifiers, conflicting partial/total/fixedpoint suffix and invalid fixedpoint prefix. Flat syntax lowering is checked for retaining partialDefinition rather than changing it to definition. One additional request after all existing measured requests must fail at **elaborate**, with no executable result despite requested JS/TS/Rust targets. Measurements/iterations/checksums and existing runtime source are unchanged.

The old parser corpus case that called valid partial def 'retired grammar' is replaced by the v7.2-required invalid partial const head. Its formerly valid-source rejection is now covered by a positive source test and an explicit staged elaboration refusal. Other corpus cases remain unchanged. This is migration to the selected normative rule, not accepting an arbitrary failure or weakening the trust gate.

These tests do NOT establish P-TERM-02-A ordinary runtime success, inhabited Empty refusal, body type correctness, logical-opacity proof behavior, verified refinement, unsafe capabilities or fixedpoint construction. N-TERM-02-EMPTY/PROOF/TOTAL and full P0/P1 remain pending; a generic unimplemented-feature rejection is not claimed as their semantic qualification.

## Next semantic work

Implement the shared partial declaration's typed recursive body and inhabited-result admissibility, preserve its safe opaque logical identity separately from executable implementation/dependency identity, and add explicit ordinary-versus-verified requests/receipts before executable admission. Use the pinned Lean separation, not an unchecked axiom or an ordinary total-definition alias. Then qualify source, kernel, erasure and each selected target while keeping verified model/refinement obligations fail-closed. Continue broader M3 data/recursion/deriving and measured remaining closure bottlenecks without restarting accepted M2 or runtime work.
