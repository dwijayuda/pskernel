import {
  LocalContext,
  TypeChecker,
  fvar,
  instantiate1,
  nameKey,
  nameToString,
} from 'lean-ts-kernel';
import type {CheckedCoreModule} from '@proofscript/checked-core';
import type {
  VerifiedIrStructure,
} from '@proofscript/compiler-ir/verified';
import {
  classifyBinder,
  type ErasureScope,
  type RuntimeStructureInfo,
} from './model.js';
import {safeIdentifier} from './names.js';
import {eraseRuntimeType} from './type-erasure.js';

export interface PreparedRuntimeStructures {
  readonly ir:readonly VerifiedIrStructure[];
  readonly byType:ReadonlyMap<string,RuntimeStructureInfo>;
  readonly byConstructor:ReadonlyMap<string,RuntimeStructureInfo>;
}

export function prepareRuntimeStructures(
  module:CheckedCoreModule,
  symbolNames:ReadonlyMap<string,string>,
):PreparedRuntimeStructures {
  const ir:VerifiedIrStructure[]=[];
  const byType=new Map<string,RuntimeStructureInfo>();
  const byConstructor=new Map<string,RuntimeStructureInfo>();

  for(const structure of module.structures){
    const constructor=module.environment.find(structure.constructor);
    if(constructor?.kind!=='constructor'){
      throw new Error(
        "PS_ERASE_STRUCTURE_CONSTRUCTOR_MISSING: '"+
        nameToString(structure.constructor)+"'",
      );
    }
    if(constructor.numParams!==0){
      throw new Error(
        "PS_ERASE_PARAMETERIZED_STRUCTURE_UNSUPPORTED: '"+
        nameToString(structure.name)+"'",
      );
    }

    const structureName=symbolNames.get(nameKey(structure.name));
    if(structureName===undefined){
      throw new Error('PS_ERASE_STRUCTURE_NAME_MISSING');
    }

    let localContext=new LocalContext();
    let runtimeLocals=new Map<string,string>();
    let cursor=constructor.type;
    const fields:RuntimeStructureInfo['fields'][number][]=[];
    const names=new Set<string>();

    for(const sourceField of structure.fields){
      const checker=new TypeChecker(
        module.environment,
        localContext.clone(),
      );
      const binder=checker.ensureForall(checker.whnf(cursor));
      const kind=classifyBinder(binder.type,checker);
      if(kind!=='runtime'){
        throw new Error(
          "PS_ERASE_DEPENDENT_STRUCTURE_FIELD_UNSUPPORTED: structure '"+
          structureName+"' field '"+sourceField.name+
          "' is "+kind+"-level",
        );
      }

      const fieldName=safeIdentifier(sourceField.name,'field');
      if(names.has(fieldName)){
        throw new Error(
          "PS_ERASE_STRUCTURE_FIELD_COLLISION: '"+fieldName+"'",
        );
      }
      names.add(fieldName);

      const scope:ErasureScope={
        localContext,
        runtimeLocals,
        typeLocals:new Map(),
        erasedLocals:new Set(),
        declarationNames:symbolNames,
        structuresByType:byType,
        structuresByConstructor:byConstructor,
        inductivesByType:new Map(),
        inductivesByConstructor:new Map(),
      };
      const type=eraseRuntimeType(
        binder.type,
        scope,
        module.environment,
      );
      if(type.kind==='unknown'||type.kind==='typeParameter'){
        throw new Error(
          "PS_ERASE_STRUCTURE_FIELD_TYPE_UNSUPPORTED: structure '"+
          structureName+"' field '"+sourceField.name+"'",
        );
      }
      fields.push({
        sourceIndex:sourceField.index,
        name:fieldName,
        type,
      });

      const next=localContext.clone();
      const id=next.fresh(sourceField.name);
      next.addLocal(
        id,
        binder.name,
        binder.type,
        binder.binderInfo,
      );
      runtimeLocals=new Map(runtimeLocals);
      runtimeLocals.set(id,fieldName);
      localContext=next;
      cursor=instantiate1(binder.body,fvar(id));
    }

    const info:RuntimeStructureInfo={
      name:structureName,
      typeKey:nameKey(structure.name),
      constructorKey:nameKey(structure.constructor),
      fields,
    };
    byType.set(info.typeKey,info);
    byConstructor.set(info.constructorKey,info);
    ir.push({
      name:structureName,
      fields:fields.map((field)=>({
        name:field.name,
        type:field.type,
      })),
    });
  }

  return {ir,byType,byConstructor};
}
