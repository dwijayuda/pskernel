import Lean
import Ps.MinKernel.Tests.RegularIngressVectors
open Lean

namespace Ps.MinKernel.RegularIngressNative

def field (value : Json) (key : String) : Except String Json := value.getObjVal? key
def str (value : Json) (key : String) : Except String String := do
  (← field value key).getStr?
def naturalText (value : Json) : Except String Nat := do
  let text ← value.getStr?
  match text.toNat? with
  | none => throw "invalid natural"
  | some n => pure n

def name (fuel : Nat) (value : Json) : Except String PsMinCoreName := do
  match fuel with
  | 0 => throw "name depth"
  | fuel + 1 =>
    match ← str value "k" with
    | "a" => pure .anonymous
    | "s" => pure (.str (← name fuel (← field value "p")) ((← str value "v").toList.map Char.toNat))
    | "n" => pure (.num (← name fuel (← field value "p")) (← naturalText (← field value "v")))
    | _ => throw "name tag"

def level (value : Json) : Except String Nat := do
  match ← str value "k" with
  | "z" => pure 0
  | "s" =>
    if (← str (← field value "o") "k") == "z" then pure 1 else throw "level"
  | _ => throw "level"

def binder (value : Json) : Except String Nat := do
  match ← value.getStr? with
  | "default" => pure 0
  | "implicit" => pure 1
  | "strictImplicit" => pure 2
  | "instImplicit" => pure 3
  | _ => throw "binder"

def expr (fuel : Nat) (value : Json) : Except String PsMinCoreExpr := do
  match fuel with
  | 0 => throw "expression depth"
  | fuel + 1 =>
    match ← str value "k" with
    | "b" => pure (.bvar (← (← field value "i").getNat?))
    | "nat" => pure (.natural (← naturalText (← field value "v")))
    | "sort" => pure (.sort (← level (← field value "l")))
    | "const" =>
      let levels ← (← (← field value "ls").getArr?).toList.mapM level
      pure (.constant (← name 16 (← field value "n")) levels)
    | "app" => pure (.app (← expr fuel (← field value "f")) (← expr fuel (← field value "a")))
    | "lam" => pure (.lam (← name 16 (← field value "n")) (← binder (← field value "bi"))
        (← expr fuel (← field value "t")) (← expr fuel (← field value "b")))
    | "forall" => pure (.forallE (← name 16 (← field value "n")) (← binder (← field value "bi"))
        (← expr fuel (← field value "t")) (← expr fuel (← field value "b")))
    | "let" => pure (.letE (← name 16 (← field value "n")) (← expr fuel (← field value "t"))
        (← expr fuel (← field value "v")) (← expr fuel (← field value "b")))
    | "proj" => pure (.projection (← name 16 (← field value "n")) (← (← field value "i").getNat?)
        (← expr fuel (← field value "e")))
    | _ => throw "expression tag"

def readConstructor (value : Json) : Except String PsMinRegCoreConstructor := do
  pure (.mk (← name 16 (← field value "n")) (← expr 256 (← field value "t")))

def entry (value : Json) : Except String PsMinRegCoreEntry := do
  let declaration ← field value "declaration"
  match ← str value "kind" with
  | "constant" =>
    pure (.definition (.mk (← name 16 (← field declaration "n"))
      (← naturalText (← field (← field declaration "h") "h"))
      (← expr 256 (← field declaration "t")) (← expr 256 (← field declaration "v"))))
  | "inductive" =>
    let families ← (← field declaration "ts").getArr?
    if families.size != 1 then throw "mutual group"
    let family := families[0]!
    let constructors ← (← (← field family "cs").getArr?).toList.mapM readConstructor
    pure (.inductiveE (.mk (← name 16 (← field family "n")) (← expr 256 (← field family "t")) constructors))
  | _ => throw "admission kind"

def propose (text : String) : Except String (List PsMinRegCoreEntry) := do
  let root ← Json.parse text
  (← (← root.getObjVal? "admissions").getArr?).toList.mapM entry

def accepted (bytes : ByteArray) (source : List PsMinRegCoreEntry) : Bool :=
  match psMinRegCoreAdmit (bytes.toList.map UInt8.toNat) source with
  | none => false
  | some _ => true

def main (args : List String) : IO Unit := do
  match args with
  | ["--cases", file] =>
    let parsed ← IO.ofExcept (Json.parse (← IO.FS.readFile file))
    let rows ← IO.ofExcept parsed.getArr?
    for index in List.range rows.size do
      let row := rows[index]!
      let source ← IO.ofExcept (str row "source")
      let expected ← IO.ofExcept ((← IO.ofExcept (field row "expected")).getBool?)
      let outcome := accepted source.toUTF8 (psMinRegCoreCandidate index)
      IO.println s!"PSC1_MIN_REGULAR_INGRESS_VECTOR {index} {outcome}"
      if outcome != expected then throw (IO.userError s!"regular ingress vector {index} mismatch")
    IO.println "PSC1_MIN_REGULAR_INGRESS_NATIVE_PASS"
  | ["--self", file] =>
    let bytes ← IO.FS.readBinFile file
    if bytes.size > psMinRegCoreByteBudget then throw (IO.userError "self input byte bound")
    let some text := String.fromUTF8? bytes | throw (IO.userError "invalid UTF8")
    let source ← IO.ofExcept (propose text)
    let outcome := accepted bytes source
    IO.println s!"PSC1_MIN_REGULAR_INGRESS_NATIVE_SELF {outcome}"
    if !outcome then throw (IO.userError "regular runtime self-admission refused")
  | _ => throw (IO.userError "expected --cases PATH or --self PATH")

end Ps.MinKernel.RegularIngressNative

def main := Ps.MinKernel.RegularIngressNative.main
