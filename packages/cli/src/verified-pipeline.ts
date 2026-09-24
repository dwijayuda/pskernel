import {
  createDefaultSourceFrontendRegistry,
  lowerV061ModuleToLean,
} from '@proofscript/syntax';
import {elaborateV061Declarations} from '@proofscript/elab';
import {compileCheckedCore} from '@proofscript/compiler';
import {createLeanEnvironmentProvider,requireLeanEnvironment} from '@proofscript/environment/node';
import {canonicalSourceIdentity} from './canonical-source.js';

const verifiedEnvironment=createLeanEnvironmentProvider();
const sourceFrontends=createDefaultSourceFrontendRegistry();

export function requireVerifiedBaseEnvironment(){
  return requireLeanEnvironment(verifiedEnvironment);
}

export function checkVerifiedSource(
  source:string,
  sourceFileName='input.ps',
){
  const surface=sourceFrontends.forFile(sourceFileName).parse(source);
  if((surface.imports?.length??0)>0){
    throw new Error(
      'PS_PROJECT_IMPORT_CONTEXT_REQUIRED: source imports require the project pipeline',
    );
  }
  const canonical=canonicalSourceIdentity(surface);
  const environment=requireVerifiedBaseEnvironment();
  const checkedCore=elaborateV061Declarations(surface,environment);
  return {
    surface,
    ...canonical,
    checkedCore,
    lean:lowerV061ModuleToLean(surface),
  };
}

export function compileVerifiedSource(
  source:string,
  fileName:string,
  sourceFileName='input.ps',
){
  const checked=checkVerifiedSource(source,sourceFileName);
  const compiled=compileCheckedCore(checked.checkedCore,fileName);
  return {...checked,...compiled};
}
