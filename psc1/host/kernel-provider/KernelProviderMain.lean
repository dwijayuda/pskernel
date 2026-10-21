import Lean.Data.Json
import Ps.KernelCore.API.Kernel

/- Host-only canonical-admissions transport. All semantic decisions are made
   by PSKernel-Core's checked API. No Lean environment/checker is called.
   The portable SelfHost closure does not import this IO adapter. -/
namespace PSKernelCanonicalProvider
open Lean

structure WireError where
  outcome : String
  message : String

private def bad {α : Type} (message : String) : Except WireError α :=
  .error ⟨"malformedInput", message⟩

private def unsupported {α : Type} (message : String) : Except WireError α :=
  .error ⟨"declinedUnsupported", message⟩

private def lift {α : Type} (value : Except String α) : Except WireError α :=
  value.mapError (fun message => ⟨"malformedInput", message⟩)

private def field (value : Json) (key : String) : Except WireError Json :=
  lift (value.getObjVal? key)

private def string (value : Json) : Except WireError String :=
  lift value.getStr?

private def array (value : Json) : Except WireError (List Json) := do
  return (← lift value.getArr?).toList

private def fieldString (value : Json) (key : String) : Except WireError String := do
  string (← field value key)

private def keys (value : Json) (allowed : List String) : Except WireError Unit := do
  let fields ← lift value.getObj?
  if !(fields.all (fun key _ => allowed.contains key)) then
    unsupported "unrecognized transport field"
  else if allowed.all (fun key => fields.contains key) then pure ()
  else bad "missing required transport field"

private def tagged (value : Json) (choices : List (String × List String)) : Except WireError String := do
  let tag ← fieldString value "k"
  match choices.find? (fun entry => entry.1 == tag) with
  | none => unsupported "unsupported transport tag"
  | some entry =>
      keys value entry.2
      pure tag

private def natural (value : Json) : Except WireError Nat := do
  match value.getStr? with
  | .ok text =>
      match text.toNat? with
      | some n => if toString n == text then pure n else bad "noncanonical natural"
      | none => bad "invalid natural"
  | .error _ =>
      let n ← lift value.getNat?
      if n <= 9007199254740991 then pure n else bad "unsafe JSON numeric natural; use a decimal string"

private def decodeName : Nat → Json → Except WireError PsKernelName
  | 0, _ => .error ⟨"resourceExhausted", "transport name depth exceeded"⟩
  | fuel + 1, value => do
      match ← tagged value [("a", ["k"]), ("s", ["k", "p", "v"]), ("n", ["k", "p", "v"])] with
      | "a" => return .anonymous
      | "s" => return .str (← decodeName fuel (← field value "p")) (← fieldString value "v")
      | "n" => return .num (← decodeName fuel (← field value "p")) (← natural (← field value "v"))
      | _ => bad "name tag"

private def decodeLevel : Nat → Json → Except WireError PsKernelLevel
  | 0, _ => .error ⟨"resourceExhausted", "transport level depth exceeded"⟩
  | fuel + 1, value => do
      match ← tagged value [("z", ["k"]), ("s", ["k", "o"]),
        ("max", ["k", "l", "r"]), ("imax", ["k", "l", "r"]), ("p", ["k", "n"])] with
      | "z" => return .zero
      | "s" => return .succ (← decodeLevel fuel (← field value "o"))
      | "max" => return .max (← decodeLevel fuel (← field value "l")) (← decodeLevel fuel (← field value "r"))
      | "imax" => return .imax (← decodeLevel fuel (← field value "l")) (← decodeLevel fuel (← field value "r"))
      | "p" => return .param (← decodeName fuel (← field value "n"))
      | _ => unsupported "level tag"

private def decodeBinder (value : Json) : Except WireError PsKernelBinderInfo := do
  match ← string value with
  | "default" => return .default
  | "implicit" => return .implicit
  | "strictImplicit" => return .strictImplicit
  | "instImplicit" => return .instImplicit
  | _ => bad "binder tag"

private def decodeExpr : Nat → Json → Except WireError PsKernelExpr
  | 0, _ => .error ⟨"resourceExhausted", "transport expression depth exceeded"⟩
  | fuel + 1, value => do
      match ← tagged value [("b", ["k", "i"]), ("sort", ["k", "l"]),
        ("const", ["k", "n", "ls"]), ("app", ["k", "f", "a"]),
        ("lam", ["k", "n", "t", "b", "bi"]), ("forall", ["k", "n", "t", "b", "bi"]),
        ("let", ["k", "n", "t", "v", "b"]), ("nat", ["k", "v"]),
        ("str", ["k", "v"]), ("proj", ["k", "n", "i", "e"])] with
      | "b" => return .bvar (← natural (← field value "i"))
      | "sort" => return .sort (← decodeLevel fuel (← field value "l"))
      | "const" =>
          let levels ← (← array (← field value "ls")).mapM (decodeLevel fuel)
          return .const (← decodeName fuel (← field value "n")) levels
      | "app" => return .app (← decodeExpr fuel (← field value "f")) (← decodeExpr fuel (← field value "a"))
      | "lam" => return .lam (← decodeName fuel (← field value "n"))
          (← decodeExpr fuel (← field value "t")) (← decodeExpr fuel (← field value "b"))
          (← decodeBinder (← field value "bi"))
      | "forall" => return .forallE (← decodeName fuel (← field value "n"))
          (← decodeExpr fuel (← field value "t")) (← decodeExpr fuel (← field value "b"))
          (← decodeBinder (← field value "bi"))
      | "let" => return .letE (← decodeName fuel (← field value "n"))
          (← decodeExpr fuel (← field value "t")) (← decodeExpr fuel (← field value "v"))
          (← decodeExpr fuel (← field value "b")) false
      | "nat" => return .lit (.nat (← natural (← field value "v")))
      | "str" => return .lit (.str (← fieldString value "v"))
      | "proj" => return .proj (← decodeName fuel (← field value "n"))
          (← natural (← field value "i")) (← decodeExpr fuel (← field value "e"))
      | _ => unsupported "expression tag"

private def decodeBase (value : Json) : Except WireError PsKernelConstantBase := do
  return {
    name := (← decodeName 4096 (← field value "n"))
    levelParams := (← (← array (← field value "lp")).mapM (decodeName 4096))
    type := (← decodeExpr 4096 (← field value "t"))
  }

private def decodeCtor (value : Json) : Except WireError PsKernelSimpleConstructorDecl := do
  keys value ["n", "t"]
  return {
    name := (← decodeName 4096 (← field value "n"))
    type := (← decodeExpr 4096 (← field value "t"))
  }

private def decodeInductive (value : Json) : Except WireError PsKernelSimpleMutualTypeDecl := do
  keys value ["n", "t", "cs"]
  return {
    name := (← decodeName 4096 (← field value "n"))
    type := (← decodeExpr 4096 (← field value "t"))
    ctors := (← (← array (← field value "cs")).mapM decodeCtor)
  }

private def decodeRequest (value : Json) : Except WireError PsKernelDeclarationRequest := do
  keys value ["kind", "declaration"]
  let declaration ← field value "declaration"
  match ← fieldString value "kind" with
  | "constant" =>
      match ← tagged declaration [("definition", ["k", "n", "lp", "t", "v", "s", "h"]),
        ("theorem", ["k", "n", "lp", "t", "v"])] with
      | "definition" =>
          if (← fieldString declaration "s") != "safe" then
            unsupported "definition safety outside canonical provider scope"
          else
            let hints ← field declaration "h"
            keys hints ["k", "h"]
            if (← fieldString hints "k") != "regular" then
              unsupported "definition hint outside canonical provider scope"
            else
              let height ← natural (← field hints "h")
              if height > 4294967295 then bad "definition height overflow"
              else return .definitionDecl {
                base := (← decodeBase declaration)
                value := (← decodeExpr 4096 (← field declaration "v"))
                hints := .regular height
                safety := .safe
              }
      | "theorem" => return .theoremDecl {
          base := (← decodeBase declaration)
          value := (← decodeExpr 4096 (← field declaration "v"))
        }
      | _ => unsupported "constant kind outside canonical provider scope"
  | "inductive" =>
      keys declaration ["lp", "np", "ts"]
      let types ← array (← field declaration "ts")
      if types.isEmpty then bad "empty inductive group"
      else return .nestedInductive {
        levelParams := (← (← array (← field declaration "lp")).mapM (decodeName 4096))
        numParams := (← natural (← field declaration "np"))
        types := (← types.mapM decodeInductive)
        isUnsafe := false
      }
  | _ => unsupported "admission kind outside canonical provider scope"

private def decodeBatch (source : String) : Except WireError (List Json) := do
  let root ← lift (Json.parse source)
  keys root ["format", "version", "admissions"]
  if (← fieldString root "format") != "proofscript-checked-admissions" then
    unsupported "admissions format"
  else if (← field root "version").getNat?.toOption != some 2 then
    unsupported "admissions version"
  else
    let values ← array (← field root "admissions")
    if values.length > 20000 then
      .error ⟨"resourceExhausted", "transport declaration count exceeded"⟩
    else return values

private def resourceName (value : PsKernelResourceError) : String :=
  match value with
  | .fuel => "fuel"
  | .recursionDepth => "recursionDepth"
  | .natSize => "natSize"
  | .cancelled => "cancelled"
  | .declarationLimit => "declarationLimit"
  | .hostStack => "hostStack"

private def kernelFailure (error : PsKernelError) : List (String × Json) :=
  match error with
  | .rejectedInvalid message => [("outcome", .str "rejectedInvalid"), ("message", .str message)]
  | .declinedUnsupported message => [("outcome", .str "declinedUnsupported"), ("message", .str message)]
  | .resourceExhausted resource message => [("outcome", .str "resourceExhausted"),
      ("resource", .str (resourceName resource)), ("message", .str message)]
  | .internalError message => [("outcome", .str "internalError"), ("message", .str message)]

private def envelope (fuel : Nat) (fields : List (String × Json)) : Json :=
  Json.mkObj ([
    ("protocol", .str "pskernel-canonical-provider/1"),
    ("provider", .str "pskernel-core-v1"),
    ("leanVersion", .str "4.35.0"),
    ("leanCommit", .str "eb6cafb7290e8bd5f2937522d8d804f58f02bafc"),
    ("fuel", .str (toString fuel)),
    ("scope", .str "canonical-v2-empty-environment")
  ] ++ fields)

private def wireFailure (fuel : Nat) (error : WireError)
    (extra : List (String × Json) := []) : Json :=
  envelope fuel ([("accepted", .bool false), ("outcome", .str error.outcome),
    ("stage", .str "transport"), ("message", .str error.message)] ++ extra)

private def runRequests (fuel : Nat) (requests : List Json)
    (session : PsKernelKernelSession) (index : Nat) : Json :=
  match requests with
  | [] => envelope fuel [("accepted", .bool true), ("outcome", .str "accepted"),
      ("stage", .str "complete"), ("declarationCount", toJson index),
      ("environmentSize", toJson (psKernelEnvironmentSize session.environment))]
  | request :: rest =>
      match decodeRequest request with
      | .error error => wireFailure fuel error [("declarationIndex", toJson index)]
      | .ok decoded =>
          match psKernelV1AdmitDeclaration session decoded with
          | .error error => envelope fuel ([("accepted", .bool false), ("stage", .str "kernel"),
              ("declarationIndex", toJson index)] ++ kernelFailure error)
          | .ok admitted => runRequests fuel rest admitted.session (index + 1)

def check (source : String) (fuel : Nat := 4096) : Json :=
  if source.utf8ByteSize > 16777216 then
    wireFailure fuel ⟨"resourceExhausted", "transport input byte limit exceeded"⟩
  else
    match decodeBatch source with
    | .error error => wireFailure fuel error
    | .ok requests =>
        let resources := { psKernelResourcePolicyDefault with fuel := fuel }
        match psKernelKernelSessionEmpty resources psKernelProviderDefault with
        | .error error => envelope fuel ([("accepted", .bool false), ("stage", .str "kernel")] ++ kernelFailure error)
        | .ok session =>
            match psKernelKernelSessionPreflight session with
            | .error error => envelope fuel ([("accepted", .bool false), ("stage", .str "kernel")] ++ kernelFailure error)
            | .ok _ => runRequests fuel requests session 0

end PSKernelCanonicalProvider

def main (args : List String) : IO UInt32 := do
  let fuel? := match args with
    | [] => some 4096
    | ["--fuel", value] => value.toNat?
    | _ => none
  match fuel? with
  | none =>
      IO.eprintln "usage: psc1_kernel_provider [--fuel 0..4096] < canonical-admissions.json"
      return 2
  | some fuel =>
      if fuel > 4096 then
        IO.eprintln "provider fuel cannot exceed the default 4096"
        return 2
      let source ← (← IO.getStdin).readToEnd
      IO.println (PSKernelCanonicalProvider.check source fuel).compress
      return 0
