import type {
  V061InstanceDeclaration,
  V061ValueDeclaration,
} from '@proofscript/syntax';
import {
  Environment,
  appView,
  nameFromDotted,
  nameToString,
  type DefinitionInfo,
  type Expr,
} from 'lean-ts-kernel';
import type {CheckedCoreStructure} from '@proofscript/checked-core';
import {elaborateV061ValueDeclaration} from './v061-value-declaration-elab.js';

function instanceTargetClass(
  type:Expr,
  classes:ReadonlySet<string>,
):ReturnType<typeof nameFromDotted> {
  let target=type;
  while(target.kind==='forall')target=target.body;
  const view=appView(target);
  if(view.fn.kind!=='const'){
    throw new Error(
      'PS_ELAB_INSTANCE_TARGET: instance result must be an admitted class application',
    );
  }

  const className=nameToString(view.fn.name);
  if(!classes.has(className)){
    throw new Error(
      "PS_ELAB_INSTANCE_TARGET: '"+className+
      "' is not a previously admitted ProofScript class",
    );
  }
  return view.fn.name;
}

export interface ElaboratedV061Instance {
  readonly declaration:DefinitionInfo;
  readonly className:ReturnType<typeof nameFromDotted>;
}

export function elaborateV061InstanceDeclaration(
  source:V061InstanceDeclaration,
  environment:Environment,
  structures:ReadonlyMap<string,CheckedCoreStructure>,
  classes:ReadonlySet<string>,
  globalInstances:readonly Expr[],
):ElaboratedV061Instance {
  const valueSource:V061ValueDeclaration={
    kind:'def',
    name:source.name,
    params:source.params,
    resultType:source.resultType,
    body:source.body,
    terminatedBySemicolon:source.terminatedBySemicolon,
    span:source.span,
  };
  const elaborated=elaborateV061ValueDeclaration(
    valueSource,
    environment,
    structures,
    classes,
    globalInstances,
  );
  if(elaborated.kind!=='definition'){
    throw new Error(
      'PS_ELAB_INSTANCE_INTERNAL: instance did not elaborate as definition',
    );
  }
  return {
    declaration:elaborated,
    className:instanceTargetClass(elaborated.type,classes),
  };
}
