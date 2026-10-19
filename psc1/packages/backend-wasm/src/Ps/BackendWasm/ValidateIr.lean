import Ps.BackendWasm.ValidateTyping

-- Keep the public boundary stable. Structural checks precede target typing,
-- and production callers retain/encode the same module only after both pass.
def psWasmIrValidateModule
    (module : PsWasmModule) :
    Except PsWasmIrValidationError Unit :=
  match psWasmIrValidateModuleStructure module with
  | Except.error error => Except.error error
  | Except.ok _ =>
      match psWasmTypingValidateParents module module.structures List.nil with
      | Except.error error => Except.error error
      | Except.ok _ => psWasmTypingValidateFunctions module module.functions
