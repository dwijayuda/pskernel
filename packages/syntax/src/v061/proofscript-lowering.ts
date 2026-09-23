import type {
  V061Declaration,
  V061Module,
  V061Parameter,
  V061StructureField,
} from './ast.js';
import {lowerV061ExprToProofScript} from './proofscript-expression-lowering.js';
import {lowerV061TypeToProofScript} from './proofscript-type-lowering.js';

function lowerParameter(parameter:V061Parameter):string {
  const rendered=
    parameter.name+' : '+
    lowerV061TypeToProofScript(parameter.type);
  switch(parameter.binderInfo??'default'){
    case 'default':
      return rendered;
    case 'implicit':
      return '{'+rendered+'}';
    case 'strictImplicit':
      return '{{'+rendered+'}}';
    case 'instImplicit':
      return '['+rendered+']';
  }
}

function lowerParameterSequence(
  params:readonly V061Parameter[],
):string {
  const out:string[]=[];
  for(let index=0;index<params.length;){
    const parameter=params[index]!;
    if((parameter.binderInfo??'default')!=='default'){
      out.push(lowerParameter(parameter));
      index+=1;
      continue;
    }
    const explicit:string[]=[];
    while(
      index<params.length
      &&(params[index]!.binderInfo??'default')==='default'
    ){
      explicit.push(lowerParameter(params[index]!));
      index+=1;
    }
    out.push('('+explicit.join(', ')+')');
  }
  if(out.length===0)return '';
  return (out[0]!.startsWith('(')?'':' ')+out.join('');
}

function lowerExplicitOnlyParameters(
  params:readonly V061Parameter[],
  owner:string,
):string {
  for(const parameter of params){
    if((parameter.binderInfo??'default')!=='default'){
      throw new Error(
        'PS_PRINT_BINDER_UNSUPPORTED: '+owner+
        ' cannot print non-explicit binder '+parameter.name+
        ' in the current ProofScript grammar',
      );
    }
  }
  return params.length===0
    ?''
    :'('+params.map(lowerParameter).join(', ')+')';
}

function lowerField(field:V061StructureField):string {
  const rendered=
    field.name+' : '+lowerV061TypeToProofScript(field.type);
  switch(field.binderKind){
    case 'explicit':
      return '  '+rendered+';';
    case 'implicit':
      return '  {'+rendered+'};';
    case 'instance':
      return '  ['+rendered+'];';
  }
}

function lowerDeclaration(decl:V061Declaration):string {
  if(decl.kind==='structure'||decl.kind==='class'){
    const params=decl.kind==='class'
      ?lowerExplicitOnlyParameters(decl.params,'class')
      :lowerParameterSequence(decl.params);
    return decl.kind+' '+decl.name+params+' where {
'+
      decl.fields.map(lowerField).join('
')+
      '
};';
  }

  if(decl.kind==='inductive'){
    const params=lowerExplicitOnlyParameters(
      decl.params,
      'inductive',
    );
    const result=decl.resultType===undefined
      ?''
      :' : '+lowerV061TypeToProofScript(decl.resultType);
    const constructors=decl.constructors.map((ctor)=>
      '  | '+ctor.name+
      lowerExplicitOnlyParameters(
        ctor.params,
        'inductive constructor',
      )+
      ';',
    ).join('
');
    return 'inductive '+decl.name+params+result+' where {
'+
      constructors+
      '
};';
  }

  if(decl.kind==='instance'){
    return 'instance'+
      (decl.anonymous?'':' '+decl.name)+
      lowerParameterSequence(decl.params)+
      ' : '+lowerV061TypeToProofScript(decl.resultType)+
      ' := '+lowerV061ExprToProofScript(decl.body)+';';
  }

  const params=lowerParameterSequence(decl.params);
  const base=
    decl.kind+' '+decl.name+params+
    ' : '+lowerV061TypeToProofScript(decl.resultType)+
    ' := '+lowerV061ExprToProofScript(decl.body);
  const whereDeclarations=decl.whereDeclarations??[];
  if(whereDeclarations.length===0)return base+';';

  const locals=whereDeclarations.map((local)=>
    '  '+local.name+
    lowerExplicitOnlyParameters(local.params,'where declaration')+
    ' : '+lowerV061TypeToProofScript(local.resultType)+
    ' := '+lowerV061ExprToProofScript(local.body)+';',
  ).join('
');
  return base+' where {
'+locals+'
};';
}

export function lowerV061ModuleToProofScript(
  module:V061Module,
):string {
  const imports=(module.imports??[])
    .map((name)=>'import '+name)
    .join('\n');
  const declarations=module.declarations
    .map(lowerDeclaration)
    .join('\n\n');
  const sections=[imports,declarations]
    .filter((section)=>section.length>0);
  return sections.length===0?'':sections.join('\n\n')+'\n';
}
