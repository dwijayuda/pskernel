import Ps.BackendTs.Expr
import Ps.Codegen.Names
import Ps.BackendEcma.Utf8

def psTsEmitStructure
    (brands : List (String × String))
    (structureInfo : PsVerifiedIrStructure) :
    Except PsTsEmitError (List String) :=
  match psTsLookup brands structureInfo.name with
  | Option.none =>
      Except.error (PsTsEmitError.unknownStructure structureInfo.name)
  | Option.some brand =>
      let printField : PsVerifiedIrStructureField -> Except PsTsEmitError String :=
        fun (field : PsVerifiedIrStructureField) =>
          match psTsEmitType field.type with
          | Except.error error => Except.error error
          | Except.ok type =>
              Except.ok
                (psTsJoin "" ["readonly ", field.name, ": ", type, ";"]);
      match psListMapExcept printField structureInfo.fields with
      | Except.error error => Except.error error
      | Except.ok fields =>
          let generic :=
            psTsGenericNames structureInfo.typeParameters;
          let brandLine := psTsJoin "" ["const ", brand, ": unique symbol = Symbol(", psJsonQuote (psTsJoin "" ["ProofScript.", structureInfo.name]), ");"];
          let interfaceLine := psTsJoin "" ["export interface ", structureInfo.name, generic, " { readonly [", brand, "]: true; ", psTsJoin " " fields, " }"];
          Except.ok [brandLine, interfaceLine]

def psTsEmitConstructorVariant
    (tag : String)
    (constructorInfo : PsVerifiedIrConstructor) :
    Except PsTsEmitError String :=
  let printField : PsVerifiedIrConstructorField -> Except PsTsEmitError String :=
    fun (field : PsVerifiedIrConstructorField) =>
      match psTsEmitType field.type with
      | Except.error error => Except.error error
      | Except.ok type =>
          Except.ok
            (psTsJoin "" ["readonly ", field.name, ": ", type, ";"]);
  match psListMapExcept printField constructorInfo.fields with
  | Except.error error => Except.error error
  | Except.ok fields =>
      Except.ok
        (psTsJoin "" ["{ readonly [", tag, "]: ", psJsonQuote constructorInfo.name, "; ", psTsJoin " " fields, " }"])

def psTsEmitConstructorValue
    (tag : String)
    (inductiveInfo : PsVerifiedIrInductive)
    (constructorInfo : PsVerifiedIrConstructor) :
    Except PsTsEmitError String :=
  let generic := psTsGenericNames inductiveInfo.typeParameters;
  let resultType := psTsJoin "" [inductiveInfo.name, generic];
  if if psListIsEmpty inductiveInfo.typeParameters then psListIsEmpty constructorInfo.fields else false then
    Except.ok
      (psTsJoin "" ["  ", psJsonQuote constructorInfo.name, ": { [", tag, "]: ", psJsonQuote constructorInfo.name, " } as ", resultType, ","])
  else
    let printParameter : PsVerifiedIrConstructorField -> Except PsTsEmitError String :=
      fun (field : PsVerifiedIrConstructorField) =>
        match psTsEmitType field.type with
        | Except.error error => Except.error error
        | Except.ok type =>
            Except.ok type;
    match psListMapExcept printParameter constructorInfo.fields with
    | Except.error error => Except.error error
    | Except.ok fieldTypes =>
        let parameterNames := psTsNameSequence "__field" (psListLength constructorInfo.fields) 0;
        let formatParameter : (String × String) -> String :=
          fun (entry : String × String) =>
            match entry with
            | Prod.mk name type => psTsJoin "" [name, ": ", type];
        let parameters := psListMap formatParameter (psListZip parameterNames fieldTypes);
        let formatField : (PsVerifiedIrConstructorField × String) -> String :=
          fun (entry : PsVerifiedIrConstructorField × String) =>
            match entry with
            | Prod.mk field name => psTsJoin "" [field.name, ": ", name];
        let fields := psListMap formatField (psListZip constructorInfo.fields parameterNames);
        let suffix :=
          if psListIsEmpty fields then ""
          else psTsJoin "" [", ", psTsJoin ", " fields];
        Except.ok
          (psTsJoin "" ["  ", psJsonQuote constructorInfo.name, ": ", generic, "(", psTsJoin ", " parameters, "): ", resultType, " => ({ [", tag, "]: ", psJsonQuote constructorInfo.name, suffix, " } as ", resultType, "),"])

def psTsEmitInductive
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
              let typeLine :=
                if psListIsEmpty variants then
                  psTsJoin "" ["export type ", inductiveInfo.name, generic, " = never;"]
                else
                  psTsJoin "" ["export type ", inductiveInfo.name, generic, " =\n  | ", psTsJoin "\n  | " variants, ";"];
              let tagLine := psTsJoin "" ["const ", tag, ": unique symbol = Symbol(", psJsonQuote (psTsJoin "" ["ProofScript.", inductiveInfo.name, ".tag"]), ");"];
              let exportLine := psTsJoin "" ["export const ", inductiveInfo.name, " = {"];
              Except.ok (psTsAppendLines [tagLine, typeLine, exportLine] (psTsAppendLines constructorValues ["} as const;"]))

def psTsEmitImport (item : PsVerifiedIrExternalImport) : String :=
  let alias := if psStringEq item.importedName item.localName then ""
    else String.Internal.append " as " item.localName;
  psTsJoin "" ["import { ", item.importedName, alias, " } from ", psJsonQuote item.source, ";"]


-- Each recursive call suspends its generator; the host loop owns the work stack.
-- Public functions remain synchronous and retain their ordinary TypeScript types.
def psTsStackRuntimeSupport : String :=
  "type __ps$Request = { readonly fn: Function; readonly args: unknown[] };\ntype __ps$Computation<R> = Generator<__ps$Request, R, unknown>;\nconst __ps$implementations = new WeakMap<Function, Function>();\nfunction __ps$run<R>(root: __ps$Computation<R>): R {\n  const pending: __ps$Computation<unknown>[] = [root];\n  let value: unknown = undefined;\n  while (pending.length !== 0) {\n    const next = pending[pending.length - 1].next(value);\n    if (next.done) { pending.pop(); value = next.value; }\n    else {\n      const { fn, args } = next.value;\n      const implementation = __ps$implementations.get(fn);\n      if (implementation) { pending.push(Reflect.apply(implementation, undefined, args)); value = undefined; }\n      else value = Reflect.apply(fn, undefined, args);\n    }\n  }\n  return value as R;\n}\nfunction __ps$wrap<A extends unknown[], R>(implementation: (...args: A) => __ps$Computation<R>): (...args: A) => R {\n  const fn = (...args: A): R => __ps$run(implementation(...args));\n  __ps$implementations.set(fn, implementation);\n  return fn;\n}\nfunction* __ps$invoke<A extends unknown[], R>(fn: (...args: A) => R, ...args: A): __ps$Computation<R> {\n  return (yield { fn, args }) as R;\n}"

-- Cache two immutable strings so pairwise comparisons reuse both byte indexes.
-- Retention is bounded; character access remains exact at UTF-8 boundaries.
def psTsUtf8RuntimeSupport : String :=
  "type __ps$Utf8View = { readonly text: string; readonly size: bigint; readonly positions: Uint32Array };\nlet __ps$lastUtf8: __ps$Utf8View | undefined;\nlet __ps$previousUtf8: __ps$Utf8View | undefined;\nfunction __ps$utf8Width(code: number): number { return code <= 0x7f ? 1 : code <= 0x7ff ? 2 : code <= 0xffff ? 3 : 4; }\nfunction __ps$utf8(text: string): __ps$Utf8View {\n  if (__ps$lastUtf8?.text === text) return __ps$lastUtf8;\n  if (__ps$previousUtf8?.text === text) return __ps$previousUtf8;\n  let size = 0;\n  for (const char of text) size += __ps$utf8Width(char.codePointAt(0) ?? 0);\n  const positions = new Uint32Array(size + 1);\n  let byte = 0, index = 0;\n  for (const char of text) {\n    positions[byte] = index + 1;\n    const __ps_w = __ps$utf8Width(char.codePointAt(0) ?? 0);\n    byte += __ps_w; index += char.length;\n  }\n  positions[size] = text.length + 1;\n  __ps$previousUtf8 = __ps$lastUtf8;\n  return __ps$lastUtf8 = { text, size: BigInt(size), positions };\n}\nfunction __ps$stringGet(text: string, position: bigint): string {\n  const view = __ps$utf8(text);\n  if (position < 0n || position >= view.size) return \"A\";\n  const index = view.positions[Number(position)];\n  return index === 0 ? \"A\" : String.fromCodePoint(text.codePointAt(index - 1) ?? 65);\n}\nfunction __ps$stringNext(text: string, position: bigint): bigint {\n  const view = __ps$utf8(text);\n  if (position < 0n || position >= view.size) return position + 1n;\n  const index = view.positions[Number(position)];\n  return index === 0 ? position + 1n : position + BigInt(__ps$utf8Width(text.codePointAt(index - 1) ?? 0));\n}"

def psTsRuntimeSupport : String :=
  psTsJoin "\n" [psTsStackRuntimeSupport, psTsUtf8RuntimeSupport]

def psTsEmitDeclarationGeneral
    (brands : List (String × String))
    (tags : List (String × String))
    (declaration : PsVerifiedIrDeclaration) :
    Except PsTsEmitError String :=
  let generic := psTsGenericNames declaration.typeParameters;
  match psTsEmitType declaration.resultType with
  | Except.error error => Except.error error
  | Except.ok resultType =>
      match psTsEmitExpr brands tags (psTsInlineEtaApplication declaration.body) with
      | Except.error error => Except.error error
      | Except.ok body =>
          if psListIsEmpty declaration.parameters then
            if psListIsEmpty declaration.typeParameters then
              Except.ok
                (psTsJoin "" ["export const ", declaration.name, ": ", resultType, " = __ps$run((function*(): __ps$Computation<", resultType, "> { return ", body, "; })());"])
            else
              Except.error
                (PsTsEmitError.genericValueUnsupported declaration.name)
          else
            let printParameter : PsVerifiedIrParameter -> Except PsTsEmitError String :=
              fun (parameter : PsVerifiedIrParameter) =>
                match psTsEmitType parameter.type with
                | Except.error error => Except.error error
                | Except.ok type =>
                    Except.ok
                      (psTsJoin "" [parameter.name, ": ", type]);
            match psListMapExcept printParameter declaration.parameters with
            | Except.error error => Except.error error
            | Except.ok parameters =>
                let parameterName : PsVerifiedIrParameter -> String :=
                  fun (parameter : PsVerifiedIrParameter) => parameter.name;
                let arguments := psTsJoin ", " (psListMap parameterName declaration.parameters);
                let implementation := String.Internal.append "__ps$impl$" declaration.name;
                Except.ok
                  (psTsJoin "" ["export function ", declaration.name, generic, "(", psTsJoin ", " parameters, "): ", resultType, " { return __ps$run(", implementation, generic, "(", arguments, ")); }\nfunction* ", implementation, generic, "(", psTsJoin ", " parameters, "): __ps$Computation<", resultType, "> { return ", body, "; }\n__ps$implementations.set(", declaration.name, ", ", implementation, ");"])

def psTsEmitCountCases (tag : String) (name : String)
    (base step : Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr)) : Option String :=
  if psTsCountLiteral 0 (Prod.snd (Prod.snd base)) then
    match psTsCountStepArgument name (Prod.snd (Prod.snd step)) with
    | Option.none => Option.none
    | Option.some localName =>
        match psTsCountField localName (Prod.fst (Prod.snd step)) with
        | Option.none => Option.none
        | Option.some field =>
            Option.some (psTsJoin "" ["let __ps$count = 0n; for (;;) { switch (__ps$cursor[", tag,
              "]) { case ", psJsonQuote (Prod.fst base), ": return __ps$count; case ", psJsonQuote (Prod.fst step),
              ": __ps$cursor = __ps$cursor.", field, "; __ps$count += 1n; break; default: throw new Error(\"invalid ProofScript constructor tag\"); } }"])
  else Option.none

def psTsEmitCountLoop (tags : List (Prod String String)) (declaration : PsVerifiedIrDeclaration) : Option String :=
  match declaration.resultType with
  | PsVerifiedIrType.primitive primitive =>
      match primitive with
      | PsVerifiedIrPrimitiveType.nat =>
          match declaration.parameters with
          | List.cons parameter rest =>
              if psListIsEmpty rest then
                match declaration.body with
                | PsVerifiedIrExpr.matchE name _ scrutinee alternatives =>
                    match scrutinee with
                    | PsVerifiedIrExpr.var localName =>
                        if psStringEq localName parameter.name then
                          match psTsLookup tags name with
                          | Option.none => Option.none
                          | Option.some tag =>
                              match alternatives with
                              | List.cons first remaining =>
                                  match remaining with
                                  | List.cons second tail =>
                                      if psListIsEmpty tail then
                                        let cases : Option String := match psTsEmitCountCases tag declaration.name first second with
                                          | Option.some printed => Option.some printed
                                          | Option.none => psTsEmitCountCases tag declaration.name second first;
                                        match cases with
                                        | Option.none => Option.none
                                        | Option.some printed =>
                                            match psTsEmitType parameter.type with
                                            | Except.error _ => Option.none
                                            | Except.ok type =>
                                                Option.some (psTsJoin "" ["export function ", declaration.name,
                                                  psTsGenericNames declaration.typeParameters, "(", parameter.name, ": ", type,
                                                  "): bigint { let __ps$cursor = ", parameter.name, "; ", printed, " }"])
                                      else Option.none
                                  | _ => Option.none
                              | _ => Option.none
                        else Option.none
                    | _ => Option.none
                | _ => Option.none
              else Option.none
          | _ => Option.none
      | _ => Option.none
  | _ => Option.none

def psTsTailPrintPure (brands tags : List (Prod String String)) (aliases : List PsTsTailAlias) (expr : PsVerifiedIrExpr) : Option String :=
  if psTsTailPureWithFuel aliases 4096 expr then
    match psTsEmitExpr brands tags expr with
    | Except.error _ => Option.none
    | Except.ok printed => Option.some printed
  else Option.none

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

def psTsEmitTailLoop (brands tags : List (Prod String String)) (declaration : PsVerifiedIrDeclaration) : Option String :=
  if psListIsEmpty declaration.typeParameters then
    if psListIsEmpty declaration.parameters then Option.none
    else
      let body := psTsInlineEtaApplication declaration.body;
      match psTsTailEmitWithFuel brands tags declaration 4096 List.nil body with
      | Option.none => Option.none
      | Option.some printedBody =>
          let printParameter : PsVerifiedIrParameter -> Option String := fun (parameter : PsVerifiedIrParameter) =>
            match psTsEmitType parameter.type with
            | Except.error _ => Option.none
            | Except.ok type => Option.some (psTsJoin "" [parameter.name, ": ", type]);
          match psTsTailMap printParameter declaration.parameters with
          | Option.none => Option.none
          | Option.some parameters =>
              match psTsEmitType declaration.resultType with
              | Except.error _ => Option.none
              | Except.ok resultType => Option.some (psTsJoin "" ["export function ", declaration.name, "(",
                  psTsJoin ", " parameters, "): ", resultType, " { while (true) { ", printedBody, " } }"])
  else Option.none


def psTsEmitDeclaration (brands tags : List (Prod String String))
    (declaration : PsVerifiedIrDeclaration) : Except PsTsEmitError String :=
  match psTsEmitCountLoop tags declaration with
  | Option.some loop => Except.ok loop
  | Option.none =>
      match psTsEmitTailLoop brands tags declaration with
      | Option.some loop => Except.ok loop
      | Option.none => psTsEmitDeclarationGeneral brands tags declaration

def psTsFlattenLines (groups : List (List String)) : List String :=
  match groups with
  | List.nil => List.nil
  | List.cons lines rest => psTsAppendLines lines (psTsFlattenLines rest)

def psTsEmitNamedModule
    (module : PsVerifiedIrModule) :
    Except PsTsEmitError String :=
  let brands := psTsBuildBrandMap module;
  let tags := psTsBuildTagMap module;
  match psListMapExcept (psTsEmitStructure brands) module.structures with
  | Except.error error => Except.error error
  | Except.ok structures =>
      match psListMapExcept (psTsEmitInductive tags) module.inductives with
      | Except.error error => Except.error error
      | Except.ok inductives =>
          match psListMapExcept (psTsEmitDeclaration brands tags) module.declarations with
          | Except.error error => Except.error error
          | Except.ok declarations => do
              let docs ← (PsEcma.utf8CodecRuntime.mapM (PsEcma.stmtDoc .typescript 4096)).mapError
                (fun _ => PsTsEmitError.intrinsicArity)
              let codec ← (psRenderDoc (psDocJoin .hardline docs)).mapError
                (fun _ => PsTsEmitError.intrinsicArity)
              let header : List String := ["// generated from ProofScript runtime IR; kernel provenance belongs to the caller", psTsRuntimeSupport, codec.text];
              let lines := psTsFlattenLines [header, psListMap psTsEmitImport module.imports, psTsFlattenLines structures, psTsFlattenLines inductives, declarations];
              Except.ok (psTsJoin "" [psTsJoin "\n" lines, "\n"])

-- Raw lowering API: naming is still required for all callers. Provider
-- acceptance belongs to the host; the checked entry owns IR validation.
def psTsEmitModule (ir : PsVerifiedIrModule) : Except PsTsEmitError String := do
  let (view, _) ← (psCodegenNamesFor ir psTsReservedNames).mapError (fun _ => .fuelExhausted)
  psTsEmitNamedModule view
