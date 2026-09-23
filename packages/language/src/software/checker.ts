import type {
  V061InductiveDeclaration,
  V061Module,
  V061StructureDeclaration,
  V061ValueDeclaration,
} from '@proofscript/syntax';
import type {
  CheckedSoftwareModule,
  SoftwareSignature,
  SoftwareType,
} from './types.js';
import {softwareTypeEquals,softwareTypeToString} from './types.js';
import {asSoftwareType} from './type-conversion.js';
import {checkValueDeclarationWithWhere} from './where-checker.js';
import {collectStructures} from './structure-checker.js';
import {
  collectConstructorIndex,
  collectInductives,
} from './inductive-checker.js';

export function checkV061SoftwareModule(module:V061Module):CheckedSoftwareModule {
  if(module.declarations.some((decl)=>decl.kind==='class')){
    throw new Error(
      'PS_CHECK_DECL_UNSUPPORTED: class declarations require typeclass/instance elaboration',
    );
  }

  const structureDecls=module.declarations.filter(
    (decl):decl is V061StructureDeclaration=>decl.kind==='structure',
  );
  const inductiveDecls=module.declarations.filter(
    (decl):decl is V061InductiveDeclaration=>decl.kind==='inductive',
  );
  const valueDecls=module.declarations.filter(
    (decl):decl is V061ValueDeclaration=>decl.kind!=='structure'&&decl.kind!=='class'&&decl.kind!=='inductive',
  );

  const nominalNames=new Set<string>();
  for(const declaration of [...structureDecls,...inductiveDecls]){
    if(nominalNames.has(declaration.name)){
      throw new Error(
        "PS_CHECK_DUPLICATE_GLOBAL: duplicate nominal type '"+declaration.name+"'",
      );
    }
    nominalNames.add(declaration.name);
  }

  const structures=collectStructures(structureDecls,nominalNames);
  const inductives=collectInductives(inductiveDecls,nominalNames);
  const constructors=collectConstructorIndex(inductives);

  const signatures=new Map<string,SoftwareSignature>();
  for(const decl of valueDecls){
    if(decl.params.some((param)=>(param.binderInfo??'default')!=='default')){
      throw new Error(
        "PS_CHECK_BINDER_UNSUPPORTED: '"+decl.name+
        "' uses implicit/instance parameters; software-profile generic elaboration is not implemented",
      );
    }
    if(nominalNames.has(decl.name)||constructors.has(decl.name)){
      throw new Error(
        "PS_CHECK_DUPLICATE_GLOBAL: '"+decl.name+"' conflicts with a type or constructor",
      );
    }
    if(signatures.has(decl.name)){
      throw new Error("PS_CHECK_DUPLICATE_DECL: duplicate declaration '"+decl.name+"'");
    }
    signatures.set(decl.name,{
      params:decl.params.map((param)=>asSoftwareType(param.type,nominalNames)),
      result:asSoftwareType(decl.resultType,nominalNames),
    });
  }

  const declarations=valueDecls.map((decl)=>{
    const locals=new Map<string,SoftwareType>();
    const params=decl.params.map((param)=>{
      if(locals.has(param.name)){
        throw new Error("PS_CHECK_DUPLICATE_PARAM: duplicate parameter '"+param.name+"'");
      }
      const type=asSoftwareType(param.type,nominalNames);
      locals.set(param.name,type);
      return {name:param.name,type};
    });

    const resultType=asSoftwareType(decl.resultType,nominalNames);
    const checkedBody=checkValueDeclarationWithWhere(
      decl,
      {locals,signatures,structures,inductives,constructors},
      resultType,
    );
    const body=checkedBody.body;
    if(!softwareTypeEquals(body.resultType,resultType)){
      throw new Error(
        'PS_CHECK_DECL_TYPE: '+decl.name+' expects '+softwareTypeToString(resultType)+
        ', got '+softwareTypeToString(body.resultType),
      );
    }
    return {
      kind:decl.kind,
      name:decl.name,
      params,
      resultType,
      body,
      whereDeclarations:checkedBody.whereDeclarations,
    };
  });

  return {
    kind:'checked-v061-software-module',
    structures:[...structures.values()],
    inductives:[...inductives.values()],
    declarations,
  };
}
