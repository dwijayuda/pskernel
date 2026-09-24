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
      // Lean KVMap equality is extensional: insertion/list order is not
      // observable when the same key/value bindings exist.
      for(let i=xk.length-1;i>=0;i--){
        const k=xk[i]!;
        if(!Object.prototype.hasOwnProperty.call(yo,k))return false;
        todo.push([xo[k],yo[k]]);
      }
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
  let x=e;
  while(true){
    const v=appView(x);
    if(v.fn.kind!=='const')return x;
    if((nameEq(v.fn.name,typeAnnotationOutParam)||nameEq(v.fn.name,typeAnnotationSemiOutParam))&&v.args.length===1){x=v.args[0]!;continue;}
    if((nameEq(v.fn.name,typeAnnotationOptParam)||nameEq(v.fn.name,typeAnnotationAutoParam))&&v.args.length===2){x=v.args[0]!;continue;}
    return x;
  }
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
const leanExprHashCache=new WeakMap<object,number>();
const leanLevelHashCache=new WeakMap<object,number>();

function mixLeanHash(h:number,x:number):number{
  h^=x>>>0;
  return Math.imul(h,0x01000193)>>>0;
}
function hashLeanString(s:string):number{
  let h=0x811c9dc5;
  for(let i=0;i<s.length;i++)h=mixLeanHash(h,s.charCodeAt(i));
  return h>>>0;
}
function leanLevelStructuralHash(root:Level):number{
  const cached=leanLevelHashCache.get(root as object);if(cached!==undefined)return cached;
  const todo:{l:Level;done:boolean}[]=[{l:root,done:false}];
  while(todo.length){
    const f=todo.pop()!,l=f.l;
    if(leanLevelHashCache.has(l as object))continue;
    if(!f.done){
      todo.push({l,done:true});
      if(l.kind==='succ')todo.push({l:l.of,done:false});
      else if(l.kind==='max'||l.kind==='imax')todo.push({l:l.right,done:false},{l:l.left,done:false});
      continue;
    }
    let h=hashLeanString(l.kind);
    switch(l.kind){
      case'zero':break;
      case'param':case'mvar':h=mixLeanHash(h,hashLeanString(nameKey(l.name)));break;
      case'succ':h=mixLeanHash(h,leanLevelHashCache.get(l.of as object)!);break;
      case'max':case'imax':
        h=mixLeanHash(h,leanLevelHashCache.get(l.left as object)!);
        h=mixLeanHash(h,leanLevelHashCache.get(l.right as object)!);
        break;
    }
    leanLevelHashCache.set(l as object,h>>>0);
  }
  return leanLevelHashCache.get(root as object)!;
}

/**
 * Cached structural hash compatible with Lean kernel Expr equality.
 *
 * Lean 4.34 stores a hash in Expr.Data when each immutable expression node is
 * constructed. TypeScript objects do not have that field, so keep the
 * equivalent lifetime cache externally. The exact numeric hash need not match
 * Lean's runtime hash; equal expressions must hash equally and the value must
 * remain stable for the immutable Expr node.
 */
export function exprLeanHash(root:Expr):number{
  const cached=leanExprHashCache.get(root as object);if(cached!==undefined)return cached;
  const todo:{e:Expr;done:boolean}[]=[{e:root,done:false}];
  while(todo.length){
    const f=todo.pop()!,e=f.e;
    if(leanExprHashCache.has(e as object))continue;
    if(!f.done){
      todo.push({e,done:true});
      switch(e.kind){
        case'app':todo.push({e:e.arg,done:false},{e:e.fn,done:false});break;
        case'lam':case'forall':todo.push({e:e.body,done:false},{e:e.type,done:false});break;
        case'let':todo.push({e:e.body,done:false},{e:e.value,done:false},{e:e.type,done:false});break;
        case'mdata':case'proj':todo.push({e:e.expr,done:false});break;
        default:break;
      }
      continue;
    }
    let h=hashLeanString(e.kind);
    switch(e.kind){
      case'bvar':h=mixLeanHash(h,e.index);break;
      case'fvar':case'mvar':h=mixLeanHash(h,hashLeanString(e.id));break;
      case'sort':h=mixLeanHash(h,leanLevelStructuralHash(e.level));break;
      case'const':
        h=mixLeanHash(h,hashLeanString(nameKey(e.name)));h=mixLeanHash(h,e.levels.length);
        for(const l of e.levels)h=mixLeanHash(h,leanLevelStructuralHash(l));
        break;
      case'app':
        h=mixLeanHash(mixLeanHash(h,leanExprHashCache.get(e.fn as object)!),leanExprHashCache.get(e.arg as object)!);
        break;
      case'lam':case'forall':
        // Kernel equality ignores binder display names and BinderInfo.
        h=mixLeanHash(mixLeanHash(h,leanExprHashCache.get(e.type as object)!),leanExprHashCache.get(e.body as object)!);
        break;
      case'let':
        // Kernel equality ignores the display name but observes let_nondep.
        h=mixLeanHash(h,e.nondep?1:0);
        h=mixLeanHash(h,leanExprHashCache.get(e.type as object)!);
        h=mixLeanHash(h,leanExprHashCache.get(e.value as object)!);
        h=mixLeanHash(h,leanExprHashCache.get(e.body as object)!);
        break;
      case'lit':
        h=mixLeanHash(h,hashLeanString(e.literal.kind));
        h=mixLeanHash(h,hashLeanString(e.literal.kind==='nat'?e.literal.value.toString():e.literal.value));
        break;
      case'mdata':
        // Lean's Expr.Data hash also ignores the metadata payload; equality
        // checks the KVMap only after the hash/shape fast path.
        h=mixLeanHash(h,leanExprHashCache.get(e.expr as object)!);
        break;
      case'proj':
        h=mixLeanHash(h,hashLeanString(nameKey(e.typeName)));h=mixLeanHash(h,e.index);
        h=mixLeanHash(h,leanExprHashCache.get(e.expr as object)!);
        break;
    }
    leanExprHashCache.set(e as object,h>>>0);
  }
  return leanExprHashCache.get(root as object)!;
}

export function exprLeanEq(a:Expr,b:Expr):boolean{
  const compared=new WeakMap<object,WeakSet<object>>();
  const alreadyCompared=(x:Expr,y:Expr):boolean=>{
    let ys=compared.get(x as object);
    if(ys?.has(y as object))return true;
    if(ys===undefined){ys=new WeakSet<object>();compared.set(x as object,ys);}
    ys.add(y as object);
    return false;
  };
  const todo:[Expr,Expr][]=[[a,b]];
  while(todo.length){
    const [x,y]=todo.pop()!;
    if(x===y)continue;
    // Lean 4.34 expr_eq_fn rejects different cached Expr.Data hashes before
    // walking children. This is crucial for large proof terms.
    if(exprLeanHash(x)!==exprLeanHash(y))return false;
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
        if(alreadyCompared(x,y))break;
        // Lean compares application arguments before walking the function spine.
        todo.push([x.fn,y.fn],[x.arg,y.arg]);
        break;
      case'lam':
        if(y.kind!=='lam')return false;
        if(alreadyCompared(x,y))break;
        todo.push([x.type,y.type],[x.body,y.body]);
        break;
      case'forall':
        if(y.kind!=='forall')return false;
        if(alreadyCompared(x,y))break;
        todo.push([x.type,y.type],[x.body,y.body]);
        break;
      case'let':
        if(y.kind!=='let'||(x.nondep??false)!==(y.nondep??false))return false;
        if(alreadyCompared(x,y))break;
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
        if(alreadyCompared(x,y))break;
        todo.push([x.expr,y.expr]);
        break;
      case'proj':
        if(y.kind!=='proj'||!nameEq(x.typeName,y.typeName)||x.index!==y.index)return false;
        if(alreadyCompared(x,y))break;
        todo.push([x.expr,y.expr]);
        break;
    }
  }
  return true;
}


/** Lean ConstantInfo/RecursorVal BEq uses Expr.eqv: binder names/annotations
 * are ignored, while mdata placement and payload remain significant. */
export function exprKernelMetadataEq(a: Expr, b: Expr): boolean {
  return exprLeanEq(a,b);
}

/** Return the first difference under the same Expr.eqv semantics used by Lean BEq. */
export function exprKernelMetadataDiff(a: Expr, b: Expr, path = '$'): string | null {
  if(exprLeanEq(a,b))return null;
  if(a.kind!==b.kind)return `${path}: kind ${a.kind} != ${b.kind}`;
  const levelJson=(x:unknown)=>JSON.stringify(x,(_k,v)=>typeof v==='bigint'?v.toString():v);
  switch(a.kind){
    case'bvar':return b.kind==='bvar'&&a.index===b.index?null:`${path}: bvar mismatch`;
    case'fvar':return b.kind==='fvar'&&a.id===b.id?null:`${path}: fvar mismatch`;
    case'mvar':return b.kind==='mvar'&&a.id===b.id?null:`${path}: mvar mismatch`;
    case'sort':return b.kind==='sort'&&levelEqStructural(a.level,b.level)?null:`${path}: sort ${levelJson(a.level)} != ${b.kind==='sort'?levelJson(b.level):'?'}`;
    case'const':{
      if(b.kind!=='const')return `${path}: const kind mismatch`;
      if(!nameEq(a.name,b.name))return `${path}: const name ${nameToString(a.name)} != ${nameToString(b.name)}`;
      if(a.levels.length!==b.levels.length)return `${path}: const level arity ${a.levels.length} != ${b.levels.length}`;
      for(let i=0;i<a.levels.length;i++)if(!levelEqStructural(a.levels[i]!,b.levels[i]!))return `${path}.levels[${i}]: level mismatch`;
      return null;
    }
    case'app':
      if(b.kind!=='app')return `${path}: app kind mismatch`;
      return exprKernelMetadataDiff(a.fn,b.fn,path+'.fn')??exprKernelMetadataDiff(a.arg,b.arg,path+'.arg');
    case'lam':
      if(b.kind!=='lam')return `${path}: lam kind mismatch`;
      return exprKernelMetadataDiff(a.type,b.type,path+'.type')??exprKernelMetadataDiff(a.body,b.body,path+'.body');
    case'forall':
      if(b.kind!=='forall')return `${path}: forall kind mismatch`;
      return exprKernelMetadataDiff(a.type,b.type,path+'.type')??exprKernelMetadataDiff(a.body,b.body,path+'.body');
    case'let':
      if(b.kind!=='let')return `${path}: let kind mismatch`;
      if((a.nondep??false)!==(b.nondep??false))return `${path}: let nondep mismatch`;
      return exprKernelMetadataDiff(a.type,b.type,path+'.type')??exprKernelMetadataDiff(a.value,b.value,path+'.value')??exprKernelMetadataDiff(a.body,b.body,path+'.body');
    case'lit':
      if(b.kind!=='lit'||a.literal.kind!==b.literal.kind)return `${path}: literal kind mismatch`;
      return a.literal.kind==='nat'
        ?(a.literal.value===(b.literal as {kind:'nat';value:bigint}).value?null:`${path}: nat literal mismatch`)
        :(a.literal.value===(b.literal as {kind:'string';value:string}).value?null:`${path}: string literal mismatch`);
    case'mdata':
      if(b.kind!=='mdata')return `${path}: mdata kind mismatch`;
      if(!metadataValueEq(a.data,b.data))return `${path}: mdata payload mismatch`;
      return exprKernelMetadataDiff(a.expr,b.expr,path+'.expr');
    case'proj':
      if(b.kind!=='proj')return `${path}: proj kind mismatch`;
      if(!nameEq(a.typeName,b.typeName)||a.index!==b.index)return `${path}: projection metadata mismatch`;
      return exprKernelMetadataDiff(a.expr,b.expr,path+'.expr');
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
  const todo:{b:Expr;vidx:number}[]=[{b,vidx}];
  while(todo.length){
    const f=todo.pop()!,x=f.b;
    if(x.kind==='forall'){
      if(hasLooseBVarAt(x.type,f.vidx)){
        if(x.binderInfo==='default')return true;
        // Preserve Lean's transitive dependency search before the ordinary body search.
        todo.push({b:x.body,vidx:f.vidx+1},{b:x.body,vidx:0});
      }else{
        todo.push({b:x.body,vidx:f.vidx+1});
      }
    }else if(!strict&&hasLooseBVarAt(x,f.vidx)){
      return true;
    }
  }
  return false;
}

/** Port of Lean 4.34 `infer_implicit`; used by kernel-generated recursor types. */
export function inferImplicit(e: Expr, strict: boolean, numParams = Number.MAX_SAFE_INTEGER): Expr {
  const binders:Extract<Expr,{kind:'forall'}>[]=[];
  let body=e,remaining=numParams;
  while(remaining>0&&body.kind==='forall'){
    binders.push(body);body=body.body;remaining--;
  }
  for(let i=binders.length-1;i>=0;i--){
    const b=binders[i]!;
    const bi=b.binderInfo==='default'&&hasLooseBVarInPiDomain(body,0,strict)?'implicit':b.binderInfo;
    body=body===b.body&&bi===b.binderInfo?b:{...b,body,binderInfo:bi};
  }
  return body;
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
  // Final Lean 4.34 instantiate_lparams returns the original expression when no
  // universe substitution is needed and uses update_* nodes otherwise.
  if(params.length===0)return e;
  type Frame={e:Expr;done:boolean};
  const todo:Frame[]=[{e,done:false}],out:Expr[]=[];
  while(todo.length){
    const f=todo.pop()!,x=f.e;
    if(!f.done){
      switch(x.kind){
        case'sort':{
          const level=instantiateLevel(x.level,params,levels);
          out.push(level===x.level?x:{...x,level});
          break;
        }
        case'const':{
          let changed=false;
          const us=x.levels.map(l=>{const r=instantiateLevel(l,params,levels);if(r!==l)changed=true;return r;});
          out.push(changed?{...x,levels:us}:x);
          break;
        }
        case'app':todo.push({e:x,done:true},{e:x.arg,done:false},{e:x.fn,done:false});break;
        case'lam':case'forall':todo.push({e:x,done:true},{e:x.body,done:false},{e:x.type,done:false});break;
        case'let':todo.push({e:x,done:true},{e:x.body,done:false},{e:x.value,done:false},{e:x.type,done:false});break;
        case'mdata':case'proj':todo.push({e:x,done:true},{e:x.expr,done:false});break;
        default:out.push(x);break;
      }
      continue;
    }
    switch(x.kind){
      case'app':{
        const arg=out.pop()!,fn=out.pop()!;
        out.push(fn===x.fn&&arg===x.arg?x:{...x,fn,arg});break;
      }
      case'lam':case'forall':{
        const body=out.pop()!,type=out.pop()!;
        out.push(type===x.type&&body===x.body?x:{...x,type,body});break;
      }
      case'let':{
        const body=out.pop()!,value=out.pop()!,type=out.pop()!;
        out.push(type===x.type&&value===x.value&&body===x.body?x:{...x,type,value,body});break;
      }
      case'mdata':case'proj':{
        const inner=out.pop()!;
        out.push(inner===x.expr?x:{...x,expr:inner});break;
      }
      default:throw new Error('internal instantiateExprLevels frame');
    }
  }
  if(out.length!==1)throw new Error('internal instantiateExprLevels result');
  return out[0]!;
}

export function exprKey(e: Expr): string {
  type Frame={e:Expr;done:boolean};
  type LevelPart=Level|string;
  const levelKey=(root:Level):string=>{
    const todo:LevelPart[]=[root],parts:string[]=[];
    while(todo.length){
      const x=todo.pop()!;
      if(typeof x==='string'){parts.push(x);continue;}
      switch(x.kind){
        case'zero':parts.push('z');break;
        case'param':{const k=nameKey(x.name);parts.push(`p${k.length}:${k}`);break;}
        case'mvar':{const k=nameKey(x.name);parts.push(`v${k.length}:${k}`);break;}
        case'succ':parts.push('s(');todo.push(')',x.of);break;
        case'max':parts.push('m(');todo.push(')',x.right,',',x.left);break;
        case'imax':parts.push('i(');todo.push(')',x.right,',',x.left);break;
      }
    }
    return parts.join('');
  };
  const todo:Frame[]=[{e,done:false}],out:string[]=[];
  while(todo.length){
    const f=todo.pop()!,x=f.e;
    if(!f.done){
      switch(x.kind){
        case'bvar':out.push(`b${x.index}`);break;
        case'fvar':out.push(`f${x.id}`);break;
        case'mvar':out.push(`?${x.id}`);break;
        case'sort':out.push(`S${levelKey(x.level)}`);break;
        case'const':out.push(`C${nameKey(x.name)}[${x.levels.map(levelKey).join(',')}]`);break;
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
