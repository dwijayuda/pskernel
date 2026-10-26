import Ps.CompilerIr.Model
import Ps.Foundation.List

/-!
# Wasm runtime dependencies

Read-only analysis of the existing IR for Nat, Int and String runtime selection.
Inputs are types, expressions, declarations and modules; outputs are Bool hints
used by Lower.psWasmLowerSpecializedModule. This module does not validate IR,
lower instructions, admit declarations, choose host tools or publish output.

The bodies below are moved verbatim from Lower.lean at 7fc146ef. Preserve source
order, intrinsic cross-dependencies, and short-circuit traversal. In particular,
String operations may require Nat support even when they do not introduce Nat
literals. The existing limits are 64 for type traversal and 4096 for expression
traversal. Fuel exhaustion returns false: these hints are not an absence proof
and must never replace strict IR or backend validation.

No names, algorithms, failure priority, fuel or runtime capabilities change.
See docs/PSC1_PASS_CONTRACTS.md and scripts/readability-module-check.mjs.
-/

def psWasmTypeUsesNatWithFuel
    (remainingFuel : Nat) :
    PsVerifiedIrType -> Bool :=
  match remainingFuel with
  | 0 =>
      fun (_type : PsVerifiedIrType) => false
  | fuel + 1 =>
      fun (type : PsVerifiedIrType) =>
        let smaller : PsVerifiedIrType -> Bool :=
          psWasmTypeUsesNatWithFuel fuel;
        let usesType :
            PsVerifiedIrType -> Bool :=
          fun (value : PsVerifiedIrType) =>
            smaller value;
        match type with
        | .primitive primitive =>
            match primitive with
            | .nat => true
            | _ => false
        | .function parameters result =>
            if psListAny usesType parameters then
              true
            else
              usesType result
        | .named _ arguments =>
            psListAny usesType arguments
        | _ => false

def psWasmTypeUsesNat
    (type : PsVerifiedIrType) : Bool :=
  psWasmTypeUsesNatWithFuel 64 type

def psWasmIntrinsicUsesNat
    (operation : PsVerifiedIrIntrinsic) : Bool :=
  match operation with
  | .natAdd => true
  | .natSub => true
  | .natMul => true
  | .natDiv => true
  | .natMod => true
  | .natEq => true
  | .natNe => true
  | .natLe => true
  | .natLt => true
  | .intOfNat => true
  | .intRepr => true
  | .intNegSucc => true
  | .charOfNat => true
  | .charToNat => true
  | .stringLength => true
  | .stringUtf8ByteSize => true
  | .stringNext => true
  | .stringGet => true
  | .stringAtEnd => true
  | .stringExtract => true
  | .arrayEmptyWithCapacity => true
  | .arraySize => true
  | .arrayGet => true
  | .arrayGetD => true
  | .arraySet => true
  | .arraySetIfInBounds => true
  | .arrayFoldl => true
  | _ => false

def psWasmExprUsesNatWithFuel
    (remainingFuel : Nat) :
    PsVerifiedIrExpr -> Bool :=
  match remainingFuel with
  | 0 =>
      fun (_expr : PsVerifiedIrExpr) => false
  | fuel + 1 =>
      fun (expr : PsVerifiedIrExpr) =>
        let smaller : PsVerifiedIrExpr -> Bool :=
          psWasmExprUsesNatWithFuel fuel;
        let uses :
            PsVerifiedIrExpr -> Bool :=
          fun (nested : PsVerifiedIrExpr) =>
            smaller nested;
        let fieldUses :
            (String × PsVerifiedIrExpr) -> Bool :=
          fun (field : String × PsVerifiedIrExpr) =>
            uses (Prod.snd field);
        let parameterUses :
            PsVerifiedIrParameter -> Bool :=
          fun (parameter : PsVerifiedIrParameter) =>
            psWasmTypeUsesNat parameter.type;
        let bindingUses :
            PsVerifiedIrMatchBinding -> Bool :=
          fun (binding : PsVerifiedIrMatchBinding) =>
            psWasmTypeUsesNat binding.type;
        let alternativeUses :
            (String ×
              List PsVerifiedIrMatchBinding ×
              PsVerifiedIrExpr) -> Bool :=
          fun
            (alternative :
              String ×
                List PsVerifiedIrMatchBinding ×
                PsVerifiedIrExpr) =>
            if
                psListAny
                  bindingUses
                  (Prod.fst (Prod.snd alternative)) then
              true
            else
              uses (Prod.snd (Prod.snd alternative));
        match expr with
        | .literal literal =>
            match literal with
            | .natural _ => true
            | _ => false
        | .var _ => false
        | .intrinsic operation typeArguments arguments =>
            if psWasmIntrinsicUsesNat operation then
              true
            else if psListAny psWasmTypeUsesNat typeArguments then
              true
            else
              psListAny uses arguments
        | .lambda parameters resultType body =>
            if psListAny parameterUses parameters then
              true
            else if psWasmTypeUsesNat resultType then
              true
            else
              uses body
        | .call fn typeArguments arguments =>
            if uses fn then
              true
            else if psListAny psWasmTypeUsesNat typeArguments then
              true
            else
              psListAny uses arguments
        | .letE _ type value body =>
            if psWasmTypeUsesNat type then
              true
            else if uses value then
              true
            else
              uses body
        | .ifE condition thenBranch elseBranch =>
            if uses condition then
              true
            else if uses thenBranch then
              true
            else
              uses elseBranch
        | .record _ typeArguments fields =>
            if psListAny psWasmTypeUsesNat typeArguments then
              true
            else
              psListAny fieldUses fields
        | .projection _ typeArguments target _ =>
            if psListAny psWasmTypeUsesNat typeArguments then
              true
            else
              uses target
        | .constructor _ _ typeArguments fields =>
            if psListAny psWasmTypeUsesNat typeArguments then
              true
            else
              psListAny fieldUses fields
        | .matchE _ typeArguments scrutinee alternatives =>
            if psListAny psWasmTypeUsesNat typeArguments then
              true
            else if uses scrutinee then
              true
            else
              psListAny alternativeUses alternatives

def psWasmExprUsesNat
    (expr : PsVerifiedIrExpr) : Bool :=
  psWasmExprUsesNatWithFuel 4096 expr

def psWasmTypeUsesIntWithFuel
    (remainingFuel : Nat) :
    PsVerifiedIrType -> Bool :=
  match remainingFuel with
  | 0 =>
      fun (_type : PsVerifiedIrType) => false
  | fuel + 1 =>
      fun (type : PsVerifiedIrType) =>
        let smaller : PsVerifiedIrType -> Bool :=
          psWasmTypeUsesIntWithFuel fuel;
        let usesType :
            PsVerifiedIrType -> Bool :=
          fun (value : PsVerifiedIrType) =>
            smaller value;
        match type with
        | .primitive primitive =>
            match primitive with
            | .int => true
            | _ => false
        | .function parameters result =>
            if psListAny usesType parameters then
              true
            else
              usesType result
        | .named _ arguments =>
            psListAny usesType arguments
        | _ => false

def psWasmTypeUsesInt
    (type : PsVerifiedIrType) : Bool :=
  psWasmTypeUsesIntWithFuel 64 type

def psWasmIntrinsicUsesInt
    (operation : PsVerifiedIrIntrinsic) : Bool :=
  match operation with
  | .intOfNat => true
  | .intNegSucc => true
  | .intNeg => true
  | .intAdd => true
  | .intSub => true
  | .intMul => true
  | .intEq => true
  | .intLe => true
  | .intLt => true
  | _ => false

def psWasmExprUsesIntWithFuel
    (remainingFuel : Nat) :
    PsVerifiedIrExpr -> Bool :=
  match remainingFuel with
  | 0 =>
      fun (_expr : PsVerifiedIrExpr) => false
  | fuel + 1 =>
      fun (expr : PsVerifiedIrExpr) =>
        let smaller : PsVerifiedIrExpr -> Bool :=
          psWasmExprUsesIntWithFuel fuel;
        let uses :
            PsVerifiedIrExpr -> Bool :=
          fun (nested : PsVerifiedIrExpr) =>
            smaller nested;
        let fieldUses :
            (String × PsVerifiedIrExpr) -> Bool :=
          fun (field : String × PsVerifiedIrExpr) =>
            uses (Prod.snd field);
        let parameterUses :
            PsVerifiedIrParameter -> Bool :=
          fun (parameter : PsVerifiedIrParameter) =>
            psWasmTypeUsesInt parameter.type;
        let bindingUses :
            PsVerifiedIrMatchBinding -> Bool :=
          fun (binding : PsVerifiedIrMatchBinding) =>
            psWasmTypeUsesInt binding.type;
        let alternativeUses :
            (String ×
              List PsVerifiedIrMatchBinding ×
              PsVerifiedIrExpr) -> Bool :=
          fun
            (alternative :
              String ×
                List PsVerifiedIrMatchBinding ×
                PsVerifiedIrExpr) =>
            if
                psListAny
                  bindingUses
                  (Prod.fst (Prod.snd alternative)) then
              true
            else
              uses (Prod.snd (Prod.snd alternative));
        match expr with
        | .literal literal =>
            match literal with
            | .integer _ => true
            | _ => false
        | .var _ => false
        | .intrinsic operation typeArguments arguments =>
            if psWasmIntrinsicUsesInt operation then
              true
            else if psListAny psWasmTypeUsesInt typeArguments then
              true
            else
              psListAny uses arguments
        | .lambda parameters resultType body =>
            if psListAny parameterUses parameters then
              true
            else if psWasmTypeUsesInt resultType then
              true
            else
              uses body
        | .call fn typeArguments arguments =>
            if uses fn then
              true
            else if psListAny psWasmTypeUsesInt typeArguments then
              true
            else
              psListAny uses arguments
        | .letE _ type value body =>
            if psWasmTypeUsesInt type then
              true
            else if uses value then
              true
            else
              uses body
        | .ifE condition thenBranch elseBranch =>
            if uses condition then
              true
            else if uses thenBranch then
              true
            else
              uses elseBranch
        | .record _ typeArguments fields =>
            if psListAny psWasmTypeUsesInt typeArguments then
              true
            else
              psListAny fieldUses fields
        | .projection _ typeArguments target _ =>
            if psListAny psWasmTypeUsesInt typeArguments then
              true
            else
              uses target
        | .constructor _ _ typeArguments fields =>
            if psListAny psWasmTypeUsesInt typeArguments then
              true
            else
              psListAny fieldUses fields
        | .matchE _ typeArguments scrutinee alternatives =>
            if psListAny psWasmTypeUsesInt typeArguments then
              true
            else if uses scrutinee then
              true
            else
              psListAny alternativeUses alternatives

def psWasmExprUsesInt
    (expr : PsVerifiedIrExpr) : Bool :=
  psWasmExprUsesIntWithFuel 4096 expr

def psWasmTypeUsesStringWithFuel
    (remainingFuel : Nat) :
    PsVerifiedIrType -> Bool :=
  match remainingFuel with
  | 0 =>
      fun (_type : PsVerifiedIrType) => false
  | fuel + 1 =>
      fun (type : PsVerifiedIrType) =>
        let smaller : PsVerifiedIrType -> Bool :=
          psWasmTypeUsesStringWithFuel fuel;
        let usesType :
            PsVerifiedIrType -> Bool :=
          fun (value : PsVerifiedIrType) =>
            smaller value;
        match type with
        | .primitive primitive =>
            match primitive with
            | .string => true
            | _ => false
        | .function parameters result =>
            if psListAny usesType parameters then
              true
            else
              usesType result
        | .named _ arguments =>
            psListAny usesType arguments
        | _ => false

def psWasmTypeUsesString
    (type : PsVerifiedIrType) : Bool :=
  psWasmTypeUsesStringWithFuel 64 type

def psWasmIntrinsicUsesString
    (operation : PsVerifiedIrIntrinsic) : Bool :=
  match operation with
  | .intRepr => true
  | .stringPush => true
  | .stringSingleton => true
  | .stringLength => true
  | .stringAppend => true
  | .stringUtf8ByteSize => true
  | .stringNext => true
  | .stringGet => true
  | .stringAtEnd => true
  | .stringExtract => true
  | .stringEq => true
  | _ => false

def psWasmExprUsesStringWithFuel
    (remainingFuel : Nat) :
    PsVerifiedIrExpr -> Bool :=
  match remainingFuel with
  | 0 =>
      fun (_expr : PsVerifiedIrExpr) => false
  | fuel + 1 =>
      fun (expr : PsVerifiedIrExpr) =>
        let smaller : PsVerifiedIrExpr -> Bool :=
          psWasmExprUsesStringWithFuel fuel;
        let uses :
            PsVerifiedIrExpr -> Bool :=
          fun (nested : PsVerifiedIrExpr) =>
            smaller nested;
        let fieldUses :
            (String × PsVerifiedIrExpr) -> Bool :=
          fun (field : String × PsVerifiedIrExpr) =>
            uses (Prod.snd field);
        let parameterUses :
            PsVerifiedIrParameter -> Bool :=
          fun (parameter : PsVerifiedIrParameter) =>
            psWasmTypeUsesString parameter.type;
        let bindingUses :
            PsVerifiedIrMatchBinding -> Bool :=
          fun (binding : PsVerifiedIrMatchBinding) =>
            psWasmTypeUsesString binding.type;
        let alternativeUses :
            (String ×
              List PsVerifiedIrMatchBinding ×
              PsVerifiedIrExpr) -> Bool :=
          fun
            (alternative :
              String ×
                List PsVerifiedIrMatchBinding ×
                PsVerifiedIrExpr) =>
            if
                psListAny
                  bindingUses
                  (Prod.fst (Prod.snd alternative)) then
              true
            else
              uses (Prod.snd (Prod.snd alternative));
        match expr with
        | .literal literal =>
            match literal with
            | .string _ => true
            | _ => false
        | .var _ => false
        | .intrinsic operation typeArguments arguments =>
            if psWasmIntrinsicUsesString operation then
              true
            else if psListAny psWasmTypeUsesString typeArguments then
              true
            else
              psListAny uses arguments
        | .lambda parameters resultType body =>
            if psListAny parameterUses parameters then
              true
            else if psWasmTypeUsesString resultType then
              true
            else
              uses body
        | .call fn typeArguments arguments =>
            if uses fn then
              true
            else if psListAny psWasmTypeUsesString typeArguments then
              true
            else
              psListAny uses arguments
        | .letE _ type value body =>
            if psWasmTypeUsesString type then
              true
            else if uses value then
              true
            else
              uses body
        | .ifE condition thenBranch elseBranch =>
            if uses condition then
              true
            else if uses thenBranch then
              true
            else
              uses elseBranch
        | .record _ typeArguments fields =>
            if psListAny psWasmTypeUsesString typeArguments then
              true
            else
              psListAny fieldUses fields
        | .projection _ typeArguments target _ =>
            if psListAny psWasmTypeUsesString typeArguments then
              true
            else
              uses target
        | .constructor _ _ typeArguments fields =>
            if psListAny psWasmTypeUsesString typeArguments then
              true
            else
              psListAny fieldUses fields
        | .matchE _ typeArguments scrutinee alternatives =>
            if psListAny psWasmTypeUsesString typeArguments then
              true
            else if uses scrutinee then
              true
            else
              psListAny alternativeUses alternatives

def psWasmExprUsesString
    (expr : PsVerifiedIrExpr) : Bool :=
  psWasmExprUsesStringWithFuel 4096 expr

def psWasmStructureUsesNat
    (structureInfo : PsVerifiedIrStructure) : Bool :=
  let fieldUses :
      PsVerifiedIrStructureField -> Bool :=
    fun (field : PsVerifiedIrStructureField) =>
      psWasmTypeUsesNat field.type;
  psListAny fieldUses structureInfo.fields

def psWasmConstructorUsesNat
    (constructorInfo : PsVerifiedIrConstructor) : Bool :=
  let fieldUses :
      PsVerifiedIrConstructorField -> Bool :=
    fun (field : PsVerifiedIrConstructorField) =>
      psWasmTypeUsesNat field.type;
  psListAny fieldUses constructorInfo.fields

def psWasmInductiveUsesNat
    (inductiveInfo : PsVerifiedIrInductive) : Bool :=
  psListAny
    psWasmConstructorUsesNat
    inductiveInfo.constructors

def psWasmDeclarationUsesNat
    (declaration : PsVerifiedIrDeclaration) : Bool :=
  let parameterUses :
      PsVerifiedIrParameter -> Bool :=
    fun (parameter : PsVerifiedIrParameter) =>
      psWasmTypeUsesNat parameter.type;
  if psListAny parameterUses declaration.parameters then
    true
  else if psWasmTypeUsesNat declaration.resultType then
    true
  else
    psWasmExprUsesNat declaration.body

def psWasmModuleUsesNat
    (module : PsVerifiedIrModule) : Bool :=
  let importUses :
      PsVerifiedIrExternalImport -> Bool :=
    fun (importInfo : PsVerifiedIrExternalImport) =>
      psWasmTypeUsesNat importInfo.type;
  if psListAny importUses module.imports then
    true
  else if psListAny psWasmStructureUsesNat module.structures then
    true
  else if psListAny psWasmInductiveUsesNat module.inductives then
    true
  else
    psListAny psWasmDeclarationUsesNat module.declarations

def psWasmStructureUsesInt
    (structureInfo : PsVerifiedIrStructure) : Bool :=
  let fieldUses :
      PsVerifiedIrStructureField -> Bool :=
    fun (field : PsVerifiedIrStructureField) =>
      psWasmTypeUsesInt field.type;
  psListAny fieldUses structureInfo.fields

def psWasmConstructorUsesInt
    (constructorInfo : PsVerifiedIrConstructor) : Bool :=
  let fieldUses :
      PsVerifiedIrConstructorField -> Bool :=
    fun (field : PsVerifiedIrConstructorField) =>
      psWasmTypeUsesInt field.type;
  psListAny fieldUses constructorInfo.fields

def psWasmInductiveUsesInt
    (inductiveInfo : PsVerifiedIrInductive) : Bool :=
  psListAny
    psWasmConstructorUsesInt
    inductiveInfo.constructors

def psWasmDeclarationUsesInt
    (declaration : PsVerifiedIrDeclaration) : Bool :=
  let parameterUses :
      PsVerifiedIrParameter -> Bool :=
    fun (parameter : PsVerifiedIrParameter) =>
      psWasmTypeUsesInt parameter.type;
  if psListAny parameterUses declaration.parameters then
    true
  else if psWasmTypeUsesInt declaration.resultType then
    true
  else
    psWasmExprUsesInt declaration.body

def psWasmModuleUsesInt
    (module : PsVerifiedIrModule) : Bool :=
  let importUses :
      PsVerifiedIrExternalImport -> Bool :=
    fun (importInfo : PsVerifiedIrExternalImport) =>
      psWasmTypeUsesInt importInfo.type;
  if psListAny importUses module.imports then
    true
  else if psListAny psWasmStructureUsesInt module.structures then
    true
  else if psListAny psWasmInductiveUsesInt module.inductives then
    true
  else
    psListAny psWasmDeclarationUsesInt module.declarations


def psWasmStructureUsesString
    (structureInfo : PsVerifiedIrStructure) : Bool :=
  let fieldUses :
      PsVerifiedIrStructureField -> Bool :=
    fun (field : PsVerifiedIrStructureField) =>
      psWasmTypeUsesString field.type;
  psListAny fieldUses structureInfo.fields

def psWasmConstructorUsesString
    (constructorInfo : PsVerifiedIrConstructor) : Bool :=
  let fieldUses :
      PsVerifiedIrConstructorField -> Bool :=
    fun (field : PsVerifiedIrConstructorField) =>
      psWasmTypeUsesString field.type;
  psListAny fieldUses constructorInfo.fields

def psWasmInductiveUsesString
    (inductiveInfo : PsVerifiedIrInductive) : Bool :=
  psListAny
    psWasmConstructorUsesString
    inductiveInfo.constructors

def psWasmDeclarationUsesString
    (declaration : PsVerifiedIrDeclaration) : Bool :=
  let parameterUses :
      PsVerifiedIrParameter -> Bool :=
    fun (parameter : PsVerifiedIrParameter) =>
      psWasmTypeUsesString parameter.type;
  if psListAny parameterUses declaration.parameters then
    true
  else if psWasmTypeUsesString declaration.resultType then
    true
  else
    psWasmExprUsesString declaration.body

def psWasmModuleUsesString
    (module : PsVerifiedIrModule) : Bool :=
  let importUses :
      PsVerifiedIrExternalImport -> Bool :=
    fun (importInfo : PsVerifiedIrExternalImport) =>
      psWasmTypeUsesString importInfo.type;
  if psListAny importUses module.imports then
    true
  else if psListAny psWasmStructureUsesString module.structures then
    true
  else if psListAny psWasmInductiveUsesString module.inductives then
    true
  else
    psListAny psWasmDeclarationUsesString module.declarations


