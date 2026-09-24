import { ConstantInfo } from './declaration.js';
import { Name, nameKey, nameToString } from './name.js';

export class KernelError extends Error { constructor(message:string){super(message);this.name='KernelError';} }
export class Environment {
  private readonly constants = new Map<string,ConstantInfo>();
  private _quotInitialized=false;
  private _revision=0;
  private readonly transactions:{revision:number;quotInitialized:boolean;added:string[]}[]=[];

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

  /**
   * Run a synchronous admission transaction without copying the accumulated environment.
   * Additions remain visible while `f` runs and are committed on success. On failure,
   * every addition plus the revision/Quot marker are restored exactly. Nested committed
   * transactions are folded into their parent so an outer rollback remains atomic.
   */
  transaction<T>(f:()=>T):T{
    const tx={revision:this._revision,quotInitialized:this._quotInitialized,added:[] as string[]};
    this.transactions.push(tx);
    let result:T;
    try{
      result=f();
    }catch(e){
      this.transactions.pop();
      for(let i=tx.added.length-1;i>=0;i--)this.constants.delete(tx.added[i]!);
      this._quotInitialized=tx.quotInitialized;
      this._revision=tx.revision;
      throw e;
    }
    this.transactions.pop();
    const parent=this.transactions[this.transactions.length-1];
    if(parent)for(const k of tx.added)parent.added.push(k);
    return result;
  }
  has(n:Name):boolean{return this.constants.has(nameKey(n));}
  find(n:Name):ConstantInfo|undefined{return this.constants.get(nameKey(n));}
  get(n:Name):ConstantInfo{const r=this.find(n);if(!r)throw new KernelError(`unknown constant '${nameToString(n)}'`);return r;}
  add(i:ConstantInfo):void{
    const k=nameKey(i.name);
    if(this.constants.has(k))throw new KernelError(`already declared '${nameToString(i.name)}'`);
    this.constants.set(k,i);
    this.transactions[this.transactions.length-1]?.added.push(k);
    this._revision++;
  }
  get size():number{return this.constants.size;}
  entries():readonly ConstantInfo[]{return [...this.constants.values()];}
}
