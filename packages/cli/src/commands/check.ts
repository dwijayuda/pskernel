import {baseReport,checkSource} from '../pipeline.js';
import {checkVerifiedSource} from '../verified-pipeline.js';
import {resolveInput} from '../input.js';
import type {CommonArgs} from '../types.js';

export async function checkCommand(common:CommonArgs){
  const input=await resolveInput(common);
  if(common.verified){
    const result=checkVerifiedSource(
      input.source,
      input.sourcePath,
    );
    return {
      ok:true,
      command:'check',
      ...baseReport(
        input.sourcePath,
        result.checkedCore.declarations.length,
        result.surface.featureIds,
        result.canonicalSourceHash,
      ),
      semanticPipeline:'verified-core',
      proofStatus:'kernel-verified',
    };
  }
  const result=checkSource(
    input.source,
    input.sourcePath,
  );
  return {
    ok:true,
    command:'check',
    ...baseReport(
      input.sourcePath,
      result.checked.structures.length+
        result.checked.inductives.length+
        result.checked.declarations.length,
      result.surface.featureIds,
      result.canonicalSourceHash,
    ),
  };
}
