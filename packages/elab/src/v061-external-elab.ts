import type {V061ExternalDeclaration} from '@proofscript/syntax';
import {
  abstractFVar,
  forallE,
  hasMVar,
  nameFromDotted,
  type AxiomInfo,
  type Environment,
  type Expr,
} from 'lean-ts-kernel';
import type {CheckedCoreStructure} from '@proofscript/checked-core';
import {elaborateV061ValueHeader} from './v061-header-elab.js';

export function elaborateV061ExternalDeclaration(
  source:V061ExternalDeclaration,
  environment:Environment,
  structures:ReadonlyMap<string,CheckedCoreStructure>,
  classes:ReadonlySet<string>,
  globalInstances:readonly Expr[],
):AxiomInfo {
  const header=elaborateV061ValueHeader(
    source,
    environment,
    structures,
    classes,
    globalInstances,
  );
  header.context.metaContext.validateGroundAssignments();

  let type=header.context.metaContext.instantiate(header.resultType);
  for(let index=header.parameters.length-1;index>=0;index-=1){
    const parameter=header.parameters[index]!;
    type=forallE(
      parameter.name,
      parameter.type,
      abstractFVar(type,parameter.id),
      parameter.binderInfo,
    );
  }
  type=header.context.metaContext.instantiate(type);
  if(hasMVar(type)){
    throw new Error(
      'PS_ELAB_EXTERNAL_UNSOLVED_METAVARS: external signature contains unresolved metavariables',
    );
  }

  return {
    kind:'axiom',
    name:nameFromDotted(source.name),
    levelParams:[],
    type,
    isUnsafe:false,
  };
}
