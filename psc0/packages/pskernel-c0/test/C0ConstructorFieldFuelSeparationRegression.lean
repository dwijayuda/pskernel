import Ps.KernelCore.Admission.Inductive.Mutual.Analysis

/-!
Pinned Lean 4.35 inductive.cpp::check_constructors iterates raw constructor
Pi fields while invoking the type checker separately. A decreasing field
traversal budget must not silently replace the requested checker fuel.
Low traversal budgets below are operation-local probes, NOT admission
permissions: the parent constructor declaration is still fully checked.
-/

def main : IO Unit := do
  let source := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [] .safe 4096 psKernelLeanNatMaxSizeDefault
  let name : PsKernelName := .str .anonymous "FieldBudget"
  let target : PsKernelName := .str .anonymous "BudgetTarget"
  let sort0 : PsKernelExpr := .sort .zero
  -- Checking this nested Pi domain requires more recursion budget than the
  -- two syntactic field-walker steps below.
  let domain : PsKernelExpr :=
    .forallE name sort0 (.forallE name sort0 sort0 .default) .default
  let constructorType : PsKernelExpr :=
    .forallE name domain sort0 .default
  let level : PsKernelLevel := .succ .zero

  let ordinary ← match psKernelOpenSimpleConstructorFieldsWithFuel
      2 16 source target [] [] 0 level constructorType [] [] with
    | .ok result => pure result
    | .error e => throw (IO.userError ("ordinary field checker lost independent fuel: " ++ e))
  if ordinary.fields.length != 1 ||
      !psKernelExprEq ordinary.result sort0 then
    throw (IO.userError "ordinary constructor field walk changed raw Pi shape")

  let mutual ← match psKernelOpenSimpleMutualConstructorFieldsWithFuel
      2 16 source [] [] [] [] level constructorType [] [] with
    | .ok result => pure result
    | .error e => throw (IO.userError ("mutual field checker lost independent fuel: " ++ e))
  if mutual.fields.length != 1 ||
      !psKernelExprEq mutual.result sort0 then
    throw (IO.userError "mutual constructor field walk changed raw Pi shape")

  -- The checker's own exhausted budget still fails closed; walker exhaustion
  -- is independent of its higher allowance.
  match psKernelOpenSimpleConstructorFieldsWithFuel
      2 0 source target [] [] 0 level constructorType [] [] with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "ordinary checker zero-fuel accepted a field")
  match psKernelOpenSimpleMutualConstructorFieldsWithFuel
      2 0 source [] [] [] [] level constructorType [] [] with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "mutual checker zero-fuel accepted a field")
  match psKernelOpenSimpleConstructorFieldsWithFuel
      1 16 source target [] [] 0 level constructorType [] [] with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "ordinary field traversal exceeded its budget")
  match psKernelOpenSimpleMutualConstructorFieldsWithFuel
      1 16 source [] [] [] [] level constructorType [] [] with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "mutual field traversal exceeded its budget")

  IO.println "C0_CONSTRUCTOR_FIELD_FUEL ordinary=separate mutual=separate zero_checker=declined exhausted_walk=declined"
