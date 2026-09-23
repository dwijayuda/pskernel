import type {SoftwareIrType} from '@proofscript/compiler-ir';

export function typeScriptType(type:SoftwareIrType):string {
  if(typeof type!=='string'){
    if(type.kind==='nominal')return type.name;
    return '(_arg: '+typeScriptType(type.parameter)+') => '+typeScriptType(type.result);
  }
  switch(type){
    case 'Nat':
    case 'Int':return 'bigint';
    case 'Bool':return 'boolean';
    case 'String':return 'string';
    case 'Unit':return 'undefined';
  }
}

function stableInternalIdentifier(prefix:string,name:string):string {
  let hash=2166136261;
  for(let index=0;index<name.length;index+=1){
    hash^=name.charCodeAt(index);
    hash=Math.imul(hash,16777619);
  }
  const safe=name.replace(/[^A-Za-z0-9_$]/gu,'_');
  return '__ps_'+prefix+'_'+(safe.length===0?'type':safe)+'_'+(hash>>>0).toString(16);
}

export function brandIdentifier(name:string):string {
  return stableInternalIdentifier('brand',name);
}

export function tagIdentifier(name:string):string {
  return stableInternalIdentifier('tag',name);
}

export function property(name:string):string {
  return JSON.stringify(name);
}

export function plainMember(name:string):string {
  return /^[A-Za-z_$][A-Za-z0-9_$]*$/u.test(name)?name:property(name);
}

export function propertyAccess(name:string):string {
  return /^[A-Za-z_$][A-Za-z0-9_$]*$/u.test(name)
    ? '.'+name
    : '['+property(name)+']';
}
