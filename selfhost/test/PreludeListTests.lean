import Ps.Core.Builtin
import Ps.Environment.Basic
import Ps.Environment.Prelude

def psPreludeListNilName : PsName :=
  psNameAppendStr psListName "nil"

def psPreludeListConsName : PsName :=
  psNameAppendStr psListName "cons"

def psTestPreludeListConstructors : Bool :=
  match
      psEnvironmentFindInductive psBootstrapPreludeEnvironment psListName,
      psEnvironmentFindConstructor psBootstrapPreludeEnvironment psPreludeListNilName,
      psEnvironmentFindConstructor psBootstrapPreludeEnvironment psPreludeListConsName with
  | some listInfo, some nilInfo, some consInfo =>
      Nat.beq listInfo.numParams 1
        && Nat.beq listInfo.numIndices 0
        && Nat.beq (List.length listInfo.constructors) 2
        && psNameEq nilInfo.inductiveName psListName
        && Nat.beq nilInfo.constructorIndex 0
        && Nat.beq nilInfo.numParams 1
        && Nat.beq nilInfo.numFields 0
        && psNameEq consInfo.inductiveName psListName
        && Nat.beq consInfo.constructorIndex 1
        && Nat.beq consInfo.numParams 1
        && Nat.beq consInfo.numFields 2
  | _, _, _ =>
      false

def main : IO Unit := do
  if psTestPreludeListConstructors then
    IO.println "PSC1_PRELUDE_LIST_TESTS: PASS"
  else
    throw (IO.userError "PSC1_PRELUDE_LIST_TESTS: FAIL")
