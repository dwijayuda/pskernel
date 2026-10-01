import {
  createDefaultSourceFrontendRegistry,
  createDefaultTranslationTargetPrinterRegistry,
} from '@proofscript/syntax';
import {resolveInput} from '../input.js';
import type {CommonArgs} from '../types.js';

const sourceFrontends=createDefaultSourceFrontendRegistry();
const translationTargets=createDefaultTranslationTargetPrinterRegistry();

export async function emitLeanCommand(common:CommonArgs):Promise<string>{
  const input=await resolveInput(common);
  const surface=sourceFrontends
    .forFile(input.sourcePath)
    .parse(input.source);
  return translationTargets.require('lean').print(surface);
}
