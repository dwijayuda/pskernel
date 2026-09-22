import { BinderInfo, Expr } from './expr.js';
import { Name } from './name.js';
export type LocalDecl={readonly kind:'local';readonly id:string;readonly userName:Name;readonly binderInfo:BinderInfo;readonly type:Expr}|{readonly kind:'let';readonly id:string;readonly userName:Name;readonly type:Expr;readonly value:Expr};
export class LocalContext{
  private readonly map=new Map<string,LocalDecl>();
  constructor(private readonly seq:{n:number}={n:0}){}
  clone():LocalContext{const c=new LocalContext(this.seq);for(const [k,v] of this.map)c.map.set(k,v);return c;}
  fresh(prefix='x'):string{let id:string;do{id=`${prefix}@${this.seq.n++}`;}while(this.map.has(id));return id;}
  addLocal(id:string,userName:Name,type:Expr,binderInfo:BinderInfo='default'):void{this.map.set(id,{kind:'local',id,userName,binderInfo,type});}
  addLet(id:string,userName:Name,type:Expr,value:Expr):void{this.map.set(id,{kind:'let',id,userName,type,value});}
  get(id:string):LocalDecl|undefined{return this.map.get(id);}
}
