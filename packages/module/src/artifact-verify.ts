import {
  decodeCheckedCoreAdmissions,
  type CheckedCoreAdmission,
} from '@proofscript/checked-core';
import {
  canonicalJson,
  moduleFail,
  moduleHex256,
  moduleKernelValid,
  moduleObject,
  moduleSha256,
  normalizeDeclarationStream,
  normalizeModuleDependencies,
} from './canonical.js';
import {
  MODULE_FORMAT,
  type CheckedAdmissionsPayload,
  type ModuleArtifact,
} from './artifact-types.js';

function bodyForIntegrity(artifact:ModuleArtifact):unknown {
  const {integrity:_ignored,...body}=artifact;
  return body;
}

export function parseCheckedAdmissionsPayload(
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
  if(
    !moduleObject(parsed)
    ||(
      payload.formatVersion==='1.0.0'
        ?parsed.version!==1
        :parsed.version!==2
    )
  ){
    moduleFail(
      'checked admissions payload format/version mismatch',
    );
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
      ||(
        value.payload.formatVersion!=='1.0.0'
        &&value.payload.formatVersion!=='1.1.0'
      )
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
