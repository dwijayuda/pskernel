export type Name =
  | { readonly kind: 'anonymous' }
  | { readonly kind: 'str'; readonly prefix: Name; readonly value: string }
  | { readonly kind: 'num'; readonly prefix: Name; readonly value: bigint };

export const anonymous: Name = Object.freeze({ kind: 'anonymous' });
export const strName = (prefix: Name, value: string): Name => Object.freeze({ kind: 'str', prefix, value });
export const numName = (prefix: Name, value: bigint | number): Name => Object.freeze({ kind: 'num', prefix, value: BigInt(value) });

export function nameFromDotted(s: string): Name {
  if (s === '' || s === '_') return anonymous;
  return s.split('.').filter(Boolean).reduce<Name>((p, x) => strName(p, x), anonymous);
}


/** Lean `Name.appendAfter`: append text to the final string component, or add one if needed. */
export function nameAppendAfter(n: Name, suffix: string): Name {
  return n.kind==='str' ? strName(n.prefix,n.value+suffix) : strName(n,suffix);
}

/** Lean `Name.appendIndexAfter`: append `_<idx>` to the final string component. */
export function nameAppendIndexAfter(n: Name, idx: bigint | number): Name {
  return nameAppendAfter(n,`_${BigInt(idx)}`);
}

/** Lean `Name.replacePrefix`: replace an ancestor prefix while preserving structural string/number suffix components. */
type NameComponent={readonly k:0|1;readonly v:string|bigint};

function components(n:Name,out:NameComponent[]=[]):NameComponent[]{
  const rev:NameComponent[]=[];
  let x=n;
  while(x.kind!=='anonymous'){
    rev.push(x.kind==='str'?{k:0,v:x.value}:{k:1,v:x.value});
    x=x.prefix;
  }
  for(let i=rev.length-1;i>=0;i--)out.push(rev[i]!);
  return out;
}

export function nameReplacePrefix(n: Name, prefix: Name, replacement: Name = anonymous): Name | null {
  const ns=components(n),ps=components(prefix);
  if(ps.length>ns.length)return null;
  for(let i=0;i<ps.length;i++){
    const a=ns[i]!,b=ps[i]!;
    if(a.k!==b.k||a.v!==b.v)return null;
  }
  let r=replacement;
  for(let i=ps.length;i<ns.length;i++){
    const c=ns[i]!;
    r=c.k===0?strName(r,c.v as string):numName(r,c.v as bigint);
  }
  return r;
}

export function nameEq(a: Name, b: Name): boolean {
  let x=a,y=b;
  while(true){
    if(x===y)return true;
    if(x.kind!==y.kind)return false;
    if(x.kind==='anonymous')return true;
    if(x.kind==='str'){
      if(y.kind!=='str'||x.value!==y.value)return false;
      x=x.prefix;y=y.prefix;continue;
    }
    if(y.kind!=='num'||x.value!==y.value)return false;
    x=x.prefix;y=y.prefix;
  }
}

export function nameKey(n: Name): string {
  const parts:string[]=['a'];
  for(const c of components(n))
    parts.push(c.k===0?`/s:${(c.v as string).length}:${c.v as string}`:`/n:${c.v as bigint}`);
  return parts.join('');
}

function leanStringCmp(a:string,b:string):-1|0|1{
  const ai=a[Symbol.iterator](),bi=b[Symbol.iterator]();
  while(true){
    const x=ai.next(),y=bi.next();
    if(x.done||y.done){
      if(x.done&&y.done)return 0;
      return x.done?-1:1;
    }
    const xc=x.value.codePointAt(0)!,yc=y.value.codePointAt(0)!;
    if(xc!==yc)return xc<yc?-1:1;
  }
}

/** Final Lean C++ Name order: NUMERAL components precede STRING components,
 * and strings use UTF-8 byte order (equivalent to scalar-value order for valid strings). */
export function nameCmp(a: Name, b: Name): -1 | 0 | 1 {
  if (nameEq(a, b)) return 0;
  const as = components(a), bs = components(b);
  const n = Math.min(as.length, bs.length);
  for (let i = 0; i < n; i++) {
    const x = as[i]!, y = bs[i]!;
    if (x.k !== y.k) return x.k < y.k ? 1 : -1; // Lean: NUMERAL components sort before STRING components
    if (typeof x.v === 'string' && typeof y.v === 'string') {
      const c=leanStringCmp(x.v,y.v);if(c!==0)return c;
    } else if (typeof x.v === 'bigint' && typeof y.v === 'bigint' && x.v !== y.v) {
      return x.v < y.v ? -1 : 1;
    }
  }
  return as.length < bs.length ? -1 : 1;
}

export function nameToString(n: Name): string {
  const xs = components(n);
  if (xs.length === 0) return '_';
  return xs.map(x => x.k === 0 ? String(x.v) : String(x.v)).join('.');
}
