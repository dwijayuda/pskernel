import Ps.Environment.StandardInt

-- Authoring support for closed, non-indexed Type-0 Standard data. Source data
-- elaboration keeps its general dependent telescope/positivity machinery.
-- All generated declarations are submitted to the official kernel as usual.
structure PsStandardDataField where
  name : String
  type : PsExpr
  recursive : Bool := false

structure PsStandardDataConstructor where
  name : String
  fields : List PsStandardDataField := []

def psStandardDataBind (fields : List PsStandardDataField) (offset : Nat)
    (body : PsExpr) (lambda : Bool := false) : PsExpr :=
  (fields.zipIdx).foldr (fun (field, index) body =>
    if lambda then psLogicLam (offset + index) field.name field.type body
    else psLogicPi (offset + index) field.name field.type body) body

def psStandardDataDeclarations (name : PsName)
    (constructors : List PsStandardDataConstructor) (isStructure : Bool := false) :
    List PsDeclaration :=
  let family := PsExpr.constE name []
  let names := constructors.map (fun ctor => psNameAppendStr name ctor.name)
  let u := psRootName "u"
  let motive := PsExpr.fvar 0
  let fieldOffset := constructors.length + 1
  let motiveType := psLogicPi fieldOffset "value" family (.sortE (.param u))
  let declarations := constructors.zipIdx |>.map fun (ctor, index) =>
    PsDeclaration.constructorDecl {
      name := psNameAppendStr name ctor.name
      levelParams := []
      type := psStandardDataBind ctor.fields fieldOffset family
      inductiveName := name
      constructorIndex := index
      numParams := 0
      numFields := ctor.fields.length
      recursiveFields := ctor.fields.zipIdx |>.filterMap fun (field, position) =>
        if field.recursive then some position else none }
  let minorTypes := constructors.map fun ctor =>
    let args := (List.range ctor.fields.length).map fun index => PsExpr.fvar (fieldOffset + index)
    let value := psLogicApply (.constE (psNameAppendStr name ctor.name) []) args
    let conclusion := PsExpr.app motive value
    let recursive := ctor.fields.zipIdx |>.filterMap fun (field, index) =>
      if field.recursive then some index else none
    let body := recursive.foldr (fun index body =>
      psLogicPi (fieldOffset + ctor.fields.length + index) ("ih" ++ toString index)
        (.app motive (.fvar (fieldOffset + index))) body) conclusion
    psStandardDataBind ctor.fields fieldOffset body
  let type := psLogicPi fieldOffset "value" family (.app motive (.fvar fieldOffset))
  let type := (minorTypes.zipIdx).foldr (fun (minor, index) body =>
    psLogicPi (1 + index) ("case" ++ toString index) minor body) type
  let recursor := PsDeclaration.recursorDecl {
    name := psNameAppendStr name "rec"
    levelParams := [u]
    type := psLogicPi 0 "motive" motiveType type .implicit
    inductiveNames := [name]
    numParams := 0, numIndices := 0, numMotives := 1, numMinors := constructors.length }
  .inductiveDecl { name, levelParams := [], type := psPreludeTypeType,
      numParams := 0, numIndices := 0, constructors := names, isStructure } ::
    (declarations ++ [recursor])

-- Closed record support uses ordinary projections; all field types are closed.
def psStandardRecordDeclarations (name : PsName)
    (fields : List PsStandardDataField) : List PsDeclaration :=
  psStandardDataDeclarations name [{ name := "mk", fields }] true ++
    (fields.zipIdx).map (fun (field, index) =>
      .definitionDecl (psNameAppendStr name field.name) []
        (psLogicPi 0 "self" (.constE name []) field.type)
        (psLogicLam 0 "self" (.constE name []) (.proj name index (.fvar 0))))

def psStandardDataCase (name : PsName) (constructors : List PsStandardDataConstructor)
    (result value : PsExpr) (offset : Nat) (bodies : List PsExpr) : PsExpr :=
  psLogicApply (.constE (psNameAppendStr name "rec") [.succ .zero])
    ([psLogicLam offset "_" (.constE name []) result] ++
      (constructors.zip bodies).map (fun (ctor, body) =>
        psStandardDataBind ctor.fields offset body true) ++ [value])
