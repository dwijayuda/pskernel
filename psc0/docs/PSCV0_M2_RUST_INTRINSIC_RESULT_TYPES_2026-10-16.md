# M2+A — retain checked intrinsic result types in Rust emission

## Observed boundary

Native38827509921 at fe702130e6a1e12c529b4fd592db954f096b8493 passed compiler/parser/assets, all source/Standard/solver/source-info/module checks, GC Wasm/core/components and JS/TS qualification. All35 platform probes passed for each32/64 profile under V8, Wasmtime, JS, TS and Rust. The1069 shared application observations passed both TypeScript and direct JavaScript. The subsequent Rust shared application failed to compile with E0282 at application.rs:15589: `__ps_array_empty_with_capacity(&(__ps_arg_65531_0))` lacked an inferable element type. Native repeated Wasmtime and performance steps were skipped.

Exact evidence was read from the original completed job116738299607 using compact read-only diagnostic38828783509/job116742409590 (afc619b81406647b55c58e8ea30973680f0658df). Artifact12016012693 has digest sha256:159ccb002c743b1c25d8fa3add7eaa3d046b950aa85b739b0a0bb47a1f980181. Its actual Standard manifest reports3599 declarations,39 classes,355 ordinary instances and13 defaults; both approved assumptions and all three pins remain unchanged.

## Source study and root cause

Pinned Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc:

- `src/Lean/Compiler/IR/Basic.lean`, `FnBody.vdecl`: runtime bindings retain their `IRType`.
- `src/Lean/Compiler/IR/EmitLLVM.lean`, `declareVars`, `declareVar`, `emitVDecl`: declared runtime types reach target allocation and typed emission. This is an architectural reference only; no LLVM dependency is added to PSC0.
- Rust's official E0282 explanation uses `Vec::new()` as the canonical return-only type-parameter ambiguity and permits a typed local binding as its resolution: https://doc.rust-lang.org/error_codes/E0282.html . The `let` statement's type annotation supplies this constraint: https://doc.rust-lang.org/reference/statements.html#let-statements . Inspected16 October2026; compilation remains pinned to Rust1.98.1.

PSC0 already has the validated result type in `PsVerifiedIrExpr.intrinsic`. `Ps.BackendRust.Expr.psRustExpr` matched it as `_`, then emitted untyped operand temporaries and a raw runtime-helper expression. A consumer such as collection size can erase all information needed to infer the empty collection's element type. This is lost target typing information, not a Lean logical/model or platform-width defect. Ordinary source let/lambda/constructor/call emission already retains explicit runtime types or generic arguments.

## Coherent correction

Retain the result type at the shared intrinsic expression boundary. After exactly the same ordered, once-only operand evaluation and borrowed/owned operand decisions, emit a block-local `let __ps_result_<fuel>: <checked Rust type> = <existing intrinsic expression>;` and return that binding by move. The existing `psRustEmitType` renderer is reused, including its fail-closed unknown/named-arity checks. No host type inference, cast, unchecked representation or source-name special case is introduced.

This covers every intrinsic result rather than adding an Array.filter or empty-array fixture exception. The body/helper selection, argument ordering, liveness/capture/clone analysis, runtime representations, IR validation, public ABI and logical environment are unchanged. The temporary is block-local, evaluated once and returned without a new clone. This does not introduce a new compiler pass or module.

## Validation and scope

Reuse the existing failing shared application plus both platform profiles and the full current qualification pipeline; no extra test corpus, assertion rewrite, budget or source fixture change. The new native run must compile and execute all1069 Rust observations, then complete repeated native Wasmtime and performance gates. Earlier JS/TS/GC success is prior evidence, not a replacement for the new exact-commit run. M2+A remains OPEN pending full research qualification, exit reconciliation and history-preserving exact-integration qualification.
