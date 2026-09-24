import {baseReport} from '../report.js';
import {checkVerifiedSourceProject} from '../verified-project-pipeline.js';
import {resolveSourceProject} from '../project-sources.js';
import {resolveInput} from '../input.js';
import type {
  CommonArgs,
  VerifiedCheckReport,
} from '../types.js';
import {verifiedAssuranceReport} from '../verified-assurance.js';
import {assertRuntimeDependencyPolicy} from '../runtime-dependencies.js';

export async function checkCommand(
  common:CommonArgs,
):Promise<VerifiedCheckReport>{
  const input=await resolveInput(common);
  const project=await resolveSourceProject(input);
  const runtimeDependencyPolicy=assertRuntimeDependencyPolicy(
    project,
    input.loaded.config.runtimeDependencies,
  );
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
    sourceRoots:result.sourceRoots,
    moduleCacheHits:result.moduleCacheHits,
    moduleCacheMisses:result.moduleCacheMisses,
    semanticPipeline:'verified-core',
    proofStatus:'kernel-verified',
    assurance:verifiedAssuranceReport(
      result.checkedCore,
      input.loaded.config.runtimeDependencies,
    ),
    runtimeDependencyPolicy,
  };
}
