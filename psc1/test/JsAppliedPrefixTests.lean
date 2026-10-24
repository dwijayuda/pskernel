import JsAppliedPrefixReference

theorem js_applied_prefix_psVerifiedIrIntDecimalMagnitudeWithFuel_eq : @psVerifiedIrIntDecimalMagnitudeWithFuel = @JsAppliedPrefixReference.psVerifiedIrIntDecimalMagnitudeWithFuel := by
  funext remainingFuel
  induction remainingFuel with
  | zero => rfl
  | succ remaining ih =>
      simp only [psVerifiedIrIntDecimalMagnitudeWithFuel, JsAppliedPrefixReference.psVerifiedIrIntDecimalMagnitudeWithFuel, ih] <;> rfl

#print axioms js_applied_prefix_psVerifiedIrIntDecimalMagnitudeWithFuel_eq

theorem js_applied_prefix_psJsTypeSupportedWithPolicyAndFuel_eq : @psJsTypeSupportedWithPolicyAndFuel = @JsAppliedPrefixReference.psJsTypeSupportedWithPolicyAndFuel := by
  funext profile uniform fuel
  induction fuel with
  | zero => rfl
  | succ remaining ih =>
      simp only [psJsTypeSupportedWithPolicyAndFuel, JsAppliedPrefixReference.psJsTypeSupportedWithPolicyAndFuel, ih, js_applied_prefix_psVerifiedIrIntDecimalMagnitudeWithFuel_eq] <;> rfl

#print axioms js_applied_prefix_psJsTypeSupportedWithPolicyAndFuel_eq

theorem js_applied_prefix_psJsLowerExprWithPolicyAndFuel_eq : @psJsLowerExprWithPolicyAndFuel = @JsAppliedPrefixReference.psJsLowerExprWithPolicyAndFuel := by
  funext profile uniform fuel
  induction fuel with
  | zero => rfl
  | succ remaining ih =>
      simp only [psJsLowerExprWithPolicyAndFuel, JsAppliedPrefixReference.psJsLowerExprWithPolicyAndFuel, ih, js_applied_prefix_psVerifiedIrIntDecimalMagnitudeWithFuel_eq, js_applied_prefix_psJsTypeSupportedWithPolicyAndFuel_eq] <;> rfl

#print axioms js_applied_prefix_psJsLowerExprWithPolicyAndFuel_eq

theorem js_applied_prefix_psJsValidationAppendNames_eq : @psJsValidationAppendNames = @JsAppliedPrefixReference.psJsValidationAppendNames := by
  funext left
  induction left with
  | nil => rfl
  | cons head tail ih =>
      simp only [psJsValidationAppendNames, JsAppliedPrefixReference.psJsValidationAppendNames, ih, js_applied_prefix_psVerifiedIrIntDecimalMagnitudeWithFuel_eq, js_applied_prefix_psJsTypeSupportedWithPolicyAndFuel_eq, js_applied_prefix_psJsLowerExprWithPolicyAndFuel_eq] <;> rfl

#print axioms js_applied_prefix_psJsValidationAppendNames_eq

theorem js_applied_prefix_psJsValidationAddBindings_eq : @psJsValidationAddBindings = @JsAppliedPrefixReference.psJsValidationAddBindings := by
  funext bindings
  induction bindings with
  | nil => rfl
  | cons head tail ih =>
      simp only [psJsValidationAddBindings, JsAppliedPrefixReference.psJsValidationAddBindings, ih, js_applied_prefix_psVerifiedIrIntDecimalMagnitudeWithFuel_eq, js_applied_prefix_psJsTypeSupportedWithPolicyAndFuel_eq, js_applied_prefix_psJsLowerExprWithPolicyAndFuel_eq, js_applied_prefix_psJsValidationAppendNames_eq] <;> rfl

#print axioms js_applied_prefix_psJsValidationAddBindings_eq

theorem js_applied_prefix_psJsValidateExprWithFuel_eq : @psJsValidateExprWithFuel = @JsAppliedPrefixReference.psJsValidateExprWithFuel := by
  funext globals fuel
  induction fuel with
  | zero => rfl
  | succ remaining ih =>
      simp only [psJsValidateExprWithFuel, JsAppliedPrefixReference.psJsValidateExprWithFuel, ih, js_applied_prefix_psVerifiedIrIntDecimalMagnitudeWithFuel_eq, js_applied_prefix_psJsTypeSupportedWithPolicyAndFuel_eq, js_applied_prefix_psJsLowerExprWithPolicyAndFuel_eq, js_applied_prefix_psJsValidationAppendNames_eq, js_applied_prefix_psJsValidationAddBindings_eq] <;> rfl

#print axioms js_applied_prefix_psJsValidateExprWithFuel_eq

theorem js_applied_prefix_psJsTailDrop_eq : @psJsTailDrop = @JsAppliedPrefixReference.psJsTailDrop := by
  funext count
  induction count with
  | zero => rfl
  | succ remaining ih =>
      simp only [psJsTailDrop, JsAppliedPrefixReference.psJsTailDrop, ih, js_applied_prefix_psVerifiedIrIntDecimalMagnitudeWithFuel_eq, js_applied_prefix_psJsTypeSupportedWithPolicyAndFuel_eq, js_applied_prefix_psJsLowerExprWithPolicyAndFuel_eq, js_applied_prefix_psJsValidationAppendNames_eq, js_applied_prefix_psJsValidationAddBindings_eq, js_applied_prefix_psJsValidateExprWithFuel_eq] <;> rfl

#print axioms js_applied_prefix_psJsTailDrop_eq

theorem js_applied_prefix_psJsTailEtaSuffix_eq : @psJsTailEtaSuffix = @JsAppliedPrefixReference.psJsTailEtaSuffix := by
  funext parameters
  induction parameters with
  | nil => rfl
  | cons head tail ih =>
      simp only [psJsTailEtaSuffix, JsAppliedPrefixReference.psJsTailEtaSuffix, ih, js_applied_prefix_psVerifiedIrIntDecimalMagnitudeWithFuel_eq, js_applied_prefix_psJsTypeSupportedWithPolicyAndFuel_eq, js_applied_prefix_psJsLowerExprWithPolicyAndFuel_eq, js_applied_prefix_psJsValidationAppendNames_eq, js_applied_prefix_psJsValidationAddBindings_eq, js_applied_prefix_psJsValidateExprWithFuel_eq, js_applied_prefix_psJsTailDrop_eq] <;> rfl

#print axioms js_applied_prefix_psJsTailEtaSuffix_eq

theorem js_applied_prefix_psJsTailCaptureBindings_eq : @psJsTailCaptureBindings = @JsAppliedPrefixReference.psJsTailCaptureBindings := by
  funext available scope names
  induction names with
  | nil => rfl
  | cons head tail ih =>
      simp only [psJsTailCaptureBindings, JsAppliedPrefixReference.psJsTailCaptureBindings, ih, js_applied_prefix_psVerifiedIrIntDecimalMagnitudeWithFuel_eq, js_applied_prefix_psJsTypeSupportedWithPolicyAndFuel_eq, js_applied_prefix_psJsLowerExprWithPolicyAndFuel_eq, js_applied_prefix_psJsValidationAppendNames_eq, js_applied_prefix_psJsValidationAddBindings_eq, js_applied_prefix_psJsValidateExprWithFuel_eq, js_applied_prefix_psJsTailDrop_eq, js_applied_prefix_psJsTailEtaSuffix_eq] <;> rfl

#print axioms js_applied_prefix_psJsTailCaptureBindings_eq

theorem js_applied_prefix_psJsTailRewriteWithFuel_eq : @psJsTailRewriteWithFuel = @JsAppliedPrefixReference.psJsTailRewriteWithFuel := by
  funext declaration uses available fuel
  induction fuel with
  | zero => rfl
  | succ remaining ih =>
      simp only [psJsTailRewriteWithFuel, JsAppliedPrefixReference.psJsTailRewriteWithFuel, ih, js_applied_prefix_psVerifiedIrIntDecimalMagnitudeWithFuel_eq, js_applied_prefix_psJsTypeSupportedWithPolicyAndFuel_eq, js_applied_prefix_psJsLowerExprWithPolicyAndFuel_eq, js_applied_prefix_psJsValidationAppendNames_eq, js_applied_prefix_psJsValidationAddBindings_eq, js_applied_prefix_psJsValidateExprWithFuel_eq, js_applied_prefix_psJsTailDrop_eq, js_applied_prefix_psJsTailEtaSuffix_eq, js_applied_prefix_psJsTailCaptureBindings_eq] <;> rfl

#print axioms js_applied_prefix_psJsTailRewriteWithFuel_eq

theorem js_applied_prefix_psJsPrintDeclarationsObservedWith_eq : @psJsPrintDeclarationsObservedWith = @JsAppliedPrefixReference.psJsPrintDeclarationsObservedWith := by
  funext print declarations
  induction declarations with
  | nil => rfl
  | cons head tail ih =>
      simp only [psJsPrintDeclarationsObservedWith, JsAppliedPrefixReference.psJsPrintDeclarationsObservedWith, ih, js_applied_prefix_psVerifiedIrIntDecimalMagnitudeWithFuel_eq, js_applied_prefix_psJsTypeSupportedWithPolicyAndFuel_eq, js_applied_prefix_psJsLowerExprWithPolicyAndFuel_eq, js_applied_prefix_psJsValidationAppendNames_eq, js_applied_prefix_psJsValidationAddBindings_eq, js_applied_prefix_psJsValidateExprWithFuel_eq, js_applied_prefix_psJsTailDrop_eq, js_applied_prefix_psJsTailEtaSuffix_eq, js_applied_prefix_psJsTailCaptureBindings_eq, js_applied_prefix_psJsTailRewriteWithFuel_eq] <;> rfl

#print axioms js_applied_prefix_psJsPrintDeclarationsObservedWith_eq

def runJsAppliedPrefixTests : IO Unit := do
  if psVerifiedIrIntDecimalMagnitudeWithFuel 1000000 "" 0 19 != 19 then
    throw (IO.userError "JS decimal early result changed")
  if !psJsTypeSupportedWithPolicyAndFuel .none false 1000000 (.primitive .nat) then
    throw (IO.userError "JS primitive type early result changed")
  match psJsLowerExprWithPolicyAndFuel .none false 1000000 (.literal (.bool true)) with
  | .ok (.literal (.bool true)) => pure ()
  | _ => throw (IO.userError "JS lower literal early result changed")
  match psJsValidateExprWithFuel [] 1000000 [] (.literal (.natural 0)) with
  | .ok () => pure ()
  | _ => throw (IO.userError "JS validate literal early result changed")
  match psJsValidateExprWithFuel [] 0 [] (.literal (.natural 0)) with
  | .error .fuelExhausted => pure ()
  | _ => throw (IO.userError "JS validation zero-fuel refusal changed")
  if !(psJsTailDrop 1000000 []).isEmpty then
    throw (IO.userError "JS tail drop empty early result changed")
  if psJsTailEtaSuffix ["x"] [.var "wrong"] then
    throw (IO.userError "JS eta mismatch refusal changed")
  let bindings : List PsJsIrMatchBinding := [.mk "field" "first", .mk "field" "last"]
  if psJsValidationAddBindings bindings ["tail"] != ["last","first","tail"] then
    throw (IO.userError "JS validation binding order changed")
  let captures := psJsTailCaptureBindings (fun _ => true) 3 ["a","b"] 0
  match captures with
  | .some [("a","__ps$tail$capture$3$0"),("b","__ps$tail$capture$3$1")] => pure ()
  | _ => throw (IO.userError "JS tail capture names/order changed")
  IO.println "PSC1_JS_APPLIED_PREFIXES: eleven all-input function equalities; million-fuel early results and exact refusal/order/capture cases"
