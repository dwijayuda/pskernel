import Lean
import Ps.KernelCore.API.Dag
import Ps.KernelCore.Research.ExprV2PagedImport

/- Frozen reference definitions are copied from Core/Name.lean at
   f9e9b20f92ce2ffa4a666acaf55aa8852949f589, with identifiers renamed only. -/
namespace PsKernelNameWorkerRegression

def originalStringEqFromWithFuel
    (fuel : Nat) :
    String -> String -> Nat -> Nat -> Bool :=
  match fuel with
  | Nat.zero =>
      fun
        (_left : String)
        (_right : String)
        (_leftPos : Nat)
        (_rightPos : Nat) =>
        false
  | Nat.succ remaining =>
      let smaller :
          String -> String -> Nat -> Nat -> Bool :=
        originalStringEqFromWithFuel remaining;
      fun
        (left : String)
        (right : String)
        (leftPos : Nat)
        (rightPos : Nat) =>
        if String.Pos.Raw.atEnd left (String.Pos.Raw.mk leftPos) then
          String.Pos.Raw.atEnd right (String.Pos.Raw.mk rightPos)
        else if String.Pos.Raw.atEnd right (String.Pos.Raw.mk rightPos) then
          false
        else
          let leftChar :=
            String.Internal.get left (String.Pos.Raw.mk leftPos);
          let rightChar :=
            String.Internal.get right (String.Pos.Raw.mk rightPos);
          if Nat.beq (Char.toNat leftChar) (Char.toNat rightChar) then
            smaller
              left
              right
              (String.Pos.Raw.byteIdx
                (String.Pos.Raw.next
                  left
                  (String.Pos.Raw.mk leftPos)))
              (String.Pos.Raw.byteIdx
                (String.Pos.Raw.next
                  right
                  (String.Pos.Raw.mk rightPos)))
          else
            false

def originalStringEq
    (left : String)
    (right : String) : Bool :=
  if Nat.beq (String.utf8ByteSize left) (String.utf8ByteSize right) then
    originalStringEqFromWithFuel
      (Nat.succ (String.utf8ByteSize left))
      left
      right
      0
      0
  else
    false

def originalNameEq
    (left : PsKernelName) :
    PsKernelName -> Bool :=
  match left with
  | PsKernelName.anonymous =>
      fun (right : PsKernelName) =>
        match right with
        | PsKernelName.anonymous => true
        | _ => false
  | PsKernelName.str leftParent leftValue =>
      let smaller : PsKernelName -> Bool :=
        originalNameEq leftParent;
      fun (right : PsKernelName) =>
        match right with
        | PsKernelName.str rightParent rightValue =>
            if originalStringEq leftValue rightValue then
              smaller rightParent
            else
              false
        | _ => false
  | PsKernelName.num leftParent leftValue =>
      let smaller : PsKernelName -> Bool :=
        originalNameEq leftParent;
      fun (right : PsKernelName) =>
        match right with
        | PsKernelName.num rightParent rightValue =>
            if Nat.beq leftValue rightValue then
              smaller rightParent
            else
              false
        | _ => false

private def require (label : String) (condition : Bool) : IO Unit := do
  unless condition do throw (IO.userError ("PSC1_NAME_WORKER_FAIL " ++ label))

private def expect {a : Type} : Except String a -> IO a
  | .ok value => pure value
  | .error error => throw (IO.userError error)

private def expectPublic {a : Type} : Except PsKernelError a -> IO a
  | .ok value => pure value
  | .error _ => throw (IO.userError "name-worker public fixture failed")

private def rejectedInvalid {a : Type} : Except PsKernelError a -> Bool
  | .error (.rejectedInvalid _) => true
  | _ => false

private def nm (value : String) : PsKernelName := .str .anonymous value

private def officialName : PsKernelName -> Lean.Name
  | .anonymous => .anonymous
  | .str parent value => .str (officialName parent) value
  | .num parent value => .num (officialName parent) value

private def level : Nat -> PsKernelLevel
  | 0 => .zero
  | n + 1 => .succ (level n)

private def officialLevel : Nat -> Lean.Level
  | 0 => .zero
  | n + 1 => .succ (officialLevel n)

private def rawCompare
    (label : String) (fuel : Nat) (left right : String) (lp rp : Nat) : IO Unit := do
  let original := originalStringEqFromWithFuel fuel left right lp rp
  require (label ++ "-worker")
    (psKernelStringEqFromWorkerWithFuel fuel left right lp rp == original)
  require (label ++ "-public")
    (psKernelStringEqFromWithFuel fuel left right lp rp == original)

private def stringMatrix : IO Unit := do
  let words := ["","A","B","é","é","🙂","L∃∀N",String.ofList [Char.ofNat 0,'x']]
  let mut raw := 0
  let mut full := 0
  for left in words do
    for right in words do
      let reference := originalStringEq left right
      require "full-string-frozen" (psKernelStringEq left right == reference)
      require "full-string-official" (psKernelStringEq left right == (left == right))
      full := full + 1
      for lp in [0,1,2,3,4,7,8,9] do
        for rp in [0,1,2,3,4,7,8,9] do
          for fuel in [0,1,2,4,8,16] do
            rawCompare "raw-matrix" fuel left right lp rp
            raw := raw + 1
  let huge := 1000000000000000000000000000023
  let controls : List (String × Nat × String × String × Nat × Nat × Bool) := [
    ("zero-empty",0,"","",0,0,false),
    ("zero-after-end",0,"A","B",9,9,false),
    ("one-empty",1,"","",0,0,true),
    ("one-char-exhausted",1,"A","A",0,0,false),
    ("two-char-complete",2,"A","A",0,0,true),
    ("current-mismatch",1,"A","B",0,0,false),
    ("left-end-only",1,"A","A",1,0,false),
    ("right-end-only",1,"A","A",0,1,false),
    ("both-arbitrary-end",1,"A","B",9,9,true),
    ("middle-two-byte-default",2,"é","A",1,0,true),
    ("middle-four-byte-default",2,"🙂","A",3,0,true),
    ("middle-three-default-short",3,"🙂","AAA",1,0,false),
    ("middle-three-default-enough",4,"🙂","AAA",1,0,true),
    ("huge-raw-positions",1,"α","β",huge,huge,true),
    ("distinct-normalizations",1,"é","é",0,0,false),
    ("one-unicode-scalar",2,"🙂","🙂",0,0,true)]
  for (label,fuel,left,right,lp,rp,answer) in controls do
    rawCompare label fuel left right lp rp
    require (label ++ "-exact") (psKernelStringEqFromWithFuel fuel left right lp rp == answer)
  let mut long := 0
  for count in [1,32,256,1024,4096] do
    let left := String.ofList (List.replicate count 'A')
    let mismatch := String.ofList ('B' :: List.replicate (count - 1) 'A')
    rawCompare "ascii-equal-insufficient" count left left 0 0
    require "ascii-equal-insufficient-exact"
      (!psKernelStringEqFromWithFuel count left left 0 0)
    rawCompare "ascii-equal-sufficient" (count + 1) left left 0 0
    require "ascii-equal-sufficient-exact"
      (psKernelStringEqFromWithFuel (count + 1) left left 0 0)
    rawCompare "ascii-first-mismatch" (count + 1) left mismatch 0 0
    require "ascii-first-mismatch-exact" (!psKernelStringEq left mismatch)
    long := long + 3
  for count in [1,32,256] do
    let text := String.ofList (List.replicate count '🙂')
    rawCompare "unicode-insufficient" count text text 0 0
    require "unicode-insufficient-exact" (!psKernelStringEqFromWithFuel count text text 0 0)
    rawCompare "unicode-sufficient" (count + 1) text text 0 0
    require "unicode-sufficient-exact" (psKernelStringEqFromWithFuel (count + 1) text text 0 0)
    require "unicode-byte-derived-public-budget"
      (psKernelStringEq text text && originalStringEq text text)
    long := long + 3
  require "string-matrix-counts" (raw == 24576 && full == 64 && controls.length == 16 && long == 24)
  IO.println "PSC1_NAME_WORKER_STRINGS_PASS raw=24576 full=64 controls=16 long=24"

private def deepName (seed : String) (depth : Nat) : PsKernelName := Id.run do
  let mut result := nm seed
  for i in [:depth] do
    result := if i % 2 == 0 then .num result i else .str result "🙂"
  return result

private def nameMatrix : IO Unit := do
  let base : List PsKernelName := [
    .anonymous,nm "",nm "A",nm "0",.num .anonymous 0,.num .anonymous 1,
    .num .anonymous 9007199254740993,.num .anonymous 9007199254806514,
    .str (nm "A") "B",nm "A.B",nm "é",nm "é"]
  let mut names := base
  for depth in [1,8,64,256] do
    names := names ++ [deepName "A" depth,deepName "B" depth]
  let mut comparisons := 0
  for left in names do
    let publicPartial := psKernelNameEq left
    for right in names do
      let frozen := originalNameEq left right
      let official := officialName left == officialName right
      require "name-frozen-agrees-with-official" (frozen == official)
      require "name-worker-exact" (psKernelNameEqWorker left right == frozen)
      require "name-public-partial-exact" (publicPartial right == frozen)
      comparisons := comparisons + 1
  let deep := deepName "A" 1024
  let same := deepName "A" 1024
  let parentMismatch := deepName "B" 1024
  let cases : List (PsKernelName × PsKernelName × Bool) := [
    (deep,same,true),
    (deep,parentMismatch,false),
    (.str deep "tail",.str same "Tail",false),
    (.str deep "1",.num same 1,false)]
  for (left,right,answer) in cases do
    require "deep-name-frozen" (originalNameEq left right == answer)
    require "deep-name-worker" (psKernelNameEqWorker left right == answer)
    require "deep-name-public" (psKernelNameEq left right == answer)
    require "deep-name-official" ((officialName left == officialName right) == answer)
  require "name-matrix-counts" (names.length == 20 && comparisons == 400 && cases.length == 4)
  IO.println "PSC1_NAME_WORKER_NAMES_PASS pairs=400 deep=4 maxDepth=1024"

private def publicNames : List PsKernelName :=
  let nameRoot := nm "NameWorker";
  [.str nameRoot "é",.str nameRoot "é",.str nameRoot "αβ",.str nameRoot "🙂",
    .str nameRoot "with.dot",.str (.str nameRoot "with") "dot",
    .num nameRoot 9007199254740993,.num nameRoot 9007199254806514,
    .str nameRoot "Plain",deepName "NameWorkerDeep" 32]

private structure PublicFixture where
  name : PsKernelName
  type : PsKernelExpr
  value : PsKernelExpr
  term : PsKernelExpr
  typeId : Nat
  valueId : Nat
  root : Nat

private def publicChecking : IO Unit := do
  let empty <- expectPublic
    (psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault)
  let mut originalSession := empty
  let mut arena := psKernelExprV2PagedEmpty
  let mut fixtures : List PublicFixture := []
  let mut requests : List PsKernelDagDeclarationRequest := []
  Lean.initSearchPath (← Lean.findSysroot)
  let initialOfficial <- Lean.importModules #[{ module := .str .anonymous "Init" }] {}
  let mut official := initialOfficial
  let mut index := 0
  for name in publicNames do
    let type := PsKernelExpr.sort (level (index + 1))
    let value := PsKernelExpr.sort (level index)
    let term := PsKernelExpr.const name []
    let (a,typeId) <- expect (psKernelExprV2PagedImportIntoChecked arena type)
    let (a,valueId) <- expect (psKernelExprV2PagedImportIntoChecked a value)
    let (a,root) <- expect (psKernelExprV2PagedImportIntoChecked a term)
    arena := a
    fixtures := fixtures ++ [PublicFixture.mk name type value term typeId valueId root]
    requests := requests ++ [.definitionDecl
      (PsKernelDagDefinition.mk (PsKernelDagConstantBase.mk name [] typeId)
        valueId .abbrevHint .safe)]
    let old <- expectPublic (psKernelV1AdmitDeclaration originalSession (.definitionDecl
      (PsKernelDefinitionInfo.mk (PsKernelConstantBase.mk name [] type) value .abbrevHint .safe)))
    originalSession := old.session
    match official.addDeclCore 0 0 (.defnDecl {
      name := officialName name, levelParams := [],
      type := .sort (officialLevel (index + 1)), value := .sort (officialLevel index),
      hints := .abbrev, safety := .safe }) none true with
    | .ok next => official := next
    | .error _ => throw (IO.userError "official name-worker positive fixture refused")
    index := index + 1
  let missingName := nm "NameWorkerMissing"
  let (finalArena,missingRoot) <- expect
    (psKernelExprV2PagedImportIntoChecked arena (.const missingName []))
  let canonical <- expect (psKernelExprV2PagedValidate finalArena)
  let commands := requests.map PsKernelDagCommand.admit ++
    fixtures.flatMap (fun fixture => [PsKernelDagCommand.check fixture.root,
      PsKernelDagCommand.whnf fixture.root])
  let batch <- expectPublic (psKernelV1RunDag empty [] .safe canonical commands)
  require "real-batch-count" (fixtures.length == 10 && batch.replies.length == 30 &&
    psKernelEnvironmentSize batch.session.environment == 10 &&
    psKernelEnvironmentSize originalSession.environment == 10)
  let mut replies := batch.replies.drop 10
  for fixture in fixtures do
    match replies with
    | .checked checked :: .normalized normalized :: rest =>
        require "dag-checked-exact-type" (psKernelExprEqual checked.type fixture.type)
        require "dag-checked-exact-expression" (psKernelExprEqual checked.expression fixture.term)
        require "dag-normalized-exact-body" (psKernelExprEqual normalized fixture.value)
        replies := rest
    | _ => throw (IO.userError "name-worker public batch reply shape")
    let checked <- expectPublic (psKernelV1CheckExpression originalSession [] .safe fixture.term)
    let normalized <- expectPublic (psKernelV1Whnf originalSession [] .safe fixture.term)
    require "reference-checked-exact-type" (psKernelExprEqual checked.type fixture.type)
    require "reference-normalized-exact-body" (psKernelExprEqual normalized fixture.value)
  require "all-replies-consumed" replies.isEmpty
  let nameRoot := nm "NameWorker"
  require "numeric-hash-collision-is-real"
    (psKernelEnvironmentNameHash (.num nameRoot 9007199254740993) ==
      psKernelEnvironmentNameHash (.num nameRoot 9007199254806514))
  let some first := fixtures.head? | throw (IO.userError "missing name-worker fixture")
  let some duplicate := requests.head? | throw (IO.userError "missing name-worker request")
  let badName := nm "NameWorkerIlltyped"
  let unknownName := nm "NameWorkerUnknownBody"
  let negatives : List (PsKernelDeclarationRequest × PsKernelDagDeclarationRequest) := [
    (.definitionDecl (PsKernelDefinitionInfo.mk
      (PsKernelConstantBase.mk first.name [] first.type) first.value .abbrevHint .safe),
      duplicate),
    (.definitionDecl (PsKernelDefinitionInfo.mk
      (PsKernelConstantBase.mk badName [] (.sort .zero)) (.sort .zero) .abbrevHint .safe),
      .definitionDecl (PsKernelDagDefinition.mk
        (PsKernelDagConstantBase.mk badName [] first.valueId) first.valueId .abbrevHint .safe)),
    (.definitionDecl (PsKernelDefinitionInfo.mk
      (PsKernelConstantBase.mk unknownName [] first.type) (.const missingName []) .abbrevHint .safe),
      .definitionDecl (PsKernelDagDefinition.mk
        (PsKernelDagConstantBase.mk unknownName [] first.typeId) missingRoot .abbrevHint .safe))]
  for (old,dag) in negatives do
    require "reference-rejects-invalid-declaration"
      (rejectedInvalid (psKernelV1AdmitDeclaration originalSession old))
    require "dag-rejects-invalid-declaration"
      (rejectedInvalid (psKernelV1RunDag batch.session [] .safe canonical [.admit dag]))
  require "fresh-reference-cannot-resolve-prior-name"
    (rejectedInvalid (psKernelV1CheckExpression empty [] .safe first.term))
  require "fresh-dag-cannot-resolve-prior-name"
    (rejectedInvalid (psKernelV1RunDag empty [] .safe canonical [.check first.root]))
  let officialNegatives : List Lean.Declaration := [
    .defnDecl {
      name := officialName first.name, levelParams := [],
      type := .sort (.succ .zero), value := .sort .zero, hints := .abbrev, safety := .safe },
    .defnDecl {
      name := officialName badName, levelParams := [],
      type := .sort .zero, value := .sort .zero, hints := .abbrev, safety := .safe },
    .defnDecl {
      name := officialName unknownName, levelParams := [],
      type := .sort (.succ .zero), value := .const (officialName missingName) [],
      hints := .abbrev, safety := .safe }]
  for declaration in officialNegatives do
    require "official-rejects-invalid-declaration"
      (match official.addDeclCore 0 0 declaration none true with
       | .error _ => true | .ok _ => false)
  require "fresh-official-cannot-resolve-prior-name"
    (match initialOfficial.addDeclCore 0 0 (.defnDecl {
      name := .str .anonymous "NameWorkerFresh", levelParams := [],
      type := .sort (.succ .zero), value := .const (officialName first.name) [],
      hints := .abbrev, safety := .safe }) none true with
     | .error _ => true | .ok _ => false)
  require "resource-policy-and-environments-preserved"
    (empty.resources.fuel == 4096 && psKernelEnvironmentSize empty.environment == 0 &&
      psKernelEnvironmentSize batch.session.environment == 10 &&
      psKernelEnvironmentSize originalSession.environment == 10)
  IO.println "PSC1_NAME_WORKER_CHECKING_PASS declarations=10 checked=10 normalized=10 negatives=4 officialPositive=10 officialNegative=4"

end PsKernelNameWorkerRegression

def main : IO Unit := do
  PsKernelNameWorkerRegression.stringMatrix
  PsKernelNameWorkerRegression.nameMatrix
  PsKernelNameWorkerRegression.publicChecking
  IO.println "PSC1_NAME_WORKER_PASS"
