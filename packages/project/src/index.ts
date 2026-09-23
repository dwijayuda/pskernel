export interface ProjectNode {
  readonly name:string;
  readonly dependencies:readonly string[];
}
export interface BuildPlan {
  readonly order:readonly string[];
}

export function createBuildPlan(nodes:readonly ProjectNode[]):BuildPlan{
  const byName=new Map<string,ProjectNode>();
  for(const node of nodes){
    if(node.name.length===0)throw new Error('project node name must be non-empty');
    if(byName.has(node.name))throw new Error(`duplicate project node '${node.name}'`);
    byName.set(node.name,node);
  }
  for(const node of nodes)for(const dep of node.dependencies)if(!byName.has(dep))throw new Error(`missing dependency '${dep}' for '${node.name}'`);

  const temporary=new Set<string>(),permanent=new Set<string>(),order:string[]=[];
  const visit=(name:string,stack:readonly string[]):void=>{
    if(permanent.has(name))return;
    if(temporary.has(name))throw new Error(`dependency cycle: ${[...stack,name].join(' -> ')}`);
    temporary.add(name);
    const node=byName.get(name)!;
    for(const dep of [...node.dependencies].sort())visit(dep,[...stack,name]);
    temporary.delete(name);permanent.add(name);order.push(name);
  };
  for(const name of [...byName.keys()].sort())visit(name,[]);
  return {order};
}

export class BuildCache<Value> {
  private readonly values=new Map<string,Value>();
  get(key:string):Value|undefined{return this.values.get(key);}
  set(key:string,value:Value):void{if(key.length===0)throw new Error('cache key must be non-empty');this.values.set(key,value);}
  has(key:string):boolean{return this.values.has(key);}
  clear():void{this.values.clear();}
}
