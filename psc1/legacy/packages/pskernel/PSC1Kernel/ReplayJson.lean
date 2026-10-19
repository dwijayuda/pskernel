import Lean.Data.Json.Parser
import PSC1Kernel.Replay

namespace PSC1Kernel

namespace ReplayJson

open Lean

def jsonWs (c : Char) : Bool :=
  c == ' ' || c == '\n' || c == '\r' || c == '\t'

def skipJsonWs : List Char → List Char
  | c :: rest => if jsonWs c then skipJsonWs rest else c :: rest
  | [] => []

partial def scanJsonStringToken
    (input : List Char) : Except String (String × List Char) := do
  let '"' :: rest := input
    | throw "expected JSON string"
  let rec go
      (pending : List Char)
      (acc : List Char)
      (escaped : Bool) :
      Except String (String × List Char) := do
    match pending with
    | [] => throw "unterminated JSON string"
    | c :: tail =>
        if escaped then
          go tail (c :: acc) false
        else if c == '\\' then
          go tail (c :: acc) true
        else if c == '"' then
          pure (String.ofList ('"' :: acc.reverse ++ ['"']), tail)
        else
          go tail (c :: acc) false
  go rest [] false

def decodedJsonKey (token : String) : Except String String := do
  match Lean.Json.parse token with
  | .ok (.str key) => pure key
  | .ok _ => throw "JSON object key did not decode as a string"
  | .error err => throw ("invalid JSON object key: " ++ err)

mutual

partial def scanJsonValue : List Char → Except String (List Char)
  | input => do
      let input := skipJsonWs input
      match input with
      | [] => throw "unexpected end of JSON input"
      | '{' :: rest => scanJsonObject rest []
      | '[' :: rest => scanJsonArray rest
      | '"' :: _ =>
          let (_, rest) ← scanJsonStringToken input
          pure rest
      | _ =>
          let rec primitive : List Char → List Char
            | [] => []
            | c :: rest =>
                if jsonWs c || c == ',' || c == ']' || c == '}' then
                  c :: rest
                else
                  primitive rest
          pure (primitive input)

partial def scanJsonObject
    (input : List Char)
    (seen : List String) : Except String (List Char) := do
  let input := skipJsonWs input
  match input with
  | '}' :: rest => pure rest
  | _ => do
      let (token, afterKey) ← scanJsonStringToken input
      let key ← decodedJsonKey token
      if seen.any (fun old => old == key) then
        throw ("duplicate JSON object key: " ++ key)
      let afterKey := skipJsonWs afterKey
      let ':' :: afterColon := afterKey
        | throw "expected ':' after JSON object key"
      let afterValue ← scanJsonValue afterColon
      let afterValue := skipJsonWs afterValue
      match afterValue with
      | ',' :: rest => scanJsonObject rest (key :: seen)
      | '}' :: rest => pure rest
      | _ => throw "expected ',' or '}' after JSON object value"

partial def scanJsonArray
    (input : List Char) : Except String (List Char) := do
  let input := skipJsonWs input
  match input with
  | ']' :: rest => pure rest
  | _ => do
      let afterValue ← scanJsonValue input
      let afterValue := skipJsonWs afterValue
      match afterValue with
      | ',' :: rest => scanJsonArray rest
      | ']' :: rest => pure rest
      | _ => throw "expected ',' or ']' after JSON array value"

end

def validateNoDuplicateJsonKeys (raw : String) : Except String Unit := do
  let rest ← scanJsonValue raw.toList
  unless (skipJsonWs rest).isEmpty do
    throw "trailing JSON input"
  pure ()

def field? (value : Json) (key : String) : Option Json :=
  match value with
  | .obj fields => fields.get? key
  | _ => none

def requireField
    (value : Json) (key where_ : String) : Except String Json :=
  match field? value key with
  | some result => pure result
  | none => throw (where_ ++ "." ++ key ++ " is missing")

def asObject (value : Json) (where_ : String) : Except String Json := do
  let _ ← value.getObj?
  pure value

def asString (value : Json) (where_ : String) : Except String String :=
  match value with
  | .str text => pure text
  | _ => throw (where_ ++ " must be a string")

def asBool (value : Json) (where_ : String) : Except String Bool :=
  match value with
  | .bool result => pure result
  | _ => throw (where_ ++ " must be a boolean")

def asNat (value : Json) (where_ : String) : Except String Nat :=
  match value.getNat? with
  | .ok result => pure result
  | .error _ => throw (where_ ++ " must be a nonnegative integer")

def asArray (value : Json) (where_ : String) : Except String (Array Json) :=
  match value with
  | .arr values => pure values
  | _ => throw (where_ ++ " must be an array")

def stringField
    (value : Json) (key where_ : String) : Except String String := do
  asString (← requireField value key where_) (where_ ++ "." ++ key)

def natField
    (value : Json) (key where_ : String) : Except String Nat := do
  asNat (← requireField value key where_) (where_ ++ "." ++ key)

def boolField
    (value : Json) (key where_ : String) : Except String Bool := do
  asBool (← requireField value key where_) (where_ ++ "." ++ key)

def natList
    (value : Json) (where_ : String) : Except String (List Nat) := do
  let values ← asArray value where_
  let rec go : List Json → Except String (List Nat)
    | [] => pure []
    | item :: rest => do
        let head ← asNat item where_
        let tail ← go rest
        pure (head :: tail)
  go values.toList

def natListField
    (value : Json) (key where_ : String) : Except String (List Nat) := do
  natList (← requireField value key where_) (where_ ++ "." ++ key)

def decodeBinderInfo (value : Json) : Except String BinderInfo := do
  match ← asString value "binderInfo" with
  | "default" => pure .default
  | "implicit" => pure .implicit
  | "strictImplicit" => pure .strictImplicit
  | "instImplicit" => pure .instImplicit
  | other => throw ("invalid binder info " ++ other)

def decodeSafety (value : Json) : Except String DefinitionSafety := do
  match ← asString value "definition safety" with
  | "safe" => pure .safe
  | "unsafe" => pure .unsafeDef
  | "partial" => pure .partialDef
  | other => throw ("invalid definition safety " ++ other)

def decodeHints (value : Json) : Except String ReducibilityHints := do
  match value with
  | .str "opaque" => pure .opaqueHint
  | .str "abbrev" => pure .abbrevHint
  | .obj _ =>
      pure (.regular (← natField value "regular" "def.hints"))
  | _ => throw "invalid reducibility hint"

def decodeQuotKind (value : Json) : Except String QuotKind := do
  match ← asString value "quot.kind" with
  | "type" => pure .typeQ
  | "ctor" => pure .ctorQ
  | "lift" => pure .liftQ
  | "ind" => pure .indQ
  | other => throw ("invalid Quot kind " ++ other)

def decodeMeta (root : Json) : Except String Replay.Record := do
  let value ← asObject (← requireField root "meta" "line") "meta"
  let lean ← asObject (← requireField value "lean" "meta") "meta.lean"
  let format ← asObject (← requireField value "format" "meta") "meta.format"
  pure (.metaR {
    leanVersion := ← stringField lean "version" "meta.lean"
    leanGitHash := ← stringField lean "githash" "meta.lean"
    formatVersion := ← stringField format "version" "meta.format"
  })

def decodeName (root : Json) : Except String Replay.Record := do
  let index ← natField root "in" "Name"
  match field? root "str", field? root "num" with
  | some strValue, none =>
      let value ← asObject strValue "Name.str"
      pure (.nameR {
        index := index
        node := .str
          (← natField value "pre" "Name.str")
          (← stringField value "str" "Name.str")
      })
  | none, some numValue =>
      let value ← asObject numValue "Name.num"
      pure (.nameR {
        index := index
        node := .num
          (← natField value "pre" "Name.num")
          (← natField value "i" "Name.num")
      })
  | _, _ => throw "invalid lean4export Name record"

def decodeLevel (root : Json) : Except String Replay.Record := do
  let index ← natField root "il" "Level"
  let node ←
    match field? root "succ", field? root "max",
        field? root "imax", field? root "param" with
    | some parent, none, none, none =>
        pure (Replay.LevelNode.succ (← asNat parent "Level.succ"))
    | none, some pair, none, none =>
        match (← natList pair "Level.max") with
        | [left, right] => pure (.max left right)
        | _ => throw "Level.max requires exactly two operands"
    | none, none, some pair, none =>
        match (← natList pair "Level.imax") with
        | [left, right] => pure (.imax left right)
        | _ => throw "Level.imax requires exactly two operands"
    | none, none, none, some name =>
        pure (.param (← asNat name "Level.param"))
    | _, _, _, _ => throw "invalid lean4export Level record"
  pure (.levelR { index := index, node := node })

def parseNatLiteral (value : Json) : Except String Nat := do
  let text ← asString value "Expr.natVal"
  match text.toNat? with
  | some result => pure result
  | none => throw "Expr.natVal must be a decimal Nat string"

def decodeBinding
    (value : Json)
    (isLambda : Bool) : Except String Replay.ExprNode := do
  let name ← natField value "name" "Expr.binding"
  let type ← natField value "type" "Expr.binding"
  let body ← natField value "body" "Expr.binding"
  let binderInfo ←
    decodeBinderInfo (← requireField value "binderInfo" "Expr.binding")
  if isLambda then
    pure (.lam name type body binderInfo)
  else
    pure (.forallE name type body binderInfo)

def decodeExpr (root : Json) : Except String Replay.Record := do
  let index ← natField root "ie" "Expr"
  let node ←
    match field? root "bvar" with
    | some value => pure (.bvar (← asNat value "Expr.bvar"))
    | none =>
      match field? root "sort" with
      | some value => pure (.sort (← asNat value "Expr.sort"))
      | none =>
        match field? root "const" with
        | some raw => do
            let value ← asObject raw "Expr.const"
            pure (.const
              (← natField value "name" "Expr.const")
              (← natListField value "us" "Expr.const"))
        | none =>
          match field? root "app" with
          | some raw => do
              let value ← asObject raw "Expr.app"
              pure (.app
                (← natField value "fn" "Expr.app")
                (← natField value "arg" "Expr.app"))
          | none =>
            match field? root "lam" with
            | some raw =>
                decodeBinding (← asObject raw "Expr.lam") true
            | none =>
              match field? root "forallE" with
              | some raw =>
                  decodeBinding (← asObject raw "Expr.forallE") false
              | none =>
                match field? root "letE" with
                | some raw => do
                    let value ← asObject raw "Expr.letE"
                    let nondep ←
                      match field? value "nondep" with
                      | some item => asBool item "Expr.letE.nondep"
                      | none => pure false
                    pure (.letE
                      (← natField value "name" "Expr.letE")
                      (← natField value "type" "Expr.letE")
                      (← natField value "value" "Expr.letE")
                      (← natField value "body" "Expr.letE")
                      nondep)
                | none =>
                  match field? root "proj" with
                  | some raw => do
                      let value ← asObject raw "Expr.proj"
                      pure (.proj
                        (← natField value "typeName" "Expr.proj")
                        (← natField value "idx" "Expr.proj")
                        (← natField value "struct" "Expr.proj"))
                  | none =>
                    match field? root "natVal" with
                    | some raw => pure (.natVal (← parseNatLiteral raw))
                    | none =>
                      match field? root "strVal" with
                      | some raw => pure (.strVal (← asString raw "Expr.strVal"))
                      | none =>
                        match field? root "mdata" with
                        | some raw => do
                            let value ← asObject raw "Expr.mdata"
                            let metadata ←
                              match field? value "dataEq" with
                              | some id => asNat id "Expr.mdata.dataEq"
                              | none =>
                                  match field? value "data" with
                                  | some data => do
                                      let _ ← asObject data "Expr.mdata.data"
                                      pure 0
                                  | none => throw "Expr.mdata.data is missing"
                            pure (.mdata metadata
                              (← natField value "expr" "Expr.mdata"))
                        | none => throw "invalid lean4export Expr record"
  pure (.exprR { index := index, node := node })

def decodeAxiom (root : Json) : Except String Replay.Record := do
  let value ← asObject (← requireField root "axiom" "line") "axiom"
  pure (.axiomR {
    name := ← natField value "name" "axiom"
    levelParams := ← natListField value "levelParams" "axiom"
    type := ← natField value "type" "axiom"
    isUnsafe := ← boolField value "isUnsafe" "axiom"
  })

def decodeDefinition (root : Json) : Except String Replay.Record := do
  let value ← asObject (← requireField root "def" "line") "def"
  let all ←
    match field? value "all" with
    | some raw => natList raw "def.all"
    | none => pure []
  pure (.definitionR {
    name := ← natField value "name" "def"
    levelParams := ← natListField value "levelParams" "def"
    type := ← natField value "type" "def"
    value := ← natField value "value" "def"
    hints := ← decodeHints (← requireField value "hints" "def")
    safety := ← decodeSafety (← requireField value "safety" "def")
    all := all
  })

def decodeTheorem (root : Json) : Except String Replay.Record := do
  let value ← asObject (← requireField root "thm" "line") "thm"
  pure (.theoremR {
    name := ← natField value "name" "thm"
    levelParams := ← natListField value "levelParams" "thm"
    type := ← natField value "type" "thm"
    value := ← natField value "value" "thm"
  })

def decodeOpaque (root : Json) : Except String Replay.Record := do
  let value ← asObject (← requireField root "opaque" "line") "opaque"
  pure (.opaqueR {
    name := ← natField value "name" "opaque"
    levelParams := ← natListField value "levelParams" "opaque"
    type := ← natField value "type" "opaque"
    value := ← natField value "value" "opaque"
    isUnsafe := ← boolField value "isUnsafe" "opaque"
  })

def decodeQuot (root : Json) : Except String Replay.Record := do
  let value ← asObject (← requireField root "quot" "line") "quot"
  pure (.quotR {
    name := ← natField value "name" "quot"
    levelParams := ← natListField value "levelParams" "quot"
    type := ← natField value "type" "quot"
    kind := ← decodeQuotKind (← requireField value "kind" "quot")
  })

def findCtorJson?
    (name : Nat) : List Json → Option Json
  | [] => none
  | item :: rest =>
      match natField item "name" "constructor" with
      | .ok found =>
          if found == name then some item else findCtorJson? name rest
      | .error _ => none

def decodeConstructorFromJson
    (value : Json) : Except String Replay.ConstructorRecord := do
  pure {
    name := ← natField value "name" "constructor"
    type := ← natField value "type" "constructor"
    levelParams := some (← natListField value "levelParams" "constructor")
    induct := some (← natField value "induct" "constructor")
    cidx := some (← natField value "cidx" "constructor")
    numParams := some (← natField value "numParams" "constructor")
    numFields := some (← natField value "numFields" "constructor")
    isUnsafe := some (← boolField value "isUnsafe" "constructor")
  }

def decodeInductiveType
    (ctors : List Json)
    (value : Json) : Except String Replay.InductiveTypeRecord := do
  let ctorNames ← natListField value "ctors" "inductive type"
  let rec resolve :
      List Nat → Except String (List Replay.ConstructorRecord)
    | [] => pure []
    | name :: rest => do
        let some ctor := findCtorJson? name ctors
          | throw "missing exported constructor metadata"
        let head ← decodeConstructorFromJson ctor
        let tail ← resolve rest
        pure (head :: tail)
  pure {
    name := ← natField value "name" "inductive type"
    type := ← natField value "type" "inductive type"
    ctors := ← resolve ctorNames
    levelParams := some (← natListField value "levelParams" "inductive type")
    numParams := some (← natField value "numParams" "inductive type")
    numIndices := some (← natField value "numIndices" "inductive type")
    all := some (← natListField value "all" "inductive type")
    numNested := some (← natField value "numNested" "inductive type")
    isRec := some (← boolField value "isRec" "inductive type")
    isReflexive := some (← boolField value "isReflexive" "inductive type")
    isUnsafe := some (← boolField value "isUnsafe" "inductive type")
  }

def decodeRecursorRule
    (value : Json) : Except String Replay.RecursorRuleRecord := do
  pure {
    ctor := ← natField value "ctor" "recursor rule"
    nFields := ← natField value "nfields" "recursor rule"
    rhs := ← natField value "rhs" "recursor rule"
  }

def decodeRecursor
    (value : Json) : Except String Replay.RecursorRecord := do
  let rules ←
    asArray (← requireField value "rules" "recursor") "recursor.rules"
  let rec decodeRules :
      List Json → Except String (List Replay.RecursorRuleRecord)
    | [] => pure []
    | item :: rest => do
        let head ← decodeRecursorRule (← asObject item "recursor rule")
        let tail ← decodeRules rest
        pure (head :: tail)
  pure {
    name := ← natField value "name" "recursor"
    levelParams := ← natListField value "levelParams" "recursor"
    type := ← natField value "type" "recursor"
    all := ← natListField value "all" "recursor"
    numParams := ← natField value "numParams" "recursor"
    numIndices := ← natField value "numIndices" "recursor"
    numMotives := ← natField value "numMotives" "recursor"
    numMinors := ← natField value "numMinors" "recursor"
    rules := ← decodeRules rules.toList
    k := ← boolField value "k" "recursor"
    isUnsafe := ← boolField value "isUnsafe" "recursor"
  }

def maxNat : List Nat → Nat
  | [] => 0
  | x :: xs => Nat.max x (maxNat xs)

def decodeInductive (root : Json) : Except String Replay.Record := do
  let value ←
    asObject (← requireField root "inductive" "line") "inductive"
  let typeArray ←
    asArray (← requireField value "types" "inductive") "inductive.types"
  let ctorArray ←
    asArray (← requireField value "ctors" "inductive") "inductive.ctors"
  let recArray ←
    asArray (← requireField value "recs" "inductive") "inductive.recs"
  let typeValues := typeArray.toList
  let first :: _ := typeValues
    | throw "empty exported inductive group"
  let sharedLevels ←
    natListField first "levelParams" "inductive type"
  let sharedParams ← natField first "numParams" "inductive type"
  let sharedUnsafe ← boolField first "isUnsafe" "inductive type"

  let rec checkShared :
      List Json → Except String (List Nat)
    | [] => pure []
    | item :: rest => do
        let levels ← natListField item "levelParams" "inductive type"
        let numParams ← natField item "numParams" "inductive type"
        let isUnsafe ← boolField item "isUnsafe" "inductive type"
        unless levels == sharedLevels &&
            numParams == sharedParams &&
            isUnsafe == sharedUnsafe do
          throw "inconsistent shared inductive group metadata"
        let nested ← natField item "numNested" "inductive type"
        let tail ← checkShared rest
        pure (nested :: tail)
  let nestedCounts ← checkShared typeValues

  let rec decodeTypes :
      List Json → Except String (List Replay.InductiveTypeRecord)
    | [] => pure []
    | item :: rest => do
        let head ← decodeInductiveType ctorArray.toList item
        let tail ← decodeTypes rest
        pure (head :: tail)
  let rec decodeRecs :
      List Json → Except String (List Replay.RecursorRecord)
    | [] => pure []
    | item :: rest => do
        let head ← decodeRecursor (← asObject item "recursor")
        let tail ← decodeRecs rest
        pure (head :: tail)
  pure (.inductiveR {
    levelParams := sharedLevels
    numParams := sharedParams
    types := ← decodeTypes typeValues
    isUnsafe := sharedUnsafe
    numNested := maxNat nestedCounts
    recs := ← decodeRecs recArray.toList
  })

def recordKindCount (root : Json) : Nat :=
  let has (key : String) : Nat :=
    if (field? root key).isSome then 1 else 0
  has "meta" + has "in" + has "il" + has "ie" +
    has "axiom" + has "def" + has "thm" + has "opaque" +
    has "quot" + has "inductive"

def decodeJson (root : Json) : Except String Replay.Record := do
  let _ ← asObject root "line"
  unless recordKindCount root == 1 do
    throw "lean4export line must contain exactly one record kind"
  if (field? root "meta").isSome then
    decodeMeta root
  else if (field? root "in").isSome then
    decodeName root
  else if (field? root "il").isSome then
    decodeLevel root
  else if (field? root "ie").isSome then
    decodeExpr root
  else if (field? root "axiom").isSome then
    decodeAxiom root
  else if (field? root "def").isSome then
    decodeDefinition root
  else if (field? root "thm").isSome then
    decodeTheorem root
  else if (field? root "opaque").isSome then
    decodeOpaque root
  else if (field? root "quot").isSome then
    decodeQuot root
  else if (field? root "inductive").isSome then
    decodeInductive root
  else
    throw "unknown lean4export record"

def decodeLine (raw : String) : Except String Replay.Record := do
  validateNoDuplicateJsonKeys raw
  let json ←
    match Lean.Json.parse raw with
    | .ok value => pure value
    | .error err => throw ("invalid lean4export JSON: " ++ err)
  decodeJson json

def replayLine
    (state : Replay.State)
    (raw : String) : Except String Replay.State := do
  if raw.trim.isEmpty then
    pure state
  else
    state.replay (← decodeLine raw)

def replayLines
    (state : Replay.State)
    (lines : List String) : Except String Replay.State := do
  let rec go :
      Replay.State → Nat → List String → Except String Replay.State
    | current, _, [] => pure current
    | current, lineNo, line :: rest => do
        let next ←
          match replayLine current line with
          | .ok value => pure value
          | .error err =>
              throw ("line " ++ toString lineNo ++ ": " ++ err)
        go next (lineNo + 1) rest
  let final ← go state 1 lines
  let _ ← final.finish
  pure final

def replayText
    (state : Replay.State)
    (text : String) : Except String Replay.State :=
  replayLines state (text.splitOn "\n")

end ReplayJson

end PSC1Kernel
