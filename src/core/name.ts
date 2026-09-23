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
export function nameReplacePrefix(n: Name, prefix: Name, replacement: Name = anonymous): Name | null {
  if (nameEq(n, prefix)) return replacement;
  if (n.kind === 'anonymous') return null;
  const p = nameReplacePrefix(n.prefix, prefix, replacement);
  if (p === null) return null;
  return n.kind === 'str' ? strName(p, n.value) : numName(p, n.value);
}

export function nameEq(a: Name, b: Name): boolean {
  if (a === b) return true;
  if (a.kind !== b.kind) return false;
  switch (a.kind) {
    case 'anonymous': return true;
    case 'str': return b.kind === 'str' && a.value === b.value && nameEq(a.prefix, b.prefix);
    case 'num': return b.kind === 'num' && a.value === b.value && nameEq(a.prefix, b.prefix);
  }
}

export function nameKey(n: Name): string {
  switch (n.kind) {
    case 'anonymous': return 'a';
    case 'str': return `${nameKey(n.prefix)}/s:${n.value.length}:${n.value}`;
    case 'num': return `${nameKey(n.prefix)}/n:${n.value}`;
  }
}

function components(n: Name, out: Array<{ k: 0 | 1; v: string | bigint }> = []): Array<{ k: 0 | 1; v: string | bigint }> {
  if (n.kind === 'anonymous') return out;
  components(n.prefix, out);
  out.push(n.kind === 'str' ? { k: 0, v: n.value } : { k: 1, v: n.value });
  return out;
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
