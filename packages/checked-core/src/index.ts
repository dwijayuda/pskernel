import {
  Environment,
  Kernel,
  addInductive,
  nameKey,
  type DefinitionInfo,
  type InductiveDecl,
  type InductiveInfo,
  type TheoremInfo,
} from 'lean-ts-kernel';

export type CheckedCoreDeclaration=DefinitionInfo|TheoremInfo;

export type CheckedCoreAdmission =
  | {
      readonly kind:'constant';
      readonly declaration:CheckedCoreDeclaration;
    }
  | {
      readonly kind:'inductive';
      readonly declaration:InductiveDecl;
    };

export interface CheckedCoreModule {
  readonly kind:'proofscript-checked-core';
  readonly environment:Environment;
  readonly admissions:readonly CheckedCoreAdmission[];
  readonly declarations:readonly CheckedCoreDeclaration[];
  readonly definitions:readonly DefinitionInfo[];
  readonly theorems:readonly TheoremInfo[];
  readonly inductiveDeclarations:readonly InductiveDecl[];
  readonly inductives:readonly InductiveInfo[];
}

/**
 * Replay the complete frontend result through pskernel in source admission
 * order. This is the only constructor for mixed checked-core modules.
 */
export function admitCheckedCoreAdmissions(
  baseEnvironment:Environment,
  admissions:readonly CheckedCoreAdmission[],
):CheckedCoreModule {
  const environment=baseEnvironment.clone();
  const kernel=new Kernel(environment);
  const declarations:CheckedCoreDeclaration[]=[];
  const definitions:DefinitionInfo[]=[];
  const theorems:TheoremInfo[]=[];
  const inductiveDeclarations:InductiveDecl[]=[];
  const inductives:InductiveInfo[]=[];

  for(const admission of admissions){
    if(admission.kind==='inductive'){
      addInductive(environment,admission.declaration);
      inductiveDeclarations.push(admission.declaration);
      for(const type of admission.declaration.types){
        const info=environment.find(type.name);
        if(info?.kind!=='inductive'){
          throw new Error(
            'checked-core invariant: missing admitted inductive '+
            nameKey(type.name),
          );
        }
        inductives.push(info);
      }
      continue;
    }

    const declaration=admission.declaration;
    if(declaration.kind==='definition'){
      kernel.addDefinition(declaration);
      definitions.push(declaration);
    }else{
      kernel.addTheorem(declaration);
      theorems.push(declaration);
    }
    declarations.push(declaration);
  }

  return {
    kind:'proofscript-checked-core',
    environment,
    admissions:[...admissions],
    declarations,
    definitions,
    theorems,
    inductiveDeclarations,
    inductives,
  };
}

/**
 * Backward-compatible value/theorem-only checked-core constructor.
 */
export function admitCheckedCoreModule(
  baseEnvironment:Environment,
  declarations:readonly CheckedCoreDeclaration[],
):CheckedCoreModule {
  return admitCheckedCoreAdmissions(
    baseEnvironment,
    declarations.map((declaration)=>({
      kind:'constant' as const,
      declaration,
    })),
  );
}
