import type {
  VerifiedIrModule,
} from '@proofscript/compiler-ir/verified';
import {emitVerifiedType} from './verified-type-emitter.js';

export type BrandMap=ReadonlyMap<string,string>;
export type TagMap=ReadonlyMap<string,string>;

function freshInternal(
  used:Set<string>,
  prefix:string,
  index:number,
):string {
  let candidate=prefix+index;
  while(used.has(candidate))candidate+='_';
  used.add(candidate);
  return candidate;
}

export function buildBrandMap(
  module:VerifiedIrModule,
):BrandMap {
  const used=new Set([
    ...module.declarations.map((item)=>item.name),
    ...(module.structures??[]).map((item)=>item.name),
    ...(module.inductives??[]).map((item)=>item.name),
  ]);
  const result=new Map<string,string>();
  let index=0;
  for(const structure of module.structures??[]){
    result.set(
      structure.name,
      freshInternal(used,'__ps$brand$',index++),
    );
  }
  return result;
}

export function buildTagMap(
  module:VerifiedIrModule,
):TagMap {
  const used=new Set([
    ...module.declarations.map((item)=>item.name),
    ...(module.structures??[]).map((item)=>item.name),
    ...(module.inductives??[]).map((item)=>item.name),
  ]);
  const result=new Map<string,string>();
  let index=0;
  for(const inductive of module.inductives??[]){
    result.set(
      inductive.name,
      freshInternal(used,'__ps$tag$',index++),
    );
  }
  return result;
}

export function emitVerifiedStructures(
  module:VerifiedIrModule,
  brands:BrandMap,
):string[] {
  const lines:string[]=[];
  for(const structure of module.structures??[]){
    const brand=brands.get(structure.name);
    if(brand===undefined){
      throw new Error(
        "PS_TS_STRUCTURE_BRAND_MISSING: '"+structure.name+"'",
      );
    }
    lines.push(
      'const '+brand+': unique symbol = Symbol('+
      JSON.stringify('ProofScript.'+structure.name)+');',
    );
    lines.push(
      'export interface '+structure.name+' { '+
      'readonly ['+brand+']: true; '+
      structure.fields.map((field)=>
        'readonly '+field.name+': '+
        emitVerifiedType(field.type)+';'
      ).join(' ')+
      ' }',
    );
  }
  return lines;
}

export function emitVerifiedInductives(
  module:VerifiedIrModule,
  tags:TagMap,
):string[] {
  const lines:string[]=[];
  for(const inductive of module.inductives??[]){
    const tag=tags.get(inductive.name);
    if(tag===undefined){
      throw new Error(
        "PS_TS_INDUCTIVE_TAG_MISSING: '"+inductive.name+"'",
      );
    }
    lines.push(
      'const '+tag+': unique symbol = Symbol('+
      JSON.stringify('ProofScript.'+inductive.name+'.tag')+');',
    );
    const typeParameters=inductive.typeParameters??[];
    const genericNames=typeParameters.map((parameter)=>parameter.name);
    const genericSuffix=genericNames.length===0
      ?''
      :'<'+genericNames.join(', ')+'>';
    const variants=inductive.constructors.map((constructor)=>{
      const fields=constructor.fields.map((field)=>
        'readonly '+field.name+': '+
        emitVerifiedType(field.type)+';'
      );
      return '{ readonly ['+tag+']: '+
        JSON.stringify(constructor.name)+'; '+
        fields.join(' ')+' }';
    });
    lines.push(
      'export type '+inductive.name+genericSuffix+' =\n  | '+
      variants.join('\n  | ')+';',
    );
    lines.push('export const '+inductive.name+' = {');
    for(const constructor of inductive.constructors){
      const resultType=inductive.name+genericSuffix;
      if(typeParameters.length===0&&constructor.fields.length===0){
        lines.push(
          '  '+JSON.stringify(constructor.name)+': { ['+tag+']: '+
          JSON.stringify(constructor.name)+' } as '+resultType+',',
        );
        continue;
      }
      const genericPrefix=typeParameters.length===0
        ?''
        :'<'+genericNames.join(', ')+'>';
      const params=constructor.fields.map((field,index)=>
        '__field'+index+': '+emitVerifiedType(field.type)
      ).join(', ');
      const fields=constructor.fields.map((field,index)=>
        field.name+': __field'+index
      );
      lines.push(
        '  '+JSON.stringify(constructor.name)+': '+genericPrefix+
        '('+params+'): '+resultType+' => ({ ['+tag+']: '+
        JSON.stringify(constructor.name)+
        (fields.length===0?'':', '+fields.join(', '))+
        ' } as '+resultType+'),',
      );
    }
    lines.push('} as const;');
  }
  return lines;
}
