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
  const todo:[unknown,unknown][]=[[a,b]];
  while(todo.length){
    const [x,y]=todo.pop()!;
    if(Object.is(x,y))continue;
    if(typeof x!==typeof y||x===null||y===null)return false;
    if(Array.isArray(x)||Array.isArray(y)){
      if(!Array.isArray(x)||!Array.isArray(y)||x.length!==y.length)return false;
      for(let i=x.length-1;i>=0;i--)todo.push([x[i],y[i]]);
      continue;
    }
    if(typeof x==='object'){
      const xo=x as Record<string,unknown>,yo=y as Record<string,unknown>,xk=Object.keys(xo),yk=Object.keys(yo);
      if(xk.length!==yk.length)return false;
      for(let i=0;i<xk.length;i++)if(xk[i]!==yk[i])return false;
      for(let i=xk.length-1;i>=0;i--){const k=xk[i]!;todo.push([xo[k],yo[k]]);}
      continue;
    }
    return false;
  }
  return true;
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
        todo.push([x.arg,y.arg],[x.fn,y.fn]);break;
      case'lam':
        if(y.kind!=='lam'||x.binderInfo!==y.binderInfo)return false;
        todo.push([x.body,y.body],[x.type,y.type]);break;
      case'forall':
        if(y.kind!=='forall'||x.binderInfo!==y.binderInfo)return false;
        todo.push([x.body,y.body],[x.type,y.type]);break;
      case'let':
        if(y.kind!=='let'||(x.nondep??false)!==(y.nondep??false))return false;
        todo.push([x.body,y.body],[x.value,y.value],[x.type,y.type]);break;
      case'lit':
        if(y.kind!=='lit'||x.literal.kind!==y.literal.kind)return false;
        if(x.literal.kind==='nat'){
          if(x.literal.value!==(y.literal as {kind:'nat';value:bigint}).value)return false;
        }else if(x.literal.value!==(y.literal as {kind:'string';value:string}).value)return false;
        break;
      case'mdata':
        if(y.kind!=='mdata'||!metadataValueEq(x.data,y.data))return false;
        todo.push([x.expr,y.expr]);break;
      case'proj':
        if(y.kind!=='proj'||!nameEq(x.typeName,y.typeName)||x.index!==y.index)return false;
        todo.push([x.expr,y.expr]);break;
    }
  }
  return true;
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
  const todo:[Expr,Expr][]=[[a,b]];
  while(todo.length){
    let [x,y]=todo.pop()!;
    while(x.kind==='mdata')x=x.expr;
    while(y.kind==='mdata')y=y.expr;
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
        todo.push([x.arg,y.arg],[x.fn,y.fn]);break;
      case'lam':
        if(y.kind!=='lam'||x.binderInfo!==y.binderInfo)return false;
        todo.push([x.body,y.body],[x.type,y.type]);break;
      case'forall':
        if(y.kind!=='forall'||x.binderInfo!==y.binderInfo)return false;
        todo.push([x.body,y.body],[x.type,y.type]);break;
      case'let':
        if(y.kind!=='let'||(x.nondep??false)!==(y.nondep??false))return false;
        todo.push([x.body,y.body],[x.value,y.value],[x.type,y.type]);break;
      case'lit':
        if(y.kind!=='lit'||x.literal.kind!==y.literal.kind)return false;
        if(x.literal.kind==='nat'){
          if(x.literal.value!==(y.literal as {kind:'nat';value:bigint}).value)return false;
        }else if(x.literal.value!==(y.literal as {kind:'string';value:string}).value)return false;
        break;
      case'proj':
        if(y.kind!=='proj'||!nameEq(x.typeName,y.typeName)||x.index!==y.index)return false;
        todo.push([x.expr,y.expr]);break;
    }
  }
  return true;
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
  type Frame={e:Expr;done:boolean};
  const todo:Frame[]=[{e,done:false}],out:Expr[]=[];
  while(todo.length){
    const f=todo.pop()!,x=f.e;
    if(!f.done){
      switch(x.kind){
        case'sort':out.push({...x,level:instantiateLevel(x.level,params,levels)});break;
        case'const':out.push({...x,levels:x.levels.map(l=>instantiateLevel(l,params,levels))});break;
        case'app':todo.push({e:x,done:true},{e:x.arg,done:false},{e:x.fn,done:false});break;
        case'lam':case'forall':todo.push({e:x,done:true},{e:x.body,done:false},{e:x.type,done:false});break;
        case'let':todo.push({e:x,done:true},{e:x.body,done:false},{e:x.value,done:false},{e:x.type,done:false});break;
        case'mdata':case'proj':todo.push({e:x,done:true},{e:x.expr,done:false});break;
        default:out.push(x);break;
      }
      continue;
    }
    switch(x.kind){
      case'app':{const arg=out.pop()!,fn=out.pop()!;out.push({...x,fn,arg});break;}
      case'lam':case'forall':{const body=out.pop()!,type=out.pop()!;out.push({...x,type,body});break;}
      case'let':{const body=out.pop()!,value=out.pop()!,type=out.pop()!;out.push({...x,type,value,body});break;}
      case'mdata':case'proj':out.push({...x,expr:out.pop()!});break;
      default:throw new Error('internal instantiateExprLevels frame');
    }
  }
  if(out.length!==1)throw new Error('internal instantiateExprLevels result');
  return out[0]!;
}

export function exprKey(e: Expr): string {
  type Frame={e:Expr;done:boolean};
  const levelJson=(x:Level)=>JSON.stringify(x,(_k,v)=>typeof v==='bigint'?v.toString():v);
  const todo:Frame[]=[{e,done:false}],out:string[]=[];
  while(todo.length){
    const f=todo.pop()!,x=f.e;
    if(!f.done){
      switch(x.kind){
        case'bvar':out.push(`b${x.index}`);break;
        case'fvar':out.push(`f${x.id}`);break;
        case'mvar':out.push(`?${x.id}`);break;
        case'sort':out.push(`S${levelJson(x.level)}`);break;
        case'const':out.push(`C${nameKey(x.name)}[${x.levels.map(levelJson).join(',')}]`);break;
        case'lit':out.push(x.literal.kind==='nat'?`N${x.literal.value}`:`Q${JSON.stringify(x.literal.value)}`);break;
        case'app':todo.push({e:x,done:true},{e:x.arg,done:false},{e:x.fn,done:false});break;
        case'lam':case'forall':todo.push({e:x,done:true},{e:x.body,done:false},{e:x.type,done:false});break;
        case'let':todo.push({e:x,done:true},{e:x.body,done:false},{e:x.value,done:false},{e:x.type,done:false});break;
        case'mdata':todo.push({e:x.expr,done:false});break;
        case'proj':todo.push({e:x,done:true},{e:x.expr,done:false});break;
      }
      continue;
    }
    switch(x.kind){
      case'app':{const arg=out.pop()!,fn=out.pop()!;out.push(`A(${fn},${arg})`);break;}
      case'lam':{const body=out.pop()!,type=out.pop()!;out.push(`L(${type},${body})`);break;}
      case'forall':{const body=out.pop()!,type=out.pop()!;out.push(`P(${type},${body})`);break;}
      case'let':{const body=out.pop()!,value=out.pop()!,type=out.pop()!;out.push(`T${x.nondep?'1':'0'}(${type},${value},${body})`);break;}
      case'proj':out.push(`R${nameKey(x.typeName)}:${x.index}(${out.pop()!})`);break;
      default:throw new Error('internal exprKey frame');
    }
  }
  if(out.length!==1)throw new Error('internal exprKey result');
  return out[0]!;
}
export function exprToString(e: Expr): string { switch(e.kind){case'bvar':return `#${e.index}`;case'fvar':return e.id;case'mvar':return `?${e.id}`;case'sort':return 'Sort';case'const':return `${nameToString(e.name)}${e.levels.length?`.{${e.levels.map(levelToString).join(',')}}`:''}`;case'app':return `(${exprToString(e.fn)} ${exprToString(e.arg)})`;case'lam':return `(fun ${nameToString(e.name)} => ${exprToString(e.body)})`;case'forall':return `(Pi ${nameToString(e.name)} : ${exprToString(e.type)}, ${exprToString(e.body)})`;case'let':return `(let ${nameToString(e.name)} := ${exprToString(e.value)}; ${exprToString(e.body)})`;case'lit':return e.literal.kind==='nat'?String(e.literal.value):JSON.stringify(e.literal.value);case'mdata':return exprToString(e.expr);case'proj':return `${exprToString(e.expr)}.${e.index}`;} }
