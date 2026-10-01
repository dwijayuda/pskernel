/** JSON value with integral number tokens preserved exactly as bigint. */
export type ExactJson = null | boolean | string | bigint | number | ExactJson[] | { readonly [key:string]: ExactJson };

export class ExactJsonError extends Error { constructor(message:string){super(message);this.name='ExactJsonError';} }

export function parseExactJson(text:string):ExactJson{
 let i=0;
 const ws=()=>{while(i<text.length&&/\s/.test(text[i]!))i++;};
 const fail=(m:string):never=>{throw new ExactJsonError(`${m} at offset ${i}`);};
 const string=():string=>{
   const start=i;if(text[i]!==`"`)fail('expected string');i++;let esc=false;
   while(i<text.length){const c=text[i++]!;if(esc){esc=false;continue;}if(c==='\\'){esc=true;continue;}if(c==='"'){const tok=text.slice(start,i);try{return JSON.parse(tok) as string;}catch{return fail('invalid JSON string');}}}
   return fail('unterminated string');
 };
 const number=():bigint|number=>{
   const start=i;if(text[i]==='-')i++;
   if(text[i]==='0')i++;else{if(!/[1-9]/.test(text[i]??''))fail('invalid number');while(/[0-9]/.test(text[i]??''))i++;}
   let integral=true;if(text[i]==='.'){integral=false;i++;if(!/[0-9]/.test(text[i]??''))fail('invalid fraction');while(/[0-9]/.test(text[i]??''))i++;}
   if(text[i]==='e'||text[i]==='E'){integral=false;i++;if(text[i]==='+'||text[i]==='-')i++;if(!/[0-9]/.test(text[i]??''))fail('invalid exponent');while(/[0-9]/.test(text[i]??''))i++;}
   const tok=text.slice(start,i);if(integral)return BigInt(tok);const n=Number(tok);if(!Number.isFinite(n))fail('non-finite JSON number');return n;
 };
 const value=():ExactJson=>{ws();const c=text[i];if(c==='"')return string();if(c==='-'||/[0-9]/.test(c??''))return number();
   if(text.startsWith('true',i)){i+=4;return true;}if(text.startsWith('false',i)){i+=5;return false;}if(text.startsWith('null',i)){i+=4;return null;}
   if(c==='['){i++;const a:ExactJson[]=[];ws();if(text[i]===']'){i++;return a;}while(true){a.push(value());ws();if(text[i]===']'){i++;return a;}if(text[i]!==',')fail("expected ',' or ']'");i++;}}
   if(c==='{'){i++;const o:{[k:string]:ExactJson}={};ws();if(text[i]==='}'){i++;return o;}while(true){ws();const k=string();ws();if(text[i]!==':')fail("expected ':'");i++;if(Object.prototype.hasOwnProperty.call(o,k))fail(`duplicate key ${k}`);o[k]=value();ws();if(text[i]==='}'){i++;return o;}if(text[i]!==',')fail("expected ',' or '}'");i++;}}
   return fail('unexpected token');
 };
 const out=value();ws();if(i!==text.length)fail('trailing input');return out;
}

export type JObject={readonly [key:string]:ExactJson};
export function asObject(v:ExactJson,where='value'):JObject{if(v===null||Array.isArray(v)||typeof v!=='object')throw new ExactJsonError(`${where} must be an object`);return v as JObject;}
export function asArray(v:ExactJson,where='value'):readonly ExactJson[]{if(!Array.isArray(v))throw new ExactJsonError(`${where} must be an array`);return v;}
export function asString(v:ExactJson,where='value'):string{if(typeof v!=='string')throw new ExactJsonError(`${where} must be a string`);return v;}
export function asBoolean(v:ExactJson,where='value'):boolean{if(typeof v!=='boolean')throw new ExactJsonError(`${where} must be a boolean`);return v;}
export function asBigInt(v:ExactJson,where='value'):bigint{if(typeof v!=='bigint')throw new ExactJsonError(`${where} must be an integer`);return v;}
export function asIndex(v:ExactJson,where='index'):number{const n=asBigInt(v,where);if(n<0n||n>BigInt(Number.MAX_SAFE_INTEGER))throw new ExactJsonError(`${where} is outside safe table-index range`);return Number(n);}
export function field(o:JObject,k:string,where='object'):ExactJson{if(!Object.prototype.hasOwnProperty.call(o,k))throw new ExactJsonError(`${where}.${k} is missing`);return o[k]!;}
export function maybeField(o:JObject,k:string):ExactJson|undefined{return Object.prototype.hasOwnProperty.call(o,k)?o[k]:undefined;}
