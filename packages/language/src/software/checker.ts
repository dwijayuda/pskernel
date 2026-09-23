import type {V061Module} from '@proofscript/syntax';
import type {
  CheckedSoftwareModule,
  SoftwareSignature,
  SoftwareType,
} from './types.js';
import {softwareTypeEquals,softwareTypeToString} from './types.js';
import {asSoftwareType} from './type-conversion.js';
import {checkSoftwareExpr} from './expression-checker.js';

export function checkV061SoftwareModule(module:V061Module):CheckedSoftwareModule {
  const signatures=new Map<string,SoftwareSignature>();
  for(const decl of module.declarations){
    if(decl.kind==='structure'){
      throw new Error(
        'PS_CHECK_DECL_UNSUPPORTED: structure declarations require nominal structure elaboration',
      );
    }
    if(signatures.has(decl.name)){
      throw new Error("PS_CHECK_DUPLICATE_DECL: duplicate declaration '"+decl.name+"'");
    }
    signatures.set(decl.name,{
      params:decl.params.map((param)=>asSoftwareType(param.type)),
      result:asSoftwareType(decl.resultType),
    });
  }

  const declarations=module.declarations.map((decl)=>{
    if(decl.kind==='structure'){
      throw new Error(
        'PS_CHECK_DECL_UNSUPPORTED: structure declarations require nominal structure elaboration',
      );
    }
    const locals=new Map<string,SoftwareType>();
    const params=decl.params.map((param)=>{
      if(locals.has(param.name)){
        throw new Error("PS_CHECK_DUPLICATE_PARAM: duplicate parameter '"+param.name+"'");
      }
      const type=asSoftwareType(param.type);
      locals.set(param.name,type);
      return {name:param.name,type};
    });

    const resultType=asSoftwareType(decl.resultType);
    const body=checkSoftwareExpr(decl.body,{locals,signatures},resultType);
    if(!softwareTypeEquals(body.resultType,resultType)){
      throw new Error(
        'PS_CHECK_DECL_TYPE: '+decl.name+' expects '+softwareTypeToString(resultType)+
        ', got '+softwareTypeToString(body.resultType),
      );
    }
    return {kind:decl.kind,name:decl.name,params,resultType,body};
  });

  return {kind:'checked-v061-software-module',declarations};
}
