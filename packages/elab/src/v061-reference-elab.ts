import {
  TypeChecker,
  appView,
  fvar,
  nameFromDotted,
  nameToString,
  type Expr,
} from 'lean-ts-kernel';
import type {
  ElaboratedCoreTerm,
  V061CoreElabContext,
} from './v061-context.js';

function rootTerm(
  name:string,
  context:V061CoreElabContext,
):Expr|undefined {
  const local=context.locals.get(name);
  if(local!==undefined)return fvar(local);
  const full=nameFromDotted(name);
  return context.environment.find(full)===undefined
    ?undefined
    :{kind:'const',name:full,levels:[]};
}

export function tryElaborateV061ProjectionReference(
  name:string,
  context:V061CoreElabContext,
):ElaboratedCoreTerm|undefined {
  const parts=name.split('.');
  if(parts.length<2)return undefined;
  let term=rootTerm(parts[0]!,context);
  if(term===undefined)return undefined;
  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );
  let type=checker.check(term);

  for(const fieldName of parts.slice(1)){
    const reduced=appView(checker.whnf(type));
    if(reduced.fn.kind!=='const')return undefined;
    const structure=context.structures.get(nameToString(reduced.fn.name));
    if(structure===undefined)return undefined;
    const field=structure.fields.find((item)=>item.name===fieldName);
    if(field===undefined){
      throw new Error(
        "PS_ELAB_UNKNOWN_PROJECTION: structure '"+
        nameToString(structure.name)+"' has no field '"+fieldName+"'",
      );
    }
    term={
      kind:'proj',
      typeName:structure.name,
      index:field.index,
      expr:term,
    };
    type=checker.check(term);
  }
  return {term,type};
}
