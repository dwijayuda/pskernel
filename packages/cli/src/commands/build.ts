import {mkdir,writeFile} from 'node:fs/promises';
import {basename,extname,join,resolve} from 'node:path';
import {baseReport} from '../report.js';
import {compileVerifiedSourceProject} from '../verified-project-pipeline.js';
import {resolveSourceProject} from '../project-sources.js';
import {resolveInput} from '../input.js';
import type {
  CommonArgs,
  VerifiedBuildReport,
  VerifiedBuildResult,
} from '../types.js';
import {
  writeVerifiedModuleArtifacts,
} from '../project-artifact-output.js';
import {verifiedAssuranceReport} from '../verified-assurance.js';
import {
  assertRuntimeDependencyPolicy,
  verifyInstalledRuntimeDependencies,
} from '../runtime-dependencies.js';
import {verifyRuntimeDependencyLock} from '../runtime-lock.js';

export async function buildCommand(
  common:CommonArgs,
):Promise<VerifiedBuildResult>{
  const input=await resolveInput(common);
  const extension=extname(input.sourcePath);
  const stem=basename(input.sourcePath,extension);
  const project=await resolveSourceProject(input);
  const runtimeDependencyPolicy=assertRuntimeDependencyPolicy(
    project,
    input.loaded.config.runtimeDependencies,
  );
  await verifyInstalledRuntimeDependencies(
    input.loaded.directory,
    runtimeDependencyPolicy,
  );
  const runtimeDependencyLock=await verifyRuntimeDependencyLock(
    input.loaded.directory,
    runtimeDependencyPolicy,
  );
  const outDir=resolve(
    input.loaded.directory,
    input.loaded.config.compilerOptions.outDir,
  );
  await mkdir(outDir,{recursive:true});

  const tsPath=join(outDir,stem+'.ts');
  const result=compileVerifiedSourceProject(
    project,
    tsPath,
  );
  const jsPath=join(outDir,stem+'.js');
  const dtsPath=join(outDir,stem+'.d.ts');
  const leanPath=join(outDir,stem+'.lean');
  const mapPath=join(outDir,stem+'.js.map');
  const manifestPath=join(outDir,stem+'.proofscript.json');
  const moduleArtifactFiles=await writeVerifiedModuleArtifacts(
    outDir,
    result.moduleArtifacts,
  );

  const report:VerifiedBuildReport={
    ok:true,
    command:'build',
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
    runtimeDependencyLock,
    outputDirectory:outDir,
    artifacts:{
      typescript:tsPath,
      javascript:jsPath,
      declarations:dtsPath,
      sourceMap:result.emitted.sourceMap===undefined?null:mapPath,
      lean:leanPath,
      manifest:manifestPath,
      modules:moduleArtifactFiles,
    },
    typescriptVersion:result.emitted.typescriptVersion,
  };

  const writes=[
    writeFile(tsPath,result.typeScript,'utf8'),
    writeFile(jsPath,result.emitted.javascript,'utf8'),
    writeFile(dtsPath,result.emitted.declaration,'utf8'),
    writeFile(leanPath,result.lean,'utf8'),
    writeFile(
      manifestPath,
      JSON.stringify(report,null,2)+'\n',
      'utf8',
    ),
  ];
  if(result.emitted.sourceMap!==undefined){
    writes.push(writeFile(mapPath,result.emitted.sourceMap,'utf8'));
  }
  await Promise.all(writes);
  return {report,verifiedIr:result.ir,jsPath};
}
