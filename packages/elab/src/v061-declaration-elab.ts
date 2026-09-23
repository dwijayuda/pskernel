import type {
  V061Module,
  V061ValueDeclaration,
} from '@proofscript/syntax';
import {
  Environment,
  Kernel,
  addInductive,
  type DefinitionInfo,
  type TheoremInfo,
  type Expr,
  abstractFVar,
  exprToString,
  forallE,
  hasMVar,
  lam,
  nameFromDotted,
} from 'lean-ts-kernel';
import {
  admitCheckedCoreAdmissions,
  type CheckedCoreAdmission,
  type CheckedCoreModule,
  type CheckedCoreStructure,
} from '@proofscript/checked-core';
import {elaborateV061ValueHeader} from './v061-header-elab.js';
import {elaborateV061StructureDeclaration} from './v061-structure-elab.js';
import {elaborateV061ClassDeclaration} from './v061-class-elab.js';
import {elaborateV061InductiveDeclaration} from './v061-inductive-elab.js';
import {withStructuralRecursionContext} from './v061-structural-recursion.js';
import {
  checkElaboratedTerm,
  elaborateV061Term,
} from './v061-term-elab.js';
import {elaborateV061WhereBody} from './v061-where-elab.js';


function maxRegularHeight(environment:Environment,expr:Expr):bigint {
  let max=0n;
  const visit=(value:Expr):void=>{
    switch(value.kind){
      case 'const':{
        const info=environment.find(value.name);
        if(
          info?.kind==='definition'
          &&info.hints.kind==='regular'
          &&info.hints.height>max
        )max=info.hints.height;
        return;
      }
      case 'app':
        visit(value.fn);
        visit(value.arg);
        return;
      case 'lam':
      case 'forall':
        visit(value.type);
        visit(value.body);
        return;
      case 'let':
        visit(value.type);
        visit(value.value);
        visit(value.body);
        return;
      case 'mdata':
      case 'proj':
        visit(value.expr);
        return;
      default:
        return;
    }
  };
  visit(expr);
  return max;
}

function elaborateValueDeclaration(
  source:V061ValueDeclaration,
  environment:Environment,
  structures:ReadonlyMap<string,CheckedCoreStructure>,
):DefinitionInfo|TheoremInfo {
  const header=elaborateV061ValueHeader(
    source,
    environment,
    structures,
  );
  const context=header.context;
  const parameters=header.parameters;
  const resultType=header.resultType;

  const bodyContext=withStructuralRecursionContext(source,context);
  const whereDeclarations=source.whereDeclarations??[];
  const body=whereDeclarations.length===0
    ? elaborateV061Term(
        source.body,
        bodyContext,
        resultType,
      )
    : elaborateV061WhereBody(
        whereDeclarations,
        source.body,
        bodyContext,
        resultType,
        elaborateV061Term,
      );
  checkElaboratedTerm(body,resultType,bodyContext);
  context.metaContext.validateGroundAssignments();
  let value=context.metaContext.instantiate(body.term);
  let type=context.metaContext.instantiate(resultType);
  if(hasMVar(value)||hasMVar(type)){
    throw new Error(
      'PS_ELAB_UNSOLVED_METAVARS: declaration contains unresolved metavariables',
    );
  }

  for(let index=parameters.length-1;index>=0;index-=1){
    const parameter=parameters[index]!;
    value=lam(
      parameter.name,
      parameter.type,
      abstractFVar(value,parameter.id),
      parameter.binderInfo,
    );
    type=forallE(
      parameter.name,
      parameter.type,
      abstractFVar(type,parameter.id),
      parameter.binderInfo,
    );
  }

  if(source.kind==='theorem'){
    return {
      kind:'theorem',
      name:nameFromDotted(source.name),
      levelParams:[],
      type,
      value,
    };
  }

  return {
    kind:'definition',
    name:nameFromDotted(source.name),
    levelParams:[],
    type,
    value,
    hints:{
      kind:'regular',
      height:maxRegularHeight(environment,value)+1n,
    },
    safety:'safe',
  };
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
  const kernel=new Kernel(workEnvironment);

  for(const declaration of module.declarations){
    if(declaration.kind==='structure'){
      let inductive;
      try{
        inductive=elaborateV061StructureDeclaration(
          declaration,
          workEnvironment,
        );
        addInductive(workEnvironment,inductive.declaration);
      }catch(error){
        const detail=error instanceof Error?error.message:String(error);
        throw new Error(
          "PS_ELAB_DECL_FAILED: '"+declaration.name+"': "+detail,
        );
      }
      structures.set(declaration.name,inductive.structure);
      admissions.push({
        kind:'structure',
        declaration:inductive.declaration,
        structure:inductive.structure,
      });
      continue;
    }
    if(declaration.kind==='inductive'){
      let inductive;
      try{
        inductive=elaborateV061InductiveDeclaration(
          declaration,
          workEnvironment,
        );
        addInductive(workEnvironment,inductive);
      }catch(error){
        const detail=error instanceof Error?error.message:String(error);
        throw new Error(
          "PS_ELAB_DECL_FAILED: '"+declaration.name+"': "+detail,
        );
      }
      admissions.push({
        kind:'inductive',
        declaration:inductive,
      });
      continue;
    }
    if(declaration.kind==='class'){
      let klass;
      try{
        klass=elaborateV061ClassDeclaration(
          declaration,
          workEnvironment,
        );
        addInductive(workEnvironment,klass.declaration);
      }catch(error){
        const detail=error instanceof Error?error.message:String(error);
        throw new Error(
          "PS_ELAB_DECL_FAILED: '"+declaration.name+"': "+detail,
        );
      }
      structures.set(declaration.name,klass.structure);
      admissions.push({
        kind:'class',
        declaration:klass.declaration,
        structure:klass.structure,
      });
      continue;
    }

    let info:DefinitionInfo|TheoremInfo;
    try{
      info=elaborateValueDeclaration(
        declaration,
        workEnvironment,
        structures,
      );
    }catch(error){
      const detail=error instanceof Error?error.message:String(error);
      throw new Error(
        "PS_ELAB_DECL_FAILED: '"+declaration.name+"': "+detail,
      );
    }
    if(info.kind==='theorem')kernel.addTheorem(info);
    else kernel.addDefinition(info);
    admissions.push({kind:'constant',declaration:info});
  }

  return admitCheckedCoreAdmissions(baseEnvironment,admissions);
}


/** Preferred name now that the kernel-facing path also admits theorem proof terms. */
export const elaborateV061Declarations=elaborateV061Definitions;
