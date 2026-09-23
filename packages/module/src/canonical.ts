import {createHash} from 'node:crypto';
import type {
  KernelCompatibility,
  ModuleDependency,
  Sha256,
} from './artifact-types.js';
import {DEFAULT_KERNEL} from './artifact-types.js';

export function moduleFail(message:string):never {
  throw new Error('@proofscript/module: '+message);
}
export function moduleObject(
  value:unknown,
):value is Record<string,unknown> {
  return typeof value==='object'&&value!==null&&!Array.isArray(value);
}
export function moduleHex256(value:unknown):value is Sha256 {
  return typeof value==='string'&&/^sha256:[0-9a-f]{64}$/.test(value);
}
export function moduleSha256(text:string):Sha256 {
  return `sha256:${createHash('sha256').update(text,'utf8').digest('hex')}`;
}
export function moduleKernelValid(
  value:unknown,
):value is KernelCompatibility {
  return moduleObject(value)
    &&value.semantics==='lean4'
    &&typeof value.leanVersion==='string'
    &&value.leanVersion.length>0
    &&typeof value.apiVersion==='string'
    &&value.apiVersion.length>0;
}
export function moduleKernelMatchesCurrent(
  kernel:KernelCompatibility,
):boolean {
  return kernel.semantics===DEFAULT_KERNEL.semantics
    &&kernel.leanVersion===DEFAULT_KERNEL.leanVersion
    &&kernel.apiVersion===DEFAULT_KERNEL.apiVersion;
}

export function canonicalJson(value:unknown):string {
  const seen=new Set<object>();
  const go=(x:unknown,path:string):string=>{
    if(x===null||typeof x==='string'||typeof x==='boolean'){
      return JSON.stringify(x);
    }
    if(typeof x==='number'){
      if(!Number.isFinite(x))moduleFail('non-finite number at '+path);
      return Object.is(x,-0)?'0':JSON.stringify(x);
    }
    if(typeof x==='bigint'){
      moduleFail('bigint is not valid module JSON at '+path);
    }
    if(Array.isArray(x)){
      if(seen.has(x))moduleFail('cycle at '+path);
      seen.add(x);
      const out='['+x.map(
        (value,index)=>go(value,path+'['+index+']'),
      ).join(',')+']';
      seen.delete(x);
      return out;
    }
    if(moduleObject(x)){
      if(seen.has(x))moduleFail('cycle at '+path);
      seen.add(x);
      const keys=Object.keys(x)
        .filter((key)=>x[key]!==undefined)
        .sort();
      const out='{'+keys.map(
        (key)=>JSON.stringify(key)+':'+go(x[key],path+'.'+key),
      ).join(',')+'}';
      seen.delete(x);
      return out;
    }
    moduleFail('unsupported value at '+path);
  };
  return go(value,'$');
}

export function normalizeDeclarationStream(text:string):string {
  const normalized=text
    .replace(/\r\n?/g,'\n')
    .replace(/[\t ]+$/gm,'')
    .replace(/\n+$/,'');
  return normalized.length===0?'':normalized+'\n';
}

export function normalizeModuleDependencies(
  dependencies:readonly ModuleDependency[]=[],
):ModuleDependency[] {
  const seen=new Set<string>();
  const out=dependencies.map((dependency,index)=>{
    if(
      typeof dependency.module!=='string'
      ||dependency.module.length===0
      ||!moduleHex256(dependency.integrity)
    ){
      moduleFail('invalid dependency at index '+index);
    }
    if(seen.has(dependency.module)){
      moduleFail("duplicate dependency '"+dependency.module+"'");
    }
    seen.add(dependency.module);
    return {
      module:dependency.module,
      integrity:dependency.integrity,
    };
  });
  out.sort(
    (a,b)=>a.module.localeCompare(b.module)
      ||a.integrity.localeCompare(b.integrity),
  );
  return out;
}
