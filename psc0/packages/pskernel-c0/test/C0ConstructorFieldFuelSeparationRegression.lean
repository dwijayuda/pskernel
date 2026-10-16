import Ps.KernelCore.Admission.Inductive.Mutual.Analysis
import Ps.KernelCore.Admission.Inductive.Common.Elimination

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

  let mutualFields ← match psKernelOpenSimpleMutualConstructorFieldsWithFuel
      2 16 source [] [] [] [] level constructorType [] [] with
    | .ok result => pure result
    | .error e => throw (IO.userError ("mutual field checker lost independent fuel: " ++ e))
  if mutualFields.fields.length != 1 ||
      !psKernelExprEq mutualFields.result sort0 then
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

  -- Other finite constructor-spine walkers must preserve the same budget
  -- separation: datatype parameter DefEq, index checking and small-elim tests.
  let param : PsKernelOpenBinder := PsKernelOpenBinder.mk name name sort0 .default
  let parameterType : PsKernelExpr := .forallE name sort0 sort0 .default
  let params ← match psKernelOpenSimpleConstructorParamsWithFuel
      2 16 source [param] parameterType with
    | .ok result => pure result
    | .error e => throw (IO.userError ("constructor parameter DefEq used traversal fuel: " ++ e))
  if !psKernelExprEq params.result sort0 then
    throw (IO.userError "constructor parameters changed the raw result type")
  let indices ← match psKernelOpenSimpleHeaderIndicesWithFuel
      2 16 source constructorType [] with
    | .ok result => pure result
    | .error e => throw (IO.userError ("datatype index checker used traversal fuel: " ++ e))
  if indices.binders.length != 1 then
    throw (IO.userError "datatype index walker omitted an index")
  match psKernelSimpleCtorAllowsLargeElimWithFuel
      2 16 source constructorType [] with
  | .ok _ => pure ()
  | .error e => throw (IO.userError ("large-elimination checker used traversal fuel: " ++ e))

  match psKernelOpenSimpleConstructorParamsWithFuel
      2 0 source [param] parameterType with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "constructor parameter zero checker fuel accepted")
  match psKernelOpenSimpleHeaderIndicesWithFuel
      2 0 source constructorType [] with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "datatype index zero checker fuel accepted")
  match psKernelSimpleCtorAllowsLargeElimWithFuel
      2 0 source constructorType [] with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "large-elimination zero checker fuel accepted")

  match psKernelOpenSimpleConstructorParamsWithFuel
      1 16 source [param] parameterType with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "constructor parameter traversal overran")
  match psKernelOpenSimpleHeaderIndicesWithFuel
      1 16 source constructorType [] with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "datatype index traversal overran")
  match psKernelSimpleCtorAllowsLargeElimWithFuel
      1 16 source constructorType [] with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "large-elimination traversal overran")

  IO.println "C0_CONSTRUCTOR_FIELD_FUEL ordinary=separate mutual=separate params=separate indices=separate elimination=separate zero_checker=declined exhausted_walk=declined"
