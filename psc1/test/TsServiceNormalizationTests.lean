import Ps.BackendTs.Module

-- Preserve the exact pre-normalization visitor for all-input native equality.
namespace PsTsServiceReference
def legacyContext
    (brands : List (String × String)) (tags : List (String × String)) (fuel : Nat) :
    Bool -> PsVerifiedIrExpr -> Except PsTsEmitError String :=
  match fuel with
  | Nat.zero => fun (_tail : Bool) (_expr : PsVerifiedIrExpr) => Except.error PsTsEmitError.fuelExhausted
  | Nat.succ remaining =>
    fun (tail : Bool) (expr : PsVerifiedIrExpr) =>
      let smaller : PsVerifiedIrExpr -> Except PsTsEmitError String := legacyContext brands tags remaining false;
      let result : PsVerifiedIrExpr -> Except PsTsEmitError String := legacyContext brands tags remaining tail;
      let owned : PsVerifiedIrExpr -> Except PsTsEmitError String := legacyContext brands tags remaining true;
      match expr with
      | .literal literal =>
          psTsEmitLiteral literal
      | .var name =>
          Except.ok name
      | .intrinsic operation _ arguments =>
          match psListMapExcept smaller arguments with
          | Except.error error => Except.error error
          | Except.ok printed =>
              psTsEmitIntrinsicFromPrinted operation printed
      | .lambda parameters resultType body =>
          let printParameter : PsVerifiedIrParameter -> Except PsTsEmitError String :=
            fun (parameter : PsVerifiedIrParameter) =>
              match psTsEmitType parameter.type with
              | Except.error error => Except.error error
              | Except.ok type =>
                  Except.ok (psTsJoin "" [parameter.name, ": ", type]);
          match psListMapExcept printParameter parameters with
          | Except.error error => Except.error error
          | Except.ok printedParameters =>
              match owned body with
              | Except.error error => Except.error error
              | Except.ok printedBody =>
                  match psTsEmitType resultType with
                  | Except.error error => Except.error error
                  | Except.ok printedResult =>
                      Except.ok
                        (psTsJoin "" ["__ps$wrap(function*(", psTsJoin ", " printedParameters, "): __ps$Computation<", printedResult, "> { return ", printedBody, "; })"])
      | .call fn typeArguments arguments =>
          match smaller fn with
          | Except.error error => Except.error error
          | Except.ok printedFn =>
              let callable : String :=
                match fn with
                | PsVerifiedIrExpr.lambda _ _ _ => psTsJoin "" ["(", printedFn, ")"]
                | _ => printedFn;
              match psTsEmitTypeArguments typeArguments with
              | Except.error error => Except.error error
              | Except.ok generic =>
                  match psListMapExcept smaller arguments with
                  | Except.error error => Except.error error
                  | Except.ok printedArguments =>
                      let suffix :=
                        if psListIsEmpty printedArguments then ""
                        else psTsJoin "" [", ", psTsJoin ", " printedArguments];
                      Except.ok
                        (psTsJoin "" ["(yield* ", (if tail then "__ps$tail" else "__ps$invoke"), "(", callable, generic, suffix, "))"])
      | .letE _ _ _ _ =>
          match psTsEmitLetStatementsWithResult smaller result expr with
          | Except.error error => Except.error error
          | Except.ok statements =>
              Except.ok (psTsJoin "" ["(yield* (function*() { ", statements, " })())"])
      | .ifE condition thenBranch elseBranch =>
          match smaller condition with
          | Except.error error => Except.error error
          | Except.ok printedCondition =>
              match result thenBranch with
              | Except.error error => Except.error error
              | Except.ok printedThen =>
                  match result elseBranch with
                  | Except.error error => Except.error error
                  | Except.ok printedElse =>
                      Except.ok
                        (psTsJoin "" ["(", printedCondition, " ? ", printedThen, " : ", printedElse, ")"])
      | .record structureName _ fields =>
          match psTsLookup brands structureName with
          | Option.none =>
              Except.error (PsTsEmitError.unknownStructure structureName)
          | Option.some brand =>
              let printField : (String × PsVerifiedIrExpr) -> Except PsTsEmitError String :=
                fun (field : String × PsVerifiedIrExpr) =>
                  match field with
                  | Prod.mk fieldName fieldValue =>
                      match
                          smaller
                            fieldValue with
                      | Except.error error => Except.error error
                      | Except.ok value =>
                          Except.ok (psTsJoin "" ["[", psJsonQuote fieldName, "]: ", value]);
              match psListMapExcept printField fields with
              | Except.error error => Except.error error
              | Except.ok printedFields =>
                  let suffix :=
                    if psListIsEmpty printedFields then
                      ""
                    else
                      psTsJoin "" [", ", psTsJoin ", " printedFields];
                  Except.ok
                    (psTsJoin "" ["({ [", brand, "]: true as const", suffix, " })"])
      | .projection _ _ target field =>
          match smaller target with
          | Except.error error => Except.error error
          | Except.ok printedTarget =>
              Except.ok (psTsJoin "" [printedTarget, ".", field])
      | .constructor inductiveName constructorName typeArguments fields =>
          match psTsLookup tags inductiveName with
          | Option.none =>
              Except.error (PsTsEmitError.unknownInductive inductiveName)
          | Option.some _ =>
              match psTsEmitTypeArguments typeArguments with
              | Except.error error => Except.error error
              | Except.ok generic =>
                  let access :=
                    psTsJoin "" [inductiveName, "[", psJsonQuote constructorName, "]"];
                  let printField : (String × PsVerifiedIrExpr) -> Except PsTsEmitError String :=
                    fun (field : String × PsVerifiedIrExpr) =>
                      match field with
                      | Prod.mk fieldName fieldValue =>
                          smaller
                            fieldValue;
                  match psListMapExcept printField fields with
                  | Except.error error => Except.error error
                  | Except.ok printedFields =>
                      if if psListIsEmpty typeArguments then psListIsEmpty fields else false then
                        Except.ok access
                      else
                        Except.ok
                          (psTsJoin "" [access, generic, "(", psTsJoin ", " printedFields, ")"])
      | .matchE inductiveName _ scrutinee alternatives =>
          match psTsLookup tags inductiveName with
          | Option.none =>
              Except.error (PsTsEmitError.unknownInductive inductiveName)
          | Option.some tag =>
              if psListIsEmpty alternatives then
                match smaller scrutinee with
                | Except.error error => Except.error error
                | Except.ok printedScrutinee =>
                    Except.ok
                      (psTsJoin "" ["(yield* (function*(): __ps$Computation<never> { void (",
                        printedScrutinee, "); throw new Error(",
                        psJsonQuote "unreachable empty ProofScript match", "); })())"])
              else
                let temp := psTsFreshMatchTemp expr;
                let printAlternative : (String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr) -> Except PsTsEmitError String :=
                  fun (alternative : String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr) =>
                    match alternative with
                    | Prod.mk constructorName detail =>
                      match detail with
                      | Prod.mk bindings body =>
                        match
                            result
                              body with
                        | Except.error error => Except.error error
                        | Except.ok printedBody =>
                            if psListIsEmpty bindings then
                              Except.ok
                                (psTsJoin "" ["case ", psJsonQuote constructorName, ": return ", printedBody, ";"])
                            else
                              let printBinding : PsVerifiedIrMatchBinding -> Except PsTsEmitError String :=
                                fun (binding : PsVerifiedIrMatchBinding) =>
                                  match psTsEmitType binding.type with
                                  | Except.error error => Except.error error
                                  | Except.ok type =>
                                      Except.ok
                                        (psTsJoin "" ["const ", binding.name, ": ", type, " = ", temp, ".", binding.field, ";"]);
                              match psListMapExcept printBinding bindings with
                              | Except.error error => Except.error error
                              | Except.ok printedBindings =>
                                  Except.ok
                                    (psTsJoin "" ["case ", psJsonQuote constructorName, ": { ", psTsJoin " " printedBindings, " return ", printedBody, "; }"]);
                match psListMapExcept printAlternative alternatives with
                | Except.error error => Except.error error
                | Except.ok cases =>
                    match
                        smaller
                          scrutinee with
                    | Except.error error => Except.error error
                    | Except.ok printedScrutinee =>
                        Except.ok
                          (psTsJoin "" ["(yield* (function*() { const ", temp, " = ", printedScrutinee, "; switch (", temp, "[", tag, "]) { ", psTsJoin " " cases, " } throw new Error(", psJsonQuote
                              "invalid ProofScript constructor tag", "); })())"])


-- Ordinary expression consumers preserve their surrounding continuation.
theorem typed_disabled_eq (brands tags : List (String × String)) (fuel : Nat) :
    legacyContext brands tags fuel =
      psTsEmitTypedExprContextWithFuel brands tags false fuel Option.none := by
  induction fuel with
  | zero => rfl
  | succ remaining ih =>
      simp only [legacyContext, psTsEmitTypedExprContextWithFuel,
        psTsGeneratorResultAnnotation, ih]
      rfl

theorem context_eq (brands tags : List (String × String)) (fuel : Nat) :
    legacyContext brands tags fuel = psTsEmitExprContextWithFuel brands tags fuel := by
  exact typed_disabled_eq brands tags fuel
end PsTsServiceReference


namespace PsTsModuleReference
def psTsEmitPureDeclaration (isPublic : Bool) (brands tags : List (String × String))
    (declaration : PsVerifiedIrDeclaration) : Option String := do
  if declaration.parameters.isEmpty && !declaration.typeParameters.isEmpty then none else do
    let body ← psTsTailPrintPure brands tags [] (psTsInlineEtaApplication declaration.body)
    let result ← (psTsEmitType declaration.resultType).toOption
    let exportPrefix := if isPublic then "export " else ""
    if declaration.parameters.isEmpty then
      return exportPrefix ++ "const " ++ declaration.name ++ ": " ++ result ++ " = " ++ body ++ ";"
    else
      let parameters ← declaration.parameters.mapM fun parameter => do
        let type ← (psTsEmitType parameter.type).toOption
        return parameter.name ++ ": " ++ type
      return exportPrefix ++ "function " ++ declaration.name ++ psTsGenericNames declaration.typeParameters ++
        "(" ++ String.intercalate ", " parameters ++ "): " ++ result ++ " { return " ++ body ++ "; }"


partial def psTsNeedsUtf8Runtime : PsVerifiedIrExpr → Bool
  | .literal _ | .var _ => false
  | .intrinsic operation _ arguments =>
      (match operation with
        | .stringUtf8ByteSize | .stringNext | .stringGet | .stringAtEnd => true
        | _ => false) || arguments.any psTsNeedsUtf8Runtime
  | .lambda _ _ body => psTsNeedsUtf8Runtime body
  | .call fn _ arguments => psTsNeedsUtf8Runtime fn || arguments.any psTsNeedsUtf8Runtime
  | .letE _ _ value body => psTsNeedsUtf8Runtime value || psTsNeedsUtf8Runtime body
  | .ifE condition left right => psTsNeedsUtf8Runtime condition || psTsNeedsUtf8Runtime left || psTsNeedsUtf8Runtime right
  | .record _ _ fields | .constructor _ _ _ fields => fields.any (fun f => psTsNeedsUtf8Runtime f.2)
  | .projection _ _ target _ => psTsNeedsUtf8Runtime target
  | .matchE _ _ scrutinee alternatives => psTsNeedsUtf8Runtime scrutinee || alternatives.any (fun a => psTsNeedsUtf8Runtime a.2.2)

def psTsNeedsStackRuntime (brands tags : List (String × String))
    (declaration : PsVerifiedIrDeclaration) : Bool :=
  (psTsEmitPureDeclaration false brands tags declaration).isNone &&
    (psTsEmitCountLoop tags declaration).isNone &&
    (psTsEmitTailLoop brands tags declaration).isNone

def psTsSelectedRuntimeRequirements (module : PsVerifiedIrModule) : List String :=
  let brands := psTsBuildBrandMap module
  let tags := psTsBuildTagMap module
  (if module.declarations.any (psTsNeedsStackRuntime brands tags) then ["generator-stack"] else []) ++
  (if module.declarations.any (fun d => psTsNeedsUtf8Runtime d.body) then ["utf8-byte-index"] else [])

def psTsSelectedRuntimeSource (module : PsVerifiedIrModule) : String :=
  let needs := psTsSelectedRuntimeRequirements module
  String.intercalate "\n" (
    (if needs.contains "generator-stack" then [psTsStackRuntimeSupport] else []) ++
    (if needs.contains "utf8-byte-index" then [psTsUtf8RuntimeSupport] else []))

def psTsEmitInductiveWithVisibility (isPublic : Bool)
    (tags : List (String × String))
    (inductiveInfo : PsVerifiedIrInductive) :
    Except PsTsEmitError (List String) :=
  match psTsLookup tags inductiveInfo.name with
  | Option.none =>
      Except.error (PsTsEmitError.unknownInductive inductiveInfo.name)
  | Option.some tag =>
      match psListMapExcept (psTsEmitConstructorVariant tag) inductiveInfo.constructors with
      | Except.error error => Except.error error
      | Except.ok variants =>
          match psListMapExcept (psTsEmitConstructorValue tag inductiveInfo) inductiveInfo.constructors with
          | Except.error error => Except.error error
          | Except.ok constructorValues =>
              let generic :=
                psTsGenericNames inductiveInfo.typeParameters;
              let declarationPrefix :=
                psTsJoin "" [(if isPublic then "export type " else "type "), inductiveInfo.name, generic];
              -- A leading union separator on a single variant creates a
              -- one-member TSUnionType which formatters collapse to its member.
              -- Emit the canonical type shape before the exact AST guard.
              let typeLine :=
                match variants with
                | List.nil => psTsJoin "" [declarationPrefix, " = never;"]
                | List.cons first rest =>
                    match rest with
                    | List.nil => psTsJoin "" [declarationPrefix, " = ", first, ";"]
                    | List.cons _ _ =>
                        psTsJoin "" [declarationPrefix, " =\n  | ", psTsJoin "\n  | " variants, ";"];
              let tagLine := psTsJoin "" ["const ", tag, ": unique symbol = Symbol(", psJsonQuote (psTsJoin "" ["ProofScript.", inductiveInfo.name, ".tag"]), ");"];
              let exportLine := psTsJoin "" [(if isPublic then "export const " else "const "), inductiveInfo.name, " = {"];
              Except.ok (psTsAppendLines [tagLine, typeLine, exportLine] (psTsAppendLines constructorValues ["} as const;"]))

example (isPublic : Bool) (tags : List (String × String)) (info : PsVerifiedIrInductive) :
    psTsEmitInductiveWithVisibility isPublic tags info =
      _root_.psTsEmitInductiveWithVisibility isPublic tags info := by
  rfl

end PsTsModuleReference


namespace PsTsLegacyTailReference
def psTsTailEmitWithFuel (brands tags : List (Prod String String)) (declaration : PsVerifiedIrDeclaration)
    (fuel : Nat) : List PsTsTailAlias -> PsVerifiedIrExpr -> Option String :=
  match fuel with
  | Nat.zero => fun (_aliases : List PsTsTailAlias) (_expr : PsVerifiedIrExpr) => Option.none
  | Nat.succ remaining =>
      fun (aliases : List PsTsTailAlias) (expr : PsVerifiedIrExpr) =>
        let smaller : List PsTsTailAlias -> PsVerifiedIrExpr -> Option String := psTsTailEmitWithFuel brands tags declaration remaining;
        let emitPure : PsVerifiedIrExpr -> Option String := psTsTailPrintPure brands tags aliases;
        match expr with
        | PsVerifiedIrExpr.call fn types arguments =>
            if psListIsEmpty types then
              match psTsTailCallArguments declaration.name aliases fn arguments with
              | Option.none => Option.none
              | Option.some actual =>
                  if Nat.beq (psListLength actual) (psListLength declaration.parameters) then
                    match psTsTailMap emitPure actual with
                    | Option.none => Option.none
                    | Option.some printed =>
                        let parameterName : PsVerifiedIrParameter -> String := fun (parameter : PsVerifiedIrParameter) => parameter.name;
                        Option.some (psTsJoin "" ["[", psTsJoin ", " (psListMap parameterName declaration.parameters),
                          "] = [", psTsJoin ", " printed, "]; continue;"])
                  else Option.none
            else Option.none
        | PsVerifiedIrExpr.letE name type value body =>
            if psTsExprUsesNameWithFuel 4096 value name then Option.none
            else if psTsTailBindingSafe declaration aliases name then
              match psTsTailAliasValue declaration.name name value with
              | Option.some alias =>
                  let capturedAlias : PsVerifiedIrExpr -> Bool := fun (argument : PsVerifiedIrExpr) =>
                    if psTsTailPureWithFuel aliases 4096 argument then false else true;
                  if psListAny capturedAlias alias.captured then Option.none
                  else smaller (List.cons alias aliases) body
              | Option.none =>
                  match emitPure value with
                  | Option.none => Option.none
                  | Option.some printedValue =>
                      match psTsEmitType type with
                      | Except.error _ => Option.none
                      | Except.ok printedType =>
                          match smaller aliases body with
                          | Option.none => Option.none
                          | Option.some printedBody => Option.some (psTsJoin "" ["{ const ", name, ": ", printedType,
                              " = ", printedValue, "; ", printedBody, " }"])
            else Option.none
        | PsVerifiedIrExpr.ifE condition left right =>
            match emitPure condition with
            | Option.none => Option.none
            | Option.some printedCondition =>
                match smaller aliases left with
                | Option.none => Option.none
                | Option.some printedLeft =>
                    match smaller aliases right with
                    | Option.none => Option.none
                    | Option.some printedRight => Option.some (psTsJoin "" ["if (", printedCondition, ") { ",
                        printedLeft, " } else { ", printedRight, " }"])
        | PsVerifiedIrExpr.matchE name _ scrutinee alternatives =>
            if psListIsEmpty alternatives then Option.none
            else
              match psTsLookup tags name with
              | Option.none => Option.none
              | Option.some tag =>
                  match emitPure scrutinee with
                  | Option.none => Option.none
                  | Option.some printedScrutinee =>
                      let temporary := psTsFreshMatchTemp declaration.body;
                      let printBinding : PsVerifiedIrMatchBinding -> Option String := fun (binding : PsVerifiedIrMatchBinding) =>
                        if psTsTailBindingSafe declaration aliases binding.name then
                          match psTsEmitType binding.type with
                          | Except.error _ => Option.none
                          | Except.ok type => Option.some (psTsJoin "" ["const ", binding.name, ": ", type, " = ", temporary, ".", binding.field, ";"])
                        else Option.none;
                      let printAlternative : Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr) -> Option String :=
                        fun (alternative : Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr)) =>
                          match psTsTailMap printBinding (Prod.fst (Prod.snd alternative)) with
                          | Option.none => Option.none
                          | Option.some bindings =>
                              match smaller aliases (Prod.snd (Prod.snd alternative)) with
                              | Option.none => Option.none
                              | Option.some body => Option.some (psTsJoin "" ["case ", psJsonQuote (Prod.fst alternative), ": { ",
                                  psTsJoin " " bindings, " ", body, " }"]);
                      if psTsTailBindingSafe declaration aliases temporary then
                        match psTsTailMap printAlternative alternatives with
                        | Option.none => Option.none
                        | Option.some cases => Option.some (psTsJoin "" ["{ const ", temporary, " = ", printedScrutinee,
                            "; switch (", temporary, "[", tag, "]) { ", psTsJoin " " cases,
                            " } throw new Error(\"invalid ProofScript constructor tag\"); }"])
                      else Option.none
        | _ =>
            match emitPure expr with
            | Option.none => Option.none
            | Option.some printed => Option.some (psTsJoin "" ["return ", printed, ";"])


theorem disabled_eq (brands tags : List (Prod String String))
    (declaration : PsVerifiedIrDeclaration) (fuel : Nat) :
    psTsTailEmitWithFuel brands tags declaration fuel =
      _root_.psTsTailEmitContextWithFuel brands tags declaration false fuel := by
  induction fuel with
  | zero => rfl
  | succ remaining ih =>
      simp only [psTsTailEmitWithFuel, _root_.psTsTailEmitContextWithFuel,
        _root_.psTsTailEmitValue, _root_.psTsTailReturnValue, ih]
      rfl
end PsTsLegacyTailReference

def main : IO Unit := do
  IO.println "PSC1_TS_SERVICE_NORMALIZATION: all-input context and legacy tail equality proved"
  let alias : PsTsTailAlias := .mk "hop" [] 1
  if psTsTailEmitValue true [] [] [alias] .none false (.var "hop") != .none then
    throw (IO.userError "PSC1_TS_GENERATOR_ALIAS_ESCAPE")
  let selfShadow : PsVerifiedIrDeclaration := .mk "self" []
    [.mk "self" (.primitive .nat)] (.primitive .nat) (.var "self")
  if psTsEmitGeneratorLoopWithVisibility true [] [] selfShadow != .none then
    throw (IO.userError "PSC1_TS_GENERATOR_SELF_SHADOW")
  IO.println "PSC1_TS_GENERATOR_GUARDS: alias escape and self shadow refuse flattening"
  let natT : PsVerifiedIrType := .primitive .nat
  let stringT : PsVerifiedIrType := .primitive .string
  let expressions : List PsVerifiedIrExpr := [
    .literal (.natural 42), .literal (.string "λ🙂"), .var "x",
    .intrinsic .stringUtf8ByteSize [] [.literal (.string "λ🙂")],
    .call (.var "f") [] [.literal (.natural 0)],
    .letE "x" natT (.literal (.natural 1)) (.var "x"),
    .ifE (.literal (.bool true)) (.literal (.natural 1)) (.literal (.natural 2)),
    .lambda [.mk "x" natT] natT (.var "x"),
    .record "R" [] [("value", .intrinsic .stringAtEnd [] [.literal (.string ""),.literal (.natural 0)])],
    .constructor "I" "C" [] [("value", .intrinsic .stringGet [] [.literal (.string "λ"),.literal (.natural 0)])],
    .matchE "I" [] (.var "value") [("C",[],.intrinsic .stringNext [] [.literal (.string "λ"),.literal (.natural 0)])]]
  let mut count := 0
  for expression in expressions do
    if psTsNeedsUtf8Runtime expression != PsTsModuleReference.psTsNeedsUtf8Runtime expression then
      throw (IO.userError "PSC1_TS_RUNTIME_SCAN_NORMALIZATION")
    for publicFlag in [false,true] do
      for parameters in [[],[PsVerifiedIrParameter.mk "x" natT]] do
        for typeParameters in [[],[PsVerifiedIrTypeParameter.mk "T"]] do
          for result in [natT,stringT,PsVerifiedIrType.unknown] do
            let declaration : PsVerifiedIrDeclaration := .mk "fixture" typeParameters parameters result expression
            if psTsEmitPureDeclaration publicFlag [] [] declaration !=
                PsTsModuleReference.psTsEmitPureDeclaration publicFlag [] [] declaration then
              throw (IO.userError "PSC1_TS_PURE_PRINT_NORMALIZATION")
            let module : PsVerifiedIrModule := .mk [] [] [] [declaration]
            if psTsSelectedRuntimeRequirements module != PsTsModuleReference.psTsSelectedRuntimeRequirements module ||
                psTsSelectedRuntimeSource module != PsTsModuleReference.psTsSelectedRuntimeSource module then
              throw (IO.userError "PSC1_TS_RUNTIME_SELECTION_NORMALIZATION")
            count := count + 1
  IO.println ("PSC1_TS_MODULE_NORMALIZATION: exact old/new output and runtime choices; cases=" ++ toString count)
