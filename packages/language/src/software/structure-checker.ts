import type {V061StructureDeclaration} from '@proofscript/syntax';
import type {SoftwareExpressionContext,CheckSoftwareExpr} from './check-context.js';
import {nominalTypeNames} from './check-context.js';
import type {
  CheckedSoftwareExpr,
  CheckedSoftwareStructure,
  NominalSoftwareType,
  SoftwareType,
} from './types.js';
import {softwareTypeEquals,softwareTypeToString} from './types.js';
import {asSoftwareType} from './type-conversion.js';

export function collectStructures(
  declarations:readonly V061StructureDeclaration[],
  nominalNames:ReadonlySet<string>,
):Map<string,CheckedSoftwareStructure> {
  const structures=new Map<string,CheckedSoftwareStructure>();
  for(const declaration of declarations){
    const seenFields=new Set<string>();
    if(declaration.fields.some((field)=>field.binderKind!=='explicit')){
      throw new Error(
        "PS_CHECK_STRUCTURE_BINDER_UNSUPPORTED: structure '"+declaration.name+
        "' uses implicit/instance fields; generic structure execution is not yet implemented",
      );
    }
    const fields=declaration.fields.map((field)=>{
      if(seenFields.has(field.name)){
        throw new Error(
          "PS_CHECK_DUPLICATE_STRUCTURE_FIELD: duplicate field '"+field.name+
          "' in structure '"+declaration.name+"'",
        );
      }
      seenFields.add(field.name);
      return {name:field.name,type:asSoftwareType(field.type,nominalNames)};
    });
    structures.set(declaration.name,{name:declaration.name,fields});
  }
  return structures;
}

function rootValue(
  name:string,
  context:SoftwareExpressionContext,
):CheckedSoftwareExpr|undefined {
  const local=context.locals.get(name);
  if(local!==undefined)return {kind:'reference',name,resultType:local};
  const signature=context.signatures.get(name);
  if(signature!==undefined&&signature.params.length===0){
    return {kind:'reference',name,resultType:signature.result};
  }
  return undefined;
}

export function tryCheckProjectionReference(
  name:string,
  context:SoftwareExpressionContext,
):CheckedSoftwareExpr|undefined {
  const parts=name.split('.');
  if(parts.length<2)return undefined;
  const rootName=parts[0]!;
  let current=rootValue(rootName,context);
  if(current===undefined)return undefined;

  for(const fieldName of parts.slice(1)){
    const type=current.resultType;
    if(typeof type==='string'||type.kind!=='nominal'){
      throw new Error(
        "PS_CHECK_PROJECTION_TYPE: cannot project '"+fieldName+"' from "+softwareTypeToString(type),
      );
    }
    const structure=context.structures.get(type.name);
    if(structure===undefined)return undefined;
    const field=structure.fields.find((candidate)=>candidate.name===fieldName);
    if(field===undefined){
      throw new Error(
        "PS_CHECK_UNKNOWN_FIELD: structure '"+structure.name+"' has no field '"+fieldName+"'",
      );
    }
    current={kind:'projection',target:current,field:fieldName,resultType:field.type};
  }
  return current;
}

export function checkRecordExpression(
  expr:Extract<import('@proofscript/syntax').V061Expr,{kind:'record'}>,
  context:SoftwareExpressionContext,
  check:CheckSoftwareExpr,
):CheckedSoftwareExpr {
  const annotation=asSoftwareType(expr.type,nominalTypeNames(context));
  if(typeof annotation==='string'||annotation.kind!=='nominal'){
    throw new Error(
      'PS_CHECK_RECORD_TYPE: record annotation must name a structure, got '+
      softwareTypeToString(annotation),
    );
  }
  const structure=context.structures.get(annotation.name);
  if(structure===undefined){
    throw new Error("PS_CHECK_UNKNOWN_STRUCTURE: unknown structure '"+annotation.name+"'");
  }

  const provided=new Map<string,CheckedSoftwareExpr>();
  for(const sourceField of expr.fields){
    if(provided.has(sourceField.name)){
      throw new Error("PS_CHECK_DUPLICATE_FIELD: duplicate field '"+sourceField.name+"'");
    }
    const field=structure.fields.find((candidate)=>candidate.name===sourceField.name);
    if(field===undefined){
      throw new Error(
        "PS_CHECK_UNKNOWN_FIELD: structure '"+structure.name+"' has no field '"+sourceField.name+"'",
      );
    }
    const value=check(sourceField.value,context,field.type);
    if(!softwareTypeEquals(value.resultType,field.type)){
      throw new Error(
        "PS_CHECK_FIELD_TYPE: field '"+sourceField.name+"' expects "+
        softwareTypeToString(field.type)+', got '+softwareTypeToString(value.resultType),
      );
    }
    provided.set(sourceField.name,value);
  }

  const missing=structure.fields.filter((field)=>!provided.has(field.name));
  if(missing.length>0){
    throw new Error(
      'PS_CHECK_MISSING_FIELD: missing '+missing.map((field)=>field.name).join(', ')+
      " for structure '"+structure.name+"'",
    );
  }

  return {
    kind:'record',
    structure:structure.name,
    fields:structure.fields.map((field)=>({name:field.name,value:provided.get(field.name)!})),
    resultType:annotation as NominalSoftwareType,
  };
}
