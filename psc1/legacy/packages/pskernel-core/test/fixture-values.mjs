import fs from 'node:fs';
export const cases = JSON.parse(fs.readFileSync(new URL('./cases.json', import.meta.url), 'utf8'));
export function naturalBits(text) {
  if (!/^(0|[1-9][0-9]*)$/.test(text)) throw Error('noncanonical fixture numeral');
  return BigInt(text).toString(2);
}
export function runtimeNatural(k, text) {
  const bits = naturalBits(text);
  if (bits === '0') return k.PsKernelNatural.zero;
  let p = k.PsKernelPositive.one;
  for (const bit of bits.slice(1)) p = bit === '0' ? k.PsKernelPositive.bit0(p) : k.PsKernelPositive.bit1(p);
  return k.PsKernelNatural.positive(p);
}
export function runtimeText(k, text) {
  let out = k.PsKernelText.empty;
  const bytes = new TextEncoder().encode(text);
  for (let i=bytes.length-1;i>=0;i--) out=k.PsKernelText.byte(runtimeNatural(k,String(bytes[i])),out);
  return out;
}
export function runtimeName(k, x) {
  switch (x[0]) {
    case 'anonymous': return k.PsKernelName.anonymous;
    case 'str': return k.PsKernelName.str(runtimeName(k,x[1]),runtimeText(k,x[2]));
    case 'num': return k.PsKernelName.num(runtimeName(k,x[1]),runtimeNatural(k,x[2]));
    default: throw Error('unknown fixture name');
  }
}
export function runtimeLevel(k,x) {
  switch (x[0]) {
    case 'zero': return k.PsKernelLevel.zero;
    case 'succ': return k.PsKernelLevel.succ(runtimeLevel(k,x[1]));
    case 'max': return k.PsKernelLevel.max(runtimeLevel(k,x[1]),runtimeLevel(k,x[2]));
    case 'imax': return k.PsKernelLevel.imax(runtimeLevel(k,x[1]),runtimeLevel(k,x[2]));
    case 'param': return k.PsKernelLevel.param(runtimeName(k,x[1]));
    default: throw Error('unknown fixture level');
  }
}
export function runtimeFuel(k,count) {
  if (!Number.isSafeInteger(count) || count<0 || count>2048) throw Error('invalid test budget');
  let f=k.PsKernelFuel.stop; for(let i=0;i<count;i++) f=k.PsKernelFuel.more(f); return f;
}
export function runCase(k, c) {
  const convert = c.kind === 'name' ? runtimeName : c.kind === 'level' ? runtimeLevel : runtimeNatural;
  const task=k.PsKernelCompareTask[c.kind](convert(k,c.left),convert(k,c.right));
  return k.psKernelCompareTasks(runtimeFuel(k,c.fuel),k.PsKernelList.cons(task,k.PsKernelList.nil()));
}
