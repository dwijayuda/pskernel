import Ps.BackendPhp.Module

private def natT : PsVerifiedIrType := .primitive .nat
private def strT : PsVerifiedIrType := .primitive .string
private def chainT : PsVerifiedIrType := .named "Chain" []
private def choiceT : PsVerifiedIrType := .named "Choice" []
private def n (value : Nat) : PsVerifiedIrExpr := .literal (.natural value)
private def p (name : String) (type : PsVerifiedIrType) : PsVerifiedIrParameter := {name, type}
private def b (field name : String) (type : PsVerifiedIrType) : PsVerifiedIrMatchBinding := {field, name, type}
private def call (name : String) (args : List PsVerifiedIrExpr) : PsVerifiedIrExpr := .call (.var name) [] args
private def chain : PsVerifiedIrInductive := {
  name := "Chain", typeParameters := [], constructors := [
    {name := "nil", fields := []},
    {name := "cons", fields := [{name := "head", type := natT}, {name := "tail", type := chainT}]}
  ]
}
private def choice : PsVerifiedIrInductive := {
  name := "Choice", typeParameters := [], constructors := [
    {name := "empty", fields := []},
    {name := "one", fields := [{name := "value", type := natT}]},
    {name := "three", fields := [
      {name := "left", type := natT}, {name := "text", type := strT}, {name := "right", type := natT}]}
  ]
}
private def module : PsVerifiedIrModule := {
  imports := [], structures := [], inductives := [chain, choice], declarations := [
    {name := "build", typeParameters := [], parameters := [p "fuel" natT, p "acc" chainT],
      resultType := chainT,
      body := .ifE (.intrinsic .natEq [] [.var "fuel", n 0]) (.var "acc")
        (call "build" [.intrinsic .natSub [] [.var "fuel", n 1],
          .constructor "Chain" "cons" [] [("head", .var "fuel"), ("tail", .var "acc")]])},
    {name := "length", typeParameters := [], parameters := [p "values" chainT, p "acc" natT],
      resultType := natT,
      body := .matchE "Chain" [] (.var "values") [
        ("nil", ([], .var "acc")),
        ("cons", ([b "head" "head" natT, b "tail" "rest" chainT],
          call "length" [.var "rest", .intrinsic .natAdd [] [.var "acc", n 1]]))]},
    {name := "run", typeParameters := [], parameters := [p "size" natT], resultType := natT,
      body := call "length" [call "build" [.var "size", .constructor "Chain" "nil" [] []], n 0]},
    {name := "read", typeParameters := [], parameters := [p "value" choiceT], resultType := natT,
      body := .matchE "Choice" [] (.var "value") [
        ("empty", ([], n 3)),
        ("one", ([b "value" "x" natT], .var "x")),
        ("three", ([b "right" "r" natT, b "text" "s" strT, b "left" "l" natT],
          .intrinsic .natAdd [] [.var "l", .var "r"]))]},
    {name := "empty", typeParameters := [], parameters := [], resultType := natT,
      body := call "read" [.constructor "Choice" "empty" [] []]},
    {name := "one", typeParameters := [], parameters := [], resultType := natT,
      body := call "read" [.constructor "Choice" "one" [] [("value", n 7)]]},
    {name := "three", typeParameters := [], parameters := [], resultType := natT,
      body := call "read" [.constructor "Choice" "three" [] [
        ("left", n 9), ("text", .literal (.string "λ🙂")), ("right", n 11)]]}
  ]
}
private def requireOk (value : Except String α) : IO α :=
  match value with
  | .error error => throw (IO.userError error)
  | .ok result => pure result

private def execute (path : String) (size : Nat) : IO String := do
  let result <- IO.Process.output {
    cmd := "php"
    args := #["-d", "memory_limit=1G", "dist/php-packed/consumer.php", path, toString size]
  }
  unless result.exitCode == 0 do throw (IO.userError ("PHP packed execution failed: " ++ result.stderr))
  pure result.stdout

def main : IO Unit := do
  let validated <- match psStrictValidateModule module with
    | .error _ => do
        let report := psCheckVerifiedIrModule psIrCheckDefaultOptions module
        for finding in report.findings do
          IO.println (finding.code ++ ":" ++ finding.owner ++ ":" ++ finding.path ++ ":" ++ finding.detail)
        throw (IO.userError "packed fixture did not strictly validate")
    | .ok validated => pure validated
  let reordered := { module with declarations := module.declarations.map (fun declaration =>
    if declaration.name == "three" then { declaration with body :=
      call "read" [.constructor "Choice" "three" [] [
        ("right", n 11), ("text", .literal (.string "λ🙂")), ("left", n 9)]] }
    else declaration) }
  match psStrictValidateModule reordered with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "noncanonical constructor field order admitted")
  let legacy <- requireOk (psPhpEmitModuleWithIoAndPolicies validated ["run", "empty", "one", "three"] false true false)
  let packed <- requireOk (psPhpEmitModuleWithIo validated ["run", "empty", "one", "three"] false)
  unless legacy.runtimeSource == packed.runtimeSource &&
      legacy.runtimeRequirements == packed.runtimeRequirements &&
      legacy.declarations == packed.declarations &&
      legacy.declarationLines == packed.declarationLines &&
      legacy.composer == packed.composer do
    throw (IO.userError "packed layout changed unrelated output metadata")
  IO.FS.createDirAll "dist/php-packed"
  IO.FS.writeFile "dist/php-packed/legacy.php" legacy.source
  IO.FS.writeFile "dist/php-packed/packed.php" packed.source
  IO.FS.writeFile "dist/php-packed/consumer.php"
    "<?php $api=require $argv[1]; echo json_encode([gmp_strval($api['run'](gmp_init($argv[2]))),gmp_strval($api['empty']),gmp_strval($api['one']),gmp_strval($api['three'])],JSON_THROW_ON_ERROR);"
  for size in [0, 1, 2, 31, 1000, 5000] do
    let old <- execute "dist/php-packed/legacy.php" size
    let actual <- execute "dist/php-packed/packed.php" size
    unless old == actual && actual == s!"[\"{size}\",\"3\",\"7\",\"20\"]" do
      throw (IO.userError "packed/legacy observations differ")
  let large <- execute "dist/php-packed/packed.php" 200000
  unless large == "[\"200000\",\"3\",\"7\",\"20\"]" do
    throw (IO.userError "packed large collection result mismatch")
  -- Owner-qualified same-tag layout lookup must not confuse field names.
  let other : PsVerifiedIrInductive := {
    name := "Other", typeParameters := [],
    constructors := [{name := "one", fields := [{name := "different", type := strT}]}] }
  let context : PsPhp.Context := .mk [] [] [] [] false true true [choice, other]
  let first <- requireOk (PsPhp.constructorFields context "Choice" "one")
  let second <- requireOk (PsPhp.constructorFields context "Other" "one")
  unless first == ["value"] && second == ["different"] do
    throw (IO.userError "owner-qualified constructor layout mismatch")
  IO.println "PSC1_PHP_PACKED_LAYOUT: strict IR; zero/one/three fields, canonical construction/noncanonical refusal/reordered bindings, Unicode, recursive lists, six retained-layout comparisons and200000-cell1G execution passed"
