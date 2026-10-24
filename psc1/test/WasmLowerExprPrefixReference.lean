import Ps.BackendWasm.Lower

namespace WasmLowerExprPrefixReference

def psWasmLowerExprWorker
    (profile : PsWasmTargetProfile)
    (allDeclarations : List PsVerifiedIrDeclaration)
    (structures : List PsVerifiedIrStructure)
    (inductives : List PsVerifiedIrInductive)
    (remainingFuel : Nat) :
    List PsWasmBinding ->
    Option PsWasmValueType ->
    PsWasmLowerState ->
    PsVerifiedIrExpr ->
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match remainingFuel with
  | 0 =>
      fun (_bindings : List PsWasmBinding) =>
        fun (_expected : Option PsWasmValueType) =>
          fun (state : PsWasmLowerState) =>
            fun (_expr : PsVerifiedIrExpr) =>
              Except.error
                (PsWasmLowerError.unsupportedExpressionContext
                  state.currentDefinition
                  "fuel-exhausted")
  | fuel + 1 =>
      let smaller :
          List PsWasmBinding ->
          Option PsWasmValueType ->
          PsWasmLowerState ->
          PsVerifiedIrExpr ->
          Except PsWasmLowerError PsWasmLoweredExpr :=
        psWasmLowerExprWorker
          profile
          allDeclarations
          structures
          inductives
          fuel;
      fun (bindings : List PsWasmBinding) =>
        fun (expected : Option PsWasmValueType) =>
          fun (state : PsWasmLowerState) =>
            fun (expr : PsVerifiedIrExpr) =>
              let lowerWithBindings :
                  List PsWasmBinding ->
                  Option PsWasmValueType ->
                  PsWasmLowerState ->
                  PsVerifiedIrExpr ->
                  Except PsWasmLowerError PsWasmLoweredExpr :=
                fun
                (nextBindings : List PsWasmBinding)
                (expectedType : Option PsWasmValueType)
                (nestedState : PsWasmLowerState)
                (nestedExpr : PsVerifiedIrExpr) =>
                  smaller
                    nextBindings
                    expectedType
                    nestedState
                    nestedExpr;
              let lower :
                  Option PsWasmValueType ->
                  PsWasmLowerState ->
                  PsVerifiedIrExpr ->
                  Except PsWasmLowerError PsWasmLoweredExpr :=
                lowerWithBindings bindings;
              match expr with
              | .literal literal =>
                  match literal with
                  | .natural value =>
                      Except.ok {
                        instructions := psWasmNatLiteralInstructions value
                        state := state
                      }
                  | .integer value =>
                      Except.ok {
                        instructions := psWasmIntLiteralInstructions value
                        state := state
                      }
                  | .machineInteger type value =>
                      Except.ok {
                        instructions :=
                          psWasmLowerMachineIntegerLiteral profile type value
                        state := state
                      }
                  | .string value =>
                      Except.ok {
                        instructions :=
                          psWasmStringLiteralInstructions value
                        state := state
                      }
                  | .bool value =>
                      let encodedValue : Int :=
                        if value then 1 else 0;
                      Except.ok {
                        instructions :=
                          [PsWasmInstruction.i32Const encodedValue]
                        state := state
                      }
                  | .unit =>
                      match expected with
                      | Option.none =>
                          Except.ok {
                            instructions := [PsWasmInstruction.i32Const 0]
                            state := state
                          }
                      | Option.some valueType =>
                          match valueType with
                          | PsWasmValueType.i32 =>
                              Except.ok {
                                instructions :=
                                  [PsWasmInstruction.i32Const 0]
                                state := state
                              }
                          | _ =>
                              Except.error
                                PsWasmLowerError.unsupportedType
              | .var name =>
                  match psWasmFindBindingIndex bindings name with
                  | Option.none =>
                      match psStrictFindDeclaration allDeclarations name with
                      | Option.none =>
                          Except.error (PsWasmLowerError.unknownVariable name)
                      | Option.some declaration =>
                          match declaration.parameters with
                          | List.nil =>
                              Except.ok {
                                instructions := psWasmCallValueInstructions declaration.resultType (PsWasmInstruction.call name)
                                state := state
                              }
                          | List.cons _ _ =>
                              let parameters : List PsVerifiedIrParameter :=
                                psWasmGlobalFunctionParameters
                                  name declaration.parameters 0;
                              let body : PsVerifiedIrExpr :=
                                PsVerifiedIrExpr.call (PsVerifiedIrExpr.var name)
                                  List.nil (psWasmGlobalFunctionArguments parameters);
                              psWasmLowerLambdaWith
                                profile bindings lowerWithBindings state
                                parameters declaration.resultType body
                  | Option.some index =>
                      Except.ok {
                        instructions := [PsWasmInstruction.localGet index]
                        state := state
                      }
              | .lambda parameters resultType body =>
                  psWasmLowerLambdaWith
                    profile
                    bindings
                    lowerWithBindings
                    state
                    parameters
                    resultType
                    body
              | .intrinsic operation typeArguments arguments =>
                  psWasmLowerIntrinsicWith
                    profile lower state operation typeArguments arguments
              | .call fn _ arguments =>
                  psWasmLowerCallWith
                    profile
                    (PsVerifiedIrModule.mk List.nil structures inductives allDeclarations)
                    bindings lower state fn arguments
              | .letE name type value body =>
                  match psWasmLowerParameterType profile type with
                  | Except.error error => Except.error error
                  | Except.ok localType =>
                      match
                          lower
                            (Option.some localType)
                            state
                            value with
                      | Except.error error => Except.error error
                      | Except.ok loweredValue =>
                          let allocated :=
                            psWasmAddLocal loweredValue.state localType;
                          let localIndex := (Prod.fst allocated);
                          let localState := (Prod.snd allocated);
                          let bodyBindings :=
                            List.cons
                              (PsWasmBinding.mk
                                name
                                localIndex
                                type)
                              bindings;
                          match
                              smaller
                                bodyBindings
                                expected
                                localState
                                body with
                          | Except.error error => Except.error error
                          | Except.ok loweredBody =>
                              Except.ok {
                                instructions :=
                                  psListAppend
                                    loweredValue.instructions
                                    (psListAppend
                                      [PsWasmInstruction.localSet localIndex]
                                      (loweredBody.instructions))
                                state := loweredBody.state
                              }
              | .record structureName _ fields =>
                  match psWasmFindStructure structures structureName with
                  | Option.none =>
                      Except.error
                        (PsWasmLowerError.unknownStructure structureName)
                  | Option.some structInfo =>
                      match structInfo.typeParameters with
                      | _ :: _ =>
                          Except.error PsWasmLowerError.unsupportedType
                      | [] =>
                          match
                              psWasmLowerRecordFieldsWith
                                profile
                                lower
                                structInfo
                                fields
                                state
                                structInfo.fields with
                          | Except.error error => Except.error error
                          | Except.ok lowered =>
                              Except.ok {
                                instructions :=
                                  psListAppend
                                    lowered.instructions
                                    [PsWasmInstruction.structNew structureName]
                                state := lowered.state
                              }
              | .projection structureName _ target fieldName =>
                  match psWasmFindStructure structures structureName with
                  | Option.none =>
                      Except.error
                        (PsWasmLowerError.unknownStructure structureName)
                  | Option.some structInfo =>
                      match psWasmFindStructureField structInfo fieldName with
                      | Option.none =>
                          Except.error
                            (PsWasmLowerError.unknownStructureField
                              structureName fieldName)
                      | Option.some indexedField =>
                          let fieldIndex := (Prod.fst indexedField);
                          let field := (Prod.snd indexedField);
                          match
                              lower
                                (Option.some (PsWasmValueType.refT structureName))
                                state
                                target with
                          | Except.error error => Except.error error
                          | Except.ok lowered =>
                              Except.ok {
                                instructions :=
                                  psListAppend
                                    lowered.instructions
                                    [psWasmStructGetInstruction
                                                                  structureName
                                                                  fieldIndex
                                                                  field.type]
                                state := lowered.state
                              }
              | .constructor
                  inductiveName
                  constructorName
                  typeArguments
                  fields =>
                  match typeArguments with
                  | _ :: _ =>
                      Except.error PsWasmLowerError.unsupportedType
                  | [] =>
                      match psWasmFindInductive inductives inductiveName with
                      | Option.none =>
                          Except.error
                            (PsWasmLowerError.unknownInductive inductiveName)
                      | Option.some inductiveInfo =>
                          match inductiveInfo.typeParameters with
                          | _ :: _ =>
                              Except.error PsWasmLowerError.unsupportedType
                          | [] =>
                              match
                                  psWasmFindConstructor
                                    inductiveInfo.constructors
                                    constructorName with
                              | Option.none =>
                                  Except.error
                                    (PsWasmLowerError.unknownConstructor
                                      inductiveName
                                      constructorName)
                              | Option.some constructorInfo =>
                                  match
                                      psWasmLowerConstructorValuesWith
                                        profile
                                        lower
                                        inductiveName
                                        constructorInfo
                                        fields
                                        state
                                        constructorInfo.fields with
                                  | Except.error error =>
                                      Except.error error
                                  | Except.ok lowered =>
                                      Except.ok {
                                        instructions :=
                                          psListAppend
                                            lowered.instructions
                                            [PsWasmInstruction.structNew
                                                                                  (psWasmConstructorTypeName
                                                                                    inductiveName
                                                                                    constructorName)]
                                        state := lowered.state
                                      }
              | .matchE inductiveName _ scrutinee alternatives =>
                  match psWasmFindInductive inductives inductiveName with
                  | Option.none =>
                      Except.error
                        (PsWasmLowerError.unknownInductive inductiveName)
                  | Option.some inductiveInfo =>
                      match inductiveInfo.typeParameters with
                      | _ :: _ =>
                          Except.error PsWasmLowerError.unsupportedType
                      | [] =>
                          match
                              lower
                                (Option.some (PsWasmValueType.refT inductiveName))
                                state
                                scrutinee with
                          | Except.error error => Except.error error
                          | Except.ok loweredScrutinee =>
                              let allocated :=
                                psWasmAddLocal
                                  loweredScrutinee.state
                                  (PsWasmValueType.refT inductiveName);
                              let scrutineeLocal := (Prod.fst allocated);
                              let nextState := (Prod.snd allocated);
                              match
                                  psWasmLowerMatchAlternativesWith
                                    profile
                                    inductiveInfo
                                    scrutineeLocal
                                    lowerWithBindings
                                    bindings
                                    expected
                                    nextState
                                    alternatives with
                              | Except.error error => Except.error error
                              | Except.ok loweredMatch =>
                                  Except.ok {
                                    instructions :=
                                      psListAppend
                                        loweredScrutinee.instructions
                                        (psListAppend
                                          [PsWasmInstruction.localSet
                                                                            scrutineeLocal]
                                          (loweredMatch.instructions))
                                    state := loweredMatch.state
                                  }
              | .ifE condition thenBranch elseBranch =>
                  psWasmLowerIfWith
                    lower state expected condition thenBranch elseBranch
        

end WasmLowerExprPrefixReference
