from pathlib import Path

path = Path('selfhost/packages/backend-wasm/src/Ps/BackendWasm/Lower.lean')
text = path.read_text()
old = '''      | .intrinsic _ typeArguments arguments =>
          let withTypes :=
            typeArguments.foldl
              (fun state type =>
                psWasmCollectArrayTypesFromType type state)
              types
          arguments.foldl
            (fun state argument => collect argument state)
            withTypes
'''
new = '''      | .intrinsic operation typeArguments arguments =>
          let withTypes :=
            typeArguments.foldl
              (fun state type =>
                psWasmCollectArrayTypesFromType type state)
              types
          let withArrayTypes :=
            match operation, typeArguments with
            | .arrayMap, [inputType, outputType] =>
                psWasmInsertArrayType
                  (psWasmInsertArrayType
                    withTypes
                    (PsVerifiedIrType.named "Array" [inputType]))
                  (PsVerifiedIrType.named "Array" [outputType])
            | .arrayFoldl, [elementType, _] =>
                psWasmInsertArrayType
                  withTypes
                  (PsVerifiedIrType.named "Array" [elementType])
            | .arrayEmptyWithCapacity, [elementType]
            | .arraySize, [elementType]
            | .arrayPush, [elementType]
            | .arrayGet, [elementType]
            | .arrayGetD, [elementType]
            | .arraySet, [elementType]
            | .arraySetIfInBounds, [elementType] =>
                psWasmInsertArrayType
                  withTypes
                  (PsVerifiedIrType.named "Array" [elementType])
            | _, _ => withTypes
          arguments.foldl
            (fun state argument => collect argument state)
            withArrayTypes
'''
count = text.count(old)
if count != 1:
    raise SystemExit(f'expected one Array collector intrinsic arm, found {count}')
path.write_text(text.replace(old, new, 1))
print('WASM_ARRAY_COLLECTION_FIX: APPLIED')
