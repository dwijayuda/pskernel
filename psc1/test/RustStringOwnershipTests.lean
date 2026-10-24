import RustStringOwnershipReference

private def natT : PsVerifiedIrType := .primitive .nat
private def strT : PsVerifiedIrType := .primitive .string
private def boolT : PsVerifiedIrType := .primitive .bool
private def p (name : String) (type : PsVerifiedIrType) : PsVerifiedIrParameter := {name, type}
private def n (value : Nat) : PsVerifiedIrExpr := .literal (.natural value)
private def intrinsic (op : PsVerifiedIrIntrinsic) (args : List PsVerifiedIrExpr) : PsVerifiedIrExpr := .intrinsic op [] args
private def call (name : String) (args : List PsVerifiedIrExpr) : PsVerifiedIrExpr := .call (.var name) [] args
private def reader (name : String) (op : PsVerifiedIrIntrinsic) (result : PsVerifiedIrType) : PsVerifiedIrDeclaration :=
  {name, typeParameters := [], parameters := [p "text" strT,p "position" natT],resultType := result,
   body := intrinsic op [.var "text",.var "position"]}
private def left : PsVerifiedIrExpr := intrinsic .natSub [.var "fuel",n 1]
private def next : PsVerifiedIrExpr := call "readNext" [.var "text",.var "position"]
private def added : PsVerifiedIrExpr := intrinsic .natAdd [.var "count",n 1]
private def scanner (name : String) (alias : Bool) : PsVerifiedIrDeclaration :=
  let recur := if alias then
      .letE "left" natT left
        (.letE "again" (.function [strT,natT,natT] natT)
          (.lambda [p "s" strT,p "pos" natT,p "acc" natT] natT
            (call name [.var "left",.var "s",.var "pos",.var "acc"]))
          (call "again" [.var "text",next,added]))
    else call name [left,.var "text",next,added]
  {name, typeParameters := [], parameters := [p "fuel" natT,p "text" strT,p "position" natT,p "count" natT],
   resultType := natT,
   body := .ifE (intrinsic .natEq [.var "fuel",n 0]) (.var "count")
     (.ifE (call "readEnd" [.var "text",.var "position"]) (.var "count")
       (.letE "character" (.primitive .char) (call "readGet" [.var "text",.var "position"]) recur))}
private def workerScanner : PsVerifiedIrDeclaration :=
  let original := scanner "scanWorker" false
  { original with
    parameters := [p "fuel" natT,p "__workerString" strT,p "position" natT,p "count" natT]
    body := .letE "text" strT (.var "__workerString") original.body}
private def pairResult : PsVerifiedIrExpr :=
  intrinsic .natAdd [intrinsic .natMul [intrinsic .stringLength [.var "a"],n 100],intrinsic .stringLength [.var "b"]]
private def paired (name : String) (duplicate : Bool) : PsVerifiedIrDeclaration :=
  {name, typeParameters := [],parameters := [p "fuel" natT,p "a" strT,p "b" strT],resultType := natT,
   body := .ifE (intrinsic .natEq [.var "fuel",n 0]) pairResult
     (call name [left, (if duplicate then .var "a" else .var "b"), .var "a"])}
private def later : PsVerifiedIrDeclaration :=
  {name := "later",typeParameters := [],parameters := [p "fuel" natT,p "text" strT,p "count" natT],resultType := natT,
   body := .ifE (intrinsic .natEq [.var "fuel",n 0]) (.var "count")
     (call "later" [left,.var "text",intrinsic .stringLength [.var "text"]])}
private def shadow : PsVerifiedIrDeclaration :=
  {name := "shadow",typeParameters := [],parameters := [p "text" strT],resultType := boolT,
   body := .letE "readEnd" (.function [strT,natT] boolT)
     (.lambda [p "s" strT,p "pos" natT] boolT (.literal (.bool true)))
     (call "readEnd" [.var "text",n 0])}
private def module : PsVerifiedIrModule :=
  {imports := [],structures := [],inductives := [],declarations := [
    reader "readEnd" .stringAtEnd boolT, reader "readNext" .stringNext natT,
    reader "readGet" .stringGet (.primitive .char),scanner "scan" false,
    scanner "scanAlias" true,workerScanner,paired "swap" false,paired "duplicate" true,later,shadow]}
private def spineT : PsVerifiedIrType := .named "Spine" []
private def emptySpine : PsVerifiedIrExpr := .constructor "Spine" "nil" [] []
private def spineModule : PsVerifiedIrModule := {
  imports := [],structures := []
  inductives := [{name := "Spine",typeParameters := [],constructors := [
    {name := "nil",fields := []},
    {name := "cons",fields := [
      {name := "head",type := natT},{name := "tail",type := spineT}]}]}]
  declarations := [
    {name := "makeSpine",typeParameters := [],parameters := [p "fuel" natT,p "acc" spineT],
     resultType := spineT,
     body := .ifE (intrinsic .natEq [.var "fuel",n 0]) (.var "acc")
       (call "makeSpine" [left,.constructor "Spine" "cons" [] [("head",n 1),("tail",.var "acc")]])},
    {name := "countSpine",typeParameters := [],parameters := [p "xs" spineT,p "count" natT],
     resultType := natT,
     body := .matchE "Spine" [] (.var "xs") [
       ("nil",([], .var "count")),
       ("cons",([.mk "head" "head" natT,.mk "tail" "rest" spineT],
         call "countSpine" [.var "rest",added]))]},
    {name := "probeSpine",typeParameters := [],parameters := [p "size" natT],resultType := natT,
     body := .letE "xs" spineT (call "makeSpine" [.var "size",emptySpine])
       (.letE "shared" spineT (.var "xs")
         (intrinsic .natAdd [call "countSpine" [.var "xs",n 0],call "countSpine" [.var "shared",n 0]]))}
  ]
}
private def emitSpineLegacy (isPublic : Bool) : Except PsRustEmitError String := do
  let inductives <- spineModule.inductives.mapM
    (RustStringOwnershipReference.psRustEmitInductiveWithVisibility isPublic)
  let declarations <- spineModule.declarations.mapM
    (fun d => RustStringOwnershipReference.psRustEmitDeclarationWithVisibility
      (isPublic || d.name == "probeSpine") spineModule.declarations [] d)
  pure (psRustAssembleModuleSource [] inductives declarations)

private def require (name : String) (ok : Bool) : IO Unit := do
  if !ok then throw (IO.userError ("PSC1_RUST_STRING_OWNERSHIP_FAIL: " ++ name))
private def emit (legacy : Bool) : Except PsRustEmitError String := do
  if legacy then
    let declarations <- module.declarations.mapM (RustStringOwnershipReference.psRustEmitDeclarationWithVisibility true module.declarations [])
    pure (psRustAssembleModuleSource [] [] declarations)
  else psRustEmitModule module
def main : IO Unit := do
  match psStrictValidateModule module with
  | .error _ => throw (IO.userError "ownership fixture must pass strict IR")
  | .ok _ => pure ()
  require "exact reader discovered" ((psRustFindStringReader module.declarations "readEnd").isSome)
  require "local callee shadow refuses inlining"
    ((psRustCallStringReader module.declarations ["readEnd"] (.var "readEnd") []).isNone)
  require "dynamic call refuses inlining"
    ((psRustCallStringReader module.declarations [] (.lambda [] boolT (.literal (.bool true))) []).isNone)
  require "type arguments refuse inlining"
    ((psRustCallStringReader module.declarations [] (.var "readEnd") [strT]).isNone)
  let bad := { (reader "bad" .stringAtEnd boolT) with body := intrinsic .stringAtEnd [.var "position",.var "text"] }
  require "reordered forwarding refuses inlining" ((psRustFindStringReader [bad] "bad").isNone)
  require "allocating intrinsic is not a reader" (!psRustReadOnlyStringIntrinsic .stringAppend)
  require "same-position String selects move" (psRustTailStringPassthrough (p "text" strT) (.var "text"))
  require "different variable retains snapshot" (!psRustTailStringPassthrough (p "text" strT) (.var "other"))
  require "other types retain existing path" (!psRustTailStringPassthrough (p "text" natT) (.var "text"))
  require "wrapper argument fuel checks retained"
    (match psRustEmitExprWorker module.declarations 1 ["text","position"]
      (call "readEnd" [.var "text",.var "position"]) with
     | .error .fuelExhausted => true | _ => false)
  require "malformed wrapper arity refused"
    (match psRustEmitExprWorker module.declarations 8 ["text"] (call "readEnd" [.var "text"]) with
     | .error .intrinsicArity => true | _ => false)
  require "worker alias moves when the original name is dead"
    (psRustLetValuePrinted 64 ["source"] strT (.var "source") (.var "alias") "(source).clone()" == "source")
  require "escaping source capture retains a copy"
    (psRustLetValuePrinted 64 ["source"] strT (.var "source") (.lambda [] strT (.var "source")) "(source).clone()" == "(source).clone()")
  require "exhausted liveness keeps the copy"
    (psRustLetValuePrinted 0 ["source"] strT (.var "source") (.var "alias") "(source).clone()" == "(source).clone()")
  require "renamed worker String can move"
    ((psRustTailStringMove ["alias"] (p "worker" strT) (.var "alias") []).isSome)
  require "duplicate move waits for the last occurrence"
    ((psRustTailStringMove ["alias"] (p "worker" strT) (.var "alias") [.var "alias"]).isNone)
  IO.FS.createDirAll "dist/rust-string-ownership"
  for legacy in [false,true] do
    match emit legacy with
    | .error _ => throw (IO.userError "ownership fixture emission refused")
    | .ok text =>
        IO.FS.writeFile ("dist/rust-string-ownership/" ++ (if legacy then "legacy.rs" else "current.rs")) text
  let checked <- match psStrictValidateModule spineModule with
    | .error _ => throw (IO.userError "recursive sharing fixture strict IR refused")
    | .ok checked => pure checked
  for legacy in [false,true] do
    for isPublic in [false,true] do
      let output <- if legacy then
          match emitSpineLegacy isPublic with
          | .error _ => throw (IO.userError "legacy recursive fixture refused")
          | .ok text => pure text
        else if isPublic then
          match psRustEmitModule spineModule with
          | .error _ => throw (IO.userError "public recursive fixture refused")
          | .ok text => pure text
        else
          match psRustEmitSelectedValidatedModule checked ["probeSpine"] [] with
          | .error error => throw (IO.userError error)
          | .ok text => pure text
      IO.FS.writeFile ("dist/rust-string-ownership/spine-" ++
        (if legacy then "legacy" else "current") ++ (if isPublic then "-public.rs" else "-private.rs")) output
  for value in spineModule.inductives do
    match psRustEmitInductiveWithVisibility true value,
        RustStringOwnershipReference.psRustEmitInductiveWithVisibility true value with
    | .ok current,.ok legacy => require "public enum bytes preserve move-out ABI" (current == legacy)
    | _,_ => throw (IO.userError "public enum ABI emission refused")
  IO.println "PSC1_RUST_STRING_OWNERSHIP_NATIVE: checked structural reader/arity/shadow/type/fuel guards; retained original and current emitters"
