import * as generated from './runtime/kernel.js';
import {createRegularCoreIngress,regularIngressLimits} from './host/ingress.mjs';
import build from './metadata.mjs';

const check=createRegularCoreIngress(generated);
export const metadata=Object.freeze({...build,limits:regularIngressLimits});
/** Exact genuine Uint8Array input; Buffer, proxies, subclasses and shared storage refuse. */
export function checkBytes(bytes){
 const result=check(bytes);
 return Object.freeze({schema:'pskernel-min/check/1',profile:'psc1-min-core-regular/1',
  accepted:result.accepted,code:result.code,delegated:false,
  ...(result.accepted?{byteLength:result.byteLength,declarationCount:result.declarationCount}:{})});
}
