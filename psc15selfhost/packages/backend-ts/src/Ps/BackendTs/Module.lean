import Ps.BackendTs.Expr

structure PsTsFreshNameResult where
  name : String
  nextIndex : Nat

def psTsAppendLines (left : List String) : List String -> List String :=
  match left with
  | List.nil => fun (right : List String) => right
  | List.cons value rest =>
      let smaller : List String -> List String := psTsAppendLines rest;
      fun (right : List String) => List.cons value (smaller right)

def psTsFreshInternalWorker (used : List String) (namePrefix : String) (attempts : Nat) :
    Nat -> PsTsFreshNameResult :=
  match attempts with
  | Nat.zero => fun (index : Nat) => PsTsFreshNameResult.mk (String.Internal.append namePrefix "overflow") (Nat.succ index)
  | Nat.succ remaining =>
      let smaller : Nat -> PsTsFreshNameResult := psTsFreshInternalWorker used namePrefix remaining;
      fun (index : Nat) =>
        let candidate := String.Internal.append namePrefix (psNatToString index);
        let sameName : String -> Bool := fun (name : String) => psStringEq name candidate;
        if psListAny sameName used then smaller (Nat.succ index)
        else PsTsFreshNameResult.mk candidate (Nat.succ index)

def psTsFreshInternalWithFuel (used : List String) (namePrefix : String) (index attempts : Nat) : PsTsFreshNameResult :=
  psTsFreshInternalWorker used namePrefix attempts index

def psTsFreshInternal (used : List String) (namePrefix : String) (index : Nat) : PsTsFreshNameResult :=
  psTsFreshInternalWithFuel used namePrefix index 4096

structure PsTsSymbolMapState where
  used : List String
  nextIndex : Nat
  entriesRev : List (String × String)

def psTsBuildSymbolMap (namePrefix : String) (names : List String) : PsTsSymbolMapState -> PsTsSymbolMapState :=
  match names with
  | List.nil => fun (state : PsTsSymbolMapState) => state
  | List.cons name rest =>
      let smaller : PsTsSymbolMapState -> PsTsSymbolMapState := psTsBuildSymbolMap namePrefix rest;
      fun (state : PsTsSymbolMapState) =>
        let fresh := psTsFreshInternal state.used namePrefix state.nextIndex;
        smaller (PsTsSymbolMapState.mk (List.cons fresh.name state.used) fresh.nextIndex
          (List.cons (Prod.mk name fresh.name) state.entriesRev))

def psTsStructureName (value : PsVerifiedIrStructure) : String := value.name
def psTsInductiveName (value : PsVerifiedIrInductive) : String := value.name
def psTsDeclarationName (value : PsVerifiedIrDeclaration) : String := value.name
def psTsTypeParameterName (value : PsVerifiedIrTypeParameter) : String := value.name

def psTsModuleTopLevelNames (module : PsVerifiedIrModule) : List String :=
  psTsAppendLines (psListMap psTsDeclarationName module.declarations)
    (psTsAppendLines (psListMap psTsStructureName module.structures) (psListMap psTsInductiveName module.inductives))

def psTsBuildBrandMap (module : PsVerifiedIrModule) : List (String × String) :=
  let state := psTsBuildSymbolMap "__ps$brand$" (psListMap psTsStructureName module.structures)
    (PsTsSymbolMapState.mk (psTsModuleTopLevelNames module) 0 List.nil);
  psListReverse state.entriesRev

def psTsBuildTagMap (module : PsVerifiedIrModule) : List (String × String) :=
  let state := psTsBuildSymbolMap "__ps$tag$" (psListMap psTsInductiveName module.inductives)
    (PsTsSymbolMapState.mk (psTsModuleTopLevelNames module) 0 List.nil);
  psListReverse state.entriesRev

def psTsGenericNames (parameters : List PsVerifiedIrTypeParameter) : String :=
  if psListIsEmpty parameters then ""
  else psTsJoin "" ["<", psTsJoin ", " (psListMap psTsTypeParameterName parameters), ">"]

def psTsNameSequence (namePrefix : String) (count : Nat) : Nat -> List String :=
  match count with
  | Nat.zero => fun (_index : Nat) => List.nil
  | Nat.succ remaining =>
      let smaller : Nat -> List String := psTsNameSequence namePrefix remaining;
      fun (index : Nat) => List.cons (String.Internal.append namePrefix (psNatToString index)) (smaller (Nat.succ index))

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
      (psTsJoin "" ["  ", psTsDataPropertyKey constructorInfo.name, ": { [", tag, "]: ", psJsonQuote constructorInfo.name, " } as ", resultType, ","])
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
            | Prod.mk field name => psTsJoin "" [psTsDataPropertyKey field.name, ": ", name];
        let fields := psListMap formatField (psListZip constructorInfo.fields parameterNames);
        let suffix :=
          if psListIsEmpty fields then ""
          else psTsJoin "" [", ", psTsJoin ", " fields];
        Except.ok
          (psTsJoin "" ["  ", psTsDataPropertyKey constructorInfo.name, ": ", generic, "(", psTsJoin ", " parameters, "): ", resultType, " => ({ [", tag, "]: ", psJsonQuote constructorInfo.name, suffix, " } as ", resultType, "),"])

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

-- Eta parameters are already evaluated variables. When none of their names
-- occur in the callee, they can safely pass through its lexical bindings and
-- branches without capturing a name or changing argument evaluation order.
def psTsEtaArgumentsFresh (fn : PsVerifiedIrExpr) (arguments : List PsVerifiedIrExpr) : Bool :=
  match arguments with
  | List.nil => true
  | List.cons argument rest =>
      match argument with
      | PsVerifiedIrExpr.var name =>
          if psTsExprUsesNameWithFuel 4096 fn name then false else psTsEtaArgumentsFresh fn rest
      | _ => false

def psTsEtaBind (parameters : List PsVerifiedIrParameter) : List PsVerifiedIrExpr -> PsVerifiedIrExpr -> Option PsVerifiedIrExpr :=
  match parameters with
  | List.nil => fun (arguments : List PsVerifiedIrExpr) (body : PsVerifiedIrExpr) =>
      if psListIsEmpty arguments then Option.some body else Option.none
  | List.cons parameter rest =>
      let smaller : List PsVerifiedIrExpr -> PsVerifiedIrExpr -> Option PsVerifiedIrExpr := psTsEtaBind rest;
      fun (arguments : List PsVerifiedIrExpr) (body : PsVerifiedIrExpr) =>
        match arguments with
        | List.nil => Option.none
        | List.cons argument tail =>
            match smaller tail body with
            | Option.none => Option.none
            | Option.some inner => Option.some (PsVerifiedIrExpr.letE parameter.name parameter.type argument inner)

def psTsEtaAlternatives (apply : PsVerifiedIrExpr -> Option PsVerifiedIrExpr)
    (alternatives : List (Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr))) :
    Option (List (Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr))) :=
  match alternatives with
  | List.nil => Option.some List.nil
  | List.cons alternative rest =>
      match apply (Prod.snd (Prod.snd alternative)) with
      | Option.none => Option.none
      | Option.some body =>
          match psTsEtaAlternatives apply rest with
          | Option.none => Option.none
          | Option.some tail => Option.some (List.cons (Prod.mk (Prod.fst alternative) (Prod.mk (Prod.fst (Prod.snd alternative)) body)) tail)

def psTsEtaApplyWorker (arguments : List PsVerifiedIrExpr) (fuel : Nat) : PsVerifiedIrExpr -> Option PsVerifiedIrExpr :=
  match fuel with
  | Nat.zero => fun (_fn : PsVerifiedIrExpr) => Option.none
  | Nat.succ remaining =>
      let smaller : PsVerifiedIrExpr -> Option PsVerifiedIrExpr := psTsEtaApplyWorker arguments remaining;
      fun (fn : PsVerifiedIrExpr) =>
        match fn with
        | PsVerifiedIrExpr.lambda parameters _ body => psTsEtaBind parameters arguments body
        | PsVerifiedIrExpr.letE name type value body =>
            match smaller body with
            | Option.none => Option.none
            | Option.some inner => Option.some (PsVerifiedIrExpr.letE name type value inner)
        | PsVerifiedIrExpr.ifE condition left right =>
            match smaller left with
            | Option.none => Option.none
            | Option.some first =>
                match smaller right with
                | Option.none => Option.none
                | Option.some second => Option.some (PsVerifiedIrExpr.ifE condition first second)
        | PsVerifiedIrExpr.matchE name types scrutinee alternatives =>
            match psTsEtaAlternatives smaller alternatives with
            | Option.none => Option.none
            | Option.some branches => Option.some (PsVerifiedIrExpr.matchE name types scrutinee branches)
        | _ => Option.none

def psTsInlineEtaApplication (expr : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  match expr with
  | PsVerifiedIrExpr.call fn types arguments =>
      if psListIsEmpty types then
        if psTsEtaArgumentsFresh fn arguments then
          match psTsEtaApplyWorker arguments 4096 fn with
          | Option.some body => body
          | Option.none => expr
        else expr
      else expr
  | _ => expr

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

-- A zero/successor fold over one recursive field is a count. Emit its exact
-- computation as a loop, avoiding a suspended generator for every list cell.
-- Recognition uses the IR shape, not a source function or inductive name.
def psTsCountLiteral (expected : Nat) (expr : PsVerifiedIrExpr) : Bool :=
  match expr with
  | PsVerifiedIrExpr.literal literal =>
      match literal with
      | PsVerifiedIrLiteral.natural value => Nat.beq expected value
      | _ => false
  | _ => false

def psTsCountRecursiveArgument (name : String) (expr : PsVerifiedIrExpr) : Option String :=
  match expr with
  | PsVerifiedIrExpr.call fn _ args =>
      match fn with
      | PsVerifiedIrExpr.var called =>
          if psStringEq called name then
            match args with
            | List.cons argument rest =>
                if psListIsEmpty rest then
                  match argument with
                  | PsVerifiedIrExpr.var localName => Option.some localName
                  | _ => Option.none
                else Option.none
            | _ => Option.none
          else Option.none
      | _ => Option.none
  | _ => Option.none

def psTsCountStepArgument (name : String) (expr : PsVerifiedIrExpr) : Option String :=
  match expr with
  | PsVerifiedIrExpr.intrinsic operation _ args =>
      match operation with
      | PsVerifiedIrIntrinsic.natAdd =>
          match args with
          | List.cons left rest =>
              match rest with
              | List.cons right tail =>
                  if psListIsEmpty tail then
                    if psTsCountLiteral 1 left then psTsCountRecursiveArgument name right
                    else if psTsCountLiteral 1 right then psTsCountRecursiveArgument name left
                    else Option.none
                  else Option.none
              | _ => Option.none
          | _ => Option.none
      | _ => Option.none
  | _ => Option.none

def psTsCountField (localName : String) (bindings : List PsVerifiedIrMatchBinding) : Option String :=
  match bindings with
  | List.nil => Option.none
  | List.cons binding rest =>
      if psStringEq localName binding.name then Option.some binding.field
      else psTsCountField localName rest

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

-- Closed tail workers need no suspended continuations. This recognizer accepts
-- pure expressions and exact self calls only; all other code uses generators.
structure PsTsTailAlias where
  name : String
  captured : List PsVerifiedIrExpr
  arity : Nat

def psTsTailMap {alpha beta : Type} (convert : alpha -> Option beta) (values : List alpha) : Option (List beta) :=
  match values with
  | List.nil => Option.some List.nil
  | List.cons value rest =>
      match convert value with
      | Option.none => Option.none
      | Option.some result =>
          match psTsTailMap convert rest with
          | Option.none => Option.none
          | Option.some results => Option.some (List.cons result results)

def psTsTailFindAlias (aliases : List PsTsTailAlias) (name : String) : Option PsTsTailAlias :=
  match aliases with
  | List.nil => Option.none
  | List.cons alias rest =>
      if psStringEq alias.name name then Option.some alias else psTsTailFindAlias rest name

def psTsTailParametersMatch (parameters : List PsVerifiedIrParameter) : List PsVerifiedIrExpr -> Bool :=
  match parameters with
  | List.nil => fun (arguments : List PsVerifiedIrExpr) => psListIsEmpty arguments
  | List.cons parameter rest =>
      let smaller : List PsVerifiedIrExpr -> Bool := psTsTailParametersMatch rest;
      fun (arguments : List PsVerifiedIrExpr) =>
        match arguments with
        | List.nil => false
        | List.cons argument tail =>
            match argument with
            | PsVerifiedIrExpr.var name => if psStringEq name parameter.name then smaller tail else false
            | _ => false

def psTsTailAliasPrefix (parameters : List PsVerifiedIrParameter) (arguments : List PsVerifiedIrExpr) : Option (List PsVerifiedIrExpr) :=
  match arguments with
  | List.nil => if psListIsEmpty parameters then Option.some List.nil else Option.none
  | List.cons argument rest =>
      if psTsTailParametersMatch parameters arguments then Option.some List.nil
      else
        match argument with
        | PsVerifiedIrExpr.var name =>
            let shadows : PsVerifiedIrParameter -> Bool := fun (parameter : PsVerifiedIrParameter) => psStringEq parameter.name name;
            if psListAny shadows parameters then Option.none
            else
              match psTsTailAliasPrefix parameters rest with
              | Option.none => Option.none
              | Option.some captured => Option.some (List.cons argument captured)
        | _ => Option.none

def psTsTailAliasValue (self name : String) (value : PsVerifiedIrExpr) : Option PsTsTailAlias :=
  match value with
  | PsVerifiedIrExpr.lambda parameters _ body =>
      match body with
      | PsVerifiedIrExpr.call fn types arguments =>
          if psListIsEmpty types then
            match fn with
            | PsVerifiedIrExpr.var called =>
                if psStringEq called self then
                  let shadows : PsVerifiedIrParameter -> Bool := fun (parameter : PsVerifiedIrParameter) => psStringEq parameter.name self;
                  if psListAny shadows parameters then Option.none
                  else
                    match psTsTailAliasPrefix parameters arguments with
                    | Option.none => Option.none
                    | Option.some captured => Option.some (PsTsTailAlias.mk name captured (psListLength parameters))
                else Option.none
            | _ => Option.none
          else Option.none
      | _ => Option.none
  | _ => Option.none

def psTsTailPureWithFuel (aliases : List PsTsTailAlias) (fuel : Nat) : PsVerifiedIrExpr -> Bool :=
  match fuel with
  | Nat.zero => fun (_expr : PsVerifiedIrExpr) => false
  | Nat.succ remaining =>
      let smaller : PsVerifiedIrExpr -> Bool := psTsTailPureWithFuel aliases remaining;
      fun (expr : PsVerifiedIrExpr) =>
        let impure : PsVerifiedIrExpr -> Bool := fun (value : PsVerifiedIrExpr) => if smaller value then false else true;
        let impureField : Prod String PsVerifiedIrExpr -> Bool := fun (field : Prod String PsVerifiedIrExpr) => impure (Prod.snd field);
        match expr with
        | PsVerifiedIrExpr.literal _ => true
        | PsVerifiedIrExpr.var name =>
            match psTsTailFindAlias aliases name with
            | Option.none => true
            | Option.some _ => false
        | PsVerifiedIrExpr.intrinsic operation _ arguments =>
            match operation with
            | PsVerifiedIrIntrinsic.arrayMap => false
            | PsVerifiedIrIntrinsic.arrayFoldl => false
            | _ => if psListAny impure arguments then false else true
        | PsVerifiedIrExpr.record _ _ fields => if psListAny impureField fields then false else true
        | PsVerifiedIrExpr.constructor _ _ _ fields => if psListAny impureField fields then false else true
        | PsVerifiedIrExpr.projection _ _ target _ => smaller target
        | PsVerifiedIrExpr.ifE condition left right =>
            if smaller condition then if smaller left then smaller right else false else false
        | _ => false

def psTsTailPrintPure (brands tags : List (Prod String String)) (aliases : List PsTsTailAlias) (expr : PsVerifiedIrExpr) : Option String :=
  if psTsTailPureWithFuel aliases 4096 expr then
    match psTsEmitExpr brands tags expr with
    | Except.error _ => Option.none
    | Except.ok printed => Option.some printed
  else Option.none

def psTsTailBindingSafe (declaration : PsVerifiedIrDeclaration) (aliases : List PsTsTailAlias) (name : String) : Bool :=
  let parameterUses : PsVerifiedIrParameter -> Bool := fun (parameter : PsVerifiedIrParameter) => psStringEq parameter.name name;
  let prefixUses : PsVerifiedIrExpr -> Bool := fun (value : PsVerifiedIrExpr) => psTsExprUsesNameWithFuel 4096 value name;
  let aliasUses : PsTsTailAlias -> Bool := fun (alias : PsTsTailAlias) =>
    if psStringEq alias.name name then true else psListAny prefixUses alias.captured;
  if psStringEq declaration.name name then false
  else if psListAny parameterUses declaration.parameters then false
  else if psListAny aliasUses aliases then false
  else true

def psTsTailCallArguments (self : String) (aliases : List PsTsTailAlias)
    (fn : PsVerifiedIrExpr) (arguments : List PsVerifiedIrExpr) : Option (List PsVerifiedIrExpr) :=
  match fn with
  | PsVerifiedIrExpr.var name =>
      if psStringEq name self then Option.some arguments
      else
        match psTsTailFindAlias aliases name with
        | Option.none => Option.none
        | Option.some alias =>
            if Nat.beq alias.arity (psListLength arguments) then Option.some (psListAppend alias.captured arguments)
            else Option.none
  | _ => Option.none

def psTsTailEmitWithFuel (brands tags : List (Prod String String)) (declaration : PsVerifiedIrDeclaration)
    (fuel : Nat) : List PsTsTailAlias -> PsVerifiedIrExpr -> Option String :=
  match fuel with
  | Nat.zero => fun (_aliases : List PsTsTailAlias) (_expr : PsVerifiedIrExpr) => Option.none
  | Nat.succ remaining =>
      let smaller : List PsTsTailAlias -> PsVerifiedIrExpr -> Option String := psTsTailEmitWithFuel brands tags declaration remaining;
      fun (aliases : List PsTsTailAlias) (expr : PsVerifiedIrExpr) =>
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
            if psTsTailBindingSafe declaration aliases name then
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

def psTsEmitModule
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
          | Except.ok declarations =>
              let header : List String := ["// generated from pskernel-admitted ProofScript checked core", psTsRuntimeSupport];
              let lines := psTsFlattenLines [header, psListMap psTsEmitImport module.imports, psTsFlattenLines structures, psTsFlattenLines inductives, declarations];
              Except.ok (psTsJoin "" [psTsJoin "\n" lines, "\n"])

def psTsEmitValidatedModule
    (module : PsValidatedIrModule) :
    Except PsTsEmitError String :=
  psTsEmitModule module.raw
