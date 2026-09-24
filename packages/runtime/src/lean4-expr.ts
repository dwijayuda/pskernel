import {
  app,
  bvar,
  constant,
  fvar,
  forallE,
  lam,
  nameKey,
  nameFromDotted,
  natLit,
  sort,
  strLit,
  type BinderInfo,
  type Expr,
  type Name,
} from 'lean-ts-kernel';
import type {
  Lean434ConstructorValue,
  Lean434RuntimeValue,
} from './lean4-eval.js';
import {
  kernelLevelToLean434Runtime,
  lean434RuntimeLevelToKernel,
} from './lean4-level.js';
import {
  kernelNameToLean434Runtime,
  lean434RuntimeNameToKernel,
} from './lean4-name.js';

export class Lean434ExprBridgeError extends Error{
  constructor(message:string){
    super(message);
    this.name='Lean434ExprBridgeError';
  }
}

function runtimeCtor(
  value:Lean434RuntimeValue,
  expected:string,
  fields:number,
):Lean434ConstructorValue{
  if(
    typeof value!=='object'
    ||value===null
    ||Array.isArray(value)
    ||!('kind' in value)
    ||value.kind!=='constructor'
    ||value.name!==expected
    ||value.fields.length!==fields
  ){
    throw new Lean434ExprBridgeError(
      "expected Lean runtime constructor '"+expected+
      "' with "+String(fields)+' fields',
    );
  }
  return value;
}

function runtimeNat(
  value:Lean434RuntimeValue,
  where:string,
):number{
  if(
    typeof value!=='bigint'
    ||value<0n
    ||value>BigInt(Number.MAX_SAFE_INTEGER)
  ){
    throw new Lean434ExprBridgeError(
      where+' is not a safe runtime Nat',
    );
  }
  return Number(value);
}

function runtimeList(
  value:Lean434RuntimeValue,
  where:string,
):Lean434RuntimeValue[]{
  const result:Lean434RuntimeValue[]=[];
  let current=value;
  while(true){
    if(
      typeof current!=='object'
      ||current===null
      ||Array.isArray(current)
      ||!('kind' in current)
      ||current.kind!=='constructor'
    ){
      throw new Lean434ExprBridgeError(where+' is not a runtime List');
    }
    if(current.name==='List.nil'){
      if(current.fields.length!==0){
        throw new Lean434ExprBridgeError(
          where+' List.nil has unexpected runtime fields',
        );
      }
      return result;
    }
    if(current.name!=='List.cons'||current.fields.length!==2){
      throw new Lean434ExprBridgeError(
        where+" has unexpected List constructor '"+current.name+"'",
      );
    }
    result.push(current.fields[0]!);
    current=current.fields[1]!;
  }
}

function runtimeListFrom(
  values:readonly Lean434RuntimeValue[],
):Lean434ConstructorValue{
  let out:Lean434ConstructorValue={
    kind:'constructor',
    name:'List.nil',
    fields:[],
  };
  for(let i=values.length-1;i>=0;i--){
    out={
      kind:'constructor',
      name:'List.cons',
      fields:[values[i]!,out],
    };
  }
  return out;
}

function runtimeBinderInfo(
  value:Lean434RuntimeValue,
):BinderInfo{
  if(
    typeof value!=='object'
    ||value===null
    ||Array.isArray(value)
    ||!('kind' in value)
    ||value.kind!=='constructor'
    ||value.fields.length!==0
  ){
    throw new Lean434ExprBridgeError(
      'runtime Lean.BinderInfo is not a nullary constructor',
    );
  }
  switch(value.name){
    case 'Lean.BinderInfo.default':return 'default';
    case 'Lean.BinderInfo.implicit':return 'implicit';
    case 'Lean.BinderInfo.strictImplicit':return 'strictImplicit';
    case 'Lean.BinderInfo.instImplicit':return 'instImplicit';
    default:
      throw new Lean434ExprBridgeError(
        "unexpected runtime Lean.BinderInfo constructor '"+value.name+"'",
      );
  }
}

function kernelBinderInfo(
  value:BinderInfo,
):Lean434ConstructorValue{
  return {
    kind:'constructor',
    name:'Lean.BinderInfo.'+value,
    fields:[],
  };
}

function encodeRuntimeIdName(value:Lean434RuntimeValue,kind:string):string{
  const wrapper=runtimeCtor(value,'Lean.'+kind+'.mk',1);
  return nameKey(lean434RuntimeNameToKernel(wrapper.fields[0]!));
}

/**
 * Decode the exact structural key produced by pskernel nameKey.
 *
 * FVarId/MVarId are Names in Lean but strings in pskernel's elaboration-only
 * Expr nodes. The bridge stores the structural Name key rather than display
 * text so numeric and string components remain distinguishable.
 */
function decodeKernelIdName(key:string,where:string):Name{
  if(key==='a')return nameFromDotted('');
  if(!key.startsWith('a/')){
    throw new Lean434ExprBridgeError(
      where+' does not contain a canonical pskernel Name key',
    );
  }
  let name:Name=nameFromDotted('');
  let offset=1;
  while(offset<key.length){
    if(key[offset]!=='/'){
      throw new Lean434ExprBridgeError(where+' has malformed Name key');
    }
    offset++;
    if(key.startsWith('s:',offset)){
      offset+=2;
      const colon=key.indexOf(':',offset);
      if(colon<0){
        throw new Lean434ExprBridgeError(where+' has malformed string Name key');
      }
      const lengthText=key.slice(offset,colon);
      if(!/^\d+$/u.test(lengthText)){
        throw new Lean434ExprBridgeError(where+' has invalid string length');
      }
      const length=Number(lengthText);
      const start=colon+1;
      const end=start+length;
      if(!Number.isSafeInteger(length)||end>key.length){
        throw new Lean434ExprBridgeError(where+' has invalid string component');
      }
      const component=key.slice(start,end);
      name={
        kind:'str',
        prefix:name,
        value:component,
      };
      offset=end;
      continue;
    }
    if(key.startsWith('n:',offset)){
      offset+=2;
      let end=offset;
      while(end<key.length&&key[end]!=='/')end++;
      const digits=key.slice(offset,end);
      if(!/^\d+$/u.test(digits)){
        throw new Lean434ExprBridgeError(where+' has invalid numeric component');
      }
      name={
        kind:'num',
        prefix:name,
        value:BigInt(digits),
      };
      offset=end;
      continue;
    }
    throw new Lean434ExprBridgeError(where+' has unknown Name-key component');
  }
  return name;
}

function kernelId(
  kind:'FVarId'|'MVarId',
  id:string,
):Lean434ConstructorValue{
  return {
    kind:'constructor',
    name:'Lean.'+kind+'.mk',
    fields:[
      kernelNameToLean434Runtime(
        decodeKernelIdName(id,'Expr.'+kind),
      ),
    ],
  };
}

function runtimeLiteralToKernel(
  value:Lean434RuntimeValue,
):Expr{
  if(
    typeof value!=='object'
    ||value===null
    ||Array.isArray(value)
    ||!('kind' in value)
    ||value.kind!=='constructor'
  ){
    throw new Lean434ExprBridgeError(
      'runtime Lean.Literal is not a constructor',
    );
  }
  switch(value.name){
    case 'Lean.Literal.natVal':{
      const ctor=runtimeCtor(value,'Lean.Literal.natVal',1);
      const n=ctor.fields[0];
      if(typeof n!=='bigint'||n<0n){
        throw new Lean434ExprBridgeError(
          'Lean.Literal.natVal payload is not a runtime Nat',
        );
      }
      return natLit(n);
    }
    case 'Lean.Literal.strVal':{
      const ctor=runtimeCtor(value,'Lean.Literal.strVal',1);
      const s=ctor.fields[0];
      if(typeof s!=='string'){
        throw new Lean434ExprBridgeError(
          'Lean.Literal.strVal payload is not a runtime String',
        );
      }
      return strLit(s);
    }
    default:
      throw new Lean434ExprBridgeError(
        "unexpected runtime Lean.Literal constructor '"+value.name+"'",
      );
  }
}

function kernelLiteralToRuntime(
  value:Extract<Expr,{kind:'lit'}>['literal'],
):Lean434ConstructorValue{
  return value.kind==='nat'
    ?{
      kind:'constructor',
      name:'Lean.Literal.natVal',
      fields:[value.value],
    }
    :{
      kind:'constructor',
      name:'Lean.Literal.strVal',
      fields:[value.value],
    };
}


export type Lean434MDataValue=
  |{readonly kind:'string';readonly value:string}
  |{readonly kind:'bool';readonly value:boolean}
  |{readonly kind:'name';readonly value:Name}
  |{readonly kind:'nat';readonly value:bigint}
  |{readonly kind:'int';readonly value:bigint}
  |{readonly kind:'syntax';readonly value:Lean434RuntimeValue};

export type Lean434MDataRecord=
  Readonly<Record<string,Lean434MDataValue>>;

function runtimeIntToBigInt(
  value:Lean434RuntimeValue,
):bigint{
  if(typeof value==='bigint')return value;
  if(
    typeof value!=='object'
    ||value===null
    ||Array.isArray(value)
    ||!('kind' in value)
    ||value.kind!=='constructor'
  ){
    throw new Lean434ExprBridgeError(
      'Lean.DataValue.ofInt payload is not a runtime Int',
    );
  }
  if(value.name==='Int.ofNat'){
    const ctor=runtimeCtor(value,'Int.ofNat',1);
    const n=ctor.fields[0];
    if(typeof n!=='bigint'||n<0n){
      throw new Lean434ExprBridgeError(
        'Int.ofNat payload is not a runtime Nat',
      );
    }
    return n;
  }
  if(value.name==='Int.negSucc'){
    const ctor=runtimeCtor(value,'Int.negSucc',1);
    const n=ctor.fields[0];
    if(typeof n!=='bigint'||n<0n){
      throw new Lean434ExprBridgeError(
        'Int.negSucc payload is not a runtime Nat',
      );
    }
    return -(n+1n);
  }
  throw new Lean434ExprBridgeError(
    "unexpected runtime Int constructor '"+value.name+"'",
  );
}

function kernelIntToRuntime(
  value:bigint,
):Lean434ConstructorValue{
  return value>=0n
    ?{
      kind:'constructor',
      name:'Int.ofNat',
      fields:[value],
    }
    :{
      kind:'constructor',
      name:'Int.negSucc',
      fields:[-value-1n],
    };
}

function runtimeDataValueToKernel(
  value:Lean434RuntimeValue,
):Lean434MDataValue{
  if(
    typeof value!=='object'
    ||value===null
    ||Array.isArray(value)
    ||!('kind' in value)
    ||value.kind!=='constructor'
  ){
    throw new Lean434ExprBridgeError(
      'Lean KVMap entry value is not a DataValue constructor',
    );
  }
  switch(value.name){
    case 'Lean.DataValue.ofString':{
      const payload=runtimeCtor(value,value.name,1).fields[0];
      if(typeof payload!=='string'){
        throw new Lean434ExprBridgeError(
          'DataValue.ofString payload is not String',
        );
      }
      return {kind:'string',value:payload};
    }
    case 'Lean.DataValue.ofBool':{
      const payload=runtimeCtor(value,value.name,1).fields[0];
      if(typeof payload!=='boolean'){
        throw new Lean434ExprBridgeError(
          'DataValue.ofBool payload is not Bool',
        );
      }
      return {kind:'bool',value:payload};
    }
    case 'Lean.DataValue.ofName':
      return {
        kind:'name',
        value:lean434RuntimeNameToKernel(
          runtimeCtor(value,value.name,1).fields[0]!,
        ),
      };
    case 'Lean.DataValue.ofNat':{
      const payload=runtimeCtor(value,value.name,1).fields[0];
      if(typeof payload!=='bigint'||payload<0n){
        throw new Lean434ExprBridgeError(
          'DataValue.ofNat payload is not Nat',
        );
      }
      return {kind:'nat',value:payload};
    }
    case 'Lean.DataValue.ofInt':
      return {
        kind:'int',
        value:runtimeIntToBigInt(
          runtimeCtor(value,value.name,1).fields[0]!,
        ),
      };
    case 'Lean.DataValue.ofSyntax':{
      const payload=runtimeCtor(value,value.name,1).fields[0]!;
      if(
        typeof payload!=='object'
        ||payload===null
        ||Array.isArray(payload)
        ||!('kind' in payload)
        ||payload.kind!=='constructor'
      ){
        throw new Lean434ExprBridgeError(
          'DataValue.ofSyntax payload is not a logical Syntax constructor',
        );
      }
      return {kind:'syntax',value:payload};
    }
    default:
      throw new Lean434ExprBridgeError(
        "unexpected Lean.DataValue constructor '"+value.name+"'",
      );
  }
}

function kernelDataValueToRuntime(
  value:unknown,
  where:string,
):Lean434ConstructorValue{
  if(
    typeof value!=='object'
    ||value===null
    ||Array.isArray(value)
    ||!('kind' in value)
    ||!('value' in value)
  ){
    throw new Lean434ExprBridgeError(
      where+' is not a canonical Lean MData value',
    );
  }
  const entry=value as {readonly kind:unknown;readonly value:unknown};
  switch(entry.kind){
    case 'string':
      if(typeof entry.value!=='string')break;
      return {
        kind:'constructor',
        name:'Lean.DataValue.ofString',
        fields:[entry.value],
      };
    case 'bool':
      if(typeof entry.value!=='boolean')break;
      return {
        kind:'constructor',
        name:'Lean.DataValue.ofBool',
        fields:[entry.value],
      };
    case 'name':
      if(
        typeof entry.value!=='object'
        ||entry.value===null
        ||!('kind' in entry.value)
      )break;
      return {
        kind:'constructor',
        name:'Lean.DataValue.ofName',
        fields:[
          kernelNameToLean434Runtime(entry.value as Name),
        ],
      };
    case 'nat':
      if(typeof entry.value!=='bigint'||entry.value<0n)break;
      return {
        kind:'constructor',
        name:'Lean.DataValue.ofNat',
        fields:[entry.value],
      };
    case 'int':
      if(typeof entry.value!=='bigint')break;
      return {
        kind:'constructor',
        name:'Lean.DataValue.ofInt',
        fields:[kernelIntToRuntime(entry.value)],
      };
    case 'syntax':
      if(
        typeof entry.value!=='object'
        ||entry.value===null
        ||Array.isArray(entry.value)
        ||!('kind' in entry.value)
        ||entry.value.kind!=='constructor'
      )break;
      return {
        kind:'constructor',
        name:'Lean.DataValue.ofSyntax',
        fields:[entry.value as Lean434ConstructorValue],
      };
  }
  throw new Lean434ExprBridgeError(
    where+' has malformed or unsupported Lean MData value',
  );
}

export function lean434RuntimeMDataToKernel(
  value:Lean434RuntimeValue,
):Lean434MDataRecord{
  const map=runtimeCtor(value,'Lean.KVMap.mk',1);
  const entries=runtimeList(map.fields[0]!,'Lean.KVMap.entries');
  const out:Record<string,Lean434MDataValue>={};
  for(let index=0;index<entries.length;index++){
    const pair=runtimeCtor(
      entries[index]!,
      'Prod.mk',
      2,
    );
    const key=nameKey(
      lean434RuntimeNameToKernel(pair.fields[0]!),
    );
    if(Object.prototype.hasOwnProperty.call(out,key)){
      throw new Lean434ExprBridgeError(
        'Lean KVMap contains duplicate structural key '+key,
      );
    }
    out[key]=runtimeDataValueToKernel(pair.fields[1]!);
  }
  return Object.freeze(out);
}

export function kernelMDataToLean434Runtime(
  data:Readonly<Record<string,unknown>>,
):Lean434ConstructorValue{
  const entries:Lean434RuntimeValue[]=[];
  for(const [key,value] of Object.entries(data)){
    const name=decodeKernelIdName(key,'Expr.mdata key');
    entries.push({
      kind:'constructor',
      name:'Prod.mk',
      fields:[
        kernelNameToLean434Runtime(name),
        kernelDataValueToRuntime(value,'Expr.mdata['+key+']'),
      ],
    });
  }
  return {
    kind:'constructor',
    name:'Lean.KVMap.mk',
    fields:[runtimeListFrom(entries)],
  };
}

/**
 * Convert executable logical Lean.Expr constructors into pskernel Expr.
 *
 * Lean MData/KVMap is normalized into pskernel's metadata record using
 * structural Name keys and tagged DataValue payloads. Syntax values are kept
 * as logical runtime Syntax constructors until the dedicated Syntax bridge
 * lands; they remain untrusted metadata rather than kernel semantics.
 */
export function lean434RuntimeExprToKernel(
  value:Lean434RuntimeValue,
):Expr{
  if(
    typeof value!=='object'
    ||value===null
    ||Array.isArray(value)
    ||!('kind' in value)
    ||value.kind!=='constructor'
  ){
    throw new Lean434ExprBridgeError(
      'runtime Lean.Expr is not a constructor',
    );
  }

  switch(value.name){
    case 'Lean.Expr.bvar':{
      const ctor=runtimeCtor(value,'Lean.Expr.bvar',1);
      return bvar(runtimeNat(ctor.fields[0]!,'Expr.bvar index'));
    }
    case 'Lean.Expr.fvar':{
      const ctor=runtimeCtor(value,'Lean.Expr.fvar',1);
      return fvar(encodeRuntimeIdName(ctor.fields[0]!,'FVarId'));
    }
    case 'Lean.Expr.mvar':{
      const ctor=runtimeCtor(value,'Lean.Expr.mvar',1);
      return {
        kind:'mvar',
        id:encodeRuntimeIdName(ctor.fields[0]!,'MVarId'),
      };
    }
    case 'Lean.Expr.sort':{
      const ctor=runtimeCtor(value,'Lean.Expr.sort',1);
      return sort(lean434RuntimeLevelToKernel(ctor.fields[0]!));
    }
    case 'Lean.Expr.const':{
      const ctor=runtimeCtor(value,'Lean.Expr.const',2);
      const levels=runtimeList(
        ctor.fields[1]!,
        'Expr.const universe levels',
      ).map(lean434RuntimeLevelToKernel);
      return constant(
        lean434RuntimeNameToKernel(ctor.fields[0]!),
        levels,
      );
    }
    case 'Lean.Expr.app':{
      const ctor=runtimeCtor(value,'Lean.Expr.app',2);
      return app(
        lean434RuntimeExprToKernel(ctor.fields[0]!),
        lean434RuntimeExprToKernel(ctor.fields[1]!),
      );
    }
    case 'Lean.Expr.lam':{
      const ctor=runtimeCtor(value,'Lean.Expr.lam',4);
      return lam(
        lean434RuntimeNameToKernel(ctor.fields[0]!),
        lean434RuntimeExprToKernel(ctor.fields[1]!),
        lean434RuntimeExprToKernel(ctor.fields[2]!),
        runtimeBinderInfo(ctor.fields[3]!),
      );
    }
    case 'Lean.Expr.forallE':{
      const ctor=runtimeCtor(value,'Lean.Expr.forallE',4);
      return forallE(
        lean434RuntimeNameToKernel(ctor.fields[0]!),
        lean434RuntimeExprToKernel(ctor.fields[1]!),
        lean434RuntimeExprToKernel(ctor.fields[2]!),
        runtimeBinderInfo(ctor.fields[3]!),
      );
    }
    case 'Lean.Expr.letE':{
      const ctor=runtimeCtor(value,'Lean.Expr.letE',5);
      const nondep=ctor.fields[4];
      if(typeof nondep!=='boolean'){
        throw new Lean434ExprBridgeError(
          'Expr.letE nondep flag is not a runtime Bool',
        );
      }
      return {
        kind:'let',
        name:lean434RuntimeNameToKernel(ctor.fields[0]!),
        type:lean434RuntimeExprToKernel(ctor.fields[1]!),
        value:lean434RuntimeExprToKernel(ctor.fields[2]!),
        body:lean434RuntimeExprToKernel(ctor.fields[3]!),
        nondep,
      };
    }
    case 'Lean.Expr.lit':{
      const ctor=runtimeCtor(value,'Lean.Expr.lit',1);
      return runtimeLiteralToKernel(ctor.fields[0]!);
    }
    case 'Lean.Expr.mdata':{
      const ctor=runtimeCtor(value,'Lean.Expr.mdata',2);
      return {
        kind:'mdata',
        data:lean434RuntimeMDataToKernel(ctor.fields[0]!),
        expr:lean434RuntimeExprToKernel(ctor.fields[1]!),
      };
    }
    case 'Lean.Expr.proj':{
      const ctor=runtimeCtor(value,'Lean.Expr.proj',3);
      return {
        kind:'proj',
        typeName:lean434RuntimeNameToKernel(ctor.fields[0]!),
        index:runtimeNat(ctor.fields[1]!,'Expr.proj index'),
        expr:lean434RuntimeExprToKernel(ctor.fields[2]!),
      };
    }
    default:
      throw new Lean434ExprBridgeError(
        "unexpected runtime Lean.Expr constructor '"+value.name+"'",
      );
  }
}

/**
 * Convert pskernel Expr into the logical Lean.Expr constructor representation
 * used by the source evaluator.
 *
 * This does not synthesize Lean's computed Expr.Data field. Reused Lean source
 * is interpreted against the logical constructors; optimized computed-field
 * representations remain an untrusted runtime/compiler concern.
 */
export function kernelExprToLean434Runtime(
  expr:Expr,
):Lean434ConstructorValue{
  switch(expr.kind){
    case 'bvar':
      return {
        kind:'constructor',
        name:'Lean.Expr.bvar',
        fields:[BigInt(expr.index)],
      };
    case 'fvar':
      return {
        kind:'constructor',
        name:'Lean.Expr.fvar',
        fields:[kernelId('FVarId',expr.id)],
      };
    case 'mvar':
      return {
        kind:'constructor',
        name:'Lean.Expr.mvar',
        fields:[kernelId('MVarId',expr.id)],
      };
    case 'sort':
      return {
        kind:'constructor',
        name:'Lean.Expr.sort',
        fields:[kernelLevelToLean434Runtime(expr.level)],
      };
    case 'const':
      return {
        kind:'constructor',
        name:'Lean.Expr.const',
        fields:[
          kernelNameToLean434Runtime(expr.name),
          runtimeListFrom(
            expr.levels.map(kernelLevelToLean434Runtime),
          ),
        ],
      };
    case 'app':
      return {
        kind:'constructor',
        name:'Lean.Expr.app',
        fields:[
          kernelExprToLean434Runtime(expr.fn),
          kernelExprToLean434Runtime(expr.arg),
        ],
      };
    case 'lam':
      return {
        kind:'constructor',
        name:'Lean.Expr.lam',
        fields:[
          kernelNameToLean434Runtime(expr.name),
          kernelExprToLean434Runtime(expr.type),
          kernelExprToLean434Runtime(expr.body),
          kernelBinderInfo(expr.binderInfo),
        ],
      };
    case 'forall':
      return {
        kind:'constructor',
        name:'Lean.Expr.forallE',
        fields:[
          kernelNameToLean434Runtime(expr.name),
          kernelExprToLean434Runtime(expr.type),
          kernelExprToLean434Runtime(expr.body),
          kernelBinderInfo(expr.binderInfo),
        ],
      };
    case 'let':
      return {
        kind:'constructor',
        name:'Lean.Expr.letE',
        fields:[
          kernelNameToLean434Runtime(expr.name),
          kernelExprToLean434Runtime(expr.type),
          kernelExprToLean434Runtime(expr.value),
          kernelExprToLean434Runtime(expr.body),
          expr.nondep??false,
        ],
      };
    case 'lit':
      return {
        kind:'constructor',
        name:'Lean.Expr.lit',
        fields:[kernelLiteralToRuntime(expr.literal)],
      };
    case 'mdata':
      return {
        kind:'constructor',
        name:'Lean.Expr.mdata',
        fields:[
          kernelMDataToLean434Runtime(expr.data),
          kernelExprToLean434Runtime(expr.expr),
        ],
      };
    case 'proj':
      return {
        kind:'constructor',
        name:'Lean.Expr.proj',
        fields:[
          kernelNameToLean434Runtime(expr.typeName),
          BigInt(expr.index),
          kernelExprToLean434Runtime(expr.expr),
        ],
      };
  }
}
