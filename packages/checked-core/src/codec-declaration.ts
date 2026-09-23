import type {
  DefinitionInfo,
  InductiveDecl,
  ReducibilityHints,
  TheoremInfo,
} from 'lean-ts-kernel';
import {
  codecArray,
  codecBool,
  codecNat,
  codecObject,
  codecOptionalBool,
  codecString,
  decodeCodecExpr,
  decodeCodecName,
  encodeCodecExpr,
  encodeCodecName,
  type EncodedExpr,
  type EncodedName,
} from './codec-base.js';

type EncodedHints=
  |{readonly k:'opaque'}
  |{readonly k:'abbrev'}
  |{readonly k:'regular';readonly h:string};

export interface EncodedDefinition {
  readonly k:'definition';
  readonly n:EncodedName;
  readonly lp:readonly EncodedName[];
  readonly t:EncodedExpr;
  readonly v:EncodedExpr;
  readonly h:EncodedHints;
  readonly s:'unsafe'|'safe'|'partial';
}
export interface EncodedTheorem {
  readonly k:'theorem';
  readonly n:EncodedName;
  readonly lp:readonly EncodedName[];
  readonly t:EncodedExpr;
  readonly v:EncodedExpr;
}
export interface EncodedInductiveDecl {
  readonly lp:readonly EncodedName[];
  readonly np:number;
  readonly ts:readonly {
    readonly n:EncodedName;
    readonly t:EncodedExpr;
    readonly cs:readonly {readonly n:EncodedName;readonly t:EncodedExpr}[];
  }[];
  readonly u?:boolean;
  readonly nn?:number;
}

function encodeHints(hints:ReducibilityHints):EncodedHints {
  switch(hints.kind){
    case 'opaque':return {k:'opaque'};
    case 'abbrev':return {k:'abbrev'};
    case 'regular':return {k:'regular',h:String(hints.height)};
  }
}
function decodeHints(value:unknown):ReducibilityHints {
  const o=codecObject(value,'hints');
  if(o.k==='opaque')return {kind:'opaque'};
  if(o.k==='abbrev')return {kind:'abbrev'};
  if(o.k==='regular'){
    const h=codecString(o.h,'hints.height');
    if(!/^(?:0|[1-9][0-9]*)$/.test(h))throw new Error('checked-core codec: invalid hint height');
    return {kind:'regular',height:BigInt(h)};
  }
  throw new Error('checked-core codec: invalid reducibility hints');
}
function decodeSafety(value:unknown):DefinitionInfo['safety'] {
  if(value==='unsafe'||value==='safe'||value==='partial')return value;
  throw new Error('checked-core codec: invalid definition safety');
}

export function encodeCodecDefinition(info:DefinitionInfo):EncodedDefinition {
  return {
    k:'definition',
    n:encodeCodecName(info.name),
    lp:info.levelParams.map(encodeCodecName),
    t:encodeCodecExpr(info.type),
    v:encodeCodecExpr(info.value),
    h:encodeHints(info.hints),
    s:info.safety,
  };
}
export function decodeCodecDefinition(value:unknown):DefinitionInfo {
  const o=codecObject(value,'definition');
  if(o.k!=='definition')throw new Error('checked-core codec: expected definition');
  return {
    kind:'definition',
    name:decodeCodecName(o.n),
    levelParams:codecArray(o.lp,'definition.levelParams').map(decodeCodecName),
    type:decodeCodecExpr(o.t),
    value:decodeCodecExpr(o.v),
    hints:decodeHints(o.h),
    safety:decodeSafety(o.s),
  };
}

export function encodeCodecTheorem(info:TheoremInfo):EncodedTheorem {
  return {
    k:'theorem',
    n:encodeCodecName(info.name),
    lp:info.levelParams.map(encodeCodecName),
    t:encodeCodecExpr(info.type),
    v:encodeCodecExpr(info.value),
  };
}
export function decodeCodecTheorem(value:unknown):TheoremInfo {
  const o=codecObject(value,'theorem');
  if(o.k!=='theorem')throw new Error('checked-core codec: expected theorem');
  return {
    kind:'theorem',
    name:decodeCodecName(o.n),
    levelParams:codecArray(o.lp,'theorem.levelParams').map(decodeCodecName),
    type:decodeCodecExpr(o.t),
    value:decodeCodecExpr(o.v),
  };
}

export function encodeCodecInductive(decl:InductiveDecl):EncodedInductiveDecl {
  return {
    lp:decl.levelParams.map(encodeCodecName),
    np:decl.numParams,
    ts:decl.types.map((type)=>({
      n:encodeCodecName(type.name),
      t:encodeCodecExpr(type.type),
      cs:type.ctors.map((ctor)=>({
        n:encodeCodecName(ctor.name),
        t:encodeCodecExpr(ctor.type),
      })),
    })),
    ...(decl.isUnsafe===undefined?{}:{u:decl.isUnsafe}),
    ...(decl.numNested===undefined?{}:{nn:decl.numNested}),
  };
}
export function decodeCodecInductive(value:unknown):InductiveDecl {
  const o=codecObject(value,'inductive');
  return {
    levelParams:codecArray(o.lp,'inductive.levelParams').map(decodeCodecName),
    numParams:codecNat(o.np,'inductive.numParams'),
    types:codecArray(o.ts,'inductive.types').map((raw)=>{
      const type=codecObject(raw,'inductive.type');
      return {
        name:decodeCodecName(type.n),
        type:decodeCodecExpr(type.t),
        ctors:codecArray(type.cs,'inductive.ctors').map((ctorRaw)=>{
          const ctor=codecObject(ctorRaw,'inductive.ctor');
          return {name:decodeCodecName(ctor.n),type:decodeCodecExpr(ctor.t)};
        }),
      };
    }),
    ...(o.u===undefined?{}:{isUnsafe:codecBool(o.u,'inductive.isUnsafe')}),
    ...(o.nn===undefined?{}:{numNested:codecNat(o.nn,'inductive.numNested')}),
  };
}
