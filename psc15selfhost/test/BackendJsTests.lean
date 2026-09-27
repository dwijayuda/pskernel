import Ps.BackendJs.Module
import Ps.BackendTs.Module

def jsFixtureExprDecl (name : String) (type : PsVerifiedIrPrimitiveType)
    (body : PsVerifiedIrExpr) : PsVerifiedIrDeclaration :=
  { name := name, typeParameters := [], parameters := [],
    resultType := .primitive type, body := body }

def jsFixtureDecl (name : String) (type : PsVerifiedIrPrimitiveType)
    (literal : PsVerifiedIrLiteral) : PsVerifiedIrDeclaration :=
  jsFixtureExprDecl name type (.literal literal)

def jsFixtureFunctionDecl (name parameterName : String)
    (parameterType resultType : PsVerifiedIrPrimitiveType)
    (body : PsVerifiedIrExpr) : PsVerifiedIrDeclaration :=
  { name := name, typeParameters := [],
    parameters := [{ name := parameterName, type := .primitive parameterType }],
    resultType := .primitive resultType, body := body }

def jsFixtureModule : PsVerifiedIrModule :=
  { psVerifiedIrModuleEmpty with declarations := [
    jsFixtureDecl "largeNat" .nat (.natural 9007199254740993123456789),
    jsFixtureDecl "negativeInt" .int (.integer (-9007199254740993123456789)),
    jsFixtureDecl "zero" .nat (.natural 0),
    jsFixtureDecl "yes" .bool (.bool true),
    jsFixtureDecl "no" .bool (.bool false),
    jsFixtureDecl "text" .string (.string "quote\" slash\\ newline\n tab\t 😀 é"),
    jsFixtureDecl "empty" .string (.string ""),
    jsFixtureDecl "control" .string (.string (String.singleton (Char.ofNat 0))),
    jsFixtureDecl "lineSeparators" .string (.string "  "),
    jsFixtureDecl "nothing" .unit .unit,
    jsFixtureDecl "__psc_js_0" .nat (.natural 7),
    jsFixtureExprDecl "letAlias" .nat
      (.letE "x" (.primitive .nat) (.literal (.natural 42)) (.var "x")),
    jsFixtureExprDecl "shadowed" .nat
      (.letE "x" (.primitive .nat) (.literal (.natural 1))
        (.letE "x" (.primitive .nat) (.literal (.natural 2)) (.var "x"))),
    jsFixtureExprDecl "renamedLocal" .nat
      (.letE "a-b" (.primitive .nat) (.literal (.natural 3)) (.var "a-b")),
    jsFixtureFunctionDecl "identity" "value" .nat .nat (.var "value")
  ] }

def jsRequireError (label : String) (module : PsVerifiedIrModule) : IO Unit := do
  match psJsEmitModule module with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError s!"accepted invalid JS fixture: {label}")

def main (args : List String) : IO Unit := do
  let out := args.head!
  let declaration := jsFixtureDecl "x" .nat (.natural 1)
  for name in ["", "default", "class", "await", "x;throw 1;//", "a-b", "a.b", "1x", "é"] do
    jsRequireError s!"name {name}" { psVerifiedIrModuleEmpty with
      declarations := [{ declaration with name := name }] }
  jsRequireError "duplicates" { psVerifiedIrModuleEmpty with declarations := [declaration, declaration] }
  jsRequireError "type mismatch" { psVerifiedIrModuleEmpty with
    declarations := [{ declaration with resultType := .primitive .int }] }
  jsRequireError "unknown type" { psVerifiedIrModuleEmpty with
    declarations := [{ declaration with resultType := .unknown }] }
  jsRequireError "free variable" { psVerifiedIrModuleEmpty with
    declarations := [{ declaration with body := .var "missing" }] }
  jsRequireError "let value type mismatch" { psVerifiedIrModuleEmpty with
    declarations := [jsFixtureExprDecl "badLet" .nat
      (.letE "x" (.primitive .int) (.literal (.natural 1)) (.var "x"))] }
  jsRequireError "nonprimitive parameter" { psVerifiedIrModuleEmpty with
    declarations := [{ declaration with parameters := [
      { name := "a", type := .function [.primitive .nat] (.primitive .nat) }] }] }
  jsRequireError "generic" { psVerifiedIrModuleEmpty with
    declarations := [{ declaration with typeParameters := [{name := "T"}] }] }
  jsRequireError "machine integer" { psVerifiedIrModuleEmpty with
    declarations := [jsFixtureDecl "machine" .uint8 (.machineInteger .uint8 1)] }
  jsRequireError "import" { psVerifiedIrModuleEmpty with imports := [
    { localName := "x", source := "evil", importedName := "x", type := .unknown }] }
  jsRequireError "structure" { psVerifiedIrModuleEmpty with structures := [
    { name := "S", typeParameters := [], fields := [] }] }
  jsRequireError "inductive" { psVerifiedIrModuleEmpty with inductives := [
    { name := "I", typeParameters := [], constructors := [] }] }
  let .ok direct := psJsEmitModule jsFixtureModule | throw (IO.userError "JS lexical emission failed")
  let .ok again := psJsEmitModule jsFixtureModule | throw (IO.userError "second emission failed")
  unless direct == again do throw (IO.userError "nondeterministic emission")
  let .ok empty := psJsEmitModule psVerifiedIrModuleEmpty | throw (IO.userError "empty module failed")
  let .ok reference := psTsEmitModule jsFixtureModule | throw (IO.userError "TS oracle failed")
  IO.FS.writeFile (out ++ "/direct.mjs") direct
  IO.FS.writeFile (out ++ "/empty.mjs") empty
  IO.FS.writeFile (out ++ "/reference.ts") reference
  IO.println "BACKEND_JS_LEAN_TESTS: PASS"
