import {
  createDefaultSourceFrontendRegistry,
  createDefaultTranslationTargetPrinterRegistry,
} from '@proofscript/syntax';
import {resolveInput} from '../input.js';
import type {TranslateArgs} from '../types.js';

const sourceFrontends=createDefaultSourceFrontendRegistry();
const translationTargets=createDefaultTranslationTargetPrinterRegistry();

export async function translateCommand(
  args:TranslateArgs,
):Promise<string> {
  const input=await resolveInput(args);
  const surface=sourceFrontends
    .forFile(input.sourcePath)
    .parse(input.source);
  return translationTargets.require(args.target).print(surface);
}
