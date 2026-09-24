import {
  Environment,
  appView,
  nameEq,
  nameFromDotted,
  nameKey,
  nameToString,
  type Expr,
} from 'lean-ts-kernel';
import type {CheckedCoreModule} from '@proofscript/checked-core';
import type {
  VerifiedIrExpr,
  VerifiedIrStructure,
} from '@proofscript/compiler-ir/verified';
import type {
  ErasureScope,
  RuntimeStructureInfo,
} from './model.js';

const Prod=nameFromDotted('Prod');
const ProdMk=nameFromDotted('Prod.mk');

function mentionsProd(expr:Expr):boolean {
  switch(expr.kind){
    case 'const':
      return nameEq(expr.name,Prod)
        ||nameToString(expr.name).startsWith('Prod.');
    case 'app':
      return mentionsProd(expr.fn)||mentionsProd(expr.arg);
    case 'lam':
    case 'forall':
      return mentionsProd(expr.type)||mentionsProd(expr.body);
    case 'let':
      return mentionsProd(expr.type)
        ||mentionsProd(expr.value)
        ||mentionsProd(expr.body);
    case 'mdata':
      return mentionsProd(expr.expr);
    case 'proj':
      return nameEq(expr.typeName,Prod)||mentionsProd(expr.expr);
    default:
      return false;
  }
}

function constructorType(
  environment:Environment,
  name:import('lean-ts-kernel').Name,
):Expr|undefined {
  const info=environment.find(name);
  return info?.kind==='constructor'?info.type:undefined;
}

function moduleUsesProd(module:CheckedCoreModule):boolean {
  if(module.definitions.some(
    (item)=>mentionsProd(item.type)||mentionsProd(item.value),
  ))return true;
  for(const structure of module.structures){
    const type=constructorType(module.environment,structure.constructor);
    if(type!==undefined&&mentionsProd(type))return true;
  }
  for(const inductive of module.inductives){
    for(const ctor of inductive.ctors){
      const type=constructorType(module.environment,ctor);
      if(type!==undefined&&mentionsProd(type))return true;
    }
  }
  return false;
}

export interface ImportedRuntimeStructure {
  readonly info:RuntimeStructureInfo;
  readonly ir:VerifiedIrStructure;
}

export function prepareImportedRuntimeStructures(
  module:CheckedCoreModule,
):readonly ImportedRuntimeStructure[] {
  if(!moduleUsesProd(module))return [];

  const inductive=module.environment.find(Prod);
  const constructor=module.environment.find(ProdMk);
  if(
    inductive?.kind!=='inductive'
    ||inductive.numParams!==2
    ||inductive.ctors.length!==1
    ||!nameEq(inductive.ctors[0]!,ProdMk)
    ||constructor?.kind!=='constructor'
    ||constructor.numParams!==2
    ||constructor.numFields!==2
  ){
    throw new Error(
      'PS_ERASE_IMPORTED_PROD_METADATA: Lean Prod metadata is not canonical',
    );
  }

  const typeParameters=[{name:'T0'},{name:'T1'}] as const;
  const fields=[
    {
      sourceIndex:2,
      projectionIndex:0,
      name:'fst',
      type:{kind:'typeParameter',name:'T0'} as const,
    },
    {
      sourceIndex:3,
      projectionIndex:1,
      name:'snd',
      type:{kind:'typeParameter',name:'T1'} as const,
    },
  ];
  const info:RuntimeStructureInfo={
    name:'Prod',
    typeKey:nameKey(Prod),
    constructorKey:nameKey(ProdMk),
    numParams:2,
    typeParameters,
    fields,
  };
  return [{
    info,
    ir:{
      name:'Prod',
      typeParameters,
      fields:fields.map((field)=>({
        name:field.name,
        type:field.type,
      })),
    },
  }];
}

type RuntimeExprEraser=(
  expr:Expr,
  scope:ErasureScope,
  environment:Environment,
)=>VerifiedIrExpr;

export function tryEraseImportedStructureApplication(
  expr:Extract<Expr,{kind:'app'}>,
  scope:ErasureScope,
  environment:Environment,
  erase:RuntimeExprEraser,
):VerifiedIrExpr|undefined {
  const view=appView(expr);
  if(view.fn.kind!=='const')return undefined;
  const name=nameToString(view.fn.name);
  if(name!=='Prod.fst'&&name!=='Prod.snd')return undefined;
  if(view.args.length!==3){
    throw new Error(
      "PS_ERASE_IMPORTED_PROD_PROJECTION_ARITY: '"+name+
      "' expected two type arguments and one runtime pair",
    );
  }
  return {
    kind:'projection',
    target:erase(view.args[2]!,scope,environment),
    field:name==='Prod.fst'?'fst':'snd',
  };
}
