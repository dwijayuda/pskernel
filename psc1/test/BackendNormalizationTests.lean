import Ps.Host.DirectBackend
import Ps.BackendJs.Print
import Ps.BackendRust.RuntimePlan
import Ps.BackendRust.Type

private def require (name : String) (condition : Bool) : IO Unit := do
  if !condition then throw (IO.userError ("PSC1_BACKEND_NORMALIZATION_FAIL: " ++ name))
  IO.println ("PSC1_BACKEND_NORMALIZATION_PASS: " ++ name)

def main : IO Unit := do
  let plain : PsJsIrModule := {
    imports := []
    declarations := [{ name := "identity", parameters := [{ name := "value" }], body := .var "value" }]
  }
  require "plain module selects no runtime"
    (psJsSelectedRuntimeRequirements plain == [] && psJsSelectedRuntimeSource plain == "")
  let utf8 : PsJsIrModule := {
    imports := []
    declarations := [{
      name := "advance", parameters := [{ name := "text" }, { name := "offset" }]
      body := .matchE (.var "packet") [
        ("Packet", [], .record [("next", .runtime .stringNext [.var "text", .var "offset"])])
      ]
    }]
  }
  require "UTF8 operation nested in match record selects exact helper group"
    (psJsSelectedRuntimeRequirements utf8 == ["utf8-byte-index"] &&
      psJsSelectedRuntimeSource utf8 == psJsStringRuntimeSupport)
  let recursive : PsJsIrDeclaration := {
    name := "repeat", parameters := [{ name := "n" }]
    body := .binary .bigintAdd (.literal (.natural 1)) (.call (.var "repeat") [.var "n"])
  }
  let combined : PsJsIrModule := { imports := [], declarations := recursive :: utf8.declarations }
  require "structured non-tail recursion and UTF8 select groups in stable requirement order"
    (psJsSelectedRuntimeRequirements combined == ["generator-stack", "utf8-byte-index"])
  require "runtime source keeps UTF8-before-stack byte order"
    (psJsSelectedRuntimeSource combined == psJsStringRuntimeSupport ++ psJsStackRuntimeSupport)
  let rust : PsVerifiedIrModule := {
    imports := [], structures := [], inductives := []
    declarations := [{
      name := "select", typeParameters := []
      parameters := [{ name := "text", type := .primitive .string }]
      resultType := .primitive .char
      body := .ifE (.literal (.bool true))
        (.intrinsic .stringGet [] [.var "text", .literal (.natural 0)])
        (.intrinsic .charOfNat [] [.literal (.natural 65)])
    }]
  }
  let plan := psRustPlanRuntime rust
  require "nested Rust requirements select catalogue order and dependency pins"
    (plan.requirements == ["num-bigint@0.4.6", "num-traits@0.2.19",
      "__ps_nat_lit", "__ps_char_of_nat", "__ps_string_get"])
  let expected := "use num_bigint::BigUint as PsNat;\n" ++
    "use num_traits::{ToPrimitive, Zero};\n" ++
    "use std::str::FromStr;\n" ++
    (psRustRuntimeHelperCatalogue.filter (fun helper =>
      ["__ps_nat_lit", "__ps_char_of_nat", "__ps_string_get"].contains helper.name)).foldl
        (fun text helper => text ++ helper.source) ""
  require "Rust planner emits exactly the selected original catalogue bytes"
    (plan.source == expected)
  require "empty Rust module selects no dependencies"
    ((psRustPlanRuntime psVerifiedIrModuleEmpty).source == "" &&
      (psRustPlanRuntime psVerifiedIrModuleEmpty).requirements == [])
  let scalar : PsVerifiedIrType := .primitive .nat
  let callback : PsVerifiedIrType := .function [scalar] scalar
  require "direct nested closure arrows remain supported"
    (psRustDirectClosureTypeSupported (.function [callback] callback))
  require "named aggregate containing an owned closure is supported"
    (psRustDirectClosureTypeSupported (.named "Array" [callback]))
  require "unknown nested storage remains refused"
    (!psRustDirectClosureTypeSupported (.named "Array" [.unknown]))
  require "unknown closure storage remains refused"
    (!psRustDirectClosureTypeSupported .unknown)
  require "unchanged traversal boundary refuses at zero"
    (!psRustDirectClosureTypeSupportedWithFuel 0 scalar)
  require "direct closure printer keeps owned Rc representation"
    (match psRustEmitClosureValueType callback with
      | .ok printed => printed == "std::rc::Rc<dyn Fn(PsNat) -> PsNat + 'static>"
      | .error _ => false)

  for source in [
    "private def hidden : Nat := 1\n",
    "def first : Nat := 1\nprivate def hidden : Nat := 2\n",
    "def first : Nat := 1\nprivate partial def hidden (n : Nat) : Nat := n\n"
  ] do
    require "unsupported private token refuses in Lean without expression absorption"
      (match psParseLeanSource source with | .error _ => true | .ok _ => false)
    require "unsupported private token refuses in PS without expression absorption"
      (match psParseProofScriptSource source with | .error _ => true | .ok _ => false)
  IO.FS.createDirAll "dist/architecture-native/visibility"
  for extension in ["lean", "ps"] do
    let path := "dist/architecture-native/visibility/Entry." ++ extension
    IO.FS.writeFile path
      "def Ps.Internal.Visibility.hidden : Nat := 7\ndef visible : Nat := Ps.Internal.Visibility.hidden\n"
    let prepared <- psHostDirectPrepare path
    require ("qualified internal helper is retained and hidden from entry API: " ++ extension)
      (prepared.publicNames == ["visible"] &&
        prepared.declarationNames.any (fun entry =>
          psNameToString entry.1 == "Ps.Internal.Visibility.hidden"))
    let kind := if extension == "lean" then PsCompilerSourceKind.lean else .proofScript
    require ("unqualified internal helper remains unavailable: " ++ extension)
      (match psCompilerPrepareSource kind
          "def Ps.Internal.Visibility.hidden : Nat := 7\ndef visible : Nat := hidden\n" with
        | .error _ => true
        | .ok _ => false)
