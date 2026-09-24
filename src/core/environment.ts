import { ConstantInfo } from './declaration.js';
import { Name, nameKey, nameToString } from './name.js';

export class KernelError extends Error { constructor(message:string){super(message);this.name='KernelError';} }

const deeplyFrozenKernelValues=new WeakSet<object>();

/**
 * Enforce the runtime immutability promised by the public readonly kernel data
 * types. Lean Expr/Level/Name values are physically immutable; the TypeScript
 * port must preserve that invariant because checker caches are identity-based.
 */
export function deepFreezeKernelValue<T>(value:T):T{
  const visit=(x:unknown):void=>{
    if(x===null||(typeof x!=='object'&&typeof x!=='function'))return;
    const o=x as object;
    if(deeplyFrozenKernelValues.has(o))return;
    // Register before descent so hostile/cyclic metadata cannot recurse forever.
    deeplyFrozenKernelValues.add(o);
    for(const key of Reflect.ownKeys(o)){
      const d=Object.getOwnPropertyDescriptor(o,key);
      if(d&&'value' in d)visit(d.value);
    }
    Object.freeze(o);
  };
  visit(value);
  return value;
}
export class Environment {
  private readonly constants = new Map<string,ConstantInfo>();
  private _quotInitialized=false;
  private _revision=0;

  get quotInitialized():boolean{return this._quotInitialized;}
  set quotInitialized(v:boolean){if(v!==this._quotInitialized){this._quotInitialized=v;this._revision++;}}
  get revision():number{return this._revision;}

  clone():Environment{
    const e=new Environment();
    for(const [k,v] of this.constants)e.constants.set(k,v);
    e._quotInitialized=this._quotInitialized;
    e._revision=this._revision;
    return e;
  }
  has(n:Name):boolean{return this.constants.has(nameKey(n));}
  find(n:Name):ConstantInfo|undefined{return this.constants.get(nameKey(n));}
  get(n:Name):ConstantInfo{const r=this.find(n);if(!r)throw new KernelError(`unknown constant '${nameToString(n)}'`);return r;}
  add(i:ConstantInfo):void{
    deepFreezeKernelValue(i);
    const k=nameKey(i.name);
    if(this.constants.has(k))throw new KernelError(`already declared '${nameToString(i.name)}'`);
    this.constants.set(k,i);
    this._revision++;
  }
  get size():number{return this.constants.size;}
  entries():readonly ConstantInfo[]{return [...this.constants.values()];}
}
