import Ps.Bridge.CheckedAdmissions
import Ps.Core.Builtin

def psBridgeTestDefinition : PsDeclaration :=
  PsDeclaration.definitionDecl
    (psRootName "idNat")
    []
    (PsExpr.constE psNatName [])
    (PsExpr.lit (PsLiteral.natural 1))

def psBridgeExpectedDefinitionPayload : String :=
  "{\"admissions\":[{\"declaration\":{" ++
  "\"h\":{\"h\":\"1\",\"k\":\"regular\"}," ++
  "\"k\":\"definition\",\"lp\":[]," ++
  "\"n\":{\"k\":\"s\",\"p\":{\"k\":\"a\"},\"v\":\"idNat\"}," ++
  "\"s\":\"safe\"," ++
  "\"t\":{\"k\":\"const\",\"ls\":[]," ++
    "\"n\":{\"k\":\"s\",\"p\":{\"k\":\"a\"},\"v\":\"Nat\"}}," ++
  "\"v\":{\"k\":\"nat\",\"v\":\"1\"}}," ++
  "\"kind\":\"constant\"}]," ++
  "\"format\":\"proofscript-checked-admissions\",\"version\":2}"

def psTestCanonicalDefinitionPayload : Bool :=
  match psEncodeCheckedAdmissionsCanonical [psBridgeTestDefinition] with
  | Except.error _ => false
  | Except.ok encoded =>
      encoded == psBridgeExpectedDefinitionPayload

def psTestCanonicalTextNewline : Bool :=
  match psEncodeCheckedAdmissionsText [psBridgeTestDefinition] with
  | Except.error _ => false
  | Except.ok encoded =>
      encoded == psBridgeExpectedDefinitionPayload ++ "\n"

def psTestJsonEscaping : Bool :=
  psJsonQuote "a\n\"b\\c" == "\"a\\n\\\"b\\\\c\""

def psTestJsonParserCanonicalPayload : Bool :=
  match psJsonParse psBridgeExpectedDefinitionPayload with
  | Except.error _ => false
  | Except.ok value =>
      match
          psJsonGetField value "format",
          psJsonGetField value "version",
          psJsonGetField value "admissions" with
      | some format, some version, some admissions =>
          psJsonAsString format == some "proofscript-checked-admissions"
            && psJsonAsNumberText version == some "2"
            && match psJsonAsArray admissions with
               | some [_] => true
               | _ => false
      | _, _, _ => false

def psTestJsonParserEscapesAndNested : Bool :=
  match
      psJsonParse
        "{\"a\":[true,false,null,-12],\"s\":\"x\\ny\\u0021\"}" with
  | Except.error _ => false
  | Except.ok value =>
      match
          psJsonGetField value "a",
          psJsonGetField value "s" with
      | some arrayValue, some stringValue =>
          psJsonAsString stringValue == some "x\ny!"
            && match psJsonAsArray arrayValue with
               | some [
                   PsJsonValue.bool true,
                   PsJsonValue.bool false,
                   PsJsonValue.nullE,
                   PsJsonValue.number "-12"
                 ] => true
               | _ => false
      | _, _ => false

def psTestJsonParserRejectsInvalid : Bool :=
  let trailing :=
    match psJsonParse "{\"x\":1} junk" with
    | Except.error PsJsonParseError.trailingInput => true
    | _ => false
  let invalidNumber :=
    match psJsonParse "{\"x\":01}" with
    | Except.error PsJsonParseError.invalidNumber => true
    | _ => false
  let invalidEscape :=
    match psJsonParse "{\"x\":\"\\q\"}" with
    | Except.error PsJsonParseError.invalidEscape => true
    | _ => false
  trailing && invalidNumber && invalidEscape

def psTestRejectFreeVariable : Bool :=
  let declaration :=
    PsDeclaration.definitionDecl
      (psRootName "bad")
      []
      (PsExpr.constE psNatName [])
      (PsExpr.fvar 0)
  match psEncodeCheckedAdmissionsCanonical [declaration] with
  | Except.error PsCheckedAdmissionCodecError.freeVariable => true
  | _ => false

def psTestRejectExpressionMetavariable : Bool :=
  let declaration :=
    PsDeclaration.definitionDecl
      (psRootName "badMeta")
      []
      (PsExpr.constE psNatName [])
      (PsExpr.mvar 0)
  match psEncodeCheckedAdmissionsCanonical [declaration] with
  | Except.error PsCheckedAdmissionCodecError.expressionMetavariable => true
  | _ => false

def psTestRejectUniverseMetavariable : Bool :=
  let declaration :=
    PsDeclaration.definitionDecl
      (psRootName "badLevel")
      []
      (PsExpr.sortE (PsLevel.mvar 0))
      (PsExpr.sortE PsLevel.zero)
  match psEncodeCheckedAdmissionsCanonical [declaration] with
  | Except.error PsCheckedAdmissionCodecError.universeMetavariable => true
  | _ => false

def psTestRejectPartialCertification : Bool :=
  let natType := PsExpr.constE psNatName []
  let loopName := psRootName "loop"
  let loopType :=
    PsExpr.forallE
      (psRootName "n")
      natType
      natType
      PsBinderInfo.explicit
  let loopValue :=
    PsExpr.lam
      (psRootName "n")
      natType
      (PsExpr.app
        (PsExpr.constE loopName [])
        (PsExpr.bvar 0))
      PsBinderInfo.explicit
  let declaration :=
    PsDeclaration.partialDecl
      loopName
      []
      loopType
      loopValue
  match psEncodeCheckedAdmissionsCanonical [declaration] with
  | Except.error PsCheckedAdmissionCodecError.unsupportedDeclaration => true
  | _ => false

def psTestInductiveGrouping : Bool :=
  let choice := psRootName "Choice"
  let left := psNameAppendStr choice "left"
  let right := psNameAppendStr choice "right"
  let recName := psNameAppendStr choice "rec"
  let choiceType := PsExpr.sortE (PsLevel.succ PsLevel.zero)
  let choiceValueType := PsExpr.constE choice []
  let declarations : List PsDeclaration := [
    PsDeclaration.inductiveDecl {
      name := choice
      levelParams := []
      type := choiceType
      numParams := 0
      numIndices := 0
      constructors := [left, right]
    },
    PsDeclaration.constructorDecl {
      name := left
      levelParams := []
      type := choiceValueType
      inductiveName := choice
      constructorIndex := 0
      numParams := 0
      numFields := 0
    },
    PsDeclaration.constructorDecl {
      name := right
      levelParams := []
      type := choiceValueType
      inductiveName := choice
      constructorIndex := 1
      numParams := 0
      numFields := 0
    },
    PsDeclaration.recursorDecl {
      name := recName
      levelParams := []
      type := choiceType
      inductiveNames := [choice]
      numParams := 0
      numIndices := 0
      numMotives := 1
      numMinors := 2
    }
  ]
  match psEncodeCheckedAdmissionsCanonical declarations with
  | Except.error _ => false
  | Except.ok encoded =>
      encoded.contains "\"kind\":\"inductive\""
        && !encoded.contains "\"kind\":\"constructor\""
        && !encoded.contains "\"kind\":\"recursor\""
        && encoded.contains "\"v\":\"left\""
        && encoded.contains "\"v\":\"right\""

structure PsBridgeNamedTest where
  name : String
  passed : Bool

def psBridgeTests : List PsBridgeNamedTest := [
  { name := "canonical definition payload", passed := psTestCanonicalDefinitionPayload },
  { name := "canonical text newline", passed := psTestCanonicalTextNewline },
  { name := "JSON escaping", passed := psTestJsonEscaping },
  { name := "JSON parser canonical payload", passed := psTestJsonParserCanonicalPayload },
  { name := "JSON parser escapes and nested values", passed := psTestJsonParserEscapesAndNested },
  { name := "JSON parser rejects malformed input", passed := psTestJsonParserRejectsInvalid },
  { name := "reject free variable", passed := psTestRejectFreeVariable },
  { name := "reject expression metavariable", passed := psTestRejectExpressionMetavariable },
  { name := "reject universe metavariable", passed := psTestRejectUniverseMetavariable },
  { name := "reject partial certification", passed := psTestRejectPartialCertification },
  { name := "inductive grouping", passed := psTestInductiveGrouping }
]

def psRunBridgeTests : List PsBridgeNamedTest -> IO Bool
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSC1_BRIDGE_PASS: " ++ test.name)
      else
        IO.println ("PSC1_BRIDGE_FAIL: " ++ test.name)
      let restPassed ← psRunBridgeTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psRunBridgeTests psBridgeTests
  if passed then
    IO.println "PSC1_BRIDGE_TESTS: PASS"
  else
    throw (IO.userError "PSC1_BRIDGE_TESTS: FAIL")
