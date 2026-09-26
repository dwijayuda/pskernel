import Ps.Host.KernelBridge
import Ps.Core.Builtin
import Ps.Core.Equality

def psBridgeHostLookupNat : IO Bool := do
  let response ← psHostKernelLookup psNatName
  match response.value with
  | none => pure false
  | some value =>
      match psJsonGetField value "kind" with
      | none => pure false
      | some kind =>
          match psJsonAsString kind with
          | none => pure false
          | some text =>
              pure (!text.isEmpty)

def psBridgeHostInferNat : IO Bool := do
  let inferred ←
    psHostKernelInfer
      (PsExpr.lit (PsLiteral.natural 7))
  pure (psExprAlphaEq inferred (PsExpr.constE psNatName []))

def psBridgeHostDefEqNat : IO Bool := do
  psHostKernelDefEq
    (PsExpr.lit (PsLiteral.natural 7))
    (PsExpr.lit (PsLiteral.natural 7))

def psBridgeHostReplayDefinition : IO Bool := do
  let declaration :=
    PsDeclaration.definitionDecl
      (psRootName "bridgeOne")
      []
      (PsExpr.constE psNatName [])
      (PsExpr.lit (PsLiteral.natural 1))
  let response ← psHostKernelReplay [declaration]
  match response.value with
  | none => pure false
  | some value =>
      match
          psJsonGetField value "admissions",
          psJsonGetField value "declarations" with
      | some admissions, some declarations =>
          pure
            (psJsonAsNumberText admissions == some "1"
              && psJsonAsNumberText declarations == some "1")
      | _, _ => pure false

def psBridgeHostReplayInductive : IO Bool := do
  let choice := psRootName "BridgeChoice"
  let left := psNameAppendStr choice "left"
  let right := psNameAppendStr choice "right"
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
    }
  ]
  let response ← psHostKernelReplay declarations
  match response.value with
  | none => pure false
  | some value =>
      match
          psJsonGetField value "admissions",
          psJsonGetField value "declarations" with
      | some admissions, some declarationsValue =>
          match
              psJsonAsNumberText admissions,
              psJsonAsNumberText declarationsValue with
          | some admissionCount, some declarationCount =>
              pure
                (admissionCount == "1"
                  && !declarationCount.isEmpty)
          | _, _ => pure false
      | _, _ => pure false

def main : IO Unit := do
  let ping ← psHostKernelPing
  if !ping then
    throw (IO.userError "PSC1_KERNEL_BRIDGE_PING: FAIL")
  IO.println "PSC1_KERNEL_BRIDGE_PASS: ping"

  let lookup ← psBridgeHostLookupNat
  if !lookup then
    throw (IO.userError "PSC1_KERNEL_BRIDGE_LOOKUP: FAIL")
  IO.println "PSC1_KERNEL_BRIDGE_PASS: lookup"

  let infer ← psBridgeHostInferNat
  if !infer then
    throw (IO.userError "PSC1_KERNEL_BRIDGE_INFER: FAIL")
  IO.println "PSC1_KERNEL_BRIDGE_PASS: infer"

  let defeq ← psBridgeHostDefEqNat
  if !defeq then
    throw (IO.userError "PSC1_KERNEL_BRIDGE_DEFEQ: FAIL")
  IO.println "PSC1_KERNEL_BRIDGE_PASS: defeq"

  let replay ← psBridgeHostReplayDefinition
  if !replay then
    throw (IO.userError "PSC1_KERNEL_BRIDGE_REPLAY: FAIL")
  IO.println "PSC1_KERNEL_BRIDGE_PASS: replay"

  let inductiveReplay ← psBridgeHostReplayInductive
  if !inductiveReplay then
    throw (IO.userError "PSC1_KERNEL_BRIDGE_INDUCTIVE_REPLAY: FAIL")
  IO.println "PSC1_KERNEL_BRIDGE_PASS: inductive replay"
  IO.println "PSC1_KERNEL_BRIDGE_HOST_TESTS: PASS"
