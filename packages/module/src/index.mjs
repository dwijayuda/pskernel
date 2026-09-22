import {createHash} from 'node:crypto';
import {Environment} from 'lean-ts-kernel';
import {Lean4ExportReplay} from 'lean-ts-kernel/lean4export';

export const MODULE_FORMAT='proofscript-module';
export const MODULE_FORMAT_VERSION=1;
export const DEFAULT_KERNEL={
  semantics:'lean4',
  leanVersion:'4.34.0',
  apiVersion:'0.1.0'
};

function fail(message){throw new Error(`@proofscript/module: ${message}`);}
function isObject(x){return typeof x==='object'&&x!==null&&!Array.isArray(x);}
function isHex256(x){return typeof x==='string'&&/^sha256:[0-9a-f]{64}$/.test(x);}
function sha256(text){return 'sha256:'+createHash('sha256').update(text,'utf8').digest('hex');}

export function canonicalJson(value){
  const seen=new Set();
  const go=(x,path)=>{
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

export function normalizeDeclarationStream(text){
  if(typeof text!=='string')fail('declaration stream must be a string');
  const normalized=text.replace(/\r\n?/g,'\n').replace(/[\t ]+$/gm,'').replace(/\n+$/,'');
  return normalized.length===0?'':normalized+'\n';
}

function normalizeDependencies(dependencies=[]){
  if(!Array.isArray(dependencies))fail('dependencies must be an array');
  const seen=new Set();
  const out=dependencies.map((d,i)=>{
    if(!isObject(d)||typeof d.module!=='string'||d.module.length===0||!isHex256(d.integrity))
      fail(`invalid dependency at index ${i}`);
    if(seen.has(d.module))fail(`duplicate dependency '${d.module}'`);
    seen.add(d.module);
    return {module:d.module,integrity:d.integrity};
  });
  out.sort((a,b)=>a.module.localeCompare(b.module)||a.integrity.localeCompare(b.integrity));
  return out;
}

function bodyForIntegrity(artifact){
  const {integrity:_ignored,...body}=artifact;
  return body;
}

export function createModuleArtifact({
  module,
  declarations,
  dependencies=[],
  kernel=DEFAULT_KERNEL,
  metadata
}){
  if(typeof module!=='string'||module.length===0)fail('module name must be a non-empty string');
  if(!isObject(kernel)||kernel.semantics!=='lean4'||typeof kernel.leanVersion!=='string'||typeof kernel.apiVersion!=='string')
    fail('invalid kernel compatibility descriptor');

  const text=normalizeDeclarationStream(declarations);
  const payload={
    kind:'lean4export-ndjson',
    formatVersion:'3.1.0',
    integrity:sha256(text),
    text
  };
  const artifact={
    format:MODULE_FORMAT,
    version:MODULE_FORMAT_VERSION,
    module,
    kernel:{
      semantics:kernel.semantics,
      leanVersion:kernel.leanVersion,
      apiVersion:kernel.apiVersion
    },
    dependencies:normalizeDependencies(dependencies),
    payload,
    ...(metadata===undefined?{}:{metadata})
  };
  return {...artifact,integrity:sha256(canonicalJson(artifact))};
}

export function encodeModuleArtifact(artifact){
  verifyModuleArtifact(artifact);
  return canonicalJson(artifact)+'\n';
}

export function decodeModuleArtifact(text){
  if(typeof text!=='string')fail('encoded artifact must be a string');
  let value;
  try{value=JSON.parse(text);}catch(e){fail(`invalid JSON: ${e instanceof Error?e.message:String(e)}`);}
  verifyModuleArtifact(value);
  return value;
}

export function verifyModuleArtifact(artifact){
  if(!isObject(artifact))fail('artifact must be an object');
  if(artifact.format!==MODULE_FORMAT||artifact.version!==MODULE_FORMAT_VERSION)
    fail(`unsupported artifact format/version ${String(artifact.format)}@${String(artifact.version)}`);
  if(typeof artifact.module!=='string'||artifact.module.length===0)fail('invalid module name');
  if(!isObject(artifact.kernel)||artifact.kernel.semantics!=='lean4'||typeof artifact.kernel.leanVersion!=='string'||typeof artifact.kernel.apiVersion!=='string')
    fail('invalid kernel compatibility descriptor');
  const deps=normalizeDependencies(artifact.dependencies);
  if(canonicalJson(deps)!==canonicalJson(artifact.dependencies))fail('dependencies are not in canonical order');
  if(!isObject(artifact.payload)||artifact.payload.kind!=='lean4export-ndjson'||artifact.payload.formatVersion!=='3.1.0'||typeof artifact.payload.text!=='string')
    fail('unsupported module payload');
  const normalized=normalizeDeclarationStream(artifact.payload.text);
  if(normalized!==artifact.payload.text)fail('declaration stream is not canonical');
  const payloadIntegrity=sha256(artifact.payload.text);
  if(artifact.payload.integrity!==payloadIntegrity)fail('declaration payload integrity mismatch');
  if(!isHex256(artifact.integrity))fail('invalid module integrity');
  const expected=sha256(canonicalJson(bodyForIntegrity(artifact)));
  if(artifact.integrity!==expected)fail('module integrity mismatch');
  return true;
}

export function verifyModuleDependencies(artifact,available){
  verifyModuleArtifact(artifact);
  if(!(available instanceof Map))fail('available dependencies must be a Map(module -> integrity)');
  for(const dep of artifact.dependencies){
    const got=available.get(dep.module);
    if(got===undefined)fail(`missing dependency '${dep.module}'`);
    if(got!==dep.integrity)fail(`dependency integrity mismatch for '${dep.module}'`);
  }
  return true;
}

export function loadModuleArtifact(artifact,{
  env=new Environment(),
  dependencyIntegrities=new Map()
}={}){
  verifyModuleArtifact(artifact);
  verifyModuleDependencies(artifact,dependencyIntegrities);
  const replay=new Lean4ExportReplay(env,{expectedLeanVersion:artifact.kernel.leanVersion});
  const stats=replay.replay(artifact.payload.text);
  return {
    env:replay.env,
    stats,
    module:artifact.module,
    integrity:artifact.integrity
  };
}

export function moduleArtifactSummary(artifact){
  verifyModuleArtifact(artifact);
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
