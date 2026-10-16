# M2+A — retain instantiated intrinsic result types in Rust emission

## Reproducer and evidence

Native run38827509921/job116738299607 at fe702130e6a1e12c529b4fd592db954f096b8493 passed compiler/parser/assets/source/Standard/modules, GC/core/components and JS/TS. Both32/64 platform suites passed35 probes each on V8, Wasmtime, JS, TS and Rust. Both JS and TS passed1069 shared application observations. The Rust shared application then failed E0282 at application.rs:15589: `__ps_array_empty_with_capacity(&(__ps_arg_65531_0))` has no inferable element type. Native repeated Wasmtime and performance were skipped.

Read-only cloud diagnostic38828783509/job116742409590 extracted the original logs and artifact12016012693, digest sha256:159ccb002c743b1c25d8fa3add7eaa3d046b950aa85b739b0a0bb47a1f980181. The manifest measured3599 declarations,39 classes,355 ordinary instances and13 defaults. No declaration or surface pin changed.

## Source study and API correction

Pinned Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc: `src/Lean/Compiler/IR/Basic.lean` FnBody.vdecl retains IRType; `src/Lean/Compiler/IR/EmitLLVM.lean` declareVar/declareVars/emitVDecl preserve typed bindings in target emission. This is an architectural reference, not a new LLVM dependency. Rust's official E0282 reference uses Vec::new as the example of return-only generic ambiguity; a typed local binding resolves it. References: https://doc.rust-lang.org/error_codes/E0282.html and https://doc.rust-lang.org/reference/statements.html#let-statements . Rust remains pinned1.98.1.

The first attempt dc4a3c01c9b5972df65e1f6481d7a6c50a030dfe FAILED Lean compilation in native38829386400 and candidate38829386386. It misread `PsVerifiedIrExpr.intrinsic`'s second field as a result type. `Ps.CompilerIr.Model` actually stores `List PsVerifiedIrType` type arguments. The exact compile diagnostic at Expr.lean:93:48 rejected that list where one type was expected. No runtime or logical gate passed that attempt; earlier wording claiming a directly stored result type was incorrect.

The existing authoritative `Ps.CompilerIr.CheckTypes.psIrCheckIntrinsicSignature(operation,typeArguments)` already produces the fully instantiated parameter/result signature and refuses wrong type arities. Its empty-array signature is `[Nat] -> Array element`. Its map/filter/fold/build and scalar branches cover the complete IR enum. Reuse this owner rather than inventing another signature table or treating a type-argument list as a result.

## Correct implementation

`Ps.BackendRust.Expr` now imports the existing CheckTypes module, passes the intrinsic's actual type arguments to that signature function, preserves its diagnostic on error, and renders `signature.resultType` through the existing Rust type renderer. After unchanged ordered, once-only argument evaluation and borrowing/ownership choices, the existing primitive expression is assigned to a block-local explicitly typed result and returned by move.

No new IR fields, inference engine, signature registry, cast, runtime helper, representation, logical assumption or source-name special case is added. Intrinsic operands, liveness/capture/clone decisions, and public ABI are unchanged. The shared signature remains the source of truth. This handles the entire intrinsic family, including return-only generic collection types, without a fixture-specific exception.

## Acceptance

Reuse the existing failing application and both platform profiles; no new test corpus, rewritten runtime assertion, budget increase or qualification-gate change. Fresh native qualification must compile and run all1069 Rust observations and complete native Wasmtime/performance. M2+A remains OPEN pending full research, exit reconciliation and history-preserving exact-integration qualification. Prior green gates are historical evidence, not a substitute for the new exact commit.
