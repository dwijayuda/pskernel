import Ps.KernelCore.Core.Expr
import Ps.KernelCore.Core.ExprV2.TransformSpine

/-
Type-annotation consumption inside one already canonical owning arena.
Only the exact V1 application names and arities are consumed. In particular,
metadata wrappers and oversaturated applications remain unchanged. The bound
is structural and is unrelated to the checker's reduction fuel. No node or
semantic checker state is allocated or changed by this operation.
-/
def psKernelExprV2OrdinaryConsumeTypeAnnotationsWithFuel
    (fuel : Nat) :
    PsKernelExprV2PagedArena -> Nat -> Except String Nat :=
  match fuel with
  | Nat.zero =>
      fun (_arena : PsKernelExprV2PagedArena) (root : Nat) =>
        Except.ok root
  | Nat.succ remaining =>
      fun (arena : PsKernelExprV2PagedArena) (root : Nat) =>
        match psKernelExprV2TransformAppSpineOnCanonical arena root with
        | Except.error error => Except.error error
        | Except.ok spine =>
            match psKernelExprV2PagedRequire arena (Prod.fst spine) with
            | Except.error error => Except.error error
            | Except.ok entry =>
                let recur := psKernelExprV2OrdinaryConsumeTypeAnnotationsWithFuel remaining;
                match entry.node with
                | PsKernelExprV2Node.const name _ =>
                    match Prod.snd spine with
                    | List.cons first rest =>
                        match rest with
                        | List.nil =>
                            if
                                if psKernelNameEq name psKernelTypeAnnotationOutParamName then
                                  true
                                else
                                  psKernelNameEq name psKernelTypeAnnotationSemiOutParamName then
                              recur arena first
                            else
                              Except.ok root
                        | List.cons _ secondRest =>
                            match secondRest with
                            | List.nil =>
                                if
                                    if psKernelNameEq name psKernelTypeAnnotationOptParamName then
                                      true
                                    else
                                      psKernelNameEq name psKernelTypeAnnotationAutoParamName then
                                  recur arena first
                                else
                                  Except.ok root
                            | List.cons _ _ => Except.ok root
                    | List.nil => Except.ok root
                | _ => Except.ok root

/- Internal entry. The caller has replay-validated the arena, so entry.depth
   bounds every chain of consumed first arguments and every application spine. -/
def psKernelExprV2OrdinaryConsumeTypeAnnotationsOnCanonical
    (arena : PsKernelExprV2PagedArena) (root : Nat) : Except String Nat :=
  match psKernelExprV2PagedRequire arena root with
  | Except.error error => Except.error error
  | Except.ok entry =>
      psKernelExprV2OrdinaryConsumeTypeAnnotationsWithFuel
        (Nat.succ entry.depth) arena root
