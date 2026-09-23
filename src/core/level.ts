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

type LevelAtom = { readonly kind:'param'|'mvar'; readonly name:Name };
interface VarNode { readonly atom: LevelAtom; readonly offset: bigint }
interface Node { readonly constant: bigint; readonly vars: readonly VarNode[] }
interface Entry { readonly path: readonly LevelAtom[]; readonly node: Node }
type Norm = Entry[];
const emptyNode = (): Node => ({ constant: 0n, vars: [] });
const atomEq=(a:LevelAtom,b:LevelAtom)=>a.kind===b.kind&&nameEq(a.name,b.name);
const atomCmp=(a:LevelAtom,b:LevelAtom):number=>a.kind===b.kind?nameCmp(a.name,b.name):(a.kind==='param'?-1:1);
const atomKey=(a:LevelAtom)=>`${a.kind}:${nameKey(a.name)}`;
const pathEq = (a: readonly LevelAtom[], b: readonly LevelAtom[]) => a.length === b.length && a.every((x, i) => atomEq(x, b[i]!));
const pathKey = (p: readonly LevelAtom[]) => p.map(atomKey).join('|');
function subset(a: readonly LevelAtom[], b: readonly LevelAtom[]): boolean {
  let i = 0, j = 0;
  while (i < a.length) {
    if (j >= b.length) return false;
    const c = atomCmp(a[i]!, b[j]!);
    if (c < 0) return false;
    if (c === 0) i++;
    j++;
  }
  return true;
}
function orderedInsert(a: LevelAtom, xs: readonly LevelAtom[]): readonly LevelAtom[] | null {
  const out: LevelAtom[] = [];
  let inserted = false;
  for (const x of xs) {
    const c = atomCmp(a, x);
    if (c === 0) return null;
    if (!inserted && c < 0) { out.push(a); inserted = true; }
    out.push(x);
  }
  if (!inserted) out.push(a);
  return out;
}
function addVarTo(vars: readonly VarNode[], atom: LevelAtom, offset: bigint): readonly VarNode[] {
  const out: VarNode[] = []; let done = false;
  for (const v of vars) {
    const c = atomCmp(atom, v.atom);
    if (!done && c < 0) { out.push({ atom, offset }); done = true; }
    if (c === 0) { out.push({ atom, offset: offset > v.offset ? offset : v.offset }); done = true; }
    else out.push(v);
  }
  if (!done) out.push({ atom, offset });
  return out;
}
function alter(norm: Norm, path: readonly LevelAtom[], f: (n: Node | undefined) => Node | undefined): Norm {
  const k = pathKey(path); const out: Norm = []; let found = false;
  for (const e of norm) {
    if (pathKey(e.path) === k && pathEq(e.path, path)) { found = true; const n = f(e.node); if (n) out.push({ path, node: n }); }
    else out.push(e);
  }
  if (!found) { const n = f(undefined); if (n) out.push({ path, node: n }); }
  return out;
}
function addConst(norm: Norm, k: bigint, path: readonly LevelAtom[]): Norm {
  if (k === 0n || (k === 1n && path.length > 0)) return norm;
  return alter(norm, path, n => ({ constant: n ? (n.constant > k ? n.constant : k) : k, vars: n?.vars ?? [] }));
}
function addVar(norm: Norm, v: LevelAtom, k: bigint, path: readonly LevelAtom[]): Norm {
  return alter(norm, path, n => ({ constant: n?.constant ?? 0n, vars: addVarTo(n?.vars ?? [], v, k) }));
}
function addNode(norm: Norm, v: LevelAtom, k: bigint, path: readonly LevelAtom[]): Norm { return addVar(norm, v, k, path); }
function normalizeAux(root: Level, rootPath: readonly LevelAtom[], rootK: bigint, acc: Norm): Norm {
  type Task={l:Level;path:readonly LevelAtom[];k:bigint};
  const todo:Task[]=[{l:root,path:rootPath,k:rootK}];
  let out=acc;
  while(todo.length){
    let {l,path,k}=todo.pop()!;
    while(l.kind==='succ'){k++;l=l.of;}
    switch(l.kind){
      case'zero':
        out=addConst(out,k,path);
        break;
      case'max':
        // Recursive order is left then right because normalization updates the accumulator.
        todo.push({l:l.right,path,k},{l:l.left,path,k});
        break;
      case'imax':{
        const r=l.right;
        if(r.kind==='zero'){
          out=addConst(out,k,path);
        }else if(r.kind==='succ'){
          todo.push({l:r.of,path,k:k+1n},{l:l.left,path,k});
        }else if(r.kind==='max'){
          todo.push(
            {l:mkIMax(l.left,r.right),path,k},
            {l:mkIMax(l.left,r.left),path,k},
          );
        }else if(r.kind==='imax'){
          todo.push(
            {l:mkIMax(r.left,r.right),path,k},
            {l:mkIMax(l.left,r.right),path,k},
          );
        }else{
          const v:LevelAtom={kind:r.kind,name:r.name};
          const path2=orderedInsert(v,path);
          if(path2){
            out=addNode(addConst(out,k,path),v,k,path2);
            todo.push({l:l.left,path:path2,k});
          }else{
            if(k!==0n)out=addVar(out,v,k,path);
            todo.push({l:l.left,path,k});
          }
        }
        break;
      }
      case'mvar':
      case'param':{
        const v:LevelAtom={kind:l.kind,name:l.name};
        const path2=orderedInsert(v,path);
        if(path2)out=addNode(addConst(out,k,path),v,k,path2);
        else if(k!==0n)out=addVar(out,v,k,path);
        break;
      }
    }
  }
  return out;
}
function subsumeVars(a: readonly VarNode[], b: readonly VarNode[]): readonly VarNode[] {
  const out: VarNode[] = []; let j = 0;
  for (const x of a) {
    while (j < b.length && atomCmp(b[j]!.atom, x.atom) < 0) j++;
    if (j < b.length && atomEq(x.atom, b[j]!.atom) && x.offset <= b[j]!.offset) continue;
    out.push(x);
  }
  return out;
}
function subsumeBy(a: Node, b: Node, same: boolean): Node {
  let constant = a.constant;
  const maxVar = b.vars.reduce((m, x) => x.offset > m ? x.offset : m, 0n);
  if (!(constant === 0n || ((same || constant > b.constant) && (b.vars.length === 0 || constant > maxVar + 1n)))) constant = 0n;
  return { constant, vars: same || b.vars.length === 0 ? a.vars : subsumeVars(a.vars, b.vars) };
}
function nodeEmpty(n: Node): boolean { return n.constant === 0n && n.vars.length === 0; }
function subsumption(norm: Norm): Norm {
  const out: Norm = [];
  for (const e of norm) {
    let n = e.node;
    for (const d of norm) if (subset(d.path, e.path)) n = subsumeBy(n, d.node, d.path.length === e.path.length);
    if (!nodeEmpty(n)) out.push({ path: e.path, node: n });
  }
  return out;
}
export function normalizeLevel(l: Level): Norm { return subsumption(normalizeAux(l, [], 0n, [])); }
function normLe(a: Norm, b: Norm): boolean {
  return a.every(e => {
    let n = e.node;
    for (const d of b) if (subset(d.path, e.path)) { n = subsumeBy(n, d.node, false); if (nodeEmpty(n)) return true; }
    return nodeEmpty(n);
  });
}
export function levelLe(a: Level, b: Level): boolean { return normLe(normalizeLevel(a), normalizeLevel(b)); }
export function levelEquivalent(a: Level, b: Level): boolean { return levelLe(a, b) && levelLe(b, a); }
export function levelToString(l: Level): string {
  switch (l.kind) {
    case 'zero': return '0'; case 'succ': return `(${levelToString(l.of)}+1)`;
    case 'max': return `max ${levelToString(l.left)} ${levelToString(l.right)}`;
    case 'imax': return `imax ${levelToString(l.left)} ${levelToString(l.right)}`;
    case 'param': return nameToString(l.name); case 'mvar': return `?${nameToString(l.name)}`;
  }
}
