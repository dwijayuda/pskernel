import {
  Environment,
  Kernel,
  type DefinitionInfo,
  type TheoremInfo,
} from 'lean-ts-kernel';

export type CheckedCoreDeclaration=DefinitionInfo|TheoremInfo;

export interface CheckedCoreModule {
  readonly kind:'proofscript-checked-core';
  readonly environment:Environment;
  readonly declarations:readonly CheckedCoreDeclaration[];
  readonly definitions:readonly DefinitionInfo[];
  readonly theorems:readonly TheoremInfo[];
}

/**
 * Establish the compiler-facing checked-core boundary by replaying every
 * declaration through pskernel into a clone of the supplied base environment.
 *
 * No parser/elaborator/compiler metadata can manufacture a CheckedCoreModule
 * without passing kernel admission here.
 */
export function admitCheckedCoreModule(
  baseEnvironment:Environment,
  declarations:readonly CheckedCoreDeclaration[],
):CheckedCoreModule {
  const environment=baseEnvironment.clone();
  const kernel=new Kernel(environment);
  const definitions:DefinitionInfo[]=[];
  const theorems:TheoremInfo[]=[];

  for(const declaration of declarations){
    if(declaration.kind==='definition'){
      kernel.addDefinition(declaration);
      definitions.push(declaration);
    }else{
      kernel.addTheorem(declaration);
      theorems.push(declaration);
    }
  }

  return {
    kind:'proofscript-checked-core',
    environment,
    declarations:[...declarations],
    definitions,
    theorems,
  };
}
