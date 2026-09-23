import {
  LocalContext,
  TypeChecker,
  nameKey,
} from 'lean-ts-kernel';
import type {CheckedCoreModule} from '@proofscript/checked-core';
import type {
  VerifiedIrDeclaration,
  VerifiedIrModule,
} from '@proofscript/compiler-ir/verified';
import {buildDeclarationNames} from './names.js';
import {openAndEraseDefinition} from './expr-erasure.js';

export * from './model.js';
export * from './names.js';
export * from './type-erasure.js';
export * from './expr-erasure.js';

export function eraseCheckedCoreModule(
  module:CheckedCoreModule,
):VerifiedIrModule {
  const declarationNames=buildDeclarationNames(
    module.definitions.map((definition)=>definition.name),
  );
  const declarations:VerifiedIrDeclaration[]=[];

  for(const definition of module.definitions){
    const checker=new TypeChecker(module.environment,new LocalContext());
    if(checker.isProp(definition.type))continue;

    const lowered=openAndEraseDefinition(
      definition.type,
      definition.value,
      {
        localContext:new LocalContext(),
        runtimeLocals:new Map(),
        typeLocals:new Map(),
        erasedLocals:new Set(),
        declarationNames,
      },
      module.environment,
    );
    const name=declarationNames.get(nameKey(definition.name));
    if(name===undefined){
      throw new Error('PS_ERASE_DECLARATION_NAME_MISSING');
    }
    declarations.push({name,...lowered});
  }

  return {kind:'proofscript-verified-ir',declarations};
}
