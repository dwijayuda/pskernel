import {baseReport,checkSource} from '../pipeline.js';
import {checkVerifiedSourceProject} from '../verified-project-pipeline.js';
import {resolveSourceProject} from '../project-sources.js';
import {resolveInput} from '../input.js';
import type {CommonArgs} from '../types.js';

export async function checkCommand(common:CommonArgs){
  const input=await resolveInput(common);
  if(common.verified){
    const project=await resolveSourceProject(input);
    const result=checkVerifiedSourceProject(project);
    return {
      ok:true,
      command:'check',
      ...baseReport(
        input.sourcePath,
        result.checkedCore.declarations.length,
        result.featureIds,
        result.canonicalSourceHash,
      ),
      moduleCount:result.moduleOrder.length,
      moduleOrder:result.moduleOrder,
      moduleSources:result.moduleSources,
      projectIntegrity:result.projectIntegrity,
      moduleCacheHits:result.moduleCacheHits,
      moduleCacheMisses:result.moduleCacheMisses,
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
