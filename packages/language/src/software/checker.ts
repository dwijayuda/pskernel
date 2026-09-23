import type {V061Module,V061StructureDeclaration} from '@proofscript/syntax';
import type {
  CheckedSoftwareModule,
  CheckedSoftwareStructure,
  SoftwareSignature,
  SoftwareType,
} from './types.js';
import {softwareTypeEquals,softwareTypeToString} from './types.js';
import {asSoftwareType} from './type-conversion.js';
import {checkSoftwareExpr} from './expression-checker.js';

function collectStructures(
  declarations:readonly V061StructureDeclaration[],
):Map<string,CheckedSoftwareStructure> {
  const names=new Set<string>();
  for(const declaration of declarations){
    if(names.has(declaration.name)){
      throw new Error("PS_CHECK_DUPLICATE_STRUCTURE: duplicate structure '"+declaration.name+"'");
    }
    names.add(declaration.name);
  }

  const structures=new Map<string,CheckedSoftwareStructure>();
  for(const declaration of declarations){
    const seenFields=new Set<string>();
    const fields=declaration.fields.map((field)=>{
      if(seenFields.has(field.name)){
        throw new Error(
          "PS_CHECK_DUPLICATE_STRUCTURE_FIELD: duplicate field '"+field.name+
          "' in structure '"+declaration.name+"'",
        );
      }
      seenFields.add(field.name);
      return {name:field.name,type:asSoftwareType(field.type,names)};
    });
    structures.set(declaration.name,{name:declaration.name,fields});
  }
  return structures;
}

export function checkV061SoftwareModule(module:V061Module):CheckedSoftwareModule {
  if(module.declarations.some((decl)=>decl.kind==='inductive')){
    throw new Error(
      'PS_CHECK_DECL_UNSUPPORTED: inductive declarations require ADT elaboration',
    );
  }

  const structureDecls=module.declarations.filter(
    (decl):decl is V061StructureDeclaration=>decl.kind==='structure',
  );
  const structures=collectStructures(structureDecls);
  const nominalNames=new Set(structures.keys());
  const valueDecls=module.declarations.filter((decl)=>decl.kind!=='structure');

  for(const decl of valueDecls){
    if(nominalNames.has(decl.name)){
      throw new Error(
        "PS_CHECK_DUPLICATE_GLOBAL: '"+decl.name+"' is already declared as a structure",
      );
    }
  }

  const signatures=new Map<string,SoftwareSignature>();
  for(const decl of valueDecls){
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
    const body=checkSoftwareExpr(decl.body,{locals,signatures,structures},resultType);
    if(!softwareTypeEquals(body.resultType,resultType)){
      throw new Error(
        'PS_CHECK_DECL_TYPE: '+decl.name+' expects '+softwareTypeToString(resultType)+
        ', got '+softwareTypeToString(body.resultType),
      );
    }
    return {kind:decl.kind,name:decl.name,params,resultType,body};
  });

  return {
    kind:'checked-v061-software-module',
    structures:[...structures.values()],
    declarations,
  };
}
