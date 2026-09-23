import { Name, nameCmp, nameEq, nameKey, nameToString } from './name.js';

export type Level =
  | { readonly kind: 'zero' }
  | { readonly kind: 'succ'; readonly of: Level }
  | { readonly kind: 'max'; readonly left: Level; readonly right: Level }
  | { readonly kind: 'imax'; readonly left: Level; readonly right: Level }
  | { readonly kind: 'param'; readonly name: Name }
  | { readonly kind: 'mvar'; readonly name: Name };

export const levelZero: Level = Object.freeze({ kind: 'zero' });
export const levelSucc = (of: Level): Level => Object.freeze({ kind: 'succ', of });
export const levelParam = (name: Name): Level => Object.freeze({ kind: 'param', name });
export const levelMVar = (name: Name): Level => Object.freeze({ kind: 'mvar', name });

export function levelEqStructural(a: Level, b: Level): boolean {
  const todo:[Level,Level][]=[[a,b]];
  while(todo.length){
    const [x,y]=todo.pop()!;
    if(x===y)continue;
    if(x.kind!==y.kind)return false;
    switch(x.kind){
      case'zero':break;
      case'param':case'mvar':
        if((y.kind!=='param'&&y.kind!=='mvar')||!nameEq(x.name,y.name))return false;
        break;
      case'succ':
        if(y.kind!=='succ')return false;
        todo.push([x.of,y.of]);
        break;
      case'max':
        if(y.kind!=='max')return false;
        todo.push([x.left,y.left],[x.right,y.right]);
        break;
      case'imax':
        if(y.kind!=='imax')return false;
        todo.push([x.left,y.left],[x.right,y.right]);
        break;
    }
  }
  return true;
}


export function levelHasMVar(l: Level): boolean {
  const todo:Level[]=[l];
  while(todo.length){
    const x=todo.pop()!;
    switch(x.kind){
      case'mvar':return true;
      case'succ':todo.push(x.of);break;
      case'max':case'imax':todo.push(x.right,x.left);break;
      case'zero':case'param':break;
    }
  }
  return false;
}
export function levelParamNames(l: Level, out: Name[]=[]): readonly Name[] {
  const todo:Level[]=[l];
  while(todo.length){
    const x=todo.pop()!;
    switch(x.kind){
      case'param':if(!out.some(n=>nameEq(n,x.name)))out.push(x.name);break;
      case'succ':todo.push(x.of);break;
      case'max':case'imax':todo.push(x.right,x.left);break;
      case'zero':case'mvar':break;
    }
  }
  return out;
}
export function isZero(l: Level): boolean { return l.kind === 'zero'; }
export function isNotZero(l: Level): boolean {
  const todo:Level[]=[l];
  while(todo.length){
    const x=todo.pop()!;
    switch(x.kind){
      case'succ':return true;
      case'max':todo.push(x.right,x.left);break;
      case'imax':todo.push(x.right);break;
      case'zero':case'param':case'mvar':break;
    }
  }
  return false;
}
export function normalizesToZero(l: Level): boolean {
  const todo:Level[]=[l];
  while(todo.length){
    const x=todo.pop()!;
    switch(x.kind){
      case'zero':break;
      case'param':case'mvar':case'succ':return false;
      case'max':todo.push(x.right,x.left);break;
      case'imax':todo.push(x.right);break;
    }
  }
  return true;
}
export function mkMax(a: Level, b: Level): Level {
  if (levelEqStructural(a, b)) return a;
  if (isZero(a)) return b;
  if (isZero(b)) return a;
  if (b.kind==='max'&&(levelEqStructural(b.left,a)||levelEqStructural(b.right,a))) return b;
  if (a.kind==='max'&&(levelEqStructural(a.left,b)||levelEqStructural(a.right,b))) return a;
  const oa = toOffset(a), ob = toOffset(b);
  if (levelEqStructural(oa.base, ob.base)) return oa.offset >= ob.offset ? a : b;
  return Object.freeze({ kind: 'max', left: a, right: b });
}
export function mkIMax(a: Level, b: Level): Level {
  if (isNotZero(b)) return mkMax(a, b);
  if (isZero(b)) return b;
  if (isZero(a) || (a.kind === 'succ' && isZero(a.of))) return b;
  if (levelEqStructural(a, b)) return a;
  return Object.freeze({ kind: 'imax', left: a, right: b });
}
export function toOffset(l: Level): { base: Level; offset: bigint } {
  let k = 0n, x = l;
  while (x.kind === 'succ') { k++; x = x.of; }
  return { base: x, offset: k };
}
export function addOffset(l: Level, k: bigint): Level {
  let r = l; for (let i = 0n; i < k; i++) r = levelSucc(r); return r;
}

export function instantiateLevel(root: Level, params: readonly Name[], values: readonly Level[]): Level {
  const done=new WeakMap<object,Level>();
  const todo:{l:Level;done:boolean}[]=[{l:root,done:false}];
  while(todo.length){
    const f=todo.pop()!,l=f.l;
    if(done.has(l as object))continue;
    if(!f.done){
      todo.push({l,done:true});
      if(l.kind==='succ')todo.push({l:l.of,done:false});
      else if(l.kind==='max'||l.kind==='imax')todo.push({l:l.right,done:false},{l:l.left,done:false});
      continue;
    }
    let r:Level;
    switch(l.kind){
      case'zero':case'mvar':r=l;break;
      case'param':{
        const i=params.findIndex(p=>nameEq(p,l.name));
        r=i>=0?values[i]!:l;
        break;
      }
      case'succ':r=levelSucc(done.get(l.of as object)!);break;
      case'max':r=mkMax(done.get(l.left as object)!,done.get(l.right as object)!);break;
      case'imax':r=mkIMax(done.get(l.left as object)!,done.get(l.right as object)!);break;
    }
    done.set(l as object,r);
  }
  return done.get(root as object)!;
}

const levelKindRank:Record<Level['kind'],number>={zero:0,succ:1,max:2,imax:3,param:4,mvar:5};

function isExplicitLevel(l:Level):boolean{
  let x=l;
  while(x.kind==='succ')x=x.of;
  return x.kind==='zero';
}

/** Flatten only syntactic max nodes, preserving Lean's left-to-right order. */
function pushMaxArgs(root:Level,out:Level[]):void{
  const todo:Level[]=[root];
  while(todo.length){
    const l=todo.pop()!;
    if(l.kind==='max')todo.push(l.right,l.left);
    else out.push(l);
  }
}

/** Final Lean 4.34 C++ `is_norm_lt`, expressed iteratively for stack safety. */
function normCmp(a:Level,b:Level):number{
  const todo:[Level,Level][]=[[a,b]];
  while(todo.length){
    const [x,y]=todo.pop()!;
    if(levelEqStructural(x,y))continue;
    const px=toOffset(x),py=toOffset(y),bx=px.base,by=py.base;
    if(levelEqStructural(bx,by)){
      if(px.offset<py.offset)return -1;
      if(px.offset>py.offset)return 1;
      continue;
    }
    const kx=levelKindRank[bx.kind],ky=levelKindRank[by.kind];
    if(kx!==ky)return kx<ky?-1:1;
    switch(bx.kind){
      case'param':
        if(by.kind!=='param')return kx<ky?-1:1;
        return nameCmp(bx.name,by.name);
      case'mvar':
        if(by.kind!=='mvar')return kx<ky?-1:1;
        return nameCmp(bx.name,by.name);
      case'max':
        if(by.kind!=='max')return kx<ky?-1:1;
        if(!levelEqStructural(bx.left,by.left)){todo.push([bx.left,by.left]);continue;}
        todo.push([bx.right,by.right]);continue;
      case'imax':
        if(by.kind!=='imax')return kx<ky?-1:1;
        if(!levelEqStructural(bx.left,by.left)){todo.push([bx.left,by.left]);continue;}
        todo.push([bx.right,by.right]);continue;
      case'zero':
      case'succ':
        // `toOffset` removes Succ, and unequal Zero bases are impossible.
        continue;
    }
  }
  return 0;
}

function normalizeLevelWithMemo(root:Level,memo:WeakMap<object,Level>):Level{
  const cached=memo.get(root as object);if(cached!==undefined)return cached;
  type Task={l:Level;done:boolean;leaves?:Level[]};
  const todo:Task[]=[{l:root,done:false}];
  while(todo.length){
    const task=todo.pop()!,l=task.l;
    if(memo.has(l as object))continue;
    const p=toOffset(l),base=p.base;
    if(base.kind==='zero'||base.kind==='param'||base.kind==='mvar'){
      // This is exactly the C++ fast path: zero/param/mvar with any outer Succ
      // offset is already normalized and is returned unchanged.
      memo.set(l as object,l);
      continue;
    }
    if(!task.done){
      if(base.kind==='imax'){
        todo.push({l,done:true});
        todo.push({l:base.right,done:false},{l:base.left,done:false});
      }else if(base.kind==='max'){
        const leaves:Level[]=[];pushMaxArgs(base,leaves);
        todo.push({l,done:true,leaves});
        for(let i=leaves.length-1;i>=0;i--)todo.push({l:leaves[i]!,done:false});
      }
      continue;
    }
    if(base.kind==='imax'){
      const lhs=memo.get(base.left as object)!,rhs=memo.get(base.right as object)!;
      // Deliberately do not re-normalize if mkIMax turns into a max. Final
      // Lean 4.34 does the same, and this incompleteness is observable.
      memo.set(l as object,addOffset(mkIMax(lhs,rhs),p.offset));
      continue;
    }

    const args:Level[]=[];
    for(const leaf of task.leaves!){
      const n=memo.get(leaf as object)!;
      pushMaxArgs(n,args);
    }
    args.sort(normCmp);

    let i=0;
    if(isExplicitLevel(args[i]!)){
      while(i+1<args.length&&isExplicitLevel(args[i+1]!))i++;
      const k=toOffset(args[i]!).offset;
      let j=i+1;
      while(j<args.length&&toOffset(args[j]!).offset<k)j++;
      if(j<args.length)i++;
    }

    const rargs:Level[]=[args[i]!];
    let prev=toOffset(args[i]!);
    i++;
    for(;i<args.length;i++){
      const curr=toOffset(args[i]!);
      if(levelEqStructural(prev.base,curr.base)){
        if(prev.offset<curr.offset){
          prev=curr;
          rargs.pop();
          rargs.push(args[i]!);
        }
      }else{
        prev=curr;
        rargs.push(args[i]!);
      }
    }

    const shifted=rargs.map(a=>addOffset(a,p.offset));
    let r=shifted[shifted.length-1]!;
    for(let j=shifted.length-2;j>=0;j--)r=mkMax(shifted[j]!,r);
    memo.set(l as object,r);
  }
  return memo.get(root as object)!;
}

/** Exact final Lean 4.34 C++ kernel level normalizer, kept iterative for deep levels. */
export function normalizeLevel(l:Level):Level{
  return normalizeLevelWithMemo(l,new WeakMap<object,Level>());
}

type GeqFrame={
  a:Level;
  b:Level;
  state:0|1|2;
  op?:'and'|'or'|'single';
  secondA?:Level;
  secondB?:Level;
};

/** Final Lean 4.34 `is_geq`: normalize first, then use the kernel's incomplete search. */
function kernelGeq(a:Level,b:Level):boolean{
  const memo=new WeakMap<object,Level>();
  const norm=(l:Level)=>normalizeLevelWithMemo(l,memo);
  const stack:GeqFrame[]=[{a:norm(a),b:norm(b),state:0}];
  let last=false;
  while(stack.length){
    const f=stack[stack.length-1]!;
    if(f.state===0){
      const l1=f.a,l2=f.b;
      if(levelEqStructural(l1,l2)||isZero(l2)){last=true;stack.pop();continue;}
      if(l2.kind==='max'){
        f.state=1;f.op='and';f.secondA=l1;f.secondB=norm(l2.right);
        stack.push({a:l1,b:norm(l2.left),state:0});continue;
      }
      if(l1.kind==='max'){
        f.state=1;f.op='or';f.secondA=norm(l1.right);f.secondB=l2;
        stack.push({a:norm(l1.left),b:l2,state:0});continue;
      }
      if(l2.kind==='imax'){
        f.state=1;f.op='and';f.secondA=l1;f.secondB=norm(l2.right);
        stack.push({a:l1,b:norm(l2.left),state:0});continue;
      }
      if(l1.kind==='imax'){
        f.state=1;f.op='single';
        stack.push({a:norm(l1.right),b:l2,state:0});continue;
      }
      const p1=toOffset(l1),p2=toOffset(l2);
      if(levelEqStructural(p1.base,p2.base)||isZero(p2.base)){
        last=p1.offset>=p2.offset;stack.pop();continue;
      }
      if(p1.offset===p2.offset&&p1.offset>0n){
        f.state=1;f.op='single';
        stack.push({a:norm(p1.base),b:norm(p2.base),state:0});continue;
      }
      last=false;stack.pop();continue;
    }
    if(f.state===1){
      if(f.op==='single'){stack.pop();continue;}
      if(f.op==='and'&&!last){last=false;stack.pop();continue;}
      if(f.op==='or'&&last){last=true;stack.pop();continue;}
      f.state=2;
      stack.push({a:f.secondA!,b:f.secondB!,state:0});
      continue;
    }
    stack.pop();
  }
  return last;
}

/** Lean kernel `a ≤ b`, implemented as final-4.34 `is_geq(b, a)`. */
export function levelLe(a:Level,b:Level):boolean{return kernelGeq(b,a);}

/**
 * Final Lean 4.34 `is_equivalent`.
 *
 * Keep the kernel's intentional incompleteness: do not fall back to the
 * stronger Lean4Lean complete decision procedure, because doing so accepts
 * universe equalities that the target C++ kernel rejects.
 */
export function levelEquivalent(a:Level,b:Level):boolean{
  if(levelEqStructural(a,b))return true;
  const memo=new WeakMap<object,Level>();
  return levelEqStructural(normalizeLevelWithMemo(a,memo),normalizeLevelWithMemo(b,memo));
}

export function levelToString(l: Level): string {
  switch (l.kind) {
    case 'zero': return '0'; case 'succ': return `(${levelToString(l.of)}+1)`;
    case 'max': return `max ${levelToString(l.left)} ${levelToString(l.right)}`;
    case 'imax': return `imax ${levelToString(l.left)} ${levelToString(l.right)}`;
    case 'param': return nameToString(l.name); case 'mvar': return `?${nameToString(l.name)}`;
  }
}
