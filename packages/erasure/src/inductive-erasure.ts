import {
  LocalContext,
  TypeChecker,
  fvar,
  instantiate1,
  nameEq,
  nameKey,
  nameToString,
  strName,
} from 'lean-ts-kernel';
import type {CheckedCoreModule} from '@proofscript/checked-core';
import type {
  VerifiedIrInductive,
} from '@proofscript/compiler-ir/verified';
import {
  classifyBinder,
  type ErasureScope,
  type RuntimeConstructorInfo,
  type RuntimeInductiveInfo,
} from './model.js';
import {safeIdentifier} from './names.js';
import {eraseRuntimeType} from './type-erasure.js';
import {prepareInductiveParameters} from './inductive-parameter-erasure.js';

export interface PreparedRuntimeInductives {
  readonly ir:readonly VerifiedIrInductive[];
  readonly byType:ReadonlyMap<string,RuntimeInductiveInfo>;
  readonly byConstructor:ReadonlyMap<string,RuntimeConstructorInfo>;
  readonly byRecursor:ReadonlyMap<string,RuntimeInductiveInfo>;
}

function shortName(name:string):string {
  const parts=name.split('.');
  return parts[parts.length-1]??name;
}

export function prepareRuntimeInductives(
  module:CheckedCoreModule,
  symbolNames:ReadonlyMap<string,string>,
  structuresByType:ErasureScope['structuresByType'],
  structuresByConstructor:ErasureScope['structuresByConstructor'],
):PreparedRuntimeInductives {
  const structureKeys=new Set(
    module.structures.map((item)=>nameKey(item.name)),
  );
  const ir:VerifiedIrInductive[]=[];
  const byType=new Map<string,RuntimeInductiveInfo>();
  const byConstructor=new Map<string,RuntimeConstructorInfo>();
  const byRecursor=new Map<string,RuntimeInductiveInfo>();

  for(const inductive of module.inductives){
    const typeKey=nameKey(inductive.name);
    if(structureKeys.has(typeKey))continue;
    if(inductive.numIndices!==0){
      throw new Error(
        "PS_ERASE_INDEXED_INDUCTIVE_UNSUPPORTED: '"+
        nameToString(inductive.name)+"'",
      );
    }
    if(inductive.isRec){
      throw new Error(
        "PS_ERASE_RECURSIVE_INDUCTIVE_UNSUPPORTED: '"+
        nameToString(inductive.name)+"'",
      );
    }

    const inductiveName=symbolNames.get(typeKey);
    if(inductiveName===undefined){
      throw new Error('PS_ERASE_INDUCTIVE_NAME_MISSING');
    }
    const parameters=prepareInductiveParameters(
      inductive,
      module.environment,
    );
    const constructors:RuntimeConstructorInfo[]=[];

    for(const constructorName of inductive.ctors){
      const constructor=module.environment.find(constructorName);
      if(constructor?.kind!=='constructor'){
        throw new Error(
          "PS_ERASE_CONSTRUCTOR_MISSING: '"+
          nameToString(constructorName)+"'",
        );
      }

      let cursor=constructor.type;
      let localContext=parameters.localContext.clone();
      let runtimeLocals=new Map<string,string>();

      for(let index=0;index<constructor.numParams;index+=1){
        const checker=new TypeChecker(
          module.environment,
          localContext.clone(),
        );
        const binder=checker.ensureForall(checker.whnf(cursor));
        const value=parameters.values[index];
        if(value===undefined){
          throw new Error(
            "PS_ERASE_CONSTRUCTOR_PARAMETER_MISMATCH: '"+
            nameToString(constructorName)+"'",
          );
        }
        cursor=instantiate1(binder.body,value);
      }
      const fields:RuntimeConstructorInfo['fields'][number][]=[];
      const fieldNames=new Set<string>();

      for(let index=0;index<constructor.numFields;index+=1){
        const checker=new TypeChecker(
          module.environment,
          localContext.clone(),
        );
        const binder=checker.ensureForall(checker.whnf(cursor));
        const kind=classifyBinder(binder.type,checker);
        if(kind!=='runtime'){
          throw new Error(
            "PS_ERASE_INDUCTIVE_FIELD_UNSUPPORTED: constructor '"+
            nameToString(constructorName)+"' field "+index+
            ' is '+kind+'-level',
          );
        }

        const sourceName=nameToString(binder.name)||'field'+index;
        const fieldName=safeIdentifier(sourceName,'field'+index);
        if(fieldNames.has(fieldName)){
          throw new Error(
            "PS_ERASE_CONSTRUCTOR_FIELD_COLLISION: '"+fieldName+"'",
          );
        }
        fieldNames.add(fieldName);

        const scope:ErasureScope={
          localContext,
          runtimeLocals,
          typeLocals:parameters.typeLocals,
          erasedLocals:parameters.erasedLocals,
          declarationNames:symbolNames,
          structuresByType,
          structuresByConstructor,
          inductivesByType:byType,
          inductivesByConstructor:byConstructor,
          inductivesByRecursor:byRecursor,
        };
        const type=eraseRuntimeType(
          binder.type,
          scope,
          module.environment,
        );
        if(type.kind==='unknown'){
          throw new Error(
            "PS_ERASE_INDUCTIVE_FIELD_TYPE_UNSUPPORTED: constructor '"+
            nameToString(constructorName)+"' field "+index,
          );
        }
        fields.push({
          sourceIndex:constructor.numParams+index,
          name:fieldName,
          type,
        });

        const next=localContext.clone();
        const id=next.fresh(sourceName);
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

      const info:RuntimeConstructorInfo={
        inductive:inductiveName,
        name:safeIdentifier(
          shortName(nameToString(constructorName)),
          'constructor',
        ),
        constructorKey:nameKey(constructorName),
        numParams:constructor.numParams,
        fields,
      };
      constructors.push(info);
      byConstructor.set(info.constructorKey,info);
    }

    const recursorName=strName(inductive.name,'rec');
    const recursor=module.environment.find(recursorName);
    if(
      recursor?.kind!=='recursor'
      ||recursor.numParams!==inductive.numParams
      ||recursor.numIndices!==0
      ||recursor.numMotives!==1
      ||recursor.numMinors!==constructors.length
      ||recursor.rules.length!==constructors.length
    ){
      throw new Error(
        "PS_ERASE_RECURSOR_METADATA_UNSUPPORTED: '"+
        nameToString(recursorName)+"'",
      );
    }
    for(let index=0;index<constructors.length;index+=1){
      const rule=recursor.rules[index]!;
      const constructorName=inductive.ctors[index]!;
      if(!nameEq(rule.ctor,constructorName)){
        throw new Error(
          "PS_ERASE_RECURSOR_RULE_ORDER: '"+nameToString(recursorName)+
          "' rule "+index+" does not match admitted constructor order",
        );
      }
    }

    const info:RuntimeInductiveInfo={
      name:inductiveName,
      typeKey,
      recursorKey:nameKey(recursorName),
      numParams:inductive.numParams,
      typeParameters:parameters.typeParameters,
      constructors,
    };
    byType.set(typeKey,info);
    byRecursor.set(info.recursorKey,info);
    ir.push({
      name:inductiveName,
      typeParameters:parameters.typeParameters,
      constructors:constructors.map((constructor)=>({
        name:constructor.name,
        fields:constructor.fields.map((field)=>({
          name:field.name,
          type:field.type,
        })),
      })),
    });
  }

  return {ir,byType,byConstructor,byRecursor};
}
