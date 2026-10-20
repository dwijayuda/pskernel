import Ps.KernelCore.Checker.Inference
import Ps.KernelCore.Core.ExprV2.Builder

/-
First DAG-native checking slice. The caller owns a replay-validated arena and
a fresh public-operation context. This function does not accept cached
judgments or reuse memo entries across contexts.

The terminal cases and metadata recursion preserve InferCoreWithFuel's
ordering: fuel guard, EnterRecDepth, then the syntax-directed rule. Public
check operations discard checker caches; a single metadata chain has no
branch that could consume a cache produced earlier in the same operation.
The recursive call remains inside its argument lambda, avoiding construction
of a closure chain proportional to unused fuel before a terminal return.

Option.none requests the complete checker for a composite form. It never
means acceptance. Except.error preserves the existing diagnostic. Constant
types still live in the legacy environment and use its qualified universe
substitution; migrating environment expressions remains a separate step.
-/
def psKernelExprV2TryCheckTerminalWithFuel
    (fuel : Nat) :
    PsKernelCheckerContext -> PsKernelExprV2PagedArena -> Nat ->
    Option (Except String PsKernelExpr) :=
  match fuel with
  | Nat.zero =>
      fun (_context : PsKernelCheckerContext)
          (_arena : PsKernelExprV2PagedArena) (_root : Nat) =>
        Option.some (Except.error "kernel inference budget exhausted")
  | Nat.succ remaining =>
      let smaller :=
        fun (nextContext : PsKernelCheckerContext)
            (nextArena : PsKernelExprV2PagedArena) (nextRoot : Nat) =>
          let recur := psKernelExprV2TryCheckTerminalWithFuel remaining;
          recur nextContext nextArena nextRoot;
      fun (context : PsKernelCheckerContext)
          (arena : PsKernelExprV2PagedArena) (root : Nat) =>
        match psKernelCheckerContextEnterRecDepth context with
        | Except.error error => Option.some (Except.error error)
        | Except.ok nextContext =>
            match psKernelExprV2PagedRequire arena root with
            | Except.error error => Option.some (Except.error error)
            | Except.ok entry =>
                match entry.node with
                | PsKernelExprV2Node.bvar _ =>
                    Option.some
                      (Except.error "loose bound variable in type checker")
                | PsKernelExprV2Node.mvar _ =>
                    Option.some
                      (Except.error "kernel type checker does not support metavariables")
                | PsKernelExprV2Node.fvar name =>
                    match psKernelLocalContextFind nextContext.localContext name with
                    | Option.none =>
                        Option.some (Except.error "unknown free variable")
                    | Option.some declaration =>
                        Option.some (Except.ok (psKernelLocalDeclType declaration))
                | PsKernelExprV2Node.sort level =>
                    Option.some
                      (Except.ok (PsKernelExpr.sort (PsKernelLevel.succ level)))
                | PsKernelExprV2Node.const name levels =>
                    Option.some
                      (psKernelInferConstantType nextContext name levels false)
                | PsKernelExprV2Node.lit literal =>
                    match literal with
                    | PsKernelLiteral.nat value =>
                        match psKernelCheckNatSize nextContext.maxNatSize value with
                        | Except.error error => Option.some (Except.error error)
                        | Except.ok _ =>
                            Option.some
                              (Except.ok (PsKernelExpr.const psKernelNatName List.nil))
                    | PsKernelLiteral.str _ =>
                        Option.some
                          (Except.ok (PsKernelExpr.const psKernelStringName List.nil))
                | PsKernelExprV2Node.mdata _ body =>
                    smaller nextContext arena body
                | _ => Option.none
