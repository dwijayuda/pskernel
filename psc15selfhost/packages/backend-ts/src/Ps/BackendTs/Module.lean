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

-- Cache one immutable string's byte-position index; retaining new source text
-- releases the previous index. Character access remains exact at UTF-8 boundaries.
def psTsUtf8RuntimeSupport : String :=
  "type __ps$Utf8View = { readonly text: string; readonly size: bigint; readonly positions: Uint32Array };\nlet __ps$lastUtf8: __ps$Utf8View | undefined;\nfunction __ps$utf8Width(code: number): number { return code <= 0x7f ? 1 : code <= 0x7ff ? 2 : code <= 0xffff ? 3 : 4; }\nfunction __ps$utf8(text: string): __ps$Utf8View {\n  if (__ps$lastUtf8?.text === text) return __ps$lastUtf8;\n  let size = 0;\n  for (const char of text) size += __ps$utf8Width(char.codePointAt(0) ?? 0);\n  const positions = new Uint32Array(size + 1);\n  let byte = 0, index = 0;\n  for (const char of text) {\n    positions[byte] = index + 1;\n    const __ps_w = __ps$utf8Width(char.codePointAt(0) ?? 0);\n    byte += __ps_w; index += char.length;\n  }\n  positions[size] = text.length + 1;\n  return __ps$lastUtf8 = { text, size: BigInt(size), positions };\n}\nfunction __ps$stringGet(text: string, position: bigint): string {\n  const view = __ps$utf8(text);\n  if (position < 0n || position >= view.size) return \"A\";\n  const index = view.positions[Number(position)];\n  return index === 0 ? \"A\" : String.fromCodePoint(text.codePointAt(index - 1) ?? 65);\n}\nfunction __ps$stringNext(text: string, position: bigint): bigint {\n  const view = __ps$utf8(text);\n  if (position < 0n || position >= view.size) return position + 1n;\n  const index = view.positions[Number(position)];\n  return index === 0 ? position + 1n : position + BigInt(__ps$utf8Width(text.codePointAt(index - 1) ?? 0));\n}"

def psTsRuntimeSupport : String :=
  psTsJoin "\n" [psTsStackRuntimeSupport, psTsUtf8RuntimeSupport]

def psTsEmitDeclaration
    (brands : List (String × String))
    (tags : List (String × String))
    (declaration : PsVerifiedIrDeclaration) :
    Except PsTsEmitError String :=
  let generic := psTsGenericNames declaration.typeParameters;
  match psTsEmitType declaration.resultType with
  | Except.error error => Except.error error
  | Except.ok resultType =>
      match psTsEmitExpr brands tags declaration.body with
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
