import {Buffer} from 'node:buffer';
import {
  admitCheckedCoreAdmissions,
  decodeCheckedCoreAdmissions,
  encodeCheckedCoreAdmissions,
  type CheckedCoreAdmission,
} from '@proofscript/checked-core';
import {Environment} from 'lean-ts-kernel';
import {Lean4ExportReplay} from 'lean-ts-kernel/lean4export';
import {
  canonicalJson,
  moduleFail,
  moduleHex256,
  moduleKernelMatchesCurrent,
  moduleKernelValid,
  moduleObject,
  moduleSha256,
  normalizeDeclarationStream,
  normalizeModuleDependencies,
} from './canonical.js';
import {
  CHECKED_MODULE_FORMAT_VERSION,
  DEFAULT_KERNEL,
  MODULE_FORMAT,
  MODULE_FORMAT_VERSION,
  type CheckedAdmissionsPayload,
  type CreateCheckedModuleArtifactOptions,
  type CreateModuleArtifactOptions,
  type JsonValue,
  type LoadModuleArtifactOptions,
  type LoadModuleArtifactResult,
  type ModuleArtifact,
  type ModuleArtifactSummary,
  type ModuleArtifactV1,
  type ModuleArtifactV2,
  type ModuleDependency,
} from './artifact-types.js';

function bodyForIntegrity(artifact:ModuleArtifact):unknown {
  const {integrity:_ignored,...body}=artifact;
  return body;
}
function commonBody(options:{
  readonly module:string;
  readonly dependencies:readonly ModuleDependency[];
  readonly kernel:typeof DEFAULT_KERNEL;
  readonly metadata?:JsonValue;
}){
  if(options.module.length===0){
    moduleFail('module name must be a non-empty string');
  }
  if(!moduleKernelValid(options.kernel)){
    moduleFail('invalid kernel compatibility descriptor');
  }
  return {
    format:MODULE_FORMAT,
    module:options.module,
    kernel:{...options.kernel},
    dependencies:normalizeModuleDependencies(options.dependencies),
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
  const payload={
    kind:'lean4export-ndjson',
    formatVersion:'3.1.0',
    integrity:moduleSha256(text),
    text,
  } as const;
  const body={
    ...commonBody({module,dependencies,kernel,metadata}),
    version:MODULE_FORMAT_VERSION,
    payload,
  } satisfies Omit<ModuleArtifactV1,'integrity'>;
  return {...body,integrity:moduleSha256(canonicalJson(body))};
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
    integrity:moduleSha256(text),
    text,
  };
  const body={
    ...commonBody({module,dependencies,kernel,metadata}),
    version:CHECKED_MODULE_FORMAT_VERSION,
    payload,
  } satisfies Omit<ModuleArtifactV2,'integrity'>;
  return {...body,integrity:moduleSha256(canonicalJson(body))};
}

function parseCheckedAdmissionsPayload(
  payload:CheckedAdmissionsPayload,
):readonly CheckedCoreAdmission[] {
  let parsed:unknown;
  try{
    parsed=JSON.parse(payload.text);
  }catch(error){
    moduleFail(
      'invalid checked admissions JSON: '+
      (error instanceof Error?error.message:String(error)),
    );
  }
  if(canonicalJson(parsed)+'\n'!==payload.text){
    moduleFail('checked admissions payload is not canonical JSON');
  }
  try{
    return decodeCheckedCoreAdmissions(parsed);
  }catch(error){
    moduleFail(
      'invalid checked admissions payload: '+
      (error instanceof Error?error.message:String(error)),
    );
  }
}

export function encodeModuleArtifact(artifact:unknown):string {
  if(!verifyModuleArtifact(artifact)){
    moduleFail('invalid module artifact');
  }
  return canonicalJson(artifact)+'\n';
}
export function decodeModuleArtifact(text:string):ModuleArtifact {
  let value:unknown;
  try{
    value=JSON.parse(text);
  }catch(error){
    moduleFail(
      'invalid JSON: '+
      (error instanceof Error?error.message:String(error)),
    );
  }
  if(!verifyModuleArtifact(value)){
    moduleFail('invalid module artifact');
  }
  return value;
}

function verifyCommonArtifact(value:Record<string,unknown>):void {
  if(
    value.format!==MODULE_FORMAT
    ||(value.version!==1&&value.version!==2)
  ){
    moduleFail(
      'unsupported artifact format/version '+
      String(value.format)+'@'+String(value.version),
    );
  }
  if(typeof value.module!=='string'||value.module.length===0){
    moduleFail('invalid module name');
  }
  if(!moduleKernelValid(value.kernel)){
    moduleFail('invalid kernel compatibility descriptor');
  }
  if(!Array.isArray(value.dependencies)){
    moduleFail('dependencies must be an array');
  }
  const deps=normalizeModuleDependencies(
    value.dependencies.map((dependency,index)=>{
      if(
        !moduleObject(dependency)
        ||typeof dependency.module!=='string'
        ||!moduleHex256(dependency.integrity)
      ){
        moduleFail('invalid dependency at index '+index);
      }
      return {
        module:dependency.module,
        integrity:dependency.integrity,
      };
    }),
  );
  if(canonicalJson(deps)!==canonicalJson(value.dependencies)){
    moduleFail('dependencies are not in canonical order');
  }
  if('metadata' in value)canonicalJson(value.metadata);
  if(!moduleHex256(value.integrity)){
    moduleFail('invalid module integrity');
  }
}

export function verifyModuleArtifact(
  value:unknown,
):value is ModuleArtifact {
  if(!moduleObject(value))moduleFail('artifact must be an object');
  verifyCommonArtifact(value);
  if(!moduleObject(value.payload)){
    moduleFail('unsupported module payload');
  }

  if(value.version===1){
    if(
      value.payload.kind!=='lean4export-ndjson'
      ||value.payload.formatVersion!=='3.1.0'
      ||typeof value.payload.text!=='string'
      ||!moduleHex256(value.payload.integrity)
    ){
      moduleFail('unsupported module payload');
    }
    if(
      normalizeDeclarationStream(value.payload.text)!==
      value.payload.text
    ){
      moduleFail('declaration stream is not canonical');
    }
    if(
      value.payload.integrity!==
      moduleSha256(value.payload.text)
    ){
      moduleFail('declaration payload integrity mismatch');
    }
  }else{
    if(
      value.payload.kind!=='proofscript-checked-admissions-json'
      ||value.payload.formatVersion!=='1.0.0'
      ||typeof value.payload.text!=='string'
      ||!moduleHex256(value.payload.integrity)
    ){
      moduleFail('unsupported module payload');
    }
    if(
      value.payload.integrity!==
      moduleSha256(value.payload.text)
    ){
      moduleFail('checked admissions payload integrity mismatch');
    }
    parseCheckedAdmissionsPayload(
      value.payload as unknown as CheckedAdmissionsPayload,
    );
  }

  const artifact=value as unknown as ModuleArtifact;
  if(
    artifact.integrity!==
    moduleSha256(canonicalJson(bodyForIntegrity(artifact)))
  ){
    moduleFail('module integrity mismatch');
  }
  return true;
}

export function verifyModuleDependencies(
  artifact:unknown,
  available:ReadonlyMap<string,string>,
):true {
  if(!verifyModuleArtifact(artifact)){
    moduleFail('invalid module artifact');
  }
  for(const dependency of artifact.dependencies){
    const got=available.get(dependency.module);
    if(got===undefined){
      moduleFail("missing dependency '"+dependency.module+"'");
    }
    if(got!==dependency.integrity){
      moduleFail(
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
  if(!verifyModuleArtifact(artifact)){
    moduleFail('invalid module artifact');
  }
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

  if(!moduleKernelMatchesCurrent(artifact.kernel)){
    moduleFail(
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
  if(!verifyModuleArtifact(artifact)){
    moduleFail('invalid module artifact');
  }
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
