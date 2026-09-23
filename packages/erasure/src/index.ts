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
import {prepareRuntimeStructures} from './structure-erasure.js';
import {prepareRuntimeInductives} from './inductive-erasure.js';

export * from './model.js';
export * from './names.js';
export * from './type-erasure.js';
export * from './expr-erasure.js';
export * from './structure-erasure.js';
export * from './inductive-erasure.js';
export * from './recursor-erasure.js';

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
    ...module.definitions.map((definition)=>definition.name),
  ]);
  const structures=prepareRuntimeStructures(module,declarationNames);
  const inductives=prepareRuntimeInductives(
    module,
    declarationNames,
    structures.byType,
    structures.byConstructor,
  );
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
      {
        localContext:new LocalContext(),
        runtimeLocals:new Map(),
        typeLocals:new Map(),
        erasedLocals:new Set(),
        declarationNames,
        structuresByType:structures.byType,
        structuresByConstructor:structures.byConstructor,
        inductivesByType:inductives.byType,
        inductivesByConstructor:inductives.byConstructor,
        inductivesByRecursor:inductives.byRecursor,
      },
      module.environment,
      name,
    );
    declarations.push({name,...lowered});
  }

  return {
    kind:'proofscript-verified-ir',
    structures:structures.ir,
    inductives:inductives.ir,
    declarations,
  };
}
