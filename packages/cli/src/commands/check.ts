import {baseReport,checkSource} from '../pipeline.js';
import {resolveInput} from '../input.js';
import type {CommonArgs} from '../types.js';

export async function checkCommand(common:CommonArgs){
  const input=await resolveInput(common);
  const result=checkSource(input.source);
  return {
    ok:true,
    command:'check',
    ...baseReport(input.sourcePath,result.checked.structures.length+result.checked.inductives.length+result.checked.declarations.length,result.surface.featureIds),
  };
}
