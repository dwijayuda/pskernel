import WasmLowerExprPrefixReference

theorem wasm_lower_expr_prefix_eq
    (profile : PsWasmTargetProfile)
    (allDeclarations : List PsVerifiedIrDeclaration)
    (structures : List PsVerifiedIrStructure)
    (inductives : List PsVerifiedIrInductive)
    (fuel : Nat) :
    psWasmLowerExprWorker profile allDeclarations structures inductives fuel =
      WasmLowerExprPrefixReference.psWasmLowerExprWorker
        profile allDeclarations structures inductives fuel := by
  induction fuel with
  | zero => rfl
  | succ remaining ih =>
      funext bindings expected state expr
      simp only [psWasmLowerExprWorker,
        WasmLowerExprPrefixReference.psWasmLowerExprWorker, ih] <;> rfl

#print axioms wasm_lower_expr_prefix_eq

def runWasmLowerExprPrefixTests : IO Unit := do
  let profile := PsWasmTargetProfile.mk PsWasmWordSize.wasm32
  let state : PsWasmLowerState :=
    { nextLocalIndex := 17, localTypes := [], currentDefinition := "prefix-check",
      nextLambdaId := 23, generatedStructures := [], generatedFunctionTypes := [],
      generatedFunctions := [], generatedFunctionRefs := [] }
  match psWasmLowerExprWorker profile [] [] [] 1000000 [] (some .i32) state (.literal (.bool true)) with
  | .ok lowered =>
      match lowered.instructions with
      | [.i32Const 1] =>
          if lowered.state.nextLocalIndex != 17 || lowered.state.nextLambdaId != 23 then
            throw (IO.userError "Wasm lower expression changed threaded state")
      | _ => throw (IO.userError "Wasm lower expression changed bool literal")
  | .error _ => throw (IO.userError "Wasm lower expression early result refused")
  match psWasmLowerExprWorker profile [] [] [] 0 [] (some .i32) state (.literal (.bool true)) with
  | .error (.unsupportedExpressionContext "prefix-check" "fuel-exhausted") => pure ()
  | _ => throw (IO.userError "Wasm lower expression fuel-zero refusal changed")
  IO.println "PSC1_WASM_LOWER_EXPR_PREFIX: all-input Lean equality; million-fuel early result; exact zero-fuel error"
