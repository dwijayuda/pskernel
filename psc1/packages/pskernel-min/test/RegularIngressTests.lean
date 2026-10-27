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


def debugName : PsMinCoreName → String
  | .anonymous => "_"
  | .str parent bytes => debugName parent ++ "." ++ String.ofList (bytes.map Char.ofNat)
  | .num parent value => debugName parent ++ "." ++ toString value

def debugExpr (fuel total visible : Nat) (groups : List PsMinRegCorePlan)
    (names : List PsMinCoreName) (source : PsMinCoreExpr) : String :=
  match fuel with
  | 0 => "diagnostic-depth"
  | fuel + 1 =>
    if (psMinRegCoreTranslate 256 total visible groups names source).isSome then "accepted" else
    match source with
    | .constant name levels => "constant " ++ debugName name ++ " levels=" ++ toString levels
    | .bvar index => "bvar " ++ toString index
    | .natural value => "natural " ++ toString value
    | .sort level => "sort " ++ toString level
    | .forallE _ _ _ _ => "forall-as-term"
    | .lam _ _ type body =>
      if (psMinRegCoreType 256 total visible groups type).isNone then "lambda-type" else
        "lambda-body:" ++ debugExpr fuel total visible groups names body
    | .letE _ type value body =>
      if (psMinRegCoreType 256 total visible groups type).isNone then "let-type" else
      if (psMinRegCoreTranslate 256 total visible groups names value).isNone then
        "let-value:" ++ debugExpr fuel total visible groups names value else
        "let-body:" ++ debugExpr fuel total visible groups names body
    | .app fn arg =>
      if (psMinRegCoreTranslate 256 total visible groups names fn).isNone then
        "app-fn:" ++ debugExpr fuel total visible groups names fn else
        "app-arg:" ++ debugExpr fuel total visible groups names arg
    | .projection owner field major =>
      if (psMinRegCoreGroupSlot total visible groups owner).isNone then
        "projection-owner " ++ debugName owner ++ " field=" ++ toString field else
        "projection-major:" ++ debugExpr fuel total visible groups names major


def debugType : PsMinRegTy → String
  | .empty => "False"
  | .unit => "Unit"
  | .nat => "Nat"
  | .boolean => "Bool"
  | .data slot => "D" ++ toString slot
  | .arr a b => "(" ++ debugType a ++ "->" ++ debugType b ++ ")"
  | .list a => "List(" ++ debugType a ++ ")"
  | .option a => "Option(" ++ debugType a ++ ")"

def debugInfer (fuel : Nat) (specs : List PsMinRegSpec) (globals locals : List PsMinRegTy)
    (term : PsMinRegCoreTerm) : String :=
  match fuel with
  | 0 => "diagnostic-depth"
  | fuel + 1 =>
    if (psMinRegCoreInfer 512 specs globals locals term).isSome then "accepted" else
    match term with
    | .ordinary _ => "ordinary-atom"
    | .recursor slot result => "ambient-recursor " ++ toString slot ++ " result=" ++ debugType result
    | .lam domain body =>
      if !psMinRegTyValid 511 (psMinRegSpecCount specs) domain then "lambda-domain:" ++ debugType domain else
        "lambda-body:" ++ debugInfer fuel specs globals (domain :: locals) body
    | .letE type value body =>
      if !psMinRegTyValid 511 (psMinRegSpecCount specs) type then "let-type:" ++ debugType type else
      match psMinRegCoreInfer 511 specs globals locals value with
      | none => "let-value:" ++ debugInfer fuel specs globals locals value
      | some inferred => if !psMinRegTyEq 511 inferred type then
          "let-mismatch inferred=" ++ debugType inferred ++ " declared=" ++ debugType type else
          "let-body:" ++ debugInfer fuel specs globals (type :: locals) body
    | .app fn argument =>
      match psMinRegCoreInfer 511 specs globals locals fn with
      | none => "app-fn:" ++ debugInfer fuel specs globals locals fn
      | some fnType => match fnType with
        | .arr domain _ => match psMinRegCoreInfer 511 specs globals locals argument with
          | none => "app-arg:" ++ debugInfer fuel specs globals locals argument
          | some inferred => "app-mismatch domain=" ++ debugType domain ++ " argument=" ++ debugType inferred
        | _ => "app-nonfunction:" ++ debugType fnType

def diagnose (bytes : ByteArray) (entries : List PsMinRegCoreEntry) : IO Unit := do
  IO.println s!"PSC1_MIN_REGULAR_DIAGNOSTIC certificate={(psMinRegCoreDecodeCertificate (bytes.toList.map UInt8.toNat) entries).isSome}"
  let some plans := psMinRegCorePlans entries | do
    IO.println "PSC1_MIN_REGULAR_DIAGNOSTIC plans=false"
    return
  IO.println s!"PSC1_MIN_REGULAR_DIAGNOSTIC plans=true groups={plans.count} signatures={psMinRegCoreCheckSignatures plans.count plans.groups plans.groups}"
  let mut visible := 0
  let mut names := []
  let mut index := 0
  for entry in entries do
    match entry with
    | .inductiveE _ => visible := visible + 1
    | .definition declaration =>
      let typeOk := (psMinRegCoreType 256 plans.count visible plans.groups declaration.type).isSome
      let valueOk := (psMinRegCoreTranslate 256 plans.count visible plans.groups names declaration.value).isSome
      if !typeOk || !valueOk then
        IO.println s!"PSC1_MIN_REGULAR_DIAGNOSTIC entry={index} name={debugName declaration.name} type={typeOk} value={valueOk}"
        IO.println ("PSC1_MIN_REGULAR_DIAGNOSTIC expression=" ++ debugExpr 256 plans.count visible plans.groups names declaration.value)
        return
      names := declaration.name :: names
    index := index + 1
  let some normalized := psMinRegCoreTranslateEntries 512 plans.count 0 plans.groups [] entries |
    throw (IO.userError "diagnostic translation changed")
  let specs := psMinRegCoreSpecs plans.groups
  IO.println s!"PSC1_MIN_REGULAR_DIAGNOSTIC registry={psMinRegRegistryValid 512 specs} translation=true"
  let sourceNames := entries.filterMap fun e => match e with
    | .definition d => some d.name
    | .inductiveE _ => none
  let mut globals := []
  let mut definitionIndex := 0
  for declaration in normalized do
    let inferred := psMinRegCoreInfer 512 specs globals [] declaration.value
    let agrees := match inferred with
      | none => false
      | some type => psMinRegTyEq 512 type declaration.type
    if !agrees then
      let name := (sourceNames[definitionIndex]?).map debugName
      IO.println s!"PSC1_MIN_REGULAR_DIAGNOSTIC definition={definitionIndex} name={name} declared={debugType declaration.type} inferred={inferred.map debugType}"
      IO.println ("PSC1_MIN_REGULAR_DIAGNOSTIC infer=" ++ debugInfer 512 specs globals [] declaration.value)
      return
    globals := declaration.type :: globals
    definitionIndex := definitionIndex + 1

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
    if !outcome then
      diagnose bytes source
      throw (IO.userError "regular runtime self-admission refused")
  | _ => throw (IO.userError "expected --cases PATH or --self PATH")

end Ps.MinKernel.RegularIngressNative

def main := Ps.MinKernel.RegularIngressNative.main
