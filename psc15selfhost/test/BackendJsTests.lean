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

def jsFixtureBinaryFunctionDecl (name firstName secondName : String)
    (firstType secondType resultType : PsVerifiedIrPrimitiveType)
    (body : PsVerifiedIrExpr) : PsVerifiedIrDeclaration :=
  { name := name, typeParameters := [],
    parameters := [
      { name := firstName, type := .primitive firstType },
      { name := secondName, type := .primitive secondType }
    ],
    resultType := .primitive resultType, body := body }

def jsDifferentialDeclarations : List PsVerifiedIrDeclaration :=
  [
    jsFixtureDecl "largeNat" .nat (.natural 9007199254740993123456789),
    jsFixtureDecl "negativeInt" .int (.integer (-9007199254740993123456789)),
    jsFixtureDecl "zero" .nat (.natural 0),
    jsFixtureDecl "yes" .bool (.bool true),
    jsFixtureDecl "no" .bool (.bool false),
    jsFixtureDecl "text" .string (.string "quote\" slash\\ newline\n tab\t 😀 é"),
    jsFixtureDecl "empty" .string (.string ""),
    jsFixtureDecl "control" .string (.string (String.singleton (Char.ofNat 0))),
    jsFixtureDecl "lineSeparators" .string
      (.string ((String.singleton (Char.ofNat 8232)) ++ (String.singleton (Char.ofNat 8233)))),
    jsFixtureDecl "nothing" .unit .unit,
    jsFixtureDecl "__psc_js_0" .nat (.natural 7),
    jsFixtureExprDecl "letAlias" .nat
      (.letE "x" (.primitive .nat) (.literal (.natural 42)) (.var "x")),
    jsFixtureExprDecl "shadowed" .nat
      (.letE "x" (.primitive .nat) (.literal (.natural 1))
        (.letE "x" (.primitive .nat) (.literal (.natural 2)) (.var "x"))),
    jsFixtureFunctionDecl "identity" "value" .nat .nat (.var "value"),
    jsFixtureFunctionDecl "choose" "flag" .bool .nat
      (.ifE
        (.var "flag")
        (.literal (.natural 10))
        (.literal (.natural 20))),
    jsFixtureFunctionDecl "callIdentity" "value" .nat .nat
      (.call (.var "identity") [] [(.var "value")]),
    jsFixtureFunctionDecl "callIdentityLet" "value" .nat .nat
      (.call (.var "identity") [] [
        (.letE "temporary" (.primitive .nat) (.var "value") (.var "temporary"))]),
    jsFixtureFunctionDecl "callSecond" "value" .nat .nat
      (.call (.var "second") [] [(.literal (.natural 11)), (.var "value")]),
    jsFixtureBinaryFunctionDecl "second" "left" "right" .nat .nat .nat
      (.var "right")
  ]

def jsDirectOnlyDeclarations : List PsVerifiedIrDeclaration :=
  [
    jsFixtureFunctionDecl "callCapturedLambda" "value" .nat .nat
      (.letE "captured" (.primitive .nat) (.var "value")
        (.call
          (.lambda
            [{ name := "ignored", type := .primitive .nat }]
            (.primitive .nat)
            (.var "captured"))
          []
          [(.literal (.natural 0))])),
    jsFixtureFunctionDecl "callInlineLambdaArgument" "value" .nat .nat
      (.call (.var "identity") [] [
        (.call
          (.lambda
            [{ name := "inner", type := .primitive .nat }]
            (.primitive .nat)
            (.var "inner"))
          []
          [(.var "value")])])
  ]

def jsDifferentialFixtureModule : PsVerifiedIrModule :=
  { psVerifiedIrModuleEmpty with declarations := jsDifferentialDeclarations }

def jsFixtureModule : PsVerifiedIrModule :=
  { psVerifiedIrModuleEmpty with declarations :=
      jsDifferentialDeclarations ++ jsDirectOnlyDeclarations ++ [
        jsFixtureExprDecl "renamedLocal" .nat
          (.letE "a-b" (.primitive .nat) (.literal (.natural 3)) (.var "a-b"))
      ] }

def jsRequireError (label : String) (module : PsVerifiedIrModule) : IO Unit := do
  match psJsEmitModule module with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError s!"accepted invalid JS fixture: {label}")

def main (args : List String) : IO Unit := do
  let out := args.head!
  let declaration := jsFixtureDecl "x" .nat (.natural 1)
  let identity := jsFixtureFunctionDecl "identity" "value" .nat .nat (.var "value")
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
  jsRequireError "if condition type mismatch" { psVerifiedIrModuleEmpty with
    declarations := [jsFixtureExprDecl "badIf" .nat
      (.ifE (.literal (.natural 1)) (.literal (.natural 2)) (.literal (.natural 3)))] }
  jsRequireError "unknown call target" { psVerifiedIrModuleEmpty with
    declarations := [jsFixtureFunctionDecl "caller" "value" .nat .nat
      (.call (.var "missing") [] [(.var "value")])] }
  jsRequireError "shadowed call target" { psVerifiedIrModuleEmpty with
    declarations := [identity,
      jsFixtureFunctionDecl "caller" "identity" .nat .nat
        (.call (.var "identity") [] [(.literal (.natural 1))])] }
  jsRequireError "let-shadowed call target" { psVerifiedIrModuleEmpty with
    declarations := [identity,
      jsFixtureFunctionDecl "caller" "value" .nat .nat
        (.letE "identity" (.primitive .nat) (.var "value")
          (.call (.var "identity") [] [(.literal (.natural 1))]))] }
  jsRequireError "eager forward call" { psVerifiedIrModuleEmpty with
    declarations := [
      jsFixtureExprDecl "eager" .nat
        (.call (.var "later") [] [(.literal (.natural 1))]),
      jsFixtureFunctionDecl "later" "value" .nat .nat (.var "value")
    ] }
  jsRequireError "call type arguments" { psVerifiedIrModuleEmpty with
    declarations := [identity,
      jsFixtureFunctionDecl "caller" "value" .nat .nat
        (.call (.var "identity") [(.primitive .nat)] [(.var "value")])] }
  jsRequireError "call zero arguments" { psVerifiedIrModuleEmpty with
    declarations := [identity,
      jsFixtureExprDecl "caller" .nat (.call (.var "identity") [] [])] }
  jsRequireError "call too many arguments" { psVerifiedIrModuleEmpty with
    declarations := [identity,
      jsFixtureFunctionDecl "caller" "value" .nat .nat
        (.call (.var "identity") [] [(.var "value"), (.var "value")])] }
  jsRequireError "call result type mismatch" { psVerifiedIrModuleEmpty with
    declarations := [identity,
      jsFixtureFunctionDecl "caller" "value" .nat .int
        (.call (.var "identity") [] [(.var "value")])] }
  jsRequireError "lambda result type mismatch" { psVerifiedIrModuleEmpty with
    declarations := [
      jsFixtureFunctionDecl "caller" "value" .nat .nat
        (.call
          (.lambda
            [{ name := "inner", type := .primitive .nat }]
            (.primitive .int)
            (.var "inner"))
          []
          [(.var "value")])
    ] }
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
  let .ok reference := psTsEmitModule jsDifferentialFixtureModule | throw (IO.userError "TS oracle failed")
  IO.FS.writeFile (out ++ "/direct.mjs") direct
  IO.FS.writeFile (out ++ "/empty.mjs") empty
  IO.FS.writeFile (out ++ "/reference.ts") reference
  IO.println "BACKEND_JS_LEAN_TESTS: PASS"
