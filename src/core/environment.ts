import { ConstantInfo } from './declaration.js';
import { Name, nameKey, nameToString } from './name.js';

export class KernelError extends Error { constructor(message:string){super(message);this.name='KernelError';} }
export class Environment {
  private readonly constants = new Map<string,ConstantInfo>();
  quotInitialized=false;
  clone():Environment{const e=new Environment();for(const [k,v] of this.constants)e.constants.set(k,v);e.quotInitialized=this.quotInitialized;return e;}
  has(n:Name):boolean{return this.constants.has(nameKey(n));}
  find(n:Name):ConstantInfo|undefined{return this.constants.get(nameKey(n));}
  get(n:Name):ConstantInfo{const r=this.find(n);if(!r)throw new KernelError(`unknown constant '${nameToString(n)}'`);return r;}
  add(i:ConstantInfo):void{const k=nameKey(i.name);if(this.constants.has(k))throw new KernelError(`already declared '${nameToString(i.name)}'`);this.constants.set(k,i);}
  get size():number{return this.constants.size;}
  entries():readonly ConstantInfo[]{return [...this.constants.values()];}
}
