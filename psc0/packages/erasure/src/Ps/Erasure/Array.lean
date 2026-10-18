import Ps.Erasure.Basic

-- The checked Array logical model uses List, while every runtime has its
-- own array layout. Conversion adapters use prepared List metadata, ordinary
-- typed matches/constructors, and a layout-independent sized builder.
def psEraseArrayConversion (scope : PsErasureScope) (element : PsVerifiedIrType)
    (value : PsVerifiedIrExpr) (fromList : Bool) :
    Except PsErasureError PsVerifiedIrExpr := do
  let some nilInfo := psErasureLookupConstructor scope.runtimeConstructors
    (psNameAppendStr psListName "nil") | throw .unsupportedRuntimeTerm
  let some consInfo := psErasureLookupConstructor scope.runtimeConstructors
    (psNameAppendStr psListName "cons") | throw .unsupportedRuntimeTerm
  -- Prepared source positions include the uniform parameter telescope.
  let [head, tail] := consInfo.fields | throw .unsupportedRuntimeTerm
  if !nilInfo.fields.isEmpty || nilInfo.inductiveName != consInfo.inductiveName ||
      nilInfo.numParams != 1 || consInfo.numParams != 1 ||
      head.sourceIndex != consInfo.numParams ||
      tail.sourceIndex != consInfo.numParams + 1 then
    throw .unsupportedRuntimeTerm
  let list := PsVerifiedIrType.named consInfo.inductiveName [element]
  let array := PsVerifiedIrType.named "Array" [element]
  let inputName := psErasureLocalName scope "__ps_collection" "__ps_collection"
    scope.localContext.nextId
  let input := PsVerifiedIrExpr.var inputName
  let nilValue := PsVerifiedIrExpr.constructor nilInfo.inductiveName nilInfo.name [element] []
  let cons := fun value rest => PsVerifiedIrExpr.constructor consInfo.inductiveName
    consInfo.name [element] [(head.name, value), (tail.name, rest)]
  if fromList then
    let some length := psErasureLookupName scope.declarationNames
      (psNameAppendStr psListName "length") | throw .unsupportedRuntimeTerm
    let select := fun (first : Bool) =>
      let result := if first then element else list
      PsVerifiedIrExpr.lambda [{ name := "__ps_cursor", type := list }] result
        (.matchE consInfo.inductiveName [element] (.var "__ps_cursor")
          [(nilInfo.name, [], .unreachable result),
           (consInfo.name,
            [{ field := head.name, name := "__ps_head", type := element },
             { field := tail.name, name := "__ps_tail", type := list }],
            .var (if first then "__ps_head" else "__ps_tail"))])
    -- The exact checked List.length is the builder count. The nil selector
    -- arms are unreachable only because this adapter owns that invariant.
    return .letE inputName list value
      (.intrinsic .arrayBuild [element, list]
        [.call (.var length) [element] [input], input, select true, select false])
  else
    let some reverse := psErasureLookupName scope.declarationNames
      (psNameAppendStr psListName "reverse") | throw .unsupportedRuntimeTerm
    let step := PsVerifiedIrExpr.lambda
      [{ name := "__ps_acc", type := list }, { name := "__ps_item", type := element }]
      list (cons (.var "__ps_item") (.var "__ps_acc"))
    let reversed := PsVerifiedIrExpr.intrinsic .arrayFoldl [element, list]
      [step, nilValue, input, .literal (.natural 0),
       .intrinsic .arraySize [element] [input]]
    return .letE inputName array value (.call (.var reverse) [element] [reversed])
