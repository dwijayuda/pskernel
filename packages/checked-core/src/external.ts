import {
  LocalContext,
  TypeChecker,
  fvar,
  instantiate1,
  nameToString,
  type AxiomInfo,
  type Environment,
  type Expr,
} from 'lean-ts-kernel';

export interface CheckedCoreExternalBinding {
  readonly source:string;
  readonly importedName:string;
}

export interface CheckedCoreExternal {
  readonly declaration:AxiomInfo;
  readonly binding:CheckedCoreExternalBinding;
}

const importIdentifier=/^[A-Za-z_$][A-Za-z0-9_$]*$/u;
const runtimePrimitives=new Set([
  'Nat','Int','Bool','String','Unit',
]);

function isRuntimePrimitive(
  type:Expr,
  checker:TypeChecker,
):boolean {
  const value=checker.whnf(type);
  return value.kind==='const'
    &&runtimePrimitives.has(nameToString(value.name));
}

export function validateCheckedCoreExternal(
  external:CheckedCoreExternal,
  environment:Environment,
):void {
  if(external.declaration.isUnsafe===true){
    throw new Error(
      'checked-core external invariant: runtime externals use explicit '+
      'external-assumption metadata, not Lean unsafe declaration safety',
    );
  }
  if(external.binding.source.length===0){
    throw new Error(
      'checked-core external invariant: module source must be non-empty',
    );
  }
  if(!importIdentifier.test(external.binding.importedName)){
    throw new Error(
      "checked-core external invariant: invalid imported name '"+
      external.binding.importedName+"'",
    );
  }

  let cursor=external.declaration.type;
  let localContext=new LocalContext();
  let parameterCount=0;
  while(true){
    const checker=new TypeChecker(environment,localContext.clone());
    const whnf=checker.whnf(cursor);
    if(whnf.kind!=='forall')break;
    if(
      whnf.binderInfo!=='default'
      ||!isRuntimePrimitive(whnf.type,checker)
    ){
      throw new Error(
        'checked-core external invariant: only explicit primitive runtime '+
        'parameters are supported',
      );
    }
    const next=localContext.clone();
    const id=next.fresh('externalArg');
    next.addLocal(id,whnf.name,whnf.type,whnf.binderInfo);
    cursor=instantiate1(whnf.body,fvar(id));
    localContext=next;
    parameterCount+=1;
  }

  const checker=new TypeChecker(environment,localContext.clone());
  if(parameterCount===0||!isRuntimePrimitive(cursor,checker)){
    throw new Error(
      'checked-core external invariant: extern must be a first-order '+
      'primitive runtime function',
    );
  }
}
