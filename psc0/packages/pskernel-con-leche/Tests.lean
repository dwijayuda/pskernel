import PsKernelConLeche
import Std.Async.System

open PsKernelConLeche

private def good : String := String.intercalate "\n" [
  "{\"in\":1,\"str\":{\"pre\":0,\"str\":\"Nat\"}}",
  "{\"in\":2,\"str\":{\"pre\":0,\"str\":\"answer\"}}",
  "{\"ie\":0,\"const\":{\"name\":1,\"us\":[]}}",
  "{\"ie\":1,\"natVal\":\"42\"}",
  "{\"def\":{\"all\":[2],\"levelParams\":[],\"name\":2,\"type\":0,\"value\":1,\"hints\":{\"regular\":1},\"safety\":\"safe\"}}",
  ""]

private def bad : String := String.intercalate "\n" [
  "{\"in\":1,\"str\":{\"pre\":0,\"str\":\"False\"}}",
  "{\"in\":2,\"str\":{\"pre\":0,\"str\":\"contradiction\"}}",
  "{\"ie\":0,\"const\":{\"name\":1,\"us\":[]}}",
  "{\"ie\":1,\"natVal\":\"0\"}",
  "{\"thm\":{\"all\":[2],\"levelParams\":[],\"name\":2,\"type\":0,\"value\":1}}",
  ""]

private def axiomInput : String := String.intercalate "\n" [
  "{\"in\":1,\"str\":{\"pre\":0,\"str\":\"Nat\"}}",
  "{\"in\":2,\"str\":{\"pre\":0,\"str\":\"Classical\"}}",
  "{\"in\":3,\"str\":{\"pre\":2,\"str\":\"choice\"}}",
  "{\"ie\":0,\"const\":{\"name\":1,\"us\":[]}}",
  "{\"axiom\":{\"all\":[3],\"levelParams\":[],\"name\":3,\"type\":0,\"isUnsafe\":false}}",
  ""]

private def require (ok : Bool) (label : String) : IO Unit := do
  unless ok do throw (IO.userError label)
  IO.println s!"PASS {label}"

private def expectFailure (text : String) (code : UInt32) (phase : Phase)
    (label : String) (limits : Limits := {}) : IO Unit := do
  match check [text.toUTF8] limits with
  | .ok _ => throw (IO.userError s!"{label}: unexpectedly accepted")
  | .error d => require (d.exitCode == code && d.phase == phase) label

def main : IO UInt32 := do
  try
    Std.Async.System.setEnvVar "LEAN_ABORT_ON_PANIC" "1"
    Std.Async.System.setEnvVar "LEAN_ABORT_ON_NONLINEAR" "1"
    require (check [good.toUTF8]).isOk "valid Nat definition, including prelude replay"
    let b := good.toUTF8
    require (check [b.extract 0 17, b.extract 17 b.size]).isOk "chunk boundary inside a record"
    require (check [good.toUTF8]).isOk "fresh repeat, no shared admission authority"
    expectFailure bad 1 .kernel "False theorem rejected after installation"
    expectFailure axiomInput 2 .policy "Classical.choice forbidden by PSC0 policy"
    expectFailure "not json\n" 3 .parse "malformed input is not logical rejection"
    expectFailure "{\"format\":\"proofscript-checked-admissions\",\"version\":2,\"admissions\":[]}" 3 .parse
      "canonical-v2 never misrepresented as supported"
    expectFailure good 3 .resource "byte budget exhaustion is an error" { maxInputBytes := 1 }
    expectFailure good 3 .resource "record budget exhaustion is an error" { maxInputRecords := 0 }
    require (!(permittedInputAxiom (.str .anonymous "Quot.sound"))) "dotted-name spoof refused"
    require (permittedInputAxiom (.str (.str .anonymous "Quot") "sound")) "structured Quot.sound name"
    require (!(permittedInputAxiom (.str .anonymous "sorryAx"))) "sorryAx declaration policy"
    IO.println "PSKERNEL_CON_LECHE_TESTS_PASS"
    pure 0
  catch e =>
    IO.eprintln (toString e)
    pure 3
