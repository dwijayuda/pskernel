import {lowerV061ModuleToLean,parseV061Module} from '@proofscript/syntax';
import {resolveInput} from '../input.js';
import type {CommonArgs} from '../types.js';

export async function emitLeanCommand(common:CommonArgs):Promise<string>{
  const input=await resolveInput(common);
  return lowerV061ModuleToLean(parseV061Module(input.source));
}
