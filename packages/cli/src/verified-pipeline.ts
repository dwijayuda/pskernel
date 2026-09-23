import {
  lowerV061ModuleToLean,
  parseV061Module,
} from '@proofscript/syntax';
import {elaborateV061Declarations} from '@proofscript/elab';
import {compileCheckedCore} from '@proofscript/compiler';
import {createLeanEnvironmentProvider,requireLeanEnvironment} from '@proofscript/environment/node';

const verifiedEnvironment=createLeanEnvironmentProvider();

export function checkVerifiedSource(source:string){
  const surface=parseV061Module(source);
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
){
  const checked=checkVerifiedSource(source);
  const compiled=compileCheckedCore(checked.checkedCore,fileName);
  return {...checked,...compiled};
}
