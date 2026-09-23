import type {V061Module} from '@proofscript/syntax';
import {
  Environment,
  Kernel,
  addInductive,
  constant,
  type DefinitionInfo,
  type Expr,
  type TheoremInfo,
} from 'lean-ts-kernel';
import {
  admitCheckedCoreAdmissions,
  type CheckedCoreAdmission,
  type CheckedCoreModule,
  type CheckedCoreStructure,
} from '@proofscript/checked-core';
import {elaborateV061StructureDeclaration} from './v061-structure-elab.js';
import {elaborateV061ClassDeclaration} from './v061-class-elab.js';
import {elaborateV061InductiveDeclaration} from './v061-inductive-elab.js';
import {elaborateV061ValueDeclaration} from './v061-value-declaration-elab.js';
import {elaborateV061InstanceDeclaration} from './v061-instance-elab.js';

function declarationFailure(
  name:string,
  error:unknown,
):Error {
  const detail=error instanceof Error?error.message:String(error);
  return new Error("PS_ELAB_DECL_FAILED: '"+name+"': "+detail);
}

export type ElaboratedV061Module=CheckedCoreModule;

export function elaborateV061Definitions(
  module:V061Module,
  environment=new Environment(),
):ElaboratedV061Module {
  const baseEnvironment=environment.clone();
  const workEnvironment=environment.clone();
  const admissions:CheckedCoreAdmission[]=[];
  const structures=new Map<string,CheckedCoreStructure>();
  const classes=new Set<string>();
  const globalInstances:Expr[]=[];
  const kernel=new Kernel(workEnvironment);

  for(const declaration of module.declarations){
    if(declaration.kind==='structure'){
      try{
        const result=elaborateV061StructureDeclaration(
          declaration,
          workEnvironment,
        );
        addInductive(workEnvironment,result.declaration);
        structures.set(declaration.name,result.structure);
        admissions.push({
          kind:'structure',
          declaration:result.declaration,
          structure:result.structure,
        });
      }catch(error){
        throw declarationFailure(declaration.name,error);
      }
      continue;
    }

    if(declaration.kind==='inductive'){
      try{
        const result=elaborateV061InductiveDeclaration(
          declaration,
          workEnvironment,
        );
        addInductive(workEnvironment,result);
        admissions.push({kind:'inductive',declaration:result});
      }catch(error){
        throw declarationFailure(declaration.name,error);
      }
      continue;
    }

    if(declaration.kind==='class'){
      try{
        const result=elaborateV061ClassDeclaration(
          declaration,
          workEnvironment,
        );
        addInductive(workEnvironment,result.declaration);
        structures.set(declaration.name,result.structure);
        classes.add(declaration.name);
        admissions.push({
          kind:'class',
          declaration:result.declaration,
          structure:result.structure,
        });
      }catch(error){
        throw declarationFailure(declaration.name,error);
      }
      continue;
    }

    if(declaration.kind==='instance'){
      try{
        const result=elaborateV061InstanceDeclaration(
          declaration,
          workEnvironment,
          structures,
          classes,
          globalInstances,
        );
        kernel.addDefinition(result.declaration);
        globalInstances.unshift(constant(result.declaration.name));
        admissions.push({
          kind:'instance',
          declaration:result.declaration,
          instance:{
            name:result.declaration.name,
            className:result.className,
            anonymous:declaration.anonymous,
          },
        });
      }catch(error){
        throw declarationFailure(declaration.name,error);
      }
      continue;
    }

    let info:DefinitionInfo|TheoremInfo;
    try{
      info=elaborateV061ValueDeclaration(
        declaration,
        workEnvironment,
        structures,
        classes,
        globalInstances,
      );
    }catch(error){
      throw declarationFailure(declaration.name,error);
    }

    if(info.kind==='theorem')kernel.addTheorem(info);
    else kernel.addDefinition(info);
    admissions.push({kind:'constant',declaration:info});
  }

  return admitCheckedCoreAdmissions(baseEnvironment,admissions);
}

/** Preferred name now that the kernel-facing path also admits proof terms. */
export const elaborateV061Declarations=elaborateV061Definitions;
