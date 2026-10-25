import Ps.Host.SourceOwnership

/-! Native comparison for a checked local alpha rename.
Both actual graphs are independently admitted by the host before comparison.
All non-selected declarations and the selected public type/identity remain exact.
Only bound-name annotations inside one stable definition value may differ.
This helper does not perform edits, grant admission or publish anything. -/

namespace Ps.Internal.SourceBindingComparison

deriving instance DecidableEq for PsName
deriving instance DecidableEq for PsLevel
deriving instance DecidableEq for PsBinderInfo
deriving instance DecidableEq for PsLiteral
deriving instance DecidableEq for PsExpr
deriving instance DecidableEq for PsInductiveInfo
deriving instance DecidableEq for PsConstructorInfo
deriving instance DecidableEq for PsRecursorInfo
deriving instance DecidableEq for PsDeclaration

private def exactKeys (value : Lean.Json) (keys : List String) : Except String Unit := do
  let fields ← value.getObj?
  let actual := fields.toList.map Prod.fst
  if actual.length != keys.length || !(actual.all keys.contains) then
    throw "fields"

private def boundedRequest (value : Lean.Json) :
    Except String Ps.Internal.CompilerService.Request := do
  let request ← (Ps.Internal.CompilerService.decode value.compress).mapError
    (fun error => error.phase ++ ":" ++ error.code)
  if request.sources.length > 256 ||
      request.sources.any (fun source => source.text.utf8ByteSize > 1048576) then
    throw "source-limit"
  return request

private def owned (rows : Array Lean.Json) (moduleName : String) (target : Lean.Json) : Bool :=
  rows.any fun row =>
    ((row.getObjValAs? String "module").toOption == some moduleName) &&
    match (row.getObjVal? "origins").toOption.bind (fun value => value.getArr?.toOption) with
    | none => false
    | some origins => origins.any fun origin =>
        match (origin.getObjVal? "members").toOption.bind (fun value => value.getArr?.toOption) with
        | none => false
        | some members => members.any fun member =>
            (member.getObjVal? "name").toOption.any (fun name => name.compress == target.compress)

private def sameDeclarations (target : String) :
    List PsDeclaration -> List PsDeclaration -> Except String Nat
  | [], [] => pure 0
  | left :: leftRest, right :: rightRest => do
      let isTarget := (Lean.toJson (psOwnershipName (psDeclarationName left))).compress == target
      let count ← sameDeclarations target leftRest rightRest
      if isTarget then
        match left, right with
        | .definitionDecl leftName leftLevels leftType leftValue,
          .definitionDecl rightName rightLevels rightType rightValue =>
            if decide (leftName = rightName) && decide (leftLevels = rightLevels) &&
                decide (leftType = rightType) && psExprAlphaEq leftValue rightValue then
              pure (count + 1)
            else throw "selected-definition-type-or-alpha-body"
        | _, _ => throw "selected-definition-kind"
      else if decide (left = right) then pure count
      else throw "other-declaration-changed"
  | _, _ => throw "declaration-count"

def compare (text : String) : Except String Lean.Json := do
  let envelope ← Lean.Json.parse text
  exactKeys envelope ["protocol", "before", "after", "target"]
  let protocol ← envelope.getObjValAs? String "protocol"
  if protocol != "psc1-source-binding-comparison/1" then throw "protocol"
  let before ← boundedRequest (← envelope.getObjVal? "before")
  let after ← boundedRequest (← envelope.getObjVal? "after")
  let target ← envelope.getObjVal? "target"
  exactKeys target ["module", "name"]
  let moduleName ← target.getObjValAs? String "module"
  let name ← target.getObjVal? "name"
  if before.grammar != after.grammar || before.assurance != after.assurance ||
      before.entry != after.entry ||
      before.sources.map (fun source => source.moduleName) !=
        after.sources.map (fun source => source.moduleName) then
    throw "closure-shape"
  let (left, leftRows) ← (psOwnershipCapture before).mapError (fun _ => "before-capture")
  let (right, rightRows) ← (psOwnershipCapture after).mapError (fun _ => "after-capture")
  if !owned leftRows moduleName name || !owned rightRows moduleName name then
    throw "target-owner"
  let count ← sameDeclarations name.compress left.state.declarationsRev.reverse
    right.state.declarationsRev.reverse
  if count != 1 then throw "target-count"
  return Lean.Json.mkObj [
    ("protocol", .str protocol), ("status", .str "equivalent"),
    ("beforeRequestId", .str before.requestId), ("afterRequestId", .str after.requestId),
    ("beforeDigest", .str before.sourceClosureDigest),
    ("afterDigest", .str after.sourceClosureDigest), ("target", target),
    ("relation", .str "one stable definition value alpha-equal; exact public type and all other declarations"),
    ("sourceFilesWritten", .bool false), ("publication", .bool false)]

end Ps.Internal.SourceBindingComparison
