import type {V061Expr} from '@proofscript/syntax';
import type {SoftwareExpressionContext} from './check-context.js';
import {nominalTypeNames} from './check-context.js';
import type {
  CheckedSoftwareExpr,
  NominalSoftwareType,
  SoftwareType,
} from './types.js';
import {softwareTypeEquals,softwareTypeToString} from './types.js';
import {asSoftwareType} from './type-conversion.js';

export type CheckSoftwareExpr=(
  expr:V061Expr,
  context:SoftwareExpressionContext,
  expected?:SoftwareType,
)=>CheckedSoftwareExpr;

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
    if(structure===undefined){
      throw new Error("PS_CHECK_UNKNOWN_STRUCTURE: unknown structure '"+type.name+"'");
    }
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
  expr:Extract<V061Expr,{kind:'record'}>,
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
