import Ps.BackendTs.Checked

-- A bounded first-order library ABI. Preparation and runtime IR typing are
-- separate from host-owned kernel admission. No plugin can manufacture the
-- host's accepted-project handle from this serializable description.
inductive PsCompilerCheckedTypeScriptProjectError where
  | compiler (error : PsCompilerError)
  | check (report : PsIrCheckReport)
  | emit (error : PsTsEmitError)
  | abi (detail : String)

structure PsTsProjectBinding where
  sourceId : String
  name : PsName
  runtimeName : String
  binding : String
  typeOnly : Bool
  sourceArity : Nat
  coreType : PsExpr

structure PsTsProjectBindingState where
  used : List String
  nextIndex : Nat
  bindingsRev : List PsTsProjectBinding

structure PsTsProjectOpaqueType where
  binding : PsTsProjectBinding
  brand : String
  inputs : String
  outputs : String
  pack : String
  unpack : String

structure PsTsProjectOpaqueState where
  used : List String
  nextIndex : Nat
  typesRev : List PsTsProjectOpaqueType

structure PsTsProjectSignature where
  parameters : List PsVerifiedIrType
  result : PsVerifiedIrType

def psTsProjectFindDeclaration (declarations : List PsDeclaration) :
    PsName -> Option PsDeclaration :=
  match declarations with
  | List.nil => fun (_name : PsName) => Option.none
  | List.cons declaration rest =>
      let smaller : PsName -> Option PsDeclaration := psTsProjectFindDeclaration rest;
      fun (name : PsName) =>
        if psNameEq (psDeclarationName declaration) name then Option.some declaration
        else smaller name

def psTsProjectRuntimeName (names : List (Prod PsName String)) :
    PsName -> Option String :=
  match names with
  | List.nil => fun (_name : PsName) => Option.none
  | List.cons entry rest =>
      let smaller : PsName -> Option String := psTsProjectRuntimeName rest;
      fun (name : PsName) =>
        if psNameEq (Prod.fst entry) name then Option.some (Prod.snd entry)
        else smaller name

def psTsProjectFindRuntimeDeclaration (declarations : List PsVerifiedIrDeclaration) :
    String -> Option PsVerifiedIrDeclaration :=
  match declarations with
  | List.nil => fun (_name : String) => Option.none
  | List.cons declaration rest =>
      let smaller : String -> Option PsVerifiedIrDeclaration := psTsProjectFindRuntimeDeclaration rest;
      fun (name : String) =>
        if psStringEq declaration.name name then Option.some declaration
        else smaller name

def psTsProjectRuntimeTypeExists (ir : PsVerifiedIrModule) (name : String) : Bool :=
  let structureMatches : PsVerifiedIrStructure -> Bool :=
    fun (info : PsVerifiedIrStructure) =>
      if psStringEq info.name name then psListIsEmpty info.typeParameters else false;
  let inductiveMatches : PsVerifiedIrInductive -> Bool :=
    fun (info : PsVerifiedIrInductive) =>
      if psStringEq info.name name then psListIsEmpty info.typeParameters else false;
  if psListAny structureMatches ir.structures then true
  else psListAny inductiveMatches ir.inductives

def psTsProjectAuthoredArity (arities : List (Prod PsName Nat)) :
    PsName -> Option Nat :=
  match arities with
  | List.nil => fun (_name : PsName) => Option.none
  | List.cons entry rest =>
      let smaller : PsName -> Option Nat := psTsProjectAuthoredArity rest;
      fun (name : PsName) =>
        if psNameEq (Prod.fst entry) name then Option.some (Prod.snd entry) else smaller name

def psTsProjectBuildOwnerBindings
    (declarations : List PsDeclaration) (lowered : PsErasedNamedModule)
    (sourceId : String) (arities : List (Prod PsName Nat)) (names : List PsName)
    (state : PsTsProjectBindingState) :
    Except PsCompilerCheckedTypeScriptProjectError PsTsProjectBindingState :=
  match names with
  | List.nil => Except.ok state
  | List.cons name rest =>
      let failure := PsCompilerCheckedTypeScriptProjectError.abi (psNameToString name);
      match psTsProjectRuntimeName lowered.names name with
      | Option.none => Except.error failure
      | Option.some runtimeName =>
          match psTsProjectFindDeclaration declarations name with
          | Option.none => Except.error failure
          | Option.some declaration =>
              let shape : Option (Prod Bool PsExpr) :=
                match declaration with
                | PsDeclaration.definitionDecl _ levels type _ =>
                    if psListIsEmpty levels then Option.some (Prod.mk false type) else Option.none
                | PsDeclaration.inductiveDecl info =>
                    if psListIsEmpty info.levelParams then
                      if Nat.beq info.numParams 0 then
                        if Nat.beq info.numIndices 0 then
                          if psTsProjectRuntimeTypeExists lowered.ir runtimeName then
                            Option.some (Prod.mk true info.type)
                          else Option.none
                        else Option.none
                      else Option.none
                    else Option.none
                | _ => Option.none;
              match shape with
              | Option.none => Except.error failure
              | Option.some selected =>
                  let sourceArity := if Prod.fst selected then Option.some 0 else psTsProjectAuthoredArity arities name;
                  match sourceArity with
                  | Option.none => Except.error failure
                  | Option.some arity =>
                      let fresh := psTsFreshInternal state.used "__ps$public$" state.nextIndex;
                      let collision : String -> Bool := fun (used : String) => psStringEq used fresh.name;
                      if psListAny collision state.used then Except.error failure
                      else
                        let binding := PsTsProjectBinding.mk sourceId name runtimeName fresh.name
                          (Prod.fst selected) arity (Prod.snd selected);
                        psTsProjectBuildOwnerBindings declarations lowered sourceId arities rest
                          (PsTsProjectBindingState.mk (List.cons fresh.name state.used)
                            fresh.nextIndex (List.cons binding state.bindingsRev))

def psTsProjectBuildBindings
    (declarations : List PsDeclaration) (lowered : PsErasedNamedModule)
    (owners : List PsCompilerProjectOwner)
    (state : PsTsProjectBindingState) :
    Except PsCompilerCheckedTypeScriptProjectError PsTsProjectBindingState :=
  match owners with
  | List.nil => Except.ok state
  | List.cons owner rest =>
      match psTsProjectBuildOwnerBindings declarations lowered owner.sourceId owner.arities owner.exports state with
      | Except.error error => Except.error error
      | Except.ok next => psTsProjectBuildBindings declarations lowered rest next

def psTsProjectNamesDistinct (names : List String) : Bool :=
  match names with
  | List.nil => true
  | List.cons name rest =>
      if psErasureStringInList rest name then false else psTsProjectNamesDistinct rest

def psTsProjectBuildOpaqueTypes
    (bindings : List PsTsProjectBinding) (state : PsTsProjectOpaqueState) :
    Except PsCompilerCheckedTypeScriptProjectError PsTsProjectOpaqueState :=
  match bindings with
  | List.nil => Except.ok state
  | List.cons binding rest =>
      if binding.typeOnly then
        let brand := psTsFreshInternal state.used "__ps$opaque$" state.nextIndex;
        let used1 := List.cons brand.name state.used;
        let inputs := psTsFreshInternal used1 "__ps$opaque$" brand.nextIndex;
        let used2 := List.cons inputs.name used1;
        let outputs := psTsFreshInternal used2 "__ps$opaque$" inputs.nextIndex;
        let used3 := List.cons outputs.name used2;
        let pack := psTsFreshInternal used3 "__ps$opaque$" outputs.nextIndex;
        let used4 := List.cons pack.name used3;
        let unpack := psTsFreshInternal used4 "__ps$opaque$" pack.nextIndex;
        let names := [brand.name, inputs.name, outputs.name, pack.name, unpack.name];
        let distinct : String -> Bool :=
          fun (name : String) => if psErasureStringInList state.used name then false else true;
        let conflict := psListAny (fun (name : String) => if distinct name then false else true) names;
        if if conflict then true else if psTsProjectNamesDistinct names then false else true then
          Except.error (PsCompilerCheckedTypeScriptProjectError.abi "opaque name allocation")
        else
          let opaqueType := PsTsProjectOpaqueType.mk binding brand.name inputs.name outputs.name pack.name unpack.name;
          psTsProjectBuildOpaqueTypes rest
            (PsTsProjectOpaqueState.mk (List.cons unpack.name used4) unpack.nextIndex
              (List.cons opaqueType state.typesRev))
      else psTsProjectBuildOpaqueTypes rest state

def psTsProjectFindOpaque (types : List PsTsProjectOpaqueType) :
    String -> Option PsTsProjectOpaqueType :=
  match types with
  | List.nil => fun (_name : String) => Option.none
  | List.cons type rest =>
      let smaller : String -> Option PsTsProjectOpaqueType := psTsProjectFindOpaque rest;
      fun (name : String) =>
        if psStringEq type.binding.runtimeName name then Option.some type else smaller name

def psTsProjectFindCoreType (bindings : List PsTsProjectBinding) :
    PsName -> Option String :=
  match bindings with
  | List.nil => fun (_name : PsName) => Option.none
  | List.cons binding rest =>
      let smaller : PsName -> Option String := psTsProjectFindCoreType rest;
      fun (name : PsName) =>
        if binding.typeOnly then
          if psNameEq binding.name name then Option.some binding.runtimeName else smaller name
        else smaller name

-- Inspect the original Core type. A proof premise or dependent binder cannot
-- disappear through erasure and become an unchecked foreign call.
def psTsProjectCoreValueType
    (bindings : List PsTsProjectBinding) (type : PsExpr) :
    Except PsCompilerCheckedTypeScriptProjectError PsVerifiedIrType :=
  let failure := PsCompilerCheckedTypeScriptProjectError.abi "unsupported public value type";
  match type with
  | PsExpr.constE name levels =>
      if psListIsEmpty levels then
        if psNameEq name psNatName then Except.ok (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
        else if psNameEq name psIntName then Except.ok (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int)
        else if psNameEq name psBoolName then Except.ok (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool)
        else if psNameEq name psStringName then Except.ok (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.string)
        else if psNameEq name psUnitName then Except.ok (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.unit)
        else
          match psTsProjectFindCoreType bindings name with
          | Option.none => Except.error failure
          | Option.some runtimeName => Except.ok (PsVerifiedIrType.named runtimeName List.nil)
      else Except.error failure
  | _ => Except.error failure

def psTsProjectCoreSignature
    (bindings : List PsTsProjectBinding) (type : PsExpr) :
    Except PsCompilerCheckedTypeScriptProjectError PsTsProjectSignature :=
  match type with
  | PsExpr.forallE _ domain body binder =>
      match binder with
      | PsBinderInfo.explicit =>
          match psTsProjectCoreValueType bindings domain with
          | Except.error error => Except.error error
          | Except.ok parameter =>
              match psTsProjectCoreSignature bindings body with
              | Except.error error => Except.error error
              | Except.ok signature =>
                  Except.ok (PsTsProjectSignature.mk (List.cons parameter signature.parameters) signature.result)
      | _ => Except.error (PsCompilerCheckedTypeScriptProjectError.abi "implicit public binder")
  | _ =>
      match psTsProjectCoreValueType bindings type with
      | Except.error error => Except.error error
      | Except.ok result => Except.ok (PsTsProjectSignature.mk List.nil result)

def psTsProjectIrTypeEqual (left right : PsVerifiedIrType) : Bool :=
  match psIrCheckTypeEqual 4096 left right with
  | Except.error _ => false
  | Except.ok equal => equal

def psTsProjectParametersAgree (expected : List PsVerifiedIrType) :
    List PsVerifiedIrParameter -> Bool :=
  match expected with
  | List.nil => fun (actual : List PsVerifiedIrParameter) => psListIsEmpty actual
  | List.cons type rest =>
      let smaller : List PsVerifiedIrParameter -> Bool := psTsProjectParametersAgree rest;
      fun (actual : List PsVerifiedIrParameter) =>
        match actual with
        | List.nil => false
        | List.cons parameter tail =>
            if psTsProjectIrTypeEqual type parameter.type then smaller tail else false

def psTsProjectPublicType (types : List PsTsProjectOpaqueType)
    (type : PsVerifiedIrType) : Except PsCompilerCheckedTypeScriptProjectError String :=
  match type with
  | PsVerifiedIrType.primitive primitive =>
      match primitive with
      | PsVerifiedIrPrimitiveType.nat => Except.ok "bigint"
      | PsVerifiedIrPrimitiveType.int => Except.ok "bigint"
      | PsVerifiedIrPrimitiveType.bool => Except.ok "boolean"
      | PsVerifiedIrPrimitiveType.string => Except.ok "string"
      | PsVerifiedIrPrimitiveType.unit => Except.ok "undefined"
      | _ => Except.error (PsCompilerCheckedTypeScriptProjectError.abi "unsupported primitive")
  | PsVerifiedIrType.named name arguments =>
      if psListIsEmpty arguments then
        match psTsProjectFindOpaque types name with
        | Option.none => Except.error (PsCompilerCheckedTypeScriptProjectError.abi name)
        | Option.some opaqueType => Except.ok opaqueType.binding.binding
      else Except.error (PsCompilerCheckedTypeScriptProjectError.abi name)
  | _ => Except.error (PsCompilerCheckedTypeScriptProjectError.abi "unsupported runtime public type")

def psTsProjectPrimitiveGuard (primitive : PsVerifiedIrPrimitiveType) (name : String) : String :=
  match primitive with
  | PsVerifiedIrPrimitiveType.nat => psTsJoin "" ["typeof ", name, " !== \"bigint\" || ", name, " < 0n"]
  | PsVerifiedIrPrimitiveType.int => psTsJoin "" ["typeof ", name, " !== \"bigint\""]
  | PsVerifiedIrPrimitiveType.bool => psTsJoin "" ["typeof ", name, " !== \"boolean\""]
  | PsVerifiedIrPrimitiveType.string =>
      psTsJoin "" ["typeof ", name, " !== \"string\" || /[\\uD800-\\uDFFF]/u.test(", name, ")"]
  | PsVerifiedIrPrimitiveType.unit => psTsJoin "" [name, " !== undefined"]
  | _ => "true"

def psTsProjectGuard (type : PsVerifiedIrType) (name : String) : String :=
  match type with
  | PsVerifiedIrType.primitive primitive =>
      psTsJoin "" ["if (", psTsProjectPrimitiveGuard primitive name,
        ") throw new TypeError(\"PSC_PUBLIC_ABI_VALUE\"); "]
  | _ => ""

def psTsProjectConvert (types : List PsTsProjectOpaqueType)
    (incoming : Bool) (type : PsVerifiedIrType) (name : String) :
    Except PsCompilerCheckedTypeScriptProjectError String :=
  match type with
  | PsVerifiedIrType.primitive _ => Except.ok name
  | PsVerifiedIrType.named runtimeName arguments =>
      if psListIsEmpty arguments then
        match psTsProjectFindOpaque types runtimeName with
        | Option.none => Except.error (PsCompilerCheckedTypeScriptProjectError.abi runtimeName)
        | Option.some opaqueType =>
            let convert := if incoming then opaqueType.unpack else opaqueType.pack;
            Except.ok (psTsJoin "" [convert, "(", name, ")"])
      else Except.error (PsCompilerCheckedTypeScriptProjectError.abi runtimeName)
  | _ => Except.error (PsCompilerCheckedTypeScriptProjectError.abi "unsupported public conversion")

def psTsProjectEmitOpaque (opaqueType : PsTsProjectOpaqueType) : String :=
  psTsJoin "\n"
    [psTsJoin "" ["const ", opaqueType.brand, ": unique symbol = Symbol(", psJsonQuote (psNameToString opaqueType.binding.name), ");"],
     psTsJoin "" ["export interface ", opaqueType.binding.binding, " { readonly [", opaqueType.brand, "]: true; }"],
     psTsJoin "" ["const ", opaqueType.inputs, " = new WeakMap<", opaqueType.binding.binding, ", ", opaqueType.binding.runtimeName, ">();"],
     psTsJoin "" ["const ", opaqueType.outputs, " = new WeakMap<", opaqueType.binding.runtimeName, ", ", opaqueType.binding.binding, ">();"],
     psTsJoin "" ["function ", opaqueType.unpack, "(value: ", opaqueType.binding.binding, "): ", opaqueType.binding.runtimeName,
       " { const raw = ", opaqueType.inputs, ".get(value); if (raw === undefined) throw new TypeError(\"PSC_PUBLIC_ABI_HANDLE\"); return raw; }"],
     psTsJoin "" ["function ", opaqueType.pack, "(value: ", opaqueType.binding.runtimeName, "): ", opaqueType.binding.binding,
       " { const existing = ", opaqueType.outputs, ".get(value); if (existing !== undefined) return existing; const handle = Object.freeze(Object.create(null)) as ",
       opaqueType.binding.binding, "; ", opaqueType.inputs, ".set(handle, value); ", opaqueType.outputs, ".set(value, handle); return handle; }"]]

structure PsTsProjectParameters where
  printed : List String
  guards : List String
  values : List String
  used : List String

def psTsProjectEmitParameters (types : List PsTsProjectOpaqueType)
    (parameters : List PsVerifiedIrType) (used : List String) :
    Except PsCompilerCheckedTypeScriptProjectError PsTsProjectParameters :=
  match parameters with
  | List.nil => Except.ok (PsTsProjectParameters.mk List.nil List.nil List.nil used)
  | List.cons parameter rest =>
      let fresh := psTsFreshInternal used "__ps$argument$" 0;
      if psErasureStringInList used fresh.name then
        Except.error (PsCompilerCheckedTypeScriptProjectError.abi "argument name allocation")
      else
        match psTsProjectPublicType types parameter with
        | Except.error error => Except.error error
        | Except.ok printedType =>
            match psTsProjectConvert types true parameter fresh.name with
            | Except.error error => Except.error error
            | Except.ok value =>
                match psTsProjectEmitParameters types rest (List.cons fresh.name used) with
                | Except.error error => Except.error error
                | Except.ok tail =>
                    Except.ok (PsTsProjectParameters.mk
                      (List.cons (psTsJoin "" [fresh.name, ": ", printedType]) tail.printed)
                      (List.cons (psTsProjectGuard parameter fresh.name) tail.guards)
                      (List.cons value tail.values) tail.used)

def psTsProjectEmitValue
    (ir : PsVerifiedIrModule) (bindings : List PsTsProjectBinding)
    (types : List PsTsProjectOpaqueType) (used : List String)
    (binding : PsTsProjectBinding) :
    Except PsCompilerCheckedTypeScriptProjectError String :=
  let failure := PsCompilerCheckedTypeScriptProjectError.abi (psNameToString binding.name);
  match psTsProjectFindRuntimeDeclaration ir.declarations binding.runtimeName with
  | Option.none => Except.error failure
  | Option.some declaration =>
      if psListIsEmpty declaration.typeParameters then
        match psTsProjectCoreSignature bindings binding.coreType with
        | Except.error error => Except.error error
        | Except.ok signature =>
            let authoredArityAgrees := Nat.beq binding.sourceArity (psListLength signature.parameters);
            if if authoredArityAgrees then psTsProjectParametersAgree signature.parameters declaration.parameters else false then
              if psTsProjectIrTypeEqual signature.result declaration.resultType then
                match psTsProjectEmitParameters types signature.parameters used with
                | Except.error error => Except.error error
                | Except.ok parameters =>
                    match psTsProjectPublicType types signature.result with
                    | Except.error error => Except.error error
                    | Except.ok resultType =>
                        let result := psTsFreshInternal parameters.used "__ps$result$" 0;
                        if psErasureStringInList parameters.used result.name then Except.error failure
                        else
                          match psTsProjectConvert types false signature.result result.name with
                          | Except.error error => Except.error error
                          | Except.ok converted =>
                              let isConstant := psListIsEmpty signature.parameters;
                              let call := if isConstant then binding.runtimeName else
                                psTsJoin "" [binding.runtimeName, "(", psTsJoin ", " parameters.values, ")"];
                              let arity := if isConstant then "" else psTsJoin ""
                                ["if (arguments.length !== ", psNatToString (psListLength signature.parameters),
                                 ") throw new TypeError(\"PSC_PUBLIC_ABI_ARITY\"); "];
                              let body := psTsJoin ""
                                [arity, psTsJoin "" parameters.guards, "const ", result.name, " = ", call, "; ",
                                 psTsProjectGuard signature.result result.name, "return ", converted, ";"];
                              if isConstant then
                                Except.ok (psTsJoin "" ["export const ", binding.binding, ": ", resultType,
                                  " = (() => { ", body, " })();"])
                              else
                                Except.ok (psTsJoin "" ["export function ", binding.binding, "(",
                                  psTsJoin ", " parameters.printed, "): ", resultType, " { ", body, " }"])
              else Except.error failure
            else Except.error failure
      else Except.error failure

def psTsProjectEmitValues
    (ir : PsVerifiedIrModule) (bindings : List PsTsProjectBinding)
    (types : List PsTsProjectOpaqueType) (used : List String)
    (remaining : List PsTsProjectBinding) :
    Except PsCompilerCheckedTypeScriptProjectError (List String) :=
  match remaining with
  | List.nil => Except.ok List.nil
  | List.cons binding rest =>
      if binding.typeOnly then psTsProjectEmitValues ir bindings types used rest
      else
        match psTsProjectEmitValue ir bindings types used binding with
        | Except.error error => Except.error error
        | Except.ok printed =>
            match psTsProjectEmitValues ir bindings types used rest with
            | Except.error error => Except.error error
            | Except.ok tail => Except.ok (List.cons printed tail)

def psTsProjectBindingJson (binding : PsTsProjectBinding) : String :=
  psJsonObject
    [(Prod.mk "binding" (psJsonQuote binding.binding)),
     (Prod.mk "kind" (psJsonQuote (if binding.typeOnly then "type" else "value"))),
     (Prod.mk "name" (psJsonQuote (psNameToString binding.name)))]

def psTsProjectOwnerExportsJson (sourceId : String)
    (bindings : List PsTsProjectBinding) : List String :=
  match bindings with
  | List.nil => List.nil
  | List.cons binding rest =>
      if psStringEq sourceId binding.sourceId then
        List.cons (psTsProjectBindingJson binding) (psTsProjectOwnerExportsJson sourceId rest)
      else psTsProjectOwnerExportsJson sourceId rest

def psTsProjectOwnersJson (bindings : List PsTsProjectBinding)
    (owners : List PsCompilerProjectOwner) : List String :=
  match owners with
  | List.nil => List.nil
  | List.cons owner rest =>
      if psListIsEmpty owner.exports then psTsProjectOwnersJson bindings rest
      else
        List.cons
          (psJsonObject
            [(Prod.mk "exports" (psJsonArray (psTsProjectOwnerExportsJson owner.sourceId bindings))),
             (Prod.mk "sourceId" (psJsonQuote owner.sourceId))])
          (psTsProjectOwnersJson bindings rest)

def psTsProjectEmitCheckedLowered
    (options : PsIrCheckOptions) (project : PsCompilerAdmissionReadyProject)
    (lowered : PsErasedNamedModule) :
    Except PsCompilerCheckedTypeScriptProjectError String :=
  let report := psCheckVerifiedIrModule options lowered.ir;
  if report.accepted then
    if report.traversalComplete then
      if psListIsEmpty lowered.ir.imports then
        match psTsProjectBuildBindings project.prepared.declarations lowered project.owners
            (PsTsProjectBindingState.mk (psTsModuleTopLevelNames lowered.ir) 0 List.nil) with
        | Except.error error => Except.error error
        | Except.ok collected =>
            let bindings := psListReverse collected.bindingsRev;
            match psTsProjectBuildOpaqueTypes bindings
                (PsTsProjectOpaqueState.mk collected.used 0 List.nil) with
            | Except.error error => Except.error error
            | Except.ok opaqueState =>
                let types := psListReverse opaqueState.typesRev;
                match psTsProjectEmitValues lowered.ir bindings types opaqueState.used bindings with
                | Except.error error => Except.error error
                | Except.ok values =>
                    -- Visibility is selected structurally by the emitter.
                    -- Internal constructors/functions never become ESM exports.
                    match psTsEmitModuleWithPrefix "" lowered.ir with
                    | Except.error error => Except.error (PsCompilerCheckedTypeScriptProjectError.emit error)
                    | Except.ok internalModule =>
                        let bundle := psTsJoin "\n"
                          [internalModule, psTsJoin "\n" (psListMap psTsProjectEmitOpaque types),
                           psTsJoin "\n" values, ""];
                        Except.ok
                          (psJsonObject
                            [(Prod.mk "bundle" (psJsonQuote bundle)),
                             (Prod.mk "modules" (psJsonArray (psTsProjectOwnersJson bindings project.owners))),
                             (Prod.mk "profile" (psJsonQuote "psc-ts-library/1"))])
      else Except.error (PsCompilerCheckedTypeScriptProjectError.abi "external runtime imports")
    else Except.error (PsCompilerCheckedTypeScriptProjectError.check report)
  else Except.error (PsCompilerCheckedTypeScriptProjectError.check report)

def psCompilerCheckedTypeScriptProjectFromPrepared
    (options : PsIrCheckOptions) (project : PsCompilerAdmissionReadyProject) :
    Except PsCompilerCheckedTypeScriptProjectError String :=
  match psCompilerEnvironmentFromPrepared project.prepared with
  | Except.error error => Except.error (PsCompilerCheckedTypeScriptProjectError.compiler error)
  | Except.ok environment =>
      match psEraseCoreModuleWithRuntimePreludeAndNames
          environment psSelfHostRuntimePreludeDeclarationsWithProd project.prepared.declarations with
      | Except.error error =>
          Except.error (PsCompilerCheckedTypeScriptProjectError.compiler (PsCompilerError.erasure error))
      | Except.ok lowered => psTsProjectEmitCheckedLowered options project lowered
