# PSCV0 source bridge — validation ledger

Keep native source validity, native fixture correspondence, retained-compiler generation, generated-JavaScript conformance and final compiler migration as separate claims. Failed runs stay failed.

## Latest native checkpoint

Portable implementation source: `1ed94be7b1d3c49f11e302464478be76fa299172`.
Native harness/proof source: `be0232c40e77c603da6954c505fc7ace2aa0541f`.
Run [38098707088](https://github.com/dwijayuda/pskernel/actions/runs/38098707088), job `114349935198`: **success**.

All four portable modules type-checked under Lean 4.34.0. The same implementation passed five PS → readable Lean → PS round trips, four malformed-source refusals and exact original-comment replay. The generated readable source uses native `do`, and canonical formatting of unanchored comments explicitly declines.

The harness also generated two complete functions from the actual bridge: a readable native-do version and an explicit match/let lowering of the same two-action program. Lean checked:

```lean
theorem pscv0_native_do_correspondence (a b : Except String Nat) :
    referenceProgram a b = loweredProgram a b := by
  cases a <;> cases b <;> rfl
```

`#print axioms` reported **no axioms**. This proves equality for all arguments of this particular pair of generated functions. It is not a proof of the bridge algorithm for arbitrary programs, of JavaScript preservation, or of RC4 conformance. The native run uses 4.34.0 as the bootstrap implementation environment; the reference's independent RC4 lane is distinct.

Native evidence artifact `11686798545` contains 11 files, 3062 compressed bytes; ZIP SHA-256 `c7aafa3625cf0c04fbadce46fcfa75b9d9a6d4c3591d184e5f9a04610ff87c8b`.

## Retained self-hosted compiler generation

The generation run [38098425773](https://github.com/dwijayuda/pskernel/actions/runs/38098425773), implementation `1ed94be7b1d3c49f11e302464478be76fa299172`, was still in progress at this checkpoint. Native preconditions and the exact retained runtime installation passed. Do not infer generated-bridge, Windows or RC4 success from this native record.

Previous run `38097650380`, source `9265af40cdcee0dbf1cf4b125a9c79d52c5198da`, prepared the three new modules Surface, Read and Commands successfully, then failed in Module's `psPscv0CommentTriviaWorker` with `matchExpectedType`. The local match-valued `gap` needed an explicit `Bool` annotation under the existing bootstrap language. The annotation changes no intended runtime behavior. This is the actual last localized seed issue—not a claim that native type-checking qualifies generated output.

No complete compiler C2/C3 cycle or kernel regeneration occurred. Existing 69 compiler files, the main bootstrap source closure, public CLI, selected seed and kernel source/adapter remain unchanged. New bridge modules are added independently and must earn their own qualification.

## Historical failures and corrected boundaries

| Source / run | Actual outcome | Correction or meaning |
| --- | --- | --- |
| `7b0b3803062d` / `38094720290` | Workflow invalid before execution | Set runner-local prefix at step execution |
| `7092ba81c304` / `38095004877` | C0 rejected expression `::` | Normalize new expression constructor family to List.cons, retain admitted patterns |
| `a5932fb84e74` / `38095258615` | Native prerequisite Foundation.List missing | Build actual PsFoundation prerequisite |
| `1f62effe6e86` / `38095425532` | Reserved native local identifiers syntax/prefix | Rename sourceModule/importPrefix |
| `6eb1cb5f6e42` / `38095954154` | C0 raw parse passed; unqualified Option value rejected | Qualify Option constructor expressions throughout new modules |
| `7f41b6367f40` / `38096114909` | PS result type before := confused with assignment | Give declaration result-type tokens their own delimiter ownership before shared expression parsing |
| `960692ed256f` / `38097055403` | C0 structuralRecursionArity in Surface | Use seed-compatible function-valued recursive result for the term-validation helper, preserving its full Pi type |
| `9265af40cdce` / `38097650380` | First three new modules prepared; Module local match lacked expected type | Explicit Bool annotation; no test or old-source changes |
| `01faf55c15d1` / `38098565850` | Native symbolic rfl did not close generated equality | Same universally quantified statement proved by exhaustive Except cases; generated functions unchanged |

Earlier native success `38097055425` at `960692ed256f` covered type checking, five round trips, four refusals and comment replay, not the later theorem or generated-JS behavior. Its artifact `11685979857` SHA-256 was `6822d5d919d0a2024901474d209fff52f63adef54bca68ab5cfb8f563b0edd5e`.

Native run `38097650367` also passed its then-current source checks at `9265af40cdce`; a native result is never substituted for the retained compiler's failed generation.

## Qualification discipline

The expensive prefix has only the syntax/foundation dependencies, not the complete compiler or kernel. All new raw source is preflighted before preparing that prefix, and origin-bearing preparation identifies the exact failing declaration. Native source/round-trip checks run first so known native failures do not consume another prefix build.

The generated bridge test corpus must still run against a genuinely emitted bridge. Existing tests are not changed to use native code. Its RC4 fixture theorem should use the same constructor-case proof of the unchanged equality, rather than require symbolic definitional equality that the native experiment disproved. Fixing that proof script must not be presented as changing the acceptance statement or proving the entire compiler.
