import {
  type Name,
} from 'lean-ts-kernel';
import type {
  Lean434ConstructorValue,
  Lean434RuntimeValue,
} from './lean4-eval.js';
import {
  kernelNameToLean434Runtime,
} from './lean4-name.js';

const PHM_BRANCHING=32;

function ctor(
  name:string,
  fields:readonly Lean434RuntimeValue[]=[],
):Lean434ConstructorValue{
  return {kind:'constructor',name,fields};
}

/**
 * Logical empty Lean.PersistentHashMap value.
 *
 * This mirrors the source definition exactly:
 * PersistentHashMap.mk (Node.entries (Array.replicate 32 Entry.null)).
 * The JS array is only the already-established Lean Array runtime
 * representation; insertion/find logic remains upstream Lean code.
 */
export function emptyLean434PersistentHashMap():
Lean434ConstructorValue{
  const nullEntry=ctor('Lean.PersistentHashMap.Entry.null');
  const entries=Array.from(
    {length:PHM_BRANCHING},
    ()=>nullEntry,
  );
  return ctor(
    'Lean.PersistentHashMap.mk',
    [
      ctor(
        'Lean.PersistentHashMap.Node.entries',
        [entries],
      ),
    ],
  );
}

export function lean434RuntimeMVarId(
  name:Name,
):Lean434ConstructorValue{
  return ctor(
    'Lean.MVarId.mk',
    [kernelNameToLean434Runtime(name)],
  );
}

export function lean434RuntimeLMVarId(
  name:Name,
):Lean434ConstructorValue{
  return ctor(
    'Lean.LevelMVarId.mk',
    [kernelNameToLean434Runtime(name)],
  );
}

/**
 * Logical empty Lean.MetavarContext.
 *
 * All assignment/declaration maps are real logical PersistentHashMap values;
 * this helper does not implement insertion, lookup, assignment, or unification.
 * Those operations are intentionally executed from upstream Lean source.
 */
export function emptyLean434MetavarContext():
Lean434ConstructorValue{
  return ctor(
    'Lean.MetavarContext.mk',
    [
      0n, // depth
      0n, // levelAssignDepth
      0n, // lmvarCounter
      0n, // mvarCounter
      emptyLean434PersistentHashMap(), // lDecls
      emptyLean434PersistentHashMap(), // decls
      emptyLean434PersistentHashMap(), // userNames
      emptyLean434PersistentHashMap(), // lAssignment
      emptyLean434PersistentHashMap(), // eAssignment
      emptyLean434PersistentHashMap(), // dAssignment
    ],
  );
}

export function lean434RuntimeOptionValue(
  value:Lean434RuntimeValue,
):Lean434RuntimeValue|undefined{
  if(
    typeof value!=='object'
    ||value===null
    ||Array.isArray(value)
    ||!('kind' in value)
    ||value.kind!=='constructor'
  ){
    throw new Error('Lean runtime Option is not a constructor');
  }
  if(value.name==='Option.none'){
    if(value.fields.length!==0){
      throw new Error('Option.none has runtime fields');
    }
    return undefined;
  }
  if(value.name==='Option.some'){
    if(value.fields.length!==1){
      throw new Error('Option.some runtime field count mismatch');
    }
    return value.fields[0]!;
  }
  throw new Error(
    "unexpected Lean runtime Option constructor '"+value.name+"'",
  );
}
