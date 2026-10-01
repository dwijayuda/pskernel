import {
  anonymous,
  levelParam,
  levelSucc,
  levelZero,
  mkIMax,
  mkMax,
  numName,
  strName,
  type BinderInfo,
  type Expr,
  type Level,
  type Name,
} from 'lean-ts-kernel';

type Obj=Record<string,unknown>;

export type EncodedName=
  |{readonly k:'a'}
  |{readonly k:'s';readonly p:EncodedName;readonly v:string}
  |{readonly k:'n';readonly p:EncodedName;readonly v:string};

export type EncodedLevel=
  |{readonly k:'z'}
  |{readonly k:'s';readonly o:EncodedLevel}
  |{readonly k:'max';readonly l:EncodedLevel;readonly r:EncodedLevel}
  |{readonly k:'imax';readonly l:EncodedLevel;readonly r:EncodedLevel}
  |{readonly k:'p';readonly n:EncodedName};

export type EncodedExpr=
  |{readonly k:'b';readonly i:number}
  |{readonly k:'sort';readonly l:EncodedLevel}
  |{readonly k:'const';readonly n:EncodedName;readonly ls:readonly EncodedLevel[]}
  |{readonly k:'app';readonly f:EncodedExpr;readonly a:EncodedExpr}
  |{readonly k:'lam'|'forall';readonly n:EncodedName;readonly t:EncodedExpr;readonly b:EncodedExpr;readonly bi:BinderInfo}
  |{readonly k:'let';readonly n:EncodedName;readonly t:EncodedExpr;readonly v:EncodedExpr;readonly b:EncodedExpr}
  |{readonly k:'nat';readonly v:string}
  |{readonly k:'str';readonly v:string}
  |{readonly k:'proj';readonly n:EncodedName;readonly i:number;readonly e:EncodedExpr};

export function codecObject(value:unknown,label:string):Obj {
  if(typeof value!=='object'||value===null||Array.isArray(value)){
    throw new Error('checked-core codec: expected object for '+label);
  }
  return value as Obj;
}
export function codecArray(value:unknown,label:string):readonly unknown[] {
  if(!Array.isArray(value))throw new Error('checked-core codec: expected array for '+label);
  return value;
}
export function codecString(value:unknown,label:string):string {
  if(typeof value!=='string')throw new Error('checked-core codec: expected string for '+label);
  return value;
}
export function codecNat(value:unknown,label:string):number {
  if(typeof value!=='number'||!Number.isSafeInteger(value)||value<0){
    throw new Error('checked-core codec: expected natural number for '+label);
  }
  return value;
}
export function codecBool(value:unknown,label:string):boolean {
  if(typeof value!=='boolean')throw new Error('checked-core codec: expected boolean for '+label);
  return value;
}
export function codecOptionalBool(value:unknown,label:string):boolean|undefined {
  return value===undefined?undefined:codecBool(value,label);
}
function bigintString(value:unknown,label:string):bigint {
  const text=codecString(value,label);
  if(!/^-?(?:0|[1-9][0-9]*)$/.test(text)){
    throw new Error('checked-core codec: invalid bigint for '+label);
  }
  return BigInt(text);
}
function binder(value:unknown):BinderInfo {
  if(value==='default'||value==='implicit'||value==='strictImplicit'||value==='instImplicit')return value;
  throw new Error('checked-core codec: invalid binderInfo');
}

export function encodeCodecName(name:Name):EncodedName {
  switch(name.kind){
    case 'anonymous':return {k:'a'};
    case 'str':return {k:'s',p:encodeCodecName(name.prefix),v:name.value};
    case 'num':return {k:'n',p:encodeCodecName(name.prefix),v:String(name.value)};
  }
}
export function decodeCodecName(value:unknown):Name {
  const o=codecObject(value,'name');
  switch(o.k){
    case 'a':return anonymous;
    case 's':return strName(decodeCodecName(o.p),codecString(o.v,'name.v'));
    case 'n':return numName(decodeCodecName(o.p),bigintString(o.v,'name.v'));
    default:throw new Error('checked-core codec: invalid name tag');
  }
}

export function encodeCodecLevel(level:Level):EncodedLevel {
  switch(level.kind){
    case 'zero':return {k:'z'};
    case 'succ':return {k:'s',o:encodeCodecLevel(level.of)};
    case 'max':return {k:'max',l:encodeCodecLevel(level.left),r:encodeCodecLevel(level.right)};
    case 'imax':return {k:'imax',l:encodeCodecLevel(level.left),r:encodeCodecLevel(level.right)};
    case 'param':return {k:'p',n:encodeCodecName(level.name)};
    case 'mvar':
      throw new Error('checked-core codec: universe metavariables are not persistent');
  }
}
export function decodeCodecLevel(value:unknown):Level {
  const o=codecObject(value,'level');
  switch(o.k){
    case 'z':return levelZero;
    case 's':return levelSucc(decodeCodecLevel(o.o));
    case 'max':return mkMax(decodeCodecLevel(o.l),decodeCodecLevel(o.r));
    case 'imax':return mkIMax(decodeCodecLevel(o.l),decodeCodecLevel(o.r));
    case 'p':return levelParam(decodeCodecName(o.n));
    default:throw new Error('checked-core codec: invalid level tag');
  }
}

export function encodeCodecExpr(expr:Expr):EncodedExpr {
  switch(expr.kind){
    case 'bvar':return {k:'b',i:expr.index};
    case 'sort':return {k:'sort',l:encodeCodecLevel(expr.level)};
    case 'const':return {k:'const',n:encodeCodecName(expr.name),ls:expr.levels.map(encodeCodecLevel)};
    case 'app':return {k:'app',f:encodeCodecExpr(expr.fn),a:encodeCodecExpr(expr.arg)};
    case 'lam':
    case 'forall':
      return {k:expr.kind,n:encodeCodecName(expr.name),t:encodeCodecExpr(expr.type),b:encodeCodecExpr(expr.body),bi:expr.binderInfo};
    case 'let':
      return {k:'let',n:encodeCodecName(expr.name),t:encodeCodecExpr(expr.type),v:encodeCodecExpr(expr.value),b:encodeCodecExpr(expr.body)};
    case 'lit':
      return expr.literal.kind==='nat'
        ?{k:'nat',v:String(expr.literal.value)}
        :{k:'str',v:expr.literal.value};
    case 'proj':return {k:'proj',n:encodeCodecName(expr.typeName),i:expr.index,e:encodeCodecExpr(expr.expr)};
    case 'fvar':
    case 'mvar':
      throw new Error('checked-core codec: free/metavariables are not persistent');
    case 'mdata':
      throw new Error('checked-core codec: expression metadata is not persistent in codec v1');
  }
}
export function decodeCodecExpr(value:unknown):Expr {
  const o=codecObject(value,'expr');
  switch(o.k){
    case 'b':return {kind:'bvar',index:codecNat(o.i,'bvar.index')};
    case 'sort':return {kind:'sort',level:decodeCodecLevel(o.l)};
    case 'const':return {kind:'const',name:decodeCodecName(o.n),levels:codecArray(o.ls,'const.levels').map(decodeCodecLevel)};
    case 'app':return {kind:'app',fn:decodeCodecExpr(o.f),arg:decodeCodecExpr(o.a)};
    case 'lam':
    case 'forall':
      return {kind:o.k,name:decodeCodecName(o.n),type:decodeCodecExpr(o.t),body:decodeCodecExpr(o.b),binderInfo:binder(o.bi)};
    case 'let':return {kind:'let',name:decodeCodecName(o.n),type:decodeCodecExpr(o.t),value:decodeCodecExpr(o.v),body:decodeCodecExpr(o.b)};
    case 'nat':return {kind:'lit',literal:{kind:'nat',value:bigintString(o.v,'nat.value')}};
    case 'str':return {kind:'lit',literal:{kind:'string',value:codecString(o.v,'string.value')}};
    case 'proj':return {kind:'proj',typeName:decodeCodecName(o.n),index:codecNat(o.i,'proj.index'),expr:decodeCodecExpr(o.e)};
    default:throw new Error('checked-core codec: invalid expr tag');
  }
}
