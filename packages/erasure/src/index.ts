import {
  LocalContext,
  TypeChecker,
  nameKey,
} from 'lean-ts-kernel';
import type {CheckedCoreModule} from '@proofscript/checked-core';
import type {
  VerifiedIrDeclaration,
  VerifiedIrExternalImport,
  VerifiedIrModule,
  VerifiedIrType,
} from '@proofscript/compiler-ir/verified';
import {buildDeclarationNames} from './names.js';
import {openAndEraseDefinition} from './expr-erasure.js';
import {eraseRuntimeType} from './type-erasure.js';
import {prepareRuntimeStructures} from './structure-erasure.js';
import {prepareRuntimeInductives} from './inductive-erasure.js';

export * from './model.js';
export * from './names.js';
export * from './type-erasure.js';
export * from './expr-erasure.js';
export * from './structure-erasure.js';
export * from './inductive-erasure.js';
export * from './recursor-erasure.js';

function flattenExternalFunctionType(type:VerifiedIrType):VerifiedIrType {
  if(type.kind!=='function')return type;
  const parameters=[...type.parameters];
  let result=type.result;
  while(result.kind==='function'){
    parameters.push(...result.parameters);
    result=result.result;
  }
  return {kind:'function',parameters,result};
}

function assertExternalRuntimeType(
  type:VerifiedIrType,
  name:string,
):void {
  const primitive=(value:VerifiedIrType)=>
    value.kind==='primitive';
  if(
    type.kind!=='function'
    ||!type.parameters.every(primitive)
    ||!primitive(type.result)
  ){
    throw new Error(
      "PS_ERASE_EXTERNAL_TYPE_UNSUPPORTED: '"+name+
      "' must use only runtime primitive function parameters/results",
    );
  }
}

export function eraseCheckedCoreModule(
  module:CheckedCoreModule,
):VerifiedIrModule {
  const structureKeys=new Set(
    module.structures.map((structure)=>nameKey(structure.name)),
  );
  const sourceInductives=module.inductives.filter(
    (inductive)=>!structureKeys.has(nameKey(inductive.name)),
  );
  const declarationNames=buildDeclarationNames([
    ...module.structures.map((structure)=>structure.name),
    ...sourceInductives.map((inductive)=>inductive.name),
    ...module.externals.map((external)=>external.declaration.name),
    ...module.definitions.map((definition)=>definition.name),
  ]);
  const structures=prepareRuntimeStructures(module,declarationNames);
  const inductives=prepareRuntimeInductives(
    module,
    declarationNames,
    structures.byType,
    structures.byConstructor,
  );
  const baseScope={
    localContext:new LocalContext(),
    runtimeLocals:new Map<string,string>(),
    typeLocals:new Map<string,string>(),
    erasedLocals:new Set<string>(),
    declarationNames,
    structuresByType:structures.byType,
    structuresByConstructor:structures.byConstructor,
    inductivesByType:inductives.byType,
    inductivesByConstructor:inductives.byConstructor,
    inductivesByRecursor:inductives.byRecursor,
  } as const;
  const imports:VerifiedIrExternalImport[]=module.externals.map((external)=>{
    const localName=declarationNames.get(nameKey(external.declaration.name));
    if(localName===undefined){
      throw new Error('PS_ERASE_EXTERNAL_NAME_MISSING');
    }
    const type=flattenExternalFunctionType(
      eraseRuntimeType(
        external.declaration.type,
        baseScope,
        module.environment,
      ),
    );
    assertExternalRuntimeType(type,localName);
    return {
      localName,
      source:external.binding.source,
      importedName:external.binding.importedName,
      type,
    };
  });
  const declarations:VerifiedIrDeclaration[]=[];

  for(const definition of module.definitions){
    const checker=new TypeChecker(module.environment,new LocalContext());
    if(checker.isProp(definition.type))continue;

    const name=declarationNames.get(nameKey(definition.name));
    if(name===undefined){
      throw new Error('PS_ERASE_DECLARATION_NAME_MISSING');
    }
    const lowered=openAndEraseDefinition(
      definition.type,
      definition.value,
      baseScope,
      module.environment,
      name,
    );
    declarations.push({name,...lowered});
  }

  return {
    kind:'proofscript-verified-ir',
    imports,
    structures:structures.ir,
    inductives:inductives.ir,
    declarations,
  };
}
export * from './local-erasure.js';
