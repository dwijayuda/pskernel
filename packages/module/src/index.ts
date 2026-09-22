import {createHash} from 'node:crypto';
import {Buffer} from 'node:buffer';
import {Environment} from 'lean-ts-kernel';
import {Lean4ExportReplay, type ReplayStats} from 'lean-ts-kernel/lean4export';

export type Sha256 = `sha256:${string}`;
export type JsonPrimitive = string | number | boolean | null;
export type JsonValue = JsonPrimitive | readonly JsonValue[] | {[key:string]: JsonValue};

export interface KernelCompatibility {
  readonly semantics:'lean4';
  readonly leanVersion:string;
  readonly apiVersion:string;
}
export interface ModuleDependency { readonly module:string; readonly integrity:Sha256 }
export interface Lean4ExportPayload {
  readonly kind:'lean4export-ndjson';
  readonly formatVersion:'3.1.0';
  readonly integrity:Sha256;
  readonly text:string;
}
export interface ModuleArtifact {
  readonly format:'proofscript-module';
  readonly version:1;
  readonly module:string;
  readonly kernel:KernelCompatibility;
  readonly dependencies:readonly ModuleDependency[];
  readonly payload:Lean4ExportPayload;
  readonly metadata?:JsonValue;
  readonly integrity:Sha256;
}
export interface CreateModuleArtifactOptions {
  readonly module:string;
  readonly declarations:string;
  readonly dependencies?:readonly ModuleDependency[];
  readonly kernel?:KernelCompatibility;
  readonly metadata?:JsonValue;
}
export interface LoadModuleArtifactOptions {
  readonly env?:Environment;
  readonly dependencyIntegrities?:ReadonlyMap<string,string>;
}
export interface LoadModuleArtifactResult {
  readonly env:Environment;
  readonly stats:ReplayStats;
  readonly module:string;
  readonly integrity:Sha256;
}
export interface ModuleArtifactSummary {
  readonly format:string;
  readonly module:string;
  readonly kernel:KernelCompatibility;
  readonly dependencies:number;
  readonly payloadKind:string;
  readonly payloadBytes:number;
  readonly payloadIntegrity:Sha256;
  readonly integrity:Sha256;
}

export const MODULE_FORMAT='proofscript-module' as const;
export const MODULE_FORMAT_VERSION=1 as const;
export const DEFAULT_KERNEL:KernelCompatibility={semantics:'lean4',leanVersion:'4.34.0',apiVersion:'0.1.0'};

function fail(message:string):never { throw new Error(`@proofscript/module: ${message}`); }
function isObject(x:unknown):x is Record<string,unknown> { return typeof x==='object'&&x!==null&&!Array.isArray(x); }
function isHex256(x:unknown):x is Sha256 { return typeof x==='string'&&/^sha256:[0-9a-f]{64}$/.test(x); }
function sha256(text:string):Sha256 { return `sha256:${createHash('sha256').update(text,'utf8').digest('hex')}`; }

export function canonicalJson(value:unknown):string {
  const seen=new Set<object>();
  const go=(x:unknown,path:string):string=>{
    if(x===null||typeof x==='string'||typeof x==='boolean')return JSON.stringify(x);
    if(typeof x==='number'){
      if(!Number.isFinite(x))fail(`non-finite number at ${path}`);
      return Object.is(x,-0)?'0':JSON.stringify(x);
    }
    if(typeof x==='bigint')fail(`bigint is not valid module JSON at ${path}`);
    if(Array.isArray(x)){
      if(seen.has(x))fail(`cycle at ${path}`);
      seen.add(x);
      const out='['+x.map((v,i)=>go(v,`${path}[${i}]`)).join(',')+']';
      seen.delete(x);
      return out;
    }
    if(isObject(x)){
      if(seen.has(x))fail(`cycle at ${path}`);
      seen.add(x);
      const keys=Object.keys(x).filter(k=>x[k]!==undefined).sort();
      const out='{'+keys.map(k=>JSON.stringify(k)+':'+go(x[k],`${path}.${k}`)).join(',')+'}';
      seen.delete(x);
      return out;
    }
    fail(`unsupported value at ${path}`);
  };
  return go(value,'$');
}

export function normalizeDeclarationStream(text:string):string {
  const normalized=text.replace(/\r\n?/g,'\n').replace(/[\t ]+$/gm,'').replace(/\n+$/,'');
  return normalized.length===0?'':normalized+'\n';
}

function normalizeDependencies(dependencies:readonly ModuleDependency[]=[]):ModuleDependency[] {
  const seen=new Set<string>();
  const out=dependencies.map((d,i)=>{
    if(typeof d.module!=='string'||d.module.length===0||!isHex256(d.integrity))fail(`invalid dependency at index ${i}`);
    if(seen.has(d.module))fail(`duplicate dependency '${d.module}'`);
    seen.add(d.module);
    return {module:d.module,integrity:d.integrity};
  });
  out.sort((a,b)=>a.module.localeCompare(b.module)||a.integrity.localeCompare(b.integrity));
  return out;
}

function bodyForIntegrity(artifact:ModuleArtifact):Omit<ModuleArtifact,'integrity'> {
  const {integrity:_ignored,...body}=artifact;
  return body;
}

export function createModuleArtifact({module,declarations,dependencies=[],kernel=DEFAULT_KERNEL,metadata}:CreateModuleArtifactOptions):ModuleArtifact {
  if(module.length===0)fail('module name must be a non-empty string');
  if(kernel.semantics!=='lean4'||kernel.leanVersion.length===0||kernel.apiVersion.length===0)fail('invalid kernel compatibility descriptor');
  const text=normalizeDeclarationStream(declarations);
  const payload:Lean4ExportPayload={kind:'lean4export-ndjson',formatVersion:'3.1.0',integrity:sha256(text),text};
  const body:Omit<ModuleArtifact,'integrity'>={
    format:MODULE_FORMAT,
    version:MODULE_FORMAT_VERSION,
    module,
    kernel:{...kernel},
    dependencies:normalizeDependencies(dependencies),
    payload,
    ...(metadata===undefined?{}:{metadata})
  };
  return {...body,integrity:sha256(canonicalJson(body))};
}

export function encodeModuleArtifact(artifact:unknown):string {
  if(!verifyModuleArtifact(artifact))fail('invalid module artifact');
  return canonicalJson(artifact)+'\n';
}

export function decodeModuleArtifact(text:string):ModuleArtifact {
  let value:unknown;
  try{value=JSON.parse(text);}catch(e){fail(`invalid JSON: ${e instanceof Error?e.message:String(e)}`);}
  if(!verifyModuleArtifact(value))fail('invalid module artifact');
  return value;
}

export function verifyModuleArtifact(value:unknown):value is ModuleArtifact {
  if(!isObject(value))fail('artifact must be an object');
  if(value.format!==MODULE_FORMAT||value.version!==MODULE_FORMAT_VERSION)fail(`unsupported artifact format/version ${String(value.format)}@${String(value.version)}`);
  if(typeof value.module!=='string'||value.module.length===0)fail('invalid module name');
  if(!isObject(value.kernel)||value.kernel.semantics!=='lean4'||typeof value.kernel.leanVersion!=='string'||typeof value.kernel.apiVersion!=='string')fail('invalid kernel compatibility descriptor');
  if(!Array.isArray(value.dependencies))fail('dependencies must be an array');
  const deps=normalizeDependencies(value.dependencies.map((d,i)=>{
    if(!isObject(d)||typeof d.module!=='string'||!isHex256(d.integrity))fail(`invalid dependency at index ${i}`);
    return {module:d.module,integrity:d.integrity};
  }));
  if(canonicalJson(deps)!==canonicalJson(value.dependencies))fail('dependencies are not in canonical order');
  if(!isObject(value.payload)||value.payload.kind!=='lean4export-ndjson'||value.payload.formatVersion!=='3.1.0'||typeof value.payload.text!=='string'||!isHex256(value.payload.integrity))fail('unsupported module payload');
  const normalized=normalizeDeclarationStream(value.payload.text);
  if(normalized!==value.payload.text)fail('declaration stream is not canonical');
  if(value.payload.integrity!==sha256(value.payload.text))fail('declaration payload integrity mismatch');
  if(!isHex256(value.integrity))fail('invalid module integrity');
  const artifact=value as unknown as ModuleArtifact;
  if(artifact.integrity!==sha256(canonicalJson(bodyForIntegrity(artifact))))fail('module integrity mismatch');
  if('metadata' in value)canonicalJson(value.metadata);
  return true;
}

export function verifyModuleDependencies(artifact:unknown,available:ReadonlyMap<string,string>):true {
  if(!verifyModuleArtifact(artifact))fail('invalid module artifact');
  for(const dep of artifact.dependencies){
    const got=available.get(dep.module);
    if(got===undefined)fail(`missing dependency '${dep.module}'`);
    if(got!==dep.integrity)fail(`dependency integrity mismatch for '${dep.module}'`);
  }
  return true;
}

export function loadModuleArtifact(artifact:unknown,{env=new Environment(),dependencyIntegrities=new Map<string,string>()}:LoadModuleArtifactOptions={}):LoadModuleArtifactResult {
  if(!verifyModuleArtifact(artifact))fail('invalid module artifact');
  verifyModuleDependencies(artifact,dependencyIntegrities);
  const replay=new Lean4ExportReplay(env,{expectedLeanVersion:artifact.kernel.leanVersion});
  const stats=replay.replay(artifact.payload.text);
  return {env:replay.env,stats,module:artifact.module,integrity:artifact.integrity};
}

export function moduleArtifactSummary(artifact:unknown):ModuleArtifactSummary {
  if(!verifyModuleArtifact(artifact))fail('invalid module artifact');
  return {
    format:`${artifact.format}@${artifact.version}`,
    module:artifact.module,
    kernel:artifact.kernel,
    dependencies:artifact.dependencies.length,
    payloadKind:artifact.payload.kind,
    payloadBytes:Buffer.byteLength(artifact.payload.text,'utf8'),
    payloadIntegrity:artifact.payload.integrity,
    integrity:artifact.integrity
  };
}
