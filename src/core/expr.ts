import { Level, instantiateLevel, levelEqStructural, levelHasMVar, levelToString } from './level.js';
import { Name, nameEq, nameFromDotted, nameKey, nameToString } from './name.js';

export type BinderInfo = 'default' | 'implicit' | 'strictImplicit' | 'instImplicit';
export type Literal = { readonly kind: 'nat'; readonly value: bigint } | { readonly kind: 'string'; readonly value: string };
export type Expr =
  | { readonly kind: 'bvar'; readonly index: number }
  | { readonly kind: 'fvar'; readonly id: string }
  | { readonly kind: 'mvar'; readonly id: string }
  | { readonly kind: 'sort'; readonly level: Level }
  | { readonly kind: 'const'; readonly name: Name; readonly levels: readonly Level[] }
  | { readonly kind: 'app'; readonly fn: Expr; readonly arg: Expr }
  | { readonly kind: 'lam'; readonly name: Name; readonly type: Expr; readonly body: Expr; readonly binderInfo: BinderInfo }
  | { readonly kind: 'forall'; readonly name: Name; readonly type: Expr; readonly body: Expr; readonly binderInfo: BinderInfo }
  | { readonly kind: 'let'; readonly name: Name; readonly type: Expr; readonly value: Expr; readonly body: Expr; readonly nondep?: boolean }
  | { readonly kind: 'lit'; readonly literal: Literal }
  | { readonly kind: 'mdata'; readonly data: Readonly<Record<string, unknown>>; readonly expr: Expr }
  | { readonly kind: 'proj'; readonly typeName: Name; readonly index: number; readonly expr: Expr };

export const bvar = (index: number): Expr => ({ kind: 'bvar', index });
export const fvar = (id: string): Expr => ({ kind: 'fvar', id });
export const sort = (level: Level): Expr => ({ kind: 'sort', level });
export const constant = (name: Name, levels: readonly Level[] = []): Expr => ({ kind: 'const', name, levels });
export const app = (fn: Expr, arg: Expr): Expr => ({ kind: 'app', fn, arg });
export const mkAppN = (fn: Expr, args: readonly Expr[]): Expr => args.reduce(app, fn);
export const forallE = (name: Name, type: Expr, body: Expr, binderInfo: BinderInfo = 'default'): Expr => ({ kind: 'forall', name, type, body, binderInfo });
export const lam = (name: Name, type: Expr, body: Expr, binderInfo: BinderInfo = 'default'): Expr => ({ kind: 'lam', name, type, body, binderInfo });
export const natLit = (value: bigint | number): Expr => ({ kind: 'lit', literal: { kind: 'nat', value: BigInt(value) } });
export const strLit = (value: string): Expr => ({ kind: 'lit', literal: { kind: 'string', value } });

function metadataValueEq(a:unknown,b:unknown):boolean{
  if(Object.is(a,b))return true;
  if(typeof a!==typeof b||a===null||b===null)return false;
  if(Array.isArray(a)||Array.isArray(b)){
    if(!Array.isArray(a)||!Array.isArray(b)||a.length!==b.length)return false;
    return a.every((x,i)=>metadataValueEq(x,b[i]));
  }
  if(typeof a==='object'){
    const ao=a as Record<string,unknown>,bo=b as Record<string,unknown>,ak=Object.keys(ao),bk=Object.keys(bo);
    if(ak.length!==bk.length||!ak.every((k,i)=>k===bk[i]))return false;
    return ak.every(k=>metadataValueEq(ao[k],bo[k]));
  }
  return false;
}


const typeAnnotationOutParam = nameFromDotted('outParam');
const typeAnnotationSemiOutParam = nameFromDotted('semiOutParam');
const typeAnnotationOptParam = nameFromDotted('optParam');
const typeAnnotationAutoParam = nameFromDotted('autoParam');

/** Lean 4.34 `Expr.consumeTypeAnnotations`: strip only leading type-annotation gadgets. */
export function consumeTypeAnnotations(e: Expr): Expr {
  const v=appView(e);
  if(v.fn.kind!=='const') return e;
  if((nameEq(v.fn.name,typeAnnotationOutParam)||nameEq(v.fn.name,typeAnnotationSemiOutParam))&&v.args.length===1)
    return consumeTypeAnnotations(v.args[0]!);
  if((nameEq(v.fn.name,typeAnnotationOptParam)||nameEq(v.fn.name,typeAnnotationAutoParam))&&v.args.length===2)
    return consumeTypeAnnotations(v.args[0]!);
  return e;
}

export function getAppFn(e: Expr): Expr { let x=e; while(x.kind==='app') x=x.fn; return x; }
export function getAppArgs(e: Expr): Expr[] { const xs: Expr[]=[]; let x=e; while(x.kind==='app'){xs.push(x.arg);x=x.fn;} xs.reverse(); return xs; }
export function appView(e: Expr): { fn: Expr; args: readonly Expr[] } { return { fn: getAppFn(e), args: getAppArgs(e) }; }
export function stripMData(e: Expr): Expr { while(e.kind==='mdata') e=e.expr; return e; }

export function exprEq(a: Expr, b: Expr): boolean {
  if (a === b) return true; if (a.kind !== b.kind) return false;
  switch(a.kind){
    case 'bvar': return b.kind==='bvar'&&a.index===b.index;
    case 'fvar': return b.kind==='fvar'&&a.id===b.id;
    case 'mvar': return b.kind==='mvar'&&a.id===b.id;
    case 'sort': return b.kind==='sort' && JSON.stringify(a.level, (_k,v)=>typeof v==='bigint'?v.toString():v)===JSON.stringify(b.level,(_k,v)=>typeof v==='bigint'?v.toString():v);
    case 'const': return b.kind==='const'&&nameEq(a.name,b.name)&&a.levels.length===b.levels.length&&a.levels.every((x,i)=>JSON.stringify(x,(_k,v)=>typeof v==='bigint'?v.toString():v)===JSON.stringify(b.levels[i],(_k,v)=>typeof v==='bigint'?v.toString():v));
    case 'app': return b.kind==='app'&&exprEq(a.fn,b.fn)&&exprEq(a.arg,b.arg);
    case 'lam': return b.kind==='lam'&&a.binderInfo===b.binderInfo&&exprEq(a.type,b.type)&&exprEq(a.body,b.body);
    case 'forall': return b.kind==='forall'&&a.binderInfo===b.binderInfo&&exprEq(a.type,b.type)&&exprEq(a.body,b.body);
    case 'let': return b.kind==='let'&&(a.nondep??false)===(b.nondep??false)&&exprEq(a.type,b.type)&&exprEq(a.value,b.value)&&exprEq(a.body,b.body);
    case 'lit': return b.kind==='lit'&&a.literal.kind===b.literal.kind&&(a.literal.kind==='nat'?a.literal.value===(b.literal as {kind:'nat';value:bigint}).value:a.literal.value===(b.literal as {kind:'string';value:string}).value);
    case 'mdata': return b.kind==='mdata'&&metadataValueEq(a.data,b.data)&&exprEq(a.expr,b.expr);
    case 'proj': return b.kind==='proj'&&nameEq(a.typeName,b.typeName)&&a.index===b.index&&exprEq(a.expr,b.expr);
  }
}


/** Lean kernel Expr structural equality for the expression fields represented here.
 * Unlike exprEq, binder display names/info are intentionally ignored. MData payloads
 * participate in structural equality, exactly as Lean's kvmap payload does. */
export function exprLeanEq(a:Expr,b:Expr):boolean{
  const todo:[Expr,Expr][]=[[a,b]];
  while(todo.length){
    const [x,y]=todo.pop()!;
    if(x===y)continue;
    if(x.kind!==y.kind)return false;
    switch(x.kind){
      case'bvar':if(y.kind!=='bvar'||x.index!==y.index)return false;break;
      case'fvar':if(y.kind!=='fvar'||x.id!==y.id)return false;break;
      case'mvar':if(y.kind!=='mvar'||x.id!==y.id)return false;break;
      case'sort':if(y.kind!=='sort'||!levelEqStructural(x.level,y.level))return false;break;
      case'const':
        if(y.kind!=='const'||!nameEq(x.name,y.name)||x.levels.length!==y.levels.length)return false;
        for(let i=0;i<x.levels.length;i++)if(!levelEqStructural(x.levels[i]!,y.levels[i]!))return false;
        break;
      case'app':
        if(y.kind!=='app')return false;
        todo.push([x.fn,y.fn],[x.arg,y.arg]);
        break;
      case'lam':
        if(y.kind!=='lam')return false;
        todo.push([x.type,y.type],[x.body,y.body]);
        break;
      case'forall':
        if(y.kind!=='forall')return false;
        todo.push([x.type,y.type],[x.body,y.body]);
        break;
      case'let':
        if(y.kind!=='let'||(x.nondep??false)!==(y.nondep??false))return false;
        todo.push([x.type,y.type],[x.value,y.value],[x.body,y.body]);
        break;
      case'lit':
        if(y.kind!=='lit'||x.literal.kind!==y.literal.kind)return false;
        if(x.literal.kind==='nat'){
          if(x.literal.value!==(y.literal as {kind:'nat';value:bigint}).value)return false;
        }else if(x.literal.value!==(y.literal as {kind:'string';value:string}).value)return false;
        break;
      case'mdata':
        if(y.kind!=='mdata'||!metadataValueEq(x.data,y.data))return false;
        todo.push([x.expr,y.expr]);
        break;
      case'proj':
        if(y.kind!=='proj'||!nameEq(x.typeName,y.typeName)||x.index!==y.index)return false;
        todo.push([x.expr,y.expr]);
        break;
    }
  }
  return true;
}


/** Kernel-generated metadata comparison: binder display names and mdata placement are non-semantic; binder annotations remain significant. */
export function exprKernelMetadataEq(a: Expr, b: Expr): boolean {
  if(a.kind==='mdata') return exprKernelMetadataEq(a.expr,b);
  if(b.kind==='mdata') return exprKernelMetadataEq(a,b.expr);
  if(a===b) return true;
  if(a.kind!==b.kind) return false;
  switch(a.kind){
    case 'bvar': return b.kind==='bvar'&&a.index===b.index;
    case 'fvar': return b.kind==='fvar'&&a.id===b.id;
    case 'mvar': return b.kind==='mvar'&&a.id===b.id;
    case 'sort': return b.kind==='sort'&&JSON.stringify(a.level,(_k,v)=>typeof v==='bigint'?v.toString():v)===JSON.stringify(b.level,(_k,v)=>typeof v==='bigint'?v.toString():v);
    case 'const': return b.kind==='const'&&nameEq(a.name,b.name)&&a.levels.length===b.levels.length&&a.levels.every((x,i)=>JSON.stringify(x,(_k,v)=>typeof v==='bigint'?v.toString():v)===JSON.stringify(b.levels[i],(_k,v)=>typeof v==='bigint'?v.toString():v));
    case 'app': return b.kind==='app'&&exprKernelMetadataEq(a.fn,b.fn)&&exprKernelMetadataEq(a.arg,b.arg);
    case 'lam': return b.kind==='lam'&&a.binderInfo===b.binderInfo&&exprKernelMetadataEq(a.type,b.type)&&exprKernelMetadataEq(a.body,b.body);
    case 'forall': return b.kind==='forall'&&a.binderInfo===b.binderInfo&&exprKernelMetadataEq(a.type,b.type)&&exprKernelMetadataEq(a.body,b.body);
    case 'let': return b.kind==='let'&&(a.nondep??false)===(b.nondep??false)&&exprKernelMetadataEq(a.type,b.type)&&exprKernelMetadataEq(a.value,b.value)&&exprKernelMetadataEq(a.body,b.body);
    case 'lit': return b.kind==='lit'&&a.literal.kind===b.literal.kind&&(a.literal.kind==='nat'?a.literal.value===(b.literal as {kind:'nat';value:bigint}).value:a.literal.value===(b.literal as {kind:'string';value:string}).value);
    case 'proj': return b.kind==='proj'&&nameEq(a.typeName,b.typeName)&&a.index===b.index&&exprKernelMetadataEq(a.expr,b.expr);
  }
}


/** Return the first semantic metadata difference, using the same equivalence as `exprKernelMetadataEq`. */
export function exprKernelMetadataDiff(a: Expr, b: Expr, path = '$'): string | null {
  if(a.kind==='mdata') return exprKernelMetadataDiff(a.expr,b,path+'.mdata');
  if(b.kind==='mdata') return exprKernelMetadataDiff(a,b.expr,path+'.mdata');
  if(a.kind!==b.kind) return `${path}: kind ${a.kind} != ${b.kind}`;
  const levelJson=(x:unknown)=>JSON.stringify(x,(_k,v)=>typeof v==='bigint'?v.toString():v);
  switch(a.kind){
    case 'bvar': return b.kind==='bvar'&&a.index===b.index?null:`${path}: bvar ${a.index} != ${b.kind==='bvar'?b.index:'?'}`;
    case 'fvar': return b.kind==='fvar'&&a.id===b.id?null:`${path}: fvar mismatch`;
    case 'mvar': return b.kind==='mvar'&&a.id===b.id?null:`${path}: mvar mismatch`;
    case 'sort': return b.kind==='sort'&&levelJson(a.level)===levelJson(b.level)?null:`${path}: sort ${levelJson(a.level)} != ${b.kind==='sort'?levelJson(b.level):'?'}`;
    case 'const': {
      if(b.kind!=='const') return `${path}: const kind mismatch`;
      if(!nameEq(a.name,b.name)) return `${path}: const name ${nameToString(a.name)} != ${nameToString(b.name)}`;
      if(a.levels.length!==b.levels.length) return `${path}: const level arity ${a.levels.length} != ${b.levels.length}`;
      for(let i=0;i<a.levels.length;i++) if(levelJson(a.levels[i])!==levelJson(b.levels[i])) return `${path}.levels[${i}]: ${levelJson(a.levels[i])} != ${levelJson(b.levels[i])}`;
      return null;
    }
    case 'app': if(b.kind!=='app') return `${path}: app kind mismatch`; return exprKernelMetadataDiff(a.fn,b.fn,path+'.fn')??exprKernelMetadataDiff(a.arg,b.arg,path+'.arg');
    case 'lam': if(b.kind!=='lam') return `${path}: lam kind mismatch`; if(a.binderInfo!==b.binderInfo)return `${path}: binderInfo ${a.binderInfo} != ${b.binderInfo}`; return exprKernelMetadataDiff(a.type,b.type,path+'.type')??exprKernelMetadataDiff(a.body,b.body,path+'.body');
    case 'forall': if(b.kind!=='forall') return `${path}: forall kind mismatch`; if(a.binderInfo!==b.binderInfo)return `${path}: binderInfo ${a.binderInfo} != ${b.binderInfo}`; return exprKernelMetadataDiff(a.type,b.type,path+'.type')??exprKernelMetadataDiff(a.body,b.body,path+'.body');
    case 'let': if(b.kind!=='let') return `${path}: let kind mismatch`; if((a.nondep??false)!==(b.nondep??false))return `${path}: let nondep mismatch`; return exprKernelMetadataDiff(a.type,b.type,path+'.type')??exprKernelMetadataDiff(a.value,b.value,path+'.value')??exprKernelMetadataDiff(a.body,b.body,path+'.body');
    case 'lit': if(b.kind!=='lit'||a.literal.kind!==b.literal.kind)return `${path}: literal kind mismatch`; return a.literal.kind==='nat'?(a.literal.value===(b.literal as {kind:'nat';value:bigint}).value?null:`${path}: nat literal mismatch`):(a.literal.value===(b.literal as {kind:'string';value:string}).value?null:`${path}: string literal mismatch`);
    case 'proj': if(b.kind!=='proj') return `${path}: proj kind mismatch`; if(!nameEq(a.typeName,b.typeName)||a.index!==b.index)return `${path}: projection metadata mismatch`; return exprKernelMetadataDiff(a.expr,b.expr,path+'.expr');
  }
}

/** Lean 4 `has_loose_bvar(e, i)`: whether de Bruijn index `i` is free at the current depth. */
export function hasLooseBVarAt(e: Expr, index: number, depth = 0): boolean {
  const todo:{e:Expr;depth:number}[]=[{e,depth}];
  while(todo.length){
    const f=todo.pop()!,x=f.e;
    switch(x.kind){
      case'bvar':if(x.index===index+f.depth)return true;break;
      case'app':todo.push({e:x.fn,depth:f.depth},{e:x.arg,depth:f.depth});break;
      case'lam':case'forall':todo.push({e:x.type,depth:f.depth},{e:x.body,depth:f.depth+1});break;
      case'let':todo.push({e:x.type,depth:f.depth},{e:x.value,depth:f.depth},{e:x.body,depth:f.depth+1});break;
      case'mdata':case'proj':todo.push({e:x.expr,depth:f.depth});break;
      default:break;
    }
  }
  return false;
}

function hasLooseBVarInPiDomain(b: Expr, vidx: number, strict: boolean): boolean {
  if(b.kind==='forall'){
    if(hasLooseBVarAt(b.type,vidx)){
      if(b.binderInfo==='default') return true;
      if(hasLooseBVarInPiDomain(b.body,0,strict)) return true;
    }
    return hasLooseBVarInPiDomain(b.body,vidx+1,strict);
  }
  return strict ? false : hasLooseBVarAt(b,vidx);
}

/** Port of Lean 4.34 `infer_implicit`; used by kernel-generated recursor types. */
export function inferImplicit(e: Expr, strict: boolean, numParams = Number.MAX_SAFE_INTEGER): Expr {
  if(numParams===0 || e.kind!=='forall') return e;
  const body=inferImplicit(e.body,strict,numParams-1);
  if(e.binderInfo!=='default') return {...e,body};
  return hasLooseBVarInPiDomain(body,0,strict) ? {...e,body,binderInfo:'implicit'} : {...e,body};
}

export function hasLooseBVar(e: Expr, depth=0): boolean {
  const todo:{e:Expr;depth:number}[]=[{e,depth}];
  while(todo.length){
    const f=todo.pop()!,x=f.e;
    switch(x.kind){
      case'bvar':if(x.index>=f.depth)return true;break;
      case'app':todo.push({e:x.fn,depth:f.depth},{e:x.arg,depth:f.depth});break;
      case'lam':case'forall':todo.push({e:x.type,depth:f.depth},{e:x.body,depth:f.depth+1});break;
      case'let':todo.push({e:x.type,depth:f.depth},{e:x.value,depth:f.depth},{e:x.body,depth:f.depth+1});break;
      case'mdata':case'proj':todo.push({e:x.expr,depth:f.depth});break;
      default:break;
    }
  }
  return false;
}
export function hasFVar(e: Expr): boolean {
  const todo:Expr[]=[e];
  while(todo.length){
    const x=todo.pop()!;
    switch(x.kind){
      case'fvar':return true;
      case'app':todo.push(x.fn,x.arg);break;
      case'lam':case'forall':todo.push(x.type,x.body);break;
      case'let':todo.push(x.type,x.value,x.body);break;
      case'mdata':case'proj':todo.push(x.expr);break;
      default:break;
    }
  }
  return false;
}
export function hasMVar(e: Expr): boolean {
  const todo:Expr[]=[e];
  while(todo.length){
    const x=todo.pop()!;
    switch(x.kind){
      case'mvar':return true;
      case'sort':if(levelHasMVar(x.level))return true;break;
      case'const':if(x.levels.some(levelHasMVar))return true;break;
      case'app':todo.push(x.fn,x.arg);break;
      case'lam':case'forall':todo.push(x.type,x.body);break;
      case'let':todo.push(x.type,x.value,x.body);break;
      case'mdata':case'proj':todo.push(x.expr);break;
      default:break;
    }
  }
  return false;
}

export function instantiateExprLevels(e: Expr, params: readonly Name[], levels: readonly Level[]): Expr {
  switch(e.kind){
    case'sort':return {...e,level:instantiateLevel(e.level,params,levels)};
    case'const':return {...e,levels:e.levels.map(l=>instantiateLevel(l,params,levels))};
    case'app':return app(instantiateExprLevels(e.fn,params,levels),instantiateExprLevels(e.arg,params,levels));
    case'lam':return {...e,type:instantiateExprLevels(e.type,params,levels),body:instantiateExprLevels(e.body,params,levels)};
    case'forall':return {...e,type:instantiateExprLevels(e.type,params,levels),body:instantiateExprLevels(e.body,params,levels)};
    case'let':return {...e,type:instantiateExprLevels(e.type,params,levels),value:instantiateExprLevels(e.value,params,levels),body:instantiateExprLevels(e.body,params,levels)};
    case'mdata':return {...e,expr:instantiateExprLevels(e.expr,params,levels)}; case'proj':return {...e,expr:instantiateExprLevels(e.expr,params,levels)}; default:return e;
  }
}

export function exprKey(e: Expr): string {
  switch(e.kind){
    case'bvar':return `b${e.index}`; case'fvar':return `f${e.id}`;case'mvar':return `?${e.id}`;
    case'sort':return `S${JSON.stringify(e.level,(_k,v)=>typeof v==='bigint'?v.toString():v)}`;
    case'const':return `C${nameKey(e.name)}[${e.levels.map(x=>JSON.stringify(x,(_k,v)=>typeof v==='bigint'?v.toString():v)).join(',')}]`;
    case'app':return `A(${exprKey(e.fn)},${exprKey(e.arg)})`; case'lam':return `L(${exprKey(e.type)},${exprKey(e.body)})`;case'forall':return `P(${exprKey(e.type)},${exprKey(e.body)})`;
    case'let':return `T${e.nondep?'1':'0'}(${exprKey(e.type)},${exprKey(e.value)},${exprKey(e.body)})`; case'lit':return e.literal.kind==='nat'?`N${e.literal.value}`:`Q${JSON.stringify(e.literal.value)}`;
    case'mdata':return exprKey(e.expr); case'proj':return `R${nameKey(e.typeName)}:${e.index}(${exprKey(e.expr)})`;
  }
}
export function exprToString(e: Expr): string { switch(e.kind){case'bvar':return `#${e.index}`;case'fvar':return e.id;case'mvar':return `?${e.id}`;case'sort':return 'Sort';case'const':return `${nameToString(e.name)}${e.levels.length?`.{${e.levels.map(levelToString).join(',')}}`:''}`;case'app':return `(${exprToString(e.fn)} ${exprToString(e.arg)})`;case'lam':return `(fun ${nameToString(e.name)} => ${exprToString(e.body)})`;case'forall':return `(Pi ${nameToString(e.name)} : ${exprToString(e.type)}, ${exprToString(e.body)})`;case'let':return `(let ${nameToString(e.name)} := ${exprToString(e.value)}; ${exprToString(e.body)})`;case'lit':return e.literal.kind==='nat'?String(e.literal.value):JSON.stringify(e.literal.value);case'mdata':return exprToString(e.expr);case'proj':return `${exprToString(e.expr)}.${e.index}`;} }
