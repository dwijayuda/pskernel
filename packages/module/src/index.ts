import {Buffer} from 'node:buffer';
import {createHash} from 'node:crypto';
import {
  admitCheckedCoreAdmissions,
  decodeCheckedCoreAdmissions,
  encodeCheckedCoreAdmissions,
  type CheckedCoreAdmission,
} from '@proofscript/checked-core';
import {Environment} from 'lean-ts-kernel';
import {
  Lean4ExportReplay,
  type ReplayStats,
} from 'lean-ts-kernel/lean4export';

export type Sha256=`sha256:${string}`;
export type JsonPrimitive=string|number|boolean|null;
export type JsonValue=
  JsonPrimitive|readonly JsonValue[]|{[key:string]:JsonValue};

export interface KernelCompatibility {
  readonly semantics:'lean4';
  readonly leanVersion:string;
  readonly apiVersion:string;
}
export interface ModuleDependency {
  readonly module:string;
  readonly integrity:Sha256;
}
export interface Lean4ExportPayload {
  readonly kind:'lean4export-ndjson';
  readonly formatVersion:'3.1.0';
  readonly integrity:Sha256;
  readonly text:string;
}
export interface CheckedAdmissionsPayload {
  readonly kind:'proofscript-checked-admissions-json';
  readonly formatVersion:'1.0.0';
  readonly integrity:Sha256;
  readonly text:string;
}
interface ModuleArtifactBase {
  readonly format:'proofscript-module';
  readonly module:string;
  readonly kernel:KernelCompatibility;
  readonly dependencies:readonly ModuleDependency[];
  readonly metadata?:JsonValue;
  readonly integrity:Sha256;
}
export interface ModuleArtifactV1 extends ModuleArtifactBase {
  readonly version:1;
  readonly payload:Lean4ExportPayload;
}
export interface ModuleArtifactV2 extends ModuleArtifactBase {
  readonly version:2;
  readonly payload:CheckedAdmissionsPayload;
}
export type ModuleArtifact=ModuleArtifactV1|ModuleArtifactV2;

export interface CreateModuleArtifactOptions {
  readonly module:string;
  readonly declarations:string;
  readonly dependencies?:readonly ModuleDependency[];
  readonly kernel?:KernelCompatibility;
  readonly metadata?:JsonValue;
}
export interface CreateCheckedModuleArtifactOptions {
  readonly module:string;
  readonly admissions:readonly CheckedCoreAdmission[];
  readonly dependencies?:readonly ModuleDependency[];
  readonly kernel?:KernelCompatibility;
  readonly metadata?:JsonValue;
}
export interface LoadModuleArtifactOptions {
  readonly env?:Environment;
  readonly dependencyIntegrities?:ReadonlyMap<string,string>;
}
export interface Lean4ExportLoadResult {
  readonly payloadKind:'lean4export-ndjson';
  readonly env:Environment;
  readonly stats:ReplayStats;
  readonly module:string;
  readonly integrity:Sha256;
}
export interface CheckedAdmissionsLoadResult {
  readonly payloadKind:'proofscript-checked-admissions-json';
  readonly env:Environment;
  readonly admissions:number;
  readonly module:string;
  readonly integrity:Sha256;
}
export type LoadModuleArtifactResult=
  Lean4ExportLoadResult|CheckedAdmissionsLoadResult;

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
export const CHECKED_MODULE_FORMAT_VERSION=2 as const;
export const DEFAULT_KERNEL:KernelCompatibility={
  semantics:'lean4',
  leanVersion:'4.34.0',
  apiVersion:'0.1.0',
};

function fail(message:string):never {
  throw new Error('@proofscript/module: '+message);
}
function isObject(x:unknown):x is Record<string,unknown> {
  return typeof x==='object'&&x!==null&&!Array.isArray(x);
}
function isHex256(x:unknown):x is Sha256 {
  return typeof x==='string'&&/^sha256:[0-9a-f]{64}$/.test(x);
}
function sha256(text:string):Sha256 {
  return `sha256:${createHash('sha256').update(text,'utf8').digest('hex')}`;
}
function kernelValid(value:unknown):value is KernelCompatibility {
  return isObject(value)
    &&value.semantics==='lean4'
    &&typeof value.leanVersion==='string'
    &&value.leanVersion.length>0
    &&typeof value.apiVersion==='string'
    &&value.apiVersion.length>0;
}
function kernelMatchesCurrent(kernel:KernelCompatibility):boolean {
  return kernel.semantics===DEFAULT_KERNEL.semantics
    &&kernel.leanVersion===DEFAULT_KERNEL.leanVersion
    &&kernel.apiVersion===DEFAULT_KERNEL.apiVersion;
}

export function canonicalJson(value:unknown):string {
  const seen=new Set<object>();
  const go=(x:unknown,path:string):string=>{
    if(x===null||typeof x==='string'||typeof x==='boolean'){
      return JSON.stringify(x);
    }
    if(typeof x==='number'){
      if(!Number.isFinite(x))fail('non-finite number at '+path);
      return Object.is(x,-0)?'0':JSON.stringify(x);
    }
    if(typeof x==='bigint')fail('bigint is not valid module JSON at '+path);
    if(Array.isArray(x)){
      if(seen.has(x))fail('cycle at '+path);
      seen.add(x);
      const out='['+x.map((v,i)=>go(v,path+'['+i+']')).join(',')+']';
      seen.delete(x);
      return out;
    }
    if(isObject(x)){
      if(seen.has(x))fail('cycle at '+path);
      seen.add(x);
      const keys=Object.keys(x).filter((k)=>x[k]!==undefined).sort();
      const out='{'+keys.map(
        (k)=>JSON.stringify(k)+':'+go(x[k],path+'.'+k),
      ).join(',')+'}';
      seen.delete(x);
      return out;
    }
    fail('unsupported value at '+path);
  };
  return go(value,'$');
}

export function normalizeDeclarationStream(text:string):string {
  const normalized=text
    .replace(/\r\n?/g,'\n')
    .replace(/[\t ]+$/gm,'')
    .replace(/\n+$/,'');
  return normalized.length===0?'':normalized+'\n';
}
function normalizeDependencies(
  dependencies:readonly ModuleDependency[]=[],
):ModuleDependency[] {
  const seen=new Set<string>();
  const out=dependencies.map((dependency,index)=>{
    if(
      typeof dependency.module!=='string'
      ||dependency.module.length===0
      ||!isHex256(dependency.integrity)
    ){
      fail('invalid dependency at index '+index);
    }
    if(seen.has(dependency.module)){
      fail("duplicate dependency '"+dependency.module+"'");
    }
    seen.add(dependency.module);
    return {
      module:dependency.module,
      integrity:dependency.integrity,
    };
  });
  out.sort(
    (a,b)=>a.module.localeCompare(b.module)
      ||a.integrity.localeCompare(b.integrity),
  );
  return out;
}
function bodyForIntegrity(
  artifact:ModuleArtifact,
):Omit<ModuleArtifactV1,'integrity'>|Omit<ModuleArtifactV2,'integrity'> {
  const {integrity:_ignored,...body}=artifact;
  return body;
}
function commonBody(options:{
  readonly module:string;
  readonly dependencies:readonly ModuleDependency[];
  readonly kernel:KernelCompatibility;
  readonly metadata?:JsonValue;
}){
  if(options.module.length===0){
    fail('module name must be a non-empty string');
  }
  if(!kernelValid(options.kernel)){
    fail('invalid kernel compatibility descriptor');
  }
  return {
    format:MODULE_FORMAT,
    module:options.module,
    kernel:{...options.kernel},
    dependencies:normalizeDependencies(options.dependencies),
    ...(options.metadata===undefined?{}:{metadata:options.metadata}),
  } as const;
}

export function createModuleArtifact({
  module,
  declarations,
  dependencies=[],
  kernel=DEFAULT_KERNEL,
  metadata,
}:CreateModuleArtifactOptions):ModuleArtifactV1 {
  const text=normalizeDeclarationStream(declarations);
  const payload:Lean4ExportPayload={
    kind:'lean4export-ndjson',
    formatVersion:'3.1.0',
    integrity:sha256(text),
    text,
  };
  const body={
    ...commonBody({module,dependencies,kernel,metadata}),
    version:MODULE_FORMAT_VERSION,
    payload,
  } satisfies Omit<ModuleArtifactV1,'integrity'>;
  return {...body,integrity:sha256(canonicalJson(body))};
}

export function createCheckedModuleArtifact({
  module,
  admissions,
  dependencies=[],
  kernel=DEFAULT_KERNEL,
  metadata,
}:CreateCheckedModuleArtifactOptions):ModuleArtifactV2 {
  const encoded=encodeCheckedCoreAdmissions(admissions);
  const text=canonicalJson(encoded)+'\n';
  const payload:CheckedAdmissionsPayload={
    kind:'proofscript-checked-admissions-json',
    formatVersion:'1.0.0',
    integrity:sha256(text),
    text,
  };
  const body={
    ...commonBody({module,dependencies,kernel,metadata}),
    version:CHECKED_MODULE_FORMAT_VERSION,
    payload,
  } satisfies Omit<ModuleArtifactV2,'integrity'>;
  return {...body,integrity:sha256(canonicalJson(body))};
}

function parseCheckedAdmissionsPayload(
  payload:CheckedAdmissionsPayload,
):readonly CheckedCoreAdmission[] {
  let parsed:unknown;
  try{
    parsed=JSON.parse(payload.text);
  }catch(error){
    fail(
      'invalid checked admissions JSON: '+
      (error instanceof Error?error.message:String(error)),
    );
  }
  if(canonicalJson(parsed)+'\n'!==payload.text){
    fail('checked admissions payload is not canonical JSON');
  }
  try{
    return decodeCheckedCoreAdmissions(parsed);
  }catch(error){
    fail(
      'invalid checked admissions payload: '+
      (error instanceof Error?error.message:String(error)),
    );
  }
}

export function encodeModuleArtifact(artifact:unknown):string {
  if(!verifyModuleArtifact(artifact))fail('invalid module artifact');
  return canonicalJson(artifact)+'\n';
}
export function decodeModuleArtifact(text:string):ModuleArtifact {
  let value:unknown;
  try{
    value=JSON.parse(text);
  }catch(error){
    fail(
      'invalid JSON: '+
      (error instanceof Error?error.message:String(error)),
    );
  }
  if(!verifyModuleArtifact(value))fail('invalid module artifact');
  return value;
}

function verifyCommonArtifact(value:Record<string,unknown>):void {
  if(value.format!==MODULE_FORMAT||(value.version!==1&&value.version!==2)){
    fail(
      'unsupported artifact format/version '+
      String(value.format)+'@'+String(value.version),
    );
  }
  if(typeof value.module!=='string'||value.module.length===0){
    fail('invalid module name');
  }
  if(!kernelValid(value.kernel)){
    fail('invalid kernel compatibility descriptor');
  }
  if(!Array.isArray(value.dependencies))fail('dependencies must be an array');
  const deps=normalizeDependencies(
    value.dependencies.map((dependency,index)=>{
      if(
        !isObject(dependency)
        ||typeof dependency.module!=='string'
        ||!isHex256(dependency.integrity)
      ){
        fail('invalid dependency at index '+index);
      }
      return {
        module:dependency.module,
        integrity:dependency.integrity,
      };
    }),
  );
  if(canonicalJson(deps)!==canonicalJson(value.dependencies)){
    fail('dependencies are not in canonical order');
  }
  if('metadata' in value)canonicalJson(value.metadata);
  if(!isHex256(value.integrity))fail('invalid module integrity');
}

export function verifyModuleArtifact(
  value:unknown,
):value is ModuleArtifact {
  if(!isObject(value))fail('artifact must be an object');
  verifyCommonArtifact(value);
  if(!isObject(value.payload))fail('unsupported module payload');

  if(value.version===1){
    if(
      value.payload.kind!=='lean4export-ndjson'
      ||value.payload.formatVersion!=='3.1.0'
      ||typeof value.payload.text!=='string'
      ||!isHex256(value.payload.integrity)
    ){
      fail('unsupported module payload');
    }
    const normalized=normalizeDeclarationStream(value.payload.text);
    if(normalized!==value.payload.text){
      fail('declaration stream is not canonical');
    }
    if(value.payload.integrity!==sha256(value.payload.text)){
      fail('declaration payload integrity mismatch');
    }
  }else{
    if(
      value.payload.kind!=='proofscript-checked-admissions-json'
      ||value.payload.formatVersion!=='1.0.0'
      ||typeof value.payload.text!=='string'
      ||!isHex256(value.payload.integrity)
    ){
      fail('unsupported module payload');
    }
    if(value.payload.integrity!==sha256(value.payload.text)){
      fail('checked admissions payload integrity mismatch');
    }
    parseCheckedAdmissionsPayload(
      value.payload as unknown as CheckedAdmissionsPayload,
    );
  }

  const artifact=value as unknown as ModuleArtifact;
  if(
    artifact.integrity!==
    sha256(canonicalJson(bodyForIntegrity(artifact)))
  ){
    fail('module integrity mismatch');
  }
  return true;
}

export function verifyModuleDependencies(
  artifact:unknown,
  available:ReadonlyMap<string,string>,
):true {
  if(!verifyModuleArtifact(artifact))fail('invalid module artifact');
  for(const dependency of artifact.dependencies){
    const got=available.get(dependency.module);
    if(got===undefined){
      fail("missing dependency '"+dependency.module+"'");
    }
    if(got!==dependency.integrity){
      fail(
        "dependency integrity mismatch for '"+dependency.module+"'",
      );
    }
  }
  return true;
}

export function loadModuleArtifact(
  artifact:unknown,
  {
    env=new Environment(),
    dependencyIntegrities=new Map<string,string>(),
  }:LoadModuleArtifactOptions={},
):LoadModuleArtifactResult {
  if(!verifyModuleArtifact(artifact))fail('invalid module artifact');
  verifyModuleDependencies(artifact,dependencyIntegrities);

  if(artifact.version===1){
    const replay=new Lean4ExportReplay(
      env,
      {expectedLeanVersion:artifact.kernel.leanVersion},
    );
    const stats=replay.replay(artifact.payload.text);
    return {
      payloadKind:'lean4export-ndjson',
      env:replay.env,
      stats,
      module:artifact.module,
      integrity:artifact.integrity,
    };
  }

  if(!kernelMatchesCurrent(artifact.kernel)){
    fail(
      'checked admissions kernel compatibility mismatch; expected '+
      DEFAULT_KERNEL.leanVersion+'/'+DEFAULT_KERNEL.apiVersion,
    );
  }
  const admissions=parseCheckedAdmissionsPayload(artifact.payload);
  const checked=admitCheckedCoreAdmissions(env,admissions);
  return {
    payloadKind:'proofscript-checked-admissions-json',
    env:checked.environment,
    admissions:admissions.length,
    module:artifact.module,
    integrity:artifact.integrity,
  };
}

export function moduleArtifactSummary(
  artifact:unknown,
):ModuleArtifactSummary {
  if(!verifyModuleArtifact(artifact))fail('invalid module artifact');
  return {
    format:artifact.format+'@'+artifact.version,
    module:artifact.module,
    kernel:artifact.kernel,
    dependencies:artifact.dependencies.length,
    payloadKind:artifact.payload.kind,
    payloadBytes:Buffer.byteLength(artifact.payload.text,'utf8'),
    payloadIntegrity:artifact.payload.integrity,
    integrity:artifact.integrity,
  };
}
