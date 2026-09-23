import {
  createDefaultSourceFrontendRegistry,
  lowerV061ModuleToLean,
} from '@proofscript/syntax';
import {elaborateV061Declarations} from '@proofscript/elab';
import {compileCheckedCore} from '@proofscript/compiler';
import {createLeanEnvironmentProvider,requireLeanEnvironment} from '@proofscript/environment/node';

const verifiedEnvironment=createLeanEnvironmentProvider();
const sourceFrontends=createDefaultSourceFrontendRegistry();

export function checkVerifiedSource(
  source:string,
  sourceFileName='input.ps',
){
  const surface=sourceFrontends.forFile(sourceFileName).parse(source);
  const environment=requireLeanEnvironment(verifiedEnvironment);
  const checkedCore=elaborateV061Declarations(surface,environment);
  return {
    surface,
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
