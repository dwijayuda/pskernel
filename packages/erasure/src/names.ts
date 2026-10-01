import {nameKey,nameToString,type Name} from 'lean-ts-kernel';

function hashText(text:string):string {
  let hash=2166136261;
  for(let index=0;index<text.length;index+=1){
    hash^=text.charCodeAt(index);
    hash=Math.imul(hash,16777619);
  }
  return (hash>>>0).toString(16);
}

export function safeIdentifier(
  raw:string,
  fallback='value',
):string {
  let safe=raw.replace(/[^A-Za-z0-9_$]/gu,'_');
  if(safe.length===0)safe=fallback;
  if(!/^[A-Za-z_$]/u.test(safe))safe='_'+safe;
  return safe;
}

export function buildDeclarationNames(
  names:readonly Name[],
):ReadonlyMap<string,string> {
  const result=new Map<string,string>();
  const used=new Set<string>();
  for(const name of names){
    const raw=nameToString(name);
    let candidate=safeIdentifier(raw.replaceAll('.','_'),'decl');
    if(used.has(candidate)){
      candidate=candidate+'_'+hashText(raw);
    }
    used.add(candidate);
    result.set(nameKey(name),candidate);
  }
  return result;
}
