export type TransparencyMode='reducible'|'instances'|'semireducible'|'all';
export interface MetaVar<Term> { readonly id:number; readonly type:Term; }
export interface LocalDecl<Term> { readonly name:string; readonly type:Term; readonly value?:Term; }
export interface Goal<Term> { readonly mvar:MetaVar<Term>; readonly locals:readonly LocalDecl<Term>[]; }
export interface MetaKernel<Term> {
  inferType(term:Term):Term;
  isDefEq(left:Term,right:Term,transparency:TransparencyMode):boolean;
}
export class MetaVarContext<Term> {
  private nextId=0;
  private readonly assignments=new Map<number,Term>();
  create(type:Term):MetaVar<Term>{return {id:this.nextId++,type};}
  isAssigned(meta:MetaVar<Term>):boolean{return this.assignments.has(meta.id);}
  getAssignment(meta:MetaVar<Term>):Term|undefined{return this.assignments.get(meta.id);}
  assign(meta:MetaVar<Term>,value:Term,occurs?:(meta:MetaVar<Term>,value:Term)=>boolean):void{
    if(this.assignments.has(meta.id))throw new Error(`metavariable ?m${meta.id} is already assigned`);
    if(occurs?.(meta,value))throw new Error(`occurs check failed for ?m${meta.id}`);
    this.assignments.set(meta.id,value);
  }
  snapshot():ReadonlyMap<number,Term>{return new Map(this.assignments);}
}
export function createGoal<Term>(context:MetaVarContext<Term>,target:Term,locals:readonly LocalDecl<Term>[]=[]):Goal<Term>{
  return {mvar:context.create(target),locals:[...locals]};
}
export function checkExpectedType<Term>(
  kernel:MetaKernel<Term>,term:Term,expected:Term,transparency:TransparencyMode='reducible',
):boolean{return kernel.isDefEq(kernel.inferType(term),expected,transparency);}
